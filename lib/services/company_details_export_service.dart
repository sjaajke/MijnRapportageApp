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
import '../models/company_details.dart';
import '../models/company_inspector.dart';
import '../models/measurement_instrument.dart';
import 'database_service.dart';
import 'photo_service.dart';

/// Resultaat van een import: of de bedrijfsinformatie is bijgewerkt en
/// hoeveel inspecteurs/meetinstrumenten zijn toegevoegd of bijgewerkt.
class CompanyDetailsImportResult {
  final bool companyInfoUpdated;
  final int inspectorsInserted;
  final int inspectorsUpdated;
  final int instrumentsInserted;
  final int instrumentsUpdated;

  const CompanyDetailsImportResult({
    required this.companyInfoUpdated,
    required this.inspectorsInserted,
    required this.inspectorsUpdated,
    required this.instrumentsInserted,
    required this.instrumentsUpdated,
  });
}

/// Excel-export en -import van de gegevens op de Bedrijfsgegevens-pagina: de
/// bedrijfsinformatie, de Herstel-koppeling, de inspecteurs en de
/// meetinstrumenten.
class CompanyDetailsExportService {
  final _db = DatabaseService();
  Future<String> generateExcel({
    required CompanyDetails details,
    required List<CompanyInspector> inspectors,
    required List<MeasurementInstrument> instruments,
  }) async {
    final excel = Excel.createExcel();

    final infoSheet = excel['Bedrijfsgegevens'];
    void addInfoRow(String label, String value) {
      infoSheet.appendRow([TextCellValue(label), TextCellValue(value)]);
    }

    addInfoRow('Naam bedrijf', details.companyName);
    addInfoRow('Adres', details.address);
    addInfoRow('Postcode/plaats', details.postalCity);
    addInfoRow('Telefoon', details.phone);
    addInfoRow('E-mail', details.email);
    addInfoRow('Contactpersoon', details.contactPerson);
    addInfoRow('Eindverantwoordelijke', details.finalResponsible);
    addInfoRow('Firebase project-ID', details.herstelFirebaseProjectId);
    addInfoRow('Firebase storage bucket', details.herstelFirebaseStorageBucket);
    addInfoRow('Hosting-domein webformulier', details.herstelWebDomain);

    final inspectorsSheet = excel['Inspecteurs'];
    inspectorsSheet.appendRow(
      ['Naam', 'Functie'].map((h) => TextCellValue(h)).toList(),
    );
    for (final inspector in inspectors) {
      inspectorsSheet.appendRow([
        TextCellValue(inspector.name),
        TextCellValue(inspector.functie),
      ]);
    }

    final instrumentsSheet = excel['Meetinstrumenten'];
    instrumentsSheet.appendRow(
      [
        'Fabrikant',
        'Model',
        'Serienummer',
        'Kalibratiedatum',
        'Herkalibratiedatum',
        'Certificaatnummer',
        'Kalibratiefrequentie',
        'Registratienummer',
        'Status',
        'Inspecteur',
      ].map((h) => TextCellValue(h)).toList(),
    );
    for (final instrument in instruments) {
      final inspectorName =
          inspectors
              .where((i) => i.id == instrument.inspectorId)
              .map((i) => i.name)
              .firstOrNull ??
          '';
      instrumentsSheet.appendRow([
        TextCellValue(instrument.fabrikant),
        TextCellValue(instrument.model),
        TextCellValue(instrument.serienummer),
        TextCellValue(instrument.kalibratiedatum),
        TextCellValue(instrument.herkalibratiedatum),
        TextCellValue(instrument.certificaatnummer),
        TextCellValue(instrument.kalibratiefrequentie),
        TextCellValue(instrument.registratienummer),
        TextCellValue(instrument.status),
        TextCellValue(inspectorName),
      ]);
    }

    excel.delete('Sheet1');

    final bytes = excel.save();
    final dir = await PhotoService().getExportsDir();
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final filePath = p.join(dir, 'bedrijfsgegevens_$timestamp.xlsx');
    await File(filePath).writeAsBytes(bytes!);
    return filePath;
  }

  Future<void> exportExcelAndShare({
    required CompanyDetails details,
    required List<CompanyInspector> inspectors,
    required List<MeasurementInstrument> instruments,
  }) async {
    final path = await generateExcel(
      details: details,
      inspectors: inspectors,
      instruments: instruments,
    );
    await Share.shareXFiles([XFile(path)]);
  }

  /// Leest een eerder geëxporteerd (of handmatig samengesteld) Excel-bestand
  /// in. Bedrijfsinformatie wordt bijgewerkt op basis van de rijen in het
  /// tabblad "Bedrijfsgegevens"; inspecteurs en meetinstrumenten worden
  /// toegevoegd of bijgewerkt op basis van naam respectievelijk
  /// serienummer.
  Future<CompanyDetailsImportResult> importExcel(String path) async {
    final bytes = File(path).readAsBytesSync();
    final workbook = Excel.decodeBytes(bytes);

    final companyInfoUpdated = await _importCompanyInfo(workbook);
    final inspectorNameToId = <String, int>{};
    final inspectorCounts = await _importInspectors(
      workbook,
      inspectorNameToId,
    );
    final instrumentCounts = await _importInstruments(
      workbook,
      inspectorNameToId,
    );

    return CompanyDetailsImportResult(
      companyInfoUpdated: companyInfoUpdated,
      inspectorsInserted: inspectorCounts[0],
      inspectorsUpdated: inspectorCounts[1],
      instrumentsInserted: instrumentCounts[0],
      instrumentsUpdated: instrumentCounts[1],
    );
  }

  Future<bool> _importCompanyInfo(Excel workbook) async {
    final sheet = workbook.sheets['Bedrijfsgegevens'];
    if (sheet == null) return false;

    final values = <String, String>{};
    for (final row in sheet.rows) {
      if (row.isEmpty) continue;
      final label = row[0]?.value?.toString().trim() ?? '';
      if (label.isEmpty) continue;
      final value = row.length > 1
          ? (row[1]?.value?.toString().trim() ?? '')
          : '';
      values[label.toLowerCase()] = value;
    }
    if (values.isEmpty) return false;

    final current = await _db.getCompanyDetails() ?? CompanyDetails();
    final updated = current.copyWith(
      companyName: values['naam bedrijf'] ?? current.companyName,
      address: values['adres'] ?? current.address,
      postalCity: values['postcode/plaats'] ?? current.postalCity,
      phone: values['telefoon'] ?? current.phone,
      email: values['e-mail'] ?? current.email,
      contactPerson: values['contactpersoon'] ?? current.contactPerson,
      finalResponsible:
          values['eindverantwoordelijke'] ?? current.finalResponsible,
      herstelFirebaseProjectId:
          values['firebase project-id'] ?? current.herstelFirebaseProjectId,
      herstelFirebaseStorageBucket:
          values['firebase storage bucket'] ??
          current.herstelFirebaseStorageBucket,
      herstelWebDomain:
          values['hosting-domein webformulier'] ?? current.herstelWebDomain,
    );
    await _db.saveCompanyDetails(updated);
    return true;
  }

  /// Retourneert [ingevoegd, bijgewerkt] en vult [nameToId] met de naam
  /// (kleine letters) → id van elke inspecteur, zodat meetinstrumenten
  /// gekoppeld kunnen worden.
  Future<List<int>> _importInspectors(
    Excel workbook,
    Map<String, int> nameToId,
  ) async {
    final existing = await _db.getCompanyInspectors();
    for (final inspector in existing) {
      if (inspector.id != null) {
        nameToId[inspector.name.toLowerCase()] = inspector.id!;
      }
    }

    final sheet = workbook.sheets['Inspecteurs'];
    if (sheet == null) return [0, 0];
    final rows = sheet.rows;
    if (rows.isEmpty) return [0, 0];

    final headers = _headerIndex(rows[0]);
    var inserted = 0;
    var updated = 0;
    for (var i = 1; i < rows.length; i++) {
      final row = rows[i];
      final name = _cell(row, headers, 'naam');
      if (name.isEmpty) continue;
      final functie = _cell(row, headers, 'functie');

      final match = existing.where(
        (e) => e.name.toLowerCase() == name.toLowerCase(),
      );
      if (match.isNotEmpty) {
        final inspector = match.first;
        await _db.updateCompanyInspector(inspector.copyWith(functie: functie));
        nameToId[name.toLowerCase()] = inspector.id!;
        updated++;
      } else {
        final id = await _db.insertCompanyInspector(
          CompanyInspector(name: name, functie: functie),
        );
        nameToId[name.toLowerCase()] = id;
        inserted++;
      }
    }
    return [inserted, updated];
  }

  /// Retourneert [ingevoegd, bijgewerkt]. Bestaande meetinstrumenten worden
  /// herkend op serienummer; instrumenten zonder serienummer worden altijd
  /// als nieuw toegevoegd.
  Future<List<int>> _importInstruments(
    Excel workbook,
    Map<String, int> inspectorNameToId,
  ) async {
    final sheet = workbook.sheets['Meetinstrumenten'];
    if (sheet == null) return [0, 0];
    final rows = sheet.rows;
    if (rows.isEmpty) return [0, 0];

    final headers = _headerIndex(rows[0]);
    final existing = await _db.getAllMeasurementInstruments();
    var inserted = 0;
    var updated = 0;

    for (var i = 1; i < rows.length; i++) {
      final row = rows[i];
      final fabrikant = _cell(row, headers, 'fabrikant');
      final model = _cell(row, headers, 'model');
      final serienummer = _cell(row, headers, 'serienummer');
      if (fabrikant.isEmpty && model.isEmpty && serienummer.isEmpty) continue;

      final inspectorName = _cell(row, headers, 'inspecteur');
      final inspectorId = inspectorName.isNotEmpty
          ? inspectorNameToId[inspectorName.toLowerCase()]
          : null;

      MeasurementInstrument? match;
      if (serienummer.isNotEmpty) {
        final found = existing.where(
          (e) => e.serienummer.toLowerCase() == serienummer.toLowerCase(),
        );
        if (found.isNotEmpty) match = found.first;
      }

      final instrument = MeasurementInstrument(
        id: match?.id,
        inspectorId: inspectorId ?? match?.inspectorId,
        fabrikant: fabrikant,
        model: model,
        serienummer: serienummer,
        kalibratiedatum: _cell(row, headers, 'kalibratiedatum'),
        herkalibratiedatum: _cell(row, headers, 'herkalibratiedatum'),
        certificaatnummer: _cell(row, headers, 'certificaatnummer'),
        kalibratiefrequentie: _cell(row, headers, 'kalibratiefrequentie'),
        registratienummer: _cell(row, headers, 'registratienummer'),
        status: _cell(row, headers, 'status'),
      );

      if (match != null) {
        await _db.updateMeasurementInstrument(instrument);
        updated++;
      } else {
        await _db.insertMeasurementInstrument(instrument);
        inserted++;
      }
    }
    return [inserted, updated];
  }

  Map<String, int> _headerIndex(List<Data?> row) {
    final headers = <String, int>{};
    for (var c = 0; c < row.length; c++) {
      final h = row[c]?.value?.toString().trim().toLowerCase() ?? '';
      if (h.isNotEmpty) headers[h] = c;
    }
    return headers;
  }

  String _cell(List<Data?> row, Map<String, int> headers, String col) {
    final idx = headers[col];
    if (idx == null || idx >= row.length) return '';
    return row[idx]?.value?.toString().trim() ?? '';
  }
}
