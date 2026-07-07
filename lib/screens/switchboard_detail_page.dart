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
import '../models/switchboard.dart';
import '../models/hoofdschakelaar_entry.dart';
import '../services/database_service.dart';
import '../widgets/custom_text_field.dart';
import '../widgets/location_picker_dialog.dart';
import '../widgets/location_row.dart';
import '../widgets/custom_dropdown.dart';
import '../widgets/photo_container.dart';
import '../widgets/checklist_item.dart';
import '../widgets/switchboard_measurements_section.dart';
import '../models/defect.dart';
import 'home_page.dart';
import 'inspection_menu_page.dart';
import 'switchboards_list_page.dart';
import 'solar_installations_list_page.dart';
import 'defect_detail_page.dart';
import 'defects_list_page.dart';

class SwitchboardDetailPage extends StatefulWidget {
  final int switchboardId;
  final int inspectionId;

  const SwitchboardDetailPage({super.key, required this.switchboardId, required this.inspectionId});

  @override
  State<SwitchboardDetailPage> createState() => _SwitchboardDetailPageState();
}

class _SwitchboardDetailPageState extends State<SwitchboardDetailPage> {
  final _db = DatabaseService();

  final _nameController = TextEditingController();
  final _locationController = TextEditingController();
  final _locationAController = TextEditingController();
  final _locationBController = TextEditingController();
  final _opmerkingController = TextEditingController();
  final _kortsluitstroomController = TextEditingController();

  Switchboard? _switchboard;
  bool _loading = true;
  bool _showImpedanceTable = false;
  bool _showMeetgegevens = false;

  List<HoofdschakelaarEntry> _hoofdschakelaars = [];
  int _nextHoofdschakelaarId = 1;

  List<String> _systems = ['TT', 'TN-S', 'TN-C'];
  List<String> _protections = ['B 40 A', 'C 40 A', 'Gl 50 A', 'Gl 63 A'];
  List<String> _protectionClasses = ['IP44', 'IP54'];
  List<String> _cableTypes = ['NYY', 'NAYY', 'VVG', 'VVGF', 'XGB', 'AXGB', 'FG7', 'H07V-U', 'H07V-R'];
  List<String> _cables = ['6', '10', '16', '25', '35'];
  List<String> _cableLengths = ['25', '50', '100'];
  List<String> _mainSwitchCurrents = [
    '25', '40', '63', '80', '100', '125', '160', '200', '250'
  ];
  List<String> _mainSwitchPoles = ['1', '2', '3', '4'];
  List<String> _karakteristieken = ['B', 'C', 'D', 'Gg'];
  List<String> _locationOptions = [];
  List<String> _locationAOptions = [];
  List<String> _locationBOptions = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final sb = await _db.getSwitchboard(widget.switchboardId);
    if (sb == null) {
      if (mounted) Navigator.pop(context);
      return;
    }

    // Load standards for dropdowns
    final systems = await _db.getStandards('system');
    final protections = await _db.getStandards('protection');
    final protClasses = await _db.getStandards('protection_class');
    final cables = await _db.getStandards('cable');
    final cableLengths = await _db.getStandards('cable_length');
    final mainSwitch = await _db.getStandards('main_switch');
    final mainPoles = await _db.getStandards('main_switch_poles');
    final karakteristieken = await _db.getStandards('karakteristiek');
    final cableTypeStandards = await _db.getStandards('cable_type');
    final locationStandards = await _db.getStandards('location');
    final locationAStandards = await _db.getStandards('location_a');
    final locationBStandards = await _db.getStandards('location_b');

    _nameController.text = sb.name;
    _locationController.text = sb.location;
    _locationAController.text = sb.locationA;
    _locationBController.text = sb.locationB;
    _opmerkingController.text = sb.opmerking;
    _kortsluitstroomController.text = sb.shortCircuitCurrent?.toString() ?? '';

    // Migrate legacy single-value fields to hoofdschakelaars list on first load.
    var hoofdschakelaars = sb.hoofdschakelaars;
    var nextId = 1;
    if (hoofdschakelaars.isNotEmpty) {
      nextId = hoofdschakelaars.map((e) => e.id).reduce((a, b) => a > b ? a : b) + 1;
    } else if (sb.cableType != null ||
        sb.cableCrossSection != null ||
        sb.cableLength != null ||
        sb.mainSwitchCurrent != null ||
        sb.mainSwitchPoles != null ||
        sb.protection.isNotEmpty ||
        sb.shortCircuitCurrent != null) {
      hoofdschakelaars = [
        HoofdschakelaarEntry(
          id: 1,
          leidingType: sb.cableType ?? '',
          leidingDoorsnede: sb.cableCrossSection?.toString() ?? '',
          leidingLengte: sb.cableLength?.toString() ?? '',
          hoofdschakelaar: sb.mainSwitchCurrent?.toString() ?? '',
          aantalPolen: sb.mainSwitchPoles?.toString() ?? '',
          voorbeveiliging: sb.protection,
          kortsluitstroom: sb.shortCircuitCurrent?.toString() ?? '',
        ),
      ];
      nextId = 2;
    }

    setState(() {
      _switchboard = sb;
      _hoofdschakelaars = hoofdschakelaars;
      _nextHoofdschakelaarId = nextId;
      _showImpedanceTable =
          sb.electricalMeasurements.values.any((v) => v.isNotEmpty);
      if (cableTypeStandards.isNotEmpty) {
        _cableTypes = cableTypeStandards.map((s) => s.value).toList();
      }
      if (systems.isNotEmpty) _systems = systems.map((s) => s.value).toList();
      if (protections.isNotEmpty) {
        _protections = protections.map((s) => s.value).toList();
      }
      if (protClasses.isNotEmpty) {
        _protectionClasses = protClasses.map((s) => s.value).toList();
      }
      if (cables.isNotEmpty) _cables = cables.map((s) => s.value).toList();
      if (cableLengths.isNotEmpty) {
        _cableLengths = cableLengths.map((s) => s.value).toList();
      }
      if (mainSwitch.isNotEmpty) {
        _mainSwitchCurrents = mainSwitch.map((s) => s.value).toList();
      }
      if (mainPoles.isNotEmpty) {
        _mainSwitchPoles = mainPoles.map((s) => s.value).toList();
      }
      if (karakteristieken.isNotEmpty) {
        _karakteristieken = karakteristieken.map((s) => s.value).toList();
      }
      if (locationStandards.isNotEmpty) {
        _locationOptions = locationStandards.map((s) => s.value).toList();
      }
      _locationAOptions = locationAStandards.map((s) => s.value).toList();
      _locationBOptions = locationBStandards.map((s) => s.value).toList();
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

  void _setAllVisual(String value) {
    final updated = Map<String, String>.fromEntries(
      Switchboard.visualInspectionItems.map((k) => MapEntry(k, value)),
    );
    setState(() {
      _switchboard = _switchboard!.copyWith(visualInspection: updated);
    });
    _save();
  }

  void _setAllMeasurements(String value) {
    final updated = Map<String, String>.fromEntries(
      Switchboard.measurementItems.map((k) => MapEntry(k, value)),
    );
    setState(() {
      _switchboard = _switchboard!.copyWith(measurements: updated);
    });
    _save();
  }

  Future<void> _save() async {
    if (_switchboard == null) return;
    final first = _hoofdschakelaars.isNotEmpty ? _hoofdschakelaars.first : null;
    final updated = _switchboard!.copyWith(
      name: _nameController.text,
      location: _locationController.text,
      locationA: _locationAController.text,
      locationB: _locationBController.text,
      opmerking: _opmerkingController.text,
      hoofdschakelaars: _hoofdschakelaars,
      // Sync first entry back to legacy fields for PDF/XML export.
      cableType: first?.leidingType.isNotEmpty == true ? first!.leidingType : null,
      cableCrossSection: int.tryParse(first?.leidingDoorsnede ?? ''),
      cableLength: int.tryParse(first?.leidingLengte ?? ''),
      mainSwitchCurrent: int.tryParse(first?.hoofdschakelaar ?? ''),
      mainSwitchPoles: int.tryParse(first?.aantalPolen ?? ''),
      protection: first?.voorbeveiliging.isNotEmpty == true
          ? first!.voorbeveiliging
          : _switchboard!.protection,
      shortCircuitCurrent: int.tryParse(_kortsluitstroomController.text),
    );
    await _db.updateSwitchboard(updated);
    _switchboard = updated;
  }

  Future<void> _createDefect() async {
    if (_switchboard == null) return;
    await _save();
    final sb = _switchboard!;
    final defect = Defect(
      inspectionId: widget.inspectionId,
      location: sb.location,
      locationA: sb.locationA,
      locationB: sb.locationB,
      installationComponent: sb.installationComponent,
      naamCode: sb.name,
    );
    final id = await _db.insertDefect(defect);
    if (!mounted) return;
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

  @override
  void dispose() {
    _save();
    _nameController.dispose();
    _locationController.dispose();
    _locationAController.dispose();
    _locationBController.dispose();
    _opmerkingController.dispose();
    _kortsluitstroomController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Scaffold(
        appBar: AppBar(title: Text(AppLocalizations.of(context).switchboard)),
        body: Column(
          children: [
            _NavBar(inspectionId: widget.inspectionId),
            const Expanded(child: Center(child: CircularProgressIndicator())),
          ],
        ),
      );
    }

    final sb = _switchboard!;
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(sb.name.isNotEmpty ? sb.name : l10n.switchboard),
      ),
      body: Column(
        children: [
          _NavBar(inspectionId: widget.inspectionId),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: CustomDropdown(
                    label: 'Installatie onderdeel',
                    value: sb.installationComponent.isEmpty ? null : sb.installationComponent,
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
                        _switchboard = sb.copyWith(installationComponent: v ?? '');
                      });
                      _save();
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: CustomTextField(
                    label: l10n.switchboardName,
                    controller: _nameController,
                    onChanged: (_) => _save(),
                  ),
                ),
              ],
            ),
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
                    label: l10n.system,
                    value: sb.system,
                    items: _systems,
                    onChanged: (v) {
                      setState(() {
                        _switchboard = sb.copyWith(system: v);
                      });
                      _save();
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: CustomDropdown(
                    label: 'Beschermingsklasse',
                    value: sb.beschermingsklasse.isEmpty ? null : sb.beschermingsklasse,
                    items: const ['I', 'II', 'I/II'],
                    onChanged: (v) {
                      setState(() {
                        _switchboard = sb.copyWith(beschermingsklasse: v ?? '');
                      });
                      _save();
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: CustomDropdown(
                    label: l10n.protectionClass,
                    value: sb.protectionClass,
                    items: _protectionClasses,
                    onChanged: (v) {
                      setState(() {
                        _switchboard = sb.copyWith(protectionClass: v);
                      });
                      _save();
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: CustomTextField(
                    label: l10n.shortCircuit,
                    controller: _kortsluitstroomController,
                    keyboardType: TextInputType.number,
                    onChanged: (_) => _save(),
                  ),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.only(top: 12.0, bottom: 4.0),
              child: Row(
                children: [
                  const Text(
                    'Hoofdschakelaars',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1976D2),
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.add_circle, color: Color(0xFF1976D2)),
                    tooltip: 'Hoofdschakelaar toevoegen',
                    onPressed: () {
                      setState(() {
                        _hoofdschakelaars = [
                          ..._hoofdschakelaars,
                          HoofdschakelaarEntry(id: _nextHoofdschakelaarId++),
                        ];
                      });
                      _save();
                    },
                  ),
                ],
              ),
            ),
            ..._hoofdschakelaars.asMap().entries.map((mapEntry) {
              final index = mapEntry.key;
              final hs = mapEntry.value;
              return _HoofdschakelaarCard(
                key: ValueKey(hs.id),
                index: index,
                entry: hs,
                cableTypes: _cableTypes,
                cableSizes: _cables,
                cableLengths: _cableLengths,
                mainSwitchCurrents: _mainSwitchCurrents,
                mainSwitchPoles: _mainSwitchPoles,
                karakteristieken: _karakteristieken,
                protections: _protections,
                onChanged: (updated) {
                  setState(() {
                    final list = List<HoofdschakelaarEntry>.from(_hoofdschakelaars);
                    list[index] = updated;
                    _hoofdschakelaars = list;
                  });
                  _save();
                },
                onDelete: () {
                  setState(() {
                    final list = List<HoofdschakelaarEntry>.from(_hoofdschakelaars);
                    list.removeAt(index);
                    _hoofdschakelaars = list;
                  });
                  _save();
                },
              );
            }),
            const SizedBox(height: 16),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: PhotoContainer(
                    label: l10n.photo1,
                    photoPath: sb.photo1Path,
                    onPhotoSelected: (path) {
                      setState(() {
                        _switchboard = sb.copyWith(photo1Path: path);
                      });
                      _save();
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: PhotoContainer(
                    label: l10n.photo2,
                    photoPath: sb.photo2Path,
                    onPhotoSelected: (path) {
                      setState(() {
                        _switchboard = sb.copyWith(photo2Path: path);
                      });
                      _save();
                    },
                  ),
                ),
              ],
            ),
            _ChecklistHeader(
              title: l10n.visualInspection,
              onSetAll: _setAllVisual,
              yes: l10n.yes, no: l10n.no, na: l10n.na,
            ),
            ...Switchboard.visualInspectionItems.map((item) {
              return ChecklistItem(
                label: item,
                value: sb.visualInspection[item] ?? 'N.v.t.',
                onChanged: (v) {
                  final updated = Map<String, String>.from(sb.visualInspection);
                  updated[item] = v;
                  setState(() {
                    _switchboard = sb.copyWith(visualInspection: updated);
                  });
                  _save();
                },
              );
            }),
            _ChecklistHeader(
              title: l10n.measurements,
              onSetAll: _setAllMeasurements,
              yes: l10n.yes, no: l10n.no, na: l10n.na,
            ),
            ...Switchboard.measurementItems.map((item) {
              return ChecklistItem(
                label: item,
                value: sb.measurements[item] ?? 'N.v.t.',
                onChanged: (v) {
                  final updated = Map<String, String>.from(sb.measurements);
                  updated[item] = v;
                  setState(() {
                    _switchboard = sb.copyWith(measurements: updated);
                  });
                  _save();
                },
              );
            }),
            const SizedBox(height: 8),
            CustomTextField(
              label: 'Opmerking',
              controller: _opmerkingController,
              maxLines: 3,
              onChanged: (_) => _save(),
            ),
            InkWell(
              onTap: () => setState(() => _showImpedanceTable = !_showImpedanceTable),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: Row(
                  children: [
                    const Text(
                      'Elektrische metingen',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1976D2),
                      ),
                    ),
                    const Spacer(),
                    Icon(
                      _showImpedanceTable
                          ? Icons.expand_less
                          : Icons.expand_more,
                      color: const Color(0xFF1976D2),
                    ),
                  ],
                ),
              ),
            ),
            if (_showImpedanceTable)
              _ElectricalMeasurementsTable(
                data: sb.electricalMeasurements,
                onChanged: (key, value) {
                  final updated =
                      Map<String, String>.from(sb.electricalMeasurements);
                  updated[key] = value;
                  setState(() {
                    _switchboard = sb.copyWith(electricalMeasurements: updated);
                  });
                  _save();
                },
              ),
            InkWell(
              onTap: () => setState(() => _showMeetgegevens = !_showMeetgegevens),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: Row(
                  children: [
                    const Text(
                      'Meetgegevens',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1976D2),
                      ),
                    ),
                    const Spacer(),
                    Icon(
                      _showMeetgegevens ? Icons.expand_less : Icons.expand_more,
                      color: const Color(0xFF1976D2),
                    ),
                  ],
                ),
              ),
            ),
            if (_showMeetgegevens && sb.id != null)
              SwitchboardMeasurementsSection(
                inspectionId: widget.inspectionId,
                switchboardId: sb.id!,
              ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _createDefect,
              icon: const Icon(Icons.warning_amber_outlined),
              label: const Text('Gebrek aanmaken'),
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
                navigator.pop();
              },
              child: Text(l10n.save),
            ),
            const SizedBox(height: 16),
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

class _ChecklistHeader extends StatelessWidget {
  final String title;
  final void Function(String) onSetAll;
  final String yes, no, na;

  const _ChecklistHeader({
    required this.title,
    required this.onSetAll,
    required this.yes,
    required this.no,
    required this.na,
  });

  @override
  Widget build(BuildContext context) {
    const titleStyle = TextStyle(
      fontSize: 16,
      fontWeight: FontWeight.bold,
      color: Color(0xFF1976D2),
    );
    final btnStyle = OutlinedButton.styleFrom(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
      minimumSize: Size.zero,
      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
      side: const BorderSide(color: Color(0xFF1976D2)),
      foregroundColor: const Color(0xFF1976D2),
    );

    return Padding(
      padding: const EdgeInsets.only(top: 16.0, bottom: 4.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(title, style: titleStyle),
          const SizedBox(height: 8),
          Row(
            children: [
              const Expanded(flex: 3, child: SizedBox()),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 2),
                  child: OutlinedButton(
                    style: btnStyle,
                    onPressed: () => onSetAll('Ja'),
                    child: Text(yes),
                  ),
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 2),
                  child: OutlinedButton(
                    style: btnStyle,
                    onPressed: () => onSetAll('Nee'),
                    child: Text(no),
                  ),
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 2),
                  child: OutlinedButton(
                    style: btnStyle,
                    onPressed: () => onSetAll('N.v.t.'),
                    child: Text(na),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
        ],
      ),
    );
  }
}

// ── Electrical measurements table ──────────────────────────────────────────

class _ElectricalMeasurementsTable extends StatefulWidget {
  final Map<String, String> data;
  final void Function(String key, String value) onChanged;

  const _ElectricalMeasurementsTable({
    required this.data,
    required this.onChanged,
  });

  @override
  State<_ElectricalMeasurementsTable> createState() =>
      _ElectricalMeasurementsTableState();
}

class _ElectricalMeasurementsTableState
    extends State<_ElectricalMeasurementsTable> {
  static const _cellW = 52.0;
  static const _labelW = 96.0;
  static const _rowH = 36.0;
  static const _hdrH = 26.0;

  // 11 data column keys in left-to-right order
  static const _cols = [
    'l1',
    'l1_l2', 'l1_l3', 'l1_n', 'l1_pe',
    'l2_l3', 'l2_n', 'l2_pe',
    'l3_n', 'l3_pe',
    'n_pe',
  ];

  // Group headers (row 1): label + how many sub-columns they span
  static const _groups = [
    ('L1', 1),
    ('L1', 4),
    ('L2', 3),
    ('L3', 2),
    ('N', 1),
  ];

  // Sub-column labels (row 2), same length as _cols
  static const _subLabels = [
    '', 'L2', 'L3', 'N', 'Pe', 'L3', 'N', 'Pe', 'N', 'Pe', 'Pe',
  ];

  // Which columns are active per row (null = all active)
  static const _activeI    = [0];           // only L1
  static const _activeRiso = [4, 7, 9, 10]; // L1-Pe, L2-Pe, L3-Pe, N-Pe

  final Map<String, TextEditingController> _ctrl = {};
  late String _zcirUnit;
  late String _ikUnit;

  @override
  void initState() {
    super.initState();
    _zcirUnit = widget.data['zcir_unit'] ?? 'Ω';
    _ikUnit   = widget.data['ik_unit'] ?? 'kA';
    _buildControllers('un',   null);
    _buildControllers('zcir', null);
    _buildControllers('ik',   null);
    _buildControllers('i',    _activeI);
    _buildControllers('riso', _activeRiso);
  }

  void _buildControllers(String prefix, List<int>? active) {
    for (var i = 0; i < _cols.length; i++) {
      if (active == null || active.contains(i)) {
        final key = '${prefix}_${_cols[i]}';
        _ctrl[key] = TextEditingController(text: widget.data[key] ?? '');
      }
    }
  }

  @override
  void dispose() {
    for (final c in _ctrl.values) {
      c.dispose();
    }
    super.dispose();
  }

  // ── builders ──────────────────────────────────────────────────────────────

  Widget _hdrCell(String text, {double width = _cellW}) {
    return Container(
      width: width,
      height: _hdrH,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: const Color(0xFFE3F2FD),
        border: Border.all(color: Colors.grey.shade400, width: 0.5),
      ),
      child: text.isEmpty
          ? null
          : Text(
              text,
              style: const TextStyle(
                  fontSize: 11, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
    );
  }

  Widget _cell(String key, bool active) {
    if (!active) {
      return Container(
        width: _cellW,
        height: _rowH,
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          border: Border.all(color: Colors.grey.shade300, width: 0.5),
        ),
      );
    }
    return Container(
      width: _cellW,
      height: _rowH,
      decoration: BoxDecoration(
        border: Border.all(color: const Color(0xFF90CAF9), width: 0.8),
      ),
      child: TextField(
        controller: _ctrl[key],
        keyboardType:
            const TextInputType.numberWithOptions(decimal: true, signed: true),
        textAlign: TextAlign.center,
        style: const TextStyle(fontSize: 12),
        decoration: const InputDecoration(
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(horizontal: 2, vertical: 6),
          isDense: true,
        ),
        onChanged: (v) => widget.onChanged(key, v),
      ),
    );
  }

  Widget _labelCell(String text) => Container(
        width: _labelW,
        height: _rowH,
        padding: const EdgeInsets.symmetric(horizontal: 6),
        alignment: Alignment.centerLeft,
        decoration: BoxDecoration(
          color: const Color(0xFFE3F2FD),
          border: Border.all(color: Colors.grey.shade400, width: 0.5),
        ),
        child: Text(text,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
      );

  Widget _labelCellWithUnit(
    String text,
    String unitKey,
    String currentUnit,
    List<String> units,
    void Function(String) onUnitChanged,
  ) =>
      Container(
        width: _labelW,
        height: _rowH,
        padding: const EdgeInsets.only(left: 6, right: 2),
        decoration: BoxDecoration(
          color: const Color(0xFFE3F2FD),
          border: Border.all(color: Colors.grey.shade400, width: 0.5),
        ),
        child: Row(
          children: [
            Text(text,
                style: const TextStyle(
                    fontSize: 12, fontWeight: FontWeight.w500)),
            const Spacer(),
            DropdownButton<String>(
              value: currentUnit,
              isDense: true,
              underline: const SizedBox(),
              style: const TextStyle(fontSize: 10, color: Colors.black87),
              icon: const Icon(Icons.arrow_drop_down, size: 14),
              items: units
                  .map((u) =>
                      DropdownMenuItem(value: u, child: Text(u)))
                  .toList(),
              onChanged: (v) {
                if (v == null) return;
                onUnitChanged(v);
                widget.onChanged(unitKey, v);
              },
            ),
          ],
        ),
      );

  Widget _dataRow(String label, String prefix, List<int>? active) => Row(
        children: [
          _labelCell(label),
          for (var i = 0; i < _cols.length; i++)
            _cell('${prefix}_${_cols[i]}',
                active == null || active.contains(i)),
        ],
      );

  Widget _dataRowWithUnit(
    String label,
    String prefix,
    String unitKey,
    String currentUnit,
    List<String> units,
    void Function(String) onUnitChanged,
  ) =>
      Row(
        children: [
          _labelCellWithUnit(
              label, unitKey, currentUnit, units, onUnitChanged),
          for (var i = 0; i < _cols.length; i++)
            _cell('${prefix}_${_cols[i]}', true),
        ],
      );

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header row 1: group labels
          Row(children: [
            _hdrCell('', width: _labelW),
            for (final g in _groups)
              _hdrCell(g.$1, width: g.$2 * _cellW),
          ]),
          // Header row 2: sub-column labels
          Row(children: [
            _hdrCell('', width: _labelW),
            for (final s in _subLabels) _hdrCell(s),
          ]),
          // Data rows
          _dataRow('Un (V)', 'un', null),
          _dataRowWithUnit(
            'Zcir',
            'zcir',
            'zcir_unit',
            _zcirUnit,
            const ['Ω', 'mΩ', 'kΩ'],
            (v) => setState(() => _zcirUnit = v),
          ),
          _dataRowWithUnit(
            'Ik',
            'ik',
            'ik_unit',
            _ikUnit,
            const ['kA', 'A'],
            (v) => setState(() => _ikUnit = v),
          ),
          _dataRow('I (A)', 'i', _activeI),
          _dataRow('Riso (MΩ)', 'riso', _activeRiso),
        ],
      ),
    );
  }
}

// ── Hoofdschakelaar card ───────────────────────────────────────────────────

class _HoofdschakelaarCard extends StatefulWidget {
  final int index;
  final HoofdschakelaarEntry entry;
  final List<String> cableTypes;
  final List<String> cableSizes;
  final List<String> cableLengths;
  final List<String> mainSwitchCurrents;
  final List<String> mainSwitchPoles;
  final List<String> karakteristieken;
  final List<String> protections;
  final void Function(HoofdschakelaarEntry) onChanged;
  final VoidCallback onDelete;

  const _HoofdschakelaarCard({
    super.key,
    required this.index,
    required this.entry,
    required this.cableTypes,
    required this.cableSizes,
    required this.cableLengths,
    required this.mainSwitchCurrents,
    required this.mainSwitchPoles,
    required this.karakteristieken,
    required this.protections,
    required this.onChanged,
    required this.onDelete,
  });

  @override
  State<_HoofdschakelaarCard> createState() => _HoofdschakelaarCardState();
}

class _HoofdschakelaarCardState extends State<_HoofdschakelaarCard> {
  late HoofdschakelaarEntry _entry;

  @override
  void initState() {
    super.initState();
    _entry = widget.entry;
  }

  void _update(HoofdschakelaarEntry updated) {
    setState(() => _entry = updated);
    widget.onChanged(updated);
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: const BorderSide(color: Color(0xFF90CAF9)),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 8, 4, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Text(
                  'Hoofdschakelaar ${widget.index + 1}',
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1976D2),
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.delete_outline, color: Colors.red),
                  tooltip: 'Verwijderen',
                  onPressed: widget.onDelete,
                ),
              ],
            ),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: 2,
                  child: CustomDropdown(
                    label: 'Leiding type',
                    value: _entry.leidingType.isEmpty ? null : _entry.leidingType,
                    items: widget.cableTypes,
                    onChanged: (v) => _update(_entry.copyWith(leidingType: v ?? '')),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: CustomDropdown(
                    label: 'Doorsnede (mm²)',
                    value: _entry.leidingDoorsnede.isEmpty ? null : _entry.leidingDoorsnede,
                    items: widget.cableSizes,
                    onChanged: (v) => _update(_entry.copyWith(leidingDoorsnede: v ?? '')),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: CustomDropdown(
                    label: 'Aders',
                    value: _entry.leidingAders.isEmpty ? null : _entry.leidingAders,
                    items: const ['1', '2', '3', '4', '5'],
                    onChanged: (v) => _update(_entry.copyWith(leidingAders: v ?? '')),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: CustomDropdown(
                    label: 'Lengte (m)',
                    value: _entry.leidingLengte.isEmpty ? null : _entry.leidingLengte,
                    items: widget.cableLengths,
                    onChanged: (v) => _update(_entry.copyWith(leidingLengte: v ?? '')),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: 2,
                  child: CustomDropdown(
                    label: 'Hoofdschakelaar (A)',
                    value: _entry.hoofdschakelaar.isEmpty ? null : _entry.hoofdschakelaar,
                    items: widget.mainSwitchCurrents,
                    onChanged: (v) => _update(_entry.copyWith(hoofdschakelaar: v ?? '')),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: CustomDropdown(
                    label: 'Aantal Polen',
                    value: _entry.aantalPolen.isEmpty ? null : _entry.aantalPolen,
                    items: widget.mainSwitchPoles,
                    onChanged: (v) => _update(_entry.copyWith(aantalPolen: v ?? '')),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: CustomDropdown(
                    label: 'Karakteristiek',
                    value: _entry.karakteristiek.isEmpty ? null : _entry.karakteristiek,
                    items: widget.karakteristieken,
                    onChanged: (v) => _update(_entry.copyWith(karakteristiek: v ?? '')),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  flex: 2,
                  child: CustomDropdown(
                    label: 'Voorbeveiliging',
                    value: _entry.voorbeveiliging.isEmpty ? null : _entry.voorbeveiliging,
                    items: widget.protections,
                    onChanged: (v) => _update(_entry.copyWith(voorbeveiliging: v ?? '')),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
