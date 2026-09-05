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

/// A PDF attachment (e.g. a certificate or measurement report) that gets
/// appended to the inspection report on export.
class Bijlage {
  final int? id;
  final int inspectionId;
  final String naam;
  final String bestandPad;

  Bijlage({
    this.id,
    required this.inspectionId,
    this.naam = '',
    this.bestandPad = '',
  });

  Map<String, dynamic> toMap() => {
        if (id != null) 'id': id,
        'inspection_id': inspectionId,
        'naam': naam,
        'bestand_pad': bestandPad,
      };

  factory Bijlage.fromMap(Map<String, dynamic> map) => Bijlage(
        id: map['id'] as int?,
        inspectionId: map['inspection_id'] as int,
        naam: map['naam'] as String? ?? '',
        bestandPad: map['bestand_pad'] as String? ?? '',
      );

  Bijlage copyWith({
    int? id,
    int? inspectionId,
    String? naam,
    String? bestandPad,
  }) =>
      Bijlage(
        id: id ?? this.id,
        inspectionId: inspectionId ?? this.inspectionId,
        naam: naam ?? this.naam,
        bestandPad: bestandPad ?? this.bestandPad,
      );
}
