// Copyright (C) 2026 Jay Smeekes
//
// This file is part of MijnRapportage.
//
// MijnRapportage is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// MijnRapportage is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with MijnRapportage. If not, see <https://www.gnu.org/licenses/>.

// Minimal pure-Dart reader for legacy Excel 97-2003 (.xls / BIFF8) files.
//
// Implements just enough of [MS-CFB] (Compound File Binary Format) and
// [MS-XLS] (BIFF8) to extract sheet names and cell grids (numbers and
// strings). Formulas, styles, charts and other rich features are ignored.

import 'dart:math' as math;
import 'dart:typed_data';

class XlsSheet {
  final String name;
  final List<List<dynamic>> rows;
  XlsSheet(this.name, this.rows);
}

class XlsBiffDecoder {
  static List<XlsSheet> decodeBytes(Uint8List bytes) {
    final cfb = _CfbFile(bytes);
    final wb = cfb.getStream('Workbook') ?? cfb.getStream('Book');
    if (wb == null) {
      throw FormatException('Geen Workbook-stream gevonden in .xls bestand');
    }
    return _Biff8Parser(wb).parse();
  }
}

// ─────────────────────────────── CFB (OLE2) reader ──────────────────────────

class _DirEntry {
  final String name;
  final int type; // 1=storage, 2=stream, 5=root storage
  final int start;
  final int size;
  _DirEntry(this.name, this.type, this.start, this.size);
}

class _CfbFile {
  final Uint8List bytes;
  late final ByteData _bd;
  late final int sectorSize;
  late final int miniSectorSize;
  late final int miniStreamCutoff;
  late final List<int> fat;
  late final List<int> miniFat;
  late final List<_DirEntry> entries;
  late final Uint8List miniStream;

  static const int endOfChain = 0xFFFFFFFE;
  static const int freeSect = 0xFFFFFFFF;

  _CfbFile(this.bytes) {
    _bd = ByteData.sublistView(bytes);
    if (bytes.length < 512 ||
        _bd.getUint32(0, Endian.little) != 0xE011CFD0 ||
        _bd.getUint32(4, Endian.little) != 0xE11AB1A1) {
      throw FormatException('Geen geldig OLE2/CFB-bestand (.xls verwacht)');
    }
    final sectorShift = _bd.getUint16(30, Endian.little);
    final miniSectorShift = _bd.getUint16(32, Endian.little);
    final numFatSectorsHdr = _bd.getUint32(44, Endian.little);
    final firstDirSector = _bd.getUint32(48, Endian.little);
    miniStreamCutoff = _bd.getUint32(56, Endian.little);
    final firstMiniFatSector = _bd.getUint32(60, Endian.little);
    final firstDifatSector = _bd.getUint32(68, Endian.little);
    final numDifatSectorsHdr = _bd.getUint32(72, Endian.little);

    sectorSize = 1 << sectorShift;
    miniSectorSize = 1 << miniSectorShift;

    // ── DIFAT (FAT sector list) ────────────────────────────────────────────
    final difat = <int>[];
    for (int i = 0; i < 109; i++) {
      difat.add(_bd.getUint32(76 + i * 4, Endian.little));
    }
    int curDifat = firstDifatSector;
    int difatGuard = 0;
    while (curDifat != endOfChain &&
        curDifat != freeSect &&
        difatGuard < numDifatSectorsHdr + 4 &&
        difatGuard < 10000) {
      final off = _sectorOffset(curDifat);
      final perSector = sectorSize ~/ 4;
      for (int i = 0; i < perSector - 1; i++) {
        difat.add(_bd.getUint32(off + i * 4, Endian.little));
      }
      curDifat = _bd.getUint32(off + (perSector - 1) * 4, Endian.little);
      difatGuard++;
    }

    // ── FAT ─────────────────────────────────────────────────────────────────
    final perSector = sectorSize ~/ 4;
    fat = <int>[];
    for (final sec in difat) {
      if (sec == freeSect || sec < 0) continue;
      final off = _sectorOffset(sec);
      if (off + sectorSize > bytes.length) continue;
      for (int i = 0; i < perSector; i++) {
        fat.add(_bd.getUint32(off + i * 4, Endian.little));
      }
      if (fat.length ~/ perSector >= numFatSectorsHdr + 8) break;
    }

    // ── Directory entries ──────────────────────────────────────────────────
    final dirBytes = _readChain(firstDirSector);
    entries = _parseDirEntries(dirBytes);

    // ── Mini FAT + mini stream (root entry's own stream) ───────────────────
    final root = entries.firstWhere((e) => e.type == 5,
        orElse: () => _DirEntry('Root Entry', 5, endOfChain, 0));
    miniStream = root.start == endOfChain
        ? Uint8List(0)
        : _readChain(root.start, knownSize: root.size);

    miniFat = <int>[];
    int curMini = firstMiniFatSector;
    int miniGuard = 0;
    while (curMini != endOfChain && curMini != freeSect && miniGuard < 100000) {
      final off = _sectorOffset(curMini);
      if (off + sectorSize > bytes.length) break;
      for (int i = 0; i < perSector; i++) {
        miniFat.add(_bd.getUint32(off + i * 4, Endian.little));
      }
      if (curMini >= fat.length) break;
      curMini = fat[curMini];
      miniGuard++;
    }
  }

  int _sectorOffset(int sectorId) => 512 + sectorId * sectorSize;

  Uint8List _readChain(int startSector, {int? knownSize}) {
    final out = BytesBuilder();
    int cur = startSector;
    int guard = 0;
    while (cur != endOfChain && cur != freeSect && guard < 1000000) {
      final off = _sectorOffset(cur);
      if (off + sectorSize > bytes.length) break;
      out.add(bytes.sublist(off, off + sectorSize));
      if (cur >= fat.length) break;
      cur = fat[cur];
      guard++;
    }
    var result = out.toBytes();
    if (knownSize != null && knownSize >= 0 && knownSize < result.length) {
      result = result.sublist(0, knownSize);
    }
    return result;
  }

  Uint8List _readMiniChain(int startSector, int knownSize) {
    final out = BytesBuilder();
    int cur = startSector;
    int guard = 0;
    while (cur != endOfChain && cur != freeSect && guard < 1000000) {
      final off = cur * miniSectorSize;
      if (off + miniSectorSize > miniStream.length) break;
      out.add(miniStream.sublist(off, off + miniSectorSize));
      if (cur >= miniFat.length) break;
      cur = miniFat[cur];
      guard++;
    }
    var result = out.toBytes();
    if (knownSize < result.length) result = result.sublist(0, knownSize);
    return result;
  }

  List<_DirEntry> _parseDirEntries(Uint8List dirBytes) {
    final list = <_DirEntry>[];
    final n = dirBytes.length ~/ 128;
    final dbd = ByteData.sublistView(dirBytes);
    for (int i = 0; i < n; i++) {
      final base = i * 128;
      final nameLenBytes = dbd.getUint16(base + 64, Endian.little);
      final type = dbd.getUint8(base + 66);
      if (type == 0) continue; // unused entry
      final charCount = nameLenBytes >= 2 ? (nameLenBytes ~/ 2 - 1) : 0;
      final codeUnits = <int>[];
      for (int c = 0; c < charCount; c++) {
        codeUnits.add(dbd.getUint16(base + c * 2, Endian.little));
      }
      final name = String.fromCharCodes(codeUnits);
      final start = dbd.getUint32(base + 116, Endian.little);
      final sizeLow = dbd.getUint32(base + 120, Endian.little);
      final sizeHigh = dbd.getUint32(base + 124, Endian.little);
      final size = sizeLow + sizeHigh * 4294967296;
      list.add(_DirEntry(name, type, start, size));
    }
    return list;
  }

  Uint8List? getStream(String name) {
    _DirEntry? entry;
    for (final e in entries) {
      if (e.type == 2 && e.name.toLowerCase() == name.toLowerCase()) {
        entry = e;
        break;
      }
    }
    if (entry == null) return null;
    if (entry.size < miniStreamCutoff) {
      return _readMiniChain(entry.start, entry.size);
    }
    return _readChain(entry.start, knownSize: entry.size);
  }
}

// ─────────────────────────────── BIFF8 reader ───────────────────────────────

class _BiffRecord {
  final int type;
  final int offset; // absolute offset of the record start within the stream
  final Uint8List data;
  _BiffRecord(this.type, this.offset, this.data);
}

class _BoundSheet {
  final String name;
  final int bofPos;
  _BoundSheet(this.name, this.bofPos);
}

// Reads primitive values across a sequence of byte chunks (used for SST +
// CONTINUE records), honouring the BIFF8 rule that a continued character
// array restarts with a fresh compression-flag byte at each chunk boundary.
class _ChunkReader {
  final List<Uint8List> chunks;
  int chunkIdx = 0;
  int pos = 0;
  _ChunkReader(this.chunks);

  bool get eof {
    _skipEmpty();
    return chunkIdx >= chunks.length;
  }

  void _skipEmpty() {
    while (chunkIdx < chunks.length && pos >= chunks[chunkIdx].length) {
      chunkIdx++;
      pos = 0;
    }
  }

  int readUint8() {
    _skipEmpty();
    if (chunkIdx >= chunks.length) return 0;
    final v = chunks[chunkIdx][pos];
    pos++;
    return v;
  }

  int readUint16() {
    final b0 = readUint8();
    final b1 = readUint8();
    return b0 | (b1 << 8);
  }

  int readUint32() {
    final w0 = readUint16();
    final w1 = readUint16();
    return w0 | (w1 << 16);
  }

  void skip(int n) {
    for (int i = 0; i < n; i++) {
      readUint8();
    }
  }

  String readCharArray(int cch, bool initialCompressed) {
    final codeUnits = <int>[];
    bool compressed = initialCompressed;
    int remaining = cch;
    while (remaining > 0) {
      _skipEmpty();
      if (chunkIdx >= chunks.length) break;
      if (pos == 0 && codeUnits.isNotEmpty) {
        // We just crossed into a new chunk mid-array: a fresh option-flags
        // byte precedes the continuation characters.
        final newFlags = readUint8();
        compressed = (newFlags & 0x1) == 0;
        continue;
      }
      if (compressed) {
        codeUnits.add(readUint8());
      } else {
        codeUnits.add(readUint16());
      }
      remaining--;
    }
    return String.fromCharCodes(codeUnits);
  }
}

double _rkToDouble(int rk) {
  final fX100 = (rk & 0x1) != 0;
  final fInt = (rk & 0x2) != 0;
  double value;
  if (fInt) {
    int v = (rk >> 2) & 0x3FFFFFFF;
    if ((v & 0x20000000) != 0) v -= 0x40000000;
    value = v.toDouble();
  } else {
    final bd = ByteData(8);
    bd.setUint32(0, 0, Endian.little);
    bd.setUint32(4, rk & 0xFFFFFFFC, Endian.little);
    value = bd.getFloat64(0, Endian.little);
  }
  if (fX100) value /= 100;
  return value;
}

class _Biff8Parser {
  final Uint8List wb;
  late final ByteData _bd;
  late final List<_BiffRecord> records;

  static const int rtBof = 0x0809;
  static const int rtEof = 0x000A;
  static const int rtBoundSheet = 0x0085;
  static const int rtSst = 0x00FC;
  static const int rtContinue = 0x003C;
  static const int rtLabelSst = 0x00FD;
  static const int rtNumber = 0x0203;
  static const int rtRk = 0x027E;
  static const int rtMulRk = 0x00BD;
  static const int rtLabel = 0x0204;

  _Biff8Parser(this.wb) {
    _bd = ByteData.sublistView(wb);
    records = _splitRecords();
  }

  List<_BiffRecord> _splitRecords() {
    final list = <_BiffRecord>[];
    int pos = 0;
    while (pos + 4 <= wb.length) {
      final type = _bd.getUint16(pos, Endian.little);
      final len = _bd.getUint16(pos + 2, Endian.little);
      final dataStart = pos + 4;
      final dataEnd = dataStart + len;
      if (dataEnd > wb.length) break;
      list.add(_BiffRecord(type, pos, wb.sublist(dataStart, dataEnd)));
      pos = dataEnd;
    }
    return list;
  }

  List<XlsSheet> parse() {
    final boundSheets = <_BoundSheet>[];
    List<String> sst = [];

    for (int idx = 0; idx < records.length; idx++) {
      final r = records[idx];
      if (r.type == rtBoundSheet) {
        boundSheets.add(_parseBoundSheet(r));
      } else if (r.type == rtSst) {
        final chunks = <Uint8List>[r.data];
        int j = idx + 1;
        while (j < records.length && records[j].type == rtContinue) {
          chunks.add(records[j].data);
          j++;
        }
        sst = _parseSst(chunks);
        idx = j - 1;
      }
    }

    final sheets = <XlsSheet>[];
    for (final bs in boundSheets) {
      final startIdx = records.indexWhere((r) => r.offset == bs.bofPos);
      if (startIdx < 0) continue;
      final rows = _parseSheetCells(startIdx, sst);
      sheets.add(XlsSheet(bs.name, rows));
    }
    return sheets;
  }

  _BoundSheet _parseBoundSheet(_BiffRecord r) {
    final bd = ByteData.sublistView(r.data);
    final bofPos = bd.getUint32(0, Endian.little);
    final cch = bd.getUint8(6);
    final flags = bd.getUint8(7);
    final compressed = (flags & 0x1) == 0;
    String name;
    if (compressed) {
      name = String.fromCharCodes(r.data.sublist(8, 8 + cch));
    } else {
      final units = <int>[];
      for (int c = 0; c < cch; c++) {
        units.add(bd.getUint16(8 + c * 2, Endian.little));
      }
      name = String.fromCharCodes(units);
    }
    return _BoundSheet(name, bofPos);
  }

  List<String> _parseSst(List<Uint8List> chunks) {
    final reader = _ChunkReader(chunks);
    reader.readUint32(); // cstTotal (unused)
    final cstUnique = reader.readUint32();
    final result = <String>[];
    for (int s = 0; s < cstUnique; s++) {
      if (reader.eof) break;
      final cch = reader.readUint16();
      final flags = reader.readUint8();
      final compressed = (flags & 0x1) == 0;
      final fExtSt = (flags & 0x4) != 0;
      final fRichSt = (flags & 0x8) != 0;
      int cRun = 0;
      int cbExt = 0;
      if (fRichSt) cRun = reader.readUint16();
      if (fExtSt) cbExt = reader.readUint32();
      final text = reader.readCharArray(cch, compressed);
      if (fRichSt) reader.skip(cRun * 4);
      if (fExtSt) reader.skip(cbExt);
      result.add(text);
    }
    return result;
  }

  List<List<dynamic>> _parseSheetCells(int startIdx, List<String> sst) {
    final cellMap = <int, Map<int, dynamic>>{};
    int depth = 1;
    for (int k = startIdx + 1; k < records.length; k++) {
      final r = records[k];
      if (r.type == rtBof) {
        depth++;
        continue;
      }
      if (r.type == rtEof) {
        depth--;
        if (depth == 0) break;
        continue;
      }
      if (depth > 1) continue;

      final bd = ByteData.sublistView(r.data);
      if (r.data.length < 6) continue;
      switch (r.type) {
        case rtLabelSst:
          {
            final row = bd.getUint16(0, Endian.little);
            final col = bd.getUint16(2, Endian.little);
            final isst = bd.getUint32(6, Endian.little);
            final val = (isst >= 0 && isst < sst.length) ? sst[isst] : '';
            (cellMap[row] ??= {})[col] = val;
            break;
          }
        case rtNumber:
          {
            final row = bd.getUint16(0, Endian.little);
            final col = bd.getUint16(2, Endian.little);
            final val = bd.getFloat64(6, Endian.little);
            (cellMap[row] ??= {})[col] = val;
            break;
          }
        case rtRk:
          {
            final row = bd.getUint16(0, Endian.little);
            final col = bd.getUint16(2, Endian.little);
            final rk = bd.getUint32(6, Endian.little);
            (cellMap[row] ??= {})[col] = _rkToDouble(rk);
            break;
          }
        case rtMulRk:
          {
            final row = bd.getUint16(0, Endian.little);
            final colFirst = bd.getUint16(2, Endian.little);
            final n = (r.data.length - 6) ~/ 6;
            for (int c = 0; c < n; c++) {
              final base = 4 + c * 6;
              final rk = bd.getUint32(base + 2, Endian.little);
              (cellMap[row] ??= {})[colFirst + c] = _rkToDouble(rk);
            }
            break;
          }
        case rtLabel:
          {
            final row = bd.getUint16(0, Endian.little);
            final col = bd.getUint16(2, Endian.little);
            final cch = bd.getUint16(6, Endian.little);
            final flags = bd.getUint8(8);
            final compressed = (flags & 0x1) == 0;
            String val;
            if (compressed) {
              val = String.fromCharCodes(r.data.sublist(9, 9 + cch));
            } else {
              final units = <int>[];
              for (int c = 0; c < cch; c++) {
                units.add(bd.getUint16(9 + c * 2, Endian.little));
              }
              val = String.fromCharCodes(units);
            }
            (cellMap[row] ??= {})[col] = val;
            break;
          }
        default:
          break;
      }
    }

    if (cellMap.isEmpty) return [];
    final maxRow = cellMap.keys.reduce(math.max);
    int maxCol = 0;
    for (final m in cellMap.values) {
      if (m.keys.isNotEmpty) maxCol = math.max(maxCol, m.keys.reduce(math.max));
    }
    final rows = <List<dynamic>>[];
    for (int rI = 0; rI <= maxRow; rI++) {
      final rowMap = cellMap[rI];
      rows.add(List<dynamic>.generate(maxCol + 1, (c) => rowMap?[c]));
    }
    return rows;
  }
}
