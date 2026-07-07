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
import '../l10n/app_localizations.dart';
import '../models/report_template.dart';
import '../services/database_service.dart';
import '../widgets/custom_text_field.dart';

class ReportTemplateDetailPage extends StatefulWidget {
  final ReportTemplate? template;

  const ReportTemplateDetailPage({super.key, this.template});

  @override
  State<ReportTemplateDetailPage> createState() =>
      _ReportTemplateDetailPageState();
}

class _ReportTemplateDetailPageState extends State<ReportTemplateDetailPage> {
  final _db = DatabaseService();

  final _typeRapport = TextEditingController();
  final _rapporttitel = TextEditingController();
  final _subtitel = TextEditingController();
  final _inleiding = TextEditingController();
  final _tekstRapportVerklaring = TextEditingController();
  final _visueleInspectieTitel = TextEditingController();
  final _visueleInspectie = TextEditingController();
  final _visueleInspectieToelichting = TextEditingController();
  final _metingenTitel = TextEditingController();
  final _metingen = TextEditingController();
  final _metingenToelichting = TextEditingController();
  final _aanvullendOnderzoekTitel = TextEditingController();
  final _aanvullendOnderzoek = TextEditingController();
  final _aanvullendOnderzoekToelichting = TextEditingController();
  final _lijst4Titel = TextEditingController();
  final _lijst4 = TextEditingController();
  final _lijst4Toelichting = TextEditingController();
  final _vinklijstAfkeuringscriteria = TextEditingController();
  final _inspectieUitgevoerdVolgens = TextEditingController();
  final _elektrischMaterieelGetoetst = TextEditingController();
  final _inleidingToelichting = TextEditingController();
  final _volgendInspectie = TextEditingController();
  final _eindbeoordelingOKE = TextEditingController();
  final _meldingGevaarlijkeSituatie = TextEditingController();

  bool get _isNew => widget.template == null;

  @override
  void initState() {
    super.initState();
    final t = widget.template;
    if (t != null) {
      _typeRapport.text = t.typeRapport;
      _rapporttitel.text = t.rapporttitel;
      _subtitel.text = t.subtitel;
      _inleiding.text = t.inleiding;
      _tekstRapportVerklaring.text = t.tekstRapportVerklaring;
      _visueleInspectieTitel.text = t.visueleInspectieTitel;
      _visueleInspectie.text = t.visueleInspectie;
      _visueleInspectieToelichting.text = t.visueleInspectieToelichting;
      _metingenTitel.text = t.metingenTitel;
      _metingen.text = t.metingen;
      _metingenToelichting.text = t.metingenToelichting;
      _aanvullendOnderzoekTitel.text = t.aanvullendOnderzoekTitel;
      _aanvullendOnderzoek.text = t.aanvullendOnderzoek;
      _aanvullendOnderzoekToelichting.text = t.aanvullendOnderzoekToelichting;
      _lijst4Titel.text = t.lijst4Titel;
      _lijst4.text = t.lijst4;
      _lijst4Toelichting.text = t.lijst4Toelichting;
      _vinklijstAfkeuringscriteria.text = t.vinklijstAfkeuringscriteria;
      _inspectieUitgevoerdVolgens.text = t.inspectieUitgevoerdVolgens;
      _elektrischMaterieelGetoetst.text = t.elektrischMaterieelGetoetst;
      _inleidingToelichting.text = t.inleidingToelichting;
      _volgendInspectie.text = t.volgendInspectie;
      _eindbeoordelingOKE.text = t.eindbeoordelingOKE;
      _meldingGevaarlijkeSituatie.text = t.meldingGevaarlijkeSituatie;
    }
  }

  @override
  void dispose() {
    _typeRapport.dispose();
    _rapporttitel.dispose();
    _subtitel.dispose();
    _inleiding.dispose();
    _tekstRapportVerklaring.dispose();
    _visueleInspectieTitel.dispose();
    _visueleInspectie.dispose();
    _visueleInspectieToelichting.dispose();
    _metingenTitel.dispose();
    _metingen.dispose();
    _metingenToelichting.dispose();
    _aanvullendOnderzoekTitel.dispose();
    _aanvullendOnderzoek.dispose();
    _aanvullendOnderzoekToelichting.dispose();
    _lijst4Titel.dispose();
    _lijst4.dispose();
    _lijst4Toelichting.dispose();
    _vinklijstAfkeuringscriteria.dispose();
    _inspectieUitgevoerdVolgens.dispose();
    _elektrischMaterieelGetoetst.dispose();
    _inleidingToelichting.dispose();
    _volgendInspectie.dispose();
    _eindbeoordelingOKE.dispose();
    _meldingGevaarlijkeSituatie.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final template = ReportTemplate(
      id: widget.template?.id,
      typeRapport: _typeRapport.text.trim(),
      rapporttitel: _rapporttitel.text.trim(),
      subtitel: _subtitel.text.trim(),
      inleiding: _inleiding.text,
      tekstRapportVerklaring: _tekstRapportVerklaring.text,
      visueleInspectieTitel: _visueleInspectieTitel.text.trim(),
      visueleInspectie: _visueleInspectie.text,
      visueleInspectieToelichting: _visueleInspectieToelichting.text,
      metingenTitel: _metingenTitel.text.trim(),
      metingen: _metingen.text,
      metingenToelichting: _metingenToelichting.text,
      aanvullendOnderzoekTitel: _aanvullendOnderzoekTitel.text.trim(),
      aanvullendOnderzoek: _aanvullendOnderzoek.text,
      aanvullendOnderzoekToelichting: _aanvullendOnderzoekToelichting.text,
      lijst4Titel: _lijst4Titel.text.trim(),
      lijst4: _lijst4.text,
      lijst4Toelichting: _lijst4Toelichting.text,
      vinklijstAfkeuringscriteria: _vinklijstAfkeuringscriteria.text,
      inspectieUitgevoerdVolgens: _inspectieUitgevoerdVolgens.text,
      elektrischMaterieelGetoetst: _elektrischMaterieelGetoetst.text,
      inleidingToelichting: _inleidingToelichting.text,
      volgendInspectie: _volgendInspectie.text,
      eindbeoordelingOKE: _eindbeoordelingOKE.text,
      meldingGevaarlijkeSituatie: _meldingGevaarlijkeSituatie.text,
    );

    if (_isNew) {
      await _db.insertReportTemplate(template);
    } else {
      await _db.updateReportTemplate(template);
    }

    if (!mounted) return;
    Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(_isNew ? l10n.addReportTemplate : l10n.editReportTemplate),
        actions: [
          TextButton(
            onPressed: _save,
            child: Text(
              l10n.save,
              style: const TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ── Algemeen ────────────────────────────────────────────────────
            _Section(
              title: l10n.generalSection,
              initiallyExpanded: true,
              children: [
                CustomTextField(
                  label: l10n.reportType,
                  controller: _typeRapport,
                  hint: 'bijv. ~EPM_SCOPE_8_PI',
                ),
                CustomTextField(
                  label: l10n.reportTitleField,
                  controller: _rapporttitel,
                ),
                CustomTextField(
                  label: l10n.reportSubtitle,
                  controller: _subtitel,
                ),
              ],
            ),

            // ── Inleiding en verklaring ──────────────────────────────────
            _Section(
              title: 'Inleiding, getoets aan, uitgevoerd volgens, Eindbeoordeling',
              children: [
                CustomTextField(
                  label: l10n.reportIntroduction,
                  controller: _inleiding,
                  maxLines: 8,
                ),
                CustomTextField(
                  label: l10n.reportDeclaration,
                  controller: _tekstRapportVerklaring,
                  maxLines: 6,
                ),
                CustomTextField(
                  label: 'Eindbeoordeling_OKE',
                  controller: _eindbeoordelingOKE,
                  maxLines: 6,
                ),
                CustomTextField(
                  label: 'Volgende inspectie',
                  controller: _volgendInspectie,
                ),
                CustomTextField(
                  label: l10n.inspectieUitgevoerdVolgens,
                  controller: _inspectieUitgevoerdVolgens,
                  maxLines: 4,
                ),
                CustomTextField(
                  label: l10n.elektrischMaterieelGetoetst,
                  controller: _elektrischMaterieelGetoetst,
                  maxLines: 4,
                ),
                CustomTextField(
                  label: l10n.inleidingToelichting,
                  controller: _inleidingToelichting,
                  maxLines: 4,
                ),
              ],
            ),

            // ── Visuele inspectie ────────────────────────────────────────
            _Section(
              title: l10n.visualInspectionText,
              children: [
                CustomTextField(
                  label: l10n.visualInspectionTitle,
                  controller: _visueleInspectieTitel,
                ),
                CustomTextField(
                  label: l10n.visualInspectionText,
                  controller: _visueleInspectie,
                  maxLines: 8,
                ),
                CustomTextField(
                  label: l10n.visualInspectionNote,
                  controller: _visueleInspectieToelichting,
                  maxLines: 4,
                ),
              ],
            ),

            // ── Metingen en beproevingen ─────────────────────────────────
            _Section(
              title: l10n.measurementsText,
              children: [
                CustomTextField(
                  label: l10n.measurementsTitle,
                  controller: _metingenTitel,
                ),
                CustomTextField(
                  label: l10n.measurementsText,
                  controller: _metingen,
                  maxLines: 8,
                ),
                CustomTextField(
                  label: l10n.measurementsNote,
                  controller: _metingenToelichting,
                  maxLines: 4,
                ),
              ],
            ),

            // ── Aanvullend onderzoek ─────────────────────────────────────
            _Section(
              title: l10n.additionalResearchText,
              children: [
                CustomTextField(
                  label: l10n.additionalResearchTitle,
                  controller: _aanvullendOnderzoekTitel,
                ),
                CustomTextField(
                  label: l10n.additionalResearchText,
                  controller: _aanvullendOnderzoek,
                  maxLines: 8,
                ),
                CustomTextField(
                  label: l10n.additionalResearchNote,
                  controller: _aanvullendOnderzoekToelichting,
                  maxLines: 4,
                ),
              ],
            ),

            // ── Lijst 4 ─────────────────────────────────────────────────
            _Section(
              title: l10n.list4Text,
              children: [
                CustomTextField(
                  label: l10n.list4Title,
                  controller: _lijst4Titel,
                ),
                CustomTextField(
                  label: l10n.list4Text,
                  controller: _lijst4,
                  maxLines: 8,
                ),
                CustomTextField(
                  label: l10n.list4Note,
                  controller: _lijst4Toelichting,
                  maxLines: 4,
                ),
              ],
            ),

            // ── Overig ──────────────────────────────────────────────────
            _Section(
              title: l10n.rejectionCriteria,
              children: [
                CustomTextField(
                  label: l10n.rejectionCriteria,
                  controller: _vinklijstAfkeuringscriteria,
                  maxLines: 6,
                ),
              ],
            ),

            // ── Classificatie ────────────────────────────────────────────
            _Section(
              title: 'Classificatie',
              children: [
                CustomTextField(
                  label: 'Melding gevaarlijke situatie',
                  controller: _meldingGevaarlijkeSituatie,
                  maxLines: 6,
                ),
              ],
            ),

            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _save,
              child: Text(l10n.save),
            ),
          ],
        ),
      ),
    );
  }
}

class _Section extends StatelessWidget {
  final String title;
  final List<Widget> children;
  final bool initiallyExpanded;

  const _Section({
    required this.title,
    required this.children,
    this.initiallyExpanded = false,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      clipBehavior: Clip.antiAlias,
      child: ExpansionTile(
        title: Text(
          title,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1976D2),
          ),
        ),
        initiallyExpanded: initiallyExpanded,
        childrenPadding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        children: children,
      ),
    );
  }
}
