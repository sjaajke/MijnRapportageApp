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
import '../models/title_page.dart';
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
  final bool layoutUpdated;

  const CompanyDetailsImportResult({
    required this.companyInfoUpdated,
    required this.inspectorsInserted,
    required this.inspectorsUpdated,
    required this.instrumentsInserted,
    required this.instrumentsUpdated,
    this.layoutUpdated = false,
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
    TitlePage? layoutDefaults,
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
    addInfoRow('Logo pad', details.logoPath ?? '');
    addInfoRow('Logo titelpagina pad', details.logoTitelpaginaPath ?? '');
    addInfoRow('Logo SCIOS pad', details.logoSciosPath ?? '');
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

    if (layoutDefaults != null) {
      final layoutSheet = excel['Titelpagina layout'];
      layoutSheet.appendRow(
        ['Element', 'X', 'Y', 'Breedte', 'Hoogte'].map(TextCellValue.new).toList(),
      );
      void addLayoutRow(String label, double x, double y, double w, double h) {
        layoutSheet.appendRow([
          TextCellValue(label),
          DoubleCellValue(x),
          DoubleCellValue(y),
          DoubleCellValue(w),
          DoubleCellValue(h),
        ]);
      }

      addLayoutRow('Titel', layoutDefaults.titleX, layoutDefaults.titleY,
          layoutDefaults.titleW, layoutDefaults.titleH);
      addLayoutRow('Subtitel', layoutDefaults.subtitleX, layoutDefaults.subtitleY,
          layoutDefaults.subtitleW, layoutDefaults.subtitleH);
      addLayoutRow('Foto', layoutDefaults.photoX, layoutDefaults.photoY,
          layoutDefaults.photoW, layoutDefaults.photoH);
      addLayoutRow('Inspectiedatum', layoutDefaults.dateX, layoutDefaults.dateY,
          layoutDefaults.dateW, layoutDefaults.dateH);
      addLayoutRow('Identificatiecode', layoutDefaults.codeX, layoutDefaults.codeY,
          layoutDefaults.codeW, layoutDefaults.codeH);
      addLayoutRow('Projectnummer', layoutDefaults.projectX, layoutDefaults.projectY,
          layoutDefaults.projectW, layoutDefaults.projectH);
      addLayoutRow('Inspectieadres', layoutDefaults.addressNameX,
          layoutDefaults.addressNameY, layoutDefaults.addressNameW,
          layoutDefaults.addressNameH);
      addLayoutRow('Logo (SCIOS)', layoutDefaults.logoX, layoutDefaults.logoY,
          layoutDefaults.logoW, layoutDefaults.logoH);
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
    TitlePage? layoutDefaults,
  }) async {
    final path = await generateExcel(
      details: details,
      inspectors: inspectors,
      instruments: instruments,
      layoutDefaults: layoutDefaults,
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
    final layoutUpdated = await _importLayoutDefaults(workbook);

    return CompanyDetailsImportResult(
      companyInfoUpdated: companyInfoUpdated,
      inspectorsInserted: inspectorCounts[0],
      inspectorsUpdated: inspectorCounts[1],
      instrumentsInserted: instrumentCounts[0],
      instrumentsUpdated: instrumentCounts[1],
      layoutUpdated: layoutUpdated,
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
      logoPath: _existingPathOrNull(values['logo pad']) ?? current.logoPath,
      logoTitelpaginaPath:
          _existingPathOrNull(values['logo titelpagina pad']) ??
          current.logoTitelpaginaPath,
      logoSciosPath:
          _existingPathOrNull(values['logo scios pad']) ??
          current.logoSciosPath,
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

  /// Geeft [path] terug als deze niet leeg is en op dit apparaat bestaat,
  /// anders `null`. Padden uit een import gemaakt op een ander apparaat
  /// wijzen doorgaans niet naar een bestaand bestand en worden genegeerd.
  String? _existingPathOrNull(String? path) {
    if (path == null || path.isEmpty) return null;
    return File(path).existsSync() ? path : null;
  }

  static const _layoutElements = {
    'titel': ('titleX', 'titleY', 'titleW', 'titleH'),
    'subtitel': ('subtitleX', 'subtitleY', 'subtitleW', 'subtitleH'),
    'foto': ('photoX', 'photoY', 'photoW', 'photoH'),
    'inspectiedatum': ('dateX', 'dateY', 'dateW', 'dateH'),
    'identificatiecode': ('codeX', 'codeY', 'codeW', 'codeH'),
    'projectnummer': ('projectX', 'projectY', 'projectW', 'projectH'),
    'inspectieadres': (
      'addressNameX',
      'addressNameY',
      'addressNameW',
      'addressNameH',
    ),
    'logo (scios)': ('logoX', 'logoY', 'logoW', 'logoH'),
  };

  Future<bool> _importLayoutDefaults(Excel workbook) async {
    final sheet = workbook.sheets['Titelpagina layout'];
    if (sheet == null) return false;
    final rows = sheet.rows;
    if (rows.isEmpty) return false;

    final headers = _headerIndex(rows[0]);
    final values = <String, double>{};
    for (var i = 1; i < rows.length; i++) {
      final row = rows[i];
      final element = _cell(row, headers, 'element').toLowerCase();
      final fields = _layoutElements[element];
      if (fields == null) continue;
      final x = _numCell(row, headers, 'x');
      final y = _numCell(row, headers, 'y');
      final w = _numCell(row, headers, 'breedte');
      final h = _numCell(row, headers, 'hoogte');
      if (x == null || y == null || w == null || h == null) continue;
      values[fields.$1] = x;
      values[fields.$2] = y;
      values[fields.$3] = w;
      values[fields.$4] = h;
    }
    if (values.isEmpty) return false;

    final d = await _db.getTitlePageLayoutDefaults();
    double g(String key, String dbKey, double fallback) =>
        values[key] ?? d?[dbKey] ?? fallback;

    final updated = TitlePage(
      inspectionId: 0,
      titleX: g('titleX', 'title_x', 0.5),
      titleY: g('titleY', 'title_y', 0.15),
      titleW: g('titleW', 'title_w', 0.80),
      titleH: g('titleH', 'title_h', 0.10),
      subtitleX: g('subtitleX', 'subtitle_x', 0.5),
      subtitleY: g('subtitleY', 'subtitle_y', 0.26),
      subtitleW: g('subtitleW', 'subtitle_w', 0.70),
      subtitleH: g('subtitleH', 'subtitle_h', 0.07),
      photoX: g('photoX', 'photo_x', 0.5),
      photoY: g('photoY', 'photo_y', 0.50),
      photoW: g('photoW', 'photo_w', 0.60),
      photoH: g('photoH', 'photo_h', 0.35),
      dateX: g('dateX', 'date_x', 0.5),
      dateY: g('dateY', 'date_y', 0.78),
      dateW: g('dateW', 'date_w', 0.70),
      dateH: g('dateH', 'date_h', 0.065),
      codeX: g('codeX', 'code_x', 0.5),
      codeY: g('codeY', 'code_y', 0.86),
      codeW: g('codeW', 'code_w', 0.70),
      codeH: g('codeH', 'code_h', 0.065),
      projectX: g('projectX', 'project_x', 0.5),
      projectY: g('projectY', 'project_y', 0.93),
      projectW: g('projectW', 'project_w', 0.70),
      projectH: g('projectH', 'project_h', 0.065),
      logoX: g('logoX', 'logo_x', 0.82),
      logoY: g('logoY', 'logo_y', 0.07),
      logoW: g('logoW', 'logo_w', 0.30),
      logoH: g('logoH', 'logo_h', 0.12),
      addressNameX: g('addressNameX', 'address_name_x', 0.5),
      addressNameY: g('addressNameY', 'address_name_y', 0.72),
      addressNameW: g('addressNameW', 'address_name_w', 0.70),
      addressNameH: g('addressNameH', 'address_name_h', 0.065),
    );
    await _db.saveTitlePageLayoutDefaults(updated);
    return true;
  }

  double? _numCell(List<Data?> row, Map<String, int> headers, String col) {
    final idx = headers[col];
    if (idx == null || idx >= row.length) return null;
    final value = row[idx]?.value;
    if (value is IntCellValue) return value.value.toDouble();
    if (value is DoubleCellValue) return value.value;
    if (value == null) return null;
    return double.tryParse(value.toString().trim().replaceAll(',', '.'));
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
