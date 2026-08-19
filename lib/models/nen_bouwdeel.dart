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

/// Eén node in de object > bouwdeel > element > locatie-boomstructuur van
/// een inspectie. Zelf-refererend via [parentId] zodat de decompositie een
/// vrije diepte kan hebben. Optioneel gekoppeld aan een officiële
/// [elementcodeId] (NenElementcode) zodat de bijbehorende gebrekenlijst
/// automatisch gefilterd kan worden.
class NenBouwdeel {
  final int? id;
  final int inspectionId;
  final int? parentId;
  final int? elementcodeId;
  final String naam;
  final String code;
  final int volgorde;

  NenBouwdeel({
    this.id,
    required this.inspectionId,
    this.parentId,
    this.elementcodeId,
    this.naam = '',
    this.code = '',
    this.volgorde = 0,
  });

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'inspection_id': inspectionId,
      'parent_id': parentId,
      'elementcode_id': elementcodeId,
      'naam': naam,
      'code': code,
      'volgorde': volgorde,
    };
  }

  factory NenBouwdeel.fromMap(Map<String, dynamic> map) {
    return NenBouwdeel(
      id: map['id'] as int?,
      inspectionId: map['inspection_id'] as int,
      parentId: map['parent_id'] as int?,
      elementcodeId: map['elementcode_id'] as int?,
      naam: map['naam'] as String? ?? '',
      code: map['code'] as String? ?? '',
      volgorde: map['volgorde'] as int? ?? 0,
    );
  }

  NenBouwdeel copyWith({
    int? id,
    int? inspectionId,
    int? parentId,
    bool clearParentId = false,
    int? elementcodeId,
    bool clearElementcodeId = false,
    String? naam,
    String? code,
    int? volgorde,
  }) {
    return NenBouwdeel(
      id: id ?? this.id,
      inspectionId: inspectionId ?? this.inspectionId,
      parentId: clearParentId ? null : (parentId ?? this.parentId),
      elementcodeId:
          clearElementcodeId ? null : (elementcodeId ?? this.elementcodeId),
      naam: naam ?? this.naam,
      code: code ?? this.code,
      volgorde: volgorde ?? this.volgorde,
    );
  }
}
