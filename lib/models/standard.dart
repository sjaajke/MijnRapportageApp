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

class Standard {
  final int? id;
  final String category;
  final String value;
  final String displayName;

  Standard({
    this.id,
    required this.category,
    required this.value,
    required this.displayName,
  });

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'category': category,
      'value': value,
      'display_name': displayName,
    };
  }

  factory Standard.fromMap(Map<String, dynamic> map) {
    return Standard(
      id: map['id'] as int?,
      category: map['category'] as String,
      value: map['value'] as String,
      displayName: map['display_name'] as String,
    );
  }
}
