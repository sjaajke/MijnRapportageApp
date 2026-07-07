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

class InspectionDetail {
  final int? id;
  final int inspectionId;
  final String scopeDescription;
  final String notInspectedParts;
  final String notInspectedReason;
  final String inspectionReason;
  final String performedAccordingTo;
  final String testedAgainst;
  final String typeRapport;
  final String inleiding;
  final String methodeVisueleInspectie;
  final String methodeMetingen;
  final String methodeAanvullendOnderzoek;
  final String methodeCriteria;
  final String inleidingToelichting;
  // Netaansluiting
  final String aardingsstelsel;
  final String netaansluiting;
  final String hoofdaansluiting;
  // Multi-select, stored as comma-separated values
  final String gebouwfunctie;
  final String bijzondereInstallatie;
  final String bouwjaar;
  final String oppervlakte;

  InspectionDetail({
    this.id,
    required this.inspectionId,
    this.scopeDescription = '',
    this.notInspectedParts = '',
    this.notInspectedReason = '',
    this.inspectionReason = '',
    this.performedAccordingTo = '',
    this.testedAgainst = '',
    this.typeRapport = '',
    this.inleiding = '',
    this.methodeVisueleInspectie = '',
    this.methodeMetingen = '',
    this.methodeAanvullendOnderzoek = '',
    this.methodeCriteria = '',
    this.inleidingToelichting = '',
    this.aardingsstelsel = '',
    this.netaansluiting = '',
    this.hoofdaansluiting = '',
    this.gebouwfunctie = '',
    this.bijzondereInstallatie = '',
    this.bouwjaar = '',
    this.oppervlakte = '',
  });

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'inspection_id': inspectionId,
      'scope_description': scopeDescription,
      'not_inspected_parts': notInspectedParts,
      'not_inspected_reason': notInspectedReason,
      'inspection_reason': inspectionReason,
      'performed_according_to': performedAccordingTo,
      'tested_against': testedAgainst,
      'type_rapport': typeRapport,
      'inleiding': inleiding,
      'methode_visuele_inspectie': methodeVisueleInspectie,
      'methode_metingen': methodeMetingen,
      'methode_aanvullend_onderzoek': methodeAanvullendOnderzoek,
      'methode_criteria': methodeCriteria,
      'inleiding_toelichting': inleidingToelichting,
      'aardingsstelsel': aardingsstelsel,
      'netaansluiting': netaansluiting,
      'hoofdaansluiting': hoofdaansluiting,
      'gebouwfunctie': gebouwfunctie,
      'bijzondere_installatie': bijzondereInstallatie,
      'bouwjaar': bouwjaar,
      'oppervlakte': oppervlakte,
    };
  }

  factory InspectionDetail.fromMap(Map<String, dynamic> map) {
    return InspectionDetail(
      id: map['id'] as int?,
      inspectionId: map['inspection_id'] as int,
      scopeDescription: map['scope_description'] as String? ?? '',
      notInspectedParts: map['not_inspected_parts'] as String? ?? '',
      notInspectedReason: map['not_inspected_reason'] as String? ?? '',
      inspectionReason: map['inspection_reason'] as String? ?? '',
      performedAccordingTo: map['performed_according_to'] as String? ?? '',
      testedAgainst: map['tested_against'] as String? ?? '',
      typeRapport: map['type_rapport'] as String? ?? '',
      inleiding: map['inleiding'] as String? ?? '',
      methodeVisueleInspectie:
          map['methode_visuele_inspectie'] as String? ?? '',
      methodeMetingen: map['methode_metingen'] as String? ?? '',
      methodeAanvullendOnderzoek:
          map['methode_aanvullend_onderzoek'] as String? ?? '',
      methodeCriteria: map['methode_criteria'] as String? ?? '',
      inleidingToelichting: map['inleiding_toelichting'] as String? ?? '',
      aardingsstelsel: map['aardingsstelsel'] as String? ?? '',
      netaansluiting: map['netaansluiting'] as String? ?? '',
      hoofdaansluiting: map['hoofdaansluiting'] as String? ?? '',
      gebouwfunctie: map['gebouwfunctie'] as String? ?? '',
      bijzondereInstallatie: map['bijzondere_installatie'] as String? ?? '',
      bouwjaar: map['bouwjaar'] as String? ?? '',
      oppervlakte: map['oppervlakte'] as String? ?? '',
    );
  }

  InspectionDetail copyWith({
    int? id,
    int? inspectionId,
    String? scopeDescription,
    String? notInspectedParts,
    String? notInspectedReason,
    String? inspectionReason,
    String? performedAccordingTo,
    String? testedAgainst,
    String? typeRapport,
    String? inleiding,
    String? methodeVisueleInspectie,
    String? methodeMetingen,
    String? methodeAanvullendOnderzoek,
    String? methodeCriteria,
    String? inleidingToelichting,
    String? aardingsstelsel,
    String? netaansluiting,
    String? hoofdaansluiting,
    String? gebouwfunctie,
    String? bijzondereInstallatie,
    String? bouwjaar,
    String? oppervlakte,
  }) {
    return InspectionDetail(
      id: id ?? this.id,
      inspectionId: inspectionId ?? this.inspectionId,
      scopeDescription: scopeDescription ?? this.scopeDescription,
      notInspectedParts: notInspectedParts ?? this.notInspectedParts,
      notInspectedReason: notInspectedReason ?? this.notInspectedReason,
      inspectionReason: inspectionReason ?? this.inspectionReason,
      performedAccordingTo: performedAccordingTo ?? this.performedAccordingTo,
      testedAgainst: testedAgainst ?? this.testedAgainst,
      typeRapport: typeRapport ?? this.typeRapport,
      inleiding: inleiding ?? this.inleiding,
      methodeVisueleInspectie:
          methodeVisueleInspectie ?? this.methodeVisueleInspectie,
      methodeMetingen: methodeMetingen ?? this.methodeMetingen,
      methodeAanvullendOnderzoek:
          methodeAanvullendOnderzoek ?? this.methodeAanvullendOnderzoek,
      methodeCriteria: methodeCriteria ?? this.methodeCriteria,
      inleidingToelichting: inleidingToelichting ?? this.inleidingToelichting,
      aardingsstelsel: aardingsstelsel ?? this.aardingsstelsel,
      netaansluiting: netaansluiting ?? this.netaansluiting,
      hoofdaansluiting: hoofdaansluiting ?? this.hoofdaansluiting,
      gebouwfunctie: gebouwfunctie ?? this.gebouwfunctie,
      bijzondereInstallatie:
          bijzondereInstallatie ?? this.bijzondereInstallatie,
      bouwjaar: bouwjaar ?? this.bouwjaar,
      oppervlakte: oppervlakte ?? this.oppervlakte,
    );
  }
}
