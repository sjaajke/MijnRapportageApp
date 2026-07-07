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
import 'package:xml/xml.dart';
import 'package:path/path.dart' as p;
import 'database_service.dart';
import 'photo_service.dart';

class XmlExportService {
  final _db = DatabaseService();

  Future<String> exportInspection(int inspectionId) async {
    final inspection = await _db.getInspection(inspectionId);
    final titlePage = await _db.getTitlePage(inspectionId);
    final generalData = await _db.getGeneralData(inspectionId);
    final details = await _db.getInspectionDetail(inspectionId);
    final switchboards = await _db.getSwitchboards(inspectionId);
    final solarInstallations = await _db.getSolarInstallations(inspectionId);
    final defects = await _db.getDefects(inspectionId);

    final builder = XmlBuilder();
    builder.processing('xml', 'version="1.0" encoding="UTF-8"');

    builder.element('inspection', nest: () {
      builder.element('id', nest: inspectionId.toString());
      builder.element('created_at', nest: inspection?.createdAt ?? '');
      builder.element('updated_at', nest: inspection?.updatedAt ?? '');
      builder.element('status', nest: inspection?.status ?? '');

      if (titlePage != null) {
        builder.element('title_page', nest: () {
          builder.element('title', nest: titlePage.title);
          builder.element('photo_path', nest: titlePage.photoPath ?? '');
          builder.element('inspection_date', nest: titlePage.inspectionDate);
          builder.element('identification_code',
              nest: titlePage.identificationCode);
          builder.element('project_number', nest: titlePage.projectNumber);
        });
      }

      if (generalData != null) {
        builder.element('general_data', nest: () {
          builder.element('client', nest: () {
            builder.element('company', nest: generalData.clientCompany);
            builder.element('address', nest: generalData.clientAddress);
            builder.element('postal_city', nest: generalData.clientPostalCity);
            builder.element('contact', nest: generalData.clientContact);
          });
          builder.element('inspection_address', nest: () {
            builder.element('name', nest: generalData.inspectionAddressName);
            builder.element('street',
                nest: generalData.inspectionAddressStreet);
            builder.element('postal_city',
                nest: generalData.inspectionAddressPostalCity);
            builder.element('contact',
                nest: generalData.inspectionAddressContact);
          });
          builder.element('inspector', nest: () {
            builder.element('company', nest: generalData.inspectorCompany);
            builder.element('address', nest: generalData.inspectorAddress);
            builder.element('postal_city',
                nest: generalData.inspectorPostalCity);
            builder.element('phone', nest: generalData.inspectorPhone);
            builder.element('email', nest: generalData.inspectorEmail);
            builder.element('contact', nest: generalData.inspectorContact);
            builder.element('inspectors', nest: generalData.inspectors);
          });
        });
      }

      if (details != null) {
        builder.element('inspection_details', nest: () {
          builder.element('scope', nest: () {
            builder.element('description', nest: details.scopeDescription);
            builder.element('not_inspected_parts',
                nest: details.notInspectedParts);
            builder.element('not_inspected_reason',
                nest: details.notInspectedReason);
          });
          builder.element('basis', nest: () {
            builder.element('inspection_reason',
                nest: details.inspectionReason);
            builder.element('performed_according_to',
                nest: details.performedAccordingTo);
            builder.element('tested_against', nest: details.testedAgainst);
          });
        });
      }

      if (switchboards.isNotEmpty) {
        builder.element('switchboards', nest: () {
          for (final sb in switchboards) {
            builder.element('switchboard', nest: () {
              builder.element('name', nest: sb.name);
              builder.element('location', nest: sb.location);
              builder.element('system', nest: sb.system);
              builder.element('short_circuit_current',
                  nest: sb.shortCircuitCurrent?.toString() ?? '');
              builder.element('protection', nest: sb.protection);
              builder.element('protection_class', nest: sb.protectionClass);
              builder.element('cable_cross_section',
                  nest: sb.cableCrossSection?.toString() ?? '');
              builder.element('cable_length',
                  nest: sb.cableLength?.toString() ?? '');
              builder.element('main_switch_current',
                  nest: sb.mainSwitchCurrent?.toString() ?? '');
              builder.element('main_switch_poles',
                  nest: sb.mainSwitchPoles?.toString() ?? '');
              builder.element('visual_inspection', nest: () {
                sb.visualInspection.forEach((key, value) {
                  builder.element('item', nest: () {
                    builder.attribute('name', key);
                    builder.text(value);
                  });
                });
              });
              builder.element('measurements', nest: () {
                sb.measurements.forEach((key, value) {
                  builder.element('item', nest: () {
                    builder.attribute('name', key);
                    builder.text(value);
                  });
                });
              });
            });
          }
        });
      }

      if (solarInstallations.isNotEmpty) {
        builder.element('solar_installations', nest: () {
          for (final si in solarInstallations) {
            builder.element('solar_installation', nest: () {
              builder.element('location', nest: si.location);
              builder.element('panel_sublocation', nest: si.panelSublocation);
              builder.element('panel_count',
                  nest: si.panelCount?.toString() ?? '');
              builder.element('inverter_count',
                  nest: si.inverterCount?.toString() ?? '');
              builder.element('watt_peak',
                  nest: si.wattPeak?.toString() ?? '');
              builder.element('construction_type', nest: si.constructionType);
            });
          }
        });
      }

      if (defects.isNotEmpty) {
        builder.element('defects', nest: () {
          for (final d in defects) {
            builder.element('defect', nest: () {
              builder.element('location', nest: d.location);
              builder.element('classification', nest: d.classification);
              builder.element('description', nest: d.description);
            });
          }
        });
      }
    });

    final document = builder.buildDocument();
    final xmlString = document.toXmlString(pretty: true);

    final dir = await PhotoService().getExportsDir();
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final filePath = p.join(dir, '${inspectionId}_$timestamp.xml');

    await File(filePath).writeAsString(xmlString);

    await _db.updateInspectionStatus(inspectionId, 'exported');

    return filePath;
  }
}
