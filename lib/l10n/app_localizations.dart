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

import 'package:flutter/material.dart';

class AppLocalizations {
  final Locale locale;

  AppLocalizations(this.locale);

  bool get isNl => locale.languageCode == 'nl';

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  // ── Home page ──────────────────────────────────────────────────────────────

  String get inspections => isNl ? 'Inspecties' : 'Inspections';
  String get newInspection => isNl ? 'Nieuwe Inspectie' : 'New Inspection';
  String get deleteInspection =>
      isNl ? 'Inspectie verwijderen' : 'Delete Inspection';
  String get deleteInspectionConfirm => isNl
      ? 'Weet u zeker dat u deze inspectie wilt verwijderen?'
      : 'Are you sure you want to delete this inspection?';
  String get cancel => isNl ? 'Annuleren' : 'Cancel';
  String get delete => isNl ? 'Verwijderen' : 'Delete';
  String get statusCompleted => isNl ? 'Afgerond' : 'Completed';
  String get statusExported => isNl ? 'Geëxporteerd' : 'Exported';
  String get statusDraft => isNl ? 'Concept' : 'Draft';
  String get noInspections => isNl
      ? 'Geen inspecties gevonden.\nMaak een nieuwe inspectie aan.'
      : 'No inspections found.\nCreate a new inspection.';
  String get exportXml => isNl ? 'Export XML' : 'Export XML';
  String get generatePdf => isNl ? 'Genereer PDF' : 'Generate PDF';
  String get generateConstateriungPdf =>
      isNl ? 'Genereer PDF Constatering' : 'Generate PDF Findings';
  String get generateSwitchboardConstateriungPdf => isNl
      ? 'Genereer PDF Schakel- en verdeelinrichten en constateringen'
      : 'Generate PDF Switchboards and findings';
  String get generateHerstelPdf =>
      isNl ? 'Genereer PDF Herstel' : 'Generate PDF Repair';
  String get samplePdf => isNl ? 'Voorbeeld PDF' : 'Sample PDF';
  String xmlExported(String path) =>
      isNl ? 'XML geëxporteerd: $path' : 'XML exported: $path';
  String exportFailed(Object e) =>
      isNl ? 'Export mislukt: $e' : 'Export failed: $e';
  String pdfFailed(Object e) =>
      isNl ? 'PDF generatie mislukt: $e' : 'PDF generation failed: $e';
  String samplePdfFailed(Object e) =>
      isNl ? 'Voorbeeld PDF mislukt: $e' : 'Sample PDF failed: $e';
  String inspectionNumber(int id) =>
      isNl ? 'Inspectie #$id' : 'Inspection #$id';
  String get shareText => isNl ? 'Inspectie PDF' : 'Inspection PDF';
  String get shareSampleText =>
      isNl ? 'Voorbeeld Inspectie PDF' : 'Sample Inspection PDF';
  String get language => isNl ? 'Taal' : 'Language';
  String get duplicateInspection =>
      isNl ? 'Dupliceren' : 'Duplicate';
  String get duplicateInspectionFailed => isNl
      ? 'Dupliceren mislukt'
      : 'Duplicating failed';
  String get copySuffix => isNl ? ' (kopie)' : ' (copy)';

  // ── Inspection menu page ───────────────────────────────────────────────────

  String get inspection => isNl ? 'Inspectie' : 'Inspection';
  String get titlePageTitle => isNl ? 'Titelpagina' : 'Title Page';
  String get titlePageSubtitle =>
      isNl ? 'Titel, foto en basisgegevens' : 'Title, photo and basic data';
  String get inleidingTitle => isNl ? 'Inleiding' : 'Introduction';
  String get inleidingSubtitle => isNl
      ? 'Inleidende tekst van het rapport'
      : 'Introductory text of the report';
  String get inleidingLabel => isNl ? 'Inleiding' : 'Introduction';
  String get generalData => isNl ? 'Algemene Gegevens' : 'General Data';
  String get generalDataSubtitle => isNl
      ? 'Opdrachtgever, inspectieadres, inspectiebedrijf'
      : 'Client, inspection address, inspection company';
  String get inspectionDetails =>
      isNl ? 'Inspectie Details' : 'Inspection Details';
  String get inspectionDetailsSubtitle =>
      isNl ? 'Omvang en uitgangspunten' : 'Scope and assumptions';
  String get switchboardsMenu =>
      isNl ? 'Schakel- en verdeelinrichtingen' : 'Switchboards';
  String get switchboardsMenuSubtitle =>
      isNl ? 'Verdelers beheren' : 'Manage switchboards';
  String get solarInstallations =>
      isNl ? 'Zonnestroom-installaties' : 'Solar Installations';
  String get solarInstallationsSubtitle =>
      isNl ? 'PV-installaties beheren' : 'Manage PV installations';
  String get batteryInstallations =>
      isNl ? 'Accu-installaties' : 'Battery Installations';
  String get comingSoon => isNl ? 'Binnenkort beschikbaar' : 'Coming soon';
  String get batteryComingSoon => isNl
      ? 'Accu-installaties komt binnenkort'
      : 'Battery installations coming soon';
  String get defects => isNl ? 'Constateringen' : 'Findings';
  String get defectsSubtitle =>
      isNl ? 'Constateringen registreren' : 'Register findings';
  String get finalAssessment => isNl ? 'Eindbeoordeling' : 'Final assessment';
  String get finalAssessmentSubtitle =>
      isNl ? 'Beoordeling en ondertekening' : 'Assessment and signatures';
  String get nextInspection => isNl ? 'Volgende inspectie' : 'Next inspection';
  String get signatory => isNl ? 'Ondertekenaar' : 'Signatory';
  String get signatoryName => isNl ? 'Naam' : 'Name';
  String get signatoryFunction => isNl ? 'Functie' : 'Function';
  String get signatoryDate => isNl ? 'Datum' : 'Date';
  String get signature => isNl ? 'Handtekening' : 'Signature';
  String get clearSignature => isNl ? 'Handtekening wissen' : 'Clear signature';
  String get signHere => isNl ? 'Teken hier...' : 'Sign here...';
  String get completeInspectionButton =>
      isNl ? 'Inspectie Afronden' : 'Complete Inspection';
  String get completeInspectionConfirm => isNl
      ? 'Weet u zeker dat u deze inspectie wilt afronden?'
      : 'Are you sure you want to complete this inspection?';
  String get complete => isNl ? 'Afronden' : 'Complete';

  // ── General data page ──────────────────────────────────────────────────────

  String get client => isNl ? 'Opdrachtgever' : 'Client';
  String get companyName => isNl ? 'Naam Bedrijf' : 'Company Name';
  String get address => isNl ? 'Adres' : 'Address';
  String get postalCity => isNl ? 'Postcode Plaats' : 'Postal Code City';
  String get contactPerson => isNl ? 'Contactpersoon' : 'Contact Person';
  String get phoneNumber => isNl ? 'Telefoonnummer' : 'Phone Number';
  String get installationResponsible =>
      isNl ? 'Installatieverantwoordelijke' : 'Installation Responsible';
  String get inspectionAddress =>
      isNl ? 'Inspectieadres' : 'Inspection Address';
  String get name => isNl ? 'Naam' : 'Name';
  String get inspectionCompany =>
      isNl ? 'Inspectiebedrijf' : 'Inspection Company';
  String get companyNameField => isNl ? 'Naam bedrijf' : 'Company name';
  String get phone => isNl ? 'Telefoon' : 'Phone';
  String get emailField => isNl ? 'Mail' : 'Email';
  String get inspectors => isNl ? 'Inspecteur(s)' : 'Inspector(s)';
  String get noInspectorsFound => isNl
      ? 'Geen inspecteurs gevonden in Bedrijfsgegevens.'
      : 'No inspectors found in Company Details.';
  String get next => isNl ? 'Volgende' : 'Next';

  // ── Company details page ───────────────────────────────────────────────────

  String get companyDetails => isNl ? 'Bedrijfsgegevens' : 'Company Details';
  String get companyLogo => isNl ? 'Bedrijfslogo' : 'Company Logo';
  String get logo => isNl ? 'Logo' : 'Logo';
  String get companyInfo => isNl ? 'Bedrijfsinformatie' : 'Company Information';
  String get herstelFirebaseSectionTitle =>
      isNl ? 'Herstel-koppeling (Firebase)' : 'Herstel link (Firebase)';
  String get herstelFirebaseProjectId =>
      isNl ? 'Firebase project-ID' : 'Firebase project ID';
  String get herstelFirebaseStorageBucket =>
      isNl ? 'Firebase storage bucket' : 'Firebase storage bucket';
  String get herstelWebDomain =>
      isNl ? 'Hosting-domein webformulier' : 'Web form hosting domain';
  String get herstelFirebaseNote => isNl
      ? 'Nodig voor de QR-code op de PDF en de "Ophalen"-knop bij Herstel. Te vinden in de Firebase Console.'
      : 'Needed for the PDF QR code and the "Fetch" button on the Herstel page. Found in the Firebase Console.';
  String get emailLabel => isNl ? 'E-mail' : 'Email';
  String get inspectorsSectionTitle => isNl ? 'Inspecteurs' : 'Inspectors';
  String get addInspector => isNl ? 'Inspecteur toevoegen' : 'Add Inspector';
  String get noInspectorsAdded =>
      isNl ? 'Nog geen inspecteurs toegevoegd.' : 'No inspectors added yet.';
  String get autoFillNote => isNl
      ? 'Deze gegevens worden automatisch ingevuld bij nieuwe inspecties.'
      : 'These details are automatically filled in for new inspections.';
  String get editInspector => isNl ? 'Inspecteur wijzigen' : 'Edit Inspector';
  String get inspectorExists =>
      isNl ? 'Deze inspecteur bestaat al.' : 'This inspector already exists.';
  String get inspectorDetails =>
      isNl ? 'Inspecteur gegevens' : 'Inspector details';
  String get deleteInspectorTitle =>
      isNl ? 'Inspecteur verwijderen' : 'Delete Inspector';
  String deleteInspectorConfirm(String inspectorName) => isNl
      ? 'Weet u zeker dat u "$inspectorName" wilt verwijderen?'
      : 'Are you sure you want to delete "$inspectorName"?';
  String get add => isNl ? 'Toevoegen' : 'Add';
  String get save => isNl ? 'Opslaan' : 'Save';

  // ── Measurement instruments ────────────────────────────────────────────────

  String get measurementInstrumentsSectionTitle =>
      isNl ? 'Meetinstrumenten' : 'Measuring Instruments';
  String get addMeasurementInstrument =>
      isNl ? 'Meetinstrument toevoegen' : 'Add Measuring Instrument';
  String get editMeasurementInstrument =>
      isNl ? 'Meetinstrument wijzigen' : 'Edit Measuring Instrument';
  String get deleteMeasurementInstrument =>
      isNl ? 'Meetinstrument verwijderen' : 'Delete Measuring Instrument';
  String deleteMeasurementInstrumentConfirm(String name) => isNl
      ? 'Weet u zeker dat u "$name" wilt verwijderen?'
      : 'Are you sure you want to delete "$name"?';
  String get noMeasurementInstrumentsAdded => isNl
      ? 'Nog geen meetinstrumenten toegevoegd.'
      : 'No measuring instruments added yet.';
  String get manageMeasurementInstruments =>
      isNl ? 'Meetinstrumenten beheren' : 'Manage measuring instruments';
  String get noMeasurementInstrumentsFound => isNl
      ? 'Geen meetinstrumenten gevonden in Bedrijfsgegevens.'
      : 'No measuring instruments found in Company Details.';
  String get manufacturer => isNl ? 'Fabrikant' : 'Manufacturer';
  String get instrumentModel => isNl ? 'Model' : 'Model';
  String get serialNumber => isNl ? 'Serienummer' : 'Serial number';
  String get calibrationDate => isNl ? 'Kalibratiedatum' : 'Calibration date';
  String get recalibrationDate =>
      isNl ? 'Herkalibratiedatum' : 'Recalibration date';
  String get certificateNumber =>
      isNl ? 'Certificaatnummer' : 'Certificate number';
  String get calibrationFrequency =>
      isNl ? 'Kalibratie frequentie (jaar)' : 'Calibration frequency (years)';
  String get registrationNumber =>
      isNl ? 'Registratienummer' : 'Registration number';
  String get instrumentStatus => isNl ? 'Status' : 'Status';

  // ── Report templates page ──────────────────────────────────────────────────

  String get reportTexts => isNl ? 'Rapport teksten' : 'Report texts';
  String get reportType => isNl ? 'Type rapport' : 'Report type';
  String get reportTitleField => isNl ? 'Rapporttitel' : 'Report title';
  String get reportSubtitle => isNl ? 'Subtitel' : 'Subtitle';
  String get reportIntroduction => isNl ? 'Inleiding' : 'Introduction';
  String get reportDeclaration => isNl ? 'Eindbeoordeling' : 'Final assessment';
  String get visualInspectionTitle =>
      isNl ? 'Visuele inspectie - Titel' : 'Visual inspection - Title';
  String get visualInspectionText =>
      isNl ? 'Visuele inspectie' : 'Visual inspection';
  String get visualInspectionNote =>
      isNl ? 'Visuele inspectie - Toelichting' : 'Visual inspection - Note';
  String get measurementsTitle =>
      isNl ? 'Metingen en beproevingen - Titel' : 'Measurements - Title';
  String get measurementsText =>
      isNl ? 'Metingen en beproevingen' : 'Measurements';
  String get measurementsNote =>
      isNl ? 'Metingen en beproevingen - Toelichting' : 'Measurements - Note';
  String get additionalResearchTitle =>
      isNl ? 'Aanvullend onderzoek - Titel' : 'Additional research - Title';
  String get additionalResearchText =>
      isNl ? 'Aanvullend onderzoek' : 'Additional research';
  String get additionalResearchNote =>
      isNl ? 'Toelichting aanvullend onderzoek' : 'Additional research - Note';
  String get list4Title => isNl ? 'Lijst 4 - Titel' : 'List 4 - Title';
  String get list4Text => isNl ? 'Lijst 4' : 'List 4';
  String get list4Note => isNl ? 'Lijst 4 - Toelichting' : 'List 4 - Note';
  String get rejectionCriteria => isNl ? 'Classificatie' : 'Classification';
  String get noReportTemplates =>
      isNl ? 'Geen rapport teksten gevonden.' : 'No report texts found.';
  String get addReportTemplate =>
      isNl ? 'Rapport tekst toevoegen' : 'Add report text';
  String get editReportTemplate =>
      isNl ? 'Rapport tekst wijzigen' : 'Edit report text';
  String get deleteReportTemplate =>
      isNl ? 'Rapport tekst verwijderen' : 'Delete report text';
  String deleteReportTemplateConfirm(String name) => isNl
      ? 'Weet u zeker dat u "$name" wilt verwijderen?'
      : 'Are you sure you want to delete "$name"?';
  String get generalSection => isNl ? 'Algemeen' : 'General';
  String get introductionSection =>
      isNl ? 'Inleiding en verklaring' : 'Introduction and declaration';
  String get inspectieUitgevoerdVolgens => isNl
      ? 'De inspectie is uitgevoerd volgens'
      : 'Inspection performed according to';
  String get elektrischMaterieelGetoetst => isNl
      ? 'Het elektrisch materieel is getoetst aan'
      : 'Electrical equipment tested against';
  String get inleidingToelichting => isNl ? 'Toelichting' : 'Note';

  String get calibrationSectionTitle => isNl ? 'Kalibratie' : 'Calibration';
  String get linkedInspector =>
      isNl ? 'Gekoppelde inspecteur' : 'Linked inspector';
  String get noInspectorLinked => isNl ? 'Geen koppeling' : 'No link';

  // ── Title page ─────────────────────────────────────────────────────────────

  String get titleLabel => isNl ? 'Titel' : 'Title';
  String get subtitleLabel => isNl ? 'Subtitel' : 'Subtitle';
  String get addPhoto => isNl ? 'Foto toevoegen' : 'Add Photo';
  String get inspectionDate => isNl ? 'Inspectiedatum' : 'Inspection Date';
  String get inspectionDateEnd =>
      isNl ? 'Inspectiedatum t/m' : 'Inspection Date Until';
  String get identificationCode =>
      isNl ? 'Identificatiecode' : 'Identification Code';
  String get projectNumber =>
      isNl ? 'Project-/werkbonnummer' : 'Project/work order number';

  // ── Settings page ──────────────────────────────────────────────────────────

  String get settings => isNl ? 'Instellingen' : 'Settings';
  String get standards => isNl ? 'Standaarden' : 'Standards';

  // ── Standards page ─────────────────────────────────────────────────────────

  String get catSystem => isNl ? 'Stelsel' : 'System';
  String get catProtection => isNl ? 'Voorbeveiliging' : 'Pre-protection';
  String get catProtectionClass =>
      isNl ? 'Beschermingsgraad omhulsel' : 'Protection class';
  String get catCable => isNl ? 'Leiding doorsnede' : 'Cable cross-section';
  String get catCableLength => isNl ? 'Leiding lengte' : 'Cable length';
  String get catMainSwitch => isNl ? 'Hoofdsch. stroom' : 'Main switch current';
  String get catMainSwitchPoles =>
      isNl ? 'Hoofdsch. polen' : 'Main switch poles';
  String get catCableType => isNl ? 'Leiding type' : 'Cable type';
  String get catLocation => isNl ? 'Locatie' : 'Location';
  String get catLocationA => isNl ? 'Locatie A' : 'Location A';
  String get catLocationB => isNl ? 'Locatie B' : 'Location B';
  String get catAarding => isNl ? 'Aarding' : 'Earthing';
  String get catInspectionReason =>
      isNl ? 'Reden voor inspectie' : 'Reason for inspection';
  String get catKarakteristiek => isNl ? 'Karakteristiek' : 'Characteristic';
  String addCategory(String label) => isNl ? '$label toevoegen' : 'Add $label';
  String editCategory(String label) => isNl ? '$label wijzigen' : 'Edit $label';
  String get value => isNl ? 'Waarde' : 'Value';
  String get displayName => isNl ? 'Weergavenaam' : 'Display name';
  String get noItems => isNl ? 'Geen items' : 'No items';
  String valuePrefix(String v) => isNl ? 'Waarde: $v' : 'Value: $v';
  String get deleteTitle => isNl ? 'Verwijderen' : 'Delete';
  String deleteItemConfirm(String itemName) => isNl
      ? 'Weet u zeker dat u "$itemName" wilt verwijderen?'
      : 'Are you sure you want to delete "$itemName"?';

  // ── Switchboards list page ─────────────────────────────────────────────────

  String get switchboardsTitle =>
      isNl ? 'Schakel- en verdeelinrichtingen' : 'Switchboards';
  String get newSwitchboard => isNl ? 'Nieuwe Verdeler' : 'New Switchboard';
  String get noSwitchboards => isNl
      ? 'Geen verdelers.\nVoeg een nieuwe verdeler toe.'
      : 'No switchboards.\nAdd a new switchboard.';
  String get deleteSwitchboard =>
      isNl ? 'Verdeler verwijderen' : 'Delete Switchboard';
  String get deleteSwitchboardConfirm => isNl
      ? 'Weet u zeker dat u deze verdeler wilt verwijderen?'
      : 'Are you sure you want to delete this switchboard?';
  String switchboardNumber(int id) =>
      isNl ? 'Verdeler #$id' : 'Switchboard #$id';

  // ── Solar installations list page ──────────────────────────────────────────

  String get solarTitle =>
      isNl ? 'Zonnestroom-installaties' : 'Solar Installations';
  String get newInstallation =>
      isNl ? 'Nieuwe Installatie' : 'New Installation';
  String get noInstallations => isNl
      ? 'Geen installaties.\nVoeg een nieuwe installatie toe.'
      : 'No installations.\nAdd a new installation.';
  String get deleteInstallation =>
      isNl ? 'Installatie verwijderen' : 'Delete Installation';
  String get deleteInstallationConfirm => isNl
      ? 'Weet u zeker dat u deze installatie wilt verwijderen?'
      : 'Are you sure you want to delete this installation?';
  String installationNumber(int id) =>
      isNl ? 'Installatie #$id' : 'Installation #$id';
  String panelCount(int count) => isNl ? '$count panelen' : '$count panels';

  // ── Defects list page ──────────────────────────────────────────────────────

  String get defectsTitle => isNl ? 'Gebreken' : 'Defects';
  String get newDefect => isNl ? 'Nieuw Gebrek' : 'New Defect';
  String get noDefects => isNl
      ? 'Geen gebreken.\nVoeg een nieuw gebrek toe.'
      : 'No defects.\nAdd a new defect.';
  String get deleteDefect => isNl ? 'Gebrek verwijderen' : 'Delete Defect';
  String get deleteDefectConfirm => isNl
      ? 'Weet u zeker dat u dit gebrek wilt verwijderen?'
      : 'Are you sure you want to delete this defect?';
  String get deleteAllDefects =>
      isNl ? 'Alle gebreken verwijderen' : 'Delete All Defects';
  String get deleteAllDefectsConfirm => isNl
      ? 'Weet u zeker dat u alle gebreken wilt verwijderen? Dit kan niet ongedaan worden gemaakt.'
      : 'Are you sure you want to delete all defects? This cannot be undone.';
  String defectNumber(int id) => isNl ? 'Gebrek #$id' : 'Defect #$id';
  String get selectDefects => isNl ? 'Gebreken selecteren' : 'Select Defects';
  String get selectAll => isNl ? 'Alles selecteren' : 'Select All';
  String get deselectAll => isNl ? 'Alles deselecteren' : 'Deselect All';
  String get deleteSelected =>
      isNl ? 'Selectie verwijderen' : 'Delete Selected';
  String get deleteSelectedConfirm => isNl
      ? 'Weet u zeker dat u de geselecteerde gebreken wilt verwijderen? Dit kan niet ongedaan worden gemaakt.'
      : 'Are you sure you want to delete the selected defects? This cannot be undone.';
  String selectedCount(int count) =>
      isNl ? '$count geselecteerd' : '$count selected';

  // ── Defect detail page ─────────────────────────────────────────────────────

  String get defect => isNl ? 'Gebrek' : 'Defect';
  String get location => isNl ? 'Locatie' : 'Location';
  String get classification => isNl ? 'Classificatie' : 'Classification';
  String get defectDescription =>
      isNl ? 'Omschrijving constatering' : 'Finding description';
  String get photo1 => isNl ? 'Foto 1' : 'Photo 1';
  String get photo2 => isNl ? 'Foto 2' : 'Photo 2';
  String get saved => isNl ? 'Opgeslagen' : 'Saved';
  String annotationsCount(int count) =>
      isNl ? 'Annotaties ($count)' : 'Annotations ($count)';
  String get annotatePhoto => isNl ? 'Annoteer foto' : 'Annotate photo';

  // ── Switchboard detail page ────────────────────────────────────────────────

  String get switchboard => isNl ? 'Verdeler' : 'Switchboard';
  String get switchboardName => isNl ? 'Naam/code' : 'Name/code';
  String get system => isNl ? 'Stelsel' : 'System';
  String get shortCircuit =>
      isNl ? 'Kortsluitstroom [A]' : 'Short-circuit current [A]';
  String get protection => isNl ? 'Voorbeveiliging' : 'Pre-protection';
  String get protectionClass =>
      isNl ? 'Beschermingsgraad omhulsel' : 'Protection class';
  String get crossSection =>
      isNl ? 'Leiding doorsnede [mm²]' : 'Cable cross-section [mm²]';
  String get length => isNl ? 'Leiding lengte [m]' : 'Cable length [m]';
  String get mainSwitchCurrent =>
      isNl ? 'Hoofdschakelaar stroom [A]' : 'Main switch current [A]';
  String get poles => isNl ? 'Aantal polen' : 'Number of poles';
  String get visualInspection =>
      isNl ? 'Visuele inspectie' : 'Visual inspection';
  String get item => isNl ? 'Item' : 'Item';
  String get yes => isNl ? 'Ja' : 'Yes';
  String get no => isNl ? 'Nee' : 'No';
  String get na => isNl ? 'N.v.t.' : 'N/A';
  String get measurements =>
      isNl ? 'Metingen en beproevingen' : 'Measurements and tests';

  // ── Solar installation detail page ─────────────────────────────────────────

  String get solarInstallation =>
      isNl ? 'Zonnestroom-installatie' : 'Solar Installation';
  String get panelSublocation =>
      isNl ? 'Deellocatie panelen' : 'Panel sub-location';
  String get numberOfPanels => isNl ? 'Aantal panelen' : 'Number of panels';
  String get numberOfInverters =>
      isNl ? 'Aantal omvormers' : 'Number of inverters';
  String get wattPeak => isNl ? 'WattPiek vermogen' : 'Watt peak power';
  String get constructionType => isNl ? 'Bouwvorm' : 'Installation type';
  String get photos => isNl ? "Foto's" : 'Photos';
  String get roofSetup1 => isNl ? 'Dakopstelling 1' : 'Roof setup 1';
  String get roofSetup2 => isNl ? 'Dakopstelling 2' : 'Roof setup 2';
  String get inverter1 => isNl ? 'Omvormer 1' : 'Inverter 1';
  String get inverter2 => isNl ? 'Omvormer 2' : 'Inverter 2';

  // ── Inspection details page ────────────────────────────────────────────────

  String get methode => isNl ? 'Methode' : 'Method';
  String get selectReportType =>
      isNl ? 'Selecteer rapport type' : 'Select report type';
  String get noReportTypeLinked =>
      isNl ? 'Geen rapport type geselecteerd' : 'No report type selected';
  String get fetchFromBag =>
      isNl ? 'Gegevens ophalen uit BAG' : 'Fetch data from BAG register';
  String get bagLookupInProgress => isNl
      ? 'Gegevens ophalen uit BAG-register...'
      : 'Fetching data from BAG register...';
  String get bagOverwriteTitle =>
      isNl ? 'Gebouwgegevens overschrijven' : 'Overwrite building data';
  String get bagOverwriteConfirm => isNl
      ? 'Er staan al gebouwgegevens ingevuld. Wilt u deze overschrijven met de gegevens uit het BAG-register?'
      : 'Building data has already been filled in. Do you want to overwrite it with data from the BAG register?';
  String get bagOverwriteButton => isNl ? 'Overschrijven' : 'Overwrite';
  String bagLookupSuccess(String address) =>
      isNl ? 'Gegevens opgehaald voor $address.' : 'Data fetched for $address.';
  String get gebruiksoppervlakte =>
      isNl ? 'Gebruiksoppervlakte (m²)' : 'Usable floor area (m²)';
  String get methodeVisueleInspectie =>
      isNl ? 'Visuele inspectie' : 'Visual inspection';
  String get methodeMetingen =>
      isNl ? 'Metingen en beproevingen' : 'Measurements and tests';
  String get methodeAanvullendOnderzoek =>
      isNl ? 'Aanvullend onderzoek' : 'Additional research';
  String get methodeCriteria => isNl ? 'Criteria' : 'Criteria';

  String get scope => isNl ? 'Omvang' : 'Scope';
  String get scopeDescription =>
      isNl ? 'Omschrijving van de inspectie' : 'Description of the inspection';
  String get notInspected => isNl
      ? 'Welke installatie(delen) zijn niet geïnspecteerd'
      : 'Which installation parts were not inspected';
  String get notInspectedReason =>
      isNl ? 'Reden voor het niet inspecteren' : 'Reason for not inspecting';
  String get assumptions => isNl ? 'Uitgangspunten' : 'Assumptions';
  String get inspectionReason =>
      isNl ? 'Reden van inspectie' : 'Reason for inspection';
  String get performedAccording => isNl
      ? 'De inspectie is uitgevoerd volgens'
      : 'The inspection was performed according to';
  String get testedAgainst => isNl
      ? 'Het elektrisch materieel is getoetst aan'
      : 'The electrical equipment was tested against';

  // ── Defect annotation screen ───────────────────────────────────────────────

  String annotationsPhotoTitle(int photoNumber) => isNl
      ? 'Annotaties - Foto $photoNumber'
      : 'Annotations - Photo $photoNumber';
  String get viewMode => isNl ? 'Bekijkmodus' : 'View mode';
  String get editMode => isNl ? 'Bewerkmodus' : 'Edit mode';
  String get dragToMove => isNl
      ? 'Sleep om te verplaatsen, gebruik hoeken om te vergroten/verkleinen'
      : 'Drag to move, use corners to resize';
  String get drawRectangle => isNl
      ? 'Teken een rechthoek op de foto om een gebrek te markeren'
      : 'Draw a rectangle on the photo to mark a defect';
  String get drawArrow => isNl
      ? 'Teken een pijl op de foto om een gebrek te markeren'
      : 'Draw an arrow on the photo to mark a defect';
  String get rectangleTool => isNl ? 'Rechthoek' : 'Rectangle';
  String get arrowTool => isNl ? 'Pijl' : 'Arrow';
  String get doubleArrowTool =>
      isNl ? 'Kop-staart pijl' : 'Double-headed arrow';
  String get noLabel => isNl ? 'Geen label' : 'No label';
  String get deleteAnnotation =>
      isNl ? 'Annotatie verwijderen' : 'Delete Annotation';
  String get deleteAnnotationConfirm => isNl
      ? 'Weet u zeker dat u deze annotatie wilt verwijderen?'
      : 'Are you sure you want to delete this annotation?';
  String annotationNumber(int number) =>
      isNl ? 'Annotatie $number' : 'Annotation $number';
  String get label => isNl ? 'Label' : 'Label';
  String get defectDescriptionHint =>
      isNl ? 'Beschrijving van het gebrek' : 'Description of the defect';
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) => ['nl', 'en'].contains(locale.languageCode);

  @override
  Future<AppLocalizations> load(Locale locale) async =>
      AppLocalizations(locale);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}
