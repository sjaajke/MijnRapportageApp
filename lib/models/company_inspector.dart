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

class CompanyInspector {
  final int? id;
  final String name;
  final String functie;
  final String handtekening; // base64 PNG

  CompanyInspector({
    this.id,
    required this.name,
    this.functie = '',
    this.handtekening = '',
  });

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'name': name,
      'functie': functie,
      'handtekening': handtekening,
    };
  }

  factory CompanyInspector.fromMap(Map<String, dynamic> map) {
    return CompanyInspector(
      id: map['id'] as int?,
      name: map['name'] as String? ?? '',
      functie: map['functie'] as String? ?? '',
      handtekening: map['handtekening'] as String? ?? '',
    );
  }

  CompanyInspector copyWith({
    int? id,
    String? name,
    String? functie,
    String? handtekening,
  }) {
    return CompanyInspector(
      id: id ?? this.id,
      name: name ?? this.name,
      functie: functie ?? this.functie,
      handtekening: handtekening ?? this.handtekening,
    );
  }
}
