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

/// Eén foto gekoppeld aan een NEN 2767-gebrek. In tegenstelling tot het
/// 2-foto-max patroon van [Defect] is dit een 1-op-veel-relatie, zodat een
/// gebrek een onbeperkt aantal foto's kan hebben.
class NenGebrekFoto {
  final int? id;
  final int gebrekId;
  final String fotoPath;
  final int volgorde;
  final String createdAt;

  NenGebrekFoto({
    this.id,
    required this.gebrekId,
    required this.fotoPath,
    this.volgorde = 0,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'gebrek_id': gebrekId,
      'foto_path': fotoPath,
      'volgorde': volgorde,
      'created_at': createdAt,
    };
  }

  factory NenGebrekFoto.fromMap(Map<String, dynamic> map) {
    return NenGebrekFoto(
      id: map['id'] as int?,
      gebrekId: map['gebrek_id'] as int,
      fotoPath: map['foto_path'] as String? ?? '',
      volgorde: map['volgorde'] as int? ?? 0,
      createdAt: map['created_at'] as String? ?? '',
    );
  }
}
