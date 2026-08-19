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

import '../models/nen_gebrek.dart';

/// Implementatie van de NEN 2767-conditiescoremethodiek (ernst × intensiteit
/// × omvang → conditiescore 1 t/m 6), en de aggregatie van meerdere
/// gebreken op één bouwdeel/element tot één geaggregeerde conditiescore.
///
/// De scorematrices en de aggregatieformule zijn overgenomen uit een
/// werkend NEN 2767-inspectieformulier (sheet "Stamgegevens", genoemde
/// bereiken `Ernstig`/`Serieus`/`Gering` en het "correctiefactor"-blok) en
/// tegen de voorbeeldregels van dat formulier geverifieerd (drie
/// steekproeven, exacte overeenkomst). Pure functies, geen UI/DB-
/// afhankelijkheden.
class Nen2767ScoringService {
  /// Omvangklasse-grenzen (fractie 0-1): <2%, 2-10%, 10-30%, 30-70%, >70%.
  static const List<double> _omvangGrenzen = [0, 0.02, 0.1, 0.3, 0.7];

  /// cvo-matrix per ernstniveau: rij = intensiteit (Begin/Gevorderd/Eind),
  /// kolom = omvangklasse (index overeenkomstig [_omvangGrenzen]).
  static const Map<String, Map<String, List<int>>> _matrix = {
    'E': {
      'Begin': [1, 1, 2, 3, 4],
      'Gevorderd': [1, 2, 3, 4, 5],
      'Eind': [2, 3, 4, 5, 6],
    },
    'S': {
      'Begin': [1, 1, 1, 2, 3],
      'Gevorderd': [1, 1, 2, 3, 4],
      'Eind': [1, 2, 3, 4, 5],
    },
    'G': {
      'Begin': [1, 1, 1, 1, 2],
      'Gevorderd': [1, 1, 1, 2, 3],
      'Eind': [1, 1, 2, 3, 4],
    },
  };

  /// Correctiefactor per conditieklasse (1 t/m 6), gebruikt bij het
  /// aggregeren van meerdere gebreken tot één conditiescore.
  static const Map<int, double> _correctiefactor = {
    1: 1.0,
    2: 1.02,
    3: 1.1,
    4: 1.3,
    5: 1.7,
    6: 2.0,
  };

  /// Grenswaarden om een geaggregeerde score (na correctiefactor-weging)
  /// naar een conditieklasse 1 t/m 6 te herleiden.
  static const List<double> _conditieklasseGrenzen = [1.01, 1.04, 1.15, 1.40, 1.78];

  static int _omvangklasseIndex(double omvangFractie) {
    var index = 0;
    for (var i = 0; i < _omvangGrenzen.length; i++) {
      if (omvangFractie >= _omvangGrenzen[i]) index = i;
    }
    return index;
  }

  /// Berekent de conditiescore (1-6) van één gebrek op basis van ernst
  /// ('E'/'S'/'G'), intensiteit ('Begin'/'Gevorderd'/'Eind') en de omvang
  /// als percentage (0-100) van het beschouwde bouwdeel/element.
  static int gebrekScore({
    required String ernst,
    required String intensiteit,
    required double omvangPercentage,
  }) {
    final ernstRow = _matrix[ernst] ?? _matrix['G']!;
    final scores = ernstRow[intensiteit] ?? ernstRow['Begin']!;
    final fractie = (omvangPercentage / 100).clamp(0.0, 1.0);
    return scores[_omvangklasseIndex(fractie)];
  }

  /// Herleidt een geaggregeerde score (zie [aggregeerConditiescore]) naar
  /// een conditieklasse 1 t/m 6 via de officiële grenswaarden.
  static int conditieklasse(double geaggregeerdeScore) {
    for (var i = 0; i < _conditieklasseGrenzen.length; i++) {
      if (geaggregeerdeScore <= _conditieklasseGrenzen[i]) return i + 1;
    }
    return 6;
  }

  /// Aggregeert de conditiescores van alle gebreken op één bouwdeel/element
  /// tot één conditieklasse (1-6). Gebreken zonder geconstateerde afwijking
  /// worden impliciet meegenomen als "geen gebrek" (klasse 1) voor het deel
  /// van de omvang dat niet door een gebrek gedekt wordt, zodat de totale
  /// omvang altijd optelt tot 100%.
  static int aggregeerConditiescore(List<NenGebrek> gebreken) {
    if (gebreken.isEmpty) return 1;

    final omvangPerKlasse = <int, double>{for (var k = 1; k <= 6; k++) k: 0};

    var omvangGedekt = 0.0;
    for (final gebrek in gebreken) {
      final fractie = (gebrek.omvangPercentage / 100).clamp(0.0, 1.0);
      omvangGedekt += fractie;
      final score = gebrekScore(
        ernst: gebrek.ernst,
        intensiteit: gebrek.intensiteit,
        omvangPercentage: gebrek.omvangPercentage,
      );
      omvangPerKlasse[score] = (omvangPerKlasse[score] ?? 0) + fractie;
    }

    final restOmvang = (1 - omvangGedekt).clamp(0.0, 1.0);
    omvangPerKlasse[1] = (omvangPerKlasse[1] ?? 0) + restOmvang;

    var totaalOmvang = 0.0;
    var totaalGewogen = 0.0;
    omvangPerKlasse.forEach((klasse, omvang) {
      totaalOmvang += omvang;
      totaalGewogen += omvang * (_correctiefactor[klasse] ?? 1.0);
    });

    if (totaalOmvang <= 0) return 1;
    return conditieklasse(totaalGewogen / totaalOmvang);
  }
}
