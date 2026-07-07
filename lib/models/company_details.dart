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

class CompanyDetails {
  final int? id;
  final String companyName;
  final String address;
  final String postalCity;
  final String phone;
  final String email;
  final String contactPerson;
  final String inspectors;
  final String? logoPath;
  final String? logoTitelpaginaPath;
  final String? logoSciosPath;
  final String herstelFirebaseProjectId;
  final String herstelFirebaseStorageBucket;
  final String herstelWebDomain;

  CompanyDetails({
    this.id,
    this.companyName = '',
    this.address = '',
    this.postalCity = '',
    this.phone = '',
    this.email = '',
    this.contactPerson = '',
    this.inspectors = '',
    this.logoPath,
    this.logoTitelpaginaPath,
    this.logoSciosPath,
    this.herstelFirebaseProjectId = '',
    this.herstelFirebaseStorageBucket = '',
    this.herstelWebDomain = '',
  });

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'company_name': companyName,
      'address': address,
      'postal_city': postalCity,
      'phone': phone,
      'email': email,
      'contact_person': contactPerson,
      'inspectors': inspectors,
      'logo_path': logoPath,
      'logo_titelpagina_path': logoTitelpaginaPath,
      'logo_scios_path': logoSciosPath,
      'herstel_firebase_project_id': herstelFirebaseProjectId,
      'herstel_firebase_storage_bucket': herstelFirebaseStorageBucket,
      'herstel_web_domain': herstelWebDomain,
    };
  }

  factory CompanyDetails.fromMap(Map<String, dynamic> map) {
    return CompanyDetails(
      id: map['id'] as int?,
      companyName: map['company_name'] as String? ?? '',
      address: map['address'] as String? ?? '',
      postalCity: map['postal_city'] as String? ?? '',
      phone: map['phone'] as String? ?? '',
      email: map['email'] as String? ?? '',
      contactPerson: map['contact_person'] as String? ?? '',
      inspectors: map['inspectors'] as String? ?? '',
      logoPath: map['logo_path'] as String?,
      logoTitelpaginaPath: map['logo_titelpagina_path'] as String?,
      logoSciosPath: map['logo_scios_path'] as String?,
      herstelFirebaseProjectId:
          map['herstel_firebase_project_id'] as String? ?? '',
      herstelFirebaseStorageBucket:
          map['herstel_firebase_storage_bucket'] as String? ?? '',
      herstelWebDomain: map['herstel_web_domain'] as String? ?? '',
    );
  }

  CompanyDetails copyWith({
    int? id,
    String? companyName,
    String? address,
    String? postalCity,
    String? phone,
    String? email,
    String? contactPerson,
    String? inspectors,
    String? logoPath,
    String? logoTitelpaginaPath,
    String? logoSciosPath,
    String? herstelFirebaseProjectId,
    String? herstelFirebaseStorageBucket,
    String? herstelWebDomain,
  }) {
    return CompanyDetails(
      id: id ?? this.id,
      companyName: companyName ?? this.companyName,
      address: address ?? this.address,
      postalCity: postalCity ?? this.postalCity,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      contactPerson: contactPerson ?? this.contactPerson,
      inspectors: inspectors ?? this.inspectors,
      logoPath: logoPath ?? this.logoPath,
      logoTitelpaginaPath: logoTitelpaginaPath ?? this.logoTitelpaginaPath,
      logoSciosPath: logoSciosPath ?? this.logoSciosPath,
      herstelFirebaseProjectId:
          herstelFirebaseProjectId ?? this.herstelFirebaseProjectId,
      herstelFirebaseStorageBucket:
          herstelFirebaseStorageBucket ?? this.herstelFirebaseStorageBucket,
      herstelWebDomain: herstelWebDomain ?? this.herstelWebDomain,
    );
  }
}
