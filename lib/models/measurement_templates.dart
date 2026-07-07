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

/// A single fixed measurement field within a [MeasurementTypeTemplate],
/// e.g. "L1-N" with a choice of MΩ or Ω.
class MeasurementFieldTemplate {
  final String label;
  final List<String> unitOptions;

  const MeasurementFieldTemplate(this.label, this.unitOptions);
}

/// A predefined "Meting type" (e.g. Riso, RCD, Zi/Zs) with its own set of
/// sub-types (e.g. voltage/current/rating) and fixed value fields.
class MeasurementTypeTemplate {
  final String category;
  final List<String> subTypes;
  final List<MeasurementFieldTemplate> fields;

  const MeasurementTypeTemplate({
    required this.category,
    required this.subTypes,
    required this.fields,
  });
}

class MeasurementTemplates {
  static const List<String> ziZsSubTypes = [
    'B16A', 'B20A', 'B25A', 'B32A', 'B40A', 'B50A', 'B63A', 'B80A',
    'C16A', 'C20A', 'C25A', 'C32A', 'C40A', 'C50A', 'C63A', 'C80A',
  ];

  // Note: "Zi/Zs 3 fase" must be listed before "Zi/Zs" so that prefix
  // matching against a stored "meting type" string picks the longer,
  // more specific category first.
  static const List<MeasurementTypeTemplate> all = [
    MeasurementTypeTemplate(
      category: 'Riso',
      subTypes: ['250 V', '500 V'],
      fields: [
        MeasurementFieldTemplate('L1-N', ['MΩ', 'Ω']),
        MeasurementFieldTemplate('L2-N', ['MΩ', 'Ω']),
        MeasurementFieldTemplate('L3-N', ['MΩ', 'Ω']),
        MeasurementFieldTemplate('L1-PE', ['MΩ', 'Ω']),
        MeasurementFieldTemplate('N-PE', ['MΩ', 'Ω']),
      ],
    ),
    MeasurementTypeTemplate(
      category: 'RCD',
      subTypes: ['30 mA', '100 mA', '300 mA [S]', '500 mA'],
      fields: [
        MeasurementFieldTemplate('1xIdn', ['msec']),
      ],
    ),
    MeasurementTypeTemplate(
      category: 'Zi/Zs 3 fase',
      subTypes: ziZsSubTypes,
      fields: [
        MeasurementFieldTemplate('Zi-L1-N', ['Ω', 'mΩ']),
        MeasurementFieldTemplate('Zi-L2-N', ['Ω', 'mΩ']),
        MeasurementFieldTemplate('Zi-L3-N', ['Ω', 'mΩ']),
        MeasurementFieldTemplate('Zi-L1-L2', ['Ω', 'mΩ']),
        MeasurementFieldTemplate('Zi-L1-PE', ['Ω', 'mΩ']),
      ],
    ),
    MeasurementTypeTemplate(
      category: 'Zi/Zs',
      subTypes: ziZsSubTypes,
      fields: [
        MeasurementFieldTemplate('Zi', ['Ω', 'mΩ']),
        MeasurementFieldTemplate('Zs', ['Ω', 'mΩ']),
      ],
    ),
  ];

  /// Tries to split a stored "meting type" string (e.g. "Riso 500 V" or
  /// "Zi/Zs 3 fase B16A") into its known template and sub-type. Returns
  /// null if it doesn't match any known template.
  static (MeasurementTypeTemplate, String)? parse(String metingType) {
    for (final template in all) {
      final prefix = '${template.category} ';
      if (metingType.startsWith(prefix)) {
        final subType = metingType.substring(prefix.length);
        if (template.subTypes.contains(subType)) {
          return (template, subType);
        }
      }
    }
    return null;
  }
}
