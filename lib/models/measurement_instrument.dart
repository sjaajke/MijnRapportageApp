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

class MeasurementInstrument {
  final int? id;
  final int? inspectorId;
  final String fabrikant;
  final String model;
  final String serienummer;
  final String kalibratiedatum;
  final String herkalibratiedatum;
  final String certificaatnummer;
  final String kalibratiefrequentie;
  final String registratienummer;
  final String status;

  MeasurementInstrument({
    this.id,
    this.inspectorId,
    this.fabrikant = '',
    this.model = '',
    this.serienummer = '',
    this.kalibratiedatum = '',
    this.herkalibratiedatum = '',
    this.certificaatnummer = '',
    this.kalibratiefrequentie = '',
    this.registratienummer = '',
    this.status = '',
  });

  String get displayName {
    final parts = [fabrikant, model].where((s) => s.isNotEmpty).join(' ');
    if (parts.isEmpty) return serienummer.isNotEmpty ? serienummer : '–';
    return serienummer.isNotEmpty ? '$parts ($serienummer)' : parts;
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'inspector_id': inspectorId,
      'fabrikant': fabrikant,
      'model': model,
      'serienummer': serienummer,
      'kalibratie_datum': kalibratiedatum,
      'herkalibratie_datum': herkalibratiedatum,
      'certificaatnummer': certificaatnummer,
      'kalibratie_frequentie': kalibratiefrequentie,
      'registratienummer': registratienummer,
      'status': status,
    };
  }

  factory MeasurementInstrument.fromMap(Map<String, dynamic> map) {
    return MeasurementInstrument(
      id: map['id'] as int?,
      inspectorId: map['inspector_id'] as int?,
      fabrikant: map['fabrikant'] as String? ?? '',
      model: map['model'] as String? ?? '',
      serienummer: map['serienummer'] as String? ?? '',
      kalibratiedatum: map['kalibratie_datum'] as String? ?? '',
      herkalibratiedatum: map['herkalibratie_datum'] as String? ?? '',
      certificaatnummer: map['certificaatnummer'] as String? ?? '',
      kalibratiefrequentie: map['kalibratie_frequentie'] as String? ?? '',
      registratienummer: map['registratienummer'] as String? ?? '',
      status: map['status'] as String? ?? '',
    );
  }

  MeasurementInstrument copyWith({
    int? id,
    int? inspectorId,
    String? fabrikant,
    String? model,
    String? serienummer,
    String? kalibratiedatum,
    String? herkalibratiedatum,
    String? certificaatnummer,
    String? kalibratiefrequentie,
    String? registratienummer,
    String? status,
  }) {
    return MeasurementInstrument(
      id: id ?? this.id,
      inspectorId: inspectorId ?? this.inspectorId,
      fabrikant: fabrikant ?? this.fabrikant,
      model: model ?? this.model,
      serienummer: serienummer ?? this.serienummer,
      kalibratiedatum: kalibratiedatum ?? this.kalibratiedatum,
      herkalibratiedatum: herkalibratiedatum ?? this.herkalibratiedatum,
      certificaatnummer: certificaatnummer ?? this.certificaatnummer,
      kalibratiefrequentie: kalibratiefrequentie ?? this.kalibratiefrequentie,
      registratienummer: registratienummer ?? this.registratienummer,
      status: status ?? this.status,
    );
  }
}
