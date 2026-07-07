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
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';
import 'package:signature/signature.dart';
import '../models/company_inspector.dart';
import '../models/defect.dart';
import '../services/database_service.dart';
import '../services/pdf_export_service.dart';
import '../widgets/custom_text_field.dart';
import '../widgets/section_header.dart';

class MeldingGevaarlijkeSituatiePage extends StatefulWidget {
  final int inspectionId;
  final Defect defect;
  final int defectNumber;

  const MeldingGevaarlijkeSituatiePage({
    super.key,
    required this.inspectionId,
    required this.defect,
    required this.defectNumber,
  });

  @override
  State<MeldingGevaarlijkeSituatiePage> createState() =>
      _MeldingGevaarlijkeSituatiePageState();
}

class _MeldingGevaarlijkeSituatiePageState
    extends State<MeldingGevaarlijkeSituatiePage> {
  final _db = DatabaseService();

  final _verantwoordelijkeNaamCtrl = TextEditingController();
  final _verantwoordelijkeTelCtrl = TextEditingController();
  final _meldingstekstCtrl = TextEditingController();
  final _opmerkingenCtrl = TextEditingController();
  final _naamInspecteurCtrl = TextEditingController();
  final _naamKlantCtrl = TextEditingController();

  late final SignatureController _sigInspecteur = SignatureController(
    penStrokeWidth: 2,
    penColor: Colors.black,
    exportBackgroundColor: Colors.white,
  );
  late final SignatureController _sigKlant = SignatureController(
    penStrokeWidth: 2,
    penColor: Colors.black,
    exportBackgroundColor: Colors.white,
  );

  String _savedSigInspecteur = '';
  String _savedSigKlant = '';

  List<CompanyInspector> _inspectors = [];
  bool _loading = true;
  bool _generating = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final inspectors = await _db.getCompanyInspectors();
    final assessment = await _db.getFinalAssessment(widget.inspectionId);
    final generalData = await _db.getGeneralData(widget.inspectionId);

    // Pre-fill inspector name from assessment if available
    final preFilledName = assessment?.naam1.isNotEmpty == true
        ? assessment!.naam1
        : (assessment?.naam2.isNotEmpty == true ? assessment!.naam2 : '');
    final preFilledSig = assessment?.handtekening1.isNotEmpty == true
        ? assessment!.handtekening1
        : (assessment?.handtekening2.isNotEmpty == true
            ? assessment!.handtekening2
            : '');

    final inspectionDate = DateFormat('dd-MM-yyyy').format(DateTime.now());
    final locStreet = generalData?.inspectionAddressStreet ?? '';
    final inspectorCompany = generalData?.inspectorCompany ?? '';

    final tekst = StringBuffer();
    tekst.write('Op d.d. $inspectionDate heeft onze inspecteur');
    if (locStreet.isNotEmpty) tekst.write(' op de locatie $locStreet');
    tekst.write(' de onderstaande gevaarlijke situatie geconstateerd.\n\n');
    tekst.write(
        'De contactpersoon neemt ter kennisgeving aan en is verantwoordelijke voor opvolging van de bovengenoemde gevaarlijke situatie zodat de situatie wordt opgelost.');
    if (inspectorCompany.isNotEmpty) {
      tekst.write(
          '\n\nMail direct naar $inspectorCompany t.a.v. de inspectieverantwoordelijke en naar de contactpersoon.');
    }

    if (mounted) {
      setState(() {
        _inspectors = inspectors;
        _naamInspecteurCtrl.text = preFilledName;
        _savedSigInspecteur = preFilledSig;
        _meldingstekstCtrl.text = tekst.toString();
        _loading = false;
      });
    }
  }

  Future<String> _exportSignature(SignatureController ctrl) async {
    if (ctrl.isEmpty) return '';
    final bytes = await ctrl.toPngBytes();
    if (bytes == null) return '';
    return base64Encode(bytes);
  }

  Future<void> _saveSigInspecteur() async {
    final b64 = await _exportSignature(_sigInspecteur);
    if (b64.isNotEmpty) {
      setState(() => _savedSigInspecteur = b64);
      _sigInspecteur.clear();
    }
  }

  Future<void> _saveSigKlant() async {
    final b64 = await _exportSignature(_sigKlant);
    if (b64.isNotEmpty) {
      setState(() => _savedSigKlant = b64);
      _sigKlant.clear();
    }
  }

  Future<void> _pickInspector() async {
    if (_inspectors.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text(
                'Geen inspecteurs beschikbaar. Voeg eerst een inspecteur toe in Bedrijfsgegevens.')),
      );
      return;
    }

    final inspector = await showDialog<CompanyInspector>(
      context: context,
      builder: (ctx) => SimpleDialog(
        title: const Text('Kies inspecteur'),
        children: _inspectors.map((insp) {
          final hasSig = insp.handtekening.isNotEmpty;
          return SimpleDialogOption(
            onPressed: () => Navigator.pop(ctx, insp),
            child: Row(
              children: [
                Icon(
                  hasSig ? Icons.draw : Icons.person_outline,
                  size: 20,
                  color: hasSig ? const Color(0xFF1976D2) : Colors.grey,
                ),
                const SizedBox(width: 10),
                Expanded(child: Text(insp.name)),
                if (hasSig)
                  const Text('handtekening opgeslagen',
                      style: TextStyle(fontSize: 11, color: Colors.grey)),
              ],
            ),
          );
        }).toList(),
      ),
    );

    if (inspector == null || !mounted) return;
    setState(() {
      _naamInspecteurCtrl.text = inspector.name;
      if (inspector.handtekening.isNotEmpty) {
        _savedSigInspecteur = inspector.handtekening;
        _sigInspecteur.clear();
      }
    });
  }

  Future<String?> _generatePdf() async {
    setState(() => _generating = true);
    try {
      final path = await PdfExportService().generateMeldingGevaarlijkeSituatiePdf(
        inspectionId: widget.inspectionId,
        defect: widget.defect,
        defectNumber: widget.defectNumber,
        installatieverantwoordelijkeNaam: _verantwoordelijkeNaamCtrl.text,
        installatieverantwoordelijkeTelefoon: _verantwoordelijkeTelCtrl.text,
        meldingstekst: _meldingstekstCtrl.text,
        opmerkingen: _opmerkingenCtrl.text,
        naamInspecteur: _naamInspecteurCtrl.text,
        handtekeningInspecteurBase64: _savedSigInspecteur,
        naamKlant: _naamKlantCtrl.text,
        handtekeningKlantBase64: _savedSigKlant,
      );
      return path;
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('PDF genereren mislukt: $e'),
              backgroundColor: Colors.red),
        );
      }
      return null;
    } finally {
      if (mounted) setState(() => _generating = false);
    }
  }

  Future<void> _onGeneratePdf() async {
    final path = await _generatePdf();
    if (path == null || !mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('PDF gegenereerd'),
        action: SnackBarAction(
          label: 'Delen',
          onPressed: () => Share.shareXFiles([XFile(path)],
              subject: 'Melding gevaarlijke situatie'),
        ),
      ),
    );
  }

  Future<void> _onMailPdf() async {
    final path = await _generatePdf();
    if (path == null || !mounted) return;
    await Share.shareXFiles(
      [XFile(path)],
      subject: 'Melding gevaarlijke situatie',
    );
  }

  @override
  void dispose() {
    _verantwoordelijkeNaamCtrl.dispose();
    _verantwoordelijkeTelCtrl.dispose();
    _meldingstekstCtrl.dispose();
    _opmerkingenCtrl.dispose();
    _naamInspecteurCtrl.dispose();
    _naamKlantCtrl.dispose();
    _sigInspecteur.dispose();
    _sigKlant.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Melding gevaarlijke situatie')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Melding gevaarlijke situatie')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Info banner
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                border: Border.all(color: Colors.red.shade200),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(Icons.warning, color: Colors.red.shade700, size: 20),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Gevaarlijke situatie — classificatie ${widget.defect.classification}',
                      style: TextStyle(
                          color: Colors.red.shade800,
                          fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Installatieverantwoordelijke
            const SectionHeader(title: 'Installatieverantwoordelijke'),
            CustomTextField(
              label: 'Naam',
              controller: _verantwoordelijkeNaamCtrl,
              onChanged: (_) {},
            ),
            CustomTextField(
              label: 'Telefoonnummer',
              controller: _verantwoordelijkeTelCtrl,
              onChanged: (_) {},
            ),

            const SizedBox(height: 8),

            // Standaard meldingstekst
            const SectionHeader(title: 'Meldingstekst'),
            CustomTextField(
              label: 'Meldingstekst',
              controller: _meldingstekstCtrl,
              onChanged: (_) {},
              maxLines: 6,
            ),

            const SizedBox(height: 8),

            // Opmerkingen
            const SectionHeader(title: 'Opmerkingen'),
            CustomTextField(
              label: 'Opmerkingen',
              controller: _opmerkingenCtrl,
              onChanged: (_) {},
              maxLines: 4,
            ),

            const SizedBox(height: 8),

            // Inspecteur + Klant naast elkaar
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Inspecteur ──────────────────────────────────────────
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        children: [
                          const Expanded(
                              child: SectionHeader(title: 'Inspecteur')),
                          TextButton.icon(
                            onPressed: _pickInspector,
                            icon: const Icon(Icons.person_search, size: 16),
                            label: const Text('Kies'),
                            style: TextButton.styleFrom(
                              foregroundColor: const Color(0xFF1976D2),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 6, vertical: 4),
                            ),
                          ),
                        ],
                      ),
                      CustomTextField(
                        label: 'Naam inspecteur',
                        controller: _naamInspecteurCtrl,
                        onChanged: (_) {},
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Handtekening',
                        style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: Color(0xFF1976D2)),
                      ),
                      const SizedBox(height: 4),
                      if (_savedSigInspecteur.isNotEmpty)
                        _SavedSigCard(
                          base64Png: _savedSigInspecteur,
                          onClear: () =>
                              setState(() => _savedSigInspecteur = ''),
                        )
                      else
                        _SigPad(
                          controller: _sigInspecteur,
                          onSave: _saveSigInspecteur,
                        ),
                    ],
                  ),
                ),

                const SizedBox(width: 12),

                // ── Klant ───────────────────────────────────────────────
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const SectionHeader(title: 'Klant'),
                      CustomTextField(
                        label: 'Naam klant',
                        controller: _naamKlantCtrl,
                        onChanged: (_) {},
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Handtekening',
                        style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: Color(0xFF1976D2)),
                      ),
                      const SizedBox(height: 4),
                      if (_savedSigKlant.isNotEmpty)
                        _SavedSigCard(
                          base64Png: _savedSigKlant,
                          onClear: () => setState(() => _savedSigKlant = ''),
                        )
                      else
                        _SigPad(
                          controller: _sigKlant,
                          onSave: _saveSigKlant,
                        ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // Action buttons
            if (_generating)
              const Center(child: CircularProgressIndicator())
            else
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _onGeneratePdf,
                      icon: const Icon(Icons.picture_as_pdf_outlined),
                      label: const Text('Genereer PDF'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: _onMailPdf,
                      icon: const Icon(Icons.mail_outline),
                      label: const Text('Mail PDF'),
                    ),
                  ),
                ],
              ),

            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}

class _SigPad extends StatelessWidget {
  final SignatureController controller;
  final VoidCallback onSave;

  const _SigPad({required this.controller, required this.onSave});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          height: 150,
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.shade400),
            borderRadius: BorderRadius.circular(4),
            color: Colors.white,
          ),
          child: Stack(
            children: [
              Signature(controller: controller, backgroundColor: Colors.white),
              ListenableBuilder(
                listenable: controller,
                builder: (_, _) {
                  if (controller.isNotEmpty) return const SizedBox.shrink();
                  return Center(
                    child: Text(
                      'Teken hier',
                      style: TextStyle(
                          color: Colors.grey.shade400, fontSize: 14),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
        const SizedBox(height: 6),
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            TextButton.icon(
              onPressed: () => controller.clear(),
              icon: const Icon(Icons.delete_outline, size: 18),
              label: const Text('Wissen'),
              style: TextButton.styleFrom(foregroundColor: Colors.grey),
            ),
            const SizedBox(width: 8),
            ElevatedButton.icon(
              onPressed: onSave,
              icon: const Icon(Icons.check, size: 18),
              label: const Text('Opslaan'),
            ),
          ],
        ),
      ],
    );
  }
}

class _SavedSigCard extends StatelessWidget {
  final String base64Png;
  final VoidCallback onClear;

  const _SavedSigCard({required this.base64Png, required this.onClear});

  @override
  Widget build(BuildContext context) {
    final bytes = base64Decode(base64Png);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          height: 150,
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.shade400),
            borderRadius: BorderRadius.circular(4),
            color: Colors.white,
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: Image.memory(bytes, fit: BoxFit.contain),
          ),
        ),
        const SizedBox(height: 6),
        Align(
          alignment: Alignment.centerRight,
          child: TextButton.icon(
            onPressed: onClear,
            icon: const Icon(Icons.delete_outline, size: 18),
            label: const Text('Handtekening wissen'),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
          ),
        ),
      ],
    );
  }
}
