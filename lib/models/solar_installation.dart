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

class SolarInstallation {
  final int? id;
  final int inspectionId;
  final String location;
  final String locationA;
  final String locationB;
  final String panelSublocation;

  String get locationFull => [location, locationA, locationB]
      .where((p) => p.isNotEmpty)
      .join(' ');
  final int? panelCount;
  final int? inverterCount;
  final int? wattPeak;
  final String constructionType;
  // Opstelling
  final String? buildingType;
  final String? roofType;
  final String? orientation;
  final String? tiltAngle;
  final String? frame;
  // Weersomstandigheden
  final String? cloudCover;
  final String? temperature;
  // Documentatie
  final String? layoutPlan;
  final String? ballastPlan;
  final String? cablePlan;
  final String? constructionDeclaration;
  final String? installationData;
  // Photos
  final String? photoRoof1Path;
  final String? photoRoof2Path;
  final String? photoInverter1Path;
  final String? photoInverter2Path;

  SolarInstallation({
    this.id,
    required this.inspectionId,
    this.location = '',
    this.locationA = '',
    this.locationB = '',
    this.panelSublocation = '',
    this.panelCount,
    this.inverterCount,
    this.wattPeak,
    this.constructionType = '',
    this.buildingType,
    this.roofType,
    this.orientation,
    this.tiltAngle,
    this.frame,
    this.cloudCover,
    this.temperature,
    this.layoutPlan,
    this.ballastPlan,
    this.cablePlan,
    this.constructionDeclaration,
    this.installationData,
    this.photoRoof1Path,
    this.photoRoof2Path,
    this.photoInverter1Path,
    this.photoInverter2Path,
  });

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'inspection_id': inspectionId,
      'location': location,
      'location_a': locationA,
      'location_b': locationB,
      'panel_sublocation': panelSublocation,
      'panel_count': panelCount,
      'inverter_count': inverterCount,
      'watt_peak': wattPeak,
      'construction_type': constructionType,
      'building_type': buildingType,
      'roof_type': roofType,
      'orientation': orientation,
      'tilt_angle': tiltAngle,
      'frame': frame,
      'cloud_cover': cloudCover,
      'temperature': temperature,
      'layout_plan': layoutPlan,
      'ballast_plan': ballastPlan,
      'cable_plan': cablePlan,
      'construction_declaration': constructionDeclaration,
      'installation_data': installationData,
      'photo_roof1_path': photoRoof1Path,
      'photo_roof2_path': photoRoof2Path,
      'photo_inverter1_path': photoInverter1Path,
      'photo_inverter2_path': photoInverter2Path,
    };
  }

  factory SolarInstallation.fromMap(Map<String, dynamic> map) {
    return SolarInstallation(
      id: map['id'] as int?,
      inspectionId: map['inspection_id'] as int,
      location: map['location'] as String? ?? '',
      locationA: map['location_a'] as String? ?? '',
      locationB: map['location_b'] as String? ?? '',
      panelSublocation: map['panel_sublocation'] as String? ?? '',
      panelCount: map['panel_count'] as int?,
      inverterCount: map['inverter_count'] as int?,
      wattPeak: map['watt_peak'] as int?,
      constructionType: map['construction_type'] as String? ?? '',
      buildingType: map['building_type'] as String?,
      roofType: map['roof_type'] as String?,
      orientation: map['orientation'] as String?,
      tiltAngle: map['tilt_angle'] as String?,
      frame: map['frame'] as String?,
      cloudCover: map['cloud_cover'] as String?,
      temperature: map['temperature'] as String?,
      layoutPlan: map['layout_plan'] as String?,
      ballastPlan: map['ballast_plan'] as String?,
      cablePlan: map['cable_plan'] as String?,
      constructionDeclaration: map['construction_declaration'] as String?,
      installationData: map['installation_data'] as String?,
      photoRoof1Path: map['photo_roof1_path'] as String?,
      photoRoof2Path: map['photo_roof2_path'] as String?,
      photoInverter1Path: map['photo_inverter1_path'] as String?,
      photoInverter2Path: map['photo_inverter2_path'] as String?,
    );
  }

  SolarInstallation copyWith({
    int? id,
    int? inspectionId,
    String? location,
    String? locationA,
    String? locationB,
    String? panelSublocation,
    int? panelCount,
    int? inverterCount,
    int? wattPeak,
    String? constructionType,
    String? buildingType,
    String? roofType,
    String? orientation,
    String? tiltAngle,
    String? frame,
    String? cloudCover,
    String? temperature,
    String? layoutPlan,
    String? ballastPlan,
    String? cablePlan,
    String? constructionDeclaration,
    String? installationData,
    String? photoRoof1Path,
    String? photoRoof2Path,
    String? photoInverter1Path,
    String? photoInverter2Path,
  }) {
    return SolarInstallation(
      id: id ?? this.id,
      inspectionId: inspectionId ?? this.inspectionId,
      location: location ?? this.location,
      locationA: locationA ?? this.locationA,
      locationB: locationB ?? this.locationB,
      panelSublocation: panelSublocation ?? this.panelSublocation,
      panelCount: panelCount ?? this.panelCount,
      inverterCount: inverterCount ?? this.inverterCount,
      wattPeak: wattPeak ?? this.wattPeak,
      constructionType: constructionType ?? this.constructionType,
      buildingType: buildingType ?? this.buildingType,
      roofType: roofType ?? this.roofType,
      orientation: orientation ?? this.orientation,
      tiltAngle: tiltAngle ?? this.tiltAngle,
      frame: frame ?? this.frame,
      cloudCover: cloudCover ?? this.cloudCover,
      temperature: temperature ?? this.temperature,
      layoutPlan: layoutPlan ?? this.layoutPlan,
      ballastPlan: ballastPlan ?? this.ballastPlan,
      cablePlan: cablePlan ?? this.cablePlan,
      constructionDeclaration:
          constructionDeclaration ?? this.constructionDeclaration,
      installationData: installationData ?? this.installationData,
      photoRoof1Path: photoRoof1Path ?? this.photoRoof1Path,
      photoRoof2Path: photoRoof2Path ?? this.photoRoof2Path,
      photoInverter1Path: photoInverter1Path ?? this.photoInverter1Path,
      photoInverter2Path: photoInverter2Path ?? this.photoInverter2Path,
    );
  }
}
