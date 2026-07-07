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

class FinalAssessment {
  final int? id;
  final int inspectionId;
  final String eindbeoordeling;
  final String volgendInspectie;
  // Ondertekenaar 1
  final String naam1;
  final String functie1;
  final String datum1;
  final String handtekening1; // base64 PNG
  // Ondertekenaar 2
  final String naam2;
  final String functie2;
  final String datum2;
  final String handtekening2; // base64 PNG

  FinalAssessment({
    this.id,
    required this.inspectionId,
    this.eindbeoordeling = '',
    this.volgendInspectie = '',
    this.naam1 = '',
    this.functie1 = '',
    this.datum1 = '',
    this.handtekening1 = '',
    this.naam2 = '',
    this.functie2 = '',
    this.datum2 = '',
    this.handtekening2 = '',
  });

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'inspection_id': inspectionId,
      'eindbeoordeling': eindbeoordeling,
      'volgend_inspectie': volgendInspectie,
      'naam1': naam1,
      'functie1': functie1,
      'datum1': datum1,
      'handtekening1': handtekening1,
      'naam2': naam2,
      'functie2': functie2,
      'datum2': datum2,
      'handtekening2': handtekening2,
    };
  }

  factory FinalAssessment.fromMap(Map<String, dynamic> map) {
    return FinalAssessment(
      id: map['id'] as int?,
      inspectionId: map['inspection_id'] as int,
      eindbeoordeling: map['eindbeoordeling'] as String? ?? '',
      volgendInspectie: map['volgend_inspectie'] as String? ?? '',
      naam1: map['naam1'] as String? ?? '',
      functie1: map['functie1'] as String? ?? '',
      datum1: map['datum1'] as String? ?? '',
      handtekening1: map['handtekening1'] as String? ?? '',
      naam2: map['naam2'] as String? ?? '',
      functie2: map['functie2'] as String? ?? '',
      datum2: map['datum2'] as String? ?? '',
      handtekening2: map['handtekening2'] as String? ?? '',
    );
  }

  FinalAssessment copyWith({
    int? id,
    int? inspectionId,
    String? eindbeoordeling,
    String? volgendInspectie,
    String? naam1,
    String? functie1,
    String? datum1,
    String? handtekening1,
    String? naam2,
    String? functie2,
    String? datum2,
    String? handtekening2,
  }) {
    return FinalAssessment(
      id: id ?? this.id,
      inspectionId: inspectionId ?? this.inspectionId,
      eindbeoordeling: eindbeoordeling ?? this.eindbeoordeling,
      volgendInspectie: volgendInspectie ?? this.volgendInspectie,
      naam1: naam1 ?? this.naam1,
      functie1: functie1 ?? this.functie1,
      datum1: datum1 ?? this.datum1,
      handtekening1: handtekening1 ?? this.handtekening1,
      naam2: naam2 ?? this.naam2,
      functie2: functie2 ?? this.functie2,
      datum2: datum2 ?? this.datum2,
      handtekening2: handtekening2 ?? this.handtekening2,
    );
  }
}
