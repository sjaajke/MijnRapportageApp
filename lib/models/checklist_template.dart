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

/// An app-wide, reusable checklist template (managed from Settings) that can
/// be loaded into an inspection's checklists as a starting point.
class ChecklistTemplate {
  final int? id;
  final String name;
  final List<String> items;
  final int sortOrder;

  ChecklistTemplate({
    this.id,
    this.name = '',
    List<String>? items,
    this.sortOrder = 0,
  }) : items = items ?? [];

  Map<String, dynamic> toMap() => {
        if (id != null) 'id': id,
        'name': name,
        'items_json': jsonEncode(items),
        'sort_order': sortOrder,
      };

  factory ChecklistTemplate.fromMap(Map<String, dynamic> map) {
    final raw = map['items_json'] as String?;
    final items = raw == null || raw.isEmpty
        ? <String>[]
        : (jsonDecode(raw) as List<dynamic>).map((e) => e.toString()).toList();
    return ChecklistTemplate(
      id: map['id'] as int?,
      name: map['name'] as String? ?? '',
      items: items,
      sortOrder: map['sort_order'] as int? ?? 0,
    );
  }

  ChecklistTemplate copyWith({
    int? id,
    String? name,
    List<String>? items,
    int? sortOrder,
  }) =>
      ChecklistTemplate(
        id: id ?? this.id,
        name: name ?? this.name,
        items: items ?? this.items,
        sortOrder: sortOrder ?? this.sortOrder,
      );
}
