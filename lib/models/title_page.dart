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

class TitlePage {
  final int? id;
  final int inspectionId;
  final String title;
  final String subtitle;
  final String? photoPath;
  final String? logoTitelpaginaPath;
  final String inspectionDate;
  final String inspectionDateEnd;
  final String identificationCode;
  final String projectNumber;
  // Layout: position (center as fraction 0–1) and size (fraction 0–1) per element.
  final double titleX;
  final double titleY;
  final double titleW;
  final double titleH;
  final double photoX;
  final double photoY;
  final double photoW;
  final double photoH;
  final double dateX;
  final double dateY;
  final double dateW;
  final double dateH;
  final double codeX;
  final double codeY;
  final double codeW;
  final double codeH;
  final double projectX;
  final double projectY;
  final double projectW;
  final double projectH;
  final double subtitleX;
  final double subtitleY;
  final double subtitleW;
  final double subtitleH;
  final double logoX;
  final double logoY;
  final double logoW;
  final double logoH;
  final double addressNameX;
  final double addressNameY;
  final double addressNameW;
  final double addressNameH;
  final bool showSciosLogo;
  final bool dateColorWhite;
  final bool codeColorWhite;
  final bool projectColorWhite;

  TitlePage({
    this.id,
    required this.inspectionId,
    this.title = '',
    this.subtitle = '',
    this.photoPath,
    this.logoTitelpaginaPath,
    this.inspectionDate = '',
    this.inspectionDateEnd = '',
    this.identificationCode = '',
    this.projectNumber = '',
    this.titleX = 0.5,
    this.titleY = 0.15,
    this.titleW = 0.80,
    this.titleH = 0.10,
    this.photoX = 0.5,
    this.photoY = 0.50,
    this.photoW = 0.60,
    this.photoH = 0.35,
    this.dateX = 0.5,
    this.dateY = 0.78,
    this.dateW = 0.70,
    this.dateH = 0.065,
    this.codeX = 0.5,
    this.codeY = 0.86,
    this.codeW = 0.70,
    this.codeH = 0.065,
    this.projectX = 0.5,
    this.projectY = 0.93,
    this.projectW = 0.70,
    this.projectH = 0.065,
    this.subtitleX = 0.5,
    this.subtitleY = 0.26,
    this.subtitleW = 0.70,
    this.subtitleH = 0.07,
    this.logoX = 0.82,
    this.logoY = 0.07,
    this.logoW = 0.30,
    this.logoH = 0.12,
    this.addressNameX = 0.5,
    this.addressNameY = 0.72,
    this.addressNameW = 0.70,
    this.addressNameH = 0.065,
    this.showSciosLogo = true,
    this.dateColorWhite = false,
    this.codeColorWhite = false,
    this.projectColorWhite = false,
  });

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'inspection_id': inspectionId,
      'title': title,
      'subtitle': subtitle,
      'photo_path': photoPath,
      'logo_titelpagina_path': logoTitelpaginaPath,
      'inspection_date': inspectionDate,
      'inspection_date_end': inspectionDateEnd,
      'identification_code': identificationCode,
      'project_number': projectNumber,
      'title_x': titleX, 'title_y': titleY,
      'title_w': titleW, 'title_h': titleH,
      'photo_x': photoX, 'photo_y': photoY,
      'photo_w': photoW, 'photo_h': photoH,
      'date_x': dateX,   'date_y': dateY,
      'date_w': dateW,   'date_h': dateH,
      'code_x': codeX,   'code_y': codeY,
      'code_w': codeW,   'code_h': codeH,
      'project_x': projectX, 'project_y': projectY,
      'project_w': projectW, 'project_h': projectH,
      'subtitle_x': subtitleX, 'subtitle_y': subtitleY,
      'subtitle_w': subtitleW, 'subtitle_h': subtitleH,
      'logo_x': logoX, 'logo_y': logoY,
      'logo_w': logoW, 'logo_h': logoH,
      'address_name_x': addressNameX, 'address_name_y': addressNameY,
      'address_name_w': addressNameW, 'address_name_h': addressNameH,
      'show_scios_logo': showSciosLogo ? 1 : 0,
      'date_color_white': dateColorWhite ? 1 : 0,
      'code_color_white': codeColorWhite ? 1 : 0,
      'project_color_white': projectColorWhite ? 1 : 0,
    };
  }

  factory TitlePage.fromMap(Map<String, dynamic> map) {
    double d(String key, double def) =>
        (map[key] as num?)?.toDouble() ?? def;
    return TitlePage(
      id: map['id'] as int?,
      inspectionId: map['inspection_id'] as int,
      title: map['title'] as String? ?? '',
      subtitle: map['subtitle'] as String? ?? '',
      photoPath: map['photo_path'] as String?,
      logoTitelpaginaPath: map['logo_titelpagina_path'] as String?,
      inspectionDate: map['inspection_date'] as String? ?? '',
      inspectionDateEnd: map['inspection_date_end'] as String? ?? '',
      identificationCode: map['identification_code'] as String? ?? '',
      projectNumber: map['project_number'] as String? ?? '',
      titleX: d('title_x', 0.5),   titleY: d('title_y', 0.15),
      titleW: d('title_w', 0.80),   titleH: d('title_h', 0.10),
      photoX: d('photo_x', 0.5),   photoY: d('photo_y', 0.50),
      photoW: d('photo_w', 0.60),   photoH: d('photo_h', 0.35),
      dateX:  d('date_x',  0.5),    dateY:  d('date_y',  0.78),
      dateW:  d('date_w',  0.70),   dateH:  d('date_h',  0.065),
      codeX:  d('code_x',  0.5),    codeY:  d('code_y',  0.86),
      codeW:  d('code_w',  0.70),   codeH:  d('code_h',  0.065),
      projectX: d('project_x', 0.5),  projectY: d('project_y', 0.93),
      projectW: d('project_w', 0.70),  projectH: d('project_h', 0.065),
      subtitleX: d('subtitle_x', 0.5),  subtitleY: d('subtitle_y', 0.26),
      subtitleW: d('subtitle_w', 0.70), subtitleH: d('subtitle_h', 0.07),
      logoX: d('logo_x', 0.82),  logoY: d('logo_y', 0.07),
      logoW: d('logo_w', 0.30),  logoH: d('logo_h', 0.12),
      addressNameX: d('address_name_x', 0.5),  addressNameY: d('address_name_y', 0.72),
      addressNameW: d('address_name_w', 0.70),  addressNameH: d('address_name_h', 0.065),
      showSciosLogo: (map['show_scios_logo'] as int? ?? 1) == 1,
      dateColorWhite: (map['date_color_white'] as int? ?? 0) == 1,
      codeColorWhite: (map['code_color_white'] as int? ?? 0) == 1,
      projectColorWhite: (map['project_color_white'] as int? ?? 0) == 1,
    );
  }

  TitlePage copyWith({
    int? id, int? inspectionId,
    String? title, String? subtitle, String? photoPath, String? logoTitelpaginaPath, String? inspectionDate,
    String? inspectionDateEnd, String? identificationCode, String? projectNumber,
    double? titleX, double? titleY, double? titleW, double? titleH,
    double? photoX, double? photoY, double? photoW, double? photoH,
    double? dateX,  double? dateY,  double? dateW,  double? dateH,
    double? codeX,  double? codeY,  double? codeW,  double? codeH,
    double? projectX, double? projectY, double? projectW, double? projectH,
    double? subtitleX, double? subtitleY, double? subtitleW, double? subtitleH,
    double? logoX, double? logoY, double? logoW, double? logoH,
    double? addressNameX, double? addressNameY, double? addressNameW, double? addressNameH,
    bool? showSciosLogo,
    bool? dateColorWhite,
    bool? codeColorWhite,
    bool? projectColorWhite,
  }) {
    return TitlePage(
      id: id ?? this.id,
      inspectionId: inspectionId ?? this.inspectionId,
      title: title ?? this.title,
      subtitle: subtitle ?? this.subtitle,
      photoPath: photoPath ?? this.photoPath,
      logoTitelpaginaPath: logoTitelpaginaPath ?? this.logoTitelpaginaPath,
      inspectionDate: inspectionDate ?? this.inspectionDate,
      inspectionDateEnd: inspectionDateEnd ?? this.inspectionDateEnd,
      identificationCode: identificationCode ?? this.identificationCode,
      projectNumber: projectNumber ?? this.projectNumber,
      titleX: titleX ?? this.titleX, titleY: titleY ?? this.titleY,
      titleW: titleW ?? this.titleW, titleH: titleH ?? this.titleH,
      photoX: photoX ?? this.photoX, photoY: photoY ?? this.photoY,
      photoW: photoW ?? this.photoW, photoH: photoH ?? this.photoH,
      dateX:  dateX  ?? this.dateX,  dateY:  dateY  ?? this.dateY,
      dateW:  dateW  ?? this.dateW,  dateH:  dateH  ?? this.dateH,
      codeX:  codeX  ?? this.codeX,  codeY:  codeY  ?? this.codeY,
      codeW:  codeW  ?? this.codeW,  codeH:  codeH  ?? this.codeH,
      projectX: projectX ?? this.projectX, projectY: projectY ?? this.projectY,
      projectW: projectW ?? this.projectW, projectH: projectH ?? this.projectH,
      subtitleX: subtitleX ?? this.subtitleX, subtitleY: subtitleY ?? this.subtitleY,
      subtitleW: subtitleW ?? this.subtitleW, subtitleH: subtitleH ?? this.subtitleH,
      logoX: logoX ?? this.logoX, logoY: logoY ?? this.logoY,
      logoW: logoW ?? this.logoW, logoH: logoH ?? this.logoH,
      addressNameX: addressNameX ?? this.addressNameX,
      addressNameY: addressNameY ?? this.addressNameY,
      addressNameW: addressNameW ?? this.addressNameW,
      addressNameH: addressNameH ?? this.addressNameH,
      showSciosLogo: showSciosLogo ?? this.showSciosLogo,
      dateColorWhite: dateColorWhite ?? this.dateColorWhite,
      codeColorWhite: codeColorWhite ?? this.codeColorWhite,
      projectColorWhite: projectColorWhite ?? this.projectColorWhite,
    );
  }
}
