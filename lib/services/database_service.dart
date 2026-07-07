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

import 'dart:convert';
import 'dart:math';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/inspection.dart';
import '../models/title_page.dart';
import '../models/general_data.dart';
import '../models/inspection_detail.dart';
import '../models/switchboard.dart';
import '../models/solar_installation.dart';
import '../models/solar_inverter.dart';
import '../models/solar_string_measurement.dart';
import '../models/defect.dart';
import '../models/standard.dart';
import '../models/defect_annotation.dart';
import '../models/company_details.dart';
import '../models/company_inspector.dart';
import '../models/measurement_instrument.dart';
import '../models/report_template.dart';
import '../models/final_assessment.dart';
import '../models/rapport_constatering.dart';
import '../models/steekproef_item.dart';
import '../models/tekening.dart';
import '../models/tekening_pin.dart';
import '../models/herstel.dart';
import '../models/solar_vereffening.dart';
import '../models/measurement_group.dart';
import '../models/measurement_reading.dart';
import 'photo_service.dart';

class DatabaseService {
  static final DatabaseService _instance = DatabaseService._internal();
  factory DatabaseService() => _instance;
  DatabaseService._internal();

  Future<Database>? _databaseFuture;
  Future<void>? _ensureAnnotationSchemaFuture;
  Future<void>? _ensureCompanySchemaFuture;
  Future<void>? _ensureCompanyInspectorsSchemaFuture;
  Future<void>? _ensureMeasurementInstrumentsSchemaFuture;
  Future<void>? _ensureReportTemplatesSchemaFuture;
  Future<void>? _ensureInspectionDetailMethodeSchemaFuture;
  Future<void>? _ensureFinalAssessmentSchemaFuture;
  Future<void>? _ensureRapportConstateringenSchemaFuture;
  Future<void>? _ensureSolarInstallationSchemaFuture;
  Future<void>? _ensureSolarInverterSchemaFuture;
  Future<void>? _ensureSolarStringMeasurementSchemaFuture;
  Future<void>? _ensureSolarVereffeningSchemaFuture;

  Future<Database> get database {
    _databaseFuture ??= _initDatabase();
    return _databaseFuture!;
  }

  /// Ensures the annotation schema exists. Uses a shared Future to
  /// prevent concurrent calls from racing each other.
  Future<void> _ensureAnnotationSchema() {
    _ensureAnnotationSchemaFuture ??= _doEnsureAnnotationSchema();
    return _ensureAnnotationSchemaFuture!;
  }

  Future<void> _doEnsureAnnotationSchema() async {
    final db = await database;
    await db.execute('''
      CREATE TABLE IF NOT EXISTS defect_annotations (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        defect_id INTEGER NOT NULL,
        photo_number INTEGER NOT NULL DEFAULT 1,
        x REAL NOT NULL DEFAULT 0.0,
        y REAL NOT NULL DEFAULT 0.0,
        width REAL NOT NULL DEFAULT 0.1,
        height REAL NOT NULL DEFAULT 0.1,
        label TEXT DEFAULT '',
        color TEXT DEFAULT 'Ge',
        order_number INTEGER NOT NULL DEFAULT 1,
        shape TEXT NOT NULL DEFAULT 'rect',
        FOREIGN KEY (defect_id) REFERENCES defects (id) ON DELETE CASCADE
      )
    ''');
    final cols = await db.rawQuery("PRAGMA table_info(defects)");
    if (!cols.any((c) => c['name'] == 'has_annotations')) {
      await db.execute(
        "ALTER TABLE defects ADD COLUMN has_annotations INTEGER NOT NULL DEFAULT 0",
      );
    }
    final annotationCols = await db.rawQuery(
      "PRAGMA table_info(defect_annotations)",
    );
    if (!annotationCols.any((c) => c['name'] == 'shape')) {
      await db.execute(
        "ALTER TABLE defect_annotations ADD COLUMN shape TEXT NOT NULL DEFAULT 'rect'",
      );
    }
  }

  Future<void> _ensureCompanySchema() {
    _ensureCompanySchemaFuture ??= _doEnsureCompanySchema();
    return _ensureCompanySchemaFuture!;
  }

  Future<void> _ensureCompanyInspectorsSchema() {
    _ensureCompanyInspectorsSchemaFuture ??= _doEnsureCompanyInspectorsSchema();
    return _ensureCompanyInspectorsSchemaFuture!;
  }

  Future<void> _ensureMeasurementInstrumentsSchema() {
    _ensureMeasurementInstrumentsSchemaFuture ??=
        _doEnsureMeasurementInstrumentsSchema();
    return _ensureMeasurementInstrumentsSchemaFuture!;
  }

  Future<void> _ensureReportTemplatesSchema() {
    _ensureReportTemplatesSchemaFuture ??= _doEnsureReportTemplatesSchema();
    return _ensureReportTemplatesSchemaFuture!;
  }

  Future<void> _ensureInspectionDetailMethodeSchema() {
    _ensureInspectionDetailMethodeSchemaFuture ??=
        _doEnsureInspectionDetailMethodeSchema();
    return _ensureInspectionDetailMethodeSchemaFuture!;
  }

  Future<void> _ensureSolarInstallationSchema() {
    _ensureSolarInstallationSchemaFuture ??= _doEnsureSolarInstallationSchema();
    return _ensureSolarInstallationSchemaFuture!;
  }

  Future<void> _doEnsureSolarInstallationSchema() async {
    final db = await database;
    final cols = await db.rawQuery("PRAGMA table_info(solar_installations)");
    final existing = cols.map((c) => c['name'] as String).toSet();
    final toAdd = {
      'location_a': "TEXT NOT NULL DEFAULT ''",
      'location_b': "TEXT NOT NULL DEFAULT ''",
      'building_type': "TEXT",
      'roof_type': "TEXT",
      'orientation': "TEXT",
      'tilt_angle': "TEXT",
      'frame': "TEXT",
      'cloud_cover': "TEXT",
      'temperature': "TEXT",
      'layout_plan': "TEXT",
      'ballast_plan': "TEXT",
      'cable_plan': "TEXT",
      'construction_declaration': "TEXT",
      'installation_data': "TEXT",
    };
    for (final entry in toAdd.entries) {
      if (!existing.contains(entry.key)) {
        await db.execute(
          "ALTER TABLE solar_installations ADD COLUMN ${entry.key} ${entry.value}",
        );
      }
    }
  }

  Future<void> _ensureSolarInverterSchema() {
    _ensureSolarInverterSchemaFuture ??= _doEnsureSolarInverterSchema();
    return _ensureSolarInverterSchemaFuture!;
  }

  Future<void> _doEnsureSolarInverterSchema() async {
    final db = await database;
    await db.execute('''
      CREATE TABLE IF NOT EXISTS solar_inverters (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        solar_installation_id INTEGER NOT NULL,
        location TEXT DEFAULT '',
        inverter_name TEXT DEFAULT '',
        inverter_brand TEXT DEFAULT '',
        inverter_type TEXT DEFAULT '',
        inverter_serial TEXT DEFAULT '',
        inverter_ip TEXT DEFAULT '',
        inverter_isolation_class TEXT DEFAULT '',
        inverter_max_vdc TEXT DEFAULT '',
        inverter_max_idc TEXT DEFAULT '',
        inverter_isc_pv TEXT DEFAULT '',
        inverter_inom TEXT DEFAULT '',
        panel_brand TEXT DEFAULT '',
        panel_type TEXT DEFAULT '',
        panel_short_circuit_current TEXT DEFAULT '',
        panel_open_circuit_voltage TEXT DEFAULT '',
        protection TEXT DEFAULT '',
        cable TEXT DEFAULT '',
        photo_path TEXT,
        FOREIGN KEY (solar_installation_id) REFERENCES solar_installations (id) ON DELETE CASCADE
      )
    ''');
    final invCols = await db.rawQuery("PRAGMA table_info(solar_inverters)");
    final invExisting = invCols.map((c) => c['name'] as String).toSet();
    for (final col in ['location_a', 'location_b', 'inverter_name']) {
      if (!invExisting.contains(col)) {
        await db.execute(
          "ALTER TABLE solar_inverters ADD COLUMN $col TEXT NOT NULL DEFAULT ''",
        );
      }
    }
  }

  Future<void> _ensureSolarStringMeasurementSchema() {
    _ensureSolarStringMeasurementSchemaFuture ??=
        _doEnsureSolarStringMeasurementSchema();
    return _ensureSolarStringMeasurementSchemaFuture!;
  }

  Future<void> _doEnsureSolarStringMeasurementSchema() async {
    final db = await database;
    await db.execute('''
      CREATE TABLE IF NOT EXISTS solar_string_measurements (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        solar_inverter_id INTEGER NOT NULL,
        strang TEXT DEFAULT '',
        panel_count TEXT DEFAULT '',
        irradiation TEXT DEFAULT '',
        cell_temp TEXT DEFAULT '',
        uoc TEXT DEFAULT '',
        isc TEXT DEFAULT '',
        riso TEXT DEFAULT '',
        FOREIGN KEY (solar_inverter_id) REFERENCES solar_inverters (id) ON DELETE CASCADE
      )
    ''');
  }

  Future<void> _ensureSolarVereffeningSchema() {
    _ensureSolarVereffeningSchemaFuture ??= _doEnsureSolarVereffeningSchema();
    return _ensureSolarVereffeningSchemaFuture!;
  }

  Future<void> _doEnsureSolarVereffeningSchema() async {
    final db = await database;
    await db.execute('''
      CREATE TABLE IF NOT EXISTS solar_vereffeningsrijen (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        solar_installation_id INTEGER NOT NULL,
        volgnummer INTEGER NOT NULL DEFAULT 1,
        omschrijving TEXT DEFAULT '',
        leiding_type TEXT DEFAULT '',
        leiding_mm2 TEXT DEFAULT '',
        rlow TEXT DEFAULT '',
        FOREIGN KEY (solar_installation_id) REFERENCES solar_installations (id) ON DELETE CASCADE
      )
    ''');
  }

  Future<void> _doEnsureInspectionDetailMethodeSchema() async {
    final db = await database;
    final cols = await db.rawQuery("PRAGMA table_info(inspection_details)");
    final existing = cols.map((c) => c['name'] as String).toSet();
    final toAdd = {
      'performed_according_to': "TEXT DEFAULT ''",
      'tested_against': "TEXT DEFAULT ''",
      'type_rapport': "TEXT DEFAULT ''",
      'inleiding': "TEXT DEFAULT ''",
      'methode_visuele_inspectie': "TEXT DEFAULT ''",
      'methode_metingen': "TEXT DEFAULT ''",
      'methode_aanvullend_onderzoek': "TEXT DEFAULT ''",
      'methode_criteria': "TEXT DEFAULT ''",
      'inleiding_toelichting': "TEXT DEFAULT ''",
      'aardingsstelsel': "TEXT DEFAULT ''",
      'netaansluiting': "TEXT DEFAULT ''",
      'hoofdaansluiting': "TEXT DEFAULT ''",
      'gebouwfunctie': "TEXT DEFAULT ''",
      'bijzondere_installatie': "TEXT DEFAULT ''",
      'bouwjaar': "TEXT DEFAULT ''",
      'oppervlakte': "TEXT DEFAULT ''",
    };
    for (final entry in toAdd.entries) {
      if (!existing.contains(entry.key)) {
        await db.execute(
          "ALTER TABLE inspection_details ADD COLUMN ${entry.key} ${entry.value}",
        );
      }
    }
  }

  Future<void> _doEnsureReportTemplatesSchema() async {
    final db = await database;
    await db.execute('''
      CREATE TABLE IF NOT EXISTS report_templates (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        type_rapport TEXT DEFAULT '',
        rapporttitel TEXT DEFAULT '',
        subtitel TEXT DEFAULT '',
        inleiding TEXT DEFAULT '',
        tekst_rapport_verklaring TEXT DEFAULT '',
        visuele_inspectie_titel TEXT DEFAULT '',
        visuele_inspectie TEXT DEFAULT '',
        visuele_inspectie_toelichting TEXT DEFAULT '',
        metingen_titel TEXT DEFAULT '',
        metingen TEXT DEFAULT '',
        metingen_toelichting TEXT DEFAULT '',
        aanvullend_onderzoek_titel TEXT DEFAULT '',
        aanvullend_onderzoek TEXT DEFAULT '',
        aanvullend_onderzoek_toelichting TEXT DEFAULT '',
        lijst4_titel TEXT DEFAULT '',
        lijst4 TEXT DEFAULT '',
        lijst4_toelichting TEXT DEFAULT '',
        vinklijst_afkeuringscriteria TEXT DEFAULT '',
        inspectie_uitgevoerd_volgens TEXT DEFAULT '',
        elektrisch_materieel_getoetst TEXT DEFAULT '',
        inleiding_toelichting TEXT DEFAULT '',
        volgend_inspectie TEXT DEFAULT '',
        eindbeoordeling_oke TEXT DEFAULT '',
        melding_gevaarlijke_situatie TEXT DEFAULT ''
      )
    ''');
    // Migrate existing tables that predate these columns
    final cols = await db.rawQuery("PRAGMA table_info(report_templates)");
    final existing = cols.map((c) => c['name'] as String).toSet();
    final toAdd = {
      'inspectie_uitgevoerd_volgens': "TEXT DEFAULT ''",
      'elektrisch_materieel_getoetst': "TEXT DEFAULT ''",
      'inleiding_toelichting': "TEXT DEFAULT ''",
      'volgend_inspectie': "TEXT DEFAULT ''",
      'eindbeoordeling_oke': "TEXT DEFAULT ''",
      'melding_gevaarlijke_situatie': "TEXT DEFAULT ''",
    };
    for (final entry in toAdd.entries) {
      if (!existing.contains(entry.key)) {
        await db.execute(
          "ALTER TABLE report_templates ADD COLUMN ${entry.key} ${entry.value}",
        );
      }
    }
    final count =
        Sqflite.firstIntValue(
          await db.rawQuery('SELECT COUNT(*) FROM report_templates'),
        ) ??
        0;
    if (count == 0) {
      await _seedReportTemplates(db);
    }
  }

  Future<void> _doEnsureMeasurementInstrumentsSchema() async {
    final db = await database;
    await db.execute('''
      CREATE TABLE IF NOT EXISTS measurement_instruments (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        inspector_id INTEGER,
        fabrikant TEXT DEFAULT '',
        model TEXT DEFAULT '',
        serienummer TEXT DEFAULT '',
        kalibratie_datum TEXT DEFAULT '',
        herkalibratie_datum TEXT DEFAULT '',
        certificaatnummer TEXT DEFAULT '',
        kalibratie_frequentie TEXT DEFAULT '',
        registratienummer TEXT DEFAULT '',
        status TEXT DEFAULT ''
      )
    ''');
    final cols = await db.rawQuery("PRAGMA table_info(general_data)");
    if (!cols.any((c) => c['name'] == 'measurement_instruments')) {
      await db.execute(
        "ALTER TABLE general_data ADD COLUMN measurement_instruments TEXT DEFAULT ''",
      );
    }
  }

  Future<void> _doEnsureCompanySchema() async {
    final db = await database;
    await db.execute('''
      CREATE TABLE IF NOT EXISTS company_details (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        company_name TEXT DEFAULT '',
        address TEXT DEFAULT '',
        postal_city TEXT DEFAULT '',
        phone TEXT DEFAULT '',
        email TEXT DEFAULT '',
        contact_person TEXT DEFAULT '',
        inspectors TEXT DEFAULT '',
        logo_path TEXT,
        logo_titelpagina_path TEXT
      )
    ''');
    final compCols = await db.rawQuery("PRAGMA table_info(company_details)");
    final compExisting = compCols.map((c) => c['name'] as String).toSet();
    if (!compExisting.contains('logo_titelpagina_path')) {
      await db.execute(
        "ALTER TABLE company_details ADD COLUMN logo_titelpagina_path TEXT",
      );
    }
    if (!compExisting.contains('logo_scios_path')) {
      await db.execute(
        "ALTER TABLE company_details ADD COLUMN logo_scios_path TEXT",
      );
    }
    if (!compExisting.contains('herstel_firebase_project_id')) {
      await db.execute(
        "ALTER TABLE company_details ADD COLUMN herstel_firebase_project_id TEXT DEFAULT ''",
      );
    }
    if (!compExisting.contains('herstel_firebase_storage_bucket')) {
      await db.execute(
        "ALTER TABLE company_details ADD COLUMN herstel_firebase_storage_bucket TEXT DEFAULT ''",
      );
    }
    if (!compExisting.contains('herstel_web_domain')) {
      await db.execute(
        "ALTER TABLE company_details ADD COLUMN herstel_web_domain TEXT DEFAULT ''",
      );
    }
    await _ensureCompanyInspectorsSchema();
  }

  Future<void> _doEnsureCompanyInspectorsSchema() async {
    final db = await database;
    await db.execute('''
      CREATE TABLE IF NOT EXISTS company_inspectors (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        functie TEXT DEFAULT '',
        handtekening TEXT DEFAULT ''
      )
    ''');

    // Add columns to existing tables that predate them
    final inspCols = await db.rawQuery("PRAGMA table_info(company_inspectors)");
    final inspColNames = inspCols.map((c) => c['name'] as String).toSet();
    if (!inspColNames.contains('functie')) {
      await db.execute(
        "ALTER TABLE company_inspectors ADD COLUMN functie TEXT DEFAULT ''",
      );
    }
    if (!inspColNames.contains('handtekening')) {
      await db.execute(
        "ALTER TABLE company_inspectors ADD COLUMN handtekening TEXT DEFAULT ''",
      );
    }

    // Migrate legacy inspectors text to the new list table (best-effort).
    final existingInspectors =
        Sqflite.firstIntValue(
          await db.rawQuery('SELECT COUNT(*) FROM company_inspectors'),
        ) ??
        0;
    if (existingInspectors > 0) return;

    final detailsColumns = await db.rawQuery(
      "PRAGMA table_info(company_details)",
    );
    if (detailsColumns.isEmpty) return;

    final legacy = await db.query('company_details', limit: 1);
    if (legacy.isEmpty) return;

    final legacyText = legacy.first['inspectors'] as String?;
    if (legacyText == null || legacyText.trim().isEmpty) return;

    final names = legacyText
        .split(RegExp(r'[,\n;]+'))
        .map((name) => name.trim())
        .where((name) => name.isNotEmpty)
        .toSet();
    for (final name in names) {
      await db.insert('company_inspectors', {'name': name, 'handtekening': ''});
    }
  }

  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'inspections.db');

    return await openDatabase(
      path,
      version: 23,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
      onOpen: _onOpen,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE inspections (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        status TEXT NOT NULL DEFAULT 'draft',
        sync_status TEXT NOT NULL DEFAULT 'pending'
      )
    ''');

    await db.execute('''
      CREATE TABLE title_pages (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        inspection_id INTEGER NOT NULL,
        title TEXT DEFAULT '',
        subtitle TEXT DEFAULT '',
        photo_path TEXT,
        logo_titelpagina_path TEXT,
        inspection_date TEXT DEFAULT '',
        inspection_date_end TEXT DEFAULT '',
        identification_code TEXT DEFAULT '',
        project_number TEXT DEFAULT '',
        title_x REAL NOT NULL DEFAULT 0.5,
        title_y REAL NOT NULL DEFAULT 0.15,
        title_w REAL NOT NULL DEFAULT 0.8,
        title_h REAL NOT NULL DEFAULT 0.1,
        photo_x REAL NOT NULL DEFAULT 0.5,
        photo_y REAL NOT NULL DEFAULT 0.5,
        photo_w REAL NOT NULL DEFAULT 0.6,
        photo_h REAL NOT NULL DEFAULT 0.35,
        date_x REAL NOT NULL DEFAULT 0.5,
        date_y REAL NOT NULL DEFAULT 0.78,
        date_w REAL NOT NULL DEFAULT 0.7,
        date_h REAL NOT NULL DEFAULT 0.065,
        code_x REAL NOT NULL DEFAULT 0.5,
        code_y REAL NOT NULL DEFAULT 0.86,
        code_w REAL NOT NULL DEFAULT 0.7,
        code_h REAL NOT NULL DEFAULT 0.065,
        project_x REAL NOT NULL DEFAULT 0.5,
        project_y REAL NOT NULL DEFAULT 0.93,
        project_w REAL NOT NULL DEFAULT 0.7,
        project_h REAL NOT NULL DEFAULT 0.065,
        subtitle_x REAL NOT NULL DEFAULT 0.5,
        subtitle_y REAL NOT NULL DEFAULT 0.26,
        subtitle_w REAL NOT NULL DEFAULT 0.70,
        subtitle_h REAL NOT NULL DEFAULT 0.07,
        logo_x REAL NOT NULL DEFAULT 0.82,
        logo_y REAL NOT NULL DEFAULT 0.07,
        logo_w REAL NOT NULL DEFAULT 0.30,
        logo_h REAL NOT NULL DEFAULT 0.12,
        address_name_x REAL NOT NULL DEFAULT 0.5,
        address_name_y REAL NOT NULL DEFAULT 0.72,
        address_name_w REAL NOT NULL DEFAULT 0.70,
        address_name_h REAL NOT NULL DEFAULT 0.065,
        show_scios_logo INTEGER NOT NULL DEFAULT 1,
        date_color_white INTEGER NOT NULL DEFAULT 0,
        code_color_white INTEGER NOT NULL DEFAULT 0,
        project_color_white INTEGER NOT NULL DEFAULT 0,
        FOREIGN KEY (inspection_id) REFERENCES inspections (id) ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS title_page_defaults (
        id INTEGER PRIMARY KEY CHECK (id = 1),
        title_x REAL NOT NULL DEFAULT 0.5,
        title_y REAL NOT NULL DEFAULT 0.15,
        title_w REAL NOT NULL DEFAULT 0.80,
        title_h REAL NOT NULL DEFAULT 0.10,
        subtitle_x REAL NOT NULL DEFAULT 0.5,
        subtitle_y REAL NOT NULL DEFAULT 0.26,
        subtitle_w REAL NOT NULL DEFAULT 0.70,
        subtitle_h REAL NOT NULL DEFAULT 0.07,
        photo_x REAL NOT NULL DEFAULT 0.5,
        photo_y REAL NOT NULL DEFAULT 0.50,
        photo_w REAL NOT NULL DEFAULT 0.60,
        photo_h REAL NOT NULL DEFAULT 0.35,
        date_x REAL NOT NULL DEFAULT 0.5,
        date_y REAL NOT NULL DEFAULT 0.78,
        date_w REAL NOT NULL DEFAULT 0.70,
        date_h REAL NOT NULL DEFAULT 0.065,
        code_x REAL NOT NULL DEFAULT 0.5,
        code_y REAL NOT NULL DEFAULT 0.86,
        code_w REAL NOT NULL DEFAULT 0.70,
        code_h REAL NOT NULL DEFAULT 0.065,
        project_x REAL NOT NULL DEFAULT 0.5,
        project_y REAL NOT NULL DEFAULT 0.93,
        project_w REAL NOT NULL DEFAULT 0.70,
        project_h REAL NOT NULL DEFAULT 0.065,
        logo_x REAL NOT NULL DEFAULT 0.82,
        logo_y REAL NOT NULL DEFAULT 0.07,
        logo_w REAL NOT NULL DEFAULT 0.30,
        logo_h REAL NOT NULL DEFAULT 0.12,
        address_name_x REAL NOT NULL DEFAULT 0.5,
        address_name_y REAL NOT NULL DEFAULT 0.72,
        address_name_w REAL NOT NULL DEFAULT 0.70,
        address_name_h REAL NOT NULL DEFAULT 0.065
      )
    ''');

    await db.execute('''
      CREATE TABLE general_data (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        inspection_id INTEGER NOT NULL,
        client_company TEXT DEFAULT '',
        client_address TEXT DEFAULT '',
        client_postal_city TEXT DEFAULT '',
        client_contact TEXT DEFAULT '',
        client_phone TEXT DEFAULT '',
        installation_responsible_name TEXT DEFAULT '',
        installation_responsible_phone TEXT DEFAULT '',
        inspection_address_name TEXT DEFAULT '',
        inspection_address_street TEXT DEFAULT '',
        inspection_address_postal_city TEXT DEFAULT '',
        inspection_address_contact TEXT DEFAULT '',
        inspection_address_phone TEXT DEFAULT '',
        inspector_company TEXT DEFAULT '',
        inspector_address TEXT DEFAULT '',
        inspector_postal_city TEXT DEFAULT '',
        inspector_phone TEXT DEFAULT '',
        inspector_email TEXT DEFAULT '',
        inspector_contact TEXT DEFAULT '',
        inspectors TEXT DEFAULT '',
        measurement_instruments TEXT DEFAULT '',
        FOREIGN KEY (inspection_id) REFERENCES inspections (id) ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE TABLE inspection_details (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        inspection_id INTEGER NOT NULL,
        scope_description TEXT DEFAULT '',
        not_inspected_parts TEXT DEFAULT '',
        not_inspected_reason TEXT DEFAULT '',
        inspection_reason TEXT DEFAULT '',
        performed_according_to TEXT DEFAULT '',
        tested_against TEXT DEFAULT '',
        type_rapport TEXT DEFAULT '',
        inleiding TEXT DEFAULT '',
        methode_visuele_inspectie TEXT DEFAULT '',
        methode_metingen TEXT DEFAULT '',
        methode_aanvullend_onderzoek TEXT DEFAULT '',
        methode_criteria TEXT DEFAULT '',
        inleiding_toelichting TEXT DEFAULT '',
        FOREIGN KEY (inspection_id) REFERENCES inspections (id) ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE TABLE switchboards (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        inspection_id INTEGER NOT NULL,
        name TEXT DEFAULT '',
        location TEXT DEFAULT '',
        system TEXT DEFAULT 'TN-S',
        short_circuit_current INTEGER,
        protection TEXT DEFAULT 'B 40 A',
        protection_class TEXT DEFAULT 'IP54',
        cable_cross_section INTEGER,
        cable_length INTEGER,
        main_switch_current INTEGER,
        main_switch_poles INTEGER,
        photo1_path TEXT,
        photo2_path TEXT,
        visual_inspection_json TEXT,
        measurements_json TEXT,
        opmerking TEXT DEFAULT '',
        FOREIGN KEY (inspection_id) REFERENCES inspections (id) ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE TABLE solar_installations (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        inspection_id INTEGER NOT NULL,
        location TEXT DEFAULT '',
        panel_sublocation TEXT DEFAULT '',
        panel_count INTEGER,
        inverter_count INTEGER,
        watt_peak INTEGER,
        construction_type TEXT DEFAULT '',
        photo_roof1_path TEXT,
        photo_roof2_path TEXT,
        photo_inverter1_path TEXT,
        photo_inverter2_path TEXT,
        FOREIGN KEY (inspection_id) REFERENCES inspections (id) ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE TABLE defects (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        inspection_id INTEGER NOT NULL,
        location TEXT DEFAULT '',
        classification TEXT DEFAULT 'Ge',
        description TEXT DEFAULT '',
        photo1_path TEXT,
        photo2_path TEXT,
        has_annotations INTEGER NOT NULL DEFAULT 0,
        scope8 INTEGER NOT NULL DEFAULT 0,
        scope10 INTEGER NOT NULL DEFAULT 0,
        scope12 INTEGER NOT NULL DEFAULT 0,
        scope_eos INTEGER NOT NULL DEFAULT 0,
        FOREIGN KEY (inspection_id) REFERENCES inspections (id) ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE TABLE defect_annotations (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        defect_id INTEGER NOT NULL,
        photo_number INTEGER NOT NULL DEFAULT 1,
        x REAL NOT NULL DEFAULT 0.0,
        y REAL NOT NULL DEFAULT 0.0,
        width REAL NOT NULL DEFAULT 0.1,
        height REAL NOT NULL DEFAULT 0.1,
        label TEXT DEFAULT '',
        color TEXT DEFAULT 'Ge',
        order_number INTEGER NOT NULL DEFAULT 1,
        shape TEXT NOT NULL DEFAULT 'rect',
        FOREIGN KEY (defect_id) REFERENCES defects (id) ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE TABLE standards (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        category TEXT NOT NULL,
        value TEXT NOT NULL,
        display_name TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE measurement_instruments (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        inspector_id INTEGER,
        fabrikant TEXT DEFAULT '',
        model TEXT DEFAULT '',
        serienummer TEXT DEFAULT '',
        kalibratie_datum TEXT DEFAULT '',
        herkalibratie_datum TEXT DEFAULT '',
        certificaatnummer TEXT DEFAULT '',
        kalibratie_frequentie TEXT DEFAULT '',
        registratienummer TEXT DEFAULT '',
        status TEXT DEFAULT ''
      )
    ''');

    await db.execute('''
      CREATE TABLE report_templates (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        type_rapport TEXT DEFAULT '',
        rapporttitel TEXT DEFAULT '',
        subtitel TEXT DEFAULT '',
        inleiding TEXT DEFAULT '',
        tekst_rapport_verklaring TEXT DEFAULT '',
        visuele_inspectie_titel TEXT DEFAULT '',
        visuele_inspectie TEXT DEFAULT '',
        visuele_inspectie_toelichting TEXT DEFAULT '',
        metingen_titel TEXT DEFAULT '',
        metingen TEXT DEFAULT '',
        metingen_toelichting TEXT DEFAULT '',
        aanvullend_onderzoek_titel TEXT DEFAULT '',
        aanvullend_onderzoek TEXT DEFAULT '',
        aanvullend_onderzoek_toelichting TEXT DEFAULT '',
        lijst4_titel TEXT DEFAULT '',
        lijst4 TEXT DEFAULT '',
        lijst4_toelichting TEXT DEFAULT '',
        vinklijst_afkeuringscriteria TEXT DEFAULT ''
      )
    ''');

    await db.execute('''
      CREATE TABLE steekproef_items (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        inspection_id INTEGER NOT NULL,
        beschrijving TEXT DEFAULT '',
        omvang_partij INTEGER NOT NULL,
        steekproef INTEGER NOT NULL,
        g INTEGER NOT NULL,
        f INTEGER NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE rapport_constateringen (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        groep TEXT DEFAULT '',
        beschrijving TEXT DEFAULT '',
        tekst TEXT DEFAULT '',
        kwalificatie TEXT DEFAULT 'Ge',
        norm TEXT DEFAULT '',
        toelichting TEXT DEFAULT ''
      )
    ''');

    await db.execute('''
      CREATE TABLE tekeningen (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        inspection_id INTEGER NOT NULL,
        naam TEXT DEFAULT '',
        bestand_pad TEXT DEFAULT '',
        bestand_type TEXT DEFAULT '',
        FOREIGN KEY (inspection_id) REFERENCES inspections (id) ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE TABLE tekening_pins (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        tekening_id INTEGER NOT NULL,
        x REAL NOT NULL DEFAULT 0.5,
        y REAL NOT NULL DEFAULT 0.5,
        kleur TEXT DEFAULT 'Gr',
        type TEXT DEFAULT 'notitie',
        defect_id INTEGER,
        meting_type TEXT DEFAULT '',
        meting_waarde TEXT DEFAULT '',
        meting_eenheid TEXT DEFAULT 'Ω',
        label TEXT DEFAULT '',
        volgnummer INTEGER NOT NULL DEFAULT 1,
        FOREIGN KEY (tekening_id) REFERENCES tekeningen (id) ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE TABLE measurement_groups (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        inspection_id INTEGER NOT NULL,
        switchboard_id INTEGER,
        bron_bestand TEXT DEFAULT '',
        label TEXT DEFAULT '',
        groep_nummer TEXT DEFAULT '',
        punt_nummer TEXT DEFAULT '',
        omschrijving TEXT DEFAULT '',
        volgorde INTEGER NOT NULL DEFAULT 0,
        FOREIGN KEY (inspection_id) REFERENCES inspections (id) ON DELETE CASCADE,
        FOREIGN KEY (switchboard_id) REFERENCES switchboards (id) ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE TABLE measurement_readings (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        group_id INTEGER NOT NULL,
        punt_nummer TEXT DEFAULT '',
        meting_type TEXT DEFAULT '',
        waarden_json TEXT DEFAULT '',
        volgorde INTEGER NOT NULL DEFAULT 0,
        FOREIGN KEY (group_id) REFERENCES measurement_groups (id) ON DELETE CASCADE
      )
    ''');

    await _insertDefaultStandards(db);
  }

  Future<void> _onOpen(Database db) async {
    // Defensively ensure the annotation schema exists using IF NOT EXISTS
    // to avoid errors when called alongside _ensureAnnotationSchema.
    await db.execute('''
      CREATE TABLE IF NOT EXISTS defect_annotations (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        defect_id INTEGER NOT NULL,
        photo_number INTEGER NOT NULL DEFAULT 1,
        x REAL NOT NULL DEFAULT 0.0,
        y REAL NOT NULL DEFAULT 0.0,
        width REAL NOT NULL DEFAULT 0.1,
        height REAL NOT NULL DEFAULT 0.1,
        label TEXT DEFAULT '',
        color TEXT DEFAULT 'Ge',
        order_number INTEGER NOT NULL DEFAULT 1,
        shape TEXT NOT NULL DEFAULT 'rect',
        FOREIGN KEY (defect_id) REFERENCES defects (id) ON DELETE CASCADE
      )
    ''');
    final cols = await db.rawQuery("PRAGMA table_info(defects)");
    if (!cols.any((c) => c['name'] == 'has_annotations')) {
      await db.execute(
        "ALTER TABLE defects ADD COLUMN has_annotations INTEGER NOT NULL DEFAULT 0",
      );
    }
    final annotationCols = await db.rawQuery(
      "PRAGMA table_info(defect_annotations)",
    );
    if (!annotationCols.any((c) => c['name'] == 'shape')) {
      await db.execute(
        "ALTER TABLE defect_annotations ADD COLUMN shape TEXT NOT NULL DEFAULT 'rect'",
      );
    }
    for (final col in ['scope8', 'scope10', 'scope12', 'scope_eos']) {
      if (!cols.any((c) => c['name'] == col)) {
        await db.execute(
          "ALTER TABLE defects ADD COLUMN $col INTEGER NOT NULL DEFAULT 0",
        );
      }
    }
    for (final col in [
      'location_a',
      'location_b',
      'toelichting',
      'installation_component',
      'naam_code',
    ]) {
      if (!cols.any((c) => c['name'] == col)) {
        await db.execute(
          "ALTER TABLE defects ADD COLUMN $col TEXT NOT NULL DEFAULT ''",
        );
      }
    }
    // Ensure title_page_defaults table exists (for databases created before this feature).
    await db.execute('''
      CREATE TABLE IF NOT EXISTS title_page_defaults (
        id INTEGER PRIMARY KEY CHECK (id = 1),
        title_x REAL NOT NULL DEFAULT 0.5,    title_y REAL NOT NULL DEFAULT 0.15,
        title_w REAL NOT NULL DEFAULT 0.80,   title_h REAL NOT NULL DEFAULT 0.10,
        subtitle_x REAL NOT NULL DEFAULT 0.5, subtitle_y REAL NOT NULL DEFAULT 0.26,
        subtitle_w REAL NOT NULL DEFAULT 0.70,subtitle_h REAL NOT NULL DEFAULT 0.07,
        photo_x REAL NOT NULL DEFAULT 0.5,    photo_y REAL NOT NULL DEFAULT 0.50,
        photo_w REAL NOT NULL DEFAULT 0.60,   photo_h REAL NOT NULL DEFAULT 0.35,
        date_x REAL NOT NULL DEFAULT 0.5,     date_y REAL NOT NULL DEFAULT 0.78,
        date_w REAL NOT NULL DEFAULT 0.70,    date_h REAL NOT NULL DEFAULT 0.065,
        code_x REAL NOT NULL DEFAULT 0.5,     code_y REAL NOT NULL DEFAULT 0.86,
        code_w REAL NOT NULL DEFAULT 0.70,    code_h REAL NOT NULL DEFAULT 0.065,
        project_x REAL NOT NULL DEFAULT 0.5,  project_y REAL NOT NULL DEFAULT 0.93,
        project_w REAL NOT NULL DEFAULT 0.70, project_h REAL NOT NULL DEFAULT 0.065,
        logo_x REAL NOT NULL DEFAULT 0.82,    logo_y REAL NOT NULL DEFAULT 0.07,
        logo_w REAL NOT NULL DEFAULT 0.30,    logo_h REAL NOT NULL DEFAULT 0.12
      )
    ''');
    // Ensure title_page_defaults has all current columns.
    final defCols = await db.rawQuery("PRAGMA table_info(title_page_defaults)");
    if (defCols.isNotEmpty) {
      final defExisting = defCols.map((c) => c['name'] as String).toSet();
      const defToAdd = {
        'address_name_x': 'REAL NOT NULL DEFAULT 0.5',
        'address_name_y': 'REAL NOT NULL DEFAULT 0.72',
        'address_name_w': 'REAL NOT NULL DEFAULT 0.70',
        'address_name_h': 'REAL NOT NULL DEFAULT 0.065',
      };
      for (final entry in defToAdd.entries) {
        if (!defExisting.contains(entry.key)) {
          await db.execute(
            "ALTER TABLE title_page_defaults ADD COLUMN ${entry.key} ${entry.value}",
          );
        }
      }
    }
    // Ensure title_pages has all current columns.
    final titleCols = await db.rawQuery("PRAGMA table_info(title_pages)");
    if (titleCols.isNotEmpty) {
      final titleExisting = titleCols.map((c) => c['name'] as String).toSet();
      const titleToAdd = {
        'logo_titelpagina_path': 'TEXT',
        'inspection_date_end': "TEXT NOT NULL DEFAULT ''",
        'subtitle_x': 'REAL NOT NULL DEFAULT 0.5',
        'subtitle_y': 'REAL NOT NULL DEFAULT 0.26',
        'subtitle_w': 'REAL NOT NULL DEFAULT 0.70',
        'subtitle_h': 'REAL NOT NULL DEFAULT 0.07',
        'logo_x': 'REAL NOT NULL DEFAULT 0.82',
        'logo_y': 'REAL NOT NULL DEFAULT 0.07',
        'logo_w': 'REAL NOT NULL DEFAULT 0.30',
        'logo_h': 'REAL NOT NULL DEFAULT 0.12',
        'address_name_x': 'REAL NOT NULL DEFAULT 0.5',
        'address_name_y': 'REAL NOT NULL DEFAULT 0.72',
        'address_name_w': 'REAL NOT NULL DEFAULT 0.70',
        'address_name_h': 'REAL NOT NULL DEFAULT 0.065',
      };
      for (final entry in titleToAdd.entries) {
        if (!titleExisting.contains(entry.key)) {
          await db.execute(
            "ALTER TABLE title_pages ADD COLUMN ${entry.key} ${entry.value}",
          );
        }
      }
    }
    // Seed location standards for databases created before this category was added.
    final locCount =
        Sqflite.firstIntValue(
          await db.rawQuery(
            "SELECT COUNT(*) FROM standards WHERE category = 'location'",
          ),
        ) ??
        0;
    if (locCount == 0) {
      final batch = db.batch();
      for (final s in _defaultLocationStandards) {
        batch.insert('standards', s);
      }
      await batch.commit(noResult: true);
    }
    final locACount =
        Sqflite.firstIntValue(
          await db.rawQuery(
            "SELECT COUNT(*) FROM standards WHERE category = 'location_a'",
          ),
        ) ??
        0;
    if (locACount == 0) {
      final batch = db.batch();
      for (final s in _defaultLocationAStandards) {
        batch.insert('standards', s);
      }
      await batch.commit(noResult: true);
    }
    final locBCount =
        Sqflite.firstIntValue(
          await db.rawQuery(
            "SELECT COUNT(*) FROM standards WHERE category = 'location_b'",
          ),
        ) ??
        0;
    if (locBCount == 0) {
      final batch = db.batch();
      for (final s in _defaultLocationBStandards) {
        batch.insert('standards', s);
      }
      await batch.commit(noResult: true);
    }
    // Seed karakteristiek standards for databases created before this category was added.
    final karakteristiekCount =
        Sqflite.firstIntValue(
          await db.rawQuery(
            "SELECT COUNT(*) FROM standards WHERE category = 'karakteristiek'",
          ),
        ) ??
        0;
    if (karakteristiekCount == 0) {
      final batch = db.batch();
      for (final s in _defaultKarakteristiekStandards) {
        batch.insert('standards', s);
      }
      await batch.commit(noResult: true);
    }
    // Ensure steekproef_items table exists for databases created before this feature.
    await db.execute('''
      CREATE TABLE IF NOT EXISTS steekproef_items (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        inspection_id INTEGER NOT NULL,
        beschrijving TEXT DEFAULT '',
        omvang_partij INTEGER NOT NULL,
        steekproef INTEGER NOT NULL,
        g INTEGER NOT NULL,
        f INTEGER NOT NULL
      )
    ''');
    // Ensure rapport_constateringen table exists for databases created before this feature.
    await db.execute('''
      CREATE TABLE IF NOT EXISTS rapport_constateringen (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        groep TEXT DEFAULT '',
        beschrijving TEXT DEFAULT '',
        tekst TEXT DEFAULT '',
        kwalificatie TEXT DEFAULT 'Ge',
        norm TEXT DEFAULT '',
        toelichting TEXT DEFAULT ''
      )
    ''');
    // Ensure tekeningen tables exist for databases created before this feature.
    await db.execute('''
      CREATE TABLE IF NOT EXISTS tekeningen (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        inspection_id INTEGER NOT NULL,
        naam TEXT DEFAULT '',
        bestand_pad TEXT DEFAULT '',
        bestand_type TEXT DEFAULT '',
        FOREIGN KEY (inspection_id) REFERENCES inspections (id) ON DELETE CASCADE
      )
    ''');
    await db.execute('''
      CREATE TABLE IF NOT EXISTS tekening_pins (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        tekening_id INTEGER NOT NULL,
        x REAL NOT NULL DEFAULT 0.5,
        y REAL NOT NULL DEFAULT 0.5,
        kleur TEXT DEFAULT 'Gr',
        type TEXT DEFAULT 'notitie',
        defect_id INTEGER,
        meting_type TEXT DEFAULT '',
        meting_waarde TEXT DEFAULT '',
        meting_eenheid TEXT DEFAULT 'Ω',
        label TEXT DEFAULT '',
        volgnummer INTEGER NOT NULL DEFAULT 1,
        FOREIGN KEY (tekening_id) REFERENCES tekeningen (id) ON DELETE CASCADE
      )
    ''');
    // Ensure herstel table exists.
    await db.execute('''
      CREATE TABLE IF NOT EXISTS herstel (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        defect_id INTEGER NOT NULL,
        is_hersteld INTEGER NOT NULL DEFAULT 0,
        datum TEXT DEFAULT '',
        naam TEXT DEFAULT '',
        photo1_path TEXT,
        photo2_path TEXT,
        toelichting TEXT DEFAULT '',
        FOREIGN KEY (defect_id) REFERENCES defects (id) ON DELETE CASCADE
      )
    ''');
    // Ensure herstel has a herstel_token column (for external QR herstel-submissions).
    final herstelCols = await db.rawQuery("PRAGMA table_info(herstel)");
    if (!herstelCols.any((c) => c['name'] == 'herstel_token')) {
      await db.execute("ALTER TABLE herstel ADD COLUMN herstel_token TEXT");
    }
    // Ensure solar_vereffeningsrijen table exists for databases created before this feature.
    await db.execute('''
      CREATE TABLE IF NOT EXISTS solar_vereffeningsrijen (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        solar_installation_id INTEGER NOT NULL,
        volgnummer INTEGER NOT NULL DEFAULT 1,
        omschrijving TEXT DEFAULT '',
        leiding_type TEXT DEFAULT '',
        leiding_mm2 TEXT DEFAULT '',
        rlow TEXT DEFAULT '',
        FOREIGN KEY (solar_installation_id) REFERENCES solar_installations (id) ON DELETE CASCADE
      )
    ''');
    // Ensure measurement_groups/measurement_readings tables exist for databases
    // created before this feature.
    await db.execute('''
      CREATE TABLE IF NOT EXISTS measurement_groups (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        inspection_id INTEGER NOT NULL,
        switchboard_id INTEGER,
        bron_bestand TEXT DEFAULT '',
        label TEXT DEFAULT '',
        groep_nummer TEXT DEFAULT '',
        punt_nummer TEXT DEFAULT '',
        omschrijving TEXT DEFAULT '',
        volgorde INTEGER NOT NULL DEFAULT 0,
        FOREIGN KEY (inspection_id) REFERENCES inspections (id) ON DELETE CASCADE,
        FOREIGN KEY (switchboard_id) REFERENCES switchboards (id) ON DELETE CASCADE
      )
    ''');
    // Ensure measurement_groups has the switchboard_id column for databases
    // created before verdeler-scoped metingen existed.
    final measurementGroupCols =
        await db.rawQuery("PRAGMA table_info(measurement_groups)");
    if (measurementGroupCols.isNotEmpty &&
        !measurementGroupCols.any((c) => c['name'] == 'switchboard_id')) {
      await db.execute(
        "ALTER TABLE measurement_groups ADD COLUMN switchboard_id INTEGER",
      );
    }
    await db.execute('''
      CREATE TABLE IF NOT EXISTS measurement_readings (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        group_id INTEGER NOT NULL,
        punt_nummer TEXT DEFAULT '',
        meting_type TEXT DEFAULT '',
        waarden_json TEXT DEFAULT '',
        volgorde INTEGER NOT NULL DEFAULT 0,
        FOREIGN KEY (group_id) REFERENCES measurement_groups (id) ON DELETE CASCADE
      )
    ''');
    // Ensure company_details has logo_titelpagina_path column.
    final compCols = await db.rawQuery("PRAGMA table_info(company_details)");
    if (compCols.isNotEmpty &&
        !compCols.any((c) => c['name'] == 'logo_titelpagina_path')) {
      await db.execute(
        "ALTER TABLE company_details ADD COLUMN logo_titelpagina_path TEXT",
      );
    }
    // Ensure inspection_details has all current columns (guards against both
    // old databases and the previous race-condition that could skip _onUpgrade).
    final detailCols = await db.rawQuery(
      "PRAGMA table_info(inspection_details)",
    );
    final detailExisting = detailCols.map((c) => c['name'] as String).toSet();
    const detailToAdd = {
      'type_rapport': "TEXT DEFAULT ''",
      'inleiding': "TEXT DEFAULT ''",
      'methode_visuele_inspectie': "TEXT DEFAULT ''",
      'methode_metingen': "TEXT DEFAULT ''",
      'methode_aanvullend_onderzoek': "TEXT DEFAULT ''",
      'methode_criteria': "TEXT DEFAULT ''",
      'inleiding_toelichting': "TEXT DEFAULT ''",
      'aardingsstelsel': "TEXT DEFAULT ''",
      'netaansluiting': "TEXT DEFAULT ''",
      'hoofdaansluiting': "TEXT DEFAULT ''",
      'gebouwfunctie': "TEXT DEFAULT ''",
      'bijzondere_installatie': "TEXT DEFAULT ''",
      'bouwjaar': "TEXT DEFAULT ''",
      'oppervlakte': "TEXT DEFAULT ''",
    };
    for (final entry in detailToAdd.entries) {
      if (!detailExisting.contains(entry.key)) {
        await db.execute(
          "ALTER TABLE inspection_details ADD COLUMN ${entry.key} ${entry.value}",
        );
      }
    }
    // Ensure switchboards has all current columns.
    final sbCols = await db.rawQuery("PRAGMA table_info(switchboards)");
    if (sbCols.isNotEmpty) {
      final sbExisting = sbCols.map((c) => c['name'] as String).toSet();
      const sbToAdd = {
        'electrical_measurements_json': "TEXT DEFAULT ''",
        'cable_type': 'TEXT',
        'location_a': "TEXT NOT NULL DEFAULT ''",
        'location_b': "TEXT NOT NULL DEFAULT ''",
        'installation_component': "TEXT NOT NULL DEFAULT ''",
        'hoofdschakelaars_json': "TEXT DEFAULT ''",
        'beschermingsklasse': "TEXT NOT NULL DEFAULT ''",
        'opmerking': "TEXT DEFAULT ''",
      };
      for (final entry in sbToAdd.entries) {
        if (!sbExisting.contains(entry.key)) {
          await db.execute(
            'ALTER TABLE switchboards ADD COLUMN ${entry.key} ${entry.value}',
          );
        }
      }
    }
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute(
        "ALTER TABLE defects ADD COLUMN has_annotations INTEGER NOT NULL DEFAULT 0",
      );
      await db.execute('''
        CREATE TABLE defect_annotations (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          defect_id INTEGER NOT NULL,
          photo_number INTEGER NOT NULL DEFAULT 1,
          x REAL NOT NULL DEFAULT 0.0,
          y REAL NOT NULL DEFAULT 0.0,
          width REAL NOT NULL DEFAULT 0.1,
          height REAL NOT NULL DEFAULT 0.1,
          label TEXT DEFAULT '',
          color TEXT DEFAULT 'Ge',
          order_number INTEGER NOT NULL DEFAULT 1,
          shape TEXT NOT NULL DEFAULT 'rect',
          FOREIGN KEY (defect_id) REFERENCES defects (id) ON DELETE CASCADE
        )
      ''');
    }
    if (oldVersion < 3) {
      final titleCols = await db.rawQuery("PRAGMA table_info(title_pages)");
      final colNames = titleCols.map((c) => c['name'] as String).toSet();
      if (!colNames.contains('title_x')) {
        await db.execute(
          "ALTER TABLE title_pages ADD COLUMN title_x REAL NOT NULL DEFAULT 0.5",
        );
      }
      if (!colNames.contains('title_y')) {
        await db.execute(
          "ALTER TABLE title_pages ADD COLUMN title_y REAL NOT NULL DEFAULT 0.15",
        );
      }
      if (!colNames.contains('photo_x')) {
        await db.execute(
          "ALTER TABLE title_pages ADD COLUMN photo_x REAL NOT NULL DEFAULT 0.5",
        );
      }
      if (!colNames.contains('photo_y')) {
        await db.execute(
          "ALTER TABLE title_pages ADD COLUMN photo_y REAL NOT NULL DEFAULT 0.5",
        );
      }
    }
    if (oldVersion < 4) {
      final titleCols = await db.rawQuery("PRAGMA table_info(title_pages)");
      final colNames = titleCols.map((c) => c['name'] as String).toSet();
      if (!colNames.contains('date_x')) {
        await db.execute(
          "ALTER TABLE title_pages ADD COLUMN date_x REAL NOT NULL DEFAULT 0.5",
        );
      }
      if (!colNames.contains('date_y')) {
        await db.execute(
          "ALTER TABLE title_pages ADD COLUMN date_y REAL NOT NULL DEFAULT 0.78",
        );
      }
      if (!colNames.contains('code_x')) {
        await db.execute(
          "ALTER TABLE title_pages ADD COLUMN code_x REAL NOT NULL DEFAULT 0.5",
        );
      }
      if (!colNames.contains('code_y')) {
        await db.execute(
          "ALTER TABLE title_pages ADD COLUMN code_y REAL NOT NULL DEFAULT 0.86",
        );
      }
      if (!colNames.contains('project_x')) {
        await db.execute(
          "ALTER TABLE title_pages ADD COLUMN project_x REAL NOT NULL DEFAULT 0.5",
        );
      }
      if (!colNames.contains('project_y')) {
        await db.execute(
          "ALTER TABLE title_pages ADD COLUMN project_y REAL NOT NULL DEFAULT 0.93",
        );
      }
    }
    if (oldVersion < 5) {
      final titleCols = await db.rawQuery("PRAGMA table_info(title_pages)");
      final colNames = titleCols.map((c) => c['name'] as String).toSet();
      final sizeAlters = <String, String>{
        'title_w': '0.8',
        'title_h': '0.1',
        'photo_w': '0.6',
        'photo_h': '0.35',
        'date_w': '0.7',
        'date_h': '0.065',
        'code_w': '0.7',
        'code_h': '0.065',
        'project_w': '0.7',
        'project_h': '0.065',
      };
      for (final entry in sizeAlters.entries) {
        if (!colNames.contains(entry.key)) {
          await db.execute(
            "ALTER TABLE title_pages ADD COLUMN ${entry.key} REAL NOT NULL DEFAULT ${entry.value}",
          );
        }
      }
    }
    if (oldVersion < 7) {
      final titleCols = await db.rawQuery("PRAGMA table_info(title_pages)");
      if (!titleCols.any((c) => c['name'] == 'subtitle')) {
        await db.execute(
          "ALTER TABLE title_pages ADD COLUMN subtitle TEXT DEFAULT ''",
        );
      }
    }
    if (oldVersion < 6) {
      final generalCols = await db.rawQuery("PRAGMA table_info(general_data)");
      if (!generalCols.any((c) => c['name'] == 'measurement_instruments')) {
        await db.execute(
          "ALTER TABLE general_data ADD COLUMN measurement_instruments TEXT DEFAULT ''",
        );
      }
      await db.execute('''
        CREATE TABLE IF NOT EXISTS measurement_instruments (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          inspector_id INTEGER,
          fabrikant TEXT DEFAULT '',
          model TEXT DEFAULT '',
          serienummer TEXT DEFAULT '',
          kalibratie_datum TEXT DEFAULT '',
          herkalibratie_datum TEXT DEFAULT '',
          certificaatnummer TEXT DEFAULT '',
          kalibratie_frequentie TEXT DEFAULT '',
          registratienummer TEXT DEFAULT '',
          status TEXT DEFAULT ''
        )
      ''');
    }
    if (oldVersion < 8) {
      final detailCols = await db.rawQuery(
        "PRAGMA table_info(inspection_details)",
      );
      final existing = detailCols.map((c) => c['name'] as String).toSet();
      final toAdd = {
        'type_rapport': "TEXT DEFAULT ''",
        'inleiding': "TEXT DEFAULT ''",
        'methode_visuele_inspectie': "TEXT DEFAULT ''",
        'methode_metingen': "TEXT DEFAULT ''",
        'methode_aanvullend_onderzoek': "TEXT DEFAULT ''",
        'methode_criteria': "TEXT DEFAULT ''",
        'inleiding_toelichting': "TEXT DEFAULT ''",
      };
      for (final entry in toAdd.entries) {
        if (!existing.contains(entry.key)) {
          await db.execute(
            "ALTER TABLE inspection_details ADD COLUMN ${entry.key} ${entry.value}",
          );
        }
      }
    }
    if (oldVersion < 9) {
      final titleCols = await db.rawQuery("PRAGMA table_info(title_pages)");
      final existing = titleCols.map((c) => c['name'] as String).toSet();
      const toAdd = {
        'address_name_x': 'REAL NOT NULL DEFAULT 0.5',
        'address_name_y': 'REAL NOT NULL DEFAULT 0.72',
        'address_name_w': 'REAL NOT NULL DEFAULT 0.70',
        'address_name_h': 'REAL NOT NULL DEFAULT 0.065',
      };
      for (final entry in toAdd.entries) {
        if (!existing.contains(entry.key)) {
          await db.execute(
            "ALTER TABLE title_pages ADD COLUMN ${entry.key} ${entry.value}",
          );
        }
      }
      final defCols = await db.rawQuery(
        "PRAGMA table_info(title_page_defaults)",
      );
      final defExisting = defCols.map((c) => c['name'] as String).toSet();
      for (final entry in toAdd.entries) {
        if (!defExisting.contains(entry.key)) {
          await db.execute(
            "ALTER TABLE title_page_defaults ADD COLUMN ${entry.key} ${entry.value}",
          );
        }
      }
    }
    if (oldVersion < 10) {
      final existing = await db.query(
        'standards',
        where: 'category = ?',
        whereArgs: ['cable_type'],
      );
      if (existing.isEmpty) {
        final batch = db.batch();
        for (final s in _defaultCableTypeStandards) {
          batch.insert('standards', s);
        }
        await batch.commit(noResult: true);
      }
    }
    if (oldVersion < 11) {
      final defectCols = await db.rawQuery("PRAGMA table_info(defects)");
      final defectExisting = defectCols.map((c) => c['name'] as String).toSet();
      for (final col in ['scope8', 'scope10', 'scope12', 'scope_eos']) {
        if (!defectExisting.contains(col)) {
          await db.execute(
            "ALTER TABLE defects ADD COLUMN $col INTEGER NOT NULL DEFAULT 0",
          );
        }
      }
    }
    if (oldVersion < 12) {
      final existing = await db.query(
        'standards',
        where: 'category = ?',
        whereArgs: ['aarding'],
      );
      if (existing.isEmpty) {
        final batch = db.batch();
        for (final s in _defaultAardingStandards) {
          batch.insert('standards', s);
        }
        await batch.commit(noResult: true);
      }
    }
    if (oldVersion < 13) {
      final cols = await db.rawQuery("PRAGMA table_info(title_pages)");
      final existing = cols.map((c) => c['name'] as String).toSet();
      if (!existing.contains('inspection_date_end')) {
        await db.execute(
          "ALTER TABLE title_pages ADD COLUMN inspection_date_end TEXT NOT NULL DEFAULT ''",
        );
      }
    }
    if (oldVersion < 14) {
      final existing = await db.query(
        'standards',
        where: 'category = ?',
        whereArgs: ['inspection_reason'],
      );
      if (existing.isEmpty) {
        final batch = db.batch();
        for (final s in _defaultInspectionReasonStandards) {
          batch.insert('standards', s);
        }
        await batch.commit(noResult: true);
      }
    }
    if (oldVersion < 15) {
      final sbCols = await db.rawQuery("PRAGMA table_info(switchboards)");
      if (!sbCols.any((c) => c['name'] == 'hoofdschakelaars_json')) {
        await db.execute(
          "ALTER TABLE switchboards ADD COLUMN hoofdschakelaars_json TEXT DEFAULT ''",
        );
      }
    }
    if (oldVersion < 16) {
      final sbCols = await db.rawQuery("PRAGMA table_info(switchboards)");
      if (!sbCols.any((c) => c['name'] == 'beschermingsklasse')) {
        await db.execute(
          "ALTER TABLE switchboards ADD COLUMN beschermingsklasse TEXT NOT NULL DEFAULT ''",
        );
      }
    }
    if (oldVersion < 17) {
      final tpCols = await db.rawQuery("PRAGMA table_info(title_pages)");
      if (!tpCols.any((c) => c['name'] == 'show_scios_logo')) {
        await db.execute(
          "ALTER TABLE title_pages ADD COLUMN show_scios_logo INTEGER NOT NULL DEFAULT 1",
        );
      }
    }
    if (oldVersion < 18) {
      final defectCols = await db.rawQuery("PRAGMA table_info(defects)");
      for (final col in ['installation_component', 'naam_code']) {
        if (!defectCols.any((c) => c['name'] == col)) {
          await db.execute(
            "ALTER TABLE defects ADD COLUMN $col TEXT NOT NULL DEFAULT ''",
          );
        }
      }
    }
    if (oldVersion < 19) {
      final annotationCols = await db.rawQuery(
        "PRAGMA table_info(defect_annotations)",
      );
      if (!annotationCols.any((c) => c['name'] == 'shape')) {
        await db.execute(
          "ALTER TABLE defect_annotations ADD COLUMN shape TEXT NOT NULL DEFAULT 'rect'",
        );
      }
    }
    if (oldVersion < 20) {
      final cols = await db.rawQuery("PRAGMA table_info(title_pages)");
      final existing = cols.map((c) => c['name'] as String).toSet();
      const toAdd = {
        'date_color_white': 'INTEGER NOT NULL DEFAULT 0',
        'code_color_white': 'INTEGER NOT NULL DEFAULT 0',
        'project_color_white': 'INTEGER NOT NULL DEFAULT 0',
      };
      for (final entry in toAdd.entries) {
        if (!existing.contains(entry.key)) {
          await db.execute(
            "ALTER TABLE title_pages ADD COLUMN ${entry.key} ${entry.value}",
          );
        }
      }
    }
    if (oldVersion < 21) {
      final generalCols = await db.rawQuery("PRAGMA table_info(general_data)");
      if (!generalCols.any((c) => c['name'] == 'client_phone')) {
        await db.execute(
          "ALTER TABLE general_data ADD COLUMN client_phone TEXT DEFAULT ''",
        );
      }
    }
    if (oldVersion < 22) {
      final generalCols = await db.rawQuery("PRAGMA table_info(general_data)");
      if (!generalCols.any((c) => c['name'] == 'inspection_address_phone')) {
        await db.execute(
          "ALTER TABLE general_data ADD COLUMN inspection_address_phone TEXT DEFAULT ''",
        );
      }
    }
    if (oldVersion < 23) {
      final generalCols = await db.rawQuery("PRAGMA table_info(general_data)");
      final existing = generalCols.map((c) => c['name'] as String).toSet();
      if (!existing.contains('installation_responsible_name')) {
        await db.execute(
          "ALTER TABLE general_data ADD COLUMN installation_responsible_name TEXT DEFAULT ''",
        );
      }
      if (!existing.contains('installation_responsible_phone')) {
        await db.execute(
          "ALTER TABLE general_data ADD COLUMN installation_responsible_phone TEXT DEFAULT ''",
        );
      }
    }
  }

  static const _defaultCableTypeStandards = [
    {'category': 'cable_type', 'value': 'ALU-as', 'display_name': 'ALU-as'},
    {'category': 'cable_type', 'value': 'H07RNF', 'display_name': 'H07RNF'},
    {'category': 'cable_type', 'value': 'NYCWY', 'display_name': 'NYCWY'},
    {'category': 'cable_type', 'value': 'NYY-J', 'display_name': 'NYY-J'},
    {'category': 'cable_type', 'value': 'Rail', 'display_name': 'Rail'},
    {'category': 'cable_type', 'value': 'VD', 'display_name': 'VD'},
    {'category': 'cable_type', 'value': 'VMvK', 'display_name': 'VMvK'},
    {'category': 'cable_type', 'value': 'VMvK-as', 'display_name': 'VMvK-as'},
    {'category': 'cable_type', 'value': 'VULT', 'display_name': 'VULT'},
    {'category': 'cable_type', 'value': 'VULTFLEX', 'display_name': 'VULTFLEX'},
    {'category': 'cable_type', 'value': 'XMvK', 'display_name': 'XMvK'},
    {'category': 'cable_type', 'value': 'XMvK-as', 'display_name': 'XMvK-as'},
    {'category': 'cable_type', 'value': 'YMvK', 'display_name': 'YMvK'},
    {'category': 'cable_type', 'value': 'YMvK-as', 'display_name': 'YMvK-as'},
    {'category': 'cable_type', 'value': 'YMvK-mb', 'display_name': 'YMvK-mb'},
    {'category': 'cable_type', 'value': 'YMVK-ss', 'display_name': 'YMVK-ss'},
    {'category': 'cable_type', 'value': 'YMz1K', 'display_name': 'YMz1K'},
  ];

  static const _defaultLocationStandards = [
    {
      'category': 'location',
      'value': 'Nabij hoofdentree',
      'display_name': 'Nabij hoofdentree',
    },
    {'category': 'location', 'value': 'Gang', 'display_name': 'Gang'},
    {'category': 'location', 'value': 'Keuken', 'display_name': 'Keuken'},
    {'category': 'location', 'value': 'Badkamer', 'display_name': 'Badkamer'},
    {'category': 'location', 'value': 'Woonkamer', 'display_name': 'Woonkamer'},
    {
      'category': 'location',
      'value': 'Parkeergarage',
      'display_name': 'Parkeergarage',
    },
    {'category': 'location', 'value': 'Tuin', 'display_name': 'Tuin'},
    {
      'category': 'location',
      'value': 'Bergruimte',
      'display_name': 'Bergruimte',
    },
    {'category': 'location', 'value': 'CV-ruimte', 'display_name': 'CV-ruimte'},
    {
      'category': 'location',
      'value': 'Technische ruimte',
      'display_name': 'Technische ruimte',
    },
    {
      'category': 'location',
      'value': 'Souterrain',
      'display_name': 'Souterrain',
    },
    {
      'category': 'location',
      'value': 'Begane grond',
      'display_name': 'Begane grond',
    },
    {
      'category': 'location',
      'value': '1e verdieping',
      'display_name': '1e verdieping',
    },
    {
      'category': 'location',
      'value': '2e verdieping',
      'display_name': '2e verdieping',
    },
    {
      'category': 'location',
      'value': '3e verdieping',
      'display_name': '3e verdieping',
    },
    {
      'category': 'location',
      'value': '4e verdieping',
      'display_name': '4e verdieping',
    },
    {
      'category': 'location',
      'value': '5e verdieping',
      'display_name': '5e verdieping',
    },
    {
      'category': 'location',
      'value': '6e verdieping',
      'display_name': '6e verdieping',
    },
    {
      'category': 'location',
      'value': '7e verdieping',
      'display_name': '7e verdieping',
    },
    {
      'category': 'location',
      'value': '8e verdieping',
      'display_name': '8e verdieping',
    },
    {'category': 'location', 'value': 'Zolder', 'display_name': 'Zolder'},
    {'category': 'location', 'value': 'Dakopbouw', 'display_name': 'Dakopbouw'},
  ];

  static const _defaultLocationAStandards = [
    {'category': 'location_a', 'value': 'Kelder', 'display_name': 'Kelder'},
    {
      'category': 'location_a',
      'value': 'Souterrain',
      'display_name': 'Souterrain',
    },
    {
      'category': 'location_a',
      'value': 'Begane grond',
      'display_name': 'Begane grond',
    },
    {
      'category': 'location_a',
      'value': '1e verdieping',
      'display_name': '1e verdieping',
    },
    {
      'category': 'location_a',
      'value': '2e verdieping',
      'display_name': '2e verdieping',
    },
    {
      'category': 'location_a',
      'value': '3e verdieping',
      'display_name': '3e verdieping',
    },
    {
      'category': 'location_a',
      'value': '4e verdieping',
      'display_name': '4e verdieping',
    },
    {
      'category': 'location_a',
      'value': '5e verdieping',
      'display_name': '5e verdieping',
    },
    {'category': 'location_a', 'value': 'Zolder', 'display_name': 'Zolder'},
    {
      'category': 'location_a',
      'value': 'Dakopbouw',
      'display_name': 'Dakopbouw',
    },
    {'category': 'location_a', 'value': 'Dak', 'display_name': 'Dak'},
  ];

  static const _defaultAardingStandards = [
    {
      'category': 'aarding',
      'value': 'Van HAR naar gasleiding',
      'display_name': 'Van HAR naar gasleiding',
    },
    {
      'category': 'aarding',
      'value': 'Van HAR naar waterleiding',
      'display_name': 'Van HAR naar waterleiding',
    },
    {
      'category': 'aarding',
      'value': 'Van HAR naar luchtbehandeling',
      'display_name': 'Van HAR naar luchtbehandeling',
    },
    {
      'category': 'aarding',
      'value': 'Van HAR naar constructie',
      'display_name': 'Van HAR naar constructie',
    },
    {
      'category': 'aarding',
      'value': 'Van HAR naar vreemdgeleidend deel',
      'display_name': 'Van HAR naar vreemdgeleidend deel',
    },
    {
      'category': 'aarding',
      'value': 'Van HAR naar CAI',
      'display_name': 'Van HAR naar CAI',
    },
    {
      'category': 'aarding',
      'value': 'Van HAR naar Medische zuurstof',
      'display_name': 'Van HAR naar Medische zuurstof',
    },
    {
      'category': 'aarding',
      'value': 'Van HAR naar Medische lucht',
      'display_name': 'Van HAR naar Medische lucht',
    },
  ];

  static const _defaultLocationBStandards = [
    {'category': 'location_b', 'value': 'Links', 'display_name': 'Links'},
    {'category': 'location_b', 'value': 'Rechts', 'display_name': 'Rechts'},
    {'category': 'location_b', 'value': 'Boven', 'display_name': 'Boven'},
    {'category': 'location_b', 'value': 'Onder', 'display_name': 'Onder'},
    {'category': 'location_b', 'value': 'Midden', 'display_name': 'Midden'},
    {'category': 'location_b', 'value': 'Voor', 'display_name': 'Voor'},
    {'category': 'location_b', 'value': 'Achter', 'display_name': 'Achter'},
    {'category': 'location_b', 'value': 'Noord', 'display_name': 'Noord'},
    {'category': 'location_b', 'value': 'Oost', 'display_name': 'Oost'},
    {'category': 'location_b', 'value': 'Zuid', 'display_name': 'Zuid'},
    {'category': 'location_b', 'value': 'West', 'display_name': 'West'},
    {'category': 'location_b', 'value': 'Buiten', 'display_name': 'Buiten'},
  ];

  static const _defaultInspectionReasonStandards = [
    {
      'category': 'inspection_reason',
      'value': 'Controle bestaande elektrische installatie',
      'display_name': 'Controle bestaande elektrische installatie',
    },
    {
      'category': 'inspection_reason',
      'value': 'Uitbreiding bestaande elektrische installatie',
      'display_name': 'Uitbreiding bestaande elektrische installatie',
    },
    {
      'category': 'inspection_reason',
      'value':
          'Arbeidsomstandighedenwet, alleen de veiligheid van de elektrische installatie',
      'display_name':
          'Arbeidsomstandighedenwet, alleen de veiligheid van de elektrische installatie',
    },
    {
      'category': 'inspection_reason',
      'value':
          'Polis voorwaarden verzekeringsmaatschappij, inhoud van de clausule onbekend',
      'display_name':
          'Polis voorwaarden verzekeringsmaatschappij, inhoud van de clausule onbekend',
    },
    {
      'category': 'inspection_reason',
      'value': 'Polis voorwaarden verzekeringsmaatschappij',
      'display_name': 'Polis voorwaarden verzekeringsmaatschappij',
    },
    {
      'category': 'inspection_reason',
      'value': 'Gebruikersvergunning',
      'display_name': 'Gebruikersvergunning',
    },
    {
      'category': 'inspection_reason',
      'value': 'VCA certificering',
      'display_name': 'VCA certificering',
    },
    {
      'category': 'inspection_reason',
      'value': 'Woningwet',
      'display_name': 'Woningwet',
    },
    {
      'category': 'inspection_reason',
      'value': 'Omgevingswet',
      'display_name': 'Omgevingswet',
    },
    {
      'category': 'inspection_reason',
      'value': 'Arbo-wet',
      'display_name': 'Arbo-wet',
    },
    {
      'category': 'inspection_reason',
      'value': 'Milieuwetgeving',
      'display_name': 'Milieuwetgeving',
    },
    {
      'category': 'inspection_reason',
      'value': 'Kwaliteitssysteem opdrachtgever',
      'display_name': 'Kwaliteitssysteem opdrachtgever',
    },
  ];

  static const _defaultKarakteristiekStandards = [
    {'category': 'karakteristiek', 'value': 'B', 'display_name': 'B'},
    {'category': 'karakteristiek', 'value': 'C', 'display_name': 'C'},
    {'category': 'karakteristiek', 'value': 'D', 'display_name': 'D'},
    {'category': 'karakteristiek', 'value': 'Gg', 'display_name': 'Gg'},
  ];

  Future<void> _insertDefaultStandards(Database db) async {
    final defaults = <Map<String, String>>[
      {'category': 'system', 'value': 'TT', 'display_name': 'TT'},
      {'category': 'system', 'value': 'TN-S', 'display_name': 'TN-S'},
      {'category': 'system', 'value': 'TN-C', 'display_name': 'TN-C'},
      {'category': 'protection', 'value': 'B 40 A', 'display_name': 'B 40 A'},
      {'category': 'protection', 'value': 'C 40 A', 'display_name': 'C 40 A'},
      {'category': 'protection', 'value': 'Gl 50 A', 'display_name': 'Gl 50 A'},
      {'category': 'protection', 'value': 'Gl 63 A', 'display_name': 'Gl 63 A'},
      {'category': 'protection_class', 'value': 'IP44', 'display_name': 'IP44'},
      {'category': 'protection_class', 'value': 'IP54', 'display_name': 'IP54'},
      {'category': 'cable', 'value': '6', 'display_name': '6 mm²'},
      {'category': 'cable', 'value': '10', 'display_name': '10 mm²'},
      {'category': 'cable', 'value': '16', 'display_name': '16 mm²'},
      {'category': 'cable', 'value': '25', 'display_name': '25 mm²'},
      {'category': 'cable', 'value': '35', 'display_name': '35 mm²'},
      {'category': 'cable_length', 'value': '25', 'display_name': '< 25 m'},
      {'category': 'cable_length', 'value': '50', 'display_name': '< 50 m'},
      {'category': 'cable_length', 'value': '100', 'display_name': '< 100 m'},
      {'category': 'main_switch', 'value': '25', 'display_name': '25 A'},
      {'category': 'main_switch', 'value': '40', 'display_name': '40 A'},
      {'category': 'main_switch', 'value': '63', 'display_name': '63 A'},
      {'category': 'main_switch', 'value': '80', 'display_name': '80 A'},
      {'category': 'main_switch', 'value': '100', 'display_name': '100 A'},
      {'category': 'main_switch', 'value': '125', 'display_name': '125 A'},
      {'category': 'main_switch', 'value': '160', 'display_name': '160 A'},
      {'category': 'main_switch', 'value': '200', 'display_name': '200 A'},
      {'category': 'main_switch', 'value': '250', 'display_name': '250 A'},
      {'category': 'main_switch_poles', 'value': '1', 'display_name': '1'},
      {'category': 'main_switch_poles', 'value': '2', 'display_name': '2'},
      {'category': 'main_switch_poles', 'value': '3', 'display_name': '3'},
      {'category': 'main_switch_poles', 'value': '4', 'display_name': '4'},
      ..._defaultCableTypeStandards,
      ..._defaultLocationStandards,
      ..._defaultInspectionReasonStandards,
      ..._defaultKarakteristiekStandards,
    ];

    final batch = db.batch();
    for (final standard in defaults) {
      batch.insert('standards', standard);
    }
    await batch.commit(noResult: true);
  }

  // ── Inspections ──

  Future<int> createInspection() async {
    final db = await database;
    final now = DateTime.now().toIso8601String();
    return await db.insert('inspections', {
      'created_at': now,
      'updated_at': now,
      'status': 'draft',
      'sync_status': 'pending',
    });
  }

  Future<List<Inspection>> getInspections() async {
    final db = await database;
    final maps = await db.query('inspections', orderBy: 'created_at DESC');
    return maps.map((m) => Inspection.fromMap(m)).toList();
  }

  Future<Inspection?> getInspection(int id) async {
    final db = await database;
    final maps = await db.query(
      'inspections',
      where: 'id = ?',
      whereArgs: [id],
    );
    if (maps.isEmpty) return null;
    return Inspection.fromMap(maps.first);
  }

  Future<void> updateInspectionStatus(int id, String status) async {
    final db = await database;
    await db.update(
      'inspections',
      {'status': status, 'updated_at': DateTime.now().toIso8601String()},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> deleteInspection(int id) async {
    final db = await database;
    await db.delete('inspections', where: 'id = ?', whereArgs: [id]);
  }

  /// Duplicates an inspection and all of its related data (title page,
  /// general data, switchboards, solar installations, defects, tekeningen,
  /// measurement groups, etc.) into a brand new inspection. Returns the id
  /// of the newly created inspection.
  ///
  /// [titleSuffix], if provided, is appended to the copied title page's
  /// title so the duplicate can be told apart from the original.
  Future<int> duplicateInspection(int id, {String? titleSuffix}) async {
    // Make sure lazily-created tables exist before starting the transaction.
    await _ensureSolarInverterSchema();
    await _ensureSolarStringMeasurementSchema();
    await _ensureSolarVereffeningSchema();
    await _ensureFinalAssessmentSchema();

    final db = await database;
    return db.transaction<int>((txn) async {
      final now = DateTime.now().toIso8601String();
      final newId = await txn.insert('inspections', {
        'created_at': now,
        'updated_at': now,
        'status': 'draft',
        'sync_status': 'pending',
      });

      Future<void> copyRows(
        String table,
        String fkColumn,
        int oldParentId,
        int newParentId, {
        void Function(Map<String, dynamic> copy)? mutate,
        Future<void> Function(int oldRowId, int newRowId)? onCopied,
      }) async {
        final rows = await txn.query(
          table,
          where: '$fkColumn = ?',
          whereArgs: [oldParentId],
        );
        for (final row in rows) {
          final oldRowId = row['id'] as int;
          final copy = Map<String, dynamic>.from(row)..remove('id');
          copy[fkColumn] = newParentId;
          mutate?.call(copy);
          final newRowId = await txn.insert(table, copy);
          if (onCopied != null) await onCopied(oldRowId, newRowId);
        }
      }

      await copyRows('title_pages', 'inspection_id', id, newId,
          mutate: (copy) {
        if (titleSuffix != null && titleSuffix.isNotEmpty) {
          copy['title'] = '${copy['title'] ?? ''}$titleSuffix';
        }
      });
      await copyRows('general_data', 'inspection_id', id, newId);
      await copyRows('inspection_details', 'inspection_id', id, newId);
      await copyRows('final_assessment', 'inspection_id', id, newId);

      // Keep track of old -> new switchboard ids so switchboard-scoped
      // measurement_groups can be remapped to the duplicated switchboard.
      final switchboardIdMap = <int, int>{};
      final switchboards = await txn.query(
        'switchboards',
        where: 'inspection_id = ?',
        whereArgs: [id],
      );
      for (final switchboard in switchboards) {
        final oldSwitchboardId = switchboard['id'] as int;
        final switchboardCopy = Map<String, dynamic>.from(switchboard)
          ..remove('id')
          ..['inspection_id'] = newId;
        final newSwitchboardId =
            await txn.insert('switchboards', switchboardCopy);
        switchboardIdMap[oldSwitchboardId] = newSwitchboardId;
      }

      await copyRows('steekproef_items', 'inspection_id', id, newId);

      final solarInstallations = await txn.query(
        'solar_installations',
        where: 'inspection_id = ?',
        whereArgs: [id],
      );
      for (final installation in solarInstallations) {
        final oldInstallationId = installation['id'] as int;
        final installationCopy = Map<String, dynamic>.from(installation)
          ..remove('id')
          ..['inspection_id'] = newId;
        final newInstallationId =
            await txn.insert('solar_installations', installationCopy);

        await copyRows('solar_inverters', 'solar_installation_id',
            oldInstallationId, newInstallationId,
            onCopied: (oldInverterId, newInverterId) => copyRows(
                'solar_string_measurements',
                'solar_inverter_id',
                oldInverterId,
                newInverterId));
        await copyRows('solar_vereffeningsrijen', 'solar_installation_id',
            oldInstallationId, newInstallationId);
      }

      // Keep track of old -> new defect ids so tekening_pins that point at a
      // defect can be remapped to the duplicated defect.
      final defectIdMap = <int, int>{};
      final defects = await txn.query(
        'defects',
        where: 'inspection_id = ?',
        whereArgs: [id],
      );
      for (final defect in defects) {
        final oldDefectId = defect['id'] as int;
        final defectCopy = Map<String, dynamic>.from(defect)
          ..remove('id')
          ..['inspection_id'] = newId;
        final newDefectId = await txn.insert('defects', defectCopy);
        defectIdMap[oldDefectId] = newDefectId;

        await copyRows(
            'defect_annotations', 'defect_id', oldDefectId, newDefectId);
        await copyRows('herstel', 'defect_id', oldDefectId, newDefectId);
      }

      final tekeningen = await txn.query(
        'tekeningen',
        where: 'inspection_id = ?',
        whereArgs: [id],
      );
      for (final tekening in tekeningen) {
        final oldTekeningId = tekening['id'] as int;
        final tekeningCopy = Map<String, dynamic>.from(tekening)
          ..remove('id')
          ..['inspection_id'] = newId;
        final newTekeningId = await txn.insert('tekeningen', tekeningCopy);

        await copyRows('tekening_pins', 'tekening_id', oldTekeningId,
            newTekeningId, mutate: (copy) {
          final oldPinDefectId = copy['defect_id'] as int?;
          if (oldPinDefectId != null) {
            copy['defect_id'] = defectIdMap[oldPinDefectId];
          }
        });
      }

      final measurementGroups = await txn.query(
        'measurement_groups',
        where: 'inspection_id = ?',
        whereArgs: [id],
      );
      for (final group in measurementGroups) {
        final oldGroupId = group['id'] as int;
        final groupCopy = Map<String, dynamic>.from(group)
          ..remove('id')
          ..['inspection_id'] = newId;
        final oldSwitchboardId = group['switchboard_id'] as int?;
        if (oldSwitchboardId != null) {
          groupCopy['switchboard_id'] = switchboardIdMap[oldSwitchboardId];
        }
        final newGroupId = await txn.insert('measurement_groups', groupCopy);

        await copyRows(
            'measurement_readings', 'group_id', oldGroupId, newGroupId);
      }

      return newId;
    });
  }

  Future<void> _updateInspectionTimestamp(int inspectionId) async {
    final db = await database;
    await db.update(
      'inspections',
      {'updated_at': DateTime.now().toIso8601String()},
      where: 'id = ?',
      whereArgs: [inspectionId],
    );
  }

  // ── Title Pages ──

  Future<int> insertTitlePage(TitlePage titlePage) async {
    final db = await database;
    final id = await db.insert('title_pages', titlePage.toMap());
    await _updateInspectionTimestamp(titlePage.inspectionId);
    return id;
  }

  Future<TitlePage?> getTitlePage(int inspectionId) async {
    final db = await database;
    final maps = await db.query(
      'title_pages',
      where: 'inspection_id = ?',
      whereArgs: [inspectionId],
    );
    if (maps.isEmpty) return null;
    return TitlePage.fromMap(maps.first);
  }

  Future<void> updateTitlePage(TitlePage titlePage) async {
    final db = await database;
    await db.update(
      'title_pages',
      titlePage.toMap(),
      where: 'id = ?',
      whereArgs: [titlePage.id],
    );
    await _updateInspectionTimestamp(titlePage.inspectionId);
  }

  Future<Map<String, double>?> getTitlePageLayoutDefaults() async {
    final db = await database;
    final rows = await db.query('title_page_defaults', limit: 1);
    if (rows.isEmpty) return null;
    final r = rows.first;
    double g(String k, double d) => (r[k] as num?)?.toDouble() ?? d;
    return {
      'title_x': g('title_x', 0.5),
      'title_y': g('title_y', 0.15),
      'title_w': g('title_w', 0.80),
      'title_h': g('title_h', 0.10),
      'subtitle_x': g('subtitle_x', 0.5),
      'subtitle_y': g('subtitle_y', 0.26),
      'subtitle_w': g('subtitle_w', 0.70),
      'subtitle_h': g('subtitle_h', 0.07),
      'photo_x': g('photo_x', 0.5),
      'photo_y': g('photo_y', 0.50),
      'photo_w': g('photo_w', 0.60),
      'photo_h': g('photo_h', 0.35),
      'date_x': g('date_x', 0.5),
      'date_y': g('date_y', 0.78),
      'date_w': g('date_w', 0.70),
      'date_h': g('date_h', 0.065),
      'code_x': g('code_x', 0.5),
      'code_y': g('code_y', 0.86),
      'code_w': g('code_w', 0.70),
      'code_h': g('code_h', 0.065),
      'project_x': g('project_x', 0.5),
      'project_y': g('project_y', 0.93),
      'project_w': g('project_w', 0.70),
      'project_h': g('project_h', 0.065),
      'logo_x': g('logo_x', 0.82),
      'logo_y': g('logo_y', 0.07),
      'logo_w': g('logo_w', 0.30),
      'logo_h': g('logo_h', 0.12),
      'address_name_x': g('address_name_x', 0.5),
      'address_name_y': g('address_name_y', 0.72),
      'address_name_w': g('address_name_w', 0.70),
      'address_name_h': g('address_name_h', 0.065),
    };
  }

  Future<void> saveTitlePageLayoutDefaults(TitlePage tp) async {
    final db = await database;
    await db.insert('title_page_defaults', {
      'id': 1,
      'title_x': tp.titleX,
      'title_y': tp.titleY,
      'title_w': tp.titleW,
      'title_h': tp.titleH,
      'subtitle_x': tp.subtitleX,
      'subtitle_y': tp.subtitleY,
      'subtitle_w': tp.subtitleW,
      'subtitle_h': tp.subtitleH,
      'photo_x': tp.photoX,
      'photo_y': tp.photoY,
      'photo_w': tp.photoW,
      'photo_h': tp.photoH,
      'date_x': tp.dateX,
      'date_y': tp.dateY,
      'date_w': tp.dateW,
      'date_h': tp.dateH,
      'code_x': tp.codeX,
      'code_y': tp.codeY,
      'code_w': tp.codeW,
      'code_h': tp.codeH,
      'project_x': tp.projectX,
      'project_y': tp.projectY,
      'project_w': tp.projectW,
      'project_h': tp.projectH,
      'logo_x': tp.logoX,
      'logo_y': tp.logoY,
      'logo_w': tp.logoW,
      'logo_h': tp.logoH,
      'address_name_x': tp.addressNameX,
      'address_name_y': tp.addressNameY,
      'address_name_w': tp.addressNameW,
      'address_name_h': tp.addressNameH,
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  // ── General Data ──

  Future<int> insertGeneralData(GeneralData data) async {
    final db = await database;
    final id = await db.insert('general_data', data.toMap());
    await _updateInspectionTimestamp(data.inspectionId);
    return id;
  }

  Future<GeneralData?> getGeneralData(int inspectionId) async {
    final db = await database;
    final maps = await db.query(
      'general_data',
      where: 'inspection_id = ?',
      whereArgs: [inspectionId],
    );
    if (maps.isEmpty) return null;
    return GeneralData.fromMap(maps.first);
  }

  Future<void> updateGeneralData(GeneralData data) async {
    final db = await database;
    await db.update(
      'general_data',
      data.toMap(),
      where: 'id = ?',
      whereArgs: [data.id],
    );
    await _updateInspectionTimestamp(data.inspectionId);
  }

  // ── Inspection Details ──

  Future<int> insertInspectionDetail(InspectionDetail detail) async {
    await _ensureInspectionDetailMethodeSchema();
    final db = await database;
    final id = await db.insert('inspection_details', detail.toMap());
    await _updateInspectionTimestamp(detail.inspectionId);
    return id;
  }

  Future<InspectionDetail?> getInspectionDetail(int inspectionId) async {
    await _ensureInspectionDetailMethodeSchema();
    final db = await database;
    final maps = await db.query(
      'inspection_details',
      where: 'inspection_id = ?',
      whereArgs: [inspectionId],
    );
    if (maps.isEmpty) return null;
    return InspectionDetail.fromMap(maps.first);
  }

  Future<void> updateInspectionDetail(InspectionDetail detail) async {
    await _ensureInspectionDetailMethodeSchema();
    final db = await database;
    await db.update(
      'inspection_details',
      detail.toMap(),
      where: 'id = ?',
      whereArgs: [detail.id],
    );
    await _updateInspectionTimestamp(detail.inspectionId);
  }

  // ── Switchboards ──

  Future<int> insertSwitchboard(Switchboard switchboard) async {
    final db = await database;
    final id = await db.insert('switchboards', switchboard.toMap());
    await _updateInspectionTimestamp(switchboard.inspectionId);
    return id;
  }

  Future<List<Switchboard>> getSwitchboards(int inspectionId) async {
    final db = await database;
    final maps = await db.query(
      'switchboards',
      where: 'inspection_id = ?',
      whereArgs: [inspectionId],
    );
    return maps.map((m) => Switchboard.fromMap(m)).toList();
  }

  Future<Switchboard?> getSwitchboard(int id) async {
    final db = await database;
    final maps = await db.query(
      'switchboards',
      where: 'id = ?',
      whereArgs: [id],
    );
    if (maps.isEmpty) return null;
    return Switchboard.fromMap(maps.first);
  }

  Future<void> updateSwitchboard(Switchboard switchboard) async {
    final db = await database;
    await db.update(
      'switchboards',
      switchboard.toMap(),
      where: 'id = ?',
      whereArgs: [switchboard.id],
    );
    await _updateInspectionTimestamp(switchboard.inspectionId);
  }

  Future<void> deleteSwitchboard(int id) async {
    final db = await database;
    await deleteMeasurementGroupsForSwitchboard(id);
    await db.delete('switchboards', where: 'id = ?', whereArgs: [id]);
  }

  Future<void> deleteAllSwitchboards(int inspectionId) async {
    final db = await database;
    final switchboards = await getSwitchboards(inspectionId);
    for (final switchboard in switchboards) {
      if (switchboard.id != null) {
        await deleteMeasurementGroupsForSwitchboard(switchboard.id!);
      }
    }
    await db.delete(
      'switchboards',
      where: 'inspection_id = ?',
      whereArgs: [inspectionId],
    );
  }

  // ── Solar Installations ──

  Future<int> insertSolarInstallation(SolarInstallation installation) async {
    final db = await database;
    final id = await db.insert('solar_installations', installation.toMap());
    await _updateInspectionTimestamp(installation.inspectionId);
    return id;
  }

  Future<List<SolarInstallation>> getSolarInstallations(
    int inspectionId,
  ) async {
    await _ensureSolarInstallationSchema();
    final db = await database;
    final maps = await db.query(
      'solar_installations',
      where: 'inspection_id = ?',
      whereArgs: [inspectionId],
    );
    return maps.map((m) => SolarInstallation.fromMap(m)).toList();
  }

  Future<SolarInstallation?> getSolarInstallation(int id) async {
    await _ensureSolarInstallationSchema();
    final db = await database;
    final maps = await db.query(
      'solar_installations',
      where: 'id = ?',
      whereArgs: [id],
    );
    if (maps.isEmpty) return null;
    return SolarInstallation.fromMap(maps.first);
  }

  Future<void> updateSolarInstallation(SolarInstallation installation) async {
    final db = await database;
    await db.update(
      'solar_installations',
      installation.toMap(),
      where: 'id = ?',
      whereArgs: [installation.id],
    );
    await _updateInspectionTimestamp(installation.inspectionId);
  }

  Future<void> deleteSolarInstallation(int id) async {
    final db = await database;
    await db.delete('solar_installations', where: 'id = ?', whereArgs: [id]);
  }

  // ── Solar Inverters ──

  Future<int> insertSolarInverter(SolarInverter inverter) async {
    await _ensureSolarInverterSchema();
    final db = await database;
    return db.insert('solar_inverters', inverter.toMap());
  }

  Future<List<SolarInverter>> getSolarInverters(int solarInstallationId) async {
    await _ensureSolarInverterSchema();
    final db = await database;
    final maps = await db.query(
      'solar_inverters',
      where: 'solar_installation_id = ?',
      whereArgs: [solarInstallationId],
    );
    return maps.map((m) => SolarInverter.fromMap(m)).toList();
  }

  Future<SolarInverter?> getSolarInverter(int id) async {
    await _ensureSolarInverterSchema();
    final db = await database;
    final maps = await db.query(
      'solar_inverters',
      where: 'id = ?',
      whereArgs: [id],
    );
    if (maps.isEmpty) return null;
    return SolarInverter.fromMap(maps.first);
  }

  Future<void> updateSolarInverter(SolarInverter inverter) async {
    await _ensureSolarInverterSchema();
    final db = await database;
    await db.update(
      'solar_inverters',
      inverter.toMap(),
      where: 'id = ?',
      whereArgs: [inverter.id],
    );
  }

  Future<void> deleteSolarInverter(int id) async {
    final db = await database;
    await db.delete('solar_inverters', where: 'id = ?', whereArgs: [id]);
  }

  // ── Solar String Measurements ──

  Future<int> insertSolarStringMeasurement(
    SolarStringMeasurement measurement,
  ) async {
    await _ensureSolarStringMeasurementSchema();
    final db = await database;
    return db.insert('solar_string_measurements', measurement.toMap());
  }

  Future<List<SolarStringMeasurement>> getSolarStringMeasurements(
    int solarInverterId,
  ) async {
    await _ensureSolarStringMeasurementSchema();
    final db = await database;
    final maps = await db.query(
      'solar_string_measurements',
      where: 'solar_inverter_id = ?',
      whereArgs: [solarInverterId],
    );
    return maps.map((m) => SolarStringMeasurement.fromMap(m)).toList();
  }

  Future<void> updateSolarStringMeasurement(
    SolarStringMeasurement measurement,
  ) async {
    await _ensureSolarStringMeasurementSchema();
    final db = await database;
    await db.update(
      'solar_string_measurements',
      measurement.toMap(),
      where: 'id = ?',
      whereArgs: [measurement.id],
    );
  }

  Future<void> deleteSolarStringMeasurement(int id) async {
    final db = await database;
    await db.delete(
      'solar_string_measurements',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // ── Solar Vereffeningsrijen ──

  Future<int> insertSolarVereffening(SolarVereffening vereffening) async {
    await _ensureSolarVereffeningSchema();
    final db = await database;
    return db.insert('solar_vereffeningsrijen', vereffening.toMap());
  }

  Future<List<SolarVereffening>> getSolarVereffeningsrijen(
    int solarInstallationId,
  ) async {
    await _ensureSolarVereffeningSchema();
    final db = await database;
    final maps = await db.query(
      'solar_vereffeningsrijen',
      where: 'solar_installation_id = ?',
      whereArgs: [solarInstallationId],
      orderBy: 'volgnummer ASC',
    );
    return maps.map((m) => SolarVereffening.fromMap(m)).toList();
  }

  Future<void> updateSolarVereffening(SolarVereffening vereffening) async {
    await _ensureSolarVereffeningSchema();
    final db = await database;
    await db.update(
      'solar_vereffeningsrijen',
      vereffening.toMap(),
      where: 'id = ?',
      whereArgs: [vereffening.id],
    );
  }

  Future<void> deleteSolarVereffening(int id) async {
    final db = await database;
    await db.delete(
      'solar_vereffeningsrijen',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // ── Defects ──

  Future<int> insertDefect(Defect defect) async {
    final db = await database;
    final id = await db.insert('defects', defect.toMap());
    await _updateInspectionTimestamp(defect.inspectionId);
    return id;
  }

  Future<List<Defect>> getDefects(int inspectionId) async {
    final db = await database;
    final maps = await db.query(
      'defects',
      where: 'inspection_id = ?',
      whereArgs: [inspectionId],
    );
    return maps.map((m) => Defect.fromMap(m)).toList();
  }

  Future<Defect?> getDefect(int id) async {
    final db = await database;
    final maps = await db.query('defects', where: 'id = ?', whereArgs: [id]);
    if (maps.isEmpty) return null;
    return Defect.fromMap(maps.first);
  }

  Future<void> updateDefect(Defect defect) async {
    final db = await database;
    await db.update(
      'defects',
      defect.toMap(),
      where: 'id = ?',
      whereArgs: [defect.id],
    );
    await _updateInspectionTimestamp(defect.inspectionId);
  }

  Future<void> deleteDefect(int id) async {
    final db = await database;
    await db.delete('defects', where: 'id = ?', whereArgs: [id]);
  }

  Future<void> deleteAllDefects(int inspectionId) async {
    final db = await database;
    await db.delete(
      'defects',
      where: 'inspection_id = ?',
      whereArgs: [inspectionId],
    );
  }

  Future<void> deleteDefects(List<int> ids) async {
    if (ids.isEmpty) return;
    final db = await database;
    final placeholders = List.filled(ids.length, '?').join(',');
    await db.delete('defects', where: 'id IN ($placeholders)', whereArgs: ids);
  }

  // ── Standards ──

  Future<List<Standard>> getStandards(String category) async {
    final db = await database;
    final maps = await db.query(
      'standards',
      where: 'category = ?',
      whereArgs: [category],
    );
    return maps.map((m) => Standard.fromMap(m)).toList();
  }

  Future<int> insertStandard(Standard standard) async {
    final db = await database;
    return await db.insert('standards', standard.toMap());
  }

  Future<void> updateStandard(Standard standard) async {
    final db = await database;
    await db.update(
      'standards',
      standard.toMap(),
      where: 'id = ?',
      whereArgs: [standard.id],
    );
  }

  Future<void> deleteStandard(int id) async {
    final db = await database;
    await db.delete('standards', where: 'id = ?', whereArgs: [id]);
  }

  // ── Defect Annotations ──

  Future<int> insertAnnotation(DefectAnnotation annotation) async {
    await _ensureAnnotationSchema();
    final db = await database;
    final id = await db.insert('defect_annotations', annotation.toMap());
    await _updateHasAnnotations(annotation.defectId);
    return id;
  }

  Future<List<DefectAnnotation>> getAnnotations(
    int defectId,
    int photoNumber,
  ) async {
    await _ensureAnnotationSchema();
    final db = await database;
    final maps = await db.query(
      'defect_annotations',
      where: 'defect_id = ? AND photo_number = ?',
      whereArgs: [defectId, photoNumber],
      orderBy: 'order_number ASC',
    );
    return maps.map((m) => DefectAnnotation.fromMap(m)).toList();
  }

  Future<List<DefectAnnotation>> getAllAnnotationsForDefect(
    int defectId,
  ) async {
    await _ensureAnnotationSchema();
    final db = await database;
    final maps = await db.query(
      'defect_annotations',
      where: 'defect_id = ?',
      whereArgs: [defectId],
      orderBy: 'order_number ASC',
    );
    return maps.map((m) => DefectAnnotation.fromMap(m)).toList();
  }

  Future<void> updateAnnotation(DefectAnnotation annotation) async {
    await _ensureAnnotationSchema();
    final db = await database;
    await db.update(
      'defect_annotations',
      annotation.toMap(),
      where: 'id = ?',
      whereArgs: [annotation.id],
    );
  }

  Future<void> deleteAnnotation(int id, int defectId) async {
    await _ensureAnnotationSchema();
    final db = await database;
    await db.delete('defect_annotations', where: 'id = ?', whereArgs: [id]);
    await _updateHasAnnotations(defectId);
    await _renumberAnnotations(defectId);
  }

  Future<void> deleteAnnotationsForPhoto(int defectId, int photoNumber) async {
    await _ensureAnnotationSchema();
    final db = await database;
    await db.delete(
      'defect_annotations',
      where: 'defect_id = ? AND photo_number = ?',
      whereArgs: [defectId, photoNumber],
    );
    await _updateHasAnnotations(defectId);
  }

  Future<int> getNextAnnotationNumber(int defectId) async {
    await _ensureAnnotationSchema();
    final db = await database;
    final result = await db.rawQuery(
      'SELECT MAX(order_number) as max_num FROM defect_annotations WHERE defect_id = ?',
      [defectId],
    );
    final maxNum = result.first['max_num'] as int?;
    return (maxNum ?? 0) + 1;
  }

  Future<void> _updateHasAnnotations(int defectId) async {
    final db = await database;
    final count = Sqflite.firstIntValue(
      await db.rawQuery(
        'SELECT COUNT(*) FROM defect_annotations WHERE defect_id = ?',
        [defectId],
      ),
    );
    await db.update(
      'defects',
      {'has_annotations': (count ?? 0) > 0 ? 1 : 0},
      where: 'id = ?',
      whereArgs: [defectId],
    );
  }

  Future<void> _renumberAnnotations(int defectId) async {
    final db = await database;
    final annotations = await db.query(
      'defect_annotations',
      where: 'defect_id = ?',
      whereArgs: [defectId],
      orderBy: 'order_number ASC',
    );
    for (var i = 0; i < annotations.length; i++) {
      await db.update(
        'defect_annotations',
        {'order_number': i + 1},
        where: 'id = ?',
        whereArgs: [annotations[i]['id']],
      );
    }
  }

  // ── Copy sections between inspections ──

  Future<void> copySwitchboardsToInspection(
      int sourceInspectionId, int targetInspectionId) async {
    final photoService = PhotoService();
    final switchboards = await getSwitchboards(sourceInspectionId);
    for (final switchboard in switchboards) {
      final map = switchboard.toMap();
      map.remove('id');
      map['inspection_id'] = targetInspectionId;
      map['photo1_path'] = await photoService.copyPhotoToInspection(
          switchboard.photo1Path, targetInspectionId);
      map['photo2_path'] = await photoService.copyPhotoToInspection(
          switchboard.photo2Path, targetInspectionId);
      await insertSwitchboard(Switchboard.fromMap(map));
    }
  }

  Future<void> copySolarInstallationsToInspection(
      int sourceInspectionId, int targetInspectionId) async {
    final photoService = PhotoService();
    final installations = await getSolarInstallations(sourceInspectionId);
    for (final installation in installations) {
      final map = installation.toMap();
      map.remove('id');
      map['inspection_id'] = targetInspectionId;
      map['photo_roof1_path'] = await photoService.copyPhotoToInspection(
          installation.photoRoof1Path, targetInspectionId);
      map['photo_roof2_path'] = await photoService.copyPhotoToInspection(
          installation.photoRoof2Path, targetInspectionId);
      map['photo_inverter1_path'] = await photoService.copyPhotoToInspection(
          installation.photoInverter1Path, targetInspectionId);
      map['photo_inverter2_path'] = await photoService.copyPhotoToInspection(
          installation.photoInverter2Path, targetInspectionId);
      final newInstallationId =
          await insertSolarInstallation(SolarInstallation.fromMap(map));

      final inverters = await getSolarInverters(installation.id!);
      for (final inverter in inverters) {
        final inverterMap = inverter.toMap();
        inverterMap.remove('id');
        inverterMap['solar_installation_id'] = newInstallationId;
        inverterMap['photo_path'] = await photoService.copyPhotoToInspection(
            inverter.photoPath, targetInspectionId);
        final newInverterId =
            await insertSolarInverter(SolarInverter.fromMap(inverterMap));

        final measurements =
            await getSolarStringMeasurements(inverter.id!);
        for (final measurement in measurements) {
          final measurementMap = measurement.toMap();
          measurementMap.remove('id');
          measurementMap['solar_inverter_id'] = newInverterId;
          await insertSolarStringMeasurement(
              SolarStringMeasurement.fromMap(measurementMap));
        }
      }

      final vereffeningen =
          await getSolarVereffeningsrijen(installation.id!);
      for (final vereffening in vereffeningen) {
        final vereffeningMap = vereffening.toMap();
        vereffeningMap.remove('id');
        vereffeningMap['solar_installation_id'] = newInstallationId;
        await insertSolarVereffening(
            SolarVereffening.fromMap(vereffeningMap));
      }
    }
  }

  Future<void> copyDefectsToInspection(
      int sourceInspectionId, int targetInspectionId) async {
    final photoService = PhotoService();
    final defects = await getDefects(sourceInspectionId);
    for (final defect in defects) {
      final map = defect.toMap();
      map.remove('id');
      map['inspection_id'] = targetInspectionId;
      map['photo1_path'] = await photoService.copyPhotoToInspection(
          defect.photo1Path, targetInspectionId);
      map['photo2_path'] = await photoService.copyPhotoToInspection(
          defect.photo2Path, targetInspectionId);
      final newDefectId = await insertDefect(Defect.fromMap(map));

      if (defect.hasAnnotations && defect.id != null) {
        final annotations = await getAllAnnotationsForDefect(defect.id!);
        for (final annotation in annotations) {
          final annotationMap = annotation.toMap();
          annotationMap.remove('id');
          annotationMap['defect_id'] = newDefectId;
          await insertAnnotation(DefectAnnotation.fromMap(annotationMap));
        }
      }
    }
  }

  // ── Company Details ──

  Future<CompanyDetails?> getCompanyDetails() async {
    await _ensureCompanySchema();
    final db = await database;
    final maps = await db.query('company_details', limit: 1);
    if (maps.isEmpty) return null;
    return CompanyDetails.fromMap(maps.first);
  }

  Future<void> saveCompanyDetails(CompanyDetails details) async {
    await _ensureCompanySchema();
    final db = await database;
    if (details.id != null) {
      await db.update(
        'company_details',
        details.toMap(),
        where: 'id = ?',
        whereArgs: [details.id],
      );
    } else {
      final existing = await db.query('company_details', limit: 1);
      if (existing.isNotEmpty) {
        await db.update(
          'company_details',
          details.toMap(),
          where: 'id = ?',
          whereArgs: [existing.first['id']],
        );
      } else {
        await db.insert('company_details', details.toMap());
      }
    }
  }

  // ── Company Inspectors ──

  Future<List<CompanyInspector>> getCompanyInspectors() async {
    await _ensureCompanyInspectorsSchema();
    final db = await database;
    final maps = await db.query('company_inspectors', orderBy: 'id ASC');
    return maps.map((m) => CompanyInspector.fromMap(m)).toList();
  }

  Future<int> insertCompanyInspector(CompanyInspector inspector) async {
    await _ensureCompanyInspectorsSchema();
    final db = await database;
    return await db.insert('company_inspectors', inspector.toMap());
  }

  Future<void> updateCompanyInspector(CompanyInspector inspector) async {
    await _ensureCompanyInspectorsSchema();
    final db = await database;
    await db.update(
      'company_inspectors',
      inspector.toMap(),
      where: 'id = ?',
      whereArgs: [inspector.id],
    );
  }

  Future<void> deleteCompanyInspector(int id) async {
    await _ensureCompanyInspectorsSchema();
    final db = await database;
    await db.delete('company_inspectors', where: 'id = ?', whereArgs: [id]);
  }

  // ── Measurement Instruments ──

  Future<List<MeasurementInstrument>> getMeasurementInstruments(
    int inspectorId,
  ) async {
    await _ensureMeasurementInstrumentsSchema();
    final db = await database;
    final maps = await db.query(
      'measurement_instruments',
      where: 'inspector_id = ?',
      whereArgs: [inspectorId],
      orderBy: 'id ASC',
    );
    return maps.map((m) => MeasurementInstrument.fromMap(m)).toList();
  }

  Future<List<MeasurementInstrument>> getAllMeasurementInstruments() async {
    await _ensureMeasurementInstrumentsSchema();
    final db = await database;
    final maps = await db.query(
      'measurement_instruments',
      orderBy: 'inspector_id ASC, id ASC',
    );
    return maps.map((m) => MeasurementInstrument.fromMap(m)).toList();
  }

  Future<int> insertMeasurementInstrument(
    MeasurementInstrument instrument,
  ) async {
    await _ensureMeasurementInstrumentsSchema();
    final db = await database;
    return await db.insert('measurement_instruments', instrument.toMap());
  }

  Future<void> updateMeasurementInstrument(
    MeasurementInstrument instrument,
  ) async {
    await _ensureMeasurementInstrumentsSchema();
    final db = await database;
    await db.update(
      'measurement_instruments',
      instrument.toMap(),
      where: 'id = ?',
      whereArgs: [instrument.id],
    );
  }

  Future<void> deleteMeasurementInstrument(int id) async {
    await _ensureMeasurementInstrumentsSchema();
    final db = await database;
    await db.delete(
      'measurement_instruments',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // ── Report Templates ──

  static final List<Map<String, String>> _defaultReportTemplates = [
    {
      'type_rapport': '~EPM_SCOPE_8_PI',
      'rapporttitel': 'Inspectie SCIOS SCOPE 8 PI',
      'subtitel': 'Elektrische laagspanningsinstallatie',
      'inleiding':
          'In dit inspectierapport zijn de bevindingen beschreven van een inspectie volgens Scios SCOPE 8 van de elektrische laagspanningsinstallatie. Het doel van inspecties volgens Scios SCOPE 8 is gebreken te ontdekken die een veilige bedrijfsvoering kunnen belemmeren. \n\nIn opdracht van  ##10## te ##11## is op  ##20## door EPM B.V. afdeling Inspectie & Beheer een inspectie volgens Scios Scope 8 uitgevoerd aan de elektrotechnische installaties. Deze inspectie is uitgevoerd in het pand aan de ##30## te ##31##. De inspectiewerkzaamheden zijn uitgevoerd volgens project ##22##.\n\nDe inspectie van de elektrische laagspanningsinstallatie heeft bestaan uit:\n- Een visuele inspectie;\n- Metingen en beproevingen.\n\nAls er tijdens de inspectie gebreken zijn geconstateerd, worden deze gebreken vermeld in de bijlage "Overzicht van gebreken".\n\nDe rapportage is een jaar geldig. De geldigheid wordt geteld vanaf de laatste inspectiedatum.\n\nNa de inspectie wordt in het SCIOS-portaal de inspectie afgemeld met of zonder constateringen. Een verklaring zonder constateringen. Een rapportage met constateringen kan binnen een jaar na inspectiedatum worden omgezet naar een verklaring zonder constateringen.',
      'tekst_rapport_verklaring':
          'Er is een inspectie uitgevoerd volgens SCIOS SCOPE 8 PI. Tijdens de inspectie zijn:\n\nIn de geïnspecteerde installatie(delen) zijn ##102## stuk(s) met de classificatie ##101##  aangetroffen welke direct aanrakings- of brandgevaar zorgen\n\nIn de geïnspecteerde installatie(delen) zijn ##104## stuk(s) met de classificatie ##103## aangetroffen.\n\nIn de geïnspecteerde installatie(delen) zijn ##106## stuk(s) met de classificatie ##105## aangetroffen.\n\nIndien een of meer van hier bovenstaande opmerkingen aanwezig zijn, dienen de opmerkingen vermeld in dit inspectierapport opgelost te worden.\n\nIn de geïnspecteerde installatie(delen) zijn ##108## stuk(s) met de classificatie ##107## aangetroffen.\n\nIn de geïnspecteerde installatie(delen) zijn ##110## stuk(s) met de classificatie ##109## aangetroffen.\n\nOpmerkingen met de classificatie ##109## moeten worden onderzocht en beoordeeld indien nodig worden opgelost.',
      'visuele_inspectie_titel': 'Visueel',
      'visuele_inspectie':
          '1)	De elektrische installatie volgens:\n2)	B3.01, visuele controle elektrisch materieel:\n2.1)	elektrisch materieel is geïnstalleerd en wordt gebruikt volgens de voorschriften van de fabrikant en \n	geldende installatie- en productnormen;\n2.2)	elektrische materieel is geschikt voor de gebruiker;\n2.3)	elektrische materieel is geschikt voor zijn omgeving;\n2.4)	elektrisch materieel is veilig voor gebruik;\n3)	B3.02 visuele controle schakel- en verdeelinrichtingen:\n3.1)	elektrisch materieel is bestand tegen het maximale kortsluitvermogen dat kan optreden;\n3.2)	de schakel- en verdeelinrichting wordt gebruikt volgens de productvoorschriften;\n3.3)	de schakel- en verdeelinrichting vertoont geen sporen van degeneratie;\n3.4)	de schakel- en verdeelinrichting vertoont geen sporen van oververhitting;\n3.5)	de schakel- en verdeelinrichting is vrij van vuil en vocht;\n3.6)	Bij componenten waarbij periodiek onderhoud noodzakelijk is, moet worden gecontroleerd of dit \n	daadwerkelijk wordt uitgevoerd.\n3.7)	De overstroombeveiliging van de schakel- en verdeelinrichting is juist gekozen.\n3.8)	De schakel- en verdeelinrichting is geschikt voor zijn omgeving.\n3.9)	De schakel- en verdeelinrichting is geschikt voor de gebruiker.\n4)	B3.04 eisen m.b.t. de opbouw van de installatie t.o.v. de omgeving en gebruik:\n4.1)	Bij de inspectie van de elektrische installatie moet rekening worden gehouden of de elektrische installatie \n	geschikt is voor veilig gebruik.\n4.2)	De elektrische installatie moet afgestemd zijn op de eisen m.b.t. de opbouw van de installatie t.o.v. \n	de omgeving en het gebruik. Met name:\n4.4)	de handelingen die worden uitgevoerd door gebruiker;\n4.5)	veiligheidsmaatregelen die zijn genomen;\n4.6)	toegang tot ruimtes met elektrisch gevaar;\n4.7)	schoonmaken van ruimten;\n4.8)	aanraakveiligheid van schakel- en verdeelinrichtingen;\n',
      'visuele_inspectie_toelichting': '',
      'metingen_titel': 'Metingen en beproevingen',
      'metingen':
          '1)	Ononderbroken zijn van de beschermingsleiding: B3.6 of B3.7\n1.1)	Verbindingen in de schakel- en verdeelinrichtingen \n1.2)	Contactdozen\n1.3)	Verlichtingsarmaturen\n1.4)	Overige vast aangesloten elektrisch materieel\n1.5)	Ononderbroken zijn van de beschermingsleidingen bijzondere ruimte: B3.6 of B3.7\n2.1)	Verbindingen in de schakel- en verdeelinrichtingen \n2.2)	Contactdozen\n2.3)	Verlichtingsarmaturen\n2.4)	Overige vast aangesloten elektrisch materieel\n3)	Ononderbroken zijn van de vereffeningsleidingen B3.6\n4)	Ononderbroken zijn van de vereffeningsleidingen in bijzondere ruimte\n5)	Isolatieweerstand, stroomketens van eindgroepen in de volgende omgevingen:\n5.1)	bouw- en sloopterreinen\n5.2)	vochtige omgeving\n5.3)	buitenterrein\n6)	Circuitimpedantie P-N of P-P; B3.7\n6.1	Contactdozen;\n7)	Circuitimpedantie P-PE; B3.7\n7.1)	Schakel- en verdeelinrichtingen klasse 1\n7.2)	Contactdozen \n7.3)	vast aangesloten apparaten',
      'metingen_toelichting': '',
      'aanvullend_onderzoek_titel': '',
      'aanvullend_onderzoek': '',
      'aanvullend_onderzoek_toelichting':
          'Indien blijkt dat tijdens de inspectie de huidige norm strenger is of sterk afwijkt t.o.v. het rechtens verkregen niveau dan zal  indien wettelijk toegestaan de dan geldige norm worden toegepast.',
      'lijst4_titel': '',
      'lijst4': '',
      'lijst4_toelichting': '',
      'vinklijst_afkeuringscriteria':
          'Bij een gebrek of afwijking van een standaard met onmiddellijk gevaar is het volgende uitgevoerd:\n- het wordt onmiddellijk uit bedrijf genomen en bovendien beveiligd tegen opnieuw inschakelen en/of;\n- het wordt onmiddellijk hersteld en/of;\n- het wordt direct gemeld aan de opdrachtgever.\n\nGebreken worden geclassificeerd volgens SCIOS Informatieblad 22. De classificatie volgens IB22 is als volgt:\n\nErnstig - Rood\n• Het gevaar op letsel is voortdurend aanwezig of;\n• Schade met verstrekkende gevolgen.\n\nActie\nEr moeten direct maatregelen worden genomen. Indien bereikbaar onder normale bedrijfsomstandigheden:\n• Deze constatering moet mondeling en schriftelijk worden gemeld;\n• Direct veiligstellen/verhelpen/oplossen.\n\nSerieus - Oranje\nBij een voorzienbare gebeurtenis of een enkele fout:\n• Het gevaar van blijvend letsel/ onherstelbaar letsel kan zich voor doen of\n• Schade met aanzienlijke gevolgen\n\nActie\n• Schriftelijk vastleggen in een inspectierapport.\n• Moet binnen 3 maanden worden hersteld\n\nGering - Geel\n• Het gevaar van herstelbaar letsel kan zich voordoen of;\n• Schade kan gevolgen hebben.\n\nActie\n• Schriftelijk vastleggen in een inspectierapport.\n• Moet binnen 3 maanden worden hersteld\n\nOpmerking - Blauw\n• Er is minimaal gevaar/voldoet niet aan de uitgangspunten of;\n• Het gevolg levert onder normale bedrijfsomstandigheden geen gevaar op.\n\nActie\nSchriftelijk vastleggen in een inspectierapport, indien overeengekomen.\n\nNO - Nader onderzoek is noodzakelijk\nDe opmerkingen met de classificatie NO zijn ten tijde van de inspectie niet nader door de inspecteur onderzocht. De reden hiervan is dat er niet voldoende gegevens beschikbaar waren. Er kan niet worden vastgesteld of de opmerkingen met kwalificatie NO een gebrek is. Vervolgafspraken moeten worden gemaakt.',
    },
    {
      'type_rapport': '~EPM_SCOPE_8_EBI',
      'rapporttitel': 'Inspectie SCIOS SCOPE 8 EBI',
      'subtitel': 'Elektrische laagspanningsinstallatie',
      'inleiding':
          'In dit inspectierapport zijn de bevindingen beschreven van een inspectie volgens Scios SCOPE 8 EBI van de elektrische laagspanningsinstallatie. Het doel van inspecties volgens Scios Scope 8 is gebreken te ontdekken die een veilige bedrijfsvoering kunnen belemmeren. \n\nIn opdracht van  ##10## te ##11## is op  ##20## door EPM B.V. afdeling Inspectie & Beheer een inspectie volgens Scios Scope 8 uitgevoerd aan de elektrotechnische installaties. Deze inspectie is uitgevoerd in het pand aan de ##30## te ##31##. De inspectiewerkzaamheden zijn uitgevoerd volgens project ##22##.\n\nDe inspectie van de elektrische laagspanningsinstallatie heeft bestaan uit:\n- Een visuele inspectie;\n- Metingen en beproevingen.\n\nAls er tijdens de inspectie gebreken zijn geconstateerd, worden deze gebreken vermeld in de bijlage "Overzicht van gebreken".\n\nDe rapportage is een jaar geldig. De geldigheid wordt geteld vanaf de laatste inspectiedatum.\n\nNa de inspectie wordt in het SCIOS-portaal de inspectie afgemeld met of zonder constateringen. Een verklaring zonder constateringen. Een rapportage met constateringen kan binnen een jaar na inspectiedatum worden omgezet naar een verklaring zonder constateringen.',
      'tekst_rapport_verklaring':
          'Er is een inspectie uitgevoerd volgens SCIOS SCOPE 8 EBI. Tijdens de inspectie zijn:\n\nIn de geïnspecteerde installatie(delen) zijn ##102## stuk(s) met de classificatie ##101##  aangetroffen welke direct aanrakings- of brandgevaar zorgen\n\nIn de geïnspecteerde installatie(delen) zijn ##104## stuk(s) met de classificatie ##103## aangetroffen.\n\nIn de geïnspecteerde installatie(delen) zijn ##106## stuk(s) met de classificatie ##105## aangetroffen.\n\nIndien een of meer van hier bovenstaande opmerkingen aanwezig zijn, dienen de opmerkingen vermeld in dit inspectierapport opgelost te worden.\n\nIn de geïnspecteerde installatie(delen) zijn ##108## stuk(s) met de classificatie ##107## aangetroffen.\n\nIn de geïnspecteerde installatie(delen) zijn ##110## stuk(s) met de classificatie ##109## aangetroffen.\n\nOpmerkingen met de classificatie ##109## moeten worden onderzocht en beoordeeld indien nodig worden opgelost.',
      'visuele_inspectie_titel': '',
      'visuele_inspectie':
          'De visuele controle van elektrisch materieel bestaat uit het controleren van de volgende punten: (B4.1):\n• elektrisch materieel is geïnstalleerd volgens de voorschriften van de fabrikant en geldende installatie- en productnormen; \n• elektrisch materieel is geschikt voor de omgeving; \n• elektrisch materieel is veilig voor het te verwachten gebruik.\nProducteisen volgens NEN-EN-IEC 61439-1 \nDe visuele controle van schakel- en verdeelinrichtingen bestaat uit het controleren van de volgende punten: Algemeen (Let op Conformiteits-\nverklaring)\n• elektrisch materieel is bestand tegen het maximale kortsluitvermogen dat kan optreden; \n• de schakel- en verdeelinrichting wordt gebruikt volgens de productvoorschriften; \n• de schakel- en verdeelinrichting vertoont geen sporen van degeneratie die de veiligheid in gevaar kan brengen; \n• de schakel- en verdeelinrichting vertoont geen sporen van oververhitting; \n• de schakel- en verdeelinrichting is vrij van vuil en vocht; Opmerking: Vuil is o.a. vet, olie, chemicaliën en stof; \n• de overstroombeveiliging van de SVI is juist gekozen; \n• de SVI is geschikt voor zijn omgeving \n• de SVI is geschikt voor de gebruiker\n• de SVI is geschikt voor de bedrijfsomstandigheden, gelet op de voeding vanuit twee of meer voedingsbronnen (7)\n• de SVI voldoet aan de constructie-eisen (8.3, 8.6, 8.8)\n• de SVI heeft de juiste gebruikseigenschappen (9.2, 9.3, 9.3.4)\n• de opstelling en installatie van de overspanningsbeveiliging is juist (NEN-EN-IEC 62305)\nVisuele beoordeling volgens NEN 1010	 \n• De gekozen methode voor bescherming tegen elektrische schok, waaronder metalen gestellen (h.41)\n• De aanwezigheid van brandwerende afschermingen en andere voorzorgsmaatregelen tegen brandverspreiding en ter bescherming tegen thermische invloeden (h4.42 en Rubriek 527)\n• De gekozen beschermingsmethode en keuze van geleiders in verband met de hoogste toelaatbare stroom (h4.43 en Rubriek 523)\n• De keuze, instelling, selectiviteit en coördinatie van beveiligings- en bewakingstoestellen (h43 en Rubriek 536)\n• De keuze, locatie en installatie van geschikte overspanningsafleiders (SPD’s) waar gespecificeerd (h.43 en Rubriek 534)\n• De keuze, locatie en installatie van geschikte scheiders en schakelaars (h.46 en Rubriek)\n• De keuze van het elektrisch materieel en de juiste beschermingsmaatregelen met betrekking tot de uitwendige invloeden en mechanische belasting (Rubrieken 422,512.2 en 522, bijlage 51A/B)\n• De aanduiding van nul- en beschermingsleidingen (Rubriek 514.3)\n• De aanwezigheid van schema\'s en tekeningen, waarschuwingsborden of vergelijkbare informatie (Rubriek 514.5)\n• De aanduiding van stroomketens, beveiligingstoestellen tegen overstroom, schakelaars, aansluitklemmen en dergelijke (Rubriek 214)\n• De deugdelijkheid van de aansluitingen van leidingen (Rubriek 526)\n• De keuze en installatie van beschermingsleidingen, met inbegrip van beschermende vereffeningsleidingen, en hun aansluitingen (h.54)\n• De bereikbaarheid van materieel voor bediening, identificatie en onderhoud (Rubrieken 513 en 514)\n• De maatregelen tegen elektromagnetische verstoringen (Rubriek 444)\n• De vereffening van aanraakbare vreemde geleidende delen (Rubriek 411)\n• De keuze en installatie van de leidingsystemen (Rubrieken 521 en 522)\nDe visuele inspectie moet ook alle speciale bepalingen voor bijzondere installaties of locaties omvatten (Deel 7)\nDe volgorde van het uitvoeren van metingen is van belang. Werkzaamheden waar een cijfer voor de omschrijving staat, moeten in de gegeven volgorde worden uitgevoerd.\n1. Het ononderbroken zijn van geleiders (6.4.3.2)\n2. Isolatieweerstand van de elektrische installatie (6.4.3.3)\nBescherming door SELV-ketens, PELV-ketens of elektrische scheiding (6.4.3.4)\nWeerstand/impedantie van vloeren en wanden (6.4.3.5)\nPolariteit (6.4.3.6)\nAutomatische uitschakeling van de voeding (B4.6 (6.4.3.7))\nAanvullende bescherming (B4.5 en 6.4.3.8)\nVerificatie van de fasevolgorde (6.4.3.9)\nFunctionele beproevingen (6.4.3.10)\nSpanningsverlies (B4.3)\nOnonderbroken zijn van de beschermingsleiding: \n1. Verbindingen in de schakel- en verdeelinrichtingen, 2. Contactdozen, 3. Verlichtingsarmaturen, 4. Overige vast aangesloten elektrisch materieel\nOnonderbroken zijn van de beschermingsleidingen bijzondere ruimte volgens NEN 1010 deel 7: \n1. Verbindingen in de schakel- en verdeelinrichtingen, 2. Contactdozen, 3. Verlichtingsarmaturen, 4. Overige vast aangesloten elektrisch materieel\nOnonderbroken zijn van de vereffeningsleidingen\nOnonderbroken zijn van de vereffeningsleidingen in bijzondere ruimten*\nAardlekbeveiliging (B4.5)\nGoede werking van: \n• Scheiders in schakel- en verdeelinrichtingen \n• Werkschakelaars \n• Veiligheidsketens\nCircuitimpedantie P-N of P-P: (B4.6)\n• Schakel- en verdeelinrichtingen \n• Contactdozen \n• Vast aangesloten apparaten\nCircuitimpedantie P-PE: (B4.6)\n• Schakel- en verdeelinrichtingen klasse 1 \n• Contactdozen \n• Vast aangesloten apparaten\n*Bijzondere ruimten zijn ruimten die beschreven worden in NEN 1010 deel 7.\nVerificatie dat de elektrische uitrusting overeenstemt met de technische documentatie (18.1)\nVerificatie van het ononderbroken zijn van de beschermingsketen (Beproeving 1 van 18.2.2)\nBij foutbescherming door automatische uitschakeling van de voeding moeten de voorwaarden voor de bescherming door automatische uitschakeling worden geverifieerd (18.2)\nMeting van de isolatieweerstand (18.3)\nSpanningsbeproeving (18.4)\nBescherming tegen restspanningen (18.5)\nVerificatie dat aan de relevante eisen wordt voldaan (8.2.6)\nFunctionele beproevingen (18.6)\n',
      'visuele_inspectie_toelichting': '',
      'metingen_titel': '',
      'metingen': '',
      'metingen_toelichting': '',
      'aanvullend_onderzoek_titel': '',
      'aanvullend_onderzoek': '',
      'aanvullend_onderzoek_toelichting': '',
      'lijst4_titel': '',
      'lijst4': '',
      'lijst4_toelichting': '',
      'vinklijst_afkeuringscriteria':
          'Bij een gebrek of afwijking van een standaard met onmiddellijk gevaar is het volgende uitgevoerd:\n- het wordt onmiddellijk uit bedrijf genomen en bovendien beveiligd tegen opnieuw inschakelen en/of;\n- het wordt onmiddellijk hersteld en/of;\n- het wordt direct gemeld aan de opdrachtgever.\n\nGebreken worden geclassificeerd volgens SCIOS Informatieblad 22. De classificatie volgens IB22 is als volgt:\n\nErnstig - Rood\n• Het gevaar op letsel is voortdurend aanwezig of;\n• Schade met verstrekkende gevolgen.\n\nActie\nEr moeten direct maatregelen worden genomen. Indien bereikbaar onder normale bedrijfsomstandigheden:\n• Deze constatering moet mondeling en schriftelijk worden gemeld;\n• Direct veiligstellen/verhelpen/oplossen.\n\nSerieus - Oranje\nBij een voorzienbare gebeurtenis of een enkele fout:\n• Het gevaar van blijvend letsel/ onherstelbaar letsel kan zich voor doen of\n• Schade met aanzienlijke gevolgen\n\nActie\n• Schriftelijk vastleggen in een inspectierapport.\n• Moet binnen 3 maanden worden hersteld\n\nGering - Geel\n• Het gevaar van herstelbaar letsel kan zich voordoen of;\n• Schade kan gevolgen hebben.\n\nActie\n• Schriftelijk vastleggen in een inspectierapport.\n• Moet binnen 3 maanden worden hersteld\n\nOpmerking - Blauw\n• Er is minimaal gevaar/voldoet niet aan de uitgangspunten of;\n• Het gevolg levert onder normale bedrijfsomstandigheden geen gevaar op.\n\nActie\nSchriftelijk vastleggen in een inspectierapport, indien overeengekomen.\n\nNO - Nader onderzoek is noodzakelijk\nDe opmerkingen met de classificatie NO zijn ten tijde van de inspectie niet nader door de inspecteur onderzocht. De reden hiervan is dat er niet voldoende gegevens beschikbaar waren. Er kan niet worden vastgesteld of de opmerkingen met kwalificatie NO een gebrek is. Vervolgafspraken moeten worden gemaakt.',
    },
    {
      'type_rapport': '~EPM_SCOPE_10',
      'rapporttitel': 'Inspectie SCIOS SCOPE 10',
      'subtitel':
          'Methode voor het beoordelen van elektrisch materieel op brandrisico',
      'inleiding':
          'In dit inspectierapport zijn de bevindingen beschreven van een inspectie op elektrisch materieel. De inspectie is uitgevoerd volgens de uitgangspunten van  SCIOS scope 10 wat gebaseerd is op NTA 8220.\n\nIn opdracht van  ##10## te ##11## is op  ##20## door ##50##. afdeling Inspectie & Beheer de inspectie uitgevoerd. Deze inspectie is uitgevoerd in het pand aan de ##30## te ##31##. De inspectiewerkzaamheden zijn uitgevoerd volgens project ##22##.\n\nHet doel van een SCIOS scope 10 inspectie is het beoordelen van brandrisico\'s van elektrische materieel. \n\nDe inspectie heeft bestaan uit:\n- Een visuele inspectie;\n- Metingen en beproevingen;\n- Een aanvullend onderzoek door thermografie.\n\nAls er tijdens de inspectie gebreken zijn geconstateerd, worden deze gebreken vermeld in de bijlage "Overzicht van gebreken".\n\nDe rapportage is een jaar geldig. De geldigheid wordt geteld vanaf de laatste inspectiedatum.\n\nNa de inspectie wordt in het SCIOS-portaal de inspectie afgemeld met of zonder constateringen. Een verklaring zonder constateringen. Een rapportage met constateringen kan binnen een jaar na inspectiedatum worden omgezet naar een verklaring zonder constateringen.',
      'tekst_rapport_verklaring':
          'Er is een inspectie uitgevoerd volgens SCIOS SCOPE 10. Tijdens de inspectie zijn:\n\nIn de geïnspecteerde installatie(delen) zijn ##102## stuk(s) met de classificatie ##101##  aangetroffen welke direct aanrakings- of brandgevaar zorgen\n\nIn de geïnspecteerde installatie(delen) zijn ##104## stuk(s) met de classificatie ##103## aangetroffen.\n\nIn de geïnspecteerde installatie(delen) zijn ##106## stuk(s) met de classificatie ##105## aangetroffen.\n\nIndien een of meer van hier bovenstaande opmerkingen aanwezig zijn, dienen de opmerkingen vermeld in dit inspectierapport opgelost te worden.\n\nIn de geïnspecteerde installatie(delen) zijn ##108## stuk(s) met de classificatie ##107## aangetroffen.\n\nIn de geïnspecteerde installatie(delen) zijn ##110## stuk(s) met de classificatie ##109## aangetroffen.\n\nOpmerkingen met de classificatie ##109## moeten worden onderzocht en beoordeeld indien nodig worden opgelost.',
      'visuele_inspectie_titel': 'Bedrijfsomstandigheden',
      'visuele_inspectie':
          '1)	Elektrisch materieel moet geschikt zijn voor de belastingsstromen.\n2)	Elektrisch materieel moet geschikt zijn voor de kortsluitstromen die kunnen optreden.\n3)	Elektrisch materieel moet geschikt zijn voor de stootspanningen die kunnen optreden.\n4)	Elektrisch materieel moet geschikt zijn voor het feitelijk of voorzienbaar gebruik.\n5)	Waar relevant moet elektrisch materieel periodiek worden onderhouden.',
      'visuele_inspectie_toelichting': '',
      'metingen_titel': 'Wederzijdse beïnvloeding',
      'metingen':
          '1)	De oppervlaktetemperatuur mag niet hoger zijn dan de specificatie van de fabrikant voorschrijft.\n2)	Elektrisch materieel moet vrij staan en voldoende afstand hebben tot brandbaar materiaal.\n3)	Elektrisch materieel met een oppervlaktetemperatuur hoger dan 90 °C moet voldoende afstand hebben \n	tot brandbaar materiaal of daarvan zijn afgeschermd.\n4)	De luchtspleet tussen blanke delen die onder spanning staan moet voldoende groot zijn.',
      'metingen_toelichting': '',
      'aanvullend_onderzoek_titel': 'Uitwendige invloeden',
      'aanvullend_onderzoek':
          '1)	Elektrisch materieel moet geschikt zijn voor de omgevingstemperatuur.\n2)	Bij de aanwezigheid van water of vocht moet elektrisch materieel aanvullend zijn beschermd.\n3)	Bij de aanwezigheid van water of vocht moet elektrisch materieel de juiste beschermingsgraad hebben.\n4)	Bij de aanwezigheid van vreemde voorwerpen of stof moet elektrisch materieel \n	aanvullend zijn beschermd.\n5)	Bij de aanwezigheid van vreemde voorwerpen of stof moet elektrisch materieel de \n	juiste beschermingsgraad hebben.\n6)	Bij de aanwezigheid van corrosieve of verontreinigende stoffen moet elektrisch materieel aanvullend zijn \n	beschermd.\n7)	Bij de aanwezigheid van corrosieve of verontreinigende stoffen moet elektrisch materieel de juiste \n	beschermingsgraad hebben.\n8)	Bij de aanwezigheid van de kans op stootbelasting moet elektrisch materieel daarvoor geschikt zijn of \n	aanvullend zijn beschermd.\n9)	Bij aanwezigheid van trillingen moet elektrisch materieel daartegen bestand zijn.\n10)	Bij de aanwezigheid van dieren mag elektrisch materieel daardoor niet kunnen worden aangetast.\n11)	Als elektrisch materieel wordt blootgesteld aan UV-straling dan moet het elektrisch materieel daarvoor \n	geschikt zijn of aanvullend zijn beschermd.\n12)	Als elektrisch materieel wordt blootgesteld aan externe warmtebronnen dan moet het elektrisch materieel \n	daarvoor geschikt zijn of aanvullend zijn beschermd.\n13)	Elektrisch materieel mag geen isolatiefout hebben.\n14)	Elektrisch materieel moet uitwendig vrij zijn van vervuiling zoals brandbaar stof en geleidend stof.\n15)	Elektrisch materieel moet inwendig vrij zijn van vervuiling zoals brandbaar stof, geleidend stof en vocht.',
      'aanvullend_onderzoek_toelichting':
          'Indien blijkt dat tijdens de inspectie de huidige norm strenger is of sterk afwijkt t.o.v. het rechtens verkregen niveau dan zal  indien wettelijk toegestaan de dan geldige norm worden toegepast.',
      'lijst4_titel': 'Automatisch uitschakelen van de voeding',
      'lijst4':
          '1)	Automatisch uitschakelen van de voeding\n2)	Circuitimpedantie tussen fasegeleider en beschermingsgeleider\n3)	Onderbreking van de beschermingsgeleider.\n4)	Werking van de aardlekschakelaar.\n5)	Een leiding moet op correcte wijze tegen overbelasting zijn beveiligd.\n6)	Een leiding moet op correcte wijze tegen kortsluiting zijn beveiligd.Beveiliging tegen overspanning.',
      'lijst4_toelichting': '',
      'vinklijst_afkeuringscriteria':
          'Bij een gebrek of afwijking van een standaard met onmiddellijk gevaar is het volgende uitgevoerd:\n- het wordt onmiddellijk uit bedrijf genomen en bovendien beveiligd tegen opnieuw inschakelen en/of;\n- het wordt onmiddellijk hersteld en/of;\n- het wordt direct gemeld aan de opdrachtgever.\n\nGebreken worden geclassificeerd volgens SCIOS Informatieblad 22. De classificatie volgens IB22 is als volgt:\n\nErnstig - Rood\n• Het gevaar op letsel is voortdurend aanwezig of;\n• Schade met verstrekkende gevolgen.\n\nActie\nEr moeten direct maatregelen worden genomen. Indien bereikbaar onder normale bedrijfsomstandigheden:\n• Deze constatering moet mondeling en schriftelijk worden gemeld;\n• Direct veiligstellen/verhelpen/oplossen.\n\nSerieus - Oranje\nBij een voorzienbare gebeurtenis of een enkele fout:\n• Het gevaar van blijvend letsel/ onherstelbaar letsel kan zich voor doen of\n• Schade met aanzienlijke gevolgen\n\nActie\n• Schriftelijk vastleggen in een inspectierapport.\n• Moet binnen 3 maanden worden hersteld\n\nGering - Geel\n• Het gevaar van herstelbaar letsel kan zich voordoen of;\n• Schade kan gevolgen hebben.\n\nActie\n• Schriftelijk vastleggen in een inspectierapport.\n• Moet binnen 3 maanden worden hersteld\n\nOpmerking - Blauw\n• Er is minimaal gevaar/voldoet niet aan de uitgangspunten of;\n• Het gevolg levert onder normale bedrijfsomstandigheden geen gevaar op.\n\nActie\nSchriftelijk vastleggen in een inspectierapport, indien overeengekomen.\n\nNO - Nader onderzoek is noodzakelijk\nDe opmerkingen met de classificatie NO zijn ten tijde van de inspectie niet nader door de inspecteur onderzocht. De reden hiervan is dat er niet voldoende gegevens beschikbaar waren. Er kan niet worden vastgesteld of de opmerkingen met kwalificatie NO een gebrek is. Vervolgafspraken moeten worden gemaakt.',
    },
    {
      'type_rapport': '~EPM_SCOPE_12_PI',
      'rapporttitel': 'Inspectie SCIOS SCOPE 12 PI',
      'subtitel': 'Zonnestroominstallatie',
      'inleiding':
          'In dit inspectierapport zijn de bevindingen beschreven van een inspectie van een zonnestroominstallatie volgens SCIOS SCOPE 12 EBI. De inspectie is uitgevoerd volgens de uitgangspunten van NEN 1010 en IEC 62446-1.\n\nIn opdracht van  ##10## te ##11## is op  ##20## door ##50##. afdeling Inspectie & Beheer de inspectie uitgevoerd. Deze inspectie is uitgevoerd in en op het pand aan de ##30## te ##31##. De inspectiewerkzaamheden zijn uitgevoerd volgens project ##22##.\n\nHet doel van deze inspectie is het beoordelen of de zonnestroominstallatie voldoet aan de gestelde eisen zoals beschreven in de genoemde standaarden.\n\nDe inspectie heeft bestaan uit:\n- Een visuele inspectie;\n- Metingen en beproevingen.\n\nAls er tijdens de inspectie gebreken zijn geconstateerd, worden deze gebreken vermeld in de bijlage "Overzicht van gebreken".\n\nDe rapportage is een jaar geldig. De geldigheid wordt geteld vanaf de laatste inspectiedatum.\n\nNa de inspectie wordt in het SCIOS-portaal de inspectie afgemeld met of zonder constateringen. Een verklaring zonder constateringen. Een rapportage met constateringen kan binnen een jaar na inspectiedatum worden omgezet naar een verklaring zonder constateringen.',
      'tekst_rapport_verklaring':
          'Er is een inspectie uitgevoerd volgens SCIOS SCOPE 12 PI. Tijdens de inspectie zijn:\n\nIn de geïnspecteerde installatie(delen) zijn ##102## stuk(s) met de classificatie ##101##  aangetroffen welke direct aanrakings- of brandgevaar zorgen\n\nIn de geïnspecteerde installatie(delen) zijn ##104## stuk(s) met de classificatie ##103## aangetroffen.\n\nIn de geïnspecteerde installatie(delen) zijn ##106## stuk(s) met de classificatie ##105## aangetroffen.\n\nIndien een of meer van hier bovenstaande opmerkingen aanwezig zijn, dienen de opmerkingen vermeld in dit inspectierapport opgelost te worden.\n\nIn de geïnspecteerde installatie(delen) zijn ##108## stuk(s) met de classificatie ##107## aangetroffen.\n\nIn de geïnspecteerde installatie(delen) zijn ##110## stuk(s) met de classificatie ##109## aangetroffen.\n\nOpmerkingen met de classificatie ##109## moeten worden onderzocht en beoordeeld indien nodig worden opgelost.',
      'visuele_inspectie_titel': 'Visuele beoordeling Algemeen',
      'visuele_inspectie':
          'De visuele controle wordt aangevuld met de volgende punten:\n-	elektrisch materieel is geïnstalleerd en wordt gebruikt volgens de voorschriften van de fabrikant \n	en geldende installatie- en productnormen;\n-	elektrisch materieel is geschikt voor de gebruiker;\n-	elektrisch materieel is geschikt voor zijn omgeving;\n-	elektrisch materieel is veilig voor gebruik.\n-	de zonnestroominstallatie mag andere installaties niet nadelig beïnvloeden\n-	de noodzakelijke informatie aanwezig is en de juiste informatie vermeld is\n-	de elektrische installatie past bij de huidige gebruikseisen.\n-	er geen zichtbare tekenen van oververhitting zijn\n\nGedurende de visuele inspectie wordt vastgesteld of de pv-installatie de brandveiligheid van het bouwwerk niet nadelig beïnvloed, met als minimale aandachtspunten:\n-	is de omvormer in de nabijheid van brandbaar materiaal geïnstalleerd?\n-	is de installatie over een brandscheiding aangebracht?\n-	liggen de panelen binnen gepaste afstand van lichtstraten of brandscheidingen\n\nConstructie:\n-	Controle zonnestroominstallatie en plaatsing ten opzichte van EBI-verslag (basisverslag).\n-	Het daksysteem aangelegd volgens het ballastplan\n',
      'visuele_inspectie_toelichting': '',
      'metingen_titel': 'Visuele beoordeling AC/DC-installatie algemeen',
      'metingen':
          'Elektrisch materieel:\n-	voldoet aan de veiligheidsbepalingen in de relevante productnormen en aan de instructies van \n	de fabrikant\n-	is gekozen en geïnstalleerd volgens NEN 1010, IEC 61439-1 en volgens de instructies van de fabrikant;\n\nBij de inspectie moet ten minste het volgende worden nagegaan:\n-	de keuze en instelling van beveiligingen bewakingstoestellen\n-	de deugdelijkheid van de aansluitingen van geleiders\n-	de aanwezigheid en geschiktheid van beschermingsleidingen, met inbegrip van beschermende \n	en aanvullende vereffeningsleidingen\n\nAC-installatie SVI\n-	Voldoet aan de constructie eisen\n-	De juiste gebruikseigenschappen heeft ',
      'metingen_toelichting': '',
      'aanvullend_onderzoek_titel': 'Metingen en beproevingen AC-installatie',
      'aanvullend_onderzoek':
          'Elektrisch materieel:\n-	voldoet aan de veiligheidsbepalingen in de relevante productnormen en aan de instructies van \n	de fabrikant\n-	is gekozen en geïnstalleerd volgens NEN 1010, IEC 61439-1 en volgens de instructies van de fabrikant;\n\nBij de inspectie moet ten minste het volgende worden nagegaan:\n-	de gekozen methode voor bescherming tegen elektrische schok\n-	de aanwezigheid van brandwerende afschermingen en andere voorzorgsmaatregelen tegen \n	brandverspreiding en ter bescherming tegen thermische invloeden\n-	de keuze van geleiders in verband met de hoogste toelaatbare stroom en het spanningsverlies.\n-	de keuze en instelling van beveiligingsen bewakingstoestellen\n-	de aanwezigheid van geschikte scheiders en schakelaars op de juiste plaatsen\n-	de keuze van het elektrisch materieel en de juiste beschermingsmaatregelen met betrekking tot \n	de uitwendige invloeden\n-	de deugdelijkheid van de aansluitingen van geleiders\n-	de aanwezigheid en geschiktheid van beschermingsleidingen, met inbegrip van beschermende \n	en aanvullende vereffeningsleidingen\n\nAC-installatie SVI\n-	Is geschikt voor de bedrijfsomstandigheden. Specifiek gelet op dubbele invoeding\n-	Voldoet aan de constructie eisen\n-	De juiste gebruikseigenschappen heeft \n-	Opstelling en installatie van overspanningsbeveiliging juist is\n\nDC-installatie\nTijdens de inspectie van de DC zijde moet worden beoordeelt dat de:\n-	de juiste installatie van de kabelwegen\n-	maximale PV-array spanning niet overschreden wordt\n-	installatie bestand is tegen uitwendige invloeden als wind, sneeuw temperatuur en corrosie\n-	bevestiging op het dak en dak doorvoeren waterbestendig zijn\n		• Bescherming tegen elektrische schok\n		• Bescherming tegen effecten van isolatiefouten\n		• Bescherming tegen overstroom\n		• Veiligheidsaarding en vereffening\n		• Bescherming tegen effecten van bliksem en overspanning\n		• Keuze en montage van elektrische materieel\n',
      'aanvullend_onderzoek_toelichting':
          'Indien blijkt dat tijdens de inspectie de huidige norm strenger is of sterk afwijkt t.o.v. het rechtens verkregen niveau dan zal  indien wettelijk toegestaan de dan geldige norm worden toegepast.',
      'lijst4_titel': 'Metingen en beproevingen DC-installatie',
      'lijst4':
          '-	Ononderbroken van zijn de beschermingsen vereffeningsleidingen\n-	Uitvoeren van de polariteitstest van DC bekabeling.\n-	Strengcombinatietest. Indien meerdere strengen zijn gecombineerd, kan een streng met \n	verwisselde polariteit over het hoofd worden gezien. De -	polariteit behoort te worden gecontroleerd.\n-	Meting van de open klemspanning UOC. De gemeten waarde per streng UOC behoort te worden \n	vergeleken met de verwachte UOC.\n-	Meting van de DC-stroom: kortsluitstroom ISC (of de operationele stroom).\n-	Functionele beproeving (schakelaars, omvormer, test bij wegvallen van de spanning, testprocedure \n	omvormer volgens voorschrift fabrikant).\n-	Meting van de isolatieweerstand DC-circuits',
      'lijst4_toelichting': '',
      'vinklijst_afkeuringscriteria':
          'Bij een gebrek of afwijking van een standaard met onmiddellijk gevaar is het volgende uitgevoerd:\n- het wordt onmiddellijk uit bedrijf genomen en bovendien beveiligd tegen opnieuw inschakelen en/of;\n- het wordt onmiddellijk hersteld en/of;\n- het wordt direct gemeld aan de opdrachtgever.\n\nGebreken worden geclassificeerd volgens SCIOS Informatieblad 22. De classificatie volgens IB22 is als volgt:\n\nErnstig - Rood\n• Het gevaar op letsel is voortdurend aanwezig of;\n• Schade met verstrekkende gevolgen.\n\nActie\nEr moeten direct maatregelen worden genomen. Indien bereikbaar onder normale bedrijfsomstandigheden:\n• Deze constatering moet mondeling en schriftelijk worden gemeld;\n• Direct veiligstellen/verhelpen/oplossen.\n\nSerieus - Oranje\nBij een voorzienbare gebeurtenis of een enkele fout:\n• Het gevaar van blijvend letsel/ onherstelbaar letsel kan zich voor doen of\n• Schade met aanzienlijke gevolgen\n\nActie\n• Schriftelijk vastleggen in een inspectierapport.\n• Moet binnen 3 maanden worden hersteld\n\nGering - Geel\n• Het gevaar van herstelbaar letsel kan zich voordoen of;\n• Schade kan gevolgen hebben.\n\nActie\n• Schriftelijk vastleggen in een inspectierapport.\n• Moet binnen 3 maanden worden hersteld\n\nOpmerking - Blauw\n• Er is minimaal gevaar/voldoet niet aan de uitgangspunten of;\n• Het gevolg levert onder normale bedrijfsomstandigheden geen gevaar op.\n\nActie\nSchriftelijk vastleggen in een inspectierapport, indien overeengekomen.\n\nNO - Nader onderzoek is noodzakelijk\nDe opmerkingen met de classificatie NO zijn ten tijde van de inspectie niet nader door de inspecteur onderzocht. De reden hiervan is dat er niet voldoende gegevens beschikbaar waren. Er kan niet worden vastgesteld of de opmerkingen met kwalificatie NO een gebrek is. Vervolgafspraken moeten worden gemaakt.',
    },
    {
      'type_rapport': '~EPM_SCOPE_12_EBI',
      'rapporttitel': 'Inspectie SCIOS SCOPE 12 EBI',
      'subtitel': 'Zonnestroominstallatie',
      'inleiding':
          'In dit inspectierapport zijn de bevindingen beschreven van een inspectie van een zonnestroominstallatie volgens SCIOS SCOPE 12 EBI. De inspectie is uitgevoerd volgens de uitgangspunten van NEN 1010 en IEC 62446-1.\n\nIn opdracht van  ##10## te ##11## is op  ##20## door ##50##. afdeling Inspectie & Beheer de inspectie uitgevoerd. Deze inspectie is uitgevoerd in en op het pand aan de ##30## te ##31##. De inspectiewerkzaamheden zijn uitgevoerd volgens project ##22##.\n\nHet doel van deze inspectie is het beoordelen of de zonnestroominstallatie voldoet aan de gestelde eisen zoals beschreven in de genoemde standaarden.\n\nDe inspectie heeft bestaan uit:\n- Een visuele inspectie;\n- Metingen en beproevingen.\n\nAls er tijdens de inspectie gebreken zijn geconstateerd, worden deze gebreken vermeld in de bijlage "Overzicht van gebreken".\n\nDe rapportage is een jaar geldig. De geldigheid wordt geteld vanaf de laatste inspectiedatum.\n\nNa de inspectie wordt in het SCIOS-portaal de inspectie afgemeld met of zonder constateringen. Een verklaring zonder constateringen. Een rapportage met constateringen kan binnen een jaar na inspectiedatum worden omgezet naar een verklaring zonder constateringen.',
      'tekst_rapport_verklaring':
          'Er is een inspectie uitgevoerd volgens SCIOS SCOPE 12 EBI. Tijdens de inspectie zijn:\n\nIn de geïnspecteerde installatie(delen) zijn ##102## stuk(s) met de classificatie ##101##  aangetroffen welke direct aanrakings- of brandgevaar zorgen\n\nIn de geïnspecteerde installatie(delen) zijn ##104## stuk(s) met de classificatie ##103## aangetroffen.\n\nIn de geïnspecteerde installatie(delen) zijn ##106## stuk(s) met de classificatie ##105## aangetroffen.\n\nIndien een of meer van hier bovenstaande opmerkingen aanwezig zijn, dienen de opmerkingen vermeld in dit inspectierapport opgelost te worden.\n\nIn de geïnspecteerde installatie(delen) zijn ##108## stuk(s) met de classificatie ##107## aangetroffen.\n\nIn de geïnspecteerde installatie(delen) zijn ##110## stuk(s) met de classificatie ##109## aangetroffen.\n\nOpmerkingen met de classificatie ##109## moeten worden onderzocht en beoordeeld indien nodig worden opgelost.',
      'visuele_inspectie_titel': 'Visuele beoordeling Algemeen',
      'visuele_inspectie':
          'De visuele controle wordt aangevuld met de volgende punten:\n-	elektrisch materieel is geïnstalleerd en wordt gebruikt volgens de voorschriften van de fabrikant \n	en geldende installatie- en productnormen;\n-	elektrisch materieel is geschikt voor de gebruiker;\n-	elektrisch materieel is geschikt voor zijn omgeving;\n-	elektrisch materieel is veilig voor gebruik.\n-	de zonnestroominstallatie mag andere installaties niet nadelig beïnvloeden\n-	de noodzakelijke informatie aanwezig is en de juiste informatie vermeld is\n-	de elektrische installatie past bij de huidige gebruikseisen.\n-	er geen zichtbare tekenen van oververhitting zijn\n\nGedurende de visuele inspectie wordt vastgesteld of de pv-installatie de brandveiligheid van het bouwwerk niet nadelig beïnvloed, met als minimale aandachtspunten:\n-	is de omvormer in de nabijheid van brandbaar materiaal geïnstalleerd?\n-	is de installatie over een brandscheiding aangebracht?\n-	liggen de panelen binnen gepaste afstand van lichtstraten of brandscheidingen\n\nConstructie\n-	Controle aanwezigheid goedgekeurde constructieberekening van het dak inclusief \n	de zonnestroominstallatie.\n-	Controle installatie en plaatsing ten opzichte van constructieberekening.\n-	Het daksysteem aangelegd volgens het ballastplan\n\nBij in-dak-systemen:\n-	is de brandwerendheid van de dakisolatie voldoende\n-	blokkering van luchtstromen of risico daarop\n-	voldoende ruimte tussen paneel en isolatie\n-	voldoende ventilatie\n',
      'visuele_inspectie_toelichting': '',
      'metingen_titel': 'Visuele beoordeling AC/DC-installatie algemeen',
      'metingen':
          'Elektrisch materieel:\n-	voldoet aan de veiligheidsbepalingen in de relevante productnormen en aan de instructies van \n	de fabrikant\n-	is gekozen en geïnstalleerd volgens NEN 1010, IEC 61439-1 en volgens de instructies van de fabrikant;\n\nBij de inspectie moet ten minste het volgende worden nagegaan:\n-	de gekozen methode voor bescherming tegen elektrische schok\n-	de aanwezigheid van brandwerende afschermingen en andere voorzorgsmaatregelen tegen \n	brandverspreiding en ter bescherming tegen thermische invloeden\n-	de keuze van geleiders in verband met de hoogste toelaatbare stroom en het spanningsverlies.\n-	de keuze en instelling van beveiligingsen bewakingstoestellen\n-	de aanwezigheid van geschikte scheiders en schakelaars op de juiste plaatsen\n-	de keuze van het elektrisch materieel en de juiste beschermingsmaatregelen met betrekking tot \n	de uitwendige invloeden\n-	de deugdelijkheid van de aansluitingen van geleiders\n-	de aanwezigheid en geschiktheid van beschermingsleidingen, met inbegrip van beschermende \n	en aanvullende vereffeningsleidingen\n\nAC-installatie SVI\n-	Is geschikt voor de bedrijfsomstandigheden. Specifiek gelet op dubbele invoeding\n-	Voldoet aan de constructie eisen\n-	De juiste gebruikseigenschappen heeft \n-	Opstelling en installatie van overspanningsbeveiliging juist is\n\nDC-installatie\nTijdens de inspectie van de DC zijde moet worden beoordeelt dat de:\n-	de juiste installatie van de kabelwegen\n-	maximale PV-array spanning niet overschreden wordt\n-	installatie bestand is tegen uitwendige invloeden als wind, sneeuw temperatuur en corrosie\n-	bevestiging op het dak en dak doorvoeren waterbestendig zijn\n		• Bescherming tegen elektrische schok\n		• Bescherming tegen effecten van isolatiefouten\n		• Bescherming tegen overstroom\n		• Veiligheidsaarding en vereffening\n		• Bescherming tegen effecten van bliksem en overspanning\n		• Keuze en montage van elektrische materieel\n',
      'metingen_toelichting': '',
      'aanvullend_onderzoek_titel': 'Metingen en beproevingen AC-installatie',
      'aanvullend_onderzoek':
          '-	Ononderbroken van zijn de beschermingsen vereffeningsleidingen\n-	Meting van de isolatieweerstand\n-	Beproeving van het toestel voor aardlekbeveiliging (indien toegepast).\n-	De circuitimpedanties van de foutstroomketens\n-	Bepalen van het spanningsverlies op de aansluiting van de omvormer',
      'aanvullend_onderzoek_toelichting': '',
      'lijst4_titel': 'Metingen en beproevingen DC-installatie',
      'lijst4':
          '-	Ononderbroken van zijn de beschermingsen vereffeningsleidingen\n-	Uitvoeren van de polariteitstest van DC bekabeling.\n-	Strengcombinatietest. Indien meerdere strengen zijn gecombineerd, kan een streng met \n	verwisselde polariteit over het hoofd worden gezien. De -	polariteit behoort te worden gecontroleerd.\n-	Meting van de open klemspanning UOC. De gemeten waarde per streng UOC behoort te worden \n	vergeleken met de verwachte UOC.\n-	Meting van de DC-stroom: kortsluitstroom ISC (of de operationele stroom).\n-	Functionele beproeving (schakelaars, omvormer, test bij wegvallen van de spanning, testprocedure \n	omvormer volgens voorschrift fabrikant).\n-	Meting van de isolatieweerstand DC-circuits',
      'lijst4_toelichting': '',
      'vinklijst_afkeuringscriteria':
          'Bij een gebrek of afwijking van een standaard met onmiddellijk gevaar is het volgende uitgevoerd:\n- het wordt onmiddellijk uit bedrijf genomen en bovendien beveiligd tegen opnieuw inschakelen en/of;\n- het wordt onmiddellijk hersteld en/of;\n- het wordt direct gemeld aan de opdrachtgever.\n\nGebreken worden geclassificeerd volgens SCIOS Informatieblad 22. De classificatie volgens IB22 is als volgt:\n\nErnstig - Rood\n• Het gevaar op letsel is voortdurend aanwezig of;\n• Schade met verstrekkende gevolgen.\n\nActie\nEr moeten direct maatregelen worden genomen. Indien bereikbaar onder normale bedrijfsomstandigheden:\n• Deze constatering moet mondeling en schriftelijk worden gemeld;\n• Direct veiligstellen/verhelpen/oplossen.\n\nSerieus - Oranje\nBij een voorzienbare gebeurtenis of een enkele fout:\n• Het gevaar van blijvend letsel/ onherstelbaar letsel kan zich voor doen of\n• Schade met aanzienlijke gevolgen\n\nActie\n• Schriftelijk vastleggen in een inspectierapport.\n• Moet binnen 3 maanden worden hersteld\n\nGering - Geel\n• Het gevaar van herstelbaar letsel kan zich voordoen of;\n• Schade kan gevolgen hebben.\n\nActie\n• Schriftelijk vastleggen in een inspectierapport.\n• Moet binnen 3 maanden worden hersteld\n\nOpmerking - Blauw\n• Er is minimaal gevaar/voldoet niet aan de uitgangspunten of;\n• Het gevolg levert onder normale bedrijfsomstandigheden geen gevaar op.\n\nActie\nSchriftelijk vastleggen in een inspectierapport, indien overeengekomen.\n\nNO - Nader onderzoek is noodzakelijk\nDe opmerkingen met de classificatie NO zijn ten tijde van de inspectie niet nader door de inspecteur onderzocht. De reden hiervan is dat er niet voldoende gegevens beschikbaar waren. Er kan niet worden vastgesteld of de opmerkingen met kwalificatie NO een gebrek is. Vervolgafspraken moeten worden gemaakt.',
    },
    {
      'type_rapport': '~EPM_NEN_3140',
      'rapporttitel': 'Inspectie NEN 3140',
      'subtitel': 'Bedrijfsvoering van elektrische installaties - Laagspanning',
      'inleiding':
          'In dit inspectierapport zijn de bevindingen beschreven van een inspectie volgens NEN 3140 van de elektrische laagspanningsinstallatie. Het doel van inspecties volgens NEN 3140 is gebreken te ontdekken die een veilige bedrijfsvoering kunnen belemmeren. \n\nIn opdracht van  ##10## te ##11## is op  ##20## door EPM B.V. afdeling Inspectie & Beheer een inspectie volgens NEN 3140+A3:2019 uitgevoerd aan de elektrotechnische installaties. Deze inspectie is uitgevoerd in het pand aan de ##30## te ##31##. De inspectiewerkzaamheden zijn uitgevoerd volgens project ##22##.\n\nDe inspectie van de elektrische laagspanningsinstallatie heeft bestaan uit:\n- Een visuele inspectie;\n- Metingen en beproevingen;\n- Een aanvullend onderzoek door thermografie.\n\nAls er tijdens de inspectie gebreken zijn geconstateerd, worden deze gebreken vermeld in de bijlage "Overzicht van gebreken".',
      'tekst_rapport_verklaring':
          'Er is een inspectie uitgevoerd volgens NEN 3140. Tijdens de inspectie zijn:\n\nIn de geïnspecteerde installatie(delen) zijn ##102## stuk(s) met de classificatie ##101##  aangetroffen welke direct aanrakings- of brandgevaar zorgen\n\nIn de geïnspecteerde installatie(delen) zijn ##104## stuk(s) met de classificatie ##103## aangetroffen.\n\nIn de geïnspecteerde installatie(delen) zijn ##106## stuk(s) met de classificatie ##105## aangetroffen.\n\nIndien een of meer van hier bovenstaande opmerkingen aanwezig zijn, dienen de opmerkingen vermeld in dit inspectierapport opgelost te worden.\n\nIn de geïnspecteerde installatie(delen) zijn ##108## stuk(s) met de classificatie ##107## aangetroffen.\n\nIn de geïnspecteerde installatie(delen) zijn ##110## stuk(s) met de classificatie ##109## aangetroffen.\n\nOpmerkingen met de classificatie ##109## moeten worden onderzocht en beoordeeld indien nodig worden opgelost.',
      'visuele_inspectie_titel': 'Visuele inspectie',
      'visuele_inspectie':
          'a)	de noodzakelijke tekeningen aanwezig zijn en de juiste informatie vermeld is;\nb)	de verschillende (installatie)delen eenduidig herkenbaar zijn;\nc)	de eventueel aanwezige beschadigingen geen gevaar veroorzaken;\nd)	er geen zichtbare tekenen van oververhitting zijn,\ne)	het elektrisch materieel ten minste in overeenstemming is met de installatie-eisen, zoals bijvoorbeeld \n	vastgelegd in de productnormen, installatienormen en leveranciersvoorschriften;\nf)	de gangpaden bestemd voor bediening en onderhoud en de vluchtwegen voldoende ruim en goed \n	toegankelijk zijn;\ng)	de verbindingen van de zichtbare beschermingsleidingen, inclusief vereffeningsleidingen, in orde zijn;\nh)	de juiste beveiligingstoestellen aanwezig zijn en juist zijn ingesteld;\ni)	de veiligheidsketens in orde zijn;\nj)	de aanwezige spanningsindicatoren en voltmeters functioneren;\nk)	de elektrische installatie past bij de huidige gebruikseisen.',
      'visuele_inspectie_toelichting': 'NEN 3140 Visuele inspectie',
      'metingen_titel': 'Metingen en beproevingen',
      'metingen':
          'a)	de beschermingsleidingen, inclusief vereffeningsleidingen, en hun verbindingen, zie 5.101.5.3;\nb)	de circuitimpedanties van de foutstroomketens, zie 5.101.5.4;\nc)	de aardverspreidingsweerstand van aardelektroden (het loshalen van de aardleiding kan leiden tot een \n	gevaarlijke situatie), zie 5.101.5.6;\nd)	de isolatieweerstand van elk gedeelte van de elektrische installatie, zie 5.101.5.7;\ne)	de veilige scheiding van stroomketens, zie 5.101.5.8;\nf)	de goede werking van aardlekbeveiligingen, zie 5.101.5.9;\ng)	de goede werking van schakelende beveiligingstoestellen tegen overstroom, zie 5.101.5.10;\nh)	de goede werking van de veiligheidsketens, zie 5.101.5.11;\ni)	de goede werking van veiligheidssignaleringen;\nj)	de deugdelijkheid van de verbindingen, zie 5.101.5.12.',
      'metingen_toelichting': 'NEN 3140 Metingen en beproevingen',
      'aanvullend_onderzoek_titel': '',
      'aanvullend_onderzoek': '',
      'aanvullend_onderzoek_toelichting':
          'Indien blijkt dat tijdens de inspectie de huidige norm strenger is of sterk afwijkt t.o.v. het rechtens verkregen niveau dan zal  indien wettelijk toegestaan de dan geldige norm worden toegepast.\n\nAanvullende onderzoeken zijn op verzoek van de opdrachtgever en optioneel ten opzichte van de norm NEN 3140.',
      'lijst4_titel': '',
      'lijst4': '',
      'lijst4_toelichting': '',
      'vinklijst_afkeuringscriteria': '',
    },
    {
      'type_rapport': '~EPM_NTA_8220',
      'rapporttitel': 'Inspectie NTA 8220',
      'subtitel':
          'Methode voor het beoordelen van elektrisch materieel op brandrisico',
      'inleiding':
          'In dit inspectierapport zijn de bevindingen beschreven van een inspectie op elektrisch materieel. De inspectie is uitgevoerd volgens de uitgangspunten van  SCIOS scope 10 wat gebaseerd is op NTA 8220.\n\nIn opdracht van  ##10## te ##11## is op  ##20## door ##50##. afdeling Inspectie & Beheer de inspectie uitgevoerd. Deze inspectie is uitgevoerd in het pand aan de ##30## te ##31##. De inspectiewerkzaamheden zijn uitgevoerd volgens project ##22##.\n\nHet doel van een SCIOS scope 10 inspectie is het beoordelen van brandrisico\'s van elektrische materieel. \n\nDe inspectie heeft bestaan uit:\n- Een visuele inspectie;\n- Metingen en beproevingen;\n- Een aanvullend onderzoek door thermografie.\n\nAls er tijdens de inspectie gebreken zijn geconstateerd, worden deze gebreken vermeld in de bijlage "Overzicht van gebreken".\n\nDe rapportage is een jaar geldig. De geldigheid wordt geteld vanaf de laatste inspectiedatum.\n\nNa de inspectie wordt in het SCIOS-portaal de inspectie afgemeld met of zonder constateringen. Een verklaring zonder constateringen. Een rapportage met constateringen kan binnen een jaar na inspectiedatum worden omgezet naar een verklaring zonder constateringen.',
      'tekst_rapport_verklaring':
          'Er is een inspectie uitgevoerd volgens SCIOS SCOPE 10. Tijdens de inspectie zijn:\n\nIn de geïnspecteerde installatie(delen) zijn ##102## stuk(s) met de classificatie ##101##  aangetroffen welke direct aanrakings- of brandgevaar zorgen\n\nIn de geïnspecteerde installatie(delen) zijn ##104## stuk(s) met de classificatie ##103## aangetroffen.\n\nIn de geïnspecteerde installatie(delen) zijn ##106## stuk(s) met de classificatie ##105## aangetroffen.\n\nIndien een of meer van hier bovenstaande opmerkingen aanwezig zijn, dienen de opmerkingen vermeld in dit inspectierapport opgelost te worden.\n\nIn de geïnspecteerde installatie(delen) zijn ##108## stuk(s) met de classificatie ##107## aangetroffen.\n\nIn de geïnspecteerde installatie(delen) zijn ##110## stuk(s) met de classificatie ##109## aangetroffen.\n\nOpmerkingen met de classificatie ##109## moeten worden onderzocht en beoordeeld indien nodig worden opgelost.',
      'visuele_inspectie_titel': 'Bedrijfsomstandigheden',
      'visuele_inspectie':
          '1)	Elektrisch materieel moet geschikt zijn voor de belastingsstromen.\n2)	Elektrisch materieel moet geschikt zijn voor de kortsluitstromen die kunnen optreden.\n3)	Elektrisch materieel moet geschikt zijn voor de stootspanningen die kunnen optreden.\n4)	Elektrisch materieel moet geschikt zijn voor het feitelijk of voorzienbaar gebruik.\n5)	Waar relevant moet elektrisch materieel periodiek worden onderhouden.',
      'visuele_inspectie_toelichting': '',
      'metingen_titel': 'Wederzijdse beïnvloeding',
      'metingen':
          '1)	De oppervlaktetemperatuur mag niet hoger zijn dan de specificatie van de fabrikant voorschrijft.\n2)	Elektrisch materieel moet vrij staan en voldoende afstand hebben tot brandbaar materiaal.\n3)	Elektrisch materieel met een oppervlaktetemperatuur hoger dan 90 °C moet voldoende afstand hebben \n	tot brandbaar materiaal of daarvan zijn afgeschermd.\n4)	De luchtspleet tussen blanke delen die onder spanning staan moet voldoende groot zijn.',
      'metingen_toelichting': '',
      'aanvullend_onderzoek_titel': 'Uitwendige invloeden',
      'aanvullend_onderzoek':
          '1)	Elektrisch materieel moet geschikt zijn voor de omgevingstemperatuur.\n2)	Bij de aanwezigheid van water of vocht moet elektrisch materieel aanvullend zijn beschermd.\n3)	Bij de aanwezigheid van water of vocht moet elektrisch materieel de juiste beschermingsgraad hebben.\n4)	Bij de aanwezigheid van vreemde voorwerpen of stof moet elektrisch materieel \n	aanvullend zijn beschermd.\n5)	Bij de aanwezigheid van vreemde voorwerpen of stof moet elektrisch materieel de \n	juiste beschermingsgraad hebben.\n6)	Bij de aanwezigheid van corrosieve of verontreinigende stoffen moet elektrisch materieel aanvullend zijn \n	beschermd.\n7)	Bij de aanwezigheid van corrosieve of verontreinigende stoffen moet elektrisch materieel de juiste \n	beschermingsgraad hebben.\n8)	Bij de aanwezigheid van de kans op stootbelasting moet elektrisch materieel daarvoor geschikt zijn of \n	aanvullend zijn beschermd.\n9)	Bij aanwezigheid van trillingen moet elektrisch materieel daartegen bestand zijn.\n10)	Bij de aanwezigheid van dieren mag elektrisch materieel daardoor niet kunnen worden aangetast.\n11)	Als elektrisch materieel wordt blootgesteld aan UV-straling dan moet het elektrisch materieel daarvoor \n	geschikt zijn of aanvullend zijn beschermd.\n12)	Als elektrisch materieel wordt blootgesteld aan externe warmtebronnen dan moet het elektrisch materieel \n	daarvoor geschikt zijn of aanvullend zijn beschermd.\n13)	Elektrisch materieel mag geen isolatiefout hebben.\n14)	Elektrisch materieel moet uitwendig vrij zijn van vervuiling zoals brandbaar stof en geleidend stof.\n15)	Elektrisch materieel moet inwendig vrij zijn van vervuiling zoals brandbaar stof, geleidend stof en vocht.',
      'aanvullend_onderzoek_toelichting':
          'Indien blijkt dat tijdens de inspectie de huidige norm strenger is of sterk afwijkt t.o.v. het rechtens verkregen niveau dan zal  indien wettelijk toegestaan de dan geldige norm worden toegepast.',
      'lijst4_titel': 'Automatisch uitschakelen van de voeding',
      'lijst4':
          '1)	Automatisch uitschakelen van de voeding\n2)	Circuitimpedantie tussen fasegeleider en beschermingsgeleider\n3)	Onderbreking van de beschermingsgeleider.\n4)	Werking van de aardlekschakelaar.\n5)	Een leiding moet op correcte wijze tegen overbelasting zijn beveiligd.\n6)	Een leiding moet op correcte wijze tegen kortsluiting zijn beveiligd.Beveiliging tegen overspanning.',
      'lijst4_toelichting': '',
      'vinklijst_afkeuringscriteria': '',
    },
    {
      'type_rapport': '~EPM_NEN_1010_2015',
      'rapporttitel': 'Inspectie NEN 1010 [2015]',
      'subtitel': 'Elektrische laagspanningsinstallatie',
      'inleiding':
          'Naar aanleiding van het uitvoeren van elektrotechnische werkzaamheden is de elektrische installatie geïnspecteerd. Met dit rapport wordt aangeven of de installatie die geïnstalleerd is, voldoet aan de NEN 1010.\n\nIn opdracht van  ##10## te ##11## is op  ##20## door ##50##. afdeling Inspectie & Beheer de inspectie uitgevoerd. Deze inspectie is uitgevoerd in en op het pand aan de ##30## te ##31##. De inspectiewerkzaamheden zijn uitgevoerd volgens project ##22##.\n\n',
      'tekst_rapport_verklaring': '',
      'visuele_inspectie_titel': 'Visueel',
      'visuele_inspectie':
          'a) de gekozen methode voor bescherming tegen elektrische schok (zie hoofdstuk 41);\nb) de aanwezigheid van brandwerende afschermingen en andere voorzorgsmaatregelen tegen brandverspreiding (zie 42 en rubriek 527);\nc) de keuze van geleiders in verband met de hoogste toelaatbare stroom en het spanningsverlies (zie hfst 43 en de rubrieken 523 en 525);\nd) de keuze en instelling van beveiligings- en bewakingstoestellen (zie hoofdstuk 53);\ne) de aanwezigheid van geschikte scheiders en schakelaars op de juiste plaatsen (zie rubriek 536);\nf) de keuze van het elektrisch materieel en beschermingsmaatregelen met betrekking tot de uitwendige invloeden (rubriek 422, 512.2, 522);\ng) de juiste aanduiding van nul- en beschermingsleidingen (zie 514.3);\nh) de verbinding van enkelpolige schakelaars met de faseleidingen (zie rubriek 536);\ni) de aanwezigheid van schema’s en tekeningen, waarschuwingsborden of andere vergelijkbare informatie (zie 514.5);\nj) de aanduiding van stroomketens, beveiligingstoestellen tegen overstroom, schakelaars, aansluitklemmen en dergelijke (zie rubriek 514);\nk) de deugdelijkheid van de aansluitingen van geleiders (zie rubriek 526);\nl) de aanwezigheid en geschiktheid van beschermingsleidingen, met inbegrip van beschermende en aanvullende vereffeningsleidingen (zie hoofdstuk 54);\nm) de bereikbaarheid van materieel voor bediening, identificatie en onderhoud (zie de rubrieken 513 en 514).',
      'visuele_inspectie_toelichting': '',
      'metingen_titel': 'Metingen en beproeving',
      'metingen':
          'a) het ononderbroken zijn van geleiders (zie 61.3.2);\nb) isolatieweerstand van de elektrische installatie (zie 61.3.3);\nc) bescherming door scheiding van stroomketens bij toepassing van SELV-ketens, PELV-ketens of elektrische scheiding (zie 61.3.4);\nd) isolatieweerstand van vloeren en wanden (zie 61.3.5);\ne) automatische uitschakeling van de voeding (zie 61.3.6);\nf) aanvullende bescherming (zie 61.3.7);\ng) bepaling van de polariteit (zie 61.3.8);\nh) controle op de fasevolgorde (zie 61.3.9);\ni) functionele en operationele beproevingen (zie 61.3.10);\nj) spanningsverlies (zie 61.3.1 1).',
      'metingen_toelichting': '',
      'aanvullend_onderzoek_titel': '',
      'aanvullend_onderzoek': '',
      'aanvullend_onderzoek_toelichting':
          'Nieuwe elektrische installaties worden onderricht aan een eerste inspectie volgens NEN 1010\nDe inspectie wordt uitgevoerd op basis van de NEN 1010:2015+C2:2016 hoofdstuk 61',
      'lijst4_titel': '',
      'lijst4': '',
      'lijst4_toelichting': '',
      'vinklijst_afkeuringscriteria':
          'De beoordelingscriteria van de eerste inspectie van een elektrische installatie zijn beschreven in deel 6 van de NEN 1010. Door het uitvoeren van controle, meting en beproeving, voor zover in redelijkheid uitvoerbaar, wordt getoetst of wordt voldaan aan de eisen van de delen van de NEN 1010.',
    },
    {
      'type_rapport': '~EPM_NEN_1010_2020',
      'rapporttitel': 'Inspectie NEN 1010 [2020]',
      'subtitel': 'Elektrische laagspanningsinstallatie',
      'inleiding':
          'Naar aanleiding van het uitvoeren van elektrotechnische werkzaamheden is de elektrische installatie geïnspecteerd. Met dit rapport wordt aangeven of de installatie die geïnstalleerd is, voldoet aan de NEN 1010.\n\nIn opdracht van  ##10## te ##11## is op  ##20## door ##50##. afdeling Inspectie & Beheer de inspectie uitgevoerd. Deze inspectie is uitgevoerd in en op het pand aan de ##30## te ##31##. De inspectiewerkzaamheden zijn uitgevoerd volgens project ##22##.\n\n',
      'tekst_rapport_verklaring': '',
      'visuele_inspectie_titel': 'Visueel',
      'visuele_inspectie':
          '6.4.2 Visuele inspectie \n6.4.2.1 Visuele inspectie moet voorafgaan aan metingen en beproevingen en moet in het algemeen worden uitgevoerd wanneer de installatie nog spanningsloos is. \n6.4.2.2 Visuele inspectie moet worden uitgevoerd om vast te stellen dat elektrisch materieel dat deel uitmaakt van de vaste installatie: \n	— voldoet aan de veiligheidsbepalingen in de relevante productnormen; \n	OPMERKING Dit kan worden vastgesteld aan de hand van informatie van de fabrikant, merktekens of een certificaat. \n	— is gekozen en geïnstalleerd volgens deze norm en volgens de instructies van de fabrikant; \n	— niet zodanig zichtbaar is beschadigd dat de veiligheid nadelig wordt beïnvloed. \n6.4.2.3 Bij de visuele inspectie moet ten minste en voor zover van toepassing het volgende worden nagegaan: \n	a) de gekozen methode voor bescherming tegen elektrische schok (zie hoofdstuk 41); \n	b) de aanwezigheid van brandwerende afschermingen en andere voorzorgsmaatregelen tegen brandverspreiding en ter bescherming tegen 	thermische invloeden (zie hoofdstuk 42 en rubriek 527); \n	c) de keuze van geleiders in verband met de hoogste toelaatbare stroom (zie hoofdstuk 43 en de rubriek 523); \n	d) de keuze, instelling, selectiviteit en coördinatie van beveiligings- en bewakingstoestellen (zie [C1>[nlb>rubrieken 531 t/m 536 en 538<nlb]C1]); \n	e) de keuze, locatie en installatie van geschikte overspanningsafleiders (SPD’s) waar gespecificeerd (zie rubriek 534); \n	f) de keuze, locatie en installatie van geschikte scheiders en schakelaars (zie rubriek 537); \n	g) de keuze van het elektrisch materieel en de juiste beschermingsmaatregelen met betrekking tot de uitwendige invloeden en mechanische 	belasting (zie rubrieken 422, 512.2 en 522); \n	h) de aanduiding van nul- en beschermingsleidingen (zie 514.3); \n	i) de aanwezigheid van schema’s en tekeningen, waarschuwingsborden of vergelijkbare informatie zie 514.5); \n	j) de aanduiding van stroomketens, beveiligingstoestellen tegen overstroom, schakelaars, aansluitklemmen en dergelijke (zie rubriek 514); \n	k) de deugdelijkheid van de aansluitingen van leidingen (zie rubriek 526); \n	l) de keuze en installatie van beschermingsleidingen, met inbegrip van beschermende vereffeningsleidingen, en hun aansluitingen (zie hoofdstuk 	54); \n	m) de bereikbaarheid van materieel voor bediening, identificatie en onderhoud (zie de rubrieken 513 en 514); \n	n) de maatregelen tegen elektromagnetische verstoringen (zie rubriek 444); \n	o) de vereffening van aanraakbare vreemde geleidende delen (zie rubriek 411); \n	p) de keuze en installatie van de leidingsystemen (zie rubrieken 521 en 522). \nDe visuele inspectie moet ook alle speciale bepalingen voor bijzondere installaties of locaties \nomvatten.',
      'visuele_inspectie_toelichting': '',
      'metingen_titel': 'Meting en beproevingen',
      'metingen':
          'De volgende metingen en beproevingen moeten worden uitgevoerd waar relevant, en wel bij voorkeur in de gegeven volgorde: \na) het ononderbroken zijn van geleiders (zie 6.4.3.2); \nb) isolatieweerstand van de elektrische installatie (zie 6.4.3.3); \nc) bescherming door SELV-ketens, PELV-ketens of elektrische scheiding (zie 6.4.3.4); \nd) weerstand/impedantie van vloeren en wanden (zie 6.4.3.5); \ne) polariteit (zie 6.4.3.6); \nf) automatische uitschakeling van de voeding (zie 6.4.3.7); \ng) aanvullende bescherming (zie 6.4.3.8); \nh) [C1>controle<C1] van de fasevolgorde (zie 6.4.3.9); \ni) functionele beproevingen (zie 6.4.3.10); \nj) spanningsverlies (zie 6.4.3.11). ',
      'metingen_toelichting': '',
      'aanvullend_onderzoek_titel': '',
      'aanvullend_onderzoek': '',
      'aanvullend_onderzoek_toelichting':
          'Nieuwe elektrische installaties worden onderricht aan een eerste inspectie volgens NEN 1010\nDe inspectie wordt uitgevoerd op basis van de NEN 1010:2020+C1:2025 hoofdstuk 6.4',
      'lijst4_titel': '',
      'lijst4': '',
      'lijst4_toelichting': '',
      'vinklijst_afkeuringscriteria':
          'De beoordelingscriteria van de eerste inspectie van een elektrische installatie zijn beschreven in deel 6 van de NEN 1010. Door het uitvoeren van controle, meting en beproeving, voor zover in redelijkheid uitvoerbaar, wordt getoetst of wordt voldaan aan de eisen van de delen van de NEN 1010.',
    },
    {
      'type_rapport': '~EPM_SCOPE_8_PI_10',
      'rapporttitel': 'Inspectie SCIOS SCOPE 8 PI en SCOPE 10',
      'subtitel':
          'Elektrische laagspanningsinstallatie en Methode voor het beoordelen van elektrisch materieel op brandrisico',
      'inleiding':
          'In dit inspectierapport zijn de bevindingen beschreven van een inspectie op elektrisch materieel. De inspectie is uitgevoerd volgens de uitgangspunten van  SCIOS SCOPE 8 PI wat gebaseerd is op NEN 3140 en SCIOS SCOPE 10 wat gebaseerd is op NTA 8220.\n\nIn opdracht van  ##10## te ##11## is op  ##20## door ##50##. afdeling Inspectie & Beheer de inspectie uitgevoerd. Deze inspectie is uitgevoerd in het pand aan de ##30## te ##31##. De inspectiewerkzaamheden zijn uitgevoerd volgens project ##22##.\n\nHet doel van een SCIOS SCOPE 10 (NTA 8220) inspectie is het beoordelen van brandrisico\'s van elektrische materieel. Het doel van van een SCIOS SCOPE 8 (NEN 3140) is het beoordelen of elektrische installaties gebreken vertonen die een veilige bedrijfsvoering kunnen belemmeren.\n\nDe inspectie heeft bestaan uit:\n- Een visuele inspectie;\n- Metingen en beproevingen;\n- Een aanvullend onderzoek door thermografie.\n\nAls er tijdens de inspectie gebreken zijn geconstateerd, worden deze gebreken vermeld in de bijlage "Overzicht van gebreken".\n\nDe rapportage is een jaar geldig. De geldigheid wordt geteld vanaf de laatste inspectiedatum.\n\nNa de inspectie wordt in het SCIOS-portaal de inspectie afgemeld met of zonder constateringen. Een verklaring zonder constateringen. Een rapportage met constateringen kan binnen een jaar na inspectiedatum worden omgezet naar een verklaring zonder constateringen.',
      'tekst_rapport_verklaring':
          'Er is een inspectie uitgevoerd volgens SCIOS SCOPE 8 PI en SCOPE 10. Tijdens de inspectie zijn:\n\nIn de geïnspecteerde installatie(delen) zijn ##102## stuk(s) met de classificatie ##101##  aangetroffen welke direct aanrakings- of brandgevaar zorgen\n\nIn de geïnspecteerde installatie(delen) zijn ##104## stuk(s) met de classificatie ##103## aangetroffen.\n\nIn de geïnspecteerde installatie(delen) zijn ##106## stuk(s) met de classificatie ##105## aangetroffen.\n\nIndien een of meer van hier bovenstaande opmerkingen aanwezig zijn, dienen de opmerkingen vermeld in dit inspectierapport opgelost te worden.\n\nIn de geïnspecteerde installatie(delen) zijn ##108## stuk(s) met de classificatie ##107## aangetroffen.\n\nIn de geïnspecteerde installatie(delen) zijn ##110## stuk(s) met de classificatie ##109## aangetroffen.\n\nOpmerkingen met de classificatie ##109## moeten worden onderzocht en beoordeeld indien nodig worden opgelost.',
      'visuele_inspectie_titel': 'SCIOS SCOPE 8',
      'visuele_inspectie':
          'VISUEEL\n1)	De elektrische installatie volgens:\n2)	B3.01, visuele controle elektrisch materieel:\n2.1)	elektrisch materieel is geïnstalleerd en wordt gebruikt volgens de voorschriften van de fabrikant en \n	geldende installatie- en productnormen;\n2.2)	elektrische materieel is geschikt voor de gebruiker;\n2.3)	elektrische materieel is geschikt voor zijn omgeving;\n2.4)	elektrisch materieel is veilig voor gebruik;\n3)	B3.02 visuele controle schakel- en verdeelinrichtingen:\n3.1)	elektrisch materieel is bestand tegen het maximale kortsluitvermogen dat kan optreden;\n3.2)	de schakel- en verdeelinrichting wordt gebruikt volgens de productvoorschriften;\n3.3)	de schakel- en verdeelinrichting vertoont geen sporen van degeneratie;\n3.4)	de schakel- en verdeelinrichting vertoont geen sporen van oververhitting;\n3.5)	de schakel- en verdeelinrichting is vrij van vuil en vocht;\n3.6)	Bij componenten waarbij periodiek onderhoud noodzakelijk is, moet worden gecontroleerd of dit \n	daadwerkelijk wordt uitgevoerd.\n3.7)	De overstroombeveiliging van de schakel- en verdeelinrichting is juist gekozen.\n3.8)	De schakel- en verdeelinrichting is geschikt voor zijn omgeving.\n3.9)	De schakel- en verdeelinrichting is geschikt voor de gebruiker.\n4)	B3.04 eisen m.b.t. de opbouw van de installatie t.o.v. de omgeving en gebruik:\n4.1)	Bij de inspectie van de elektrische installatie moet rekening worden gehouden of de elektrische installatie \n	geschikt is voor veilig gebruik.\n4.2)	De elektrische installatie moet afgestemd zijn op de eisen m.b.t. de opbouw van de installatie t.o.v. \n	de omgeving en het gebruik. Met name:\n4.4)	de handelingen die worden uitgevoerd door gebruiker;\n4.5)	veiligheidsmaatregelen die zijn genomen;\n4.6)	toegang tot ruimtes met elektrisch gevaar;\n4.7)	schoonmaken van ruimten;\n4.8)	aanraakveiligheid van schakel- en verdeelinrichtingen;\n\nMETINGEN EN BEPROEVINGEN\n1)	Ononderbroken zijn van de beschermingsleiding: B3.6 of B3.7\n1.1)	Verbindingen in de schakel- en verdeelinrichtingen \n1.2)	Contactdozen\n1.3)	Verlichtingsarmaturen\n1.4)	Overige vast aangesloten elektrisch materieel\n1.5)	Ononderbroken zijn van de beschermingsleidingen bijzondere ruimte: B3.6 of B3.7\n2.1)	Verbindingen in de schakel- en verdeelinrichtingen \n2.2)	Contactdozen\n2.3)	Verlichtingsarmaturen\n2.4)	Overige vast aangesloten elektrisch materieel\n3)	Ononderbroken zijn van de vereffeningsleidingen B3.6\n4)	Ononderbroken zijn van de vereffeningsleidingen in bijzondere ruimte\n5)	Isolatieweerstand, stroomketens van eindgroepen in de volgende omgevingen:\n5.1)	bouw- en sloopterreinen\n5.2)	vochtige omgeving\n5.3)	buitenterrein\n6)	Circuitimpedantie P-N of P-P; B3.7\n6.1	Contactdozen;\n7)	Circuitimpedantie P-PE; B3.7\n7.1)	Schakel- en verdeelinrichtingen klasse 1\n7.2)	Contactdozen \n7.3)	vast aangesloten apparaten\n',
      'visuele_inspectie_toelichting': '',
      'metingen_titel': 'SCIOS SCOPE 10',
      'metingen':
          'BEDRIJFSOMSTANDIGHEDEN\n1)	Elektrisch materieel moet geschikt zijn voor de belastingsstromen.\n2)	Elektrisch materieel moet geschikt zijn voor de kortsluitstromen die kunnen optreden.\n3)	Elektrisch materieel moet geschikt zijn voor de stootspanningen die kunnen optreden.\n4)	Elektrisch materieel moet geschikt zijn voor het feitelijk of voorzienbaar gebruik.\n5)	Waar relevant moet elektrisch materieel periodiek worden onderhouden.\n\nWEDERZIJDSE BEÏNVLOEDING\n1)	De oppervlaktetemperatuur mag niet hoger zijn dan de specificatie van de fabrikant voorschrijft.\n2)	Elektrisch materieel moet vrij staan en voldoende afstand hebben tot brandbaar materiaal.\n3)	Elektrisch materieel met een oppervlaktetemperatuur hoger dan 90 °C moet voldoende afstand hebben \n	tot brandbaar materiaal of daarvan zijn afgeschermd.\n4)	De luchtspleet tussen blanke delen die onder spanning staan moet voldoende groot zijn.\n\nUITWENDIGE INVLOEDEN\n1)	Elektrisch materieel moet geschikt zijn voor de omgevingstemperatuur.\n2)	Bij de aanwezigheid van water of vocht moet elektrisch materieel aanvullend zijn beschermd.\n3)	Bij de aanwezigheid van water of vocht moet elektrisch materieel de juiste beschermingsgraad hebben.\n4)	Bij de aanwezigheid van vreemde voorwerpen of stof moet elektrisch materieel \n	aanvullend zijn beschermd.\n5)	Bij de aanwezigheid van vreemde voorwerpen of stof moet elektrisch materieel de \n	juiste beschermingsgraad hebben.\n6)	Bij de aanwezigheid van corrosieve of verontreinigende stoffen moet elektrisch materieel aanvullend zijn \n	beschermd.\n7)	Bij de aanwezigheid van corrosieve of verontreinigende stoffen moet elektrisch materieel de juiste \n	beschermingsgraad hebben.\n8)	Bij de aanwezigheid van de kans op stootbelasting moet elektrisch materieel daarvoor geschikt zijn of \n	aanvullend zijn beschermd.\n9)	Bij aanwezigheid van trillingen moet elektrisch materieel daartegen bestand zijn.\n10)	Bij de aanwezigheid van dieren mag elektrisch materieel daardoor niet kunnen worden aangetast.\n11)	Als elektrisch materieel wordt blootgesteld aan UV-straling dan moet het elektrisch materieel daarvoor \n	geschikt zijn of aanvullend zijn beschermd.\n12)	Als elektrisch materieel wordt blootgesteld aan externe warmtebronnen dan moet het elektrisch materieel \n	daarvoor geschikt zijn of aanvullend zijn beschermd.\n13)	Elektrisch materieel mag geen isolatiefout hebben.\n14)	Elektrisch materieel moet uitwendig vrij zijn van vervuiling zoals brandbaar stof en geleidend stof.\n15)	Elektrisch materieel moet inwendig vrij zijn van vervuiling zoals brandbaar stof, geleidend stof en vocht.\n\nAUTOMATISCH UITSCHAKELEN VAN DE VOEDING\n1)	Automatisch uitschakelen van de voeding\n2)	Circuitimpedantie tussen fasegeleider en beschermingsgeleider\n3)	Onderbreking van de beschermingsgeleider.\n4)	Werking van de aardlekschakelaar.\n5)	Een leiding moet op correcte wijze tegen overbelasting zijn beveiligd.\n6)	Een leiding moet op correcte wijze tegen kortsluiting zijn beveiligd.Beveiliging tegen overspanning.',
      'metingen_toelichting': '',
      'aanvullend_onderzoek_titel': '',
      'aanvullend_onderzoek': '',
      'aanvullend_onderzoek_toelichting':
          'Indien blijkt dat tijdens de inspectie de huidige norm strenger is of sterk afwijkt t.o.v. het rechtens verkregen niveau dan zal  indien wettelijk toegestaan de dan geldige norm worden toegepast.',
      'lijst4_titel': '',
      'lijst4': '',
      'lijst4_toelichting': '',
      'vinklijst_afkeuringscriteria':
          'Bij een gebrek of afwijking van een standaard met onmiddellijk gevaar is het volgende uitgevoerd:\n- het wordt onmiddellijk uit bedrijf genomen en bovendien beveiligd tegen opnieuw inschakelen en/of;\n- het wordt onmiddellijk hersteld en/of;\n- het wordt direct gemeld aan de opdrachtgever.\n\nGebreken worden geclassificeerd volgens SCIOS Informatieblad 22. De classificatie volgens IB22 is als volgt:\n\nErnstig - Rood\n• Het gevaar op letsel is voortdurend aanwezig of;\n• Schade met verstrekkende gevolgen.\n\nActie\nEr moeten direct maatregelen worden genomen. Indien bereikbaar onder normale bedrijfsomstandigheden:\n• Deze constatering moet mondeling en schriftelijk worden gemeld;\n• Direct veiligstellen/verhelpen/oplossen.\n\nSerieus - Oranje\nBij een voorzienbare gebeurtenis of een enkele fout:\n• Het gevaar van blijvend letsel/ onherstelbaar letsel kan zich voor doen of\n• Schade met aanzienlijke gevolgen\n\nActie\n• Schriftelijk vastleggen in een inspectierapport.\n• Moet binnen 3 maanden worden hersteld\n\nGering - Geel\n• Het gevaar van herstelbaar letsel kan zich voordoen of;\n• Schade kan gevolgen hebben.\n\nActie\n• Schriftelijk vastleggen in een inspectierapport.\n• Moet binnen 3 maanden worden hersteld\n\nOpmerking - Blauw\n• Er is minimaal gevaar/voldoet niet aan de uitgangspunten of;\n• Het gevolg levert onder normale bedrijfsomstandigheden geen gevaar op.\n\nActie\nSchriftelijk vastleggen in een inspectierapport, indien overeengekomen.\n\nNO - Nader onderzoek is noodzakelijk\nDe opmerkingen met de classificatie NO zijn ten tijde van de inspectie niet nader door de inspecteur onderzocht. De reden hiervan is dat er niet voldoende gegevens beschikbaar waren. Er kan niet worden vastgesteld of de opmerkingen met kwalificatie NO een gebrek is. Vervolgafspraken moeten worden gemaakt.',
    },
  ];

  Future<void> _seedReportTemplates(Database db) async {
    final batch = db.batch();
    for (final template in _defaultReportTemplates) {
      batch.insert('report_templates', template);
    }
    await batch.commit(noResult: true);
  }

  Future<List<ReportTemplate>> getReportTemplates() async {
    await _ensureReportTemplatesSchema();
    final db = await database;
    final maps = await db.query(
      'report_templates',
      orderBy: 'rapporttitel ASC',
    );
    return maps.map((m) => ReportTemplate.fromMap(m)).toList();
  }

  Future<int> insertReportTemplate(ReportTemplate template) async {
    await _ensureReportTemplatesSchema();
    final db = await database;
    return await db.insert('report_templates', template.toMap());
  }

  Future<void> updateReportTemplate(ReportTemplate template) async {
    await _ensureReportTemplatesSchema();
    final db = await database;
    await db.update(
      'report_templates',
      template.toMap(),
      where: 'id = ?',
      whereArgs: [template.id],
    );
  }

  /// Insert or update based on typeRapport. Returns true if a new record was created.
  Future<bool> upsertReportTemplateByType(ReportTemplate template) async {
    await _ensureReportTemplatesSchema();
    final db = await database;
    final existing = await db.query(
      'report_templates',
      where: 'type_rapport = ?',
      whereArgs: [template.typeRapport],
    );
    if (existing.isNotEmpty) {
      final id = existing.first['id'] as int;
      final updated = ReportTemplate(
        id: id,
        typeRapport: template.typeRapport,
        rapporttitel: template.rapporttitel,
        subtitel: template.subtitel,
        inleiding: template.inleiding,
        tekstRapportVerklaring: template.tekstRapportVerklaring,
        visueleInspectieTitel: template.visueleInspectieTitel,
        visueleInspectie: template.visueleInspectie,
        visueleInspectieToelichting: template.visueleInspectieToelichting,
        metingenTitel: template.metingenTitel,
        metingen: template.metingen,
        metingenToelichting: template.metingenToelichting,
        aanvullendOnderzoekTitel: template.aanvullendOnderzoekTitel,
        aanvullendOnderzoek: template.aanvullendOnderzoek,
        aanvullendOnderzoekToelichting: template.aanvullendOnderzoekToelichting,
        lijst4Titel: template.lijst4Titel,
        lijst4: template.lijst4,
        lijst4Toelichting: template.lijst4Toelichting,
        vinklijstAfkeuringscriteria: template.vinklijstAfkeuringscriteria,
        inspectieUitgevoerdVolgens: template.inspectieUitgevoerdVolgens,
        elektrischMaterieelGetoetst: template.elektrischMaterieelGetoetst,
        inleidingToelichting: template.inleidingToelichting,
        volgendInspectie: template.volgendInspectie,
        eindbeoordelingOKE: template.eindbeoordelingOKE,
      );
      await db.update(
        'report_templates',
        updated.toMap(),
        where: 'id = ?',
        whereArgs: [id],
      );
      return false;
    } else {
      await db.insert('report_templates', template.toMap());
      return true;
    }
  }

  Future<void> deleteReportTemplate(int id) async {
    await _ensureReportTemplatesSchema();
    final db = await database;
    await db.delete('report_templates', where: 'id = ?', whereArgs: [id]);
  }

  // ── Rapport Constateringen ──────────────────────────────────────────────────

  Future<void> _ensureRapportConstateringenSchema() {
    _ensureRapportConstateringenSchemaFuture ??=
        _doEnsureRapportConstateringenSchema();
    return _ensureRapportConstateringenSchemaFuture!;
  }

  Future<void> _doEnsureRapportConstateringenSchema() async {
    final db = await database;
    await db.execute('''
      CREATE TABLE IF NOT EXISTS rapport_constateringen (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        groep TEXT DEFAULT '',
        beschrijving TEXT DEFAULT '',
        tekst TEXT DEFAULT '',
        kwalificatie TEXT DEFAULT 'Ge',
        norm TEXT DEFAULT '',
        toelichting TEXT DEFAULT ''
      )
    ''');
  }

  Future<List<RapportConstatering>> getRapportConstateringen() async {
    await _ensureRapportConstateringenSchema();
    final db = await database;
    final maps = await db.query(
      'rapport_constateringen',
      orderBy: 'groep ASC, beschrijving ASC',
    );
    return maps.map((m) => RapportConstatering.fromMap(m)).toList();
  }

  Future<int> insertRapportConstatering(RapportConstatering item) async {
    await _ensureRapportConstateringenSchema();
    final db = await database;
    return await db.insert('rapport_constateringen', item.toMap());
  }

  Future<void> updateRapportConstatering(RapportConstatering item) async {
    await _ensureRapportConstateringenSchema();
    final db = await database;
    await db.update(
      'rapport_constateringen',
      item.toMap(),
      where: 'id = ?',
      whereArgs: [item.id],
    );
  }

  Future<void> deleteRapportConstatering(int id) async {
    await _ensureRapportConstateringenSchema();
    final db = await database;
    await db.delete('rapport_constateringen', where: 'id = ?', whereArgs: [id]);
  }

  /// Upsert by groep + beschrijving (natural key).
  Future<bool> upsertRapportConstatering(RapportConstatering item) async {
    await _ensureRapportConstateringenSchema();
    final db = await database;
    final existing = await db.query(
      'rapport_constateringen',
      where: 'groep = ? AND beschrijving = ?',
      whereArgs: [item.groep, item.beschrijving],
    );
    if (existing.isNotEmpty) {
      final id = existing.first['id'] as int;
      await db.update(
        'rapport_constateringen',
        item.copyWith(id: id).toMap(),
        where: 'id = ?',
        whereArgs: [id],
      );
      return false;
    } else {
      await db.insert('rapport_constateringen', item.toMap());
      return true;
    }
  }

  // ── Steekproef items ────────────────────────────────────────────────────────

  Future<List<SteekproefItem>> getSteekproefItems(int inspectionId) async {
    final db = await database;
    final maps = await db.query(
      'steekproef_items',
      where: 'inspection_id = ?',
      whereArgs: [inspectionId],
      orderBy: 'id ASC',
    );
    return maps.map((m) => SteekproefItem.fromMap(m)).toList();
  }

  Future<int> insertSteekproefItem(SteekproefItem item) async {
    final db = await database;
    return await db.insert('steekproef_items', item.toMap());
  }

  Future<void> deleteSteekproefItem(int id) async {
    final db = await database;
    await db.delete('steekproef_items', where: 'id = ?', whereArgs: [id]);
  }

  // ── Final Assessment ────────────────────────────────────────────────────────

  Future<void> _ensureFinalAssessmentSchema() {
    _ensureFinalAssessmentSchemaFuture ??= _doEnsureFinalAssessmentSchema();
    return _ensureFinalAssessmentSchemaFuture!;
  }

  Future<void> _doEnsureFinalAssessmentSchema() async {
    final db = await database;
    await db.execute('''
      CREATE TABLE IF NOT EXISTS final_assessment (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        inspection_id INTEGER NOT NULL,
        eindbeoordeling TEXT DEFAULT '',
        volgend_inspectie TEXT DEFAULT '',
        naam1 TEXT DEFAULT '',
        functie1 TEXT DEFAULT '',
        datum1 TEXT DEFAULT '',
        handtekening1 TEXT DEFAULT '',
        naam2 TEXT DEFAULT '',
        functie2 TEXT DEFAULT '',
        datum2 TEXT DEFAULT '',
        handtekening2 TEXT DEFAULT ''
      )
    ''');
  }

  Future<FinalAssessment?> getFinalAssessment(int inspectionId) async {
    await _ensureFinalAssessmentSchema();
    final db = await database;
    final maps = await db.query(
      'final_assessment',
      where: 'inspection_id = ?',
      whereArgs: [inspectionId],
    );
    if (maps.isEmpty) return null;
    return FinalAssessment.fromMap(maps.first);
  }

  Future<int> insertFinalAssessment(FinalAssessment assessment) async {
    await _ensureFinalAssessmentSchema();
    final db = await database;
    return await db.insert('final_assessment', assessment.toMap());
  }

  Future<void> updateFinalAssessment(FinalAssessment assessment) async {
    await _ensureFinalAssessmentSchema();
    final db = await database;
    await db.update(
      'final_assessment',
      assessment.toMap(),
      where: 'id = ?',
      whereArgs: [assessment.id],
    );
  }

  // ── Tekeningen ──────────────────────────────────────────────────────────────

  Future<List<Tekening>> getTekeningen(int inspectionId) async {
    final db = await database;
    final maps = await db.query(
      'tekeningen',
      where: 'inspection_id = ?',
      whereArgs: [inspectionId],
      orderBy: 'naam ASC',
    );
    return maps.map(Tekening.fromMap).toList();
  }

  Future<int> insertTekening(Tekening tekening) async {
    final db = await database;
    return await db.insert('tekeningen', tekening.toMap());
  }

  Future<void> updateTekening(Tekening tekening) async {
    final db = await database;
    await db.update(
      'tekeningen',
      tekening.toMap(),
      where: 'id = ?',
      whereArgs: [tekening.id],
    );
  }

  Future<void> deleteTekening(int id) async {
    final db = await database;
    await db.delete('tekeningen', where: 'id = ?', whereArgs: [id]);
  }

  // ── Tekening pins ───────────────────────────────────────────────────────────

  Future<List<TekeningPin>> getTekeningPins(int tekeningId) async {
    final db = await database;
    final maps = await db.query(
      'tekening_pins',
      where: 'tekening_id = ?',
      whereArgs: [tekeningId],
      orderBy: 'volgnummer ASC',
    );
    return maps.map(TekeningPin.fromMap).toList();
  }

  Future<int> insertTekeningPin(TekeningPin pin) async {
    final db = await database;
    return await db.insert('tekening_pins', pin.toMap());
  }

  Future<void> updateTekeningPin(TekeningPin pin) async {
    final db = await database;
    await db.update(
      'tekening_pins',
      pin.toMap(),
      where: 'id = ?',
      whereArgs: [pin.id],
    );
  }

  Future<void> deleteTekeningPin(int id) async {
    final db = await database;
    await db.delete('tekening_pins', where: 'id = ?', whereArgs: [id]);
  }

  // ── Meetgegevens ────────────────────────────────────────────────────────────

  Future<List<MeasurementGroup>> getMeasurementGroups(int inspectionId) async {
    final db = await database;
    final maps = await db.query(
      'measurement_groups',
      where: 'inspection_id = ? AND switchboard_id IS NULL',
      whereArgs: [inspectionId],
      orderBy: 'volgorde ASC, id ASC',
    );
    return maps.map(MeasurementGroup.fromMap).toList();
  }

  Future<List<MeasurementGroup>> getMeasurementGroupsForSwitchboard(
      int switchboardId) async {
    final db = await database;
    final maps = await db.query(
      'measurement_groups',
      where: 'switchboard_id = ?',
      whereArgs: [switchboardId],
      orderBy: 'volgorde ASC, id ASC',
    );
    return maps.map(MeasurementGroup.fromMap).toList();
  }

  Future<int> insertMeasurementGroup(MeasurementGroup group) async {
    final db = await database;
    return await db.insert('measurement_groups', group.toMap());
  }

  Future<void> updateMeasurementGroup(MeasurementGroup group) async {
    final db = await database;
    await db.update(
      'measurement_groups',
      group.toMap(),
      where: 'id = ?',
      whereArgs: [group.id],
    );
  }

  Future<void> deleteMeasurementGroup(int id) async {
    final db = await database;
    await db.delete(
      'measurement_readings',
      where: 'group_id = ?',
      whereArgs: [id],
    );
    await db.delete('measurement_groups', where: 'id = ?', whereArgs: [id]);
  }

  Future<void> deleteMeasurementGroupsForInspection(int inspectionId) async {
    final db = await database;
    final groups = await getMeasurementGroups(inspectionId);
    for (final group in groups) {
      await db.delete(
        'measurement_readings',
        where: 'group_id = ?',
        whereArgs: [group.id],
      );
    }
    await db.delete(
      'measurement_groups',
      where: 'inspection_id = ? AND switchboard_id IS NULL',
      whereArgs: [inspectionId],
    );
  }

  Future<void> deleteMeasurementGroupsForSwitchboard(int switchboardId) async {
    final db = await database;
    final groups = await getMeasurementGroupsForSwitchboard(switchboardId);
    for (final group in groups) {
      await db.delete(
        'measurement_readings',
        where: 'group_id = ?',
        whereArgs: [group.id],
      );
    }
    await db.delete(
      'measurement_groups',
      where: 'switchboard_id = ?',
      whereArgs: [switchboardId],
    );
  }

  Future<List<MeasurementReading>> getMeasurementReadings(int groupId) async {
    final db = await database;
    final maps = await db.query(
      'measurement_readings',
      where: 'group_id = ?',
      whereArgs: [groupId],
      orderBy: 'volgorde ASC, id ASC',
    );
    return maps.map(MeasurementReading.fromMap).toList();
  }

  Future<int> insertMeasurementReading(MeasurementReading reading) async {
    final db = await database;
    return await db.insert('measurement_readings', reading.toMap());
  }

  Future<void> updateMeasurementReading(MeasurementReading reading) async {
    final db = await database;
    await db.update(
      'measurement_readings',
      reading.toMap(),
      where: 'id = ?',
      whereArgs: [reading.id],
    );
  }

  Future<void> deleteMeasurementReading(int id) async {
    final db = await database;
    await db.delete('measurement_readings', where: 'id = ?', whereArgs: [id]);
  }

  Future<int> getNextTekeningPinVolgnummer(int tekeningId) async {
    final db = await database;
    final result = await db.rawQuery(
      'SELECT MAX(volgnummer) as max FROM tekening_pins WHERE tekening_id = ?',
      [tekeningId],
    );
    final max = result.first['max'] as int? ?? 0;
    return max + 1;
  }

  // ── Herstel ─────────────────────────────────────────────────────────────────

  Future<Herstel?> getHerstel(int defectId) async {
    final db = await database;
    final maps = await db.query(
      'herstel',
      where: 'defect_id = ?',
      whereArgs: [defectId],
    );
    if (maps.isEmpty) return null;
    return Herstel.fromMap(maps.first);
  }

  Future<int> insertHerstel(Herstel herstel) async {
    final db = await database;
    return await db.insert('herstel', herstel.toMap());
  }

  Future<void> updateHerstel(Herstel herstel) async {
    final db = await database;
    await db.update(
      'herstel',
      herstel.toMap(),
      where: 'id = ?',
      whereArgs: [herstel.id],
    );
  }

  /// Returns the herstel-token for [defectId], generating and persisting one
  /// (and the herstel row itself, if needed) on first use. The token is a
  /// random, unguessable identifier used to link an externally submitted
  /// herstelmelding (via QR code) back to this defect's herstel row — it is
  /// stable across repeated calls so a once-shared QR code keeps working.
  Future<String> ensureHerstelToken(int defectId) async {
    var herstel = await getHerstel(defectId);
    herstel ??= Herstel(id: await insertHerstel(Herstel(defectId: defectId)), defectId: defectId);
    if (herstel.token != null && herstel.token!.isNotEmpty) {
      return herstel.token!;
    }
    final tokenBytes = List<int>.generate(16, (_) => Random.secure().nextInt(256));
    final token = base64Url.encode(tokenBytes).replaceAll('=', '');
    await updateHerstel(herstel.copyWith(token: token));
    return token;
  }
}
