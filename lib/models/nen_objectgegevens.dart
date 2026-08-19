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

/// Objectgegevens voor de NEN 2767-conditiemeting van één inspectie.
/// [objectcode] is een door de gebruiker vrij gekozen koppelsleutel (bv.
/// adres of postcode+huisnummer) waarmee meerdere inspecties van hetzelfde
/// object aan elkaar gekoppeld worden voor de historievergelijking.
class NenObjectgegevens {
  final int? id;
  final int inspectionId;
  final String bouwjaar;
  final String gebruiksfunctie;
  final String objectcode;
  final String opmerkingen;

  NenObjectgegevens({
    this.id,
    required this.inspectionId,
    this.bouwjaar = '',
    this.gebruiksfunctie = '',
    this.objectcode = '',
    this.opmerkingen = '',
  });

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'inspection_id': inspectionId,
      'bouwjaar': bouwjaar,
      'gebruiksfunctie': gebruiksfunctie,
      'objectcode': objectcode,
      'opmerkingen': opmerkingen,
    };
  }

  factory NenObjectgegevens.fromMap(Map<String, dynamic> map) {
    return NenObjectgegevens(
      id: map['id'] as int?,
      inspectionId: map['inspection_id'] as int,
      bouwjaar: map['bouwjaar'] as String? ?? '',
      gebruiksfunctie: map['gebruiksfunctie'] as String? ?? '',
      objectcode: map['objectcode'] as String? ?? '',
      opmerkingen: map['opmerkingen'] as String? ?? '',
    );
  }

  NenObjectgegevens copyWith({
    int? id,
    int? inspectionId,
    String? bouwjaar,
    String? gebruiksfunctie,
    String? objectcode,
    String? opmerkingen,
  }) {
    return NenObjectgegevens(
      id: id ?? this.id,
      inspectionId: inspectionId ?? this.inspectionId,
      bouwjaar: bouwjaar ?? this.bouwjaar,
      gebruiksfunctie: gebruiksfunctie ?? this.gebruiksfunctie,
      objectcode: objectcode ?? this.objectcode,
      opmerkingen: opmerkingen ?? this.opmerkingen,
    );
  }
}
