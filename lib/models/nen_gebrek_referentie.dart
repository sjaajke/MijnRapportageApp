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

/// Eén regel uit de officiële NEN 2767-2 gebrekenlijst (lijst B.x/C.x) voor
/// een specifieke elementcode. Read-only referentiedata, geseed vanuit
/// `nen2767_seed_data.dart`. Ernst, omvang en intensiteit worden per
/// waarneming door de inspecteur vastgelegd op [NenGebrek], niet hier.
class NenGebrekReferentie {
  final int? id;
  final String? nen2767Lijstnr;
  final String elementcode;
  final String installatiedeel;
  final String elementomschrijving;
  final String gebrekOmschrijving;
  final String gebrekcode;

  /// Ernst ('E'/'S'/'G'), gedecodeerd uit het gebrekcode-patroon van de
  /// officiële lijst. Een suggestie — de inspecteur legt de daadwerkelijke
  /// ernst per waarneming vast op [NenGebrek] en kan hiervan afwijken.
  final String ernstDefault;
  final String suggestieIntensiteit;
  final String suggestieOmvang;

  NenGebrekReferentie({
    this.id,
    this.nen2767Lijstnr,
    required this.elementcode,
    this.installatiedeel = '',
    this.elementomschrijving = '',
    required this.gebrekOmschrijving,
    this.gebrekcode = '',
    this.ernstDefault = '',
    this.suggestieIntensiteit = '',
    this.suggestieOmvang = '',
  });

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'nen2767_lijstnr': nen2767Lijstnr,
      'elementcode': elementcode,
      'installatiedeel': installatiedeel,
      'elementomschrijving': elementomschrijving,
      'gebrek_omschrijving': gebrekOmschrijving,
      'gebrekcode': gebrekcode,
      'ernst_default': ernstDefault,
      'suggestie_intensiteit': suggestieIntensiteit,
      'suggestie_omvang': suggestieOmvang,
    };
  }

  factory NenGebrekReferentie.fromMap(Map<String, dynamic> map) {
    return NenGebrekReferentie(
      id: map['id'] as int?,
      nen2767Lijstnr: map['nen2767_lijstnr'] as String?,
      elementcode: map['elementcode'] as String? ?? '',
      installatiedeel: map['installatiedeel'] as String? ?? '',
      elementomschrijving: map['elementomschrijving'] as String? ?? '',
      gebrekOmschrijving: map['gebrek_omschrijving'] as String? ?? '',
      gebrekcode: map['gebrekcode'] as String? ?? '',
      ernstDefault: map['ernst_default'] as String? ?? '',
      suggestieIntensiteit: map['suggestie_intensiteit'] as String? ?? '',
      suggestieOmvang: map['suggestie_omvang'] as String? ?? '',
    );
  }
}
