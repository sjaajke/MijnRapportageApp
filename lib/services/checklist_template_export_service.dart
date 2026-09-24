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
import '../models/checklist_template.dart';
import 'database_service.dart';
import 'photo_service.dart';

/// The result of importing standard checklists from Excel.
class ChecklistTemplateImportResult {
  final int inserted;
  final int updated;
  const ChecklistTemplateImportResult(this.inserted, this.updated);
}

/// Excel-export/import van de standaard checklijsten (Instellingen). Elke
/// rij bevat één item; items met dezelfde checklijstnaam vormen samen één
/// checklijst.
class ChecklistTemplateExportService {
  final _db = DatabaseService();

  static const _header = ['Checklijst', 'Item'];

  Future<String> generateExcel() async {
    final templates = await _db.getChecklistTemplates();

    final excel = Excel.createExcel();
    final sheet = excel['Standaard checklijsten'];
    sheet.appendRow(_header.map((h) => TextCellValue(h)).toList());

    for (final template in templates) {
      if (template.items.isEmpty) {
        sheet.appendRow([TextCellValue(template.name), null]);
        continue;
      }
      for (final item in template.items) {
        sheet.appendRow([TextCellValue(template.name), TextCellValue(item)]);
      }
    }
    excel.delete('Sheet1');

    final bytes = excel.save();
    final dir = await PhotoService().getExportsDir();
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final filePath = p.join(dir, 'standaard_checklijsten_$timestamp.xlsx');
    await File(filePath).writeAsBytes(bytes!);
    return filePath;
  }

  Future<void> exportExcelAndShare() async {
    final path = await generateExcel();
    await Share.shareXFiles([XFile(path)]);
  }

  /// Imports standard checklists from a previously exported Excel file.
  /// Checklists are matched by name: an existing checklist gets its items
  /// replaced with the imported ones, a new name creates a new checklist.
  Future<ChecklistTemplateImportResult> importExcel(String path) async {
    final bytes = File(path).readAsBytesSync();
    final workbook = Excel.decodeBytes(bytes);
    final sheet = workbook.sheets.values.first;
    final rows = sheet.rows;
    if (rows.isEmpty) return const ChecklistTemplateImportResult(0, 0);

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

    // Group rows by checklist name, preserving the order in which each
    // name first appears.
    final order = <String>[];
    final grouped = <String, List<String>>{};
    for (var i = 1; i < rows.length; i++) {
      final row = rows[i];
      final name = cell(row, 'Checklijst');
      if (name.isEmpty) continue;
      final items = grouped.putIfAbsent(name, () {
        order.add(name);
        return <String>[];
      });
      final itemLabel = cell(row, 'Item');
      if (itemLabel.isNotEmpty) items.add(itemLabel);
    }

    var nextSortOrder = (await _db.getChecklistTemplates()).length;
    var inserted = 0;
    var updated = 0;

    for (final name in order) {
      final wasInserted = await _db.upsertChecklistTemplate(ChecklistTemplate(
        name: name,
        items: grouped[name]!,
        sortOrder: nextSortOrder,
      ));
      if (wasInserted) {
        inserted++;
        nextSortOrder++;
      } else {
        updated++;
      }
    }

    return ChecklistTemplateImportResult(inserted, updated);
  }
}
