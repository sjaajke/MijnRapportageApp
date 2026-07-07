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
import '../models/inspection_detail.dart';
import '../models/steekproef_item.dart';
import '../services/bag_service.dart';
import '../services/database_service.dart';
import '../widgets/custom_dropdown.dart';
import '../widgets/custom_text_field.dart';
import '../widgets/section_header.dart';
import 'home_page.dart';
import 'inspection_menu_page.dart';
import 'switchboards_list_page.dart';
import 'solar_installations_list_page.dart';
import 'defects_list_page.dart';

class InspectionDetailsPage extends StatefulWidget {
  final int inspectionId;

  const InspectionDetailsPage({super.key, required this.inspectionId});

  @override
  State<InspectionDetailsPage> createState() => _InspectionDetailsPageState();
}

class _InspectionDetailsPageState extends State<InspectionDetailsPage> {
  final _db = DatabaseService();

  final _scopeDesc = TextEditingController();
  final _notInspected = TextEditingController();
  final _notInspectedReason = TextEditingController();
  final _inspectionReason = TextEditingController();
  final _performedAccording = TextEditingController();
  final _testedAgainst = TextEditingController();
  final _methodeVisuele = TextEditingController();
  final _methodeMetingen = TextEditingController();
  final _methodeAanvullend = TextEditingController();
  final _methodeCriteria = TextEditingController();
  final _inleidingToelichting = TextEditingController();
  final _bouwjaarCtrl = TextEditingController();
  final _oppervlakteCtrl = TextEditingController();

  final _bagService = BagService();

  InspectionDetail? _detail;
  List<SteekproefItem> _steekproefItems = [];
  String? _selectedTypeRapport;
  List<String> _selectedGebouwfunctie = [];
  List<String> _selectedBijzondereInstallatie = [];
  List<String> _inspectionReasonOptions = [];
  bool _loading = true;
  bool _bagLoading = false;

  // NEN 10147 / ISO 2859-1 steekproeftabel (AQL 1,0)
  static const _steekproefTabel = [
    (van: 2, tot: 8, n: 2, g: 0, f: 1),
    (van: 9, tot: 15, n: 3, g: 0, f: 1),
    (van: 16, tot: 25, n: 5, g: 0, f: 1),
    (van: 26, tot: 50, n: 8, g: 0, f: 1),
    (van: 51, tot: 90, n: 13, g: 0, f: 1),
    (van: 91, tot: 150, n: 20, g: 0, f: 1),
    (van: 151, tot: 280, n: 32, g: 1, f: 2),
    (van: 281, tot: 500, n: 50, g: 1, f: 2),
    (van: 501, tot: 1200, n: 80, g: 2, f: 3),
    (van: 1201, tot: 3200, n: 125, g: 3, f: 4),
    (van: 3201, tot: 10000, n: 200, g: 5, f: 6),
    (van: 10001, tot: 35000, n: 315, g: 7, f: 8),
  ];

  static ({int n, int g, int f})? _lookupSteekproef(int omvang) {
    for (final rij in _steekproefTabel) {
      if (omvang >= rij.van && omvang <= rij.tot) {
        return (n: rij.n, g: rij.g, f: rij.f);
      }
    }
    return null;
  }

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final reasonStandards = await _db.getStandards('inspection_reason');
    var detail = await _db.getInspectionDetail(widget.inspectionId);
    if (detail == null) {
      await _db.insertInspectionDetail(
        InspectionDetail(inspectionId: widget.inspectionId),
      );
      detail = await _db.getInspectionDetail(widget.inspectionId);
    }

    if (detail != null) {
      _scopeDesc.text = detail.scopeDescription;
      _notInspected.text = detail.notInspectedParts;
      _notInspectedReason.text = detail.notInspectedReason;
      _inspectionReason.text = detail.inspectionReason;
      _performedAccording.text = detail.performedAccordingTo;
      _testedAgainst.text = detail.testedAgainst;
      _methodeVisuele.text = detail.methodeVisueleInspectie;
      _methodeMetingen.text = detail.methodeMetingen;
      _methodeAanvullend.text = detail.methodeAanvullendOnderzoek;
      _methodeCriteria.text = detail.methodeCriteria;
      _inleidingToelichting.text = detail.inleidingToelichting;
      _bouwjaarCtrl.text = detail.bouwjaar;
      _oppervlakteCtrl.text = detail.oppervlakte;
      _selectedGebouwfunctie = detail.gebouwfunctie.isEmpty
          ? []
          : detail.gebouwfunctie.split(',');
      _selectedBijzondereInstallatie = detail.bijzondereInstallatie.isEmpty
          ? []
          : detail.bijzondereInstallatie.split(',');
    }

    final steekproefItems = await _db.getSteekproefItems(widget.inspectionId);

    setState(() {
      _detail = detail;
      _steekproefItems = steekproefItems;
      _inspectionReasonOptions = reasonStandards
          .map((s) => s.displayName)
          .toList();
      _selectedTypeRapport = detail?.typeRapport.isNotEmpty == true
          ? detail!.typeRapport
          : null;
      _loading = false;
    });
  }

  Future<void> _fetchFromBag() async {
    final l10n = AppLocalizations.of(context);
    final hasExistingData =
        _bouwjaarCtrl.text.isNotEmpty ||
        _oppervlakteCtrl.text.isNotEmpty ||
        _selectedGebouwfunctie.isNotEmpty;
    if (hasExistingData) {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Text(l10n.bagOverwriteTitle),
          content: Text(l10n.bagOverwriteConfirm),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text(l10n.cancel),
            ),
            TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: Text(l10n.bagOverwriteButton),
            ),
          ],
        ),
      );
      if (confirmed != true) return;
    }

    setState(() => _bagLoading = true);
    try {
      final generalData = await _db.getGeneralData(widget.inspectionId);
      final result = await _bagService.lookup(
        generalData?.inspectionAddressStreet ?? '',
        generalData?.inspectionAddressPostalCity ?? '',
      );
      setState(() {
        if (result.bouwjaar != null) {
          _bouwjaarCtrl.text = '${result.bouwjaar}';
        }
        if (result.oppervlakte != null) {
          _oppervlakteCtrl.text = '${result.oppervlakte}';
        }
        if (result.gebruiksdoelen.isNotEmpty) {
          _selectedGebouwfunctie = result.gebruiksdoelen;
        }
      });
      await _autoSave();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.bagLookupSuccess(result.matchedAddress))),
      );
    } on BagNotFoundException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.message)));
    } on BagLookupException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.message)));
    } finally {
      if (mounted) setState(() => _bagLoading = false);
    }
  }

  Future<void> _addSteekproef() async {
    final omvangController = TextEditingController();
    final beschrijvingController = TextEditingController();
    ({int n, int g, int f})? preview;

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setS) => AlertDialog(
          title: const Text('Steekproef toevoegen'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: beschrijvingController,
                decoration: const InputDecoration(
                  labelText: 'Omschrijving',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: omvangController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Omvang partij',
                  border: OutlineInputBorder(),
                ),
                onChanged: (v) {
                  final n = int.tryParse(v);
                  setS(() => preview = n != null ? _lookupSteekproef(n) : null);
                },
              ),
              if (preview != null) ...[
                const SizedBox(height: 16),
                Table(
                  border: TableBorder.all(color: Colors.grey.shade300),
                  columnWidths: const {
                    0: FlexColumnWidth(2),
                    1: FlexColumnWidth(1),
                    2: FlexColumnWidth(1),
                  },
                  children: [
                    TableRow(
                      decoration: BoxDecoration(color: Colors.grey.shade100),
                      children: const [
                        _TCell('Steekproef', header: true),
                        _TCell('G', header: true),
                        _TCell('F', header: true),
                      ],
                    ),
                    TableRow(
                      children: [
                        _TCell('${preview!.n}'),
                        _TCell('${preview!.g}'),
                        _TCell('${preview!.f}'),
                      ],
                    ),
                  ],
                ),
              ] else if (omvangController.text.isNotEmpty) ...[
                const SizedBox(height: 8),
                const Text(
                  'Omvang buiten tabelrange (2–35 000).',
                  style: TextStyle(color: Colors.red, fontSize: 12),
                ),
              ],
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Annuleren'),
            ),
            TextButton(
              onPressed: preview == null
                  ? null
                  : () async {
                      final omvang = int.tryParse(omvangController.text) ?? 0;
                      final item = SteekproefItem(
                        inspectionId: widget.inspectionId,
                        beschrijving: beschrijvingController.text.trim(),
                        omvangPartij: omvang,
                        steekproef: preview!.n,
                        g: preview!.g,
                        f: preview!.f,
                      );
                      final id = await _db.insertSteekproefItem(item);
                      setState(() {
                        _steekproefItems.add(item.copyWith(id: id));
                      });
                      if (ctx.mounted) Navigator.pop(ctx);
                    },
              child: const Text('Toevoegen'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _deleteSteekproef(SteekproefItem item) async {
    await _db.deleteSteekproefItem(item.id!);
    setState(() => _steekproefItems.remove(item));
  }

  Future<void> _autoSave() async {
    if (_detail == null) return;
    final updated = _detail!.copyWith(
      scopeDescription: _scopeDesc.text,
      notInspectedParts: _notInspected.text,
      notInspectedReason: _notInspectedReason.text,
      inspectionReason: _inspectionReason.text,
      performedAccordingTo: _performedAccording.text,
      testedAgainst: _testedAgainst.text,
      typeRapport: _selectedTypeRapport ?? '',
      methodeVisueleInspectie: _methodeVisuele.text,
      methodeMetingen: _methodeMetingen.text,
      methodeAanvullendOnderzoek: _methodeAanvullend.text,
      methodeCriteria: _methodeCriteria.text,
      inleidingToelichting: _inleidingToelichting.text,
      gebouwfunctie: _selectedGebouwfunctie.join(','),
      bijzondereInstallatie: _selectedBijzondereInstallatie.join(','),
      bouwjaar: _bouwjaarCtrl.text,
      oppervlakte: _oppervlakteCtrl.text,
    );
    await _db.updateInspectionDetail(updated);
    _detail = updated;
  }

  @override
  void dispose() {
    _autoSave();
    _scopeDesc.dispose();
    _notInspected.dispose();
    _notInspectedReason.dispose();
    _inspectionReason.dispose();
    _performedAccording.dispose();
    _testedAgainst.dispose();
    _methodeVisuele.dispose();
    _methodeMetingen.dispose();
    _methodeAanvullend.dispose();
    _methodeCriteria.dispose();
    _inleidingToelichting.dispose();
    _bouwjaarCtrl.dispose();
    _oppervlakteCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Scaffold(
        appBar: AppBar(
          title: Text(AppLocalizations.of(context).inspectionDetails),
        ),
        body: Column(
          children: [
            _NavBar(inspectionId: widget.inspectionId),
            const Expanded(child: Center(child: CircularProgressIndicator())),
          ],
        ),
      );
    }

    final l10n = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.inspectionDetails)),
      body: Column(
        children: [
          _NavBar(inspectionId: widget.inspectionId),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // ── Netaansluiting ───────────────────────────────────────────
                  SectionHeader(title: 'Netaansluiting'),
                  CustomDropdown(
                    label: 'Aardingsstelsel',
                    value: _detail!.aardingsstelsel.isEmpty
                        ? null
                        : _detail!.aardingsstelsel,
                    items: const ['TN-C', 'TN-C-S', 'TN-S', 'TT'],
                    onChanged: (v) async {
                      final updated = _detail!.copyWith(
                        aardingsstelsel: v ?? '',
                      );
                      await _db.updateInspectionDetail(updated);
                      setState(() => _detail = updated);
                    },
                  ),
                  CustomDropdown(
                    label: 'Netaansluiting',
                    value: _detail!.netaansluiting.isEmpty
                        ? null
                        : _detail!.netaansluiting,
                    items: const ['230V 50Hz~', '230/400V 50Hz~'],
                    onChanged: (v) async {
                      final updated = _detail!.copyWith(
                        netaansluiting: v ?? '',
                      );
                      await _db.updateInspectionDetail(updated);
                      setState(() => _detail = updated);
                    },
                  ),
                  CustomDropdown(
                    label: 'Hoofdaansluiting',
                    value: _detail!.hoofdaansluiting.isEmpty
                        ? null
                        : _detail!.hoofdaansluiting,
                    items: const [
                      '25',
                      '32',
                      '35',
                      '40',
                      '50',
                      '63',
                      '80',
                      '100',
                      '125',
                      '160',
                      '250',
                    ],
                    onChanged: (v) async {
                      final updated = _detail!.copyWith(
                        hoofdaansluiting: v ?? '',
                      );
                      await _db.updateInspectionDetail(updated);
                      setState(() => _detail = updated);
                    },
                  ),
                  SectionHeader(title: 'Gebouw'),
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: OutlinedButton.icon(
                      onPressed: _bagLoading ? null : _fetchFromBag,
                      icon: _bagLoading
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.home_work_outlined),
                      label: Text(
                        _bagLoading
                            ? l10n.bagLookupInProgress
                            : l10n.fetchFromBag,
                      ),
                    ),
                  ),
                  _MultiSelectField(
                    label: 'Gebouwfunctie volgens Bbl',
                    selected: _selectedGebouwfunctie,
                    groups: const [
                      (
                        header: '',
                        items: [
                          'Bijeenkomstfunctie',
                          'Bijeenkomstfunctie voor kinderopvang',
                          'Celfunctie',
                          'Gezondheidsfunctie',
                          'Industriefunctie',
                          'Kantoorfunctie',
                          'Lichte industriefunctie',
                          'Logiefunctie',
                          'Logieverblijf',
                          'Onderwijsfunctie',
                          'Overige',
                          'Sportfunctie',
                          'Winkelfunctie',
                          'Woonfunctie',
                        ],
                      ),
                    ],
                    onChanged: (selection) {
                      setState(() => _selectedGebouwfunctie = selection);
                      _autoSave();
                    },
                  ),
                  _MultiSelectField(
                    label: 'Bijzondere installatie of ruimte',
                    selected: _selectedBijzondereInstallatie,
                    groups: const [
                      (header: '', items: ['Niet van toepassing']),
                      (
                        header: 'HOOFDSTUKKEN',
                        items: [
                          '442 en 534 Overspanningsbeveiliging',
                          '551 Laagspanningsopwekeenheden',
                          '559 Verlichtingsarmaturen en verlichtingsinstallaties',
                        ],
                      ),
                      (
                        header: 'BIJZONDERE BEPALINGEN',
                        items: [
                          '701 Ruimten met een bad of douche',
                          '702 Zwembaden en fonteinen',
                          '703 Ruimten en cabines met saunakachels',
                          '704 Installaties op bouw- en sloopterreinen',
                          '705 Bedrijfsruimten en bedrijfsterreinen voor landbouw, tuinbouw en veeteelt',
                          '706 Nauwe geleidende ruimten',
                          '708 Campings en vergelijkbare terreinen',
                          '709 Jachthavens en vergelijkbare terreinen',
                          '710 Medisch gebruikte ruimten',
                          '711 Tentoonstellingen, shows en stands',
                          '712 Fotovoltaïsche systemen (PV-systemen)',
                          '713 Meubilair',
                          '714 Installaties voor buitenverlichting',
                          '715 Verlichtingsinstallaties met zeer lage spanning',
                          '717 Verrijdbare of verplaatsbare eenheden',
                          '718 Ruimten met een publieke functie en bedrijfsruimten',
                          '721 Elektrische installaties in caravans en campers',
                          '722 Laadinrichtingen voor elektrische voertuigen',
                          '729 Ruimten met beperkte toegang bestemd voor bedieningshandelingen en onderhoud',
                          '740 Tijdelijke elektrische installaties voor constructies, toestellen en kramen op kermissen, in attractieparken en circussen',
                          '753 Verwarmingskabels en ingebouwde verwarmingssystemen',
                        ],
                      ),
                      (
                        header: 'Vervallen vanaf NEN 1010:2020',
                        items: [
                          '723 Ruimten voor meting en beproeving',
                          '724 Elektrolyseruimten',
                          '754 Vochtige ruimten en ruimten met bijtende gassen, dampen of stoffen',
                        ],
                      ),
                      (
                        header: 'Vervallen vanaf NEN 1010:2015',
                        items: [
                          '720 Gewone ruimten',
                          '725 Elektrische bedrijfsruimten',
                          '751 Stoffige ruimten',
                          '752 Ruimten met brandgevaar',
                          '758 Ruimten met zware mechanische stootbelasting',
                          '761 Kabels in de grond',
                          '763 Grond-, wegdek- en vloerverwarming anders dan voor ruimteverwarming',
                          '773 Voeding van neoninstallaties en neontoestellen',
                          '781 Lasinstallaties – Lascabines',
                          '783 Brandpreventieve en -repressieve installaties',
                        ],
                      ),
                    ],
                    onChanged: (selection) {
                      setState(
                        () => _selectedBijzondereInstallatie = selection,
                      );
                      _autoSave();
                    },
                  ),
                  _BouwjaarField(
                    controller: _bouwjaarCtrl,
                    onChanged: (_) => _autoSave(),
                  ),
                  CustomTextField(
                    label: l10n.gebruiksoppervlakte,
                    controller: _oppervlakteCtrl,
                    onChanged: (_) => _autoSave(),
                    keyboardType: TextInputType.number,
                  ),

                  // ── Omvang ──────────────────────────────────────────────────
                  SectionHeader(title: l10n.scope),
                  CustomTextField(
                    label: l10n.scopeDescription,
                    controller: _scopeDesc,
                    onChanged: (_) => _autoSave(),
                    maxLines: 4,
                  ),
                  CustomTextField(
                    label: l10n.notInspected,
                    controller: _notInspected,
                    onChanged: (_) => _autoSave(),
                    maxLines: 3,
                  ),
                  CustomTextField(
                    label: l10n.notInspectedReason,
                    controller: _notInspectedReason,
                    onChanged: (_) => _autoSave(),
                    maxLines: 3,
                  ),

                  // ── Steekproeven ─────────────────────────────────────────────
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Expanded(
                        child: Text(
                          'Steekproeven',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      TextButton.icon(
                        onPressed: _addSteekproef,
                        icon: const Icon(Icons.add, size: 18),
                        label: const Text('Toevoegen'),
                      ),
                    ],
                  ),
                  if (_steekproefItems.isEmpty)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Text(
                        'Geen steekproeven.',
                        style: TextStyle(color: Colors.grey.shade600),
                      ),
                    )
                  else
                    Table(
                      border: TableBorder.all(color: Colors.grey.shade300),
                      columnWidths: const {
                        0: FlexColumnWidth(3),
                        1: FlexColumnWidth(2),
                        2: FlexColumnWidth(1),
                        3: FlexColumnWidth(1),
                        4: FlexColumnWidth(1),
                        5: IntrinsicColumnWidth(),
                      },
                      children: [
                        TableRow(
                          decoration: BoxDecoration(
                            color: Colors.grey.shade200,
                          ),
                          children: const [
                            _TCell('Omschrijving', header: true),
                            _TCell('Omvang partij', header: true),
                            _TCell('Steekproef', header: true),
                            _TCell('G', header: true),
                            _TCell('F', header: true),
                            _TCell('', header: true),
                          ],
                        ),
                        for (final item in _steekproefItems)
                          TableRow(
                            children: [
                              _TCell(item.beschrijving),
                              _TCell('${item.omvangPartij}'),
                              _TCell('${item.steekproef}'),
                              _TCell('${item.g}'),
                              _TCell('${item.f}'),
                              TableCell(
                                child: IconButton(
                                  icon: const Icon(
                                    Icons.delete_outline,
                                    size: 18,
                                    color: Colors.red,
                                  ),
                                  onPressed: () => _deleteSteekproef(item),
                                ),
                              ),
                            ],
                          ),
                      ],
                    ),
                  const SizedBox(height: 8),

                  // ── Uitgangspunten ───────────────────────────────────────────
                  SectionHeader(title: l10n.assumptions),
                  CustomDropdown(
                    label: l10n.inspectionReason,
                    value:
                        _inspectionReasonOptions.contains(
                          _inspectionReason.text,
                        )
                        ? _inspectionReason.text
                        : null,
                    items: _inspectionReasonOptions,
                    onChanged: (v) {
                      _inspectionReason.text = v ?? '';
                      _autoSave();
                    },
                  ),
                  CustomTextField(
                    label: l10n.performedAccording,
                    controller: _performedAccording,
                    onChanged: (_) => _autoSave(),
                    maxLines: 3,
                  ),
                  CustomTextField(
                    label: l10n.testedAgainst,
                    controller: _testedAgainst,
                    onChanged: (_) => _autoSave(),
                    maxLines: 3,
                  ),
                  CustomTextField(
                    label: l10n.inleidingToelichting,
                    controller: _inleidingToelichting,
                    onChanged: (_) => _autoSave(),
                    maxLines: 3,
                  ),

                  // ── Methode ──────────────────────────────────────────────────
                  SectionHeader(title: l10n.methode),
                  _MethodeSubSection(
                    title: l10n.methodeVisueleInspectie,
                    controller: _methodeVisuele,
                    onChanged: (_) => _autoSave(),
                  ),
                  _MethodeSubSection(
                    title: l10n.methodeMetingen,
                    controller: _methodeMetingen,
                    onChanged: (_) => _autoSave(),
                  ),
                  _MethodeSubSection(
                    title: l10n.methodeAanvullendOnderzoek,
                    controller: _methodeAanvullend,
                    onChanged: (_) => _autoSave(),
                  ),
                  _MethodeSubSection(
                    title: l10n.methodeCriteria,
                    controller: _methodeCriteria,
                    onChanged: (_) => _autoSave(),
                  ),

                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: () async {
                      final navigator = Navigator.of(context);
                      await _autoSave();
                      if (!mounted) return;
                      navigator.push(
                        MaterialPageRoute(
                          builder: (_) => InspectionMenuPage(
                            inspectionId: widget.inspectionId,
                          ),
                        ),
                      );
                    },
                    child: Text(l10n.next),
                  ),
                ],
              ),
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
            _btn(
              context,
              Icons.list_outlined,
              'Inspecties',
              () => Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (_) => HomePage()),
                (route) => false,
              ),
            ),
            _btn(
              context,
              Icons.home_outlined,
              'Inspectie',
              () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) =>
                      InspectionMenuPage(inspectionId: inspectionId),
                ),
              ),
            ),
            _btn(
              context,
              Icons.electrical_services,
              'Verdelers',
              () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) =>
                      SwitchboardsListPage(inspectionId: inspectionId),
                ),
              ),
            ),
            _btn(
              context,
              Icons.solar_power,
              'Zonnestroom',
              () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) =>
                      SolarInstallationsListPage(inspectionId: inspectionId),
                ),
              ),
            ),
            _btn(
              context,
              Icons.warning_amber,
              'Gebreken',
              () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => DefectsListPage(inspectionId: inspectionId),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _btn(
    BuildContext context,
    IconData icon,
    String label,
    VoidCallback onTap,
  ) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 22, color: const Color(0xFF1976D2)),
            Text(
              label,
              style: const TextStyle(fontSize: 10, color: Color(0xFF1976D2)),
            ),
          ],
        ),
      ),
    );
  }
}

class _MethodeSubSection extends StatelessWidget {
  final String title;
  final TextEditingController controller;
  final ValueChanged<String>? onChanged;

  const _MethodeSubSection({
    required this.title,
    required this.controller,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 12, bottom: 4),
          child: Text(
            title,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Color(0xFF1976D2),
            ),
          ),
        ),
        CustomTextField(
          label: title,
          controller: controller,
          onChanged: onChanged,
          maxLines: 6,
        ),
      ],
    );
  }
}

class _TCell extends StatelessWidget {
  final String text;
  final bool header;
  const _TCell(this.text, {this.header = false});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      child: Text(
        text,
        style: TextStyle(
          fontWeight: header ? FontWeight.w600 : FontWeight.normal,
          fontSize: 13,
        ),
      ),
    );
  }
}

class _BouwjaarField extends StatelessWidget {
  final TextEditingController controller;
  final ValueChanged<String>? onChanged;

  const _BouwjaarField({required this.controller, this.onChanged});

  Future<void> _pickYear(BuildContext context) async {
    final now = DateTime.now().year;
    final current = int.tryParse(controller.text);
    const startYear = 1900;
    final years = List.generate(now - startYear + 1, (i) => startYear + i);
    int dialogSelected = (current ?? now).clamp(startYear, now);
    final initialIndex = years.indexOf(dialogSelected);

    final result = await showDialog<int>(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setS) => AlertDialog(
            title: const Text('Kies bouwjaar'),
            content: SizedBox(
              height: 200,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Container(
                    height: 44,
                    decoration: BoxDecoration(
                      color: const Color(0xFF1976D2).withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  ListWheelScrollView.useDelegate(
                    itemExtent: 44,
                    controller: FixedExtentScrollController(
                      initialItem: initialIndex,
                    ),
                    onSelectedItemChanged: (i) =>
                        setS(() => dialogSelected = years[i]),
                    physics: const FixedExtentScrollPhysics(),
                    childDelegate: ListWheelChildBuilderDelegate(
                      builder: (ctx, i) {
                        final isSelected = years[i] == dialogSelected;
                        return Center(
                          child: Text(
                            '${years[i]}',
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: isSelected
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                              color: isSelected
                                  ? const Color(0xFF1976D2)
                                  : Colors.black87,
                            ),
                          ),
                        );
                      },
                      childCount: years.length,
                    ),
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
                onPressed: () => Navigator.pop(ctx, dialogSelected),
                child: const Text('OK'),
              ),
            ],
          ),
        );
      },
    );

    if (result != null) {
      controller.text = '$result';
      onChanged?.call('$result');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: TextField(
        controller: controller,
        keyboardType: TextInputType.number,
        maxLength: 4,
        decoration: InputDecoration(
          labelText: 'Bouwjaar',
          border: const OutlineInputBorder(),
          counterText: '',
          suffixIcon: IconButton(
            icon: const Icon(Icons.calendar_today_outlined),
            tooltip: 'Kies jaar',
            onPressed: () => _pickYear(context),
          ),
        ),
        onChanged: onChanged,
      ),
    );
  }
}

class _MultiSelectField extends StatelessWidget {
  final String label;
  final List<String> selected;
  final List<({String header, List<String> items})> groups;
  final ValueChanged<List<String>> onChanged;

  const _MultiSelectField({
    required this.label,
    required this.selected,
    required this.groups,
    required this.onChanged,
  });

  Future<void> _openDialog(BuildContext context) async {
    final result = await showDialog<List<String>>(
      context: context,
      builder: (ctx) =>
          _MultiSelectDialog(title: label, groups: groups, initial: selected),
    );
    if (result != null) onChanged(result);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InkWell(
            onTap: () => _openDialog(context),
            borderRadius: BorderRadius.circular(4),
            child: InputDecorator(
              decoration: InputDecoration(
                labelText: label,
                border: const OutlineInputBorder(),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 12,
                ),
                suffixIcon: const Icon(Icons.arrow_drop_down),
              ),
              child: Text(
                selected.isEmpty
                    ? 'Kies...'
                    : '${selected.length} geselecteerd',
                style: TextStyle(
                  fontSize: 14,
                  color: selected.isEmpty
                      ? Colors.grey.shade600
                      : Colors.black87,
                ),
              ),
            ),
          ),
          if (selected.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Wrap(
                spacing: 6,
                runSpacing: 4,
                children: selected
                    .map(
                      (s) => Chip(
                        label: Text(s, style: const TextStyle(fontSize: 12)),
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        visualDensity: VisualDensity.compact,
                        onDeleted: () {
                          final updated = selected
                              .where((x) => x != s)
                              .toList();
                          onChanged(updated);
                        },
                      ),
                    )
                    .toList(),
              ),
            ),
        ],
      ),
    );
  }
}

class _MultiSelectDialog extends StatefulWidget {
  final String title;
  final List<({String header, List<String> items})> groups;
  final List<String> initial;

  const _MultiSelectDialog({
    required this.title,
    required this.groups,
    required this.initial,
  });

  @override
  State<_MultiSelectDialog> createState() => _MultiSelectDialogState();
}

class _MultiSelectDialogState extends State<_MultiSelectDialog> {
  late List<String> _selected;

  @override
  void initState() {
    super.initState();
    _selected = List.from(widget.initial);
  }

  void _toggle(String value) {
    setState(() {
      if (_selected.contains(value)) {
        _selected.remove(value);
      } else {
        _selected.add(value);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.title),
      contentPadding: const EdgeInsets.fromLTRB(0, 16, 0, 0),
      content: SizedBox(
        width: double.maxFinite,
        child: ListView(
          shrinkWrap: true,
          children: [
            for (final group in widget.groups) ...[
              if (group.header.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                  child: Text(
                    group.header,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1976D2),
                    ),
                  ),
                ),
              for (final item in group.items)
                CheckboxListTile(
                  dense: true,
                  title: Text(item, style: const TextStyle(fontSize: 13)),
                  value: _selected.contains(item),
                  onChanged: (_) => _toggle(item),
                  controlAffinity: ListTileControlAffinity.leading,
                ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Annuleren'),
        ),
        TextButton(
          onPressed: () => Navigator.pop(context, _selected),
          child: const Text('OK'),
        ),
      ],
    );
  }
}
