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

class SolarInverter {
  final int? id;
  final int solarInstallationId;
  final String location;
  final String locationA;
  final String locationB;

  String get locationFull => [location, locationA, locationB]
      .where((p) => p.isNotEmpty)
      .join(' ');

  // Omvormer
  final String inverterName;
  final String inverterBrand;
  final String inverterType;
  final String inverterSerial;
  final String inverterIp;
  final String inverterIsolationClass;
  final String inverterMaxVdc;
  final String inverterMaxIdc;
  final String inverterIscPv;
  final String inverterInom;
  // Paneel
  final String panelBrand;
  final String panelType;
  final String panelShortCircuitCurrent;
  final String panelOpenCircuitVoltage;
  // Beveiliging / Leiding
  final String protection;
  final String cable;
  // Photo
  final String? photoPath;

  SolarInverter({
    this.id,
    required this.solarInstallationId,
    this.location = '',
    this.locationA = '',
    this.locationB = '',
    this.inverterName = '',
    this.inverterBrand = '',
    this.inverterType = '',
    this.inverterSerial = '',
    this.inverterIp = '',
    this.inverterIsolationClass = '',
    this.inverterMaxVdc = '',
    this.inverterMaxIdc = '',
    this.inverterIscPv = '',
    this.inverterInom = '',
    this.panelBrand = '',
    this.panelType = '',
    this.panelShortCircuitCurrent = '',
    this.panelOpenCircuitVoltage = '',
    this.protection = '',
    this.cable = '',
    this.photoPath,
  });

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'solar_installation_id': solarInstallationId,
      'location': location,
      'location_a': locationA,
      'location_b': locationB,
      'inverter_name': inverterName,
      'inverter_brand': inverterBrand,
      'inverter_type': inverterType,
      'inverter_serial': inverterSerial,
      'inverter_ip': inverterIp,
      'inverter_isolation_class': inverterIsolationClass,
      'inverter_max_vdc': inverterMaxVdc,
      'inverter_max_idc': inverterMaxIdc,
      'inverter_isc_pv': inverterIscPv,
      'inverter_inom': inverterInom,
      'panel_brand': panelBrand,
      'panel_type': panelType,
      'panel_short_circuit_current': panelShortCircuitCurrent,
      'panel_open_circuit_voltage': panelOpenCircuitVoltage,
      'protection': protection,
      'cable': cable,
      'photo_path': photoPath,
    };
  }

  factory SolarInverter.fromMap(Map<String, dynamic> map) {
    return SolarInverter(
      id: map['id'] as int?,
      solarInstallationId: map['solar_installation_id'] as int,
      location: map['location'] as String? ?? '',
      locationA: map['location_a'] as String? ?? '',
      locationB: map['location_b'] as String? ?? '',
      inverterName: map['inverter_name'] as String? ?? '',
      inverterBrand: map['inverter_brand'] as String? ?? '',
      inverterType: map['inverter_type'] as String? ?? '',
      inverterSerial: map['inverter_serial'] as String? ?? '',
      inverterIp: map['inverter_ip'] as String? ?? '',
      inverterIsolationClass: map['inverter_isolation_class'] as String? ?? '',
      inverterMaxVdc: map['inverter_max_vdc'] as String? ?? '',
      inverterMaxIdc: map['inverter_max_idc'] as String? ?? '',
      inverterIscPv: map['inverter_isc_pv'] as String? ?? '',
      inverterInom: map['inverter_inom'] as String? ?? '',
      panelBrand: map['panel_brand'] as String? ?? '',
      panelType: map['panel_type'] as String? ?? '',
      panelShortCircuitCurrent:
          map['panel_short_circuit_current'] as String? ?? '',
      panelOpenCircuitVoltage:
          map['panel_open_circuit_voltage'] as String? ?? '',
      protection: map['protection'] as String? ?? '',
      cable: map['cable'] as String? ?? '',
      photoPath: map['photo_path'] as String?,
    );
  }

  SolarInverter copyWith({
    int? id,
    int? solarInstallationId,
    String? location,
    String? locationA,
    String? locationB,
    String? inverterName,
    String? inverterBrand,
    String? inverterType,
    String? inverterSerial,
    String? inverterIp,
    String? inverterIsolationClass,
    String? inverterMaxVdc,
    String? inverterMaxIdc,
    String? inverterIscPv,
    String? inverterInom,
    String? panelBrand,
    String? panelType,
    String? panelShortCircuitCurrent,
    String? panelOpenCircuitVoltage,
    String? protection,
    String? cable,
    String? photoPath,
  }) {
    return SolarInverter(
      id: id ?? this.id,
      solarInstallationId: solarInstallationId ?? this.solarInstallationId,
      location: location ?? this.location,
      locationA: locationA ?? this.locationA,
      locationB: locationB ?? this.locationB,
      inverterName: inverterName ?? this.inverterName,
      inverterBrand: inverterBrand ?? this.inverterBrand,
      inverterType: inverterType ?? this.inverterType,
      inverterSerial: inverterSerial ?? this.inverterSerial,
      inverterIp: inverterIp ?? this.inverterIp,
      inverterIsolationClass:
          inverterIsolationClass ?? this.inverterIsolationClass,
      inverterMaxVdc: inverterMaxVdc ?? this.inverterMaxVdc,
      inverterMaxIdc: inverterMaxIdc ?? this.inverterMaxIdc,
      inverterIscPv: inverterIscPv ?? this.inverterIscPv,
      inverterInom: inverterInom ?? this.inverterInom,
      panelBrand: panelBrand ?? this.panelBrand,
      panelType: panelType ?? this.panelType,
      panelShortCircuitCurrent:
          panelShortCircuitCurrent ?? this.panelShortCircuitCurrent,
      panelOpenCircuitVoltage:
          panelOpenCircuitVoltage ?? this.panelOpenCircuitVoltage,
      protection: protection ?? this.protection,
      cable: cable ?? this.cable,
      photoPath: photoPath ?? this.photoPath,
    );
  }

  String get displayName {
    if (inverterName.isNotEmpty) return inverterName;
    if (inverterBrand.isNotEmpty && inverterType.isNotEmpty) {
      return '$inverterBrand $inverterType';
    }
    if (inverterBrand.isNotEmpty) return inverterBrand;
    return 'Omvormer ${id ?? ''}';
  }
}
