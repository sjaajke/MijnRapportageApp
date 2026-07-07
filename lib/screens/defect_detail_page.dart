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
import 'package:flutter/material.dart';
import '../l10n/app_localizations.dart';
import '../models/defect.dart';
import '../models/defect_annotation.dart';
import '../models/rapport_constatering.dart';
import '../services/database_service.dart';
import '../widgets/custom_text_field.dart';
import '../widgets/location_picker_dialog.dart';
import '../widgets/location_row.dart';
import '../widgets/custom_dropdown.dart';
import '../widgets/defect_annotation_painter.dart';
import '../widgets/photo_container.dart';
import 'defect_annotation_screen.dart';
import 'herstel_page.dart';
import 'home_page.dart';
import 'inspection_menu_page.dart';
import 'melding_gevaarlijke_situatie_page.dart';
import 'switchboards_list_page.dart';
import 'solar_installations_list_page.dart';
import 'defects_list_page.dart';

class DefectDetailPage extends StatelessWidget {
  final int defectId;
  final int inspectionId;

  const DefectDetailPage({super.key, required this.defectId, required this.inspectionId});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.defect)),
      body: Column(
        children: [
          _NavBar(inspectionId: inspectionId),
          Expanded(
            child: DefectDetailView(
              key: ValueKey(defectId),
              defectId: defectId,
              inspectionId: inspectionId,
              onSimilarCreated: (newId) {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (_) =>
                        DefectDetailPage(defectId: newId, inspectionId: inspectionId),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

/// The editable defect form, extracted so it can be embedded either as a
/// full [DefectDetailPage] or inline in a master-detail split view.
class DefectDetailView extends StatefulWidget {
  final int defectId;
  final int inspectionId;

  /// Called with the id of a newly created "similar" defect instead of the
  /// default push-navigation, so an embedding split view can select it.
  final ValueChanged<int>? onSimilarCreated;

  /// Called after the Save button persists changes, instead of the default
  /// pop-navigation, so an embedding split view can clear the selection.
  final VoidCallback? onSavedAndClose;

  /// Called whenever the defect is persisted, so an embedding list can
  /// refresh its summary (location/classification/description) live.
  final ValueChanged<Defect>? onDefectUpdated;

  /// Called if the defect no longer exists (e.g. deleted elsewhere), instead
  /// of the default pop-navigation.
  final VoidCallback? onNotFound;

  const DefectDetailView({
    super.key,
    required this.defectId,
    required this.inspectionId,
    this.onSimilarCreated,
    this.onSavedAndClose,
    this.onDefectUpdated,
    this.onNotFound,
  });

  @override
  State<DefectDetailView> createState() => _DefectDetailViewState();
}

class _DefectDetailViewState extends State<DefectDetailView> {
  final _db = DatabaseService();

  final _locationController = TextEditingController();
  final _locationAController = TextEditingController();
  final _locationBController = TextEditingController();
  final _naamCodeController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _toelichtingController = TextEditingController();

  Defect? _defect;
  List<RapportConstatering> _constateringen = [];
  List<String> _locationOptions = [];
  List<String> _locationAOptions = [];
  List<String> _locationBOptions = [];
  List<({String component, String name})> _switchboardOptions = [];
  int _defectNumber = 1;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final defect = await _db.getDefect(widget.defectId);
    if (defect == null) {
      if (!mounted) return;
      if (widget.onNotFound != null) {
        widget.onNotFound!();
      } else {
        Navigator.pop(context);
      }
      return;
    }

    _locationController.text = defect.location;
    _locationAController.text = defect.locationA;
    _locationBController.text = defect.locationB;
    _naamCodeController.text = defect.naamCode;
    _descriptionController.text = defect.description;
    _toelichtingController.text = defect.toelichting;

    final constateringen = await _db.getRapportConstateringen();
    final locationStandards = await _db.getStandards('location');
    final locationAStandards = await _db.getStandards('location_a');
    final locationBStandards = await _db.getStandards('location_b');
    final switchboards = await _db.getSwitchboards(widget.inspectionId);
    final allDefects = await _db.getDefects(widget.inspectionId);
    final idx = allDefects.indexWhere((d) => d.id == widget.defectId);

    setState(() {
      _defect = defect;
      _constateringen = constateringen;
      _locationOptions = locationStandards.map((s) => s.value).toList();
      _locationAOptions = locationAStandards.map((s) => s.value).toList();
      _locationBOptions = locationBStandards.map((s) => s.value).toList();
      _switchboardOptions = switchboards
          .where((s) => s.name.isNotEmpty)
          .map((s) => (component: s.installationComponent, name: s.name))
          .toList();
      _defectNumber = idx >= 0 ? idx + 1 : 1;
      _loading = false;
    });
  }

  Future<void> _pickLocation() async {
    final picked = await showDialog<String>(
      context: context,
      builder: (ctx) => LocationPickerDialog(options: _locationOptions),
    );
    if (picked == null) return;
    _locationController.text = picked;
    _save();
  }

  Future<void> _pickLocationA() async {
    final picked = await showDialog<String>(
      context: context,
      builder: (ctx) => LocationPickerDialog(options: _locationAOptions),
    );
    if (picked == null) return;
    _locationAController.text = picked;
    _save();
  }

  Future<void> _pickLocationB() async {
    final picked = await showDialog<String>(
      context: context,
      builder: (ctx) => LocationPickerDialog(options: _locationBOptions),
    );
    if (picked == null) return;
    _locationBController.text = picked;
    _save();
  }

  Future<void> _pickNaamCode() async {
    final picked = await showDialog<({String component, String name})>(
      context: context,
      builder: (ctx) => _SwitchboardPickerDialog(options: _switchboardOptions),
    );
    if (picked == null) return;
    _naamCodeController.text = picked.name;
    if (picked.component.isNotEmpty) {
      setState(() {
        _defect = _defect!.copyWith(installationComponent: picked.component);
      });
    }
    _save();
  }

  String _mapKwalificatie(String k) {
    switch (k) {
      case 'Er': return 'Rd';
      case 'Or': return 'Or';
      case 'Ge': return 'Ge';
      case 'Bl': return 'Bl';
      case 'NO': return 'Pa';
      default:   return 'Ge';
    }
  }

  Future<void> _pickFromConstateringen() async {
    final picked = await showDialog<RapportConstatering>(
      context: context,
      builder: (_) => _ConstateringenPicker(items: _constateringen),
    );
    if (picked == null || !mounted) return;

    final classification = _mapKwalificatie(picked.kwalificatie);
    _descriptionController.text = picked.tekst;
    _toelichtingController.text = picked.toelichting;
    setState(() {
      _defect = _defect!.copyWith(classification: classification);
    });
    _save();
  }

  Future<void> _createSimilarDefect() async {
    if (_defect == null) return;
    await _save();
    final source = _defect!;
    final newDefect = Defect(
      inspectionId: widget.inspectionId,
      location: source.location,
      locationA: source.locationA,
      locationB: source.locationB,
      installationComponent: source.installationComponent,
      naamCode: source.naamCode,
    );
    final id = await _db.insertDefect(newDefect);
    if (!mounted) return;
    if (widget.onSimilarCreated != null) {
      widget.onSimilarCreated!(id);
    } else {
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => DefectDetailPage(
            defectId: id,
            inspectionId: widget.inspectionId,
          ),
        ),
      );
    }
  }

  Future<void> _save() async {
    if (_defect == null) return;
    final updated = _defect!.copyWith(
      location: _locationController.text,
      locationA: _locationAController.text,
      locationB: _locationBController.text,
      naamCode: _naamCodeController.text,
      description: _descriptionController.text,
      toelichting: _toelichtingController.text,
    );
    await _db.updateDefect(updated);
    _defect = updated;
    widget.onDefectUpdated?.call(updated);
  }

  @override
  void dispose() {
    _save();
    _locationController.dispose();
    _locationAController.dispose();
    _locationBController.dispose();
    _naamCodeController.dispose();
    _descriptionController.dispose();
    _toelichtingController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    final defect = _defect!;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
            LocationRow(
              label: 'Locatie',
              controller: _locationController,
              onChanged: (_) => _save(),
              onPick: _locationOptions.isEmpty ? null : _pickLocation,
            ),
            LocationRow(
              label: 'Locatie A',
              controller: _locationAController,
              onChanged: (_) => _save(),
              onPick: _locationAOptions.isEmpty ? null : _pickLocationA,
            ),
            LocationRow(
              label: 'Locatie B',
              controller: _locationBController,
              onChanged: (_) => _save(),
              onPick: _locationBOptions.isEmpty ? null : _pickLocationB,
            ),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: CustomDropdown(
                    label: 'Installatie onderdeel',
                    value: defect.installationComponent.isEmpty ? null : defect.installationComponent,
                    items: const [
                      'Verdeler',
                      'Productielijn',
                      'Machine',
                      'Gebouw',
                      'Verdeler-no break',
                      'Verdeler-preferent',
                      'Regelkast',
                      'Zonnestroom',
                    ],
                    onChanged: (v) {
                      setState(() {
                        _defect = defect.copyWith(installationComponent: v ?? '');
                      });
                      _save();
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Expanded(
                        child: CustomTextField(
                          label: 'Naam/ code',
                          controller: _naamCodeController,
                          onChanged: (_) => _save(),
                        ),
                      ),
                      const SizedBox(width: 4),
                      Tooltip(
                        message: 'Kies Naam/code',
                        child: IconButton.outlined(
                          icon: const Icon(Icons.electrical_services_outlined),
                          onPressed: _switchboardOptions.isEmpty ? null : _pickNaamCode,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(
                  child: CustomDropdown(
                    label: l10n.classification,
                    value: defect.classification,
                    items: Defect.classifications,
                    onChanged: (v) {
                      setState(() {
                        _defect = defect.copyWith(classification: v);
                      });
                      _save();
                    },
                  ),
                ),
                const SizedBox(width: 8),
                Tooltip(
                  message: 'Opzoeken in rapport constateringen',
                  child: IconButton.outlined(
                    icon: const Icon(Icons.search),
                    onPressed: _constateringen.isEmpty
                        ? null
                        : _pickFromConstateringen,
                  ),
                ),
                const SizedBox(width: 12),
                _ScopeCheckboxes(
                  scope8: defect.scope8,
                  scope10: defect.scope10,
                  scope12: defect.scope12,
                  scopeEos: defect.scopeEos,
                  onChanged: (s8, s10, s12, sEos) {
                    setState(() {
                      _defect = defect.copyWith(
                        scope8: s8,
                        scope10: s10,
                        scope12: s12,
                        scopeEos: sEos,
                      );
                    });
                    _save();
                  },
                ),
              ],
            ),
            CustomTextField(
              label: l10n.defectDescription,
              controller: _descriptionController,
              onChanged: (_) => _save(),
              maxLines: 5,
            ),
            CustomTextField(
              label: 'Toelichting',
              controller: _toelichtingController,
              onChanged: (_) => _save(),
              maxLines: 3,
            ),
            const SizedBox(height: 16),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: _AnnotatablePhoto(
                    label: l10n.photo1,
                    photoPath: defect.photo1Path,
                    defectId: defect.id!,
                    photoNumber: 1,
                    classification: defect.classification,
                    aspectRatio: 4 / 3,
                    onPhotoSelected: (path) {
                      setState(() {
                        _defect = defect.copyWith(photo1Path: path);
                      });
                      _save();
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _AnnotatablePhoto(
                    label: l10n.photo2,
                    photoPath: defect.photo2Path,
                    defectId: defect.id!,
                    photoNumber: 2,
                    classification: defect.classification,
                    aspectRatio: 4 / 3,
                    onPhotoSelected: (path) {
                      setState(() {
                        _defect = defect.copyWith(photo2Path: path);
                      });
                      _save();
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Card(
              child: ListTile(
                leading: const Icon(Icons.build_outlined, color: Color(0xFF1976D2)),
                title: const Text(
                  'Herstel',
                  style: TextStyle(fontWeight: FontWeight.w500),
                ),
                subtitle: const Text(
                  'Herstelstatus, datum, uitvoerder en foto\'s',
                  style: TextStyle(fontSize: 12),
                ),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => HerstelPage(
                      defectId: defect.id!,
                      inspectionId: widget.inspectionId,
                      defectLabel: defect.locationFull.isNotEmpty
                          ? defect.locationFull
                          : 'Gebrek #${defect.id}',
                    ),
                  ),
                ),
              ),
            ),
            if (defect.classification == 'Rd') ...[
              const SizedBox(height: 8),
              Card(
                color: Colors.red.shade50,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(color: Colors.red.shade200),
                ),
                child: ListTile(
                  leading: Icon(Icons.warning_amber_rounded,
                      color: Colors.red.shade700),
                  title: const Text(
                    'Melding gevaarlijke situatie',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  subtitle: const Text(
                    'Genereer en mail de melding PDF',
                    style: TextStyle(fontSize: 12),
                  ),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => MeldingGevaarlijkeSituatiePage(
                        inspectionId: widget.inspectionId,
                        defect: defect,
                        defectNumber: _defectNumber,
                      ),
                    ),
                  ),
                ),
              ),
            ],
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _createSimilarDefect,
              icon: const Icon(Icons.add_circle_outline),
              label: const Text('Nieuw gebrek'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange.shade700,
                foregroundColor: Colors.white,
              ),
            ),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: () async {
                final messenger = ScaffoldMessenger.of(context);
                final navigator = Navigator.of(context);
                await _save();
                if (!mounted) return;
                messenger.showSnackBar(
                  SnackBar(content: Text(l10n.saved)),
                );
                if (widget.onSavedAndClose != null) {
                  widget.onSavedAndClose!();
                } else {
                  navigator.pop();
                }
              },
              child: Text(l10n.save),
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
            _btn(context, Icons.home_outlined, 'Inspectie',
                () => Navigator.push(context, MaterialPageRoute(
                      builder: (_) => InspectionMenuPage(inspectionId: inspectionId)))),
            _btn(context, Icons.electrical_services, 'Verdelers',
                () => Navigator.push(context, MaterialPageRoute(
                      builder: (_) => SwitchboardsListPage(inspectionId: inspectionId)))),
            _btn(context, Icons.solar_power, 'Zonnestroom',
                () => Navigator.push(context, MaterialPageRoute(
                      builder: (_) => SolarInstallationsListPage(inspectionId: inspectionId)))),
            _btn(context, Icons.warning_amber, 'Gebreken',
                () => Navigator.push(context, MaterialPageRoute(
                      builder: (_) => DefectsListPage(inspectionId: inspectionId)))),
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
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 22, color: const Color(0xFF1976D2)),
            Text(label, style: const TextStyle(fontSize: 10, color: Color(0xFF1976D2))),
          ],
        ),
      ),
    );
  }
}

// ── Rapport constateringen picker ─────────────────────────────────────────────

class _ConstateringenPicker extends StatefulWidget {
  final List<RapportConstatering> items;
  const _ConstateringenPicker({required this.items});

  @override
  State<_ConstateringenPicker> createState() => _ConstateringenPickerState();
}

class _ConstateringenPickerState extends State<_ConstateringenPicker> {
  String _query = '';

  List<RapportConstatering> get _filtered {
    if (_query.isEmpty) return widget.items;
    final q = _query.toLowerCase();
    return widget.items.where((c) =>
        c.groep.toLowerCase().contains(q) ||
        c.beschrijving.toLowerCase().contains(q) ||
        c.tekst.toLowerCase().contains(q)).toList();
  }

  Color _kwColor(String k) {
    switch (k) {
      case 'Er': return Colors.red;
      case 'Or': return Colors.orange;
      case 'Ge': return Colors.amber;
      case 'Bl': return Colors.blue;
      default:   return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filtered;

    // Build grouped structure
    final grouped = <String, List<RapportConstatering>>{};
    for (final c in filtered) {
      (grouped[c.groep.isEmpty ? '—' : c.groep] ??= []).add(c);
    }
    final sortedGroups = grouped.keys.toList()..sort();

    // Flat list: group headers + items
    final rows = <_PickerRow>[];
    for (final g in sortedGroups) {
      rows.add(_PickerRow(isHeader: true, group: g));
      for (final item in grouped[g]!) {
        rows.add(_PickerRow(isHeader: false, item: item));
      }
    }

    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Row(
              children: [
                const Expanded(
                  child: Text(
                    'Rapport constateringen',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: TextField(
              autofocus: true,
              decoration: const InputDecoration(
                hintText: 'Zoeken...',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
                isDense: true,
              ),
              onChanged: (v) => setState(() => _query = v),
            ),
          ),
          Expanded(
            child: rows.isEmpty
                ? Center(
                    child: Text(
                      'Geen resultaten voor "$_query".',
                      style: TextStyle(color: Colors.grey.shade600),
                    ),
                  )
                : ListView.builder(
                    itemCount: rows.length,
                    itemBuilder: (ctx, i) {
                      final row = rows[i];
                      if (row.isHeader) {
                        return Container(
                          padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                          color: Theme.of(context)
                              .colorScheme
                              .surfaceContainerHighest,
                          child: Text(
                            row.group!,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurfaceVariant,
                            ),
                          ),
                        );
                      }
                      final item = row.item!;
                      return ListTile(
                        leading: Container(
                          width: 12,
                          height: 12,
                          decoration: BoxDecoration(
                            color: _kwColor(item.kwalificatie),
                            shape: BoxShape.circle,
                          ),
                        ),
                        title: Text(
                          item.beschrijving,
                          style: const TextStyle(fontWeight: FontWeight.w500),
                        ),
                        subtitle: item.tekst.isNotEmpty
                            ? Text(
                                item.tekst,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey.shade600),
                              )
                            : null,
                        onTap: () => Navigator.pop(context, item),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

class _PickerRow {
  final bool isHeader;
  final String? group;
  final RapportConstatering? item;
  const _PickerRow({required this.isHeader, this.group, this.item});
}

// ── Scope checkboxes ──────────────────────────────────────────────────────────

class _ScopeCheckboxes extends StatelessWidget {
  final bool scope8;
  final bool scope10;
  final bool scope12;
  final bool scopeEos;
  final void Function(bool s8, bool s10, bool s12, bool sEos) onChanged;

  const _ScopeCheckboxes({
    required this.scope8,
    required this.scope10,
    required this.scope12,
    required this.scopeEos,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        const Text('Scope', style: TextStyle(fontSize: 11, color: Colors.grey)),
        const SizedBox(height: 2),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _ScopeChip(label: 'S8',  checked: scope8,   onTap: () => onChanged(!scope8, scope10, scope12, scopeEos)),
            _ScopeChip(label: 'S10', checked: scope10,  onTap: () => onChanged(scope8, !scope10, scope12, scopeEos)),
            _ScopeChip(label: 'S12', checked: scope12,  onTap: () => onChanged(scope8, scope10, !scope12, scopeEos)),
            _ScopeChip(label: 'EOS', checked: scopeEos, onTap: () => onChanged(scope8, scope10, scope12, !scopeEos)),
          ],
        ),
      ],
    );
  }
}

class _ScopeChip extends StatelessWidget {
  final String label;
  final bool checked;
  final VoidCallback onTap;

  const _ScopeChip({required this.label, required this.checked, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(4),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Checkbox(
            value: checked,
            onChanged: (_) => onTap(),
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            visualDensity: VisualDensity.compact,
          ),
          Text(label, style: const TextStyle(fontSize: 12)),
        ],
      ),
    );
  }
}

// ── Annotatable photo ─────────────────────────────────────────────────────────

class _AnnotatablePhoto extends StatefulWidget {
  final String label;
  final String? photoPath;
  final int defectId;
  final int photoNumber;
  final String classification;
  final ValueChanged<String> onPhotoSelected;
  final double? aspectRatio;

  const _AnnotatablePhoto({
    required this.label,
    required this.photoPath,
    required this.defectId,
    required this.photoNumber,
    required this.classification,
    required this.onPhotoSelected,
    this.aspectRatio,
  });

  @override
  State<_AnnotatablePhoto> createState() => _AnnotatablePhotoState();
}

class _AnnotatablePhotoState extends State<_AnnotatablePhoto> {
  final _db = DatabaseService();
  List<DefectAnnotation> _annotations = [];

  @override
  void initState() {
    super.initState();
    _loadAnnotations();
  }

  @override
  void didUpdateWidget(covariant _AnnotatablePhoto oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.photoPath != widget.photoPath ||
        oldWidget.defectId != widget.defectId) {
      _loadAnnotations();
    }
  }

  Future<void> _loadAnnotations() async {
    final annotations =
        await _db.getAnnotations(widget.defectId, widget.photoNumber);
    if (mounted) {
      setState(() {
        _annotations = annotations;
      });
    }
  }

  void _openAnnotationScreen() async {
    if (widget.photoPath == null) return;
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => DefectAnnotationScreen(
          defectId: widget.defectId,
          photoNumber: widget.photoNumber,
          photoPath: widget.photoPath!,
          classification: widget.classification,
        ),
      ),
    );
    _loadAnnotations();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final hasPhoto =
        widget.photoPath != null && File(widget.photoPath!).existsSync();
    final annotationCount = _annotations.length;
    final classColor =
        DefectAnnotation.getColorForClassification(widget.classification);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (hasPhoto && annotationCount > 0)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 6.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (widget.label.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 4.0),
                    child: Text(widget.label,
                        style: const TextStyle(
                            fontSize: 12, color: Colors.grey)),
                  ),
                GestureDetector(
                  onTap: _openAnnotationScreen,
                  child: AspectRatio(
                    aspectRatio: widget.aspectRatio ?? 4 / 3,
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        final displaySize = Size(
                          constraints.maxWidth,
                          constraints.maxHeight,
                        );
                        return ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Stack(
                            fit: StackFit.expand,
                            children: [
                              Image.file(
                                File(widget.photoPath!),
                                fit: BoxFit.cover,
                              ),
                              CustomPaint(
                                painter: DefectAnnotationPainter(
                                  annotations: _annotations,
                                  imageSize: displaySize,
                                  showHandles: false,
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ],
            ),
          )
        else
          PhotoContainer(
            label: widget.label,
            photoPath: widget.photoPath,
            onPhotoSelected: widget.onPhotoSelected,
            aspectRatio: widget.aspectRatio,
          ),
        if (hasPhoto)
          Padding(
            padding: const EdgeInsets.only(bottom: 8.0),
            child: Row(
              children: [
                OutlinedButton.icon(
                  onPressed: _openAnnotationScreen,
                  icon: Icon(Icons.edit_note, size: 18, color: classColor),
                  label: Text(
                    annotationCount > 0
                        ? l10n.annotationsCount(annotationCount)
                        : l10n.annotatePhoto,
                    style: TextStyle(fontSize: 13, color: classColor),
                  ),
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: classColor.withValues(alpha: 0.5)),
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    minimumSize: Size.zero,
                  ),
                ),
                if (annotationCount > 0) ...[
                  const SizedBox(width: 8),
                  Icon(Icons.check_circle, size: 16, color: classColor),
                ],
              ],
            ),
          ),
      ],
    );
  }
}

// ── Switchboard picker ────────────────────────────────────────────────────────

class _SwitchboardPickerDialog extends StatefulWidget {
  final List<({String component, String name})> options;
  const _SwitchboardPickerDialog({required this.options});

  @override
  State<_SwitchboardPickerDialog> createState() => _SwitchboardPickerDialogState();
}

class _SwitchboardPickerDialogState extends State<_SwitchboardPickerDialog> {
  String _query = '';

  List<({String component, String name})> get _filtered {
    if (_query.isEmpty) return widget.options;
    final q = _query.toLowerCase();
    return widget.options
        .where((o) =>
            o.component.toLowerCase().contains(q) ||
            o.name.toLowerCase().contains(q))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filtered;
    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 60),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 8, 8),
            child: Row(
              children: [
                const Expanded(
                  child: Text(
                    'Kies Naam/code',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: TextField(
              autofocus: true,
              decoration: const InputDecoration(
                hintText: 'Zoeken...',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
                isDense: true,
              ),
              onChanged: (v) => setState(() => _query = v),
            ),
          ),
          Container(
            color: const Color(0xFFE3F2FD),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: const Row(
              children: [
                Expanded(
                  flex: 2,
                  child: Text(
                    'Installatie onderdeel',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Text(
                    'Naam/code',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: filtered.isEmpty
                ? Center(
                    child: Text(
                      _query.isEmpty
                          ? 'Geen verdelers beschikbaar.'
                          : 'Geen resultaten voor "$_query".',
                      style: TextStyle(color: Colors.grey.shade600),
                    ),
                  )
                : ListView.separated(
                    itemCount: filtered.length,
                    separatorBuilder: (_, _) => const Divider(height: 1),
                    itemBuilder: (ctx, i) {
                      final item = filtered[i];
                      return InkWell(
                        onTap: () => Navigator.pop(context, item),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 12),
                          child: Row(
                            children: [
                              Expanded(
                                flex: 2,
                                child: Text(
                                  item.component.isEmpty ? '—' : item.component,
                                  style: const TextStyle(fontSize: 14),
                                ),
                              ),
                              Expanded(
                                flex: 2,
                                child: Text(
                                  item.name,
                                  style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
