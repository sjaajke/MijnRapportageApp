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
import 'package:excel/excel.dart';
import 'package:path/path.dart' as p;
import 'package:share_plus/share_plus.dart';
import '../models/nen_bouwdeel.dart';
import 'database_service.dart';
import 'photo_service.dart';

/// Excel- en CSV-export van de NEN 2767-conditiemeting (bouwdelen en
/// gebreken met ernst/omvang/intensiteit/conditiescore) voor deze inspectie.
class Nen2767ExportService {
  final _db = DatabaseService();

  static const _gebrekenHeader = [
    'Bouwdeel',
    'Gebrek',
    'Ernst',
    'Intensiteit',
    'Omvang (%)',
    'Conditiescore',
    'Locatie',
    'Toelichting',
    'Inspecteur',
    'Geïnspecteerd op',
  ];

  Future<List<List<String>>> _gebrekenRijen(int inspectionId) async {
    final bouwdelen = await _db.getNenBouwdelen(inspectionId);
    final bouwdeelById = {for (final b in bouwdelen) b.id!: b};
    final gebreken = await _db.getNenGebrekenVoorInspectie(inspectionId);

    String naamPad(NenBouwdeel node) {
      final parts = <String>[node.naam];
      var current = node;
      while (current.parentId != null &&
          bouwdeelById.containsKey(current.parentId)) {
        current = bouwdeelById[current.parentId]!;
        parts.insert(0, current.naam);
      }
      return parts.join(' > ');
    }

    return [
      for (final g in gebreken)
        [
          bouwdeelById.containsKey(g.bouwdeelId)
              ? naamPad(bouwdeelById[g.bouwdeelId]!)
              : '',
          g.gebrekOmschrijving,
          g.ernst,
          g.intensiteit,
          g.omvangPercentage.toStringAsFixed(0),
          '${g.conditiescore}',
          g.locatieDetail,
          g.toelichting,
          g.inspecteur,
          g.geinspecteerdOp,
        ],
    ];
  }

  Future<String> generateExcel(int inspectionId) async {
    final rijen = await _gebrekenRijen(inspectionId);
    final bouwdelen = await _db.getNenBouwdelen(inspectionId);

    final excel = Excel.createExcel();
    final gebrekenSheet = excel['Gebreken'];
    gebrekenSheet
        .appendRow(_gebrekenHeader.map((h) => TextCellValue(h)).toList());
    for (final rij in rijen) {
      gebrekenSheet.appendRow(rij.map((v) => TextCellValue(v)).toList());
    }

    final bouwdelenSheet = excel['Bouwdelen'];
    bouwdelenSheet.appendRow(
        ['Naam', 'Code'].map((h) => TextCellValue(h)).toList());
    for (final b in bouwdelen) {
      bouwdelenSheet.appendRow(
          [TextCellValue(b.naam), TextCellValue(b.code)]);
    }
    excel.delete('Sheet1');

    final bytes = excel.save();
    final dir = await PhotoService().getExportsDir();
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final filePath =
        p.join(dir, 'nen2767_${inspectionId}_$timestamp.xlsx');
    await File(filePath).writeAsBytes(bytes!);
    return filePath;
  }

  String _csvEscape(String value) {
    if (value.contains(',') || value.contains('"') || value.contains('\n')) {
      return '"${value.replaceAll('"', '""')}"';
    }
    return value;
  }

  Future<String> generateCsv(int inspectionId) async {
    final rijen = await _gebrekenRijen(inspectionId);
    final buffer = StringBuffer();
    buffer.writeln(_gebrekenHeader.map(_csvEscape).join(','));
    for (final rij in rijen) {
      buffer.writeln(rij.map(_csvEscape).join(','));
    }

    final dir = await PhotoService().getExportsDir();
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final filePath = p.join(dir, 'nen2767_${inspectionId}_$timestamp.csv');
    await File(filePath).writeAsString(buffer.toString());
    return filePath;
  }

  Future<void> exportExcelAndShare(int inspectionId) async {
    final path = await generateExcel(inspectionId);
    await Share.shareXFiles([XFile(path)]);
  }

  Future<void> exportCsvAndShare(int inspectionId) async {
    final path = await generateCsv(inspectionId);
    await Share.shareXFiles([XFile(path)]);
  }
}
