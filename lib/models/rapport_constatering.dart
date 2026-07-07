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

class RapportConstatering {
  final int? id;
  final String groep;
  final String beschrijving;
  final String tekst;
  final String kwalificatie;
  final String norm;
  final String toelichting;

  const RapportConstatering({
    this.id,
    this.groep = '',
    this.beschrijving = '',
    this.tekst = '',
    this.kwalificatie = 'Ge',
    this.norm = '',
    this.toelichting = '',
  });

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'groep': groep,
      'beschrijving': beschrijving,
      'tekst': tekst,
      'kwalificatie': kwalificatie,
      'norm': norm,
      'toelichting': toelichting,
    };
  }

  factory RapportConstatering.fromMap(Map<String, dynamic> map) {
    return RapportConstatering(
      id: map['id'] as int?,
      groep: map['groep'] as String? ?? '',
      beschrijving: map['beschrijving'] as String? ?? '',
      tekst: map['tekst'] as String? ?? '',
      kwalificatie: map['kwalificatie'] as String? ?? 'Ge',
      norm: map['norm'] as String? ?? '',
      toelichting: map['toelichting'] as String? ?? '',
    );
  }

  RapportConstatering copyWith({
    int? id,
    String? groep,
    String? beschrijving,
    String? tekst,
    String? kwalificatie,
    String? norm,
    String? toelichting,
  }) {
    return RapportConstatering(
      id: id ?? this.id,
      groep: groep ?? this.groep,
      beschrijving: beschrijving ?? this.beschrijving,
      tekst: tekst ?? this.tekst,
      kwalificatie: kwalificatie ?? this.kwalificatie,
      norm: norm ?? this.norm,
      toelichting: toelichting ?? this.toelichting,
    );
  }
}
