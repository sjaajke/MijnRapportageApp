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

class SolarStringMeasurement {
  final int? id;
  final int solarInverterId;
  final String strang;
  final String panelCount;
  final String irradiation;
  final String cellTemp;
  final String uoc;
  final String isc;
  final String riso;

  SolarStringMeasurement({
    this.id,
    required this.solarInverterId,
    this.strang = '',
    this.panelCount = '',
    this.irradiation = '',
    this.cellTemp = '',
    this.uoc = '',
    this.isc = '',
    this.riso = '',
  });

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'solar_inverter_id': solarInverterId,
      'strang': strang,
      'panel_count': panelCount,
      'irradiation': irradiation,
      'cell_temp': cellTemp,
      'uoc': uoc,
      'isc': isc,
      'riso': riso,
    };
  }

  factory SolarStringMeasurement.fromMap(Map<String, dynamic> map) {
    return SolarStringMeasurement(
      id: map['id'] as int?,
      solarInverterId: map['solar_inverter_id'] as int,
      strang: map['strang'] as String? ?? '',
      panelCount: map['panel_count'] as String? ?? '',
      irradiation: map['irradiation'] as String? ?? '',
      cellTemp: map['cell_temp'] as String? ?? '',
      uoc: map['uoc'] as String? ?? '',
      isc: map['isc'] as String? ?? '',
      riso: map['riso'] as String? ?? '',
    );
  }

  SolarStringMeasurement copyWith({
    int? id,
    int? solarInverterId,
    String? strang,
    String? panelCount,
    String? irradiation,
    String? cellTemp,
    String? uoc,
    String? isc,
    String? riso,
  }) {
    return SolarStringMeasurement(
      id: id ?? this.id,
      solarInverterId: solarInverterId ?? this.solarInverterId,
      strang: strang ?? this.strang,
      panelCount: panelCount ?? this.panelCount,
      irradiation: irradiation ?? this.irradiation,
      cellTemp: cellTemp ?? this.cellTemp,
      uoc: uoc ?? this.uoc,
      isc: isc ?? this.isc,
      riso: riso ?? this.riso,
    );
  }
}
