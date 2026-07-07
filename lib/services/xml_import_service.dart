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

import 'dart:typed_data';
import 'package:archive/archive.dart';
import 'package:xml/xml.dart';
import '../models/defect.dart';
import '../models/general_data.dart';
import '../models/inspection_detail.dart';
import '../models/solar_installation.dart';
import '../models/switchboard.dart';
import '../models/title_page.dart';
import 'database_service.dart';

class XmlImportService {
  final _db = DatabaseService();

  // Entry point: accepts raw ZIP bytes, returns the new inspection id
  Future<int> importFromZip(Uint8List zipBytes) async {
    final archive = ZipDecoder().decodeBytes(zipBytes);

    // Find the XML file in the ZIP
    final xmlEntry = archive.files.firstWhere(
      (f) => f.name.toLowerCase().endsWith('.xml') && f.isFile,
      orElse: () => throw Exception('Geen XML-bestand gevonden in ZIP'),
    );

    final xmlString = String.fromCharCodes(xmlEntry.content as List<int>);
    return _importXml(xmlString);
  }

  Future<int> _importXml(String xmlString) async {
    final doc = XmlDocument.parse(xmlString);
    final root = doc.rootElement; // <inspection>

    // Create new inspection
    final inspectionId = await _db.createInspection();

    // title_page
    final titleEl = root.findElements('title_page').firstOrNull;
    if (titleEl != null) {
      await _db.insertTitlePage(TitlePage(
        inspectionId: inspectionId,
        title:              _text(titleEl, 'title'),
        inspectionDate:     _text(titleEl, 'inspection_date'),
        identificationCode: _text(titleEl, 'identification_code'),
        projectNumber:      _text(titleEl, 'project_number'),
      ));
    }

    // general_data
    final gdEl = root.findElements('general_data').firstOrNull;
    if (gdEl != null) {
      final cl = gdEl.findElements('client').firstOrNull;
      final ia = gdEl.findElements('inspection_address').firstOrNull;
      final ins = gdEl.findElements('inspector').firstOrNull;
      await _db.insertGeneralData(GeneralData(
        inspectionId: inspectionId,
        clientCompany:               _text(cl, 'company'),
        clientAddress:               _text(cl, 'address'),
        clientPostalCity:            _text(cl, 'postal_city'),
        clientContact:               _text(cl, 'contact'),
        inspectionAddressName:       _text(ia, 'name'),
        inspectionAddressStreet:     _text(ia, 'street'),
        inspectionAddressPostalCity: _text(ia, 'postal_city'),
        inspectionAddressContact:    _text(ia, 'contact'),
        inspectorCompany:            _text(ins, 'company'),
        inspectorAddress:            _text(ins, 'address'),
        inspectorPostalCity:         _text(ins, 'postal_city'),
        inspectorPhone:              _text(ins, 'phone'),
        inspectorEmail:              _text(ins, 'email'),
        inspectorContact:            _text(ins, 'contact'),
        inspectors:                  _text(ins, 'inspectors'),
      ));
    }

    // inspection_details
    final detEl = root.findElements('inspection_details').firstOrNull;
    if (detEl != null) {
      final sc = detEl.findElements('scope').firstOrNull;
      final ba = detEl.findElements('basis').firstOrNull;
      await _db.insertInspectionDetail(InspectionDetail(
        inspectionId:         inspectionId,
        scopeDescription:     _text(sc, 'description'),
        notInspectedParts:    _text(sc, 'not_inspected_parts'),
        notInspectedReason:   _text(sc, 'not_inspected_reason'),
        inspectionReason:     _text(ba, 'inspection_reason'),
        performedAccordingTo: _text(ba, 'performed_according_to'),
        testedAgainst:        _text(ba, 'tested_against'),
      ));
    }

    // switchboards
    final sbsEl = root.findElements('switchboards').firstOrNull;
    if (sbsEl != null) {
      for (final sbEl in sbsEl.findElements('switchboard')) {
        await _db.insertSwitchboard(Switchboard(
          inspectionId:       inspectionId,
          name:               _text(sbEl, 'name'),
          location:           _text(sbEl, 'location'),
          system:             _text(sbEl, 'system'),
          shortCircuitCurrent: _parseInt(sbEl, 'short_circuit_current'),
          protection:         _text(sbEl, 'protection'),
          protectionClass:    _text(sbEl, 'protection_class'),
          cableCrossSection:  _parseInt(sbEl, 'cable_cross_section'),
          cableLength:        _parseInt(sbEl, 'cable_length'),
          mainSwitchCurrent:  _parseInt(sbEl, 'main_switch_current'),
          mainSwitchPoles:    _parseInt(sbEl, 'main_switch_poles'),
          visualInspection:   _itemMap(sbEl, 'visual_inspection'),
          measurements:       _itemMap(sbEl, 'measurements'),
        ));
      }
    }

    // solar_installations
    final sisEl = root.findElements('solar_installations').firstOrNull;
    if (sisEl != null) {
      for (final siEl in sisEl.findElements('solar_installation')) {
        await _db.insertSolarInstallation(SolarInstallation(
          inspectionId:     inspectionId,
          location:         _text(siEl, 'location'),
          panelSublocation: _text(siEl, 'panel_sublocation'),
          panelCount:       _parseInt(siEl, 'panel_count'),
          inverterCount:    _parseInt(siEl, 'inverter_count'),
          wattPeak:         _parseInt(siEl, 'watt_peak'),
          constructionType: _text(siEl, 'construction_type'),
        ));
      }
    }

    // defects
    final defsEl = root.findElements('defects').firstOrNull;
    if (defsEl != null) {
      for (final dEl in defsEl.findElements('defect')) {
        await _db.insertDefect(Defect(
          inspectionId:   inspectionId,
          location:       _text(dEl, 'location'),
          classification: _text(dEl, 'classification').isNotEmpty
              ? _text(dEl, 'classification')
              : 'Ge',
          description:    _text(dEl, 'description'),
        ));
      }
    }

    return inspectionId;
  }

  // ── helpers ────────────────────────────────────────────────────────────────

  String _text(XmlElement? parent, String tag) {
    if (parent == null) return '';
    return parent.findElements(tag).firstOrNull?.innerText.trim() ?? '';
  }

  int? _parseInt(XmlElement? parent, String tag) {
    final v = _text(parent, tag);
    return v.isEmpty ? null : int.tryParse(v);
  }

  Map<String, String> _itemMap(XmlElement parent, String container) {
    final el = parent.findElements(container).firstOrNull;
    if (el == null) return {};
    return {
      for (final item in el.findElements('item'))
        (item.getAttribute('name') ?? ''): item.innerText.trim(),
    };
  }
}
