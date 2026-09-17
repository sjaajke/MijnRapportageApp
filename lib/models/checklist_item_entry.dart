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

/// A single, user-defined item within a [Checklist].
class ChecklistItemEntry {
  final int id;
  final String label;
  final String value; // 'Ja', 'Nee', 'N.v.t.'

  const ChecklistItemEntry({
    required this.id,
    this.label = '',
    this.value = 'N.v.t.',
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'label': label,
        'value': value,
      };

  factory ChecklistItemEntry.fromMap(Map<String, dynamic> map) =>
      ChecklistItemEntry(
        id: map['id'] as int? ?? 0,
        label: map['label'] as String? ?? '',
        value: map['value'] as String? ?? 'N.v.t.',
      );

  static List<ChecklistItemEntry> listFromJson(String? json) {
    if (json == null || json.isEmpty) return [];
    final list = jsonDecode(json) as List<dynamic>;
    return list
        .map((e) => ChecklistItemEntry.fromMap(e as Map<String, dynamic>))
        .toList();
  }

  static String listToJson(List<ChecklistItemEntry> list) =>
      jsonEncode(list.map((e) => e.toMap()).toList());

  ChecklistItemEntry copyWith({
    int? id,
    String? label,
    String? value,
  }) =>
      ChecklistItemEntry(
        id: id ?? this.id,
        label: label ?? this.label,
        value: value ?? this.value,
      );
}
