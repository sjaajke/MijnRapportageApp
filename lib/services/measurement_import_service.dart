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

import 'dart:io';
import 'dart:typed_data';
import 'package:excel/excel.dart' as xlsx;
import 'package:path/path.dart' as p;
import '../models/measurement_group.dart';
import '../models/measurement_reading.dart';
import 'database_service.dart';
import 'xls_biff_decoder.dart';

/// Imports measurement data exported by installation-test instruments
/// (e.g. Metrel COMBI419) as .xlsx or legacy .xls spreadsheets.
///
/// The source sheets follow a fixed layout: an optional metadata header,
/// then repeating blocks of a "group" row (circuit/location, columns
/// L/P/Opmerking) followed by its individual measurement rows (point
/// number, measurement type, then label/value/unit triples).
class MeasurementImportService {
  final _db = DatabaseService();

  Future<int> importFile(String path, int inspectionId) async {
    final ext = p.extension(path).toLowerCase();
    final bytes = await File(path).readAsBytes();
    final sheets = switch (ext) {
      '.xlsx' => _decodeXlsx(bytes),
      '.xls' => _decodeXls(bytes),
      _ => throw Exception('Alleen .xlsx en .xls bestanden worden ondersteund'),
    };

    final bronBestand = p.basename(path);
    int volgorde = 0;
    int groupCount = 0;

    for (final sheet in sheets) {
      final groups = _parseSheet(sheet.$1, sheet.$2);
      for (final group in groups) {
        final groupId = await _db.insertMeasurementGroup(MeasurementGroup(
          inspectionId: inspectionId,
          bronBestand: bronBestand,
          label: group.sheetLabel,
          groepNummer: group.groepNummer,
          puntNummer: group.puntNummer,
          omschrijving: group.omschrijving,
          volgorde: volgorde++,
        ));
        int rv = 0;
        for (final reading in group.readings) {
          await _db.insertMeasurementReading(MeasurementReading(
            groupId: groupId,
            puntNummer: reading.puntNummer,
            metingType: reading.type,
            waarden: reading.waarden,
            volgorde: rv++,
          ));
        }
        groupCount++;
      }
    }
    return groupCount;
  }

  // ── Spreadsheet decoding ─────────────────────────────────────────────────

  List<(String, List<List<dynamic>>)> _decodeXlsx(Uint8List bytes) {
    final workbook = xlsx.Excel.decodeBytes(bytes);
    return workbook.sheets.entries.map((entry) {
      final rows = entry.value.rows
          .map((row) => row.map(_xlsxCellValue).toList())
          .toList();
      return (entry.key, rows);
    }).toList();
  }

  dynamic _xlsxCellValue(xlsx.Data? cell) {
    final value = cell?.value;
    if (value == null) return null;
    if (value is xlsx.IntCellValue) return value.value;
    if (value is xlsx.DoubleCellValue) return value.value;
    if (value is xlsx.BoolCellValue) return value.value;
    return value.toString();
  }

  List<(String, List<List<dynamic>>)> _decodeXls(Uint8List bytes) {
    final sheets = XlsBiffDecoder.decodeBytes(bytes);
    return sheets.map((s) => (s.name, s.rows)).toList();
  }

  // ── Generic row → group/reading parsing ─────────────────────────────────

  List<_ParsedGroup> _parseSheet(String sheetName, List<List<dynamic>> rows) {
    final headerIdx =
        rows.indexWhere((r) => _cellStr(r, 0) == 'L' && _cellStr(r, 1) == 'P');

    String? description;
    if (headerIdx > 0) {
      final prevText = _cellStr(rows[headerIdx - 1], 0);
      if (prevText.isNotEmpty && prevText.toLowerCase() != 'opmerking') {
        description = prevText;
      }
    }
    final sheetLabel = description ?? sheetName;
    final startRow = headerIdx >= 0 ? headerIdx + 1 : 0;

    final groups = <_ParsedGroup>[];
    _ParsedGroup? current;
    for (int i = startRow; i < rows.length; i++) {
      final row = rows[i];
      if (row.every((v) => v == null || (v is String && v.trim().isEmpty))) {
        continue;
      }
      final aEmpty = _cellEmpty(row, 0);
      final bIsNum = _cellIsNum(row, 1);
      final cText = _cellStr(row, 2);

      if (!aEmpty && _cellIsNum(row, 0) && bIsNum && cText.isNotEmpty) {
        current = _ParsedGroup(
          sheetLabel: sheetLabel,
          groepNummer: _cellStr(row, 0),
          puntNummer: _cellStr(row, 1),
          omschrijving: cText,
        );
        groups.add(current);
        continue;
      }
      if (aEmpty && cText.toLowerCase() == 'metingen') {
        continue; // section marker, no data
      }
      if (aEmpty && bIsNum && cText.isNotEmpty) {
        final waarden = <MeasurementValue>[];
        for (int c = 3; c < row.length; c += 3) {
          final label = _cellStr(row, c);
          if (label.isEmpty) continue;
          final value = c + 1 < row.length ? _cellStr(row, c + 1) : '';
          final unit =
              c + 2 < row.length ? _normalizeUnit(_cellStr(row, c + 2)) : '';
          waarden.add(MeasurementValue(label: label, value: value, unit: unit));
        }
        current ??= _ParsedGroup(
          sheetLabel: sheetLabel,
          groepNummer: '',
          puntNummer: '',
          omschrijving: '(onbekend)',
        )..addTo(groups);
        current.readings.add(_ParsedReading(
          puntNummer: _cellStr(row, 1),
          type: cText,
          waarden: waarden,
        ));
      }
    }
    return groups;
  }

  // Known instrument export quirk: the Ohm symbol is written using a
  // private symbol-font byte that decodes as these characters.
  static const _unitFixups = {'ê': 'Ω', 'Mê': 'MΩ', 'kê': 'kΩ'};

  String _normalizeUnit(String unit) => _unitFixups[unit] ?? unit;

  String _fmtNum(num n) {
    final d = n.toDouble();
    if (d == d.roundToDouble() && d.abs() < 1e15) return d.toInt().toString();
    var s = d.toStringAsFixed(4);
    s = s.replaceFirst(RegExp(r'0+$'), '');
    s = s.replaceFirst(RegExp(r'\.$'), '');
    return s;
  }

  String _cellStr(List<dynamic> row, int i) {
    if (i >= row.length) return '';
    final v = row[i];
    if (v == null) return '';
    if (v is num) return _fmtNum(v);
    return v.toString().trim();
  }

  bool _cellIsNum(List<dynamic> row, int i) {
    if (i >= row.length) return false;
    final v = row[i];
    if (v is num) return true;
    if (v == null) return false;
    final s = v.toString().trim();
    if (s.isEmpty) return false;
    return double.tryParse(s.replaceAll(',', '.')) != null;
  }

  bool _cellEmpty(List<dynamic> row, int i) {
    if (i >= row.length) return true;
    final v = row[i];
    if (v == null) return true;
    if (v is String) return v.trim().isEmpty;
    return false;
  }
}

class _ParsedGroup {
  final String sheetLabel;
  final String groepNummer;
  final String puntNummer;
  final String omschrijving;
  final List<_ParsedReading> readings = [];

  _ParsedGroup({
    required this.sheetLabel,
    required this.groepNummer,
    required this.puntNummer,
    required this.omschrijving,
  });

  void addTo(List<_ParsedGroup> list) {
    if (!list.contains(this)) list.add(this);
  }
}

class _ParsedReading {
  final String puntNummer;
  final String type;
  final List<MeasurementValue> waarden;

  _ParsedReading({
    required this.puntNummer,
    required this.type,
    required this.waarden,
  });
}
