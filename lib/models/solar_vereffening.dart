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

class SolarVereffening {
  final int? id;
  final int solarInstallationId;
  final int volgnummer;
  final String omschrijving;
  final String leidingType;
  final String leidingMm2;
  final String rlow;

  SolarVereffening({
    this.id,
    required this.solarInstallationId,
    this.volgnummer = 1,
    this.omschrijving = '',
    this.leidingType = '',
    this.leidingMm2 = '',
    this.rlow = '',
  });

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'solar_installation_id': solarInstallationId,
      'volgnummer': volgnummer,
      'omschrijving': omschrijving,
      'leiding_type': leidingType,
      'leiding_mm2': leidingMm2,
      'rlow': rlow,
    };
  }

  factory SolarVereffening.fromMap(Map<String, dynamic> map) {
    return SolarVereffening(
      id: map['id'] as int?,
      solarInstallationId: map['solar_installation_id'] as int,
      volgnummer: map['volgnummer'] as int? ?? 1,
      omschrijving: map['omschrijving'] as String? ?? '',
      leidingType: map['leiding_type'] as String? ?? '',
      leidingMm2: map['leiding_mm2'] as String? ?? '',
      rlow: map['rlow'] as String? ?? '',
    );
  }

  SolarVereffening copyWith({
    int? id,
    int? solarInstallationId,
    int? volgnummer,
    String? omschrijving,
    String? leidingType,
    String? leidingMm2,
    String? rlow,
  }) {
    return SolarVereffening(
      id: id ?? this.id,
      solarInstallationId: solarInstallationId ?? this.solarInstallationId,
      volgnummer: volgnummer ?? this.volgnummer,
      omschrijving: omschrijving ?? this.omschrijving,
      leidingType: leidingType ?? this.leidingType,
      leidingMm2: leidingMm2 ?? this.leidingMm2,
      rlow: rlow ?? this.rlow,
    );
  }
}
