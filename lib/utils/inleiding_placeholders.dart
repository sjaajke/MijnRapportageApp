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

import '../models/general_data.dart';
import '../models/title_page.dart';

/// Replaces the placeholder tokens used in the "Inleiding" template text
/// with the corresponding live values from the general data and title page.
String fillInleidingPlaceholders(
  String text, {
  GeneralData? generalData,
  TitlePage? titlePage,
}) {
  return text
      .replaceAll('[OPDRACHTGEVER]', generalData?.clientCompany ?? '')
      .replaceAll('[PLAATS OPDRACHTGEVER]', generalData?.clientPostalCity ?? '')
      .replaceAll('[INSPECTIEDATUM]', titlePage?.inspectionDate ?? '')
      .replaceAll('[INSPECTIEBEDRIJF]', generalData?.inspectorCompany ?? '')
      .replaceAll(
          '[NAAM INSPECTIEADRES]', generalData?.inspectionAddressStreet ?? '')
      .replaceAll('[PLAATS INSPECTIE ADRES]',
          generalData?.inspectionAddressPostalCity ?? '')
      .replaceAll('[PROJECTNR]', titlePage?.projectNumber ?? '');
}
