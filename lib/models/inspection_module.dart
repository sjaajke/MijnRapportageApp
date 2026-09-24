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

/// An inspection menu section that can be shown or hidden, keyed by the id
/// stored in the comma-separated `hiddenModules` of inspections and report
/// templates.
class InspectionModule {
  final String key;
  final String label;

  const InspectionModule(this.key, this.label);
}

const List<InspectionModule> inspectionModules = [
  InspectionModule('titlepage', 'Titelpagina'),
  InspectionModule('inleiding', 'Inleiding'),
  InspectionModule('generaldata', 'Algemene gegevens'),
  InspectionModule('inspectiondetails', 'Inspectie details'),
  InspectionModule('finalassessment', 'Eindbeoordeling'),
  InspectionModule('switchboards', 'Verdelers'),
  InspectionModule('solar', 'Zonnestroom-installaties'),
  InspectionModule('noodverlichting', 'Noodverlichting'),
  InspectionModule('battery', 'Batterij-installaties'),
  InspectionModule('tekeningen', 'Tekening inspectie'),
  InspectionModule('meetgegevens', 'Meetgegevens'),
  InspectionModule('bijlagen', 'Bijlagen'),
  InspectionModule('checklists', 'Checklijsten'),
  InspectionModule('herstelverklaring', 'Herstelverklaring'),
];

Set<String> parseHiddenModules(String csv) =>
    csv.isEmpty ? {} : csv.split(',').toSet();
