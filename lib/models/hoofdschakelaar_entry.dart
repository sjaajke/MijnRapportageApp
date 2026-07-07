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

import 'dart:convert';

class HoofdschakelaarEntry {
  final int id;
  final String leidingType;
  final String leidingDoorsnede;
  final String leidingAders;
  final String leidingLengte;
  final String hoofdschakelaar;
  final String aantalPolen;
  final String karakteristiek;
  final String voorbeveiliging;
  final String kortsluitstroom;

  const HoofdschakelaarEntry({
    required this.id,
    this.leidingType = '',
    this.leidingDoorsnede = '',
    this.leidingAders = '',
    this.leidingLengte = '',
    this.hoofdschakelaar = '',
    this.aantalPolen = '',
    this.karakteristiek = '',
    this.voorbeveiliging = '',
    this.kortsluitstroom = '',
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'leiding_type': leidingType,
        'leiding_doorsnede': leidingDoorsnede,
        'leiding_aders': leidingAders,
        'leiding_lengte': leidingLengte,
        'hoofdschakelaar': hoofdschakelaar,
        'aantal_polen': aantalPolen,
        'karakteristiek': karakteristiek,
        'voorbeveiliging': voorbeveiliging,
        'kortsluitstroom': kortsluitstroom,
      };

  factory HoofdschakelaarEntry.fromMap(Map<String, dynamic> map) =>
      HoofdschakelaarEntry(
        id: map['id'] as int? ?? 0,
        leidingType: map['leiding_type'] as String? ?? '',
        leidingDoorsnede: map['leiding_doorsnede'] as String? ?? '',
        leidingAders: map['leiding_aders'] as String? ?? '',
        leidingLengte: map['leiding_lengte'] as String? ?? '',
        hoofdschakelaar: map['hoofdschakelaar'] as String? ?? '',
        aantalPolen: map['aantal_polen'] as String? ?? '',
        karakteristiek: map['karakteristiek'] as String? ?? '',
        voorbeveiliging: map['voorbeveiliging'] as String? ?? '',
        kortsluitstroom: map['kortsluitstroom'] as String? ?? '',
      );

  static List<HoofdschakelaarEntry> listFromJson(String? json) {
    if (json == null || json.isEmpty) return [];
    final list = jsonDecode(json) as List<dynamic>;
    return list
        .map((e) => HoofdschakelaarEntry.fromMap(e as Map<String, dynamic>))
        .toList();
  }

  static String listToJson(List<HoofdschakelaarEntry> list) =>
      jsonEncode(list.map((e) => e.toMap()).toList());

  HoofdschakelaarEntry copyWith({
    int? id,
    String? leidingType,
    String? leidingDoorsnede,
    String? leidingAders,
    String? leidingLengte,
    String? hoofdschakelaar,
    String? aantalPolen,
    String? karakteristiek,
    String? voorbeveiliging,
    String? kortsluitstroom,
  }) =>
      HoofdschakelaarEntry(
        id: id ?? this.id,
        leidingType: leidingType ?? this.leidingType,
        leidingDoorsnede: leidingDoorsnede ?? this.leidingDoorsnede,
        leidingAders: leidingAders ?? this.leidingAders,
        leidingLengte: leidingLengte ?? this.leidingLengte,
        hoofdschakelaar: hoofdschakelaar ?? this.hoofdschakelaar,
        aantalPolen: aantalPolen ?? this.aantalPolen,
        karakteristiek: karakteristiek ?? this.karakteristiek,
        voorbeveiliging: voorbeveiliging ?? this.voorbeveiliging,
        kortsluitstroom: kortsluitstroom ?? this.kortsluitstroom,
      );
}
