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

class NoodverlichtingInstallation {
  final int? id;
  final int inspectionId;
  final int? componentNr;
  final String name;
  final String nameCode;
  final String location;
  final String locationA;
  final String locationB;

  String get locationFull => [location, locationA, locationB]
      .where((p) => p.isNotEmpty)
      .join(' ');

  final String merk;
  final String lichtbron;
  final String accuType;
  final String typeNoodverlichting;
  final String typeSteker;
  final String hoogte;
  final String functie;
  final String montage;
  final String chemieVanDeAccu;

  final String typeInstallatie;
  final String installatieOnderdeel;
  final String componentFunctie;
  final String jaarVanAanleg;
  final String inspectieDatum;
  final String inspectieInterval;

  /// Derived from [inspectieDatum] + [inspectieInterval] (jaren); not stored.
  String get herinspectieDatum {
    final interval = int.tryParse(inspectieInterval.trim());
    if (interval == null) return '';
    final parts = inspectieDatum.split('-');
    if (parts.length != 3) return '';
    final day = int.tryParse(parts[0]);
    final month = int.tryParse(parts[1]);
    final year = int.tryParse(parts[2]);
    if (day == null || month == null || year == null) return '';
    final date = DateTime(year + interval, month, day);
    return '${date.day.toString().padLeft(2, '0')}-'
        '${date.month.toString().padLeft(2, '0')}-${date.year}';
  }

  final String? photoAccuPath;
  final String? photoStekkerAansluitingPath;
  final String? photoAfbeeldingPath;
  final String? photoTypePlaatjePath;
  final String? photoGebruiktPictogramPath;
  final String? photoAfbeeldingDetailPath;

  /// 'R' (rood), 'O' (oranje) or 'G' (groen).
  final String status;

  final String opmerkingOptie;
  final String opmerking;
  final int sortOrder;

  static const List<String> statusOptions = ['R', 'O', 'G'];

  NoodverlichtingInstallation({
    this.id,
    required this.inspectionId,
    this.componentNr,
    this.name = '',
    this.nameCode = '',
    this.location = '',
    this.locationA = '',
    this.locationB = '',
    this.merk = '',
    this.lichtbron = '',
    this.accuType = '',
    this.typeNoodverlichting = '',
    this.typeSteker = '',
    this.hoogte = '',
    this.functie = '',
    this.montage = '',
    this.chemieVanDeAccu = '',
    this.typeInstallatie = 'Noodverlichtingsinstallatie',
    this.installatieOnderdeel = 'Noodverlichting',
    this.componentFunctie = 'Noodverlichting',
    this.jaarVanAanleg = '',
    this.inspectieDatum = '',
    this.inspectieInterval = '',
    this.photoAccuPath,
    this.photoStekkerAansluitingPath,
    this.photoAfbeeldingPath,
    this.photoTypePlaatjePath,
    this.photoGebruiktPictogramPath,
    this.photoAfbeeldingDetailPath,
    this.status = 'G',
    this.opmerkingOptie = '',
    this.opmerking = '',
    this.sortOrder = 0,
  });

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'inspection_id': inspectionId,
      'component_nr': componentNr,
      'name': name,
      'name_code': nameCode,
      'location': location,
      'location_a': locationA,
      'location_b': locationB,
      'merk': merk,
      'lichtbron': lichtbron,
      'accu_type': accuType,
      'type_noodverlichting': typeNoodverlichting,
      'type_steker': typeSteker,
      'hoogte': hoogte,
      'functie': functie,
      'montage': montage,
      'chemie_van_de_accu': chemieVanDeAccu,
      'type_installatie': typeInstallatie,
      'installatie_onderdeel': installatieOnderdeel,
      'component_functie': componentFunctie,
      'jaar_van_aanleg': jaarVanAanleg,
      'inspectie_datum': inspectieDatum,
      'inspectie_interval': inspectieInterval,
      'photo_accu_path': photoAccuPath,
      'photo_stekker_aansluiting_path': photoStekkerAansluitingPath,
      'photo_afbeelding_path': photoAfbeeldingPath,
      'photo_type_plaatje_path': photoTypePlaatjePath,
      'photo_gebruikt_pictogram_path': photoGebruiktPictogramPath,
      'photo_afbeelding_detail_path': photoAfbeeldingDetailPath,
      'status': status,
      'opmerking_optie': opmerkingOptie,
      'opmerking': opmerking,
      'sort_order': sortOrder,
    };
  }

  factory NoodverlichtingInstallation.fromMap(Map<String, dynamic> map) {
    return NoodverlichtingInstallation(
      id: map['id'] as int?,
      inspectionId: map['inspection_id'] as int,
      componentNr: map['component_nr'] as int?,
      name: map['name'] as String? ?? '',
      nameCode: map['name_code'] as String? ?? '',
      location: map['location'] as String? ?? '',
      locationA: map['location_a'] as String? ?? '',
      locationB: map['location_b'] as String? ?? '',
      merk: map['merk'] as String? ?? '',
      lichtbron: map['lichtbron'] as String? ?? '',
      accuType: map['accu_type'] as String? ?? '',
      typeNoodverlichting: map['type_noodverlichting'] as String? ?? '',
      typeSteker: map['type_steker'] as String? ?? '',
      hoogte: map['hoogte'] as String? ?? '',
      functie: map['functie'] as String? ?? '',
      montage: map['montage'] as String? ?? '',
      chemieVanDeAccu: map['chemie_van_de_accu'] as String? ?? '',
      typeInstallatie: map['type_installatie'] as String? ??
          'Noodverlichtingsinstallatie',
      installatieOnderdeel:
          map['installatie_onderdeel'] as String? ?? 'Noodverlichting',
      componentFunctie:
          map['component_functie'] as String? ?? 'Noodverlichting',
      jaarVanAanleg: map['jaar_van_aanleg'] as String? ?? '',
      inspectieDatum: map['inspectie_datum'] as String? ?? '',
      inspectieInterval: map['inspectie_interval'] as String? ?? '',
      photoAccuPath: map['photo_accu_path'] as String?,
      photoStekkerAansluitingPath:
          map['photo_stekker_aansluiting_path'] as String?,
      photoAfbeeldingPath: map['photo_afbeelding_path'] as String?,
      photoTypePlaatjePath: map['photo_type_plaatje_path'] as String?,
      photoGebruiktPictogramPath:
          map['photo_gebruikt_pictogram_path'] as String?,
      photoAfbeeldingDetailPath:
          map['photo_afbeelding_detail_path'] as String?,
      status: map['status'] as String? ?? 'G',
      opmerkingOptie: map['opmerking_optie'] as String? ?? '',
      opmerking: map['opmerking'] as String? ?? '',
      sortOrder: map['sort_order'] as int? ?? 0,
    );
  }

  NoodverlichtingInstallation copyWith({
    int? id,
    int? inspectionId,
    int? componentNr,
    bool clearComponentNr = false,
    String? name,
    String? nameCode,
    String? location,
    String? locationA,
    String? locationB,
    String? merk,
    String? lichtbron,
    String? accuType,
    String? typeNoodverlichting,
    String? typeSteker,
    String? hoogte,
    String? functie,
    String? montage,
    String? chemieVanDeAccu,
    String? typeInstallatie,
    String? installatieOnderdeel,
    String? componentFunctie,
    String? jaarVanAanleg,
    String? inspectieDatum,
    String? inspectieInterval,
    String? photoAccuPath,
    String? photoStekkerAansluitingPath,
    String? photoAfbeeldingPath,
    String? photoTypePlaatjePath,
    String? photoGebruiktPictogramPath,
    String? photoAfbeeldingDetailPath,
    bool clearPhotoAccuPath = false,
    bool clearPhotoStekkerAansluitingPath = false,
    bool clearPhotoAfbeeldingPath = false,
    bool clearPhotoTypePlaatjePath = false,
    bool clearPhotoGebruiktPictogramPath = false,
    bool clearPhotoAfbeeldingDetailPath = false,
    String? status,
    String? opmerkingOptie,
    String? opmerking,
    int? sortOrder,
  }) {
    return NoodverlichtingInstallation(
      id: id ?? this.id,
      inspectionId: inspectionId ?? this.inspectionId,
      componentNr:
          clearComponentNr ? null : (componentNr ?? this.componentNr),
      name: name ?? this.name,
      nameCode: nameCode ?? this.nameCode,
      location: location ?? this.location,
      locationA: locationA ?? this.locationA,
      locationB: locationB ?? this.locationB,
      merk: merk ?? this.merk,
      lichtbron: lichtbron ?? this.lichtbron,
      accuType: accuType ?? this.accuType,
      typeNoodverlichting: typeNoodverlichting ?? this.typeNoodverlichting,
      typeSteker: typeSteker ?? this.typeSteker,
      hoogte: hoogte ?? this.hoogte,
      functie: functie ?? this.functie,
      montage: montage ?? this.montage,
      chemieVanDeAccu: chemieVanDeAccu ?? this.chemieVanDeAccu,
      typeInstallatie: typeInstallatie ?? this.typeInstallatie,
      installatieOnderdeel: installatieOnderdeel ?? this.installatieOnderdeel,
      componentFunctie: componentFunctie ?? this.componentFunctie,
      jaarVanAanleg: jaarVanAanleg ?? this.jaarVanAanleg,
      inspectieDatum: inspectieDatum ?? this.inspectieDatum,
      inspectieInterval: inspectieInterval ?? this.inspectieInterval,
      photoAccuPath:
          clearPhotoAccuPath ? null : (photoAccuPath ?? this.photoAccuPath),
      photoStekkerAansluitingPath: clearPhotoStekkerAansluitingPath
          ? null
          : (photoStekkerAansluitingPath ?? this.photoStekkerAansluitingPath),
      photoAfbeeldingPath: clearPhotoAfbeeldingPath
          ? null
          : (photoAfbeeldingPath ?? this.photoAfbeeldingPath),
      photoTypePlaatjePath: clearPhotoTypePlaatjePath
          ? null
          : (photoTypePlaatjePath ?? this.photoTypePlaatjePath),
      photoGebruiktPictogramPath: clearPhotoGebruiktPictogramPath
          ? null
          : (photoGebruiktPictogramPath ?? this.photoGebruiktPictogramPath),
      photoAfbeeldingDetailPath: clearPhotoAfbeeldingDetailPath
          ? null
          : (photoAfbeeldingDetailPath ?? this.photoAfbeeldingDetailPath),
      status: status ?? this.status,
      opmerkingOptie: opmerkingOptie ?? this.opmerkingOptie,
      opmerking: opmerking ?? this.opmerking,
      sortOrder: sortOrder ?? this.sortOrder,
    );
  }
}
