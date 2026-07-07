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
// ignore: unnecessary_import
import '../l10n/app_localizations.dart';
import '../models/final_assessment.dart';
import '../models/inspection_detail.dart';
import '../models/report_template.dart';
import '../models/title_page.dart' as model;
import '../services/database_service.dart';
import 'title_page.dart';
import 'inleiding_page.dart';
import 'general_data_page.dart';
import 'inspection_details_page.dart';
import 'switchboards_list_page.dart';
import 'solar_installations_list_page.dart';
import 'defects_list_page.dart';
import 'download_page.dart';
import 'eindbeoordeling_page.dart';
import 'home_page.dart';
import 'tekeningen_list_page.dart';
import 'herstelverklaring_page.dart';
import 'herstel_overview_page.dart';
import 'meetgegevens_page.dart';

class InspectionMenuPage extends StatefulWidget {
  final int inspectionId;

  const InspectionMenuPage({super.key, required this.inspectionId});

  @override
  State<InspectionMenuPage> createState() => _InspectionMenuPageState();
}

class _InspectionMenuPageState extends State<InspectionMenuPage> {
  final _db = DatabaseService();

  List<ReportTemplate> _templates = [];
  String? _selectedTypeRapport;
  bool _loading = true;
  int _switchboardCount = 0;
  int _solarCount = 0;
  int _defectCount = 0;
  bool _hasMeldingGevaarlijk = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final results = await Future.wait([
      _db.getReportTemplates(),
      _db.getInspectionDetail(widget.inspectionId),
      _db.getSwitchboards(widget.inspectionId),
      _db.getSolarInstallations(widget.inspectionId),
      _db.getDefects(widget.inspectionId),
    ]);
    setState(() {
      _templates = results[0] as List<ReportTemplate>;
      final detail = results[1] as dynamic;
      _selectedTypeRapport = detail?.typeRapport.isNotEmpty == true
          ? detail!.typeRapport
          : null;
      _switchboardCount = (results[2] as List).length;
      _solarCount = (results[3] as List).length;
      final defects = results[4] as List;
      _defectCount = defects.length;
      _hasMeldingGevaarlijk =
          defects.any((d) => d.classification == 'Rd');
      _loading = false;
    });
  }

  Future<void> _onTemplateSelected(String? typeRapport) async {
    setState(() => _selectedTypeRapport = typeRapport);

    // Load or create the InspectionDetail
    var detail = await _db.getInspectionDetail(widget.inspectionId);
    if (detail == null) {
      await _db.insertInspectionDetail(
          InspectionDetail(inspectionId: widget.inspectionId));
      detail = await _db.getInspectionDetail(widget.inspectionId);
    }
    if (detail == null) return;

    if (typeRapport == null) {
      // Only clear the typeRapport field, leave texts as-is
      await _db.updateInspectionDetail(
          detail.copyWith(typeRapport: ''));
      return;
    }

    final matches = _templates.where((t) => t.typeRapport == typeRapport);
    if (matches.isEmpty) return;
    final template = matches.first;

    final hasExistingData = detail.performedAccordingTo.isNotEmpty ||
        detail.testedAgainst.isNotEmpty ||
        detail.inleidingToelichting.isNotEmpty ||
        detail.methodeVisueleInspectie.isNotEmpty ||
        detail.methodeMetingen.isNotEmpty ||
        detail.methodeAanvullendOnderzoek.isNotEmpty ||
        detail.methodeCriteria.isNotEmpty;

    if (hasExistingData && mounted) {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Rapport type wijzigen'),
          content: const Text(
            'Het selecteren van een rapport type overschrijft de bestaande gegevens in de methode- en uitgangspuntenvelden. Weet u het zeker?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Annuleren'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Ja, overschrijven'),
            ),
          ],
        ),
      );
      if (confirmed != true) {
        setState(() => _selectedTypeRapport =
            detail?.typeRapport.isNotEmpty == true ? detail!.typeRapport : null);
        return;
      }
    }

    await _db.updateInspectionDetail(detail.copyWith(
      typeRapport: typeRapport,
      inleiding: template.inleiding,
      performedAccordingTo: template.inspectieUitgevoerdVolgens,
      testedAgainst: template.elektrischMaterieelGetoetst,
      inleidingToelichting: template.inleidingToelichting,
      methodeVisueleInspectie: template.visueleInspectie,
      methodeMetingen: template.metingen,
      methodeAanvullendOnderzoek: template.aanvullendOnderzoek,
      methodeCriteria: template.vinklijstAfkeuringscriteria,
    ));

    // Fill FinalAssessment from template
    if (template.tekstRapportVerklaring.isNotEmpty ||
        template.volgendInspectie.isNotEmpty) {
      var assessment = await _db.getFinalAssessment(widget.inspectionId);
      if (assessment == null) {
        await _db.insertFinalAssessment(
            FinalAssessment(inspectionId: widget.inspectionId));
        assessment = await _db.getFinalAssessment(widget.inspectionId);
      }
      if (assessment != null) {
        await _db.updateFinalAssessment(assessment.copyWith(
          eindbeoordeling: template.tekstRapportVerklaring.isNotEmpty
              ? template.tekstRapportVerklaring
              : null,
          volgendInspectie: template.volgendInspectie.isNotEmpty
              ? template.volgendInspectie
              : null,
        ));
      }
    }

    // Fill TitlePage fields from template
    var titlePage = await _db.getTitlePage(widget.inspectionId);
    if (titlePage == null) {
      await _db.insertTitlePage(
          model.TitlePage(inspectionId: widget.inspectionId));
      titlePage = await _db.getTitlePage(widget.inspectionId);
    }
    if (titlePage != null) {
      await _db.updateTitlePage(titlePage.copyWith(
        title: template.rapporttitel,
        subtitle: template.subtitel,
      ));
    }

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          AppLocalizations.of(context).isNl
              ? 'Rapport teksten ingeladen: $typeRapport'
              : 'Report texts loaded: $typeRapport',
        ),
        duration: const Duration(seconds: 2),
      ),
    );
  }
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.inspection),
      ),
      body: Column(
        children: [
          _NavBar(inspectionId: widget.inspectionId),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : ListView(
                    padding: const EdgeInsets.all(16.0),
                    children: [
                // ── TypeRapport selector ────────────────────────────────
                _TypeRapportCard(
                  templates: _templates,
                  selected: _selectedTypeRapport,
                  onChanged: _onTemplateSelected,
                  l10n: l10n,
                ),
                const SizedBox(height: 8),

                // ── Inspectie menu kaarten ──────────────────────────────
                _MenuCard(
                  icon: Icons.description,
                  title: l10n.titlePageTitle,
                  subtitle: l10n.titlePageSubtitle,
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) =>
                          TitlePageScreen(inspectionId: widget.inspectionId),
                    ),
                  ),
                ),
                _MenuCard(
                  icon: Icons.article_outlined,
                  title: l10n.inleidingTitle,
                  subtitle: l10n.inleidingSubtitle,
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) =>
                          InleidingPage(inspectionId: widget.inspectionId),
                    ),
                  ),
                ),
                _MenuCard(
                  icon: Icons.business,
                  title: l10n.generalData,
                  subtitle: l10n.generalDataSubtitle,
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) =>
                          GeneralDataPage(inspectionId: widget.inspectionId),
                    ),
                  ),
                ),
                _MenuCard(
                  icon: Icons.assignment,
                  title: l10n.inspectionDetails,
                  subtitle: l10n.inspectionDetailsSubtitle,
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => InspectionDetailsPage(
                          inspectionId: widget.inspectionId),
                    ),
                  ),
                ),
                _MenuCard(
                  icon: Icons.rate_review,
                  title: l10n.finalAssessment,
                  subtitle: l10n.finalAssessmentSubtitle,
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) =>
                          EindbeoordelingPage(inspectionId: widget.inspectionId),
                    ),
                  ),
                ),
                const Divider(height: 32),
                _MenuCard(
                  icon: Icons.electrical_services,
                  title: l10n.switchboardsMenu,
                  subtitle: l10n.switchboardsMenuSubtitle,
                  showEmptyIndicator: _switchboardCount == 0,
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => SwitchboardsListPage(
                          inspectionId: widget.inspectionId),
                    ),
                  ),
                ),
                _MenuCard(
                  icon: Icons.solar_power,
                  title: l10n.solarInstallations,
                  subtitle: l10n.solarInstallationsSubtitle,
                  showEmptyIndicator: _solarCount == 0,
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => SolarInstallationsListPage(
                          inspectionId: widget.inspectionId),
                    ),
                  ),
                ),
                _MenuCard(
                  icon: Icons.battery_charging_full,
                  title: l10n.batteryInstallations,
                  subtitle: l10n.comingSoon,
                  showEmptyIndicator: true,
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(l10n.batteryComingSoon)),
                    );
                  },
                ),
                _MenuCard(
                  icon: Icons.warning_amber,
                  title: l10n.defects,
                  subtitle: l10n.defectsSubtitle,
                  showEmptyIndicator: _defectCount == 0,
                  showMeldingIndicator: _hasMeldingGevaarlijk,
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) =>
                          DefectsListPage(inspectionId: widget.inspectionId),
                    ),
                  ),
                ),
                _MenuCard(
                  icon: Icons.build_outlined,
                  title: 'Herstel',
                  subtitle: 'Overzicht van gebreken en herstelstatus',
                  showEmptyIndicator: _defectCount == 0,
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) =>
                          HerstelOverviewPage(inspectionId: widget.inspectionId),
                    ),
                  ),
                ),
                _MenuCard(
                  icon: Icons.map_outlined,
                  title: 'Tekening inspectie',
                  subtitle: 'Inspecteer vanaf plattegrond of schema',
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => TekeningenListPage(
                          inspectionId: widget.inspectionId),
                    ),
                  ),
                ),
                _MenuCard(
                  icon: Icons.table_chart_outlined,
                  title: 'Meetgegevens',
                  subtitle: 'Importeer meetgegevens uit Excel-bestanden',
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) =>
                          MeetgegevensPage(inspectionId: widget.inspectionId),
                    ),
                  ),
                ),
                _MenuCard(
                  icon: Icons.assignment_turned_in_outlined,
                  title: 'Herstelverklaring',
                  subtitle: 'Verklaring van uitgevoerde herstelwerkzaamheden',
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => HerstelverklaringPage(
                          inspectionId: widget.inspectionId),
                    ),
                  ),
                ),
                _MenuCard(
                  icon: Icons.cloud_download_outlined,
                  title: 'Download',
                  subtitle: 'Gegevens downloaden',
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) =>
                          DownloadPage(inspectionId: widget.inspectionId),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  onPressed: () async {
                    final confirmed = await showDialog<bool>(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        title: Text(l10n.completeInspectionButton),
                        content: Text(l10n.completeInspectionConfirm),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(ctx, false),
                            child: Text(l10n.cancel),
                          ),
                          TextButton(
                            onPressed: () => Navigator.pop(ctx, true),
                            child: Text(l10n.complete),
                          ),
                        ],
                      ),
                    );
                    if (confirmed == true) {
                      await DatabaseService()
                          .updateInspectionStatus(widget.inspectionId, 'completed');
                      if (!context.mounted) return;
                      Navigator.popUntil(context, (route) => route.isFirst);
                    }
                  },
                  icon: const Icon(Icons.check_circle),
                  label: Text(l10n.completeInspectionButton),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _NavBar extends StatelessWidget {
  final int inspectionId;
  const _NavBar({required this.inspectionId});

  @override
  Widget build(BuildContext context) {
    return Material(
      elevation: 2,
      child: SizedBox(
        height: 56,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _btn(context, Icons.list_outlined, 'Inspecties',
                () => Navigator.pushAndRemoveUntil(context, MaterialPageRoute(
                      builder: (_) => HomePage()), (route) => false)),
            _btn(context, Icons.electrical_services, 'Verdelers',
                () => Navigator.push(context, MaterialPageRoute(
                      builder: (_) => SwitchboardsListPage(inspectionId: inspectionId)))),
            _btn(context, Icons.solar_power, 'Zonnestroom',
                () => Navigator.push(context, MaterialPageRoute(
                      builder: (_) => SolarInstallationsListPage(inspectionId: inspectionId)))),
            _btn(context, Icons.battery_charging_full, 'Accu',
                () => ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Accu-installaties: binnenkort beschikbaar')))),
            _btn(context, Icons.warning_amber, 'Gebreken',
                () => Navigator.push(context, MaterialPageRoute(
                      builder: (_) => DefectsListPage(inspectionId: inspectionId)))),
            _btn(context, Icons.build_outlined, 'Herstel',
                () => Navigator.push(context, MaterialPageRoute(
                      builder: (_) => HerstelOverviewPage(inspectionId: inspectionId)))),
            _btn(context, Icons.map_outlined, 'Tekeningen',
                () => Navigator.push(context, MaterialPageRoute(
                      builder: (_) => TekeningenListPage(inspectionId: inspectionId)))),
          ],
        ),
      ),
    );
  }

  Widget _btn(BuildContext context, IconData icon, String label, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 20, color: const Color(0xFF1976D2)),
            Text(label, style: const TextStyle(fontSize: 9, color: Color(0xFF1976D2))),
          ],
        ),
      ),
    );
  }
}

class _TypeRapportCard extends StatelessWidget {
  final List<ReportTemplate> templates;
  final String? selected;
  final ValueChanged<String?> onChanged;
  final AppLocalizations l10n;

  const _TypeRapportCard({
    required this.templates,
    required this.selected,
    required this.onChanged,
    required this.l10n,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      color: const Color(0xFFE3F2FD),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.folder_open, color: Color(0xFF1976D2), size: 20),
                const SizedBox(width: 8),
                Text(
                  l10n.selectReportType,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1976D2),
                    fontSize: 14,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<String?>(
              initialValue: selected,
              isExpanded: true,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                contentPadding:
                    EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                filled: true,
                fillColor: Colors.white,
              ),
              items: [
                DropdownMenuItem<String?>(
                  value: null,
                  child: Text(
                    l10n.noReportTypeLinked,
                    style: TextStyle(color: Colors.grey.shade600),
                  ),
                ),
                ...templates.map(
                  (t) => DropdownMenuItem<String?>(
                    value: t.typeRapport,
                    child: Text(
                      t.rapporttitel.isNotEmpty ? t.rapporttitel : t.typeRapport,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
              ],
              onChanged: onChanged,
            ),
            if (selected != null)
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Text(
                  l10n.isNl
                      ? 'Teksten worden geladen in Inspectiegegevens'
                      : 'Texts will be loaded into Inspection details',
                  style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _MenuCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final bool showEmptyIndicator;
  final bool showMeldingIndicator;

  const _MenuCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.showEmptyIndicator = false,
    this.showMeldingIndicator = false,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Icon(icon, color: const Color(0xFF1976D2), size: 28),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w500)),
        subtitle: Text(subtitle, style: const TextStyle(fontSize: 12)),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (showMeldingIndicator)
              Container(
                margin: const EdgeInsets.only(right: 4),
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: Colors.red.shade100,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.red.shade400, width: 1),
                ),
                child: Text(
                  'Melding',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: Colors.red.shade800,
                  ),
                ),
              ),
            if (showEmptyIndicator && !showMeldingIndicator)
              Container(
                margin: const EdgeInsets.only(right: 4),
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: Colors.orange.shade100,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.orange.shade400, width: 1),
                ),
                child: Text(
                  'Leeg',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: Colors.orange.shade800,
                  ),
                ),
              ),
            const Icon(Icons.chevron_right),
          ],
        ),
        onTap: onTap,
      ),
    );
  }
}
