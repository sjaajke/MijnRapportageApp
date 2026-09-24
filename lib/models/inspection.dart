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

import 'inspection_module.dart';

class Inspection {
  final int? id;
  final String createdAt;
  final String updatedAt;
  final String status;
  final String syncStatus;
  final String hiddenModules;

  Inspection({
    this.id,
    required this.createdAt,
    required this.updatedAt,
    this.status = 'draft',
    this.syncStatus = 'pending',
    this.hiddenModules = '',
  });

  Set<String> get hiddenModuleSet => parseHiddenModules(hiddenModules);

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'created_at': createdAt,
      'updated_at': updatedAt,
      'status': status,
      'sync_status': syncStatus,
      'hidden_modules': hiddenModules,
    };
  }

  factory Inspection.fromMap(Map<String, dynamic> map) {
    return Inspection(
      id: map['id'] as int?,
      createdAt: map['created_at'] as String,
      updatedAt: map['updated_at'] as String,
      status: map['status'] as String? ?? 'draft',
      syncStatus: map['sync_status'] as String? ?? 'pending',
      hiddenModules: map['hidden_modules'] as String? ?? '',
    );
  }

  Inspection copyWith({
    int? id,
    String? createdAt,
    String? updatedAt,
    String? status,
    String? syncStatus,
    String? hiddenModules,
  }) {
    return Inspection(
      id: id ?? this.id,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      status: status ?? this.status,
      syncStatus: syncStatus ?? this.syncStatus,
      hiddenModules: hiddenModules ?? this.hiddenModules,
    );
  }
}
