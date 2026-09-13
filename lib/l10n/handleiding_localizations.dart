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

import 'app_localizations.dart';

/// Handleiding-teksten (quickstart) voor handleiding_page.dart.
extension HandleidingLocalizations on AppLocalizations {
  // ── ALGEMEEN ──────────────────────────────────────────────────────────────
  String get hdlTitel =>
      isNl ? 'Handleiding — Quickstart' : 'User Guide — Quick Start';

  String get hdlIntroTitel =>
      isNl ? 'Welkom bij MijnRapportage' : 'Welcome to MijnRapportage';

  String get hdlIntroTekst => isNl
      ? 'MijnRapportage begeleidt u door een elektrotechnische periodieke '
        'inspectie (NEN 3140) van titelpagina tot eindrapport: gegevens '
        'vastleggen, gebreken vastleggen, herstelwerk bijhouden en het '
        'rapport exporteren als PDF of XML.\n\n'
        'Deze quickstart laat de volgorde zien waarin u een inspectie '
        'doorloopt.'
      : 'MijnRapportage guides you through an electrical periodic inspection '
        '(NEN 3140) from title page to final report: recording data, logging '
        'defects, tracking repairs and exporting the report as PDF or XML.\n\n'
        'This quick start shows the order in which you work through an '
        'inspection.';

  // ── STAP 1: NIEUWE INSPECTIE ──────────────────────────────────────────────
  String get hdlStap1Titel =>
      isNl ? 'Stap 1 — Nieuwe inspectie aanmaken' : 'Step 1 — Create a New Inspection';

  String get hdlStap1Tekst => isNl
      ? 'Tik op het hoofdscherm op "Nieuwe Inspectie". De inspectie wordt '
        'direct lokaal opgeslagen en verschijnt in de lijst met status '
        '"Concept".\n\n'
        'Open vervolgens de Titelpagina en vul klant-, adres- en '
        'systeemgegevens in. Gebruik de knop "Ophalen uit BAG" bij de '
        'gebouwgegevens om adresgegevens automatisch aan te vullen vanuit '
        'de Basisregistratie Adressen en Gebouwen.\n\n'
        'Bestaande inspecties kunt u ook importeren via het upload-icoon '
        '(⬆️) op het hoofdscherm — bijvoorbeeld een ZIP die vanaf een ander '
        'apparaat is geëxporteerd.'
      : 'On the home screen, tap "New Inspection". The inspection is saved '
        'locally right away and appears in the list with status "Draft".\n\n'
        'Then open the Title Page and fill in customer, address and system '
        'details. Use the "Fetch from BAG" button in the building details to '
        'automatically fill in address data from the Dutch national address '
        'and building register.\n\n'
        'You can also import an existing inspection via the upload icon '
        '(⬆️) on the home screen — for example a ZIP exported from another '
        'device.';

  // ── STAP 2: ALGEMENE GEGEVENS & INLEIDING ─────────────────────────────────
  String get hdlStap2Titel =>
      isNl ? 'Stap 2 — Algemene gegevens & inleiding' : 'Step 2 — General Data & Introduction';

  String get hdlStap2Tekst => isNl
      ? 'Vul in "Algemene gegevens" de gegevens van de installatie en de '
        'inspecteur in.\n\n'
        'Ga daarna naar "Inleiding" voor de uitgangspunten van de inspectie: '
        'reden van de inspectie, gehanteerde methode en een toelichting die '
        'in het rapport wordt opgenomen.'
      : 'In "General Data", fill in the details of the installation and the '
        'inspector.\n\n'
        'Then go to "Introduction" for the assumptions behind the '
        'inspection: reason for the inspection, method used, and an '
        'explanation that is included in the report.';

  // ── STAP 3: INSPECTIEDETAILS ──────────────────────────────────────────────
  String get hdlStap3Titel =>
      isNl ? 'Stap 3 — Inspectiedetails vastleggen' : 'Step 3 — Recording Inspection Details';

  String get hdlStap3Tekst => isNl
      ? 'Open "Inspectiedetails" om de scope van de inspectie te bepalen:\n\n'
        '• Netaansluiting en gebouw — gebruiksoppervlakte, bouwjaar en '
        'gebouwhoogte (deels automatisch via BAG)\n'
        '• Onderzoeksomvang — kies de van toepassing zijnde normen, of geef '
        'aan welke onderdelen niet zijn geïnspecteerd (met reden)\n'
        '• Uitgangspunten — reden van inspectie, uitgevoerd volgens, '
        'getoetst aan\n'
        '• Methode — visuele inspectie, metingen en/of aanvullend onderzoek\n\n'
        'Deze gegevens bepalen mede hoe het eindrapport wordt opgebouwd.'
      : 'Open "Inspection Details" to determine the scope of the '
        'inspection:\n\n'
        '• Grid connection and building — usable floor area, year of '
        'construction and building height (partly automatic via BAG)\n'
        '• Scope of investigation — select the applicable standards, or '
        'indicate which parts were not inspected (with a reason)\n'
        '• Assumptions — reason for inspection, performed according to, '
        'tested against\n'
        '• Method — visual inspection, measurements and/or additional '
        'investigation\n\n'
        'This data partly determines how the final report is structured.';

  // ── STAP 4: INSTALLATIEONDERDELEN & GEBREKEN ──────────────────────────────
  String get hdlStap4Titel =>
      isNl ? 'Stap 4 — Installatieonderdelen inspecteren' : 'Step 4 — Inspecting Installation Parts';

  String get hdlStap4Tekst => isNl
      ? 'Doorloop vanuit het inspectiemenu de onderdelen die van toepassing '
        'zijn:\n\n'
        '• Schakel- en verdeelinrichtingen — voeg verdeelkasten toe met '
        'meetgegevens en foto\'s\n'
        '• Zonne-installaties — registreer omvormers en PV-installaties\n'
        '• Noodverlichting — inspecteer armaturen per ruimte\n'
        '• Tekening inspectie — markeer inspectiepunten direct op een '
        'plattegrond of schema\n'
        '• Meetgegevens — importeer meetresultaten uit een Excel-bestand\n\n'
        'Leg elk aangetroffen gebrek vast onder "Gebreken": omschrijving, '
        'categorie (bijv. NEN 3140-classificatie), foto\'s met annotaties '
        '(pijl of rechthoek) en een prioriteit voor herstel.'
      : 'From the inspection menu, work through the parts that apply:\n\n'
        '• Switchboards — add distribution boards with measurement data and '
        'photos\n'
        '• Solar installations — register inverters and PV installations\n'
        '• Emergency lighting — inspect luminaires per room\n'
        '• Drawing inspection — mark inspection points directly on a floor '
        'plan or diagram\n'
        '• Measurement data — import measurement results from an Excel '
        'file\n\n'
        'Log every defect found under "Defects": description, category '
        '(e.g. NEN 3140 classification), annotated photos (arrow or '
        'rectangle) and a repair priority.';

  // ── STAP 5: EINDBEOORDELING ────────────────────────────────────────────────
  String get hdlStap5Titel =>
      isNl ? 'Stap 5 — Eindbeoordeling' : 'Step 5 — Final Assessment';

  String get hdlStap5Tekst => isNl
      ? 'Stel in "Eindbeoordeling" de algehele conclusie van de inspectie '
        'op, gebaseerd op de vastgelegde gebreken en meetresultaten.\n\n'
        'Gebruik daarna, indien van toepassing, "Herstel" om per gebrek de '
        'herstelstatus bij te houden en "Herstelverklaring" om de '
        'uitgevoerde herstelwerkzaamheden te documenteren.'
      : 'In "Final Assessment", formulate the overall conclusion of the '
        'inspection, based on the logged defects and measurement results.\n\n'
        'Then, if applicable, use "Repair" to track the repair status per '
        'defect and "Repair Declaration" to document the repair work '
        'carried out.';

  // ── STAP 6: RAPPORT & DOWNLOAD ─────────────────────────────────────────────
  String get hdlStap6Titel =>
      isNl ? 'Stap 6 — Rapport genereren' : 'Step 6 — Generating the Report';

  String get hdlStap6Tekst => isNl
      ? 'Voeg eventueel aanvullende documenten toe via "Bijlagen" (PDF\'s '
        'die aan het rapport worden toegevoegd).\n\n'
        'Open "Download" om het rapport te genereren:\n'
        '• PDF — volledig inspectierapport, alleen de constateringen, of '
        'inclusief schakel- en verdeelinrichtingen\n'
        '• PDF Herstel — overzicht van uitgevoerde herstelwerkzaamheden\n'
        '• Export XML — voor verwerking in andere systemen\n\n'
        'Rond de inspectie af met de knop "Inspectie afronden" onderaan het '
        'inspectiemenu. Een afgeronde inspectie kunt u met "Heropenen" '
        'weer terugzetten naar Concept.'
      : 'Optionally add supporting documents via "Attachments" (PDFs that '
        'are added to the report).\n\n'
        'Open "Download" to generate the report:\n'
        '• PDF — full inspection report, findings only, or including '
        'switchboards\n'
        '• Repair PDF — overview of repair work carried out\n'
        '• Export XML — for processing in other systems\n\n'
        'Complete the inspection with the "Complete Inspection" button at '
        'the bottom of the inspection menu. A completed inspection can be '
        'set back to Draft with "Reopen".';

  // ── EXTRA: INSTELLINGEN ────────────────────────────────────────────────────
  String get hdlInstellingenTitel => isNl ? 'Extra — Instellingen' : 'Extra — Settings';

  String get hdlInstellingenTekst => isNl
      ? 'Via het tandwiel-icoon (⚙️) op het hoofdscherm stelt u zaken in die '
        'voor alle inspecties gelden:\n\n'
        '• Bedrijfsgegevens — naam, adres en logo voor op het rapport\n'
        '• Normen — de normen die u kunt selecteren bij onderzoeksomvang\n'
        '• Rapportteksten — standaardteksten en -sjablonen die in het '
        'rapport worden gebruikt\n'
        '• Rapport constateringen — herbruikbare, veelvoorkomende '
        'gebrekomschrijvingen'
      : 'Use the gear icon (⚙️) on the home screen to configure settings '
        'that apply to all inspections:\n\n'
        '• Company details — name, address and logo for the report\n'
        '• Standards — the standards you can select under scope of '
        'investigation\n'
        '• Report texts — standard texts and templates used in the report\n'
        '• Report findings — reusable, frequently occurring defect '
        'descriptions';

  // ── EXTRA: DELEN TUSSEN APPARATEN ─────────────────────────────────────────
  String get hdlDelenTitel =>
      isNl ? 'Extra — Delen tussen apparaten' : 'Extra — Sharing Between Devices';

  String get hdlDelenTekst => isNl
      ? 'Een inspectie is lokaal opgeslagen op het apparaat. Om verder te '
        'werken op een ander apparaat, of als backup:\n\n'
        '① Genereer op het bronapparaat een export (Download → geschikte '
        'export) of gebruik de ZIP-export van de inspectie\n'
        '② Zet het bestand over naar het andere apparaat\n'
        '③ Tik op het hoofdscherm op het upload-icoon (⬆️) en selecteer de '
        'ZIP — de inspectie wordt met alle gegevens en foto\'s toegevoegd '
        'aan de lijst'
      : 'An inspection is stored locally on the device. To continue working '
        'on another device, or as a backup:\n\n'
        '① On the source device, generate an export (Download → suitable '
        'export) or use the inspection\'s ZIP export\n'
        '② Transfer the file to the other device\n'
        '③ On the home screen, tap the upload icon (⬆️) and select the ZIP '
        '— the inspection is added to the list with all data and photos';

  // ── TIPS ──────────────────────────────────────────────────────────────────
  String get hdlTipsTitel => isNl ? 'Handige tips' : 'Useful Tips';

  String get hdlTip1 => isNl
      ? '🇳🇱/🇬🇧  Taal wisselen — tik op NL of EN in de menubalk van het '
        'hoofdscherm.'
      : '🇳🇱/🇬🇧  Switch language — tap NL or EN in the home screen\'s menu '
        'bar.';

  String get hdlTip2 => isNl
      ? '📷  Foto-annotaties — markeer gebreken op een foto met een pijl of '
        'rechthoek, inclusief label.'
      : '📷  Photo annotations — mark defects on a photo with an arrow or '
        'rectangle, including a label.';

  String get hdlTip3 => isNl
      ? '📍  BAG-koppeling — laat adres- en gebouwgegevens automatisch '
        'invullen in plaats van handmatig uitzoeken.'
      : '📍  BAG lookup — have address and building data filled in '
        'automatically instead of looking it up manually.';

  String get hdlTip4 => isNl
      ? '↩️  Heropenen — een afgeronde inspectie kan altijd terug naar '
        'Concept om nog iets aan te passen.'
      : '↩️  Reopen — a completed inspection can always be set back to '
        'Draft to make further changes.';

  String get hdlTip5 => isNl
      ? '📁  Meerdere rapportsoorten — genereer los een volledig rapport, '
        'alleen de constateringen, of een herstelrapport, afhankelijk van '
        'voor wie het bedoeld is.'
      : '📁  Multiple report types — generate a full report, findings only, '
        'or a repair report separately, depending on who it is for.';
}
