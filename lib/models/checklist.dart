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

import 'checklist_item_entry.dart';

/// A user-defined checklist attached to an inspection, made up of free-form
/// items that can each be answered with Ja/Nee/N.v.t.
class Checklist {
  final int? id;
  final int inspectionId;
  final String name;
  final List<ChecklistItemEntry> items;
  final int sortOrder;

  Checklist({
    this.id,
    required this.inspectionId,
    this.name = '',
    List<ChecklistItemEntry>? items,
    this.sortOrder = 0,
  }) : items = items ?? [];

  Map<String, dynamic> toMap() => {
        if (id != null) 'id': id,
        'inspection_id': inspectionId,
        'name': name,
        'items_json': ChecklistItemEntry.listToJson(items),
        'sort_order': sortOrder,
      };

  factory Checklist.fromMap(Map<String, dynamic> map) => Checklist(
        id: map['id'] as int?,
        inspectionId: map['inspection_id'] as int,
        name: map['name'] as String? ?? '',
        items: ChecklistItemEntry.listFromJson(map['items_json'] as String?),
        sortOrder: map['sort_order'] as int? ?? 0,
      );

  Checklist copyWith({
    int? id,
    int? inspectionId,
    String? name,
    List<ChecklistItemEntry>? items,
    int? sortOrder,
  }) =>
      Checklist(
        id: id ?? this.id,
        inspectionId: inspectionId ?? this.inspectionId,
        name: name ?? this.name,
        items: items ?? this.items,
        sortOrder: sortOrder ?? this.sortOrder,
      );
}
