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

class MeasurementValue {
  final String label;
  final String value;
  final String unit;

  const MeasurementValue({
    required this.label,
    required this.value,
    this.unit = '',
  });

  Map<String, dynamic> toJson() => {'l': label, 'v': value, 'u': unit};

  factory MeasurementValue.fromJson(Map<String, dynamic> json) =>
      MeasurementValue(
        label: json['l'] as String? ?? '',
        value: json['v'] as String? ?? '',
        unit: json['u'] as String? ?? '',
      );

  @override
  String toString() => '$label $value$unit'.trim();
}

class MeasurementReading {
  final int? id;
  final int groupId;
  final String puntNummer;
  final String metingType;
  final List<MeasurementValue> waarden;
  final int volgorde;

  MeasurementReading({
    this.id,
    required this.groupId,
    this.puntNummer = '',
    this.metingType = '',
    this.waarden = const [],
    this.volgorde = 0,
  });

  String get displayText => waarden
      .where((w) => w.value.trim().isNotEmpty)
      .map((w) => w.toString())
      .join(', ');

  Map<String, dynamic> toMap() => {
        if (id != null) 'id': id,
        'group_id': groupId,
        'punt_nummer': puntNummer,
        'meting_type': metingType,
        'waarden_json': jsonEncode(waarden.map((w) => w.toJson()).toList()),
        'volgorde': volgorde,
      };

  factory MeasurementReading.fromMap(Map<String, dynamic> map) {
    final raw = map['waarden_json'] as String? ?? '';
    List<MeasurementValue> waarden = [];
    if (raw.isNotEmpty) {
      final decoded = jsonDecode(raw) as List;
      waarden = decoded
          .map((e) => MeasurementValue.fromJson(e as Map<String, dynamic>))
          .toList();
    }
    return MeasurementReading(
      id: map['id'] as int?,
      groupId: map['group_id'] as int,
      puntNummer: map['punt_nummer'] as String? ?? '',
      metingType: map['meting_type'] as String? ?? '',
      waarden: waarden,
      volgorde: map['volgorde'] as int? ?? 0,
    );
  }

  MeasurementReading copyWith({
    String? puntNummer,
    String? metingType,
    List<MeasurementValue>? waarden,
    int? volgorde,
  }) =>
      MeasurementReading(
        id: id,
        groupId: groupId,
        puntNummer: puntNummer ?? this.puntNummer,
        metingType: metingType ?? this.metingType,
        waarden: waarden ?? this.waarden,
        volgorde: volgorde ?? this.volgorde,
      );
}
