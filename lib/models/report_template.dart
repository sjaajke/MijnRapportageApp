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

class ReportTemplate {
  final int? id;
  final String typeRapport;
  final String rapporttitel;
  final String subtitel;
  final String inleiding;
  final String tekstRapportVerklaring;
  final String visueleInspectieTitel;
  final String visueleInspectie;
  final String visueleInspectieToelichting;
  final String metingenTitel;
  final String metingen;
  final String metingenToelichting;
  final String aanvullendOnderzoekTitel;
  final String aanvullendOnderzoek;
  final String aanvullendOnderzoekToelichting;
  final String lijst4Titel;
  final String lijst4;
  final String lijst4Toelichting;
  final String vinklijstAfkeuringscriteria;
  final String inspectieUitgevoerdVolgens;
  final String elektrischMaterieelGetoetst;
  final String inleidingToelichting;
  final String volgendInspectie;
  final String eindbeoordelingOKE;
  final String meldingGevaarlijkeSituatie;

  ReportTemplate({
    this.id,
    this.typeRapport = '',
    this.rapporttitel = '',
    this.subtitel = '',
    this.inleiding = '',
    this.tekstRapportVerklaring = '',
    this.visueleInspectieTitel = '',
    this.visueleInspectie = '',
    this.visueleInspectieToelichting = '',
    this.metingenTitel = '',
    this.metingen = '',
    this.metingenToelichting = '',
    this.aanvullendOnderzoekTitel = '',
    this.aanvullendOnderzoek = '',
    this.aanvullendOnderzoekToelichting = '',
    this.lijst4Titel = '',
    this.lijst4 = '',
    this.lijst4Toelichting = '',
    this.vinklijstAfkeuringscriteria = '',
    this.inspectieUitgevoerdVolgens = '',
    this.elektrischMaterieelGetoetst = '',
    this.inleidingToelichting = '',
    this.volgendInspectie = '',
    this.eindbeoordelingOKE = '',
    this.meldingGevaarlijkeSituatie = '',
  });

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'type_rapport': typeRapport,
      'rapporttitel': rapporttitel,
      'subtitel': subtitel,
      'inleiding': inleiding,
      'tekst_rapport_verklaring': tekstRapportVerklaring,
      'visuele_inspectie_titel': visueleInspectieTitel,
      'visuele_inspectie': visueleInspectie,
      'visuele_inspectie_toelichting': visueleInspectieToelichting,
      'metingen_titel': metingenTitel,
      'metingen': metingen,
      'metingen_toelichting': metingenToelichting,
      'aanvullend_onderzoek_titel': aanvullendOnderzoekTitel,
      'aanvullend_onderzoek': aanvullendOnderzoek,
      'aanvullend_onderzoek_toelichting': aanvullendOnderzoekToelichting,
      'lijst4_titel': lijst4Titel,
      'lijst4': lijst4,
      'lijst4_toelichting': lijst4Toelichting,
      'vinklijst_afkeuringscriteria': vinklijstAfkeuringscriteria,
      'inspectie_uitgevoerd_volgens': inspectieUitgevoerdVolgens,
      'elektrisch_materieel_getoetst': elektrischMaterieelGetoetst,
      'inleiding_toelichting': inleidingToelichting,
      'volgend_inspectie': volgendInspectie,
      'eindbeoordeling_oke': eindbeoordelingOKE,
      'melding_gevaarlijke_situatie': meldingGevaarlijkeSituatie,
    };
  }

  factory ReportTemplate.fromMap(Map<String, dynamic> map) {
    return ReportTemplate(
      id: map['id'] as int?,
      typeRapport: map['type_rapport'] as String? ?? '',
      rapporttitel: map['rapporttitel'] as String? ?? '',
      subtitel: map['subtitel'] as String? ?? '',
      inleiding: map['inleiding'] as String? ?? '',
      tekstRapportVerklaring: map['tekst_rapport_verklaring'] as String? ?? '',
      visueleInspectieTitel: map['visuele_inspectie_titel'] as String? ?? '',
      visueleInspectie: map['visuele_inspectie'] as String? ?? '',
      visueleInspectieToelichting:
          map['visuele_inspectie_toelichting'] as String? ?? '',
      metingenTitel: map['metingen_titel'] as String? ?? '',
      metingen: map['metingen'] as String? ?? '',
      metingenToelichting: map['metingen_toelichting'] as String? ?? '',
      aanvullendOnderzoekTitel:
          map['aanvullend_onderzoek_titel'] as String? ?? '',
      aanvullendOnderzoek: map['aanvullend_onderzoek'] as String? ?? '',
      aanvullendOnderzoekToelichting:
          map['aanvullend_onderzoek_toelichting'] as String? ?? '',
      lijst4Titel: map['lijst4_titel'] as String? ?? '',
      lijst4: map['lijst4'] as String? ?? '',
      lijst4Toelichting: map['lijst4_toelichting'] as String? ?? '',
      vinklijstAfkeuringscriteria:
          map['vinklijst_afkeuringscriteria'] as String? ?? '',
      inspectieUitgevoerdVolgens:
          map['inspectie_uitgevoerd_volgens'] as String? ?? '',
      elektrischMaterieelGetoetst:
          map['elektrisch_materieel_getoetst'] as String? ?? '',
      inleidingToelichting:
          map['inleiding_toelichting'] as String? ?? '',
      volgendInspectie: map['volgend_inspectie'] as String? ?? '',
      eindbeoordelingOKE: map['eindbeoordeling_oke'] as String? ?? '',
      meldingGevaarlijkeSituatie:
          map['melding_gevaarlijke_situatie'] as String? ?? '',
    );
  }

  ReportTemplate copyWith({
    int? id,
    String? typeRapport,
    String? rapporttitel,
    String? subtitel,
    String? inleiding,
    String? tekstRapportVerklaring,
    String? visueleInspectieTitel,
    String? visueleInspectie,
    String? visueleInspectieToelichting,
    String? metingenTitel,
    String? metingen,
    String? metingenToelichting,
    String? aanvullendOnderzoekTitel,
    String? aanvullendOnderzoek,
    String? aanvullendOnderzoekToelichting,
    String? lijst4Titel,
    String? lijst4,
    String? lijst4Toelichting,
    String? vinklijstAfkeuringscriteria,
    String? inspectieUitgevoerdVolgens,
    String? elektrischMaterieelGetoetst,
    String? inleidingToelichting,
    String? volgendInspectie,
    String? eindbeoordelingOKE,
    String? meldingGevaarlijkeSituatie,
  }) {
    return ReportTemplate(
      id: id ?? this.id,
      typeRapport: typeRapport ?? this.typeRapport,
      rapporttitel: rapporttitel ?? this.rapporttitel,
      subtitel: subtitel ?? this.subtitel,
      inleiding: inleiding ?? this.inleiding,
      tekstRapportVerklaring:
          tekstRapportVerklaring ?? this.tekstRapportVerklaring,
      visueleInspectieTitel:
          visueleInspectieTitel ?? this.visueleInspectieTitel,
      visueleInspectie: visueleInspectie ?? this.visueleInspectie,
      visueleInspectieToelichting:
          visueleInspectieToelichting ?? this.visueleInspectieToelichting,
      metingenTitel: metingenTitel ?? this.metingenTitel,
      metingen: metingen ?? this.metingen,
      metingenToelichting: metingenToelichting ?? this.metingenToelichting,
      aanvullendOnderzoekTitel:
          aanvullendOnderzoekTitel ?? this.aanvullendOnderzoekTitel,
      aanvullendOnderzoek: aanvullendOnderzoek ?? this.aanvullendOnderzoek,
      aanvullendOnderzoekToelichting:
          aanvullendOnderzoekToelichting ?? this.aanvullendOnderzoekToelichting,
      lijst4Titel: lijst4Titel ?? this.lijst4Titel,
      lijst4: lijst4 ?? this.lijst4,
      lijst4Toelichting: lijst4Toelichting ?? this.lijst4Toelichting,
      vinklijstAfkeuringscriteria:
          vinklijstAfkeuringscriteria ?? this.vinklijstAfkeuringscriteria,
      inspectieUitgevoerdVolgens:
          inspectieUitgevoerdVolgens ?? this.inspectieUitgevoerdVolgens,
      elektrischMaterieelGetoetst:
          elektrischMaterieelGetoetst ?? this.elektrischMaterieelGetoetst,
      inleidingToelichting:
          inleidingToelichting ?? this.inleidingToelichting,
      volgendInspectie: volgendInspectie ?? this.volgendInspectie,
      eindbeoordelingOKE: eindbeoordelingOKE ?? this.eindbeoordelingOKE,
      meldingGevaarlijkeSituatie:
          meldingGevaarlijkeSituatie ?? this.meldingGevaarlijkeSituatie,
    );
  }
}
