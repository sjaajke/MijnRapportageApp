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

class Tekening {
  final int? id;
  final int inspectionId;
  final String naam;
  final String bestandPad;
  final String bestandType; // 'jpeg', 'png', 'pdf'

  Tekening({
    this.id,
    required this.inspectionId,
    this.naam = '',
    this.bestandPad = '',
    this.bestandType = '',
  });

  Map<String, dynamic> toMap() => {
        if (id != null) 'id': id,
        'inspection_id': inspectionId,
        'naam': naam,
        'bestand_pad': bestandPad,
        'bestand_type': bestandType,
      };

  factory Tekening.fromMap(Map<String, dynamic> map) => Tekening(
        id: map['id'] as int?,
        inspectionId: map['inspection_id'] as int,
        naam: map['naam'] as String? ?? '',
        bestandPad: map['bestand_pad'] as String? ?? '',
        bestandType: map['bestand_type'] as String? ?? '',
      );

  Tekening copyWith({
    int? id,
    int? inspectionId,
    String? naam,
    String? bestandPad,
    String? bestandType,
  }) =>
      Tekening(
        id: id ?? this.id,
        inspectionId: inspectionId ?? this.inspectionId,
        naam: naam ?? this.naam,
        bestandPad: bestandPad ?? this.bestandPad,
        bestandType: bestandType ?? this.bestandType,
      );
}
