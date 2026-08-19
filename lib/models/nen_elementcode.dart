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

/// Officiële NEN 2767-elementcode (NL-SfB/BD-NL-SfB-decompositiestructuur).
/// Read-only referentiedata, geseed vanuit `nen2767_seed_data.dart`.
class NenElementcode {
  final int? id;
  final String elementcode;
  final String hoofdgroep;
  final String groep;
  final String subgroep;
  final String elementbenaming;
  final String eenheid;
  final String? nen2767Lijstnr;

  String get omschrijving =>
      [hoofdgroep, groep, subgroep, elementbenaming]
          .where((p) => p.isNotEmpty)
          .join(' > ');

  NenElementcode({
    this.id,
    required this.elementcode,
    this.hoofdgroep = '',
    this.groep = '',
    this.subgroep = '',
    this.elementbenaming = '',
    this.eenheid = '',
    this.nen2767Lijstnr,
  });

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'elementcode': elementcode,
      'hoofdgroep': hoofdgroep,
      'groep': groep,
      'subgroep': subgroep,
      'elementbenaming': elementbenaming,
      'eenheid': eenheid,
      'nen2767_lijstnr': nen2767Lijstnr,
    };
  }

  factory NenElementcode.fromMap(Map<String, dynamic> map) {
    return NenElementcode(
      id: map['id'] as int?,
      elementcode: map['elementcode'] as String,
      hoofdgroep: map['hoofdgroep'] as String? ?? '',
      groep: map['groep'] as String? ?? '',
      subgroep: map['subgroep'] as String? ?? '',
      elementbenaming: map['elementbenaming'] as String? ?? '',
      eenheid: map['eenheid'] as String? ?? '',
      nen2767Lijstnr: map['nen2767_lijstnr'] as String?,
    );
  }
}
