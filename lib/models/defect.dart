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

class Defect {
  final int? id;
  final int inspectionId;
  final String location;
  final String locationA;
  final String locationB;
  final String installationComponent;
  final String naamCode;
  final String classification;
  final String description;
  final String? photo1Path;
  final String? photo2Path;
  final bool hasAnnotations;
  final bool scope8;
  final bool scope10;
  final bool scope12;
  final bool scopeEos;
  final String toelichting;

  static const List<String> classifications = ['Rd', 'Or', 'Ge', 'Bl', 'Pa', 'Gr'];

  String get locationFull => [location, locationA, locationB]
      .where((p) => p.isNotEmpty)
      .join(' ');

  Defect({
    this.id,
    required this.inspectionId,
    this.location = '',
    this.locationA = '',
    this.locationB = '',
    this.installationComponent = '',
    this.naamCode = '',
    this.classification = 'Ge',
    this.description = '',
    this.photo1Path,
    this.photo2Path,
    this.hasAnnotations = false,
    this.scope8 = false,
    this.scope10 = false,
    this.scope12 = false,
    this.scopeEos = false,
    this.toelichting = '',
  });

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'inspection_id': inspectionId,
      'location': location,
      'location_a': locationA,
      'location_b': locationB,
      'installation_component': installationComponent,
      'naam_code': naamCode,
      'classification': classification,
      'description': description,
      'photo1_path': photo1Path,
      'photo2_path': photo2Path,
      'scope8': scope8 ? 1 : 0,
      'scope10': scope10 ? 1 : 0,
      'scope12': scope12 ? 1 : 0,
      'scope_eos': scopeEos ? 1 : 0,
      'toelichting': toelichting,
    };
  }

  factory Defect.fromMap(Map<String, dynamic> map) {
    return Defect(
      id: map['id'] as int?,
      inspectionId: map['inspection_id'] as int,
      location: map['location'] as String? ?? '',
      locationA: map['location_a'] as String? ?? '',
      locationB: map['location_b'] as String? ?? '',
      installationComponent: map['installation_component'] as String? ?? '',
      naamCode: map['naam_code'] as String? ?? '',
      classification: map['classification'] as String? ?? 'Ge',
      description: map['description'] as String? ?? '',
      photo1Path: map['photo1_path'] as String?,
      photo2Path: map['photo2_path'] as String?,
      hasAnnotations: (map['has_annotations'] as int?) == 1,
      scope8: (map['scope8'] as int?) == 1,
      scope10: (map['scope10'] as int?) == 1,
      scope12: (map['scope12'] as int?) == 1,
      scopeEos: (map['scope_eos'] as int?) == 1,
      toelichting: map['toelichting'] as String? ?? '',
    );
  }

  Defect copyWith({
    int? id,
    int? inspectionId,
    String? location,
    String? locationA,
    String? locationB,
    String? installationComponent,
    String? naamCode,
    String? classification,
    String? description,
    String? photo1Path,
    String? photo2Path,
    bool? hasAnnotations,
    bool? scope8,
    bool? scope10,
    bool? scope12,
    bool? scopeEos,
    String? toelichting,
  }) {
    return Defect(
      id: id ?? this.id,
      inspectionId: inspectionId ?? this.inspectionId,
      location: location ?? this.location,
      locationA: locationA ?? this.locationA,
      locationB: locationB ?? this.locationB,
      installationComponent: installationComponent ?? this.installationComponent,
      naamCode: naamCode ?? this.naamCode,
      classification: classification ?? this.classification,
      description: description ?? this.description,
      photo1Path: photo1Path ?? this.photo1Path,
      photo2Path: photo2Path ?? this.photo2Path,
      hasAnnotations: hasAnnotations ?? this.hasAnnotations,
      scope8: scope8 ?? this.scope8,
      scope10: scope10 ?? this.scope10,
      scope12: scope12 ?? this.scope12,
      scopeEos: scopeEos ?? this.scopeEos,
      toelichting: toelichting ?? this.toelichting,
    );
  }
}
