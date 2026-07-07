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
import 'hoofdschakelaar_entry.dart';

class Switchboard {
  final int? id;
  final int inspectionId;
  final String name;
  final String location;
  final String locationA;
  final String locationB;

  String get locationFull => [location, locationA, locationB]
      .where((p) => p.isNotEmpty)
      .join(' ');

  final String installationComponent;
  final String system;
  final int? shortCircuitCurrent;
  final String protection;
  final String protectionClass;
  final String beschermingsklasse;
  final String? cableType;
  final int? cableCrossSection;
  final int? cableLength;
  final int? mainSwitchCurrent;
  final int? mainSwitchPoles;
  final String? photo1Path;
  final String? photo2Path;
  final Map<String, String> visualInspection;
  final Map<String, String> measurements;
  final Map<String, String> electricalMeasurements;
  final List<HoofdschakelaarEntry> hoofdschakelaars;
  final String opmerking;

  static const List<String> visualInspectionItems = [
    'Verdeler eenduidig herkenbaar',
    'Installatieschema actueel',
    'Codering; aansluitklemmen, bedrading',
    'Verdeler aanraakveilig',
    'Overeenstemming met de omgeving',
    'Aansluitingen zijn correct uitgevoerd',
    'Veilige scheiding van stroomketens',
    'Vrij van stof, vuil en water',
    'Verdeler toegankelijk',
    'Beveiligingstoestellen aanwezig zijn',
    'Beveiligingstoestellen juist gekozen zijn',
    'Schakelaars/scheiders aanwezig zijn',
    'Schakelaars/scheiders juist gekozen zijn',
  ];

  static const List<String> measurementItems = [
    'Impedantie foutstroomketen',
    'Isolatieweerstand',
    'Aardlekbeveiliging',
    'Thermografie',
  ];

  Switchboard({
    this.id,
    required this.inspectionId,
    this.name = '',
    this.location = '',
    this.locationA = '',
    this.locationB = '',
    this.installationComponent = '',
    this.system = 'TN-S',
    this.shortCircuitCurrent,
    this.protection = 'B 40 A',
    this.protectionClass = 'IP54',
    this.beschermingsklasse = '',
    this.cableType,
    this.cableCrossSection,
    this.cableLength,
    this.mainSwitchCurrent,
    this.mainSwitchPoles,
    this.photo1Path,
    this.photo2Path,
    Map<String, String>? visualInspection,
    Map<String, String>? measurements,
    Map<String, String>? electricalMeasurements,
    List<HoofdschakelaarEntry>? hoofdschakelaars,
    this.opmerking = '',
  })  : visualInspection = visualInspection ??
            {for (var item in visualInspectionItems) item: 'N.v.t.'},
        measurements = measurements ??
            {for (var item in measurementItems) item: 'N.v.t.'},
        electricalMeasurements = electricalMeasurements ?? {},
        hoofdschakelaars = hoofdschakelaars ?? [];

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'inspection_id': inspectionId,
      'name': name,
      'location': location,
      'location_a': locationA,
      'location_b': locationB,
      'installation_component': installationComponent,
      'system': system,
      'short_circuit_current': shortCircuitCurrent,
      'protection': protection,
      'protection_class': protectionClass,
      'beschermingsklasse': beschermingsklasse,
      'cable_type': cableType,
      'cable_cross_section': cableCrossSection,
      'cable_length': cableLength,
      'main_switch_current': mainSwitchCurrent,
      'main_switch_poles': mainSwitchPoles,
      'photo1_path': photo1Path,
      'photo2_path': photo2Path,
      'visual_inspection_json': jsonEncode(visualInspection),
      'measurements_json': jsonEncode(measurements),
      'electrical_measurements_json': jsonEncode(electricalMeasurements),
      'hoofdschakelaars_json': HoofdschakelaarEntry.listToJson(hoofdschakelaars),
      'opmerking': opmerking,
    };
  }

  factory Switchboard.fromMap(Map<String, dynamic> map) {
    Map<String, String> parseJson(String? jsonStr, List<String> defaults) {
      if (jsonStr == null || jsonStr.isEmpty) {
        return {for (var item in defaults) item: 'N.v.t.'};
      }
      final decoded = jsonDecode(jsonStr) as Map<String, dynamic>;
      return decoded.map((k, v) => MapEntry(k, v.toString()));
    }

    return Switchboard(
      id: map['id'] as int?,
      inspectionId: map['inspection_id'] as int,
      name: map['name'] as String? ?? '',
      location: map['location'] as String? ?? '',
      locationA: map['location_a'] as String? ?? '',
      locationB: map['location_b'] as String? ?? '',
      installationComponent: map['installation_component'] as String? ?? '',
      system: map['system'] as String? ?? 'TN-S',
      shortCircuitCurrent: map['short_circuit_current'] as int?,
      protection: map['protection'] as String? ?? 'B 40 A',
      protectionClass: map['protection_class'] as String? ?? 'IP54',
      beschermingsklasse: map['beschermingsklasse'] as String? ?? '',
      cableType: map['cable_type'] as String?,
      cableCrossSection: map['cable_cross_section'] as int?,
      cableLength: map['cable_length'] as int?,
      mainSwitchCurrent: map['main_switch_current'] as int?,
      mainSwitchPoles: map['main_switch_poles'] as int?,
      photo1Path: map['photo1_path'] as String?,
      photo2Path: map['photo2_path'] as String?,
      visualInspection: parseJson(
          map['visual_inspection_json'] as String?, visualInspectionItems),
      measurements:
          parseJson(map['measurements_json'] as String?, measurementItems),
      electricalMeasurements: () {
        final raw = map['electrical_measurements_json'] as String?;
        if (raw == null || raw.isEmpty) return <String, String>{};
        final decoded = jsonDecode(raw) as Map<String, dynamic>;
        return decoded.map((k, v) => MapEntry(k, v.toString()));
      }(),
      hoofdschakelaars: HoofdschakelaarEntry.listFromJson(
          map['hoofdschakelaars_json'] as String?),
      opmerking: map['opmerking'] as String? ?? '',
    );
  }

  Switchboard copyWith({
    int? id,
    int? inspectionId,
    String? name,
    String? location,
    String? locationA,
    String? locationB,
    String? installationComponent,
    String? system,
    int? shortCircuitCurrent,
    String? protection,
    String? protectionClass,
    String? beschermingsklasse,
    String? cableType,
    int? cableCrossSection,
    int? cableLength,
    int? mainSwitchCurrent,
    int? mainSwitchPoles,
    String? photo1Path,
    String? photo2Path,
    Map<String, String>? visualInspection,
    Map<String, String>? measurements,
    Map<String, String>? electricalMeasurements,
    List<HoofdschakelaarEntry>? hoofdschakelaars,
    String? opmerking,
  }) {
    return Switchboard(
      id: id ?? this.id,
      inspectionId: inspectionId ?? this.inspectionId,
      name: name ?? this.name,
      location: location ?? this.location,
      locationA: locationA ?? this.locationA,
      locationB: locationB ?? this.locationB,
      installationComponent: installationComponent ?? this.installationComponent,
      system: system ?? this.system,
      shortCircuitCurrent: shortCircuitCurrent ?? this.shortCircuitCurrent,
      protection: protection ?? this.protection,
      protectionClass: protectionClass ?? this.protectionClass,
      beschermingsklasse: beschermingsklasse ?? this.beschermingsklasse,
      cableType: cableType ?? this.cableType,
      cableCrossSection: cableCrossSection ?? this.cableCrossSection,
      cableLength: cableLength ?? this.cableLength,
      mainSwitchCurrent: mainSwitchCurrent ?? this.mainSwitchCurrent,
      mainSwitchPoles: mainSwitchPoles ?? this.mainSwitchPoles,
      photo1Path: photo1Path ?? this.photo1Path,
      photo2Path: photo2Path ?? this.photo2Path,
      visualInspection: visualInspection ?? this.visualInspection,
      measurements: measurements ?? this.measurements,
      electricalMeasurements:
          electricalMeasurements ?? this.electricalMeasurements,
      hoofdschakelaars: hoofdschakelaars ?? this.hoofdschakelaars,
      opmerking: opmerking ?? this.opmerking,
    );
  }
}
