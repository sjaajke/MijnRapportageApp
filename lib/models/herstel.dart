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

class Herstel {
  final int? id;
  final int defectId;
  final bool isHersteld;
  final String datum;
  final String naam;
  final String? photo1Path;
  final String? photo2Path;
  final String toelichting;
  final String? token;

  Herstel({
    this.id,
    required this.defectId,
    this.isHersteld = false,
    this.datum = '',
    this.naam = '',
    this.photo1Path,
    this.photo2Path,
    this.toelichting = '',
    this.token,
  });

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'defect_id': defectId,
      'is_hersteld': isHersteld ? 1 : 0,
      'datum': datum,
      'naam': naam,
      'photo1_path': photo1Path,
      'photo2_path': photo2Path,
      'toelichting': toelichting,
      'herstel_token': token,
    };
  }

  factory Herstel.fromMap(Map<String, dynamic> map) {
    return Herstel(
      id: map['id'] as int?,
      defectId: map['defect_id'] as int,
      isHersteld: (map['is_hersteld'] as int?) == 1,
      datum: map['datum'] as String? ?? '',
      naam: map['naam'] as String? ?? '',
      photo1Path: map['photo1_path'] as String?,
      photo2Path: map['photo2_path'] as String?,
      toelichting: map['toelichting'] as String? ?? '',
      token: map['herstel_token'] as String?,
    );
  }

  Herstel copyWith({
    int? id,
    int? defectId,
    bool? isHersteld,
    String? datum,
    String? naam,
    String? photo1Path,
    String? photo2Path,
    String? toelichting,
    String? token,
  }) {
    return Herstel(
      id: id ?? this.id,
      defectId: defectId ?? this.defectId,
      isHersteld: isHersteld ?? this.isHersteld,
      datum: datum ?? this.datum,
      naam: naam ?? this.naam,
      photo1Path: photo1Path ?? this.photo1Path,
      photo2Path: photo2Path ?? this.photo2Path,
      toelichting: toelichting ?? this.toelichting,
      token: token ?? this.token,
    );
  }
}
