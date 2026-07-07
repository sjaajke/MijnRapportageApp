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

import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';
import 'package:intl/intl.dart';
import 'package:pdfx/pdfx.dart' as pdfx;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path/path.dart' as p;
import '../models/defect.dart';
import '../models/defect_annotation.dart';
import '../models/herstel.dart';
import '../models/measurement_instrument.dart';
import '../models/solar_inverter.dart';
import '../models/solar_string_measurement.dart';
import '../models/steekproef_item.dart';
import '../models/tekening_pin.dart';
import 'database_service.dart';
import 'photo_service.dart';

class PdfExportService {
  final _db = DatabaseService();

  pw.Widget _herstelQrCode(String? domain, String? token) {
    if (domain == null || domain.isEmpty || token == null || token.isEmpty) {
      return pw.SizedBox.shrink();
    }
    final url = Uri.https(domain, '/herstel', {'token': token});
    return pw.BarcodeWidget(
      data: url.toString(),
      barcode: pw.Barcode.qrCode(),
      drawText: false,
      width: 50,
      height: 50,
    );
  }

  Future<String> generatePdf(int inspectionId) async {
    final titlePage = await _db.getTitlePage(inspectionId);
    final companyDetails = await _db.getCompanyDetails();
    final generalData = await _db.getGeneralData(inspectionId);
    final details = await _db.getInspectionDetail(inspectionId);
    final switchboards = await _db.getSwitchboards(inspectionId);
    final solarInstallations = await _db.getSolarInstallations(inspectionId);

    // Pre-fetch inverters and string measurements (build callbacks are sync)
    final Map<int, List<SolarInverter>> invertersByInstallation = {};
    final Map<int, List<SolarStringMeasurement>> measurementsByInverter = {};
    for (final si in solarInstallations) {
      final inverters = await _db.getSolarInverters(si.id!);
      invertersByInstallation[si.id!] = inverters;
      for (final inv in inverters) {
        measurementsByInverter[inv.id!] =
            await _db.getSolarStringMeasurements(inv.id!);
      }
    }

    final defects = await _db.getDefects(inspectionId);
    final assessment = await _db.getFinalAssessment(inspectionId);
    final allInstruments = await _db.getAllMeasurementInstruments();

    final steekproefItems = await _db.getSteekproefItems(inspectionId);

    final tekeningen = await _db.getTekeningen(inspectionId);
    final Map<int, List<TekeningPin>> pinsByTekening = {};
    final Map<int, Uint8List> tekeningBytes = {};
    final Map<int, List<Uint8List>> tekeningPdfPages = {};
    for (final t in tekeningen) {
      if (t.id != null) {
        pinsByTekening[t.id!] = await _db.getTekeningPins(t.id!);
        if (t.bestandPad.isNotEmpty) {
          if (t.bestandType != 'pdf') {
            final f = File(t.bestandPad);
            if (f.existsSync()) {
              tekeningBytes[t.id!] = await f.readAsBytes();
            }
          } else {
            try {
              final doc = await pdfx.PdfDocument.openFile(t.bestandPad);
              final pages = <Uint8List>[];
              for (int i = 1; i <= doc.pagesCount; i++) {
                final page = await doc.getPage(i);
                final img = await page.render(
                  width: page.width * 2,
                  height: page.height * 2,
                  format: pdfx.PdfPageImageFormat.png,
                  backgroundColor: '#ffffff',
                );
                await page.close();
                if (img != null) pages.add(img.bytes);
              }
              await doc.close();
              if (pages.isNotEmpty) tekeningPdfPages[t.id!] = pages;
            } catch (_) {}
          }
        }
      }
    }

    final Map<int, List<DefectAnnotation>> annotationsByDefect = {};
    for (final d in defects) {
      if (d.hasAnnotations && d.id != null) {
        annotationsByDefect[d.id!] = await _db.getAllAnnotationsForDefect(d.id!);
      }
    }

    final Map<int, String> tokenByDefect = {};
    for (final d in defects) {
      if (d.id != null) {
        tokenByDefect[d.id!] = await _db.ensureHerstelToken(d.id!);
      }
    }

    final pdf = pw.Document();

    final headerLogoBytes = companyDetails?.logoPath != null &&
            File(companyDetails!.logoPath!).existsSync()
        ? File(companyDetails.logoPath!).readAsBytesSync()
        : null;

    // Title page — positioned layout matching the in-app preview
    final effectiveLogoPath =
        (titlePage?.logoTitelpaginaPath?.isNotEmpty == true)
            ? titlePage!.logoTitelpaginaPath
            : companyDetails?.logoTitelpaginaPath;

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: pw.EdgeInsets.zero,
        build: (context) {
          final pageW = PdfPageFormat.a4.width;
          final pageH = PdfPageFormat.a4.height;

          // Places a child at fractional center/size coordinates.
          pw.Widget block(
              double cx, double cy, double fw, double fh, pw.Widget child) {
            final bw = fw * pageW;
            final bh = fh * pageH;
            return pw.Positioned(
              left: cx * pageW - bw / 2,
              top: cy * pageH - bh / 2,
              child: pw.SizedBox(width: bw, height: bh, child: child),
            );
          }

          final tp = titlePage;

          return pw.Stack(
            children: [
              // ── Logo as full-page background ──────────────────────────
              if (effectiveLogoPath != null &&
                  File(effectiveLogoPath).existsSync())
                pw.Positioned(
                  left: 0, top: 0,
                  child: pw.SizedBox(
                    width: pageW, height: pageH,
                    child: pw.Image(
                      pw.MemoryImage(
                          File(effectiveLogoPath).readAsBytesSync()),
                      fit: pw.BoxFit.cover,
                    ),
                  ),
                ),

              // ── Photo ─────────────────────────────────────────────────
              if (tp?.photoPath != null && File(tp!.photoPath!).existsSync())
                block(tp.photoX, tp.photoY, tp.photoW, tp.photoH,
                  pw.Image(
                    pw.MemoryImage(File(tp.photoPath!).readAsBytesSync()),
                    fit: pw.BoxFit.cover,
                  ),
                ),

              // ── Title ─────────────────────────────────────────────────
              if (tp != null)
                block(tp.titleX, tp.titleY, tp.titleW, tp.titleH,
                  pw.Align(
                    alignment: pw.Alignment.center,
                    child: pw.Text(
                      tp.title,
                      style: pw.TextStyle(
                          fontSize: 22, fontWeight: pw.FontWeight.bold),
                      textAlign: pw.TextAlign.center,
                    ),
                  ),
                ),

              // ── Subtitle ──────────────────────────────────────────────
              if (tp != null && tp.subtitle.isNotEmpty)
                block(tp.subtitleX, tp.subtitleY, tp.subtitleW, tp.subtitleH,
                  pw.Align(
                    alignment: pw.Alignment.center,
                    child: pw.Text(
                      tp.subtitle,
                      style: const pw.TextStyle(fontSize: 14),
                      textAlign: pw.TextAlign.center,
                    ),
                  ),
                ),

              // ── Date ──────────────────────────────────────────────────
              if (tp != null && tp.inspectionDate.isNotEmpty)
                block(tp.dateX, tp.dateY, tp.dateW, tp.dateH,
                  pw.Text(
                    tp.inspectionDateEnd.isNotEmpty
                        ? 'Datum: ${tp.inspectionDate} t/m ${tp.inspectionDateEnd}'
                        : 'Datum: ${tp.inspectionDate}',
                    style: pw.TextStyle(
                        fontSize: 10,
                        color: tp.dateColorWhite ? PdfColors.white : PdfColors.black),
                  ),
                ),

              // ── Identification code ────────────────────────────────────
              if (tp != null && tp.identificationCode.isNotEmpty)
                block(tp.codeX, tp.codeY, tp.codeW, tp.codeH,
                  pw.Text('Identificatiecode: ${tp.identificationCode}',
                    style: pw.TextStyle(
                        fontSize: 10,
                        color: tp.codeColorWhite ? PdfColors.white : PdfColors.black),
                  ),
                ),

              // ── Project number ────────────────────────────────────────
              if (tp != null && tp.projectNumber.isNotEmpty)
                block(tp.projectX, tp.projectY, tp.projectW, tp.projectH,
                  pw.Text('Projectnummer: ${tp.projectNumber}',
                    style: pw.TextStyle(
                        fontSize: 10,
                        color: tp.projectColorWhite ? PdfColors.white : PdfColors.black),
                  ),
                ),

              // ── Inspectieadres Naam ───────────────────────────────────
              if (tp != null && generalData != null &&
                  generalData.inspectionAddressName.isNotEmpty)
                block(tp.addressNameX, tp.addressNameY, tp.addressNameW, tp.addressNameH,
                  pw.Align(
                    alignment: pw.Alignment.center,
                    child: pw.Text(
                      generalData.inspectionAddressName,
                      style: const pw.TextStyle(fontSize: 25, color: PdfColors.white),
                      textAlign: pw.TextAlign.center,
                    ),
                  ),
                ),

              // ── SCIOS logo ────────────────────────────────────────────
              if (tp != null &&
                  tp.showSciosLogo &&
                  companyDetails?.logoSciosPath != null &&
                  File(companyDetails!.logoSciosPath!).existsSync())
                block(tp.logoX, tp.logoY, tp.logoW, tp.logoH,
                  pw.Image(
                    pw.MemoryImage(
                        File(companyDetails.logoSciosPath!).readAsBytesSync()),
                    fit: pw.BoxFit.contain,
                  ),
                ),
            ],
          );
        },
      ),
    );

    // Inleiding
    if (details != null && details.inleiding.isNotEmpty) {
      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(40),
          header: (context) => _logoHeader(headerLogoBytes),
          build: (context) => [
            _sectionTitle('Inleiding'),
            pw.SizedBox(height: 10),
            _textBlock(details.inleiding),
          ],
        ),
      );
    }

    // General Data page
    if (generalData != null) {
      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(40),
          header: (context) => _logoHeader(headerLogoBytes),
          build: (context) => [
            _sectionTitle('Algemene Gegevens'),
            pw.SizedBox(height: 10),
            if (generalData.clientCompany.isNotEmpty ||
                generalData.clientAddress.isNotEmpty ||
                generalData.clientPostalCity.isNotEmpty ||
                generalData.clientContact.isNotEmpty ||
                generalData.clientPhone.isNotEmpty) ...[
              _subTitle('Opdrachtgever'),
              if (generalData.clientCompany.isNotEmpty)
                _labelValue('Naam Bedrijf', generalData.clientCompany),
              if (generalData.clientAddress.isNotEmpty)
                _labelValue('Adres', generalData.clientAddress),
              if (generalData.clientPostalCity.isNotEmpty)
                _labelValue('Postcode Plaats', generalData.clientPostalCity),
              if (generalData.clientContact.isNotEmpty)
                _labelValue('Contactpersoon', generalData.clientContact),
              if (generalData.clientPhone.isNotEmpty)
                _labelValue('Telefoonnummer', generalData.clientPhone),
              pw.SizedBox(height: 10),
            ],
            if (generalData.installationResponsibleName.isNotEmpty ||
                generalData.installationResponsiblePhone.isNotEmpty) ...[
              _subTitle('Installatieverantwoordelijke'),
              if (generalData.installationResponsibleName.isNotEmpty)
                _labelValue('Installatieverantwoordelijke',
                    generalData.installationResponsibleName),
              if (generalData.installationResponsiblePhone.isNotEmpty)
                _labelValue('Telefoonnummer',
                    generalData.installationResponsiblePhone),
              pw.SizedBox(height: 10),
            ],
            if (generalData.inspectionAddressName.isNotEmpty ||
                generalData.inspectionAddressStreet.isNotEmpty ||
                generalData.inspectionAddressPostalCity.isNotEmpty ||
                generalData.inspectionAddressContact.isNotEmpty ||
                generalData.inspectionAddressPhone.isNotEmpty) ...[
              _subTitle('Inspectieadres'),
              if (generalData.inspectionAddressName.isNotEmpty)
                _labelValue('Naam', generalData.inspectionAddressName),
              if (generalData.inspectionAddressStreet.isNotEmpty)
                _labelValue('Adres', generalData.inspectionAddressStreet),
              if (generalData.inspectionAddressPostalCity.isNotEmpty)
                _labelValue('Postcode Plaats',
                    generalData.inspectionAddressPostalCity),
              if (generalData.inspectionAddressContact.isNotEmpty)
                _labelValue(
                    'Contactpersoon', generalData.inspectionAddressContact),
              if (generalData.inspectionAddressPhone.isNotEmpty)
                _labelValue(
                    'Telefoonnummer', generalData.inspectionAddressPhone),
              pw.SizedBox(height: 10),
            ],
            if (generalData.inspectorCompany.isNotEmpty ||
                generalData.inspectorAddress.isNotEmpty ||
                generalData.inspectorPostalCity.isNotEmpty ||
                generalData.inspectorPhone.isNotEmpty ||
                generalData.inspectorEmail.isNotEmpty ||
                generalData.inspectorContact.isNotEmpty ||
                generalData.inspectors.isNotEmpty) ...[
              _subTitle('Inspectiebedrijf'),
              if (generalData.inspectorCompany.isNotEmpty)
                _labelValue('Naam bedrijf', generalData.inspectorCompany),
              if (generalData.inspectorAddress.isNotEmpty)
                _labelValue('Adres', generalData.inspectorAddress),
              if (generalData.inspectorPostalCity.isNotEmpty)
                _labelValue('Postcode Plaats', generalData.inspectorPostalCity),
              if (generalData.inspectorPhone.isNotEmpty)
                _labelValue('Telefoon', generalData.inspectorPhone),
              if (generalData.inspectorEmail.isNotEmpty)
                _labelValue('Mail', generalData.inspectorEmail),
              if (generalData.inspectorContact.isNotEmpty)
                _labelValue('Contactpersoon', generalData.inspectorContact),
              if (generalData.inspectors.isNotEmpty)
                _labelValue('Inspecteur(s)', generalData.inspectors),
            ],
            if (allInstruments.isNotEmpty) ...[
              pw.SizedBox(height: 12),
              _subTitle('Meetinstrumenten'),
              pw.SizedBox(height: 4),
              _instrumentsTable(allInstruments),
            ],
          ],
        ),
      );
    }

    // Inspection Details
    if (details != null) {
      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(40),
          header: (context) => _logoHeader(headerLogoBytes),
          build: (context) => [
            _sectionTitle('Inspectie Details'),
            pw.SizedBox(height: 10),
            if (details.aardingsstelsel.isNotEmpty ||
                details.netaansluiting.isNotEmpty ||
                details.hoofdaansluiting.isNotEmpty ||
                details.gebouwfunctie.isNotEmpty ||
                details.bijzondereInstallatie.isNotEmpty) ...[
              _subTitle('Netaansluiting'),
              if (details.aardingsstelsel.isNotEmpty)
                _labelValue('Aardingsstelsel', details.aardingsstelsel),
              if (details.netaansluiting.isNotEmpty)
                _labelValue('Netaansluiting', details.netaansluiting),
              if (details.hoofdaansluiting.isNotEmpty)
                _labelValue(
                    'Hoofdaansluiting', '${details.hoofdaansluiting} A'),
              if (details.gebouwfunctie.isNotEmpty)
                _labelValue('Gebouwfunctie volgens Bbl',
                    details.gebouwfunctie.split(',').join(', ')),
              if (details.bijzondereInstallatie.isNotEmpty)
                _labelMultiValue('Bijzondere installatie of ruimte',
                    details.bijzondereInstallatie.split(',')),
              pw.SizedBox(height: 10),
            ],
            if (details.scopeDescription.isNotEmpty ||
                details.notInspectedParts.isNotEmpty ||
                details.notInspectedReason.isNotEmpty ||
                steekproefItems.isNotEmpty) ...[
              _subTitle('Omvang'),
              if (details.scopeDescription.isNotEmpty)
                _labelValue(
                    'Omschrijving van de inspectie', details.scopeDescription),
              if (details.notInspectedParts.isNotEmpty)
                _labelValue(
                    'Niet geïnspecteerde delen', details.notInspectedParts),
              if (details.notInspectedReason.isNotEmpty)
                _labelValue(
                    'Reden niet inspecteren', details.notInspectedReason),
              if (steekproefItems.isNotEmpty) ...[
                pw.SizedBox(height: 10),
                _subTitle('Steekproef'),
                pw.SizedBox(height: 4),
                _steekproefTable(steekproefItems),
              ],
              pw.SizedBox(height: 10),
            ],
            if (details.inspectionReason.isNotEmpty ||
                details.performedAccordingTo.isNotEmpty ||
                details.testedAgainst.isNotEmpty ||
                details.inleidingToelichting.isNotEmpty) ...[
              _subTitle('Uitgangspunten'),
              if (details.inspectionReason.isNotEmpty)
                _labelValue('Reden van inspectie', details.inspectionReason),
              if (details.performedAccordingTo.isNotEmpty)
                _labelValue(
                    'Uitgevoerd volgens', details.performedAccordingTo),
              if (details.testedAgainst.isNotEmpty)
                _labelValue('Getoetst aan', details.testedAgainst),
              if (details.inleidingToelichting.isNotEmpty) ...[
                pw.SizedBox(height: 4),
                _labelValue(
                    'Toelichting inleiding', details.inleidingToelichting),
              ],
              pw.SizedBox(height: 10),
            ],
            if (details.methodeVisueleInspectie.isNotEmpty ||
                details.methodeMetingen.isNotEmpty ||
                details.methodeAanvullendOnderzoek.isNotEmpty ||
                details.methodeCriteria.isNotEmpty) ...[
              _subTitle('Methode'),
              if (details.methodeVisueleInspectie.isNotEmpty) ...[
                _labelValue('Visuele inspectie', ''),
                _textBlock(details.methodeVisueleInspectie),
                pw.SizedBox(height: 6),
              ],
              if (details.methodeMetingen.isNotEmpty) ...[
                _labelValue('Metingen en beproevingen', ''),
                _textBlock(details.methodeMetingen),
                pw.SizedBox(height: 6),
              ],
              if (details.methodeAanvullendOnderzoek.isNotEmpty) ...[
                _labelValue('Aanvullend onderzoek', ''),
                _textBlock(details.methodeAanvullendOnderzoek),
                pw.SizedBox(height: 6),
              ],
              if (details.methodeCriteria.isNotEmpty) ...[
                _subTitle('Afkeuringscriteria'),
                _textBlock(details.methodeCriteria),
              ],
            ],
          ],
        ),
      );
    }

    // Eindbeoordeling
    if (assessment != null) {
      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(40),
          header: (context) => _logoHeader(headerLogoBytes),
          build: (context) => [
            _sectionTitle('Eindbeoordeling'),
            pw.SizedBox(height: 10),
            if (assessment.eindbeoordeling.isNotEmpty) ...[
              _subTitle('Beoordeling'),
              _textBlock(assessment.eindbeoordeling),
              pw.SizedBox(height: 10),
            ],
            _constateringenTabel(defects.map((d) => d.classification).toList()),
            pw.SizedBox(height: 10),
            if (assessment.volgendInspectie.isNotEmpty)
              _labelValue('Volgende inspectie', assessment.volgendInspectie),
            pw.SizedBox(height: 16),
            _subTitle('Ondertekening'),
            pw.SizedBox(height: 8),
            pw.Row(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Expanded(child: _signatoryBlock(
                  'Ondertekenaar 1',
                  assessment.naam1,
                  assessment.functie1,
                  assessment.datum1,
                  assessment.handtekening1,
                )),
                pw.SizedBox(width: 20),
                pw.Expanded(child: _signatoryBlock(
                  'Ondertekenaar 2',
                  assessment.naam2,
                  assessment.functie2,
                  assessment.datum2,
                  assessment.handtekening2,
                )),
              ],
            ),
          ],
        ),
      );
    }

    // Switchboards
    for (final sb in switchboards) {
      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(40),
          build: (context) {
            return pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                _logoHeader(headerLogoBytes),
                pw.SizedBox(height: 4),
                _sectionTitle('Verdeler: ${sb.name}'),
                pw.SizedBox(height: 10),
                if (sb.locationFull.isNotEmpty)
                  _labelValue('Locatie', sb.locationFull),
                if (sb.system.isNotEmpty)
                  _labelValue('Stelsel', sb.system),
                if (sb.shortCircuitCurrent != null)
                  _labelValue('Kortsluitstroom',
                      '${sb.shortCircuitCurrent} A'),
                if (sb.protection.isNotEmpty)
                  _labelValue('Voorbeveiliging', sb.protection),
                if (sb.protectionClass.isNotEmpty)
                  _labelValue('Beschermingsgraad omhulsel', sb.protectionClass),
                if (sb.cableCrossSection != null)
                  _labelValue('Doorsnede', '${sb.cableCrossSection} mm²'),
                if (sb.cableLength != null)
                  _labelValue('Lengte', '${sb.cableLength} m'),
                if (sb.mainSwitchCurrent != null || sb.mainSwitchPoles != null)
                  _labelValue('Hoofdschakelaar',
                      '${sb.mainSwitchCurrent ?? '-'} A, ${sb.mainSwitchPoles ?? '-'} polig'),
                pw.SizedBox(height: 10),
                if (sb.photo1Path != null && File(sb.photo1Path!).existsSync() ||
                    sb.photo2Path != null && File(sb.photo2Path!).existsSync()) ...[
                  pw.Row(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      if (sb.photo1Path != null && File(sb.photo1Path!).existsSync())
                        pw.Expanded(
                          child: pw.SizedBox(
                            height: 130,
                            child: pw.Image(
                              pw.MemoryImage(File(sb.photo1Path!).readAsBytesSync()),
                              fit: pw.BoxFit.contain,
                            ),
                          ),
                        ),
                      if (sb.photo1Path != null && File(sb.photo1Path!).existsSync() &&
                          sb.photo2Path != null && File(sb.photo2Path!).existsSync())
                        pw.SizedBox(width: 8),
                      if (sb.photo2Path != null && File(sb.photo2Path!).existsSync())
                        pw.Expanded(
                          child: pw.SizedBox(
                            height: 130,
                            child: pw.Image(
                              pw.MemoryImage(File(sb.photo2Path!).readAsBytesSync()),
                              fit: pw.BoxFit.contain,
                            ),
                          ),
                        ),
                    ],
                  ),
                  pw.SizedBox(height: 10),
                ],
                if (sb.visualInspection.isNotEmpty) ...[
                  _subTitle('Visuele inspectie'),
                  ...sb.visualInspection.entries.map(
                    (e) => _checklistRow(e.key, e.value),
                  ),
                  pw.SizedBox(height: 10),
                ],
                if (sb.measurements.isNotEmpty) ...[
                  _subTitle('Metingen en beproevingen'),
                  ...sb.measurements.entries.map(
                    (e) => _checklistRow(e.key, e.value),
                  ),
                ],
              ],
            );
          },
        ),
      );
    }

    // Solar Installations
    for (final si in solarInstallations) {
      final inverters = invertersByInstallation[si.id!] ?? [];

      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(40),
          header: (context) => _logoHeader(headerLogoBytes),
          build: (context) {
            final widgets = <pw.Widget>[
              _sectionTitle('Zonnestroom-installatie'),
              pw.SizedBox(height: 10),
              _labelValue('Locatie', si.location),
              _labelValue('Deellocatie panelen', si.panelSublocation),
              _labelValue('Aantal panelen', si.panelCount?.toString() ?? '-'),
              _labelValue('Aantal omvormers', si.inverterCount?.toString() ?? '-'),
              _labelValue('WattPiek vermogen',
                  si.wattPeak != null ? '${si.wattPeak} Wp' : '-'),
              _labelValue('Bouwvorm', si.constructionType),
            ];

            // Opstelling
            if (_hasValue(si.buildingType) || _hasValue(si.roofType) ||
                _hasValue(si.orientation) || _hasValue(si.tiltAngle) ||
                _hasValue(si.frame)) {
              widgets.addAll([
                pw.SizedBox(height: 10),
                _subTitle('Opstelling'),
                if (_hasValue(si.buildingType))
                  _labelValue('Type gebouw', si.buildingType!),
                if (_hasValue(si.roofType))
                  _labelValue('Type dak', si.roofType!),
                if (_hasValue(si.orientation))
                  _labelValue('Oriëntatie', si.orientation!),
                if (_hasValue(si.tiltAngle))
                  _labelValue('Hellingshoek (°)', si.tiltAngle!),
                if (_hasValue(si.frame)) _labelValue('Frame', si.frame!),
              ]);
            }

            // Weersomstandigheden
            if (_hasValue(si.cloudCover) || _hasValue(si.temperature)) {
              widgets.addAll([
                pw.SizedBox(height: 10),
                _subTitle('Weersomstandigheden'),
                if (_hasValue(si.cloudCover))
                  _labelValue('Bewolking', si.cloudCover!),
                if (_hasValue(si.temperature))
                  _labelValue('Temperatuur', si.temperature!),
              ]);
            }

            // Documentatie
            if (_hasValue(si.layoutPlan) || _hasValue(si.ballastPlan) ||
                _hasValue(si.cablePlan) || _hasValue(si.constructionDeclaration) ||
                _hasValue(si.installationData)) {
              widgets.addAll([
                pw.SizedBox(height: 10),
                _subTitle('Documentatie'),
                if (_hasValue(si.layoutPlan))
                  _labelValue('Legplan panelen', si.layoutPlan!),
                if (_hasValue(si.ballastPlan))
                  _labelValue('Ballastplan', si.ballastPlan!),
                if (_hasValue(si.cablePlan))
                  _labelValue('Kabelplan (>1 streng)', si.cablePlan!),
                if (_hasValue(si.constructionDeclaration))
                  _labelValue('Verklaring constructiebureau m.b.t. dakconstructie',
                      si.constructionDeclaration!),
                if (_hasValue(si.installationData))
                  _labelValue('Installatiegegevens', si.installationData!),
              ]);
            }

            // Solar installation photos (roof + inverter)
            final roofPhotos = [si.photoRoof1Path, si.photoRoof2Path]
                .where((p) => p != null && File(p).existsSync())
                .cast<String>()
                .toList();
            final invPhotos = [si.photoInverter1Path, si.photoInverter2Path]
                .where((p) => p != null && File(p).existsSync())
                .cast<String>()
                .toList();
            final allPhotos = [...roofPhotos, ...invPhotos];
            if (allPhotos.isNotEmpty) {
              widgets.add(pw.SizedBox(height: 10));
              widgets.add(_photoRow(allPhotos));
            }

            // Inverters
            for (final inv in inverters) {
              final measurements = measurementsByInverter[inv.id!] ?? [];
              widgets.addAll([
                pw.SizedBox(height: 16),
                pw.Divider(),
                pw.SizedBox(height: 4),
                _subTitle(
                  'Omvormer: ${inv.displayName}'
                  '${inv.locationFull.isNotEmpty ? "  –  ${inv.locationFull}" : ""}',
                ),
                pw.SizedBox(height: 6),
              ]);

              // Inverter photo alongside details
              final invPhoto = inv.photoPath != null &&
                      File(inv.photoPath!).existsSync()
                  ? pw.MemoryImage(File(inv.photoPath!).readAsBytesSync())
                  : null;

              final invDetails = <pw.Widget>[
                _labelValue('Merk', inv.inverterBrand),
                _labelValue('Type', inv.inverterType),
                if (inv.inverterSerial.isNotEmpty)
                  _labelValue('Serienummer', inv.inverterSerial),
                if (inv.inverterIp.isNotEmpty)
                  _labelValue('IP', inv.inverterIp),
                if (inv.inverterIsolationClass.isNotEmpty)
                  _labelValue('Isolatieklasse', inv.inverterIsolationClass),
                if (inv.inverterMaxVdc.isNotEmpty)
                  _labelValue('Max VDC', inv.inverterMaxVdc),
                if (inv.inverterMaxIdc.isNotEmpty)
                  _labelValue('Max IDC', inv.inverterMaxIdc),
                if (inv.inverterIscPv.isNotEmpty)
                  _labelValue('Isc pv', inv.inverterIscPv),
                if (inv.inverterInom.isNotEmpty)
                  _labelValue('Inom', inv.inverterInom),
              ];

              if (invPhoto != null) {
                widgets.add(
                  pw.Row(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Expanded(
                        child: pw.Column(
                          crossAxisAlignment: pw.CrossAxisAlignment.start,
                          children: invDetails,
                        ),
                      ),
                      pw.SizedBox(width: 12),
                      pw.SizedBox(
                        width: 130,
                        height: 110,
                        child: pw.Image(invPhoto, fit: pw.BoxFit.contain),
                      ),
                    ],
                  ),
                );
              } else {
                widgets.addAll(invDetails);
              }

              // Paneel
              if (inv.panelBrand.isNotEmpty || inv.panelType.isNotEmpty ||
                  inv.panelShortCircuitCurrent.isNotEmpty ||
                  inv.panelOpenCircuitVoltage.isNotEmpty) {
                widgets.addAll([
                  pw.SizedBox(height: 8),
                  _subTitle('Paneel'),
                  if (inv.panelBrand.isNotEmpty)
                    _labelValue('Merk', inv.panelBrand),
                  if (inv.panelType.isNotEmpty)
                    _labelValue('Type', inv.panelType),
                  if (inv.panelShortCircuitCurrent.isNotEmpty)
                    _labelValue('Short-circuit current',
                        inv.panelShortCircuitCurrent),
                  if (inv.panelOpenCircuitVoltage.isNotEmpty)
                    _labelValue('Open-circuit voltage',
                        inv.panelOpenCircuitVoltage),
                ]);
              }

              // Beveiliging / Leiding
              if (inv.protection.isNotEmpty || inv.cable.isNotEmpty) {
                widgets.addAll([
                  pw.SizedBox(height: 8),
                  if (inv.protection.isNotEmpty)
                    _labelValue('Beveiliging', inv.protection),
                  if (inv.cable.isNotEmpty) _labelValue('Leiding', inv.cable),
                ]);
              }

              // Strengmetingen
              if (measurements.isNotEmpty) {
                widgets.addAll([
                  pw.SizedBox(height: 8),
                  _subTitle('Strengmeting(en)'),
                  pw.SizedBox(height: 4),
                  _stringMeasurementsTable(measurements),
                ]);
              }
            }

            return widgets;
          },
        ),
      );
    }

    // Tekening Inspectie
    for (final tekening in tekeningen) {
      final pins = pinsByTekening[tekening.id!] ?? [];
      final bytes = tekeningBytes[tekening.id!];
      final pdfPages = tekeningPdfPages[tekening.id!] ?? [];

      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(40),
          header: (context) => _logoHeader(headerLogoBytes),
          build: (context) {
            const imgW = 515.0;
            const imgH = 360.0;

            final widgets = <pw.Widget>[
              _sectionTitle('Tekening Inspectie'),
              pw.SizedBox(height: 4),
              if (tekening.naam.isNotEmpty) _subTitle(tekening.naam),
              pw.SizedBox(height: 8),
            ];

            if (bytes != null) {
              // Image tekening met pin-overlay
              widgets.add(
                pw.Stack(
                  children: [
                    pw.Image(
                      pw.MemoryImage(bytes),
                      width: imgW,
                      height: imgH,
                      fit: pw.BoxFit.fill,
                    ),
                    ...pins.map((pin) {
                      const r = 8.0;
                      return pw.Positioned(
                        left: pin.x * imgW - r,
                        top: pin.y * imgH - r,
                        child: pw.Container(
                          width: r * 2,
                          height: r * 2,
                          decoration: pw.BoxDecoration(
                            color: _pdfColorForPin(pin.kleur),
                            shape: pw.BoxShape.circle,
                          ),
                          child: pw.Center(
                            child: pw.Text(
                              '${pin.volgnummer}',
                              style: pw.TextStyle(
                                fontSize: 6,
                                color: PdfColors.white,
                                fontWeight: pw.FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      );
                    }),
                  ],
                ),
              );
            } else if (pdfPages.isNotEmpty) {
              // PDF tekening — gerenderde pagina's als afbeelding
              for (int pi = 0; pi < pdfPages.length; pi++) {
                final pageBytes = pdfPages[pi];
                // Pins alleen op de eerste pagina (waar ze geplaatst zijn)
                final pagePins = pi == 0 ? pins : <TekeningPin>[];
                widgets.add(
                  pw.Stack(
                    children: [
                      pw.Image(
                        pw.MemoryImage(pageBytes),
                        width: imgW,
                        height: imgH,
                        fit: pw.BoxFit.fill,
                      ),
                      ...pagePins.map((pin) {
                        const r = 8.0;
                        return pw.Positioned(
                          left: pin.x * imgW - r,
                          top: pin.y * imgH - r,
                          child: pw.Container(
                            width: r * 2,
                            height: r * 2,
                            decoration: pw.BoxDecoration(
                              color: _pdfColorForPin(pin.kleur),
                              shape: pw.BoxShape.circle,
                            ),
                            child: pw.Center(
                              child: pw.Text(
                                '${pin.volgnummer}',
                                style: pw.TextStyle(
                                  fontSize: 6,
                                  color: PdfColors.white,
                                  fontWeight: pw.FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        );
                      }),
                    ],
                  ),
                );
                widgets.add(pw.SizedBox(height: 6));
              }
            }

            if (pins.isNotEmpty) {
              widgets.addAll([
                pw.SizedBox(height: 12),
                _subTitle('Legenda'),
                pw.SizedBox(height: 4),
                _pinsLegendTable(pins),
              ]);
            }

            return widgets;
          },
        ),
      );
    }

    // Defects — twee gebreken per pagina
    final defectsWithPhotos = defects
        .where((d) =>
            d.id != null &&
            ((d.photo1Path != null && File(d.photo1Path!).existsSync()) ||
                (d.photo2Path != null && File(d.photo2Path!).existsSync())))
        .toList();

    final herstelDomain = companyDetails?.herstelWebDomain;

    pw.Widget defectBlock(d, List<DefectAnnotation> annotations, String? token) {
      final photo1Exists = d.photo1Path != null && File(d.photo1Path!).existsSync();
      final photo2Exists = d.photo2Path != null && File(d.photo2Path!).existsSync();
      return pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Expanded(child: _subTitle('${d.classification} — ${d.locationFull}')),
              if (token != null) pw.SizedBox(width: 8),
              _herstelQrCode(herstelDomain, token),
            ],
          ),
          if (d.description.isNotEmpty) pw.SizedBox(height: 2),
          if (d.description.isNotEmpty) _textBlock(d.description),
          pw.SizedBox(height: 6),
          pw.Expanded(
            child: pw.Row(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                if (photo1Exists)
                  pw.Expanded(
                    child: _defectPhoto(
                      d.photo1Path!,
                      annotations.where((a) => a.photoNumber == 1).toList(),
                    ),
                  ),
                if (photo1Exists && photo2Exists) pw.SizedBox(width: 8),
                if (photo2Exists)
                  pw.Expanded(
                    child: _defectPhoto(
                      d.photo2Path!,
                      annotations.where((a) => a.photoNumber == 2).toList(),
                    ),
                  ),
              ],
            ),
          ),
        ],
      );
    }

    for (int i = 0; i < defectsWithPhotos.length; i += 2) {
      final d1 = defectsWithPhotos[i];
      final d2 = i + 1 < defectsWithPhotos.length ? defectsWithPhotos[i + 1] : null;
      final ann1 = annotationsByDefect[d1.id!] ?? [];
      final ann2 = d2 != null ? (annotationsByDefect[d2.id!] ?? <DefectAnnotation>[]) : <DefectAnnotation>[];

      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(40),
          build: (context) {
            return pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                _logoHeader(headerLogoBytes),
                pw.SizedBox(height: 4),
                if (i == 0) _sectionTitle('Constatering(en)'),
                if (i == 0) pw.SizedBox(height: 8),
                pw.Expanded(child: defectBlock(d1, ann1, tokenByDefect[d1.id!])),
                if (d2 != null) pw.Divider(color: PdfColors.grey400),
                if (d2 != null) pw.Expanded(child: defectBlock(d2, ann2, tokenByDefect[d2.id!])),
              ],
            );
          },
        ),
      );
    }

    // Save PDF
    final dir = await PhotoService().getExportsDir();
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final filePath = p.join(dir, '${inspectionId}_$timestamp.pdf');
    final file = File(filePath);
    await file.writeAsBytes(await pdf.save());

    await _db.updateInspectionStatus(inspectionId, 'exported');

    return filePath;
  }

  Future<String> generateConstateriungPdf(int inspectionId) async {
    final defects = await _db.getDefects(inspectionId);
    final companyDetails = await _db.getCompanyDetails();

    final Map<int, List<DefectAnnotation>> annotationsByDefect = {};
    for (final d in defects) {
      if (d.hasAnnotations && d.id != null) {
        annotationsByDefect[d.id!] =
            await _db.getAllAnnotationsForDefect(d.id!);
      }
    }

    final Map<int, String> tokenByDefect = {};
    for (final d in defects) {
      if (d.id != null) {
        tokenByDefect[d.id!] = await _db.ensureHerstelToken(d.id!);
      }
    }

    final pdf = pw.Document();

    if (defects.isNotEmpty) {
      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(40),
          build: (context) => [
            _sectionTitle('Constateringen'),
            pw.SizedBox(height: 10),
            _defectsTable(defects),
          ],
        ),
      );
    }

    _addDefectPhotoPages(pdf, defects, annotationsByDefect, null, tokenByDefect,
        companyDetails?.herstelWebDomain);

    final dir = await PhotoService().getExportsDir();
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final filePath =
        p.join(dir, '${inspectionId}_constatering_$timestamp.pdf');
    await File(filePath).writeAsBytes(await pdf.save());
    await _db.updateInspectionStatus(inspectionId, 'exported');
    return filePath;
  }

  Future<String> generateHerstelPdf(int inspectionId) async {
    final defects = await _db.getDefects(inspectionId);

    final Map<int, Herstel?> herstelByDefect = {};
    final Map<int, List<DefectAnnotation>> annotationsByDefect = {};
    for (final d in defects) {
      if (d.id != null) {
        herstelByDefect[d.id!] = await _db.getHerstel(d.id!);
        if (d.hasAnnotations) {
          annotationsByDefect[d.id!] = await _db.getAllAnnotationsForDefect(d.id!);
        }
      }
    }

    final pdf = pw.Document();

    // Constateringen overzichtstabel
    if (defects.isNotEmpty) {
      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(40),
          build: (context) => [
            _sectionTitle('Constateringen en Herstel'),
            pw.SizedBox(height: 10),
            _herstelOverzichtTable(defects, herstelByDefect),
          ],
        ),
      );
    }

    // Per constatering: details + herstelgegevens + foto's
    for (final d in defects) {
      if (d.id == null) continue;
      final herstel = herstelByDefect[d.id!];
      final annotations = annotationsByDefect[d.id!] ?? [];

      final photo1Exists = d.photo1Path != null && File(d.photo1Path!).existsSync();
      final photo2Exists = d.photo2Path != null && File(d.photo2Path!).existsSync();
      final hPhoto1Exists = herstel?.photo1Path != null && File(herstel!.photo1Path!).existsSync();
      final hPhoto2Exists = herstel?.photo2Path != null && File(herstel!.photo2Path!).existsSync();

      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(40),
          build: (context) {
            final widgets = <pw.Widget>[
              _subTitle('${d.classification} — ${d.locationFull}'),
              pw.SizedBox(height: 4),
              if (d.description.isNotEmpty) _textBlock(d.description),
              if (d.toelichting.isNotEmpty) ...[
                pw.SizedBox(height: 4),
                _labelValue('Toelichting', d.toelichting),
              ],
            ];

            if (photo1Exists || photo2Exists) {
              widgets.add(pw.SizedBox(height: 8));
              widgets.add(
                pw.SizedBox(
                  height: 180,
                  child: pw.Row(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      if (photo1Exists)
                        pw.Expanded(
                          child: _defectPhoto(
                            d.photo1Path!,
                            annotations.where((a) => a.photoNumber == 1).toList(),
                          ),
                        ),
                      if (photo1Exists && photo2Exists) pw.SizedBox(width: 8),
                      if (photo2Exists)
                        pw.Expanded(
                          child: _defectPhoto(
                            d.photo2Path!,
                            annotations.where((a) => a.photoNumber == 2).toList(),
                          ),
                        ),
                    ],
                  ),
                ),
              );
            }

            widgets.add(pw.SizedBox(height: 12));
            widgets.add(pw.Divider());
            widgets.add(pw.SizedBox(height: 8));
            widgets.add(_subTitle('Herstel'));

            if (herstel == null) {
              widgets.add(_textBlock('Geen herstelgegevens ingevoerd.'));
            } else {
              widgets.addAll([
                _labelValue('Hersteld', herstel.isHersteld ? 'Ja' : 'Nee'),
                if (herstel.naam.isNotEmpty) _labelValue('Naam', herstel.naam),
                if (herstel.datum.isNotEmpty) _labelValue('Datum', herstel.datum),
                if (herstel.toelichting.isNotEmpty)
                  _labelValue('Toelichting', herstel.toelichting),
              ]);

              if (hPhoto1Exists || hPhoto2Exists) {
                widgets.add(pw.SizedBox(height: 8));
                widgets.add(
                  pw.SizedBox(
                    height: 180,
                    child: pw.Row(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        if (hPhoto1Exists)
                          pw.Expanded(
                            child: pw.Image(
                              pw.MemoryImage(File(herstel.photo1Path!).readAsBytesSync()),
                              fit: pw.BoxFit.contain,
                            ),
                          ),
                        if (hPhoto1Exists && hPhoto2Exists) pw.SizedBox(width: 8),
                        if (hPhoto2Exists)
                          pw.Expanded(
                            child: pw.Image(
                              pw.MemoryImage(File(herstel.photo2Path!).readAsBytesSync()),
                              fit: pw.BoxFit.contain,
                            ),
                          ),
                      ],
                    ),
                  ),
                );
              }
            }

            return widgets;
          },
        ),
      );
    }

    final dir = await PhotoService().getExportsDir();
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final filePath = p.join(dir, '${inspectionId}_herstel_$timestamp.pdf');
    await File(filePath).writeAsBytes(await pdf.save());
    await _db.updateInspectionStatus(inspectionId, 'exported');
    return filePath;
  }

  pw.Widget _herstelOverzichtTable(
      List<Defect> defects, Map<int, Herstel?> herstelByDefect) {
    return pw.Table(
      border: pw.TableBorder.all(color: PdfColors.grey400),
      columnWidths: {
        0: const pw.FlexColumnWidth(1.2),
        1: const pw.FlexColumnWidth(0.5),
        2: const pw.FlexColumnWidth(1.8),
        3: const pw.FlexColumnWidth(0.6),
        4: const pw.FlexColumnWidth(1.0),
      },
      children: [
        pw.TableRow(
          decoration: const pw.BoxDecoration(color: PdfColor.fromInt(0xFFE3F2FD)),
          children: [
            _tableHeader('Locatie'),
            _tableHeader('Klasse'),
            _tableHeader('Omschrijving'),
            _tableHeader('Hersteld'),
            _tableHeader('Datum herstel'),
          ],
        ),
        ...defects.map((d) {
          final herstel = d.id != null ? herstelByDefect[d.id!] : null;
          return pw.TableRow(children: [
            _tableCell(d.locationFull),
            _tableCell(d.classification),
            _tableCell(d.description),
            _tableCell(herstel == null
                ? '-'
                : herstel.isHersteld
                    ? 'Ja'
                    : 'Nee'),
            _tableCell(herstel?.datum ?? '-'),
          ]);
        }),
      ],
    );
  }

  Future<String> generateSwitchboardsConstateriungPdf(int inspectionId) async {
    final switchboards = await _db.getSwitchboards(inspectionId);
    final defects = await _db.getDefects(inspectionId);
    final companyDetails = await _db.getCompanyDetails();

    final Map<int, List<DefectAnnotation>> annotationsByDefect = {};
    for (final d in defects) {
      if (d.hasAnnotations && d.id != null) {
        annotationsByDefect[d.id!] =
            await _db.getAllAnnotationsForDefect(d.id!);
      }
    }

    final Map<int, String> tokenByDefect = {};
    for (final d in defects) {
      if (d.id != null) {
        tokenByDefect[d.id!] = await _db.ensureHerstelToken(d.id!);
      }
    }

    final pdf = pw.Document();

    for (final sb in switchboards) {
      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(40),
          build: (context) {
            return pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                _sectionTitle('Verdeler: ${sb.name}'),
                pw.SizedBox(height: 10),
                _labelValue('Locatie', sb.locationFull),
                _labelValue('Stelsel', sb.system),
                _labelValue(
                    'Kortsluitstroom', '${sb.shortCircuitCurrent ?? '-'} A'),
                _labelValue('Voorbeveiliging', sb.protection),
                _labelValue('Beschermingsgraad omhulsel', sb.protectionClass),
                _labelValue(
                    'Doorsnede', '${sb.cableCrossSection ?? '-'} mm²'),
                _labelValue('Lengte', '${sb.cableLength ?? '-'} m'),
                _labelValue('Hoofdschakelaar',
                    '${sb.mainSwitchCurrent ?? '-'} A, ${sb.mainSwitchPoles ?? '-'} polig'),
                pw.SizedBox(height: 10),
                if (sb.photo1Path != null && File(sb.photo1Path!).existsSync() ||
                    sb.photo2Path != null && File(sb.photo2Path!).existsSync()) ...[
                  pw.Row(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      if (sb.photo1Path != null && File(sb.photo1Path!).existsSync())
                        pw.Expanded(
                          child: pw.SizedBox(
                            height: 130,
                            child: pw.Image(
                              pw.MemoryImage(File(sb.photo1Path!).readAsBytesSync()),
                              fit: pw.BoxFit.contain,
                            ),
                          ),
                        ),
                      if (sb.photo1Path != null && File(sb.photo1Path!).existsSync() &&
                          sb.photo2Path != null && File(sb.photo2Path!).existsSync())
                        pw.SizedBox(width: 8),
                      if (sb.photo2Path != null && File(sb.photo2Path!).existsSync())
                        pw.Expanded(
                          child: pw.SizedBox(
                            height: 130,
                            child: pw.Image(
                              pw.MemoryImage(File(sb.photo2Path!).readAsBytesSync()),
                              fit: pw.BoxFit.contain,
                            ),
                          ),
                        ),
                    ],
                  ),
                  pw.SizedBox(height: 10),
                ],
                _subTitle('Visuele inspectie'),
                ...sb.visualInspection.entries
                    .map((e) => _checklistRow(e.key, e.value)),
                pw.SizedBox(height: 10),
                _subTitle('Metingen en beproevingen'),
                ...sb.measurements.entries
                    .map((e) => _checklistRow(e.key, e.value)),
              ],
            );
          },
        ),
      );
    }

    if (defects.isNotEmpty) {
      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(40),
          build: (context) => [
            _sectionTitle('Constateringen'),
            pw.SizedBox(height: 10),
            _defectsTable(defects),
          ],
        ),
      );
    }

    _addDefectPhotoPages(pdf, defects, annotationsByDefect, null, tokenByDefect,
        companyDetails?.herstelWebDomain);

    final dir = await PhotoService().getExportsDir();
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final filePath =
        p.join(dir, '${inspectionId}_schakelv_constatering_$timestamp.pdf');
    await File(filePath).writeAsBytes(await pdf.save());
    await _db.updateInspectionStatus(inspectionId, 'exported');
    return filePath;
  }

  pw.Widget _defectsTable(List<Defect> defects) {
    return pw.Table(
      border: pw.TableBorder.all(color: PdfColors.grey400),
      columnWidths: {
        0: const pw.FlexColumnWidth(1.2),
        1: const pw.FlexColumnWidth(0.5),
        2: const pw.FlexColumnWidth(2.3),
      },
      children: [
        pw.TableRow(
          decoration: const pw.BoxDecoration(
              color: PdfColor.fromInt(0xFFE3F2FD)),
          children: [
            _tableHeader('Locatie'),
            _tableHeader('Klasse'),
            _tableHeader('Omschrijving'),
          ],
        ),
        ...defects.map((d) => pw.TableRow(children: [
              _tableCell(d.locationFull),
              _tableCell(d.classification),
              _tableCell(d.description),
            ])),
      ],
    );
  }

  void _addDefectPhotoPages(
    pw.Document pdf,
    List<Defect> defects,
    Map<int, List<DefectAnnotation>> annotationsByDefect,
    Uint8List? headerLogoBytes,
    Map<int, String> tokenByDefect,
    String? herstelDomain,
  ) {
    final defectsWithPhotos = defects
        .where((d) =>
            d.id != null &&
            ((d.photo1Path != null && File(d.photo1Path!).existsSync()) ||
                (d.photo2Path != null && File(d.photo2Path!).existsSync())))
        .toList();

    pw.Widget defectBlock(Defect d, List<DefectAnnotation> annotations, String? token) {
      final photo1Exists =
          d.photo1Path != null && File(d.photo1Path!).existsSync();
      final photo2Exists =
          d.photo2Path != null && File(d.photo2Path!).existsSync();
      return pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Expanded(child: _subTitle('${d.classification} — ${d.locationFull}')),
              if (token != null) pw.SizedBox(width: 8),
              _herstelQrCode(herstelDomain, token),
            ],
          ),
          if (d.description.isNotEmpty) pw.SizedBox(height: 2),
          if (d.description.isNotEmpty) _textBlock(d.description),
          pw.SizedBox(height: 6),
          pw.Expanded(
            child: pw.Row(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                if (photo1Exists)
                  pw.Expanded(
                    child: _defectPhoto(
                      d.photo1Path!,
                      annotations.where((a) => a.photoNumber == 1).toList(),
                    ),
                  ),
                if (photo1Exists && photo2Exists) pw.SizedBox(width: 8),
                if (photo2Exists)
                  pw.Expanded(
                    child: _defectPhoto(
                      d.photo2Path!,
                      annotations.where((a) => a.photoNumber == 2).toList(),
                    ),
                  ),
              ],
            ),
          ),
        ],
      );
    }

    for (int i = 0; i < defectsWithPhotos.length; i += 2) {
      final d1 = defectsWithPhotos[i];
      final d2 =
          i + 1 < defectsWithPhotos.length ? defectsWithPhotos[i + 1] : null;
      final ann1 = annotationsByDefect[d1.id!] ?? [];
      final ann2 = d2 != null
          ? (annotationsByDefect[d2.id!] ?? <DefectAnnotation>[])
          : <DefectAnnotation>[];

      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(40),
          build: (context) {
            return pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                _logoHeader(headerLogoBytes),
                pw.SizedBox(height: 4),
                if (i == 0) _sectionTitle('Constatering(en)'),
                if (i == 0) pw.SizedBox(height: 8),
                pw.Expanded(child: defectBlock(d1, ann1, tokenByDefect[d1.id!])),
                if (d2 != null) pw.Divider(color: PdfColors.grey400),
                if (d2 != null) pw.Expanded(child: defectBlock(d2, ann2, tokenByDefect[d2.id!])),
              ],
            );
          },
        ),
      );
    }
  }

  Future<String> generateSamplePdf() async {
    final pdf = pw.Document();

    // Titelpagina
    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(40),
        build: (context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Center(
                child: pw.Text(
                  'Voorbeeld Inspectie Rapport',
                  style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold),
                ),
              ),
              pw.SizedBox(height: 30),
              pw.Center(
                child: pw.Container(
                  width: 300,
                  height: 180,
                  decoration: pw.BoxDecoration(
                    border: pw.Border.all(color: PdfColors.grey400),
                    color: PdfColors.grey100,
                  ),
                  child: pw.Center(
                    child: pw.Text('[ Foto placeholder ]',
                        style: const pw.TextStyle(color: PdfColors.grey, fontSize: 14)),
                  ),
                ),
              ),
              pw.SizedBox(height: 30),
              _labelValue('Inspectiedatum', '15-02-2026'),
              _labelValue('Identificatiecode', 'INS-2026-001'),
              _labelValue('Project-/werkbonnummer', 'WB-12345'),
            ],
          );
        },
      ),
    );

    // Algemene Gegevens
    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(40),
        build: (context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              _sectionTitle('Algemene Gegevens'),
              pw.SizedBox(height: 10),
              _subTitle('Opdrachtgever'),
              _labelValue('Naam Bedrijf', 'Voorbeeld BV'),
              _labelValue('Adres', 'Hoofdstraat 1'),
              _labelValue('Postcode Plaats', '1234 AB Amsterdam'),
              _labelValue('Contactpersoon', 'Jan de Vries'),
              pw.SizedBox(height: 10),
              _subTitle('Inspectieadres'),
              _labelValue('Naam', 'Kantoorgebouw Noord'),
              _labelValue('Adres', 'Industrieweg 42'),
              _labelValue('Postcode Plaats', '5678 CD Rotterdam'),
              _labelValue('Contactpersoon', 'Piet Jansen'),
              pw.SizedBox(height: 10),
              _subTitle('Inspectiebedrijf'),
              _labelValue('Naam bedrijf', 'ElektroInspect B.V.'),
              _labelValue('Adres', 'Keuringslaan 10'),
              _labelValue('Postcode Plaats', '9012 EF Utrecht'),
              _labelValue('Telefoon', '030-1234567'),
              _labelValue('Mail', 'info@elektroinspect.nl'),
              _labelValue('Contactpersoon', 'Klaas Bakker'),
              _labelValue('Inspecteur(s)', 'K. Bakker, M. Smit'),
              pw.SizedBox(height: 12),
              _subTitle('Meetinstrumenten'),
              pw.SizedBox(height: 4),
              pw.Table(
                border: pw.TableBorder.all(color: PdfColors.grey400),
                columnWidths: {
                  0: const pw.FlexColumnWidth(1.1),
                  1: const pw.FlexColumnWidth(1.2),
                  2: const pw.FlexColumnWidth(1.2),
                  3: const pw.FlexColumnWidth(1.1),
                  4: const pw.FlexColumnWidth(0.9),
                },
                children: [
                  pw.TableRow(
                    decoration: const pw.BoxDecoration(
                        color: PdfColor.fromInt(0xFFE3F2FD)),
                    children: [
                      _tableHeader('Registratienr.'),
                      _tableHeader('Fabrikant'),
                      _tableHeader('Model'),
                      _tableHeader('Herkalibratie'),
                      _tableHeader('Status'),
                    ],
                  ),
                  pw.TableRow(children: [
                    _tableCell('003'),
                    _tableCell('HT Italia'),
                    _tableCell('Combi 420'),
                    _tableCell('30-07-2026'),
                    _tableCell('Actief'),
                  ]),
                  pw.TableRow(children: [
                    _tableCell('1034'),
                    _tableCell('Flir'),
                    _tableCell('E8 Pro'),
                    _tableCell('19-12-2026'),
                    _tableCell('Actief'),
                  ]),
                ],
              ),
            ],
          );
        },
      ),
    );

    // Inleiding
    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(40),
        build: (context) => [
          _sectionTitle('Inleiding'),
          pw.SizedBox(height: 10),
          _textBlock(
            'In dit inspectierapport zijn de bevindingen beschreven van een inspectie '
            'volgens NEN 3140 van de elektrische laagspanningsinstallatie. Het doel van '
            'inspecties volgens NEN 3140 is gebreken te ontdekken die een veilige '
            'bedrijfsvoering kunnen belemmeren.\n\n'
            'In opdracht van Voorbeeld BV te Amsterdam is op 15-02-2026 door '
            'ElektroInspect B.V. een inspectie uitgevoerd aan de elektrotechnische '
            'installaties. Deze inspectie is uitgevoerd in het pand aan de Industrieweg 42 '
            'te Rotterdam.',
          ),
        ],
      ),
    );

    // Inspectie Details
    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(40),
        build: (context) => [
          _sectionTitle('Inspectie Details'),
          pw.SizedBox(height: 10),
          _subTitle('Omvang'),
          _labelValue('Omschrijving van de inspectie',
              'Periodieke inspectie van de elektrische installatie conform NEN 3140.'),
          _labelValue('Niet geinspecteerde delen',
              'Serverruimte (niet toegankelijk tijdens inspectie)'),
          _labelValue('Reden niet inspecteren',
              'Ruimte was afgesloten i.v.m. onderhoud koelsysteem.'),
          pw.SizedBox(height: 10),
          _subTitle('Uitgangspunten'),
          _labelValue('Reden van inspectie', 'Periodieke herkeuring (5-jaarlijks)'),
          _labelValue('Uitgevoerd volgens', 'NEN 1010:2020 en NEN 3140:2018'),
          _labelValue('Getoetst aan', 'NEN 1010:2020'),
          pw.SizedBox(height: 10),
          _subTitle('Methode'),
          _labelValue('Visuele inspectie', ''),
          _textBlock('1)  De elektrische installatie visueel geïnspecteerd op:\n'
              '    - Aanraakveiligheid\n'
              '    - Overeenstemming met de omgeving\n'
              '    - Staat van onderhoud'),
          pw.SizedBox(height: 6),
          _labelValue('Metingen en beproevingen', ''),
          _textBlock('1)  Ononderbroken zijn van de beschermingsleiding\n'
              '2)  Isolatieweerstand\n'
              '3)  Aardlekbeveiliging'),
          pw.SizedBox(height: 6),
          _labelValue('Afkeuringscriteria', ''),
          _textBlock('Bij een gebrek of afwijking van een standaard met directe '
              'veiligheidsconsequenties wordt de installatie afgekeurd.'),
        ],
      ),
    );

    // Verdeler
    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(40),
        build: (context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              _sectionTitle('Verdeler: HV-01'),
              pw.SizedBox(height: 10),
              _labelValue('Locatie', 'Meterkast begane grond'),
              _labelValue('Stelsel', 'TN-S'),
              _labelValue('Kortsluitstroom', '6000 A'),
              _labelValue('Voorbeveiliging', 'Gl 63 A'),
              _labelValue('Beschermingsgraad omhulsel', 'IP54'),
              _labelValue('Doorsnede', '16 mm²'),
              _labelValue('Lengte', '< 25 m'),
              _labelValue('Hoofdschakelaar', '63 A, 4 polig'),
              pw.SizedBox(height: 10),
              _subTitle('Visuele inspectie'),
              _checklistRow('Verdeler eenduidig herkenbaar', 'Ja'),
              _checklistRow('Installatieschema actueel', 'Ja'),
              _checklistRow('Codering; aansluitklemmen, bedrading', 'Ja'),
              _checklistRow('Verdeler aanraakveilig', 'Ja'),
              _checklistRow('Overeenstemming met de omgeving', 'Ja'),
              _checklistRow('Aansluitingen zijn correct uitgevoerd', 'Nee'),
              _checklistRow('Veilige scheiding van stroomketens', 'Ja'),
              _checklistRow('Vrij van stof, vuil en water', 'Nee'),
              _checklistRow('Verdeler toegankelijk', 'Ja'),
              _checklistRow('Beveiligingstoestellen aanwezig zijn', 'Ja'),
              _checklistRow('Beveiligingstoestellen juist gekozen zijn', 'Ja'),
              _checklistRow('Schakelaars/scheiders aanwezig zijn', 'Ja'),
              _checklistRow('Schakelaars/scheiders juist gekozen zijn', 'Ja'),
              pw.SizedBox(height: 10),
              _subTitle('Metingen en beproevingen'),
              _checklistRow('Impedantie foutstroomketen', 'Ja'),
              _checklistRow('Isolatieweerstand', 'Ja'),
              _checklistRow('Aardlekbeveiliging', 'Ja'),
              _checklistRow('Thermografie', 'N.v.t.'),
            ],
          );
        },
      ),
    );

    // Zonnestroom-installatie
    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(40),
        build: (context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              _sectionTitle('Zonnestroom-installatie'),
              pw.SizedBox(height: 10),
              _labelValue('Locatie', 'Dak kantoorgebouw'),
              _labelValue('Deellocatie panelen', 'Plat dak - zuidzijde'),
              _labelValue('Aantal panelen', '24'),
              _labelValue('Aantal omvormers', '2'),
              _labelValue('WattPiek vermogen', '9600'),
              _labelValue('Bouwvorm', 'Plat dak opstelling met ballast'),
            ],
          );
        },
      ),
    );

    // Gebreken
    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(40),
        build: (context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              _sectionTitle('Gebreken'),
              pw.SizedBox(height: 10),
              pw.Table(
                border: pw.TableBorder.all(),
                columnWidths: {
                  0: const pw.FlexColumnWidth(1),
                  1: const pw.FlexColumnWidth(0.5),
                  2: const pw.FlexColumnWidth(2),
                },
                children: [
                  pw.TableRow(
                    decoration: const pw.BoxDecoration(
                      color: PdfColor.fromInt(0xFFE3F2FD),
                    ),
                    children: [
                      _tableHeader('Locatie'),
                      _tableHeader('Klasse'),
                      _tableHeader('Omschrijving'),
                    ],
                  ),
                  pw.TableRow(children: [
                    _tableCell('HV-01, groep 3'),
                    _tableCell('Or'),
                    _tableCell('Losse aansluiting L1 op klem 3. Direct herstellen.'),
                  ]),
                  pw.TableRow(children: [
                    _tableCell('HV-01, kast'),
                    _tableCell('Ge'),
                    _tableCell('Stofophoping in verdeler. Schoonmaken bij eerstvolgende onderhoud.'),
                  ]),
                  pw.TableRow(children: [
                    _tableCell('Verdieping 2, WCD 4'),
                    _tableCell('Bl'),
                    _tableCell('Wandcontactdoos vergeeld. Cosmetisch, geen veiligheidsrisico.'),
                  ]),
                ],
              ),
            ],
          );
        },
      ),
    );

    // Eindbeoordeling
    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(40),
        build: (context) => [
          _sectionTitle('Eindbeoordeling'),
          pw.SizedBox(height: 10),
          _subTitle('Beoordeling'),
          _textBlock(
            'De elektrische installatie voldoet grotendeels aan de gestelde eisen. '
            'Er zijn twee gebreken geconstateerd die binnen de gestelde termijnen '
            'dienen te worden hersteld. Na herstel is de installatie goedgekeurd.',
          ),
          pw.SizedBox(height: 6),
          _labelValue('Volgende inspectie', '01-03-2031'),
          pw.SizedBox(height: 16),
          _subTitle('Ondertekening'),
          pw.SizedBox(height: 8),
          pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Expanded(child: _signatoryBlock(
                'Ondertekenaar 1', 'K. Bakker', 'Inspecteur', '15-02-2026', '',
              )),
              pw.SizedBox(width: 20),
              pw.Expanded(child: _signatoryBlock(
                'Ondertekenaar 2', 'M. Smit', 'Hoofd Inspectie', '15-02-2026', '',
              )),
            ],
          ),
        ],
      ),
    );

    final dir = await PhotoService().getExportsDir();
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final filePath = p.join(dir, 'voorbeeld_$timestamp.pdf');
    final file = File(filePath);
    await file.writeAsBytes(await pdf.save());

    return filePath;
  }

  pw.Widget _instrumentsTable(List<MeasurementInstrument> instruments) {
    const headerColor = PdfColor.fromInt(0xFFE3F2FD);
    return pw.Table(
      border: pw.TableBorder.all(color: PdfColors.grey400),
      columnWidths: {
        0: const pw.FlexColumnWidth(1.1),
        1: const pw.FlexColumnWidth(1.2),
        2: const pw.FlexColumnWidth(1.2),
        3: const pw.FlexColumnWidth(1.1),
        4: const pw.FlexColumnWidth(0.9),
      },
      children: [
        pw.TableRow(
          decoration: const pw.BoxDecoration(color: headerColor),
          children: [
            _tableHeader('Registratienr.'),
            _tableHeader('Fabrikant'),
            _tableHeader('Model'),
            _tableHeader('Herkalibratie'),
            _tableHeader('Status'),
          ],
        ),
        ...instruments.map(
          (i) => pw.TableRow(children: [
            _tableCell(i.registratienummer),
            _tableCell(i.fabrikant),
            _tableCell(i.model),
            _tableCell(i.herkalibratiedatum),
            _tableCell(i.status),
          ]),
        ),
      ],
    );
  }

  pw.Widget _logoHeader(Uint8List? logoBytes) {
    if (logoBytes == null) return pw.SizedBox.shrink();
    return pw.Align(
      alignment: pw.Alignment.centerRight,
      child: pw.Image(pw.MemoryImage(logoBytes), height: 32),
    );
  }

  pw.Widget _constateringenTabel(List<String> classifications) {
    const cats = ['Rd', 'Or', 'Ge', 'Bl', 'Pa', 'Gr'];
    final counts = {for (final c in cats) c: classifications.where((x) => x == c).length};
    final total = counts.values.fold(0, (s, v) => s + v);

    const bgColors = {
      'Rd': PdfColor.fromInt(0xFFEF5350),
      'Or': PdfColor.fromInt(0xFFFF9800),
      'Ge': PdfColor.fromInt(0xFFFFEE58),
      'Bl': PdfColor.fromInt(0xFF42A5F5),
      'Pa': PdfColor.fromInt(0xFFAB47BC),
      'Gr': PdfColor.fromInt(0xFF9E9E9E),
    };
    const fgColors = {
      'Rd': PdfColors.white,
      'Or': PdfColors.white,
      'Ge': PdfColor.fromInt(0xFF5D4037),
      'Bl': PdfColors.white,
      'Pa': PdfColors.white,
      'Gr': PdfColors.white,
    };

    pw.Widget headerCell(String label) => pw.Container(
          color: bgColors[label],
          padding: const pw.EdgeInsets.symmetric(vertical: 4, horizontal: 2),
          alignment: pw.Alignment.center,
          child: pw.Text(label,
              style: pw.TextStyle(
                fontSize: 9,
                fontWeight: pw.FontWeight.bold,
                color: fgColors[label],
              )),
        );

    pw.Widget countCell(String cat, int n) => pw.Container(
          color: PdfColors.white,
          padding: const pw.EdgeInsets.symmetric(vertical: 5, horizontal: 2),
          alignment: pw.Alignment.center,
          child: pw.Text('$n',
              style: pw.TextStyle(
                fontSize: 10,
                fontWeight: n > 0 ? pw.FontWeight.bold : pw.FontWeight.normal,
                color: n > 0 ? bgColors[cat] : PdfColors.grey400,
              )),
        );

    pw.Widget totalCell(int n) => pw.Container(
          color: PdfColors.grey200,
          padding: const pw.EdgeInsets.symmetric(vertical: 5, horizontal: 2),
          alignment: pw.Alignment.center,
          child: pw.Text('$n',
              style: pw.TextStyle(
                  fontSize: 10, fontWeight: pw.FontWeight.bold)),
        );

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text('Overzicht constateringen',
            style: pw.TextStyle(
                fontSize: 11,
                fontWeight: pw.FontWeight.bold,
                color: const PdfColor.fromInt(0xFF1976D2))),
        pw.SizedBox(height: 4),
        pw.Table(
          border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
          columnWidths: {
            for (int i = 0; i <= cats.length; i++)
              i: const pw.FlexColumnWidth()
          },
          children: [
            pw.TableRow(children: [
              ...cats.map(headerCell),
              pw.Container(
                color: PdfColors.grey300,
                padding: const pw.EdgeInsets.symmetric(vertical: 4, horizontal: 2),
                alignment: pw.Alignment.center,
                child: pw.Text('Totaal',
                    style: pw.TextStyle(
                        fontSize: 9, fontWeight: pw.FontWeight.bold)),
              ),
            ]),
            pw.TableRow(children: [
              ...cats.map((c) => countCell(c, counts[c]!)),
              totalCell(total),
            ]),
          ],
        ),
      ],
    );
  }

  pw.Widget _sectionTitle(String text) {
    return pw.Text(
      text,
      style: pw.TextStyle(
        fontSize: 18,
        fontWeight: pw.FontWeight.bold,
        color: const PdfColor.fromInt(0xFF1976D2),
      ),
    );
  }

  pw.Widget _subTitle(String text) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 4),
      child: pw.Text(
        text,
        style: pw.TextStyle(
          fontSize: 14,
          fontWeight: pw.FontWeight.bold,
        ),
      ),
    );
  }

  pw.Widget _labelValue(String label, String value) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 2),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.SizedBox(
            width: 180,
            child: pw.Text(
              '$label:',
              style: pw.TextStyle(
                fontSize: 10,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
          ),
          pw.Expanded(
            child: pw.Text(value, style: const pw.TextStyle(fontSize: 10)),
          ),
        ],
      ),
    );
  }

  pw.Widget _checklistRow(String label, String value) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 1),
      child: pw.Row(
        children: [
          pw.Expanded(
            flex: 3,
            child: pw.Text(label, style: const pw.TextStyle(fontSize: 9)),
          ),
          pw.SizedBox(
            width: 60,
            child: pw.Text(
              value,
              style: pw.TextStyle(
                fontSize: 9,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  pw.Widget _tableHeader(String text) {
    return pw.Padding(
      padding: const pw.EdgeInsets.all(4),
      child: pw.Text(
        text,
        style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold),
      ),
    );
  }

  pw.Widget _tableCell(String text) {
    return pw.Padding(
      padding: const pw.EdgeInsets.all(4),
      child: pw.Text(text, style: const pw.TextStyle(fontSize: 9)),
    );
  }

  pw.Widget _textBlock(String text) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 4),
      child: pw.Text(text, style: const pw.TextStyle(fontSize: 10)),
    );
  }

  bool _hasValue(String? s) => s != null && s.isNotEmpty;

  pw.Widget _labelMultiValue(String label, List<String> values) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 2),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.SizedBox(
            width: 180,
            child: pw.Text(
              '$label:',
              style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold),
            ),
          ),
          pw.Expanded(
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: values
                  .map((v) => pw.Text('• ${v.trim()}',
                      style: const pw.TextStyle(fontSize: 10)))
                  .toList(),
            ),
          ),
        ],
      ),
    );
  }

  pw.Widget _photoRow(List<String> paths) {
    final images = paths.take(4).toList();
    return pw.Padding(
      padding: const pw.EdgeInsets.only(top: 6, bottom: 6),
      child: pw.Row(
        children: images.map((path) {
          return pw.Expanded(
            child: pw.Padding(
              padding: const pw.EdgeInsets.only(right: 6),
              child: pw.SizedBox(
                height: 120,
                child: pw.Image(
                  pw.MemoryImage(File(path).readAsBytesSync()),
                  fit: pw.BoxFit.contain,
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  pw.Widget _stringMeasurementsTable(List<SolarStringMeasurement> rows) {
    const headerColor = PdfColor.fromInt(0xFFE3F2FD);
    const fontSize = 8.0;

    pw.Widget hCell(String t) => pw.Padding(
          padding: const pw.EdgeInsets.all(3),
          child: pw.Text(t,
              style: pw.TextStyle(
                  fontSize: fontSize, fontWeight: pw.FontWeight.bold)),
        );
    pw.Widget dCell(String t) => pw.Padding(
          padding: const pw.EdgeInsets.all(3),
          child: pw.Text(t, style: const pw.TextStyle(fontSize: fontSize)),
        );

    return pw.Table(
      border: pw.TableBorder.all(color: PdfColors.grey400),
      columnWidths: {
        0: const pw.FlexColumnWidth(0.7),
        1: const pw.FlexColumnWidth(0.8),
        2: const pw.FlexColumnWidth(1.0),
        3: const pw.FlexColumnWidth(1.0),
        4: const pw.FlexColumnWidth(0.9),
        5: const pw.FlexColumnWidth(0.8),
        6: const pw.FlexColumnWidth(0.9),
      },
      children: [
        pw.TableRow(
          decoration: const pw.BoxDecoration(color: headerColor),
          children: [
            hCell('Streng'),
            hCell('Aantal pan.'),
            hCell('Instraling\nW/m²'),
            hCell('Cel/buiten\n°C'),
            hCell('Uoc\n(VDC)'),
            hCell('Isc\n[A]'),
            hCell('Riso\n[MΩ]'),
          ],
        ),
        ...rows.map((r) => pw.TableRow(children: [
              dCell(r.strang),
              dCell(r.panelCount),
              dCell(r.irradiation),
              dCell(r.cellTemp),
              dCell(r.uoc),
              dCell(r.isc),
              dCell(r.riso),
            ])),
      ],
    );
  }

  pw.Widget _steekproefTable(List<SteekproefItem> items) {
    return pw.Table(
      border: pw.TableBorder.all(color: PdfColors.grey400),
      columnWidths: {
        0: const pw.FlexColumnWidth(2.5),
        1: const pw.FlexColumnWidth(1.0),
        2: const pw.FlexColumnWidth(1.0),
        3: const pw.FlexColumnWidth(0.6),
        4: const pw.FlexColumnWidth(0.6),
      },
      children: [
        pw.TableRow(
          decoration: const pw.BoxDecoration(
              color: PdfColor.fromInt(0xFFE3F2FD)),
          children: [
            _tableHeader('Beschrijving'),
            _tableHeader('Omvang partij'),
            _tableHeader('Steekproef'),
            _tableHeader('G'),
            _tableHeader('F'),
          ],
        ),
        ...items.map((item) => pw.TableRow(children: [
              _tableCell(item.beschrijving),
              _tableCell('${item.omvangPartij}'),
              _tableCell('${item.steekproef}'),
              _tableCell('${item.g}'),
              _tableCell('${item.f}'),
            ])),
      ],
    );
  }

  pw.Widget _pinsLegendTable(List<TekeningPin> pins) {
    return pw.Table(
      border: pw.TableBorder.all(color: PdfColors.grey400),
      columnWidths: {
        0: const pw.FlexColumnWidth(0.4),
        1: const pw.FlexColumnWidth(0.8),
        2: const pw.FlexColumnWidth(0.7),
        3: const pw.FlexColumnWidth(2.1),
      },
      children: [
        pw.TableRow(
          decoration: const pw.BoxDecoration(
              color: PdfColor.fromInt(0xFFE3F2FD)),
          children: [
            _tableHeader('Nr.'),
            _tableHeader('Type'),
            _tableHeader('Kleur'),
            _tableHeader('Beschrijving'),
          ],
        ),
        ...pins.map((pin) => pw.TableRow(children: [
              _tableCell('${pin.volgnummer}'),
              _tableCell(pin.typeLabel),
              _tableCell(TekeningPin.kleurNamen[pin.kleur] ?? pin.kleur),
              _tableCell(pin.waardeTekst.isNotEmpty
                  ? pin.waardeTekst
                  : pin.label),
            ])),
      ],
    );
  }

  pw.Widget _defectPhoto(String path, List<DefectAnnotation> annotations) {
    final bytes = File(path).readAsBytesSync();
    return pw.ClipRect(
      child: pw.Stack(
        children: [
          pw.SizedBox(
            height: 180,
            child: pw.Image(pw.MemoryImage(bytes), fit: pw.BoxFit.contain),
          ),
          pw.Positioned.fill(
            child: pw.CustomPaint(
              size: const PdfPoint(240, 180),
              painter: (canvas, size) {
                for (final a in annotations.where((a) => _isPdfArrow(a))) {
                  _drawPdfArrow(canvas, size, a);
                }
              },
            ),
          ),
          ...annotations.where((a) => !_isPdfArrow(a)).map((a) {
            const w = 240.0;
            const h = 180.0;
            final color = _pdfColorForPin(a.color);
            return pw.Positioned(
              left: a.x * w,
              top: a.y * h,
              child: pw.Container(
                width: a.width * w,
                height: a.height * h,
                decoration: pw.BoxDecoration(
                  border: pw.Border.all(color: color, width: 1.5),
                ),
                child: a.label.isNotEmpty
                    ? pw.Align(
                        alignment: pw.Alignment.topLeft,
                        child: pw.Container(
                          color: color,
                          padding: const pw.EdgeInsets.all(1),
                          child: pw.Text(a.label,
                              style: const pw.TextStyle(fontSize: 6)),
                        ),
                      )
                    : null,
              ),
            );
          }),
        ],
      ),
    );
  }

  bool _isPdfArrow(DefectAnnotation a) =>
      a.shape == 'arrow' || a.shape == 'double_arrow';

  /// Draws an arrow annotation on a PDF canvas. [size] is the pixel size of
  /// the photo box; the canvas origin is bottom-left with y increasing
  /// upward, so y values must be flipped relative to the top-anchored
  /// normalized annotation coordinates.
  void _drawPdfArrow(PdfGraphics canvas, PdfPoint size, DefectAnnotation a) {
    final color = _pdfColorForPin(a.color);
    final x1 = a.x * size.x;
    final y1 = size.y - a.y * size.y;
    final x2 = (a.x + a.width) * size.x;
    final y2 = size.y - (a.y + a.height) * size.y;

    canvas
      ..setColor(color)
      ..setLineWidth(1.5)
      ..drawLine(x1, y1, x2, y2)
      ..strokePath();

    _drawPdfArrowHead(canvas, x1, y1, x2, y2);
    if (a.shape == 'double_arrow') {
      _drawPdfArrowHead(canvas, x2, y2, x1, y1);
    }
  }

  /// Draws a filled arrowhead triangle at (toX, toY), pointing away from
  /// (fromX, fromY).
  void _drawPdfArrowHead(
      PdfGraphics canvas, double fromX, double fromY, double toX, double toY) {
    const headLength = 6.0;
    const headAngle = 0.5;
    final angle = math.atan2(toY - fromY, toX - fromX);
    final hx1 = toX - headLength * math.cos(angle - headAngle);
    final hy1 = toY - headLength * math.sin(angle - headAngle);
    final hx2 = toX - headLength * math.cos(angle + headAngle);
    final hy2 = toY - headLength * math.sin(angle + headAngle);

    canvas
      ..moveTo(toX, toY)
      ..lineTo(hx1, hy1)
      ..lineTo(hx2, hy2)
      ..closePath()
      ..fillPath();
  }

  PdfColor _pdfColorForPin(String kleur) {
    switch (kleur) {
      case 'Rd':
        return const PdfColor.fromInt(0xFFE53935);
      case 'Or':
        return const PdfColor.fromInt(0xFFFF9800);
      case 'Ge':
        return const PdfColor.fromInt(0xFFFDD835);
      case 'Bl':
        return const PdfColor.fromInt(0xFF1E88E5);
      case 'Pa':
        return const PdfColor.fromInt(0xFF8E24AA);
      default:
        return const PdfColor.fromInt(0xFF757575);
    }
  }

  Future<String> generateMeldingGevaarlijkeSituatiePdf({
    required int inspectionId,
    required Defect defect,
    required int defectNumber,
    String installatieverantwoordelijkeNaam = '',
    String installatieverantwoordelijkeTelefoon = '',
    String meldingstekst = '',
    String opmerkingen = '',
    String naamInspecteur = '',
    String handtekeningInspecteurBase64 = '',
    String naamKlant = '',
    String handtekeningKlantBase64 = '',
  }) async {
    final companyDetails = await _db.getCompanyDetails();
    final generalData = await _db.getGeneralData(inspectionId);
    final titlePage = await _db.getTitlePage(inspectionId);

    final Uint8List? logoBytes = companyDetails?.logoPath != null &&
            File(companyDetails!.logoPath!).existsSync()
        ? File(companyDetails.logoPath!).readAsBytesSync()
        : null;

    final rapportnummer = titlePage?.projectNumber.isNotEmpty == true
        ? titlePage!.projectNumber
        : (titlePage?.identificationCode.isNotEmpty == true
            ? titlePage!.identificationCode
            : '$inspectionId');

    final fmt = DateFormat('dd/MM/yyyy');
    final printdatum = fmt.format(DateTime.now());

    const bgColor = PdfColor.fromInt(0xFFDCE9F5);
    const labelFs = 9.0;
    const headFs = 10.5;
    const pad = 28.0;
    final pageW = PdfPageFormat.a4.width;
    final pageH = PdfPageFormat.a4.height;
    final contentW = pageW - 2 * pad;

    pw.Widget lv(String label, String value) => pw.Padding(
          padding: const pw.EdgeInsets.only(bottom: 2),
          child: pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.SizedBox(
                width: 110,
                child: pw.Text(label,
                    style: const pw.TextStyle(fontSize: labelFs)),
              ),
              pw.Text(': ',
                  style: const pw.TextStyle(fontSize: labelFs)),
              pw.Expanded(
                child: pw.Text(value,
                    style: const pw.TextStyle(fontSize: labelFs)),
              ),
            ],
          ),
        );

    pw.Widget secTitle(String text) => pw.Padding(
          padding: const pw.EdgeInsets.only(top: 10, bottom: 3),
          child: pw.Text(
            text,
            style: pw.TextStyle(
                fontSize: headFs, fontWeight: pw.FontWeight.bold),
          ),
        );

    pw.Widget pageHeader(String pagina) => pw.Row(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Expanded(
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    'Melding gevaarlijke situatie',
                    style: pw.TextStyle(
                      fontSize: 20,
                      fontStyle: pw.FontStyle.italic,
                    ),
                  ),
                  pw.SizedBox(height: 6),
                  lv('Rapportnummer', rapportnummer),
                  lv('Printdatum', printdatum),
                  lv('Pagina', pagina),
                ],
              ),
            ),
            if (logoBytes != null)
              pw.Container(
                width: 110,
                height: 72,
                decoration: const pw.BoxDecoration(
                  color: PdfColors.white,
                  border: pw.Border.fromBorderSide(
                    pw.BorderSide(color: PdfColors.grey400),
                  ),
                ),
                padding: const pw.EdgeInsets.all(8),
                child: pw.Image(pw.MemoryImage(logoBytes),
                    fit: pw.BoxFit.contain),
              ),
          ],
        );

    final pdf = pw.Document();

    // ── Page 1 ─────────────────────────────────────────────────────────
    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: pw.EdgeInsets.zero,
        build: (ctx) {
          final inspectorCompany =
              generalData?.inspectorCompany ?? '';
          final locStreet =
              generalData?.inspectionAddressStreet ?? '';

          return pw.Stack(
            children: [
              pw.Positioned(
                left: 0,
                top: 0,
                child: pw.Container(
                    width: pageW, height: pageH, color: bgColor),
              ),
              pw.Positioned(
                left: pad,
                top: pad,
                child: pw.SizedBox(
                  width: contentW,
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pageHeader('1 van 2'),
                      pw.SizedBox(height: 16),

                      // Opdrachtgever
                      secTitle('Opdrachtgever'),
                      lv('Naam bedrijf',
                          generalData?.clientCompany ?? ''),
                      lv('Contactpersoon',
                          generalData?.clientContact ?? ''),
                      lv('Telefoonnummer',
                          generalData?.clientPhone ?? ''),
                      lv('Adres', generalData?.clientAddress ?? ''),
                      lv('Plaats',
                          generalData?.clientPostalCity ?? ''),

                      // Installatieverantwoordelijke (alleen tonen als ingevuld)
                      if (installatieverantwoordelijkeNaam.isNotEmpty ||
                          installatieverantwoordelijkeTelefoon.isNotEmpty) ...[
                        secTitle('Installatieverantwoordelijke'),
                        if (installatieverantwoordelijkeNaam.isNotEmpty)
                          lv('Naam', installatieverantwoordelijkeNaam),
                        if (installatieverantwoordelijkeTelefoon.isNotEmpty)
                          lv('Telefoonnummer',
                              installatieverantwoordelijkeTelefoon),
                      ],

                      // Locatie
                      secTitle('Locatie'),
                      lv('Adres', locStreet),
                      lv('Plaats',
                          generalData?.inspectionAddressPostalCity ??
                              ''),
                      lv('Contactpersoon',
                          generalData?.inspectionAddressContact ?? ''),
                      lv('Telefoonnummer',
                          generalData?.inspectionAddressPhone ?? ''),

                      // Inspectie uitgevoerd door
                      secTitle('Inspectie uitgevoerd door'),
                      lv('Naam bedrijf', inspectorCompany),
                      lv('Adres', generalData?.inspectorAddress ?? ''),
                      lv('Plaats',
                          generalData?.inspectorPostalCity ?? ''),
                      lv('Telefoon',
                          generalData?.inspectorPhone ?? ''),
                      lv('E-mail',
                          generalData?.inspectorEmail ?? ''),

                      pw.SizedBox(height: 20),

                      // Body paragraph (edited by user on screen)
                      if (meldingstekst.isNotEmpty)
                        pw.Text(
                          meldingstekst,
                          style: const pw.TextStyle(fontSize: labelFs),
                        ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );

    // ── Page 2 ─────────────────────────────────────────────────────────
    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: pw.EdgeInsets.zero,
        build: (ctx) {
          final photo1Exists = defect.photo1Path != null &&
              File(defect.photo1Path!).existsSync();
          final photo2Exists = defect.photo2Path != null &&
              File(defect.photo2Path!).existsSync();

          pw.Widget sigBox(String base64) {
            if (base64.isNotEmpty) {
              return pw.Container(
                height: 90,
                decoration: pw.BoxDecoration(
                    border: pw.Border.all(color: PdfColors.grey400)),
                child: pw.Image(
                  pw.MemoryImage(base64Decode(base64)),
                  fit: pw.BoxFit.contain,
                ),
              );
            }
            return pw.Container(
              height: 90,
              decoration: pw.BoxDecoration(
                  border: pw.Border.all(color: PdfColors.grey400)),
            );
          }

          return pw.Stack(
            children: [
              pw.Positioned(
                left: 0,
                top: 0,
                child: pw.Container(
                    width: pageW, height: pageH, color: bgColor),
              ),
              pw.Positioned(
                left: pad,
                top: pad,
                child: pw.SizedBox(
                  width: contentW,
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pageHeader('2 van 2'),
                      pw.SizedBox(height: 14),

                      // Red classification banner
                      pw.Container(
                        color: PdfColors.red,
                        padding: const pw.EdgeInsets.symmetric(
                            horizontal: 8, vertical: 7),
                        child: pw.Row(
                          mainAxisAlignment:
                              pw.MainAxisAlignment.spaceBetween,
                          children: [
                            pw.Text(
                              '$defectNumber',
                              style: pw.TextStyle(
                                color: PdfColors.white,
                                fontWeight: pw.FontWeight.bold,
                                fontSize: 13,
                              ),
                            ),
                            pw.Text(
                              defect.classification.toLowerCase(),
                              style: pw.TextStyle(
                                color: PdfColors.white,
                                fontWeight: pw.FontWeight.bold,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),

                      pw.SizedBox(height: 14),

                      // Photos
                      if (photo1Exists || photo2Exists)
                        pw.SizedBox(
                          height: 190,
                          child: pw.Row(
                            crossAxisAlignment:
                                pw.CrossAxisAlignment.stretch,
                            children: [
                              if (photo1Exists)
                                pw.Expanded(
                                  child: pw.Container(
                                    color: PdfColors.white,
                                    margin: photo2Exists
                                        ? const pw.EdgeInsets.only(
                                            right: 6)
                                        : pw.EdgeInsets.zero,
                                    padding:
                                        const pw.EdgeInsets.all(6),
                                    child: pw.Image(
                                      pw.MemoryImage(
                                        File(defect.photo1Path!)
                                            .readAsBytesSync(),
                                      ),
                                      fit: pw.BoxFit.contain,
                                    ),
                                  ),
                                ),
                              if (photo2Exists)
                                pw.Expanded(
                                  child: pw.Container(
                                    color: PdfColors.white,
                                    margin: photo1Exists
                                        ? const pw.EdgeInsets.only(
                                            left: 6)
                                        : pw.EdgeInsets.zero,
                                    padding:
                                        const pw.EdgeInsets.all(6),
                                    child: pw.Image(
                                      pw.MemoryImage(
                                        File(defect.photo2Path!)
                                            .readAsBytesSync(),
                                      ),
                                      fit: pw.BoxFit.contain,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),

                      pw.SizedBox(height: 14),

                      // Opmerkingen
                      pw.Text(
                        'Opmerkingen',
                        style: pw.TextStyle(
                          fontSize: 11,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                      pw.SizedBox(height: 4),
                      pw.Container(
                        width: contentW,
                        height: 55,
                        color: PdfColors.white,
                        padding: const pw.EdgeInsets.all(6),
                        child: opmerkingen.isNotEmpty
                            ? pw.Text(opmerkingen,
                                style: const pw.TextStyle(
                                    fontSize: labelFs))
                            : null,
                      ),

                      pw.SizedBox(height: 16),

                      // Datum row
                      pw.Row(
                        children: [
                          pw.Text(
                            'Datum',
                            style: pw.TextStyle(
                                fontSize: 11,
                                fontWeight: pw.FontWeight.bold),
                          ),
                          pw.SizedBox(width: 8),
                          pw.Container(
                            width: 130,
                            height: 22,
                            decoration: pw.BoxDecoration(
                                border: pw.Border.all(
                                    color: PdfColors.grey400)),
                            padding: const pw.EdgeInsets.symmetric(
                                horizontal: 5, vertical: 3),
                            child: pw.Text(printdatum,
                                style: const pw.TextStyle(
                                    fontSize: labelFs)),
                          ),
                        ],
                      ),

                      pw.SizedBox(height: 12),

                      // Signature row
                      pw.Row(
                        crossAxisAlignment:
                            pw.CrossAxisAlignment.start,
                        children: [
                          pw.Expanded(
                            child: pw.Column(
                              crossAxisAlignment:
                                  pw.CrossAxisAlignment.start,
                              children: [
                                pw.Text(
                                  'Naam inspecteur',
                                  style: pw.TextStyle(
                                      fontSize: 11,
                                      fontWeight:
                                          pw.FontWeight.bold),
                                ),
                                pw.SizedBox(height: 4),
                                pw.Container(
                                  height: 22,
                                  decoration: pw.BoxDecoration(
                                      border: pw.Border.all(
                                          color:
                                              PdfColors.grey400)),
                                  padding: const pw.EdgeInsets
                                      .symmetric(
                                          horizontal: 5,
                                          vertical: 3),
                                  child: pw.Text(naamInspecteur,
                                      style: const pw.TextStyle(
                                          fontSize: labelFs)),
                                ),
                                pw.SizedBox(height: 8),
                                pw.Text(
                                  'Handtekening',
                                  style: pw.TextStyle(
                                      fontSize: 11,
                                      fontWeight:
                                          pw.FontWeight.bold),
                                ),
                                pw.SizedBox(height: 4),
                                sigBox(handtekeningInspecteurBase64),
                              ],
                            ),
                          ),
                          pw.SizedBox(width: 20),
                          pw.Expanded(
                            child: pw.Column(
                              crossAxisAlignment:
                                  pw.CrossAxisAlignment.start,
                              children: [
                                pw.Text(
                                  'Naam klant',
                                  style: pw.TextStyle(
                                      fontSize: 11,
                                      fontWeight:
                                          pw.FontWeight.bold),
                                ),
                                pw.SizedBox(height: 4),
                                pw.Container(
                                  height: 22,
                                  decoration: pw.BoxDecoration(
                                      border: pw.Border.all(
                                          color:
                                              PdfColors.grey400)),
                                  padding: const pw.EdgeInsets
                                      .symmetric(
                                          horizontal: 5,
                                          vertical: 3),
                                  child: pw.Text(naamKlant,
                                      style: const pw.TextStyle(
                                          fontSize: labelFs)),
                                ),
                                pw.SizedBox(height: 8),
                                pw.Text(
                                  'Handtekening',
                                  style: pw.TextStyle(
                                      fontSize: 11,
                                      fontWeight:
                                          pw.FontWeight.bold),
                                ),
                                pw.SizedBox(height: 4),
                                sigBox(handtekeningKlantBase64),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );

    final dir = await PhotoService().getExportsDir();
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final filePath = p.join(
        dir, '${inspectionId}_melding_${defect.id}_$timestamp.pdf');
    await File(filePath).writeAsBytes(await pdf.save());
    return filePath;
  }

  pw.Widget _signatoryBlock(
    String title,
    String naam,
    String functie,
    String datum,
    String handtekeningBase64,
  ) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(title,
            style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold)),
        pw.SizedBox(height: 4),
        if (naam.isNotEmpty) _labelValue('Naam', naam),
        if (functie.isNotEmpty) _labelValue('Functie', functie),
        if (datum.isNotEmpty) _labelValue('Datum', datum),
        pw.SizedBox(height: 6),
        if (handtekeningBase64.isNotEmpty)
          pw.Container(
            height: 60,
            width: 160,
            decoration: pw.BoxDecoration(
              border: pw.Border.all(color: PdfColors.grey400),
            ),
            child: pw.Image(
              pw.MemoryImage(base64Decode(handtekeningBase64)),
              fit: pw.BoxFit.contain,
            ),
          )
        else
          pw.Container(
            height: 60,
            width: 160,
            decoration: pw.BoxDecoration(
              border: pw.Border.all(color: PdfColors.grey400),
            ),
          ),
      ],
    );
  }
}
