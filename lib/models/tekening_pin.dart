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

import 'dart:ui';

class TekeningPin {
  final int? id;
  final int tekeningId;
  final double x; // 0.0–1.0 fractie van tekening breedte
  final double y; // 0.0–1.0 fractie van tekening hoogte
  final String kleur; // 'Rd', 'Or', 'Ge', 'Bl', 'Pa', 'Gr'
  final String type; // 'notitie', 'constatering', 'meting'
  final int? defectId; // gekoppelde constatering (defect)
  final String metingType; // 'Zi', 'Zs', 'Overig'
  final String metingWaarde;
  final String metingEenheid; // eenheid bij 'Overig'
  final String label;
  final int volgnummer;

  TekeningPin({
    this.id,
    required this.tekeningId,
    this.x = 0.5,
    this.y = 0.5,
    this.kleur = 'Gr',
    this.type = 'notitie',
    this.defectId,
    this.metingType = '',
    this.metingWaarde = '',
    this.metingEenheid = 'Ω',
    this.label = '',
    this.volgnummer = 1,
  });

  static Color getColor(String kleur) {
    switch (kleur) {
      case 'Rd':
        return const Color(0xFFE53935);
      case 'Or':
        return const Color(0xFFFF9800);
      case 'Ge':
        return const Color(0xFFFDD835);
      case 'Bl':
        return const Color(0xFF1E88E5);
      case 'Pa':
        return const Color(0xFF8E24AA);
      case 'Gr':
        return const Color(0xFF757575);
      default:
        return const Color(0xFF757575);
    }
  }

  static const Map<String, String> kleurNamen = {
    'Rd': 'Rood',
    'Or': 'Oranje',
    'Ge': 'Geel',
    'Bl': 'Blauw',
    'Pa': 'Paars',
    'Gr': 'Grijs',
  };

  String get typeLabel {
    switch (type) {
      case 'constatering':
        return 'Constatering';
      case 'meting':
        return 'Meetwaarde';
      default:
        return 'Notitie';
    }
  }

  String get waardeTekst {
    if (type == 'meting' && metingType.isNotEmpty) {
      final eenheid = metingType == 'Overig' ? metingEenheid : 'Ω';
      return '$metingType: $metingWaarde $eenheid';
    }
    return label;
  }

  Map<String, dynamic> toMap() => {
        if (id != null) 'id': id,
        'tekening_id': tekeningId,
        'x': x,
        'y': y,
        'kleur': kleur,
        'type': type,
        'defect_id': defectId,
        'meting_type': metingType,
        'meting_waarde': metingWaarde,
        'meting_eenheid': metingEenheid,
        'label': label,
        'volgnummer': volgnummer,
      };

  factory TekeningPin.fromMap(Map<String, dynamic> map) => TekeningPin(
        id: map['id'] as int?,
        tekeningId: map['tekening_id'] as int,
        x: (map['x'] as num).toDouble(),
        y: (map['y'] as num).toDouble(),
        kleur: map['kleur'] as String? ?? 'Gr',
        type: map['type'] as String? ?? 'notitie',
        defectId: map['defect_id'] as int?,
        metingType: map['meting_type'] as String? ?? '',
        metingWaarde: map['meting_waarde'] as String? ?? '',
        metingEenheid: map['meting_eenheid'] as String? ?? 'Ω',
        label: map['label'] as String? ?? '',
        volgnummer: map['volgnummer'] as int? ?? 1,
      );

  TekeningPin copyWith({
    int? id,
    int? tekeningId,
    double? x,
    double? y,
    String? kleur,
    String? type,
    int? defectId,
    bool clearDefectId = false,
    String? metingType,
    String? metingWaarde,
    String? metingEenheid,
    String? label,
    int? volgnummer,
  }) =>
      TekeningPin(
        id: id ?? this.id,
        tekeningId: tekeningId ?? this.tekeningId,
        x: x ?? this.x,
        y: y ?? this.y,
        kleur: kleur ?? this.kleur,
        type: type ?? this.type,
        defectId: clearDefectId ? null : (defectId ?? this.defectId),
        metingType: metingType ?? this.metingType,
        metingWaarde: metingWaarde ?? this.metingWaarde,
        metingEenheid: metingEenheid ?? this.metingEenheid,
        label: label ?? this.label,
        volgnummer: volgnummer ?? this.volgnummer,
      );
}
