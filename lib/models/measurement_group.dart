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

class MeasurementGroup {
  final int? id;
  final int inspectionId;
  final int? switchboardId; // gezet wanneer de groep bij een verdeler hoort
  final String bronBestand;
  final String label; // sheetnaam of omschrijving uit het bronbestand
  final String groepNummer; // 'L'-kolom uit het bronbestand
  final String puntNummer; // 'P'-kolom uit het bronbestand
  final String omschrijving;
  final int volgorde;

  MeasurementGroup({
    this.id,
    required this.inspectionId,
    this.switchboardId,
    this.bronBestand = '',
    this.label = '',
    this.groepNummer = '',
    this.puntNummer = '',
    this.omschrijving = '',
    this.volgorde = 0,
  });

  Map<String, dynamic> toMap() => {
        if (id != null) 'id': id,
        'inspection_id': inspectionId,
        'switchboard_id': switchboardId,
        'bron_bestand': bronBestand,
        'label': label,
        'groep_nummer': groepNummer,
        'punt_nummer': puntNummer,
        'omschrijving': omschrijving,
        'volgorde': volgorde,
      };

  factory MeasurementGroup.fromMap(Map<String, dynamic> map) => MeasurementGroup(
        id: map['id'] as int?,
        inspectionId: map['inspection_id'] as int,
        switchboardId: map['switchboard_id'] as int?,
        bronBestand: map['bron_bestand'] as String? ?? '',
        label: map['label'] as String? ?? '',
        groepNummer: map['groep_nummer'] as String? ?? '',
        puntNummer: map['punt_nummer'] as String? ?? '',
        omschrijving: map['omschrijving'] as String? ?? '',
        volgorde: map['volgorde'] as int? ?? 0,
      );

  MeasurementGroup copyWith({
    String? bronBestand,
    String? label,
    String? groepNummer,
    String? puntNummer,
    String? omschrijving,
    int? volgorde,
  }) =>
      MeasurementGroup(
        id: id,
        inspectionId: inspectionId,
        switchboardId: switchboardId,
        bronBestand: bronBestand ?? this.bronBestand,
        label: label ?? this.label,
        groepNummer: groepNummer ?? this.groepNummer,
        puntNummer: puntNummer ?? this.puntNummer,
        omschrijving: omschrijving ?? this.omschrijving,
        volgorde: volgorde ?? this.volgorde,
      );
}
