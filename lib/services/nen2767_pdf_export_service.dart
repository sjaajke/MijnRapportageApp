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

import 'dart:io';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path/path.dart' as p;
import 'package:share_plus/share_plus.dart';
import '../models/nen_bouwdeel.dart';
import '../models/nen_gebrek.dart';
import 'database_service.dart';
import 'nen2767_scoring_service.dart';
import 'photo_service.dart';

/// Genereert het NEN 2767-conditiemetingsrapport als PDF: objectgegevens,
/// bouwdeel-structuur en gebreken met ernst/omvang/intensiteit/conditiescore.
class Nen2767PdfExportService {
  final _db = DatabaseService();

  PdfColor _scoreColor(int score) {
    switch (score) {
      case 1:
        return PdfColors.green;
      case 2:
        return PdfColors.lightGreen;
      case 3:
        return PdfColors.yellow700;
      case 4:
        return PdfColors.orange;
      case 5:
        return PdfColors.deepOrange;
      default:
        return PdfColors.red;
    }
  }

  Future<String> generatePdf(int inspectionId) async {
    final inspection = await _db.getInspection(inspectionId);
    final generalData = await _db.getGeneralData(inspectionId);
    final objectgegevens = await _db.getNenObjectgegevens(inspectionId);
    final bouwdelen = await _db.getNenBouwdelen(inspectionId);
    final gebreken = await _db.getNenGebrekenVoorInspectie(inspectionId);

    final gebrekenPerBouwdeel = <int, List<NenGebrek>>{};
    for (final g in gebreken) {
      gebrekenPerBouwdeel.putIfAbsent(g.bouwdeelId, () => []).add(g);
    }
    final bouwdeelById = {for (final b in bouwdelen) b.id!: b};

    String naamPad(NenBouwdeel node) {
      final parts = <String>[node.naam];
      var current = node;
      while (current.parentId != null &&
          bouwdeelById.containsKey(current.parentId)) {
        current = bouwdeelById[current.parentId]!;
        parts.insert(0, current.naam);
      }
      return parts.join(' > ');
    }

    final pdf = pw.Document();
    final datumFmt = DateFormat('dd-MM-yyyy');

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        header: (context) => pw.Text(
          'NEN 2767-conditiemeting',
          style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold),
        ),
        build: (context) => [
          pw.SizedBox(height: 8),
          pw.Text(
            generalData?.inspectionAddressName.isNotEmpty == true
                ? generalData!.inspectionAddressName
                : 'Object #$inspectionId',
            style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold),
          ),
          if (objectgegevens != null) ...[
            pw.SizedBox(height: 4),
            pw.Text([
              if (objectgegevens.bouwjaar.isNotEmpty)
                'Bouwjaar: ${objectgegevens.bouwjaar}',
              if (objectgegevens.gebruiksfunctie.isNotEmpty)
                'Gebruiksfunctie: ${objectgegevens.gebruiksfunctie}',
              if (objectgegevens.objectcode.isNotEmpty)
                'Objectcode: ${objectgegevens.objectcode}',
            ].join('   ·   ')),
          ],
          pw.SizedBox(height: 4),
          pw.Text(
            'Datum inspectie: ${inspection != null ? datumFmt.format(DateTime.tryParse(inspection.createdAt) ?? DateTime.now()) : '-'}',
          ),
          pw.SizedBox(height: 16),
          for (final bouwdeel in bouwdelen)
            if ((gebrekenPerBouwdeel[bouwdeel.id] ?? const []).isNotEmpty) ...[
              pw.SizedBox(height: 12),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text(
                    naamPad(bouwdeel),
                    style: pw.TextStyle(
                        fontSize: 12, fontWeight: pw.FontWeight.bold),
                  ),
                  pw.Container(
                    padding: const pw.EdgeInsets.symmetric(
                        horizontal: 8, vertical: 3),
                    decoration: pw.BoxDecoration(
                      color: _scoreColor(Nen2767ScoringService
                          .aggregeerConditiescore(
                              gebrekenPerBouwdeel[bouwdeel.id]!)),
                      borderRadius: pw.BorderRadius.circular(4),
                    ),
                    child: pw.Text(
                      'Conditiescore: ${Nen2767ScoringService.aggregeerConditiescore(gebrekenPerBouwdeel[bouwdeel.id]!)}',
                      style: pw.TextStyle(
                          color: PdfColors.white,
                          fontWeight: pw.FontWeight.bold,
                          fontSize: 10),
                    ),
                  ),
                ],
              ),
              pw.SizedBox(height: 4),
              pw.TableHelper.fromTextArray(
                headers: [
                  'Gebrek',
                  'Ernst',
                  'Intensiteit',
                  'Omvang',
                  'Score',
                  'Locatie',
                  'Inspecteur',
                ],
                data: [
                  for (final g in gebrekenPerBouwdeel[bouwdeel.id]!)
                    [
                      g.gebrekOmschrijving,
                      NenGebrek.ernstLabels[g.ernst] ?? g.ernst,
                      g.intensiteit,
                      '${g.omvangPercentage.toStringAsFixed(0)}%',
                      '${g.conditiescore}',
                      g.locatieDetail,
                      g.inspecteur,
                    ],
                ],
                cellStyle: pw.TextStyle(fontSize: 8),
                headerStyle:
                    pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold),
                cellPadding: const pw.EdgeInsets.all(3),
              ),
              for (final g in gebrekenPerBouwdeel[bouwdeel.id]!)
                if (g.toelichting.isNotEmpty)
                  pw.Padding(
                    padding: const pw.EdgeInsets.only(top: 2, bottom: 2),
                    child: pw.Text(
                      '${g.gebrekOmschrijving}: ${g.toelichting}',
                      style: pw.TextStyle(
                          fontSize: 8, fontStyle: pw.FontStyle.italic),
                    ),
                  ),
            ],
        ],
      ),
    );

    final dir = await PhotoService().getExportsDir();
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final filePath =
        p.join(dir, 'nen2767_${inspectionId}_$timestamp.pdf');
    final file = File(filePath);
    await file.writeAsBytes(await pdf.save());
    return filePath;
  }

  Future<void> exportAndShare(int inspectionId) async {
    final path = await generatePdf(inspectionId);
    await Share.shareXFiles([XFile(path)]);
  }
}
