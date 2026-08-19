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

/// Eén door de inspecteur waargenomen gebrek volgens de NEN 2767-methodiek:
/// ernst, omvang (%) en intensiteit worden alle drie per waarneming
/// vastgelegd; [conditiescore] is de op basis daarvan berekende score
/// (1 t/m 6, zie nen2767_scoring_service.dart) en wordt gecachet voor
/// snelle weergave/rapportage.
class NenGebrek {
  final int? id;
  final int inspectionId;
  final int bouwdeelId;

  /// Elementcode van dit specifieke gebrek (eerst installatiecode, dan
  /// elementcode gekozen bij het registreren van het gebrek zelf — los van
  /// een eventuele elementcode op het bouwdeel-knooppunt).
  final int? elementcodeId;
  final int? gebrekReferentieId;
  final String gebrekOmschrijving;
  final String ernst;
  final double omvangPercentage;
  final String intensiteit;
  final int conditiescore;
  final String locatieDetail;
  final String toelichting;
  final String inspecteur;
  final String geinspecteerdOp;
  final String createdAt;
  final String updatedAt;

  static const List<String> ernstNiveaus = ['E', 'S', 'G'];
  static const List<String> intensiteiten = ['Begin', 'Gevorderd', 'Eind'];

  static const Map<String, String> ernstLabels = {
    'E': 'Ernstig',
    'S': 'Serieus',
    'G': 'Gering',
  };

  NenGebrek({
    this.id,
    required this.inspectionId,
    required this.bouwdeelId,
    this.elementcodeId,
    this.gebrekReferentieId,
    this.gebrekOmschrijving = '',
    this.ernst = 'G',
    this.omvangPercentage = 0,
    this.intensiteit = 'Begin',
    this.conditiescore = 1,
    this.locatieDetail = '',
    this.toelichting = '',
    this.inspecteur = '',
    required this.geinspecteerdOp,
    required this.createdAt,
    required this.updatedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'inspection_id': inspectionId,
      'bouwdeel_id': bouwdeelId,
      'elementcode_id': elementcodeId,
      'gebrek_referentie_id': gebrekReferentieId,
      'gebrek_omschrijving': gebrekOmschrijving,
      'ernst': ernst,
      'omvang_percentage': omvangPercentage,
      'intensiteit': intensiteit,
      'conditiescore': conditiescore,
      'locatie_detail': locatieDetail,
      'toelichting': toelichting,
      'inspecteur': inspecteur,
      'geinspecteerd_op': geinspecteerdOp,
      'created_at': createdAt,
      'updated_at': updatedAt,
    };
  }

  factory NenGebrek.fromMap(Map<String, dynamic> map) {
    return NenGebrek(
      id: map['id'] as int?,
      inspectionId: map['inspection_id'] as int,
      bouwdeelId: map['bouwdeel_id'] as int,
      elementcodeId: map['elementcode_id'] as int?,
      gebrekReferentieId: map['gebrek_referentie_id'] as int?,
      gebrekOmschrijving: map['gebrek_omschrijving'] as String? ?? '',
      ernst: map['ernst'] as String? ?? 'G',
      omvangPercentage: (map['omvang_percentage'] as num?)?.toDouble() ?? 0,
      intensiteit: map['intensiteit'] as String? ?? 'Begin',
      conditiescore: map['conditiescore'] as int? ?? 1,
      locatieDetail: map['locatie_detail'] as String? ?? '',
      toelichting: map['toelichting'] as String? ?? '',
      inspecteur: map['inspecteur'] as String? ?? '',
      geinspecteerdOp: map['geinspecteerd_op'] as String? ?? '',
      createdAt: map['created_at'] as String? ?? '',
      updatedAt: map['updated_at'] as String? ?? '',
    );
  }

  NenGebrek copyWith({
    int? id,
    int? inspectionId,
    int? bouwdeelId,
    int? elementcodeId,
    bool clearElementcodeId = false,
    int? gebrekReferentieId,
    bool clearGebrekReferentieId = false,
    String? gebrekOmschrijving,
    String? ernst,
    double? omvangPercentage,
    String? intensiteit,
    int? conditiescore,
    String? locatieDetail,
    String? toelichting,
    String? inspecteur,
    String? geinspecteerdOp,
    String? createdAt,
    String? updatedAt,
  }) {
    return NenGebrek(
      id: id ?? this.id,
      inspectionId: inspectionId ?? this.inspectionId,
      bouwdeelId: bouwdeelId ?? this.bouwdeelId,
      elementcodeId:
          clearElementcodeId ? null : (elementcodeId ?? this.elementcodeId),
      gebrekReferentieId: clearGebrekReferentieId
          ? null
          : (gebrekReferentieId ?? this.gebrekReferentieId),
      gebrekOmschrijving: gebrekOmschrijving ?? this.gebrekOmschrijving,
      ernst: ernst ?? this.ernst,
      omvangPercentage: omvangPercentage ?? this.omvangPercentage,
      intensiteit: intensiteit ?? this.intensiteit,
      conditiescore: conditiescore ?? this.conditiescore,
      locatieDetail: locatieDetail ?? this.locatieDetail,
      toelichting: toelichting ?? this.toelichting,
      inspecteur: inspecteur ?? this.inspecteur,
      geinspecteerdOp: geinspecteerdOp ?? this.geinspecteerdOp,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
