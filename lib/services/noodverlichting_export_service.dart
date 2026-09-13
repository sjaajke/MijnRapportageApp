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
import '../models/noodverlichting_installation.dart';
import 'database_service.dart';
import 'photo_service.dart';

/// Excel-export van de noodverlichting-lijst van een inspectie.
class NoodverlichtingExportService {
  final _db = DatabaseService();

  static const _header = [
    'Component nr',
    'Naam',
    'Naam code',
    'Locatie',
    'Locatie A',
    'Locatie B',
    'Merk',
    'Lichtbron',
    'Accu type',
    'Type noodverlichting',
    'Type steker',
    'Hoogte',
    'Functie',
    'Montage',
    'Chemie van de accu',
    'Type installatie',
    'Installatie onderdeel',
    'Componentfunctie',
    'Jaar van aanleg',
    'Inspectie interval (jaar)',
    'Inspectiedatum',
    'Herinspectiedatum',
    'Status',
    'Opmerking optie',
    'Opmerking',
  ];

  String _statusLabel(String status) {
    switch (status) {
      case 'R':
        return 'Rood';
      case 'O':
        return 'Oranje';
      default:
        return 'Groen';
    }
  }

  CellValue? _cell(String value) =>
      value.isEmpty ? null : TextCellValue(value);

  Future<String> generateExcel(int inspectionId) async {
    final installations =
        await _db.getNoodverlichtingInstallations(inspectionId);

    final excel = Excel.createExcel();
    final sheet = excel['Noodverlichting'];
    sheet.appendRow(_header.map((h) => TextCellValue(h)).toList());

    for (final item in installations) {
      sheet.appendRow([
        item.componentNr != null ? IntCellValue(item.componentNr!) : null,
        _cell(item.name),
        _cell(item.nameCode),
        _cell(item.location),
        _cell(item.locationA),
        _cell(item.locationB),
        _cell(item.merk),
        _cell(item.lichtbron),
        _cell(item.accuType),
        _cell(item.typeNoodverlichting),
        _cell(item.typeSteker),
        _cell(item.hoogte),
        _cell(item.functie),
        _cell(item.montage),
        _cell(item.chemieVanDeAccu),
        _cell(item.typeInstallatie),
        _cell(item.installatieOnderdeel),
        _cell(item.componentFunctie),
        _cell(item.jaarVanAanleg),
        _cell(item.inspectieInterval),
        _cell(item.inspectieDatum),
        _cell(item.herinspectieDatum),
        _cell(_statusLabel(item.status)),
        _cell(item.opmerkingOptie),
        _cell(item.opmerking),
      ]);
    }
    excel.delete('Sheet1');

    final bytes = excel.save();
    final dir = await PhotoService().getExportsDir();
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final filePath = p.join(dir, 'noodverlichting_$timestamp.xlsx');
    await File(filePath).writeAsBytes(bytes!);
    return filePath;
  }

  Future<void> exportExcelAndShare(int inspectionId) async {
    final path = await generateExcel(inspectionId);
    await Share.shareXFiles([XFile(path)]);
  }

  String _statusCode(String raw) {
    switch (raw.trim().toLowerCase()) {
      case 'rood':
      case 'r':
        return 'R';
      case 'oranje':
      case 'o':
        return 'O';
      default:
        return 'G';
    }
  }

  /// Normalizes a date string to the app's internal dd-MM-yyyy format;
  /// Inspectora exports use dd/MM/yyyy.
  String _normalizeDate(String raw) => raw.trim().replaceAll('/', '-');

  /// Imports noodverlichting-installaties from a previously exported (or
  /// Inspectora-generated) Excel file into [inspectionId]. New rows are
  /// always added; existing installations are left untouched.
  Future<int> importExcel(String path, int inspectionId) async {
    final bytes = File(path).readAsBytesSync();
    final workbook = Excel.decodeBytes(bytes);
    final sheet = workbook.sheets.values.first;
    final rows = sheet.rows;
    if (rows.isEmpty) return 0;

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

    final existing = await _db.getNoodverlichtingInstallations(inspectionId);
    var sortOrder = existing.length;
    var imported = 0;

    for (var i = 1; i < rows.length; i++) {
      final row = rows[i];
      final name = cell(row, 'Naam');
      final nameCode = cell(row, 'Naam code');
      if (name.isEmpty && nameCode.isEmpty) continue;

      final componentNrRaw = cell(row, 'Component nr');
      final componentNr = componentNrRaw.isEmpty
          ? null
          : int.tryParse(componentNrRaw) ??
              double.tryParse(componentNrRaw)?.round();

      await _db.insertNoodverlichtingInstallation(
        NoodverlichtingInstallation(
          inspectionId: inspectionId,
          componentNr: componentNr,
          name: name,
          nameCode: nameCode,
          location: cell(row, 'Locatie'),
          locationA: cell(row, 'Locatie A'),
          locationB: cell(row, 'Locatie B'),
          merk: cell(row, 'Merk'),
          lichtbron: cell(row, 'Lichtbron'),
          accuType: cell(row, 'Accu type'),
          typeNoodverlichting: cell(row, 'Type noodverlichting'),
          typeSteker: cell(row, 'Type steker'),
          hoogte: cell(row, 'Hoogte'),
          functie: cell(row, 'Functie'),
          montage: cell(row, 'Montage'),
          chemieVanDeAccu: cell(row, 'Chemie van de accu'),
          typeInstallatie: cell(row, 'Type installatie').isNotEmpty
              ? cell(row, 'Type installatie')
              : 'Noodverlichtingsinstallatie',
          installatieOnderdeel: cell(row, 'Installatie onderdeel').isNotEmpty
              ? cell(row, 'Installatie onderdeel')
              : 'Noodverlichting',
          componentFunctie: cell(row, 'Componentfunctie').isNotEmpty
              ? cell(row, 'Componentfunctie')
              : 'Noodverlichting',
          jaarVanAanleg: cell(row, 'Jaar van aanleg'),
          inspectieDatum: _normalizeDate(cell(row, 'Inspectiedatum')),
          inspectieInterval: cell(row, 'Inspectie interval (jaar)'),
          status: _statusCode(cell(row, 'Status')),
          opmerkingOptie: cell(row, 'Opmerking optie'),
          opmerking: cell(row, 'Opmerking'),
          sortOrder: sortOrder++,
        ),
      );
      imported++;
    }

    return imported;
  }
}
