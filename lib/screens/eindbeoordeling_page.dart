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
import 'package:signature/signature.dart';
import '../l10n/app_localizations.dart';
import '../models/company_inspector.dart';
import '../models/defect.dart';
import '../models/final_assessment.dart';
import '../models/title_page.dart';
import '../services/database_service.dart';
import '../widgets/custom_text_field.dart';
import '../widgets/section_header.dart';

class EindbeoordelingPage extends StatefulWidget {
  final int inspectionId;

  const EindbeoordelingPage({super.key, required this.inspectionId});

  @override
  State<EindbeoordelingPage> createState() => _EindbeoordelingPageState();
}

class _EindbeoordelingPageState extends State<EindbeoordelingPage> {
  final _db = DatabaseService();

  final _eindbeoordeling = TextEditingController();
  final _volgendInspectie = TextEditingController();
  final _naam1 = TextEditingController();
  final _functie1 = TextEditingController();
  final _datum1 = TextEditingController();
  final _naam2 = TextEditingController();
  final _functie2 = TextEditingController();
  final _datum2 = TextEditingController();

  late final SignatureController _sig1 = SignatureController(
    penStrokeWidth: 2,
    penColor: Colors.black,
    exportBackgroundColor: Colors.white,
  );
  late final SignatureController _sig2 = SignatureController(
    penStrokeWidth: 2,
    penColor: Colors.black,
    exportBackgroundColor: Colors.white,
  );

  FinalAssessment? _assessment;
  TitlePage? _titlePage;
  List<CompanyInspector> _inspectors = [];
  Map<String, int> _counts = {};
  String _savedSig1 = '';
  String _savedSig2 = '';
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final inspectors = await _db.getCompanyInspectors();
    final tp = await _db.getTitlePage(widget.inspectionId);
    var a = await _db.getFinalAssessment(widget.inspectionId);
    if (a == null) {
      await _db.insertFinalAssessment(
          FinalAssessment(inspectionId: widget.inspectionId));
      a = await _db.getFinalAssessment(widget.inspectionId);
    }
    if (a != null) {
      _eindbeoordeling.text = a.eindbeoordeling;
      _volgendInspectie.text = a.volgendInspectie;
      _naam1.text = a.naam1;
      _functie1.text = a.functie1;
      _datum1.text = a.datum1;
      _naam2.text = a.naam2;
      _functie2.text = a.functie2;
      _datum2.text = a.datum2;
    }
    final defects = await _db.getDefects(widget.inspectionId);
    final counts = <String, int>{};
    for (final c in Defect.classifications) {
      counts[c] = defects.where((d) => d.classification == c).length;
    }
    setState(() {
      _assessment = a;
      _titlePage = tp;
      _inspectors = inspectors;
      _counts = counts;
      _savedSig1 = a?.handtekening1 ?? '';
      _savedSig2 = a?.handtekening2 ?? '';
      _loading = false;
    });
  }

  Future<String> _exportSignature(SignatureController ctrl) async {
    if (ctrl.isEmpty) return '';
    final bytes = await ctrl.toPngBytes();
    if (bytes == null) return '';
    return base64Encode(bytes);
  }

  Future<void> _autoSave() async {
    if (_assessment == null) return;
    final updated = _assessment!.copyWith(
      eindbeoordeling: _eindbeoordeling.text,
      volgendInspectie: _volgendInspectie.text,
      naam1: _naam1.text,
      functie1: _functie1.text,
      datum1: _datum1.text,
      handtekening1: _savedSig1,
      naam2: _naam2.text,
      functie2: _functie2.text,
      datum2: _datum2.text,
      handtekening2: _savedSig2,
    );
    await _db.updateFinalAssessment(updated);
    _assessment = updated;
  }

  // Pick an inspector and load name + saved signature
  Future<void> _pickInspector(int slot) async {
    if (_inspectors.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Geen inspecteurs beschikbaar. '
                'Voeg eerst een inspecteur toe in Bedrijfsgegevens.')),
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

    if (inspector == null) return;

    if (slot == 1) {
      setState(() {
        _naam1.text = inspector.name;
        if (inspector.functie.isNotEmpty) _functie1.text = inspector.functie;
        if (inspector.handtekening.isNotEmpty) {
          _savedSig1 = inspector.handtekening;
          _sig1.clear();
        }
      });
    } else {
      setState(() {
        _naam2.text = inspector.name;
        if (inspector.functie.isNotEmpty) _functie2.text = inspector.functie;
        if (inspector.handtekening.isNotEmpty) {
          _savedSig2 = inspector.handtekening;
          _sig2.clear();
        }
      });
    }
    await _autoSave();
  }

  Future<void> _saveSig1() async {
    final b64 = await _exportSignature(_sig1);
    if (b64.isNotEmpty) {
      setState(() => _savedSig1 = b64);
      _sig1.clear();
      await _autoSave();
    }
  }

  Future<void> _saveSig2() async {
    final b64 = await _exportSignature(_sig2);
    if (b64.isNotEmpty) {
      setState(() => _savedSig2 = b64);
      _sig2.clear();
      await _autoSave();
    }
  }

  void _clearSig1() {
    setState(() => _savedSig1 = '');
    _sig1.clear();
    _autoSave();
  }

  void _clearSig2() {
    setState(() => _savedSig2 = '');
    _sig2.clear();
    _autoSave();
  }

  Future<void> _showInspectieTermijnPicker() async {
    String? selectedNorm;
    int? selectedJaren;

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) {
          return AlertDialog(
            title: const Text('Inspectie termijn'),
            content: SizedBox(
              width: double.maxFinite,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Inspectie termijn volgens:',
                    style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                  ),
                  const SizedBox(height: 4),
                  RadioGroup<String>(
                    groupValue: selectedNorm,
                    onChanged: (v) =>
                        setDialogState(() => selectedNorm = v),
                    child: Column(
                      children: ['Polisvoorwaarde', 'NEN 3140', 'NTA 8220']
                          .map(
                            (norm) => RadioListTile<String>(
                              title: Text(norm),
                              value: norm,
                              dense: true,
                              contentPadding: EdgeInsets.zero,
                            ),
                          )
                          .toList(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Termijn:',
                    style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: List.generate(5, (i) {
                      final jaar = i + 1;
                      final selected = selectedJaren == jaar;
                      return GestureDetector(
                        onTap: () =>
                            setDialogState(() => selectedJaren = jaar),
                        child: Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: selected
                                ? const Color(0xFF1976D2)
                                : Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: selected
                                  ? const Color(0xFF1976D2)
                                  : Colors.grey.shade300,
                            ),
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            '$jaar j',
                            style: TextStyle(
                              color:
                                  selected ? Colors.white : Colors.black87,
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      );
                    }),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Annuleren'),
              ),
              ElevatedButton(
                onPressed: selectedNorm != null && selectedJaren != null
                    ? () {
                        final fmt = DateFormat('dd-MM-yyyy');
                        final baseDateStr =
                            (_titlePage?.inspectionDateEnd.isNotEmpty == true)
                                ? _titlePage!.inspectionDateEnd
                                : (_titlePage?.inspectionDate ?? '');
                        DateTime? base;
                        try {
                          if (baseDateStr.isNotEmpty) {
                            base = fmt.parse(baseDateStr);
                          }
                        } catch (_) {}
                        final jaren = selectedJaren!;
                        if (base != null) {
                          final next = DateTime(
                              base.year + jaren, base.month, base.day);
                          _volgendInspectie.text =
                              'De inspectietermijn volgens $selectedNorm vastgesteld op $jaren jaar. '
                              'De volgende inspectie moet voor ${fmt.format(next)} worden uitgevoerd.';
                        } else {
                          _volgendInspectie.text =
                              'De inspectietermijn volgens $selectedNorm vastgesteld op $jaren jaar.';
                        }
                        _autoSave();
                        Navigator.pop(ctx);
                      }
                    : null,
                child: const Text('Toepassen'),
              ),
            ],
          );
        },
      ),
    );
  }

  @override
  void dispose() {
    _autoSave();
    _eindbeoordeling.dispose();
    _volgendInspectie.dispose();
    _naam1.dispose();
    _functie1.dispose();
    _datum1.dispose();
    _naam2.dispose();
    _functie2.dispose();
    _datum2.dispose();
    _sig1.dispose();
    _sig2.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Scaffold(
        appBar: AppBar(
            title: Text(AppLocalizations.of(context).finalAssessment)),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    final l10n = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.finalAssessment)),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SectionHeader(title: l10n.finalAssessment),
            CustomTextField(
              label: l10n.finalAssessment,
              controller: _eindbeoordeling,
              onChanged: (_) => _autoSave(),
              maxLines: 6,
            ),
            const SizedBox(height: 12),
            _ConstateringenTabel(counts: _counts),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 6.0),
              child: TextFormField(
                controller: _volgendInspectie,
                onChanged: (_) => _autoSave(),
                maxLines: 3,
                keyboardType: TextInputType.multiline,
                textInputAction: TextInputAction.newline,
                style: const TextStyle(fontSize: 14),
                decoration: InputDecoration(
                  labelText: l10n.nextInspection,
                  border: const OutlineInputBorder(),
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12.0, vertical: 12.0),
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.calendar_month,
                        color: Color(0xFF1976D2)),
                    tooltip: 'Inspectie termijn berekenen',
                    onPressed: _showInspectieTermijnPicker,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 8),

            _SignatorySection(
              number: 1,
              naamCtrl: _naam1,
              functieCtrl: _functie1,
              datumCtrl: _datum1,
              sigController: _sig1,
              savedSignature: _savedSig1,
              onFieldChanged: () => _autoSave(),
              onSaveSignature: _saveSig1,
              onClearSignature: _clearSig1,
              onPickInspector: () => _pickInspector(1),
              l10n: l10n,
            ),

            const SizedBox(height: 8),

            _SignatorySection(
              number: 2,
              naamCtrl: _naam2,
              functieCtrl: _functie2,
              datumCtrl: _datum2,
              sigController: _sig2,
              savedSignature: _savedSig2,
              onFieldChanged: () => _autoSave(),
              onSaveSignature: _saveSig2,
              onClearSignature: _clearSig2,
              onPickInspector: () => _pickInspector(2),
              l10n: l10n,
            ),

            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}

class _SignatorySection extends StatelessWidget {
  final int number;
  final TextEditingController naamCtrl;
  final TextEditingController functieCtrl;
  final TextEditingController datumCtrl;
  final SignatureController sigController;
  final String savedSignature;
  final VoidCallback onFieldChanged;
  final VoidCallback onSaveSignature;
  final VoidCallback onClearSignature;
  final VoidCallback onPickInspector;
  final AppLocalizations l10n;

  const _SignatorySection({
    required this.number,
    required this.naamCtrl,
    required this.functieCtrl,
    required this.datumCtrl,
    required this.sigController,
    required this.savedSignature,
    required this.onFieldChanged,
    required this.onSaveSignature,
    required this.onClearSignature,
    required this.onPickInspector,
    required this.l10n,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: SectionHeader(title: '${l10n.signatory} $number'),
            ),
            TextButton.icon(
              onPressed: onPickInspector,
              icon: const Icon(Icons.person_search, size: 18),
              label: const Text('Kies inspecteur'),
              style: TextButton.styleFrom(
                foregroundColor: const Color(0xFF1976D2),
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              ),
            ),
          ],
        ),
        CustomTextField(
          label: l10n.signatoryName,
          controller: naamCtrl,
          onChanged: (_) => onFieldChanged(),
        ),
        CustomTextField(
          label: l10n.signatoryFunction,
          controller: functieCtrl,
          onChanged: (_) => onFieldChanged(),
        ),
        CustomTextField(
          label: l10n.signatoryDate,
          controller: datumCtrl,
          onChanged: (_) => onFieldChanged(),
          hint: 'dd-mm-jjjj',
        ),
        const SizedBox(height: 8),
        Text(
          l10n.signature,
          style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: Color(0xFF1976D2)),
        ),
        const SizedBox(height: 4),
        if (savedSignature.isNotEmpty)
          _SavedSignatureCard(
            base64Png: savedSignature,
            onClear: onClearSignature,
            l10n: l10n,
          )
        else
          _SignaturePad(
            controller: sigController,
            onSave: onSaveSignature,
            l10n: l10n,
          ),
      ],
    );
  }
}

class _SignaturePad extends StatelessWidget {
  final SignatureController controller;
  final VoidCallback onSave;
  final AppLocalizations l10n;

  const _SignaturePad({
    required this.controller,
    required this.onSave,
    required this.l10n,
  });

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
              Signature(
                controller: controller,
                backgroundColor: Colors.white,
              ),
              ListenableBuilder(
                listenable: controller,
                builder: (context, _) {
                  if (controller.isNotEmpty) return const SizedBox.shrink();
                  return Center(
                    child: Text(
                      l10n.signHere,
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
              label: Text(l10n.save),
            ),
          ],
        ),
      ],
    );
  }
}

// ── Constateringen telling tabel ────────────────────────────────────────────

class _ConstateringenTabel extends StatelessWidget {
  final Map<String, int> counts;

  static const _colors = {
    'Rd': Color(0xFFEF5350),
    'Or': Color(0xFFFF9800),
    'Ge': Color(0xFFFFEE58),
    'Bl': Color(0xFF42A5F5),
    'Pa': Color(0xFFAB47BC),
    'Gr': Color(0xFF9E9E9E),
  };
  static const _textColors = {
    'Rd': Colors.white,
    'Or': Colors.white,
    'Ge': Color(0xFF5D4037),
    'Bl': Colors.white,
    'Pa': Colors.white,
    'Gr': Colors.white,
  };

  const _ConstateringenTabel({required this.counts});

  @override
  Widget build(BuildContext context) {
    final total = counts.values.fold(0, (s, v) => s + v);
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Overzicht constateringen',
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Color(0xFF1976D2),
              ),
            ),
            const SizedBox(height: 8),
            Table(
              border: TableBorder.all(color: Colors.grey.shade300, width: 0.5),
              columnWidths: const {
                0: FlexColumnWidth(),
                1: FlexColumnWidth(),
                2: FlexColumnWidth(),
                3: FlexColumnWidth(),
                4: FlexColumnWidth(),
                5: FlexColumnWidth(),
                6: IntrinsicColumnWidth(),
              },
              children: [
                TableRow(
                  children: [
                    ...Defect.classifications.map((c) => _headerCell(c)),
                    _headerCell('Totaal'),
                  ],
                ),
                TableRow(
                  children: [
                    ...Defect.classifications.map((c) => _countCell(c, counts[c] ?? 0)),
                    _totalCell(total),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _headerCell(String label) {
    final bg = _colors[label] ?? Colors.grey.shade200;
    final fg = _textColors[label] ?? Colors.black;
    return Container(
      color: bg,
      padding: const EdgeInsets.symmetric(vertical: 6),
      alignment: Alignment.center,
      child: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: fg,
        ),
      ),
    );
  }

  Widget _countCell(String classification, int count) {
    final isNonZero = count > 0;
    final bg = isNonZero ? (_colors[classification] ?? Colors.white).withAlpha(40) : Colors.white;
    return Container(
      color: bg,
      padding: const EdgeInsets.symmetric(vertical: 8),
      alignment: Alignment.center,
      child: Text(
        '$count',
        style: TextStyle(
          fontSize: 14,
          fontWeight: isNonZero ? FontWeight.bold : FontWeight.normal,
          color: isNonZero ? (_colors[classification] ?? Colors.black) : Colors.grey.shade400,
        ),
      ),
    );
  }

  Widget _totalCell(int total) {
    return Container(
      color: Colors.grey.shade50,
      padding: const EdgeInsets.symmetric(vertical: 8),
      alignment: Alignment.center,
      child: Text(
        '$total',
        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
      ),
    );
  }
}

class _SavedSignatureCard extends StatelessWidget {
  final String base64Png;
  final VoidCallback onClear;
  final AppLocalizations l10n;

  const _SavedSignatureCard({
    required this.base64Png,
    required this.onClear,
    required this.l10n,
  });

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
            label: Text(l10n.clearSignature),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
          ),
        ),
      ],
    );
  }
}
