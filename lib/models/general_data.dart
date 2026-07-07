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

class GeneralData {
  final int? id;
  final int inspectionId;
  final String clientCompany;
  final String clientAddress;
  final String clientPostalCity;
  final String clientContact;
  final String clientPhone;
  final String installationResponsibleName;
  final String installationResponsiblePhone;
  final String inspectionAddressName;
  final String inspectionAddressStreet;
  final String inspectionAddressPostalCity;
  final String inspectionAddressContact;
  final String inspectionAddressPhone;
  final String inspectorCompany;
  final String inspectorAddress;
  final String inspectorPostalCity;
  final String inspectorPhone;
  final String inspectorEmail;
  final String inspectorContact;
  final String inspectors;
  final String measurementInstruments;

  GeneralData({
    this.id,
    required this.inspectionId,
    this.clientCompany = '',
    this.clientAddress = '',
    this.clientPostalCity = '',
    this.clientContact = '',
    this.clientPhone = '',
    this.installationResponsibleName = '',
    this.installationResponsiblePhone = '',
    this.inspectionAddressName = '',
    this.inspectionAddressStreet = '',
    this.inspectionAddressPostalCity = '',
    this.inspectionAddressContact = '',
    this.inspectionAddressPhone = '',
    this.inspectorCompany = '',
    this.inspectorAddress = '',
    this.inspectorPostalCity = '',
    this.inspectorPhone = '',
    this.inspectorEmail = '',
    this.inspectorContact = '',
    this.inspectors = '',
    this.measurementInstruments = '',
  });

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'inspection_id': inspectionId,
      'client_company': clientCompany,
      'client_address': clientAddress,
      'client_postal_city': clientPostalCity,
      'client_contact': clientContact,
      'client_phone': clientPhone,
      'installation_responsible_name': installationResponsibleName,
      'installation_responsible_phone': installationResponsiblePhone,
      'inspection_address_name': inspectionAddressName,
      'inspection_address_street': inspectionAddressStreet,
      'inspection_address_postal_city': inspectionAddressPostalCity,
      'inspection_address_contact': inspectionAddressContact,
      'inspection_address_phone': inspectionAddressPhone,
      'inspector_company': inspectorCompany,
      'inspector_address': inspectorAddress,
      'inspector_postal_city': inspectorPostalCity,
      'inspector_phone': inspectorPhone,
      'inspector_email': inspectorEmail,
      'inspector_contact': inspectorContact,
      'inspectors': inspectors,
      'measurement_instruments': measurementInstruments,
    };
  }

  factory GeneralData.fromMap(Map<String, dynamic> map) {
    return GeneralData(
      id: map['id'] as int?,
      inspectionId: map['inspection_id'] as int,
      clientCompany: map['client_company'] as String? ?? '',
      clientAddress: map['client_address'] as String? ?? '',
      clientPostalCity: map['client_postal_city'] as String? ?? '',
      clientContact: map['client_contact'] as String? ?? '',
      clientPhone: map['client_phone'] as String? ?? '',
      installationResponsibleName:
          map['installation_responsible_name'] as String? ?? '',
      installationResponsiblePhone:
          map['installation_responsible_phone'] as String? ?? '',
      inspectionAddressName: map['inspection_address_name'] as String? ?? '',
      inspectionAddressStreet: map['inspection_address_street'] as String? ?? '',
      inspectionAddressPostalCity: map['inspection_address_postal_city'] as String? ?? '',
      inspectionAddressContact: map['inspection_address_contact'] as String? ?? '',
      inspectionAddressPhone: map['inspection_address_phone'] as String? ?? '',
      inspectorCompany: map['inspector_company'] as String? ?? '',
      inspectorAddress: map['inspector_address'] as String? ?? '',
      inspectorPostalCity: map['inspector_postal_city'] as String? ?? '',
      inspectorPhone: map['inspector_phone'] as String? ?? '',
      inspectorEmail: map['inspector_email'] as String? ?? '',
      inspectorContact: map['inspector_contact'] as String? ?? '',
      inspectors: map['inspectors'] as String? ?? '',
      measurementInstruments: map['measurement_instruments'] as String? ?? '',
    );
  }

  GeneralData copyWith({
    int? id,
    int? inspectionId,
    String? clientCompany,
    String? clientAddress,
    String? clientPostalCity,
    String? clientContact,
    String? clientPhone,
    String? installationResponsibleName,
    String? installationResponsiblePhone,
    String? inspectionAddressName,
    String? inspectionAddressStreet,
    String? inspectionAddressPostalCity,
    String? inspectionAddressContact,
    String? inspectionAddressPhone,
    String? inspectorCompany,
    String? inspectorAddress,
    String? inspectorPostalCity,
    String? inspectorPhone,
    String? inspectorEmail,
    String? inspectorContact,
    String? inspectors,
    String? measurementInstruments,
  }) {
    return GeneralData(
      id: id ?? this.id,
      inspectionId: inspectionId ?? this.inspectionId,
      clientCompany: clientCompany ?? this.clientCompany,
      clientAddress: clientAddress ?? this.clientAddress,
      clientPostalCity: clientPostalCity ?? this.clientPostalCity,
      clientContact: clientContact ?? this.clientContact,
      clientPhone: clientPhone ?? this.clientPhone,
      installationResponsibleName:
          installationResponsibleName ?? this.installationResponsibleName,
      installationResponsiblePhone:
          installationResponsiblePhone ?? this.installationResponsiblePhone,
      inspectionAddressName: inspectionAddressName ?? this.inspectionAddressName,
      inspectionAddressStreet: inspectionAddressStreet ?? this.inspectionAddressStreet,
      inspectionAddressPostalCity: inspectionAddressPostalCity ?? this.inspectionAddressPostalCity,
      inspectionAddressContact: inspectionAddressContact ?? this.inspectionAddressContact,
      inspectionAddressPhone: inspectionAddressPhone ?? this.inspectionAddressPhone,
      inspectorCompany: inspectorCompany ?? this.inspectorCompany,
      inspectorAddress: inspectorAddress ?? this.inspectorAddress,
      inspectorPostalCity: inspectorPostalCity ?? this.inspectorPostalCity,
      inspectorPhone: inspectorPhone ?? this.inspectorPhone,
      inspectorEmail: inspectorEmail ?? this.inspectorEmail,
      inspectorContact: inspectorContact ?? this.inspectorContact,
      inspectors: inspectors ?? this.inspectors,
      measurementInstruments: measurementInstruments ?? this.measurementInstruments,
    );
  }
}
