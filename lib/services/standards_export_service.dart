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
import '../models/standard.dart';
import 'database_service.dart';
import 'photo_service.dart';

/// Resultaat van een standaarden-import: aantal nieuwe, bijgewerkte en
/// overgeslagen (onherkenbare categorie) rijen.
class StandardsImportResult {
  final int inserted;
  final int updated;
  final int skipped;

  const StandardsImportResult({
    required this.inserted,
    required this.updated,
    required this.skipped,
  });
}

/// Excel-export en -import van de standaardwaarden (per categorie) op de
/// Standaarden-pagina.
class StandardsExportService {
  final _db = DatabaseService();

  static const _header = ['Categorie', 'Weergavenaam', 'Waarde'];

  /// Categoriesleutel → herkenbare namen (NL/EN), onafhankelijk van de
  /// huidige app-taal, zodat een eerder geëxporteerd bestand altijd weer
  /// ingelezen kan worden.
  static const _categoryNames = {
    'system': ['Stelsel', 'System'],
    'protection': ['Voorbeveiliging', 'Pre-protection'],
    'karakteristiek': ['Karakteristiek', 'Characteristic'],
    'protection_class': ['Beschermingsgraad omhulsel', 'Protection class'],
    'cable': ['Leiding doorsnede', 'Cable cross-section'],
    'cable_length': ['Leiding lengte', 'Cable length'],
    'cable_type': ['Leiding type', 'Cable type'],
    'main_switch': ['Hoofdsch. stroom', 'Main switch current'],
    'main_switch_poles': ['Hoofdsch. polen', 'Main switch poles'],
    'location': ['Locatie', 'Location'],
    'location_a': ['Locatie A', 'Location A'],
    'location_b': ['Locatie B', 'Location B'],
    'aarding': ['Aarding', 'Earthing'],
    'inspection_reason': ['Reden voor inspectie', 'Reason for inspection'],
    'inverter': ['Omvormer', 'Inverter'],
    'panel': ['Paneel', 'Panel'],
    'inspection_scope': ['Inspectie omvang', 'Inspection scope'],
    'inspection_term_basis': [
      'Inspectie termijn volgens',
      'Inspection term according to'
    ],
    'noodverlichting_merk': ['Noodverlichting Merk', 'Emergency lighting brand'],
    'noodverlichting_lichtbron': [
      'Noodverlichting Lichtbron',
      'Emergency lighting light source'
    ],
    'noodverlichting_accu': [
      'Noodverlichting Accu',
      'Emergency lighting battery'
    ],
    'noodverlichting_type': ['Noodverlichting Type', 'Emergency lighting type'],
    'noodverlichting_steker': [
      'Noodverlichting Steker',
      'Emergency lighting plug'
    ],
    'noodverlichting_hoogte': [
      'Noodverlichting Hoogte',
      'Emergency lighting height'
    ],
    'noodverlichting_functie': [
      'Noodverlichting Functie',
      'Emergency lighting function'
    ],
    'noodverlichting_montage': [
      'Noodverlichting Montage',
      'Emergency lighting mounting'
    ],
  };

  static final Map<String, String> _categoryKeyByName = {
    for (final entry in _categoryNames.entries) entry.key.toLowerCase(): entry.key,
    for (final entry in _categoryNames.entries)
      for (final name in entry.value) name.toLowerCase(): entry.key,
  };

  static String? _resolveCategory(String raw) =>
      _categoryKeyByName[raw.trim().toLowerCase()];

  Future<String> generateExcel(
      List<String> categoryKeys, List<String> categoryLabels) async {
    final excel = Excel.createExcel();
    final sheet = excel['Standaarden'];
    sheet.appendRow(_header.map((h) => TextCellValue(h)).toList());

    for (var i = 0; i < categoryKeys.length; i++) {
      final items = await _db.getStandards(categoryKeys[i]);
      for (final item in items) {
        sheet.appendRow([
          TextCellValue(categoryLabels[i]),
          TextCellValue(item.displayName),
          TextCellValue(item.value),
        ]);
      }
    }
    excel.delete('Sheet1');

    final bytes = excel.save();
    final dir = await PhotoService().getExportsDir();
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final filePath = p.join(dir, 'standaarden_$timestamp.xlsx');
    await File(filePath).writeAsBytes(bytes!);
    return filePath;
  }

  Future<void> exportExcelAndShare(
      List<String> categoryKeys, List<String> categoryLabels) async {
    final path = await generateExcel(categoryKeys, categoryLabels);
    await Share.shareXFiles([XFile(path)]);
  }

  /// Leest een eerder geëxporteerd (of handmatig samengesteld) Excel-bestand
  /// in en voegt de standaarden toe, of werkt ze bij op basis van categorie +
  /// waarde. Rijen met een onherkenbare categorie worden overgeslagen.
  Future<StandardsImportResult> importExcel(String path) async {
    final bytes = File(path).readAsBytesSync();
    final workbook = Excel.decodeBytes(bytes);
    final sheet = workbook.sheets.values.first;
    final rows = sheet.rows;
    if (rows.isEmpty) {
      return const StandardsImportResult(inserted: 0, updated: 0, skipped: 0);
    }

    final headers = <String, int>{};
    for (var c = 0; c < rows[0].length; c++) {
      final h = rows[0][c]?.value?.toString().trim() ?? '';
      if (h.isNotEmpty) headers[h] = c;
    }

    String cell(List<Data?> row, String col) {
      final idx = headers[col];
      if (idx == null || idx >= row.length) return '';
      return row[idx]?.value?.toString().trim() ?? '';
    }

    var inserted = 0;
    var updated = 0;
    var skipped = 0;

    for (var i = 1; i < rows.length; i++) {
      final row = rows[i];
      final value = cell(row, 'Waarde');
      if (value.isEmpty) continue;

      final categoryRaw = cell(row, 'Categorie');
      final category = _resolveCategory(categoryRaw);
      if (category == null) {
        skipped++;
        continue;
      }

      final displayName = cell(row, 'Weergavenaam');
      final wasInserted = await _db.upsertStandard(Standard(
        category: category,
        value: value,
        displayName: displayName.isNotEmpty ? displayName : value,
      ));
      if (wasInserted) { inserted++; } else { updated++; }
    }

    return StandardsImportResult(
        inserted: inserted, updated: updated, skipped: skipped);
  }
}
