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
import '../models/solar_installation.dart';
import '../models/solar_inverter.dart';
import '../models/solar_vereffening.dart';
import '../services/database_service.dart';
import '../widgets/custom_dropdown.dart';
import '../widgets/custom_text_field.dart';
import '../widgets/location_picker_dialog.dart';
import '../widgets/location_row.dart';
import '../widgets/photo_container.dart';
import '../widgets/section_header.dart';
import 'home_page.dart';
import 'inspection_menu_page.dart';
import 'switchboards_list_page.dart';
import 'solar_installations_list_page.dart';
import 'defects_list_page.dart';
import 'solar_inverter_detail_page.dart';

class SolarInstallationDetailPage extends StatefulWidget {
  final int installationId;
  final int inspectionId;

  const SolarInstallationDetailPage({super.key, required this.installationId, required this.inspectionId});

  @override
  State<SolarInstallationDetailPage> createState() =>
      _SolarInstallationDetailPageState();
}

class _SolarInstallationDetailPageState
    extends State<SolarInstallationDetailPage> {
  final _db = DatabaseService();

  final _locationController = TextEditingController();
  final _locationAController = TextEditingController();
  final _locationBController = TextEditingController();
  final _sublocationController = TextEditingController();
  final _panelCountController = TextEditingController();
  final _inverterCountController = TextEditingController();
  final _wattPeakController = TextEditingController();
  final _constructionController = TextEditingController();
  final _tiltAngleController = TextEditingController();

  SolarInstallation? _installation;
  List<SolarInverter> _inverters = [];
  List<SolarVereffening> _vereffeningsrijen = [];
  final Map<int, TextEditingController> _rlowControllers = {};
  List<String> _locationOptions = [];
  List<String> _locationAOptions = [];
  List<String> _locationBOptions = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final inst = await _db.getSolarInstallation(widget.installationId);
    if (inst == null) {
      if (mounted) Navigator.pop(context);
      return;
    }

    _locationController.text = inst.location;
    _locationAController.text = inst.locationA;
    _locationBController.text = inst.locationB;
    _sublocationController.text = inst.panelSublocation;
    _panelCountController.text = inst.panelCount?.toString() ?? '';
    _inverterCountController.text = inst.inverterCount?.toString() ?? '';
    _wattPeakController.text = inst.wattPeak?.toString() ?? '';
    _constructionController.text = inst.constructionType;
    _tiltAngleController.text = inst.tiltAngle ?? '';

    final inverters = await _db.getSolarInverters(widget.installationId);
    final vereffeningsrijen = await _db.getSolarVereffeningsrijen(widget.installationId);
    final locationStandards = await _db.getStandards('location');
    final locationAStandards = await _db.getStandards('location_a');
    final locationBStandards = await _db.getStandards('location_b');

    for (final r in vereffeningsrijen) {
      _rlowControllers[r.id!] = TextEditingController(text: r.rlow);
    }
    setState(() {
      _installation = inst;
      _inverters = inverters;
      _vereffeningsrijen = vereffeningsrijen;
      _locationOptions = locationStandards.map((s) => s.value).toList();
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

  Future<void> _loadInverters() async {
    final inverters = await _db.getSolarInverters(widget.installationId);
    setState(() => _inverters = inverters);
  }

  Future<void> _addInverter() async {
    final id = await _db.insertSolarInverter(
      SolarInverter(
        solarInstallationId: widget.installationId,
        location: _locationController.text,
      ),
    );
    if (!mounted) return;
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => SolarInverterDetailPage(inverterId: id, inspectionId: widget.inspectionId),
      ),
    );
    _loadInverters();
  }

  Future<void> _deleteInverter(SolarInverter inverter) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Omvormer verwijderen'),
        content: const Text(
            'Weet je zeker dat je deze omvormer wilt verwijderen?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Annuleren'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Verwijderen',
                style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await _db.deleteSolarInverter(inverter.id!);
      _loadInverters();
    }
  }

  Future<void> _addVereffening() async {
    final volgnummer = _vereffeningsrijen.length + 1;
    final id = await _db.insertSolarVereffening(
      SolarVereffening(
        solarInstallationId: widget.installationId,
        volgnummer: volgnummer,
      ),
    );
    final row = SolarVereffening(
      id: id,
      solarInstallationId: widget.installationId,
      volgnummer: volgnummer,
    );
    _rlowControllers[id] = TextEditingController();
    setState(() => _vereffeningsrijen.add(row));
  }

  Future<void> _duplicateVereffening(SolarVereffening row) async {
    final volgnummer = _vereffeningsrijen.length + 1;
    final id = await _db.insertSolarVereffening(
      SolarVereffening(
        solarInstallationId: widget.installationId,
        volgnummer: volgnummer,
        omschrijving: row.omschrijving,
        leidingType: row.leidingType,
        leidingMm2: row.leidingMm2,
        rlow: row.rlow,
      ),
    );
    final newRow = SolarVereffening(
      id: id,
      solarInstallationId: widget.installationId,
      volgnummer: volgnummer,
      omschrijving: row.omschrijving,
      leidingType: row.leidingType,
      leidingMm2: row.leidingMm2,
      rlow: row.rlow,
    );
    _rlowControllers[id] = TextEditingController(text: row.rlow);
    setState(() => _vereffeningsrijen.add(newRow));
  }

  Future<void> _deleteVereffening(SolarVereffening row) async {
    await _db.deleteSolarVereffening(row.id!);
    _rlowControllers.remove(row.id);
    setState(() {
      _vereffeningsrijen.removeWhere((r) => r.id == row.id);
      for (int i = 0; i < _vereffeningsrijen.length; i++) {
        _vereffeningsrijen[i] = _vereffeningsrijen[i].copyWith(volgnummer: i + 1);
        _db.updateSolarVereffening(_vereffeningsrijen[i]);
      }
    });
  }

  Future<void> _saveVereffening(SolarVereffening row) async {
    final ctrl = _rlowControllers[row.id!];
    final updated = row.copyWith(rlow: ctrl?.text ?? row.rlow);
    await _db.updateSolarVereffening(updated);
    final idx = _vereffeningsrijen.indexWhere((r) => r.id == row.id);
    if (idx != -1) _vereffeningsrijen[idx] = updated;
  }

  Future<void> _reorderVereffening(SolarVereffening row, int newVolgnummer) async {
    final oldIdx = _vereffeningsrijen.indexWhere((r) => r.id == row.id);
    final newIdx = newVolgnummer - 1;
    if (oldIdx == newIdx) return;
    final updated = List<SolarVereffening>.from(_vereffeningsrijen);
    updated.removeAt(oldIdx);
    updated.insert(newIdx, row);
    for (int i = 0; i < updated.length; i++) {
      updated[i] = updated[i].copyWith(volgnummer: i + 1);
      await _db.updateSolarVereffening(updated[i]);
    }
    setState(() => _vereffeningsrijen = updated);
  }

  Future<void> _pickOmschrijving(SolarVereffening row) async {
    const options = [
      'Van HAR naar gasleiding',
      'Van HAR naar waterleiding',
      'Van HAR naar constructie',
      'Van HAR naar dakconstructie',
      'Van HAR naar omvormer',
      'Van HAR naar dakrail',
      'Tussen omvormers',
      'Van HAR naar aardleiding',
      'Van HAR naar aardingselektrode',
    ];
    final picked = await showDialog<String>(
      context: context,
      builder: (ctx) => SimpleDialog(
        title: const Text('Kies omschrijving'),
        children: options
            .map((o) => SimpleDialogOption(
                  onPressed: () => Navigator.pop(ctx, o),
                  child: Text(o),
                ))
            .toList(),
      ),
    );
    if (picked == null) return;
    final updated = row.copyWith(omschrijving: picked);
    await _db.updateSolarVereffening(updated);
    final idx = _vereffeningsrijen.indexWhere((r) => r.id == row.id);
    if (idx != -1) setState(() => _vereffeningsrijen[idx] = updated);
  }

  Widget _buildVereffeningTable() {
    const headerStyle = TextStyle(
      fontSize: 11,
      fontWeight: FontWeight.bold,
      color: Color(0xFF1976D2),
    );
    const cellDecoration = InputDecoration(
      isDense: true,
      contentPadding: EdgeInsets.symmetric(horizontal: 6, vertical: 8),
      border: OutlineInputBorder(),
    );

    final n = _vereffeningsrijen.length;

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Top header ──
          Row(
            children: [
              const SizedBox(width: 62, child: Text('Groep', style: headerStyle)),
              const SizedBox(width: 4),
              const SizedBox(
                width: 332,
                child: Text('Omschrijving', style: headerStyle),
              ),
              const SizedBox(width: 4),
              Container(
                width: 164,
                alignment: Alignment.center,
                decoration: const BoxDecoration(
                  border: Border(
                    bottom: BorderSide(color: Color(0xFF1976D2), width: 1.5),
                  ),
                ),
                child: const Padding(
                  padding: EdgeInsets.only(bottom: 2),
                  child: Text('Leiding', style: headerStyle),
                ),
              ),
              const SizedBox(width: 4),
              const SizedBox(
                width: 80,
                child: Text('Rlow\n[Ω]', style: headerStyle),
              ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: _addVereffening,
                child: const CircleAvatar(
                  radius: 16,
                  backgroundColor: Colors.green,
                  child: Icon(Icons.add, color: Colors.white, size: 20),
                ),
              ),
            ],
          ),
          // ── Sub-header ──
          const Row(
            children: [
              SizedBox(width: 62),
              SizedBox(width: 4),
              SizedBox(width: 332),
              SizedBox(width: 4),
              SizedBox(width: 80, child: Text('Type', style: headerStyle)),
              SizedBox(width: 4),
              SizedBox(width: 80, child: Text('L/N/PE\n[mm²]', style: headerStyle)),
            ],
          ),
          const Divider(height: 4),
          if (_vereffeningsrijen.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 8),
              child: Text(
                'Nog geen vereffeningsrijen.',
                style: TextStyle(color: Colors.grey),
              ),
            ),
          for (final row in _vereffeningsrijen)
            Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Groep dropdown (reorder)
                  SizedBox(
                    width: 62,
                    child: DropdownButtonFormField<int>(
                      initialValue: row.volgnummer,
                      decoration: cellDecoration,
                      style: const TextStyle(fontSize: 13, color: Colors.black87),
                      items: List.generate(
                        n,
                        (i) => DropdownMenuItem(value: i + 1, child: Text('${i + 1}')),
                      ),
                      onChanged: (v) {
                        if (v != null) _reorderVereffening(row, v);
                      },
                    ),
                  ),
                  const SizedBox(width: 4),
                  // Omschrijving + picker
                  SizedBox(
                    width: 300,
                    child: TextFormField(
                      initialValue: row.omschrijving,
                      style: const TextStyle(fontSize: 13),
                      decoration: cellDecoration,
                      onChanged: (v) async {
                        final updated = row.copyWith(omschrijving: v);
                        await _db.updateSolarVereffening(updated);
                        final idx = _vereffeningsrijen.indexWhere((r) => r.id == row.id);
                        if (idx != -1) _vereffeningsrijen[idx] = updated;
                      },
                    ),
                  ),
                  SizedBox(
                    width: 32,
                    child: IconButton(
                      padding: EdgeInsets.zero,
                      icon: const Icon(Icons.arrow_drop_down,
                          color: Colors.green, size: 22),
                      onPressed: () => _pickOmschrijving(row),
                    ),
                  ),
                  const SizedBox(width: 4),
                  // Type dropdown
                  SizedBox(
                    width: 80,
                    child: DropdownButtonFormField<String>(
                      initialValue: row.leidingType.isEmpty ? null : row.leidingType,
                      decoration: cellDecoration,
                      style: const TextStyle(fontSize: 13, color: Colors.black87),
                      items: const ['Cu', 'Al', 'Cu/Al']
                          .map((t) => DropdownMenuItem(value: t, child: Text(t)))
                          .toList(),
                      onChanged: (v) async {
                        if (v == null) return;
                        final updated = row.copyWith(leidingType: v);
                        await _db.updateSolarVereffening(updated);
                        final idx = _vereffeningsrijen.indexWhere((r) => r.id == row.id);
                        if (idx != -1) setState(() => _vereffeningsrijen[idx] = updated);
                      },
                    ),
                  ),
                  const SizedBox(width: 4),
                  // L/N/PE [mm²] dropdown
                  SizedBox(
                    width: 80,
                    child: DropdownButtonFormField<String>(
                      initialValue: row.leidingMm2.isEmpty ? null : row.leidingMm2,
                      decoration: cellDecoration,
                      style: const TextStyle(fontSize: 13, color: Colors.black87),
                      items: const [
                        '4', '6', '10', '16', '25', '35', '50', '70', '95', '120',
                      ]
                          .map((v) => DropdownMenuItem(value: v, child: Text(v)))
                          .toList(),
                      onChanged: (v) async {
                        if (v == null) return;
                        final updated = row.copyWith(leidingMm2: v);
                        await _db.updateSolarVereffening(updated);
                        final idx = _vereffeningsrijen.indexWhere((r) => r.id == row.id);
                        if (idx != -1) setState(() => _vereffeningsrijen[idx] = updated);
                      },
                    ),
                  ),
                  const SizedBox(width: 4),
                  // Rlow text field
                  SizedBox(
                    width: 80,
                    child: TextFormField(
                      controller: _rlowControllers[row.id!],
                      style: const TextStyle(fontSize: 13),
                      decoration: cellDecoration,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      onChanged: (_) => _saveVereffening(row),
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Duplicate button
                  SizedBox(
                    width: 36,
                    height: 36,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF1976D2),
                        shape: const CircleBorder(),
                        padding: EdgeInsets.zero,
                      ),
                      onPressed: () => _duplicateVereffening(row),
                      child: const Icon(Icons.copy, color: Colors.white, size: 16),
                    ),
                  ),
                  const SizedBox(width: 4),
                  // Delete button
                  SizedBox(
                    width: 36,
                    height: 36,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        shape: const CircleBorder(),
                        padding: EdgeInsets.zero,
                      ),
                      onPressed: () => _deleteVereffening(row),
                      child: const Icon(Icons.close, color: Colors.white, size: 18),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _save() async {
    if (_installation == null) return;
    final updated = _installation!.copyWith(
      location: _locationController.text,
      locationA: _locationAController.text,
      locationB: _locationBController.text,
      panelSublocation: _sublocationController.text,
      panelCount: int.tryParse(_panelCountController.text),
      inverterCount: int.tryParse(_inverterCountController.text),
      wattPeak: int.tryParse(_wattPeakController.text),
      constructionType: _constructionController.text,
      tiltAngle: _tiltAngleController.text,
    );
    await _db.updateSolarInstallation(updated);
    _installation = updated;
  }

  @override
  void dispose() {
    _save();
    _locationController.dispose();
    _locationAController.dispose();
    _locationBController.dispose();
    _sublocationController.dispose();
    _panelCountController.dispose();
    _inverterCountController.dispose();
    _wattPeakController.dispose();
    _constructionController.dispose();
    _tiltAngleController.dispose();
    for (final c in _rlowControllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Scaffold(
        appBar: AppBar(title: Text(AppLocalizations.of(context).solarInstallation)),
        body: Column(
          children: [
            _NavBar(inspectionId: widget.inspectionId),
            const Expanded(child: Center(child: CircularProgressIndicator())),
          ],
        ),
      );
    }

    final inst = _installation!;
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.solarInstallation)),
      body: Column(
        children: [
          _NavBar(inspectionId: widget.inspectionId),
          Expanded(
            child: SingleChildScrollView(
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
            CustomTextField(
              label: l10n.panelSublocation,
              controller: _sublocationController,
              onChanged: (_) => _save(),
            ),
            CustomTextField(
              label: l10n.numberOfPanels,
              controller: _panelCountController,
              onChanged: (_) => _save(),
              keyboardType: TextInputType.number,
            ),
            CustomTextField(
              label: l10n.numberOfInverters,
              controller: _inverterCountController,
              onChanged: (_) => _save(),
              keyboardType: TextInputType.number,
            ),
            CustomTextField(
              label: l10n.wattPeak,
              controller: _wattPeakController,
              onChanged: (_) => _save(),
              keyboardType: TextInputType.number,
            ),
            CustomTextField(
              label: l10n.constructionType,
              controller: _constructionController,
              onChanged: (_) => _save(),
            ),
            SectionHeader(title: 'Opstelling'),
            CustomDropdown(
              label: 'Type gebouw',
              value: inst.buildingType,
              items: const [
                'Residentieel',
                'Utiliteitsgebouw',
                'Industriegebouw',
                'Lichte industrie',
                'Veestal',
                'Open veld',
              ],
              onChanged: (v) {
                setState(() {
                  _installation = inst.copyWith(buildingType: v);
                });
                _save();
              },
            ),
            CustomDropdown(
              label: 'Type dak',
              value: inst.roofType,
              items: const [
                'Plat dak',
                'Hellend dak',
                'In dak',
                'Op water',
                'Open veld',
              ],
              onChanged: (v) {
                setState(() {
                  _installation = inst.copyWith(roofType: v);
                });
                _save();
              },
            ),
            CustomDropdown(
              label: 'Oriëntatie',
              value: inst.orientation,
              items: const ['Zuid', 'Oost/ west', 'Oost', 'West', 'Noord'],
              onChanged: (v) {
                setState(() {
                  _installation = inst.copyWith(orientation: v);
                });
                _save();
              },
            ),
            CustomTextField(
              label: 'Hellingshoek (°)',
              controller: _tiltAngleController,
              onChanged: (_) => _save(),
              keyboardType: TextInputType.number,
            ),
            CustomDropdown(
              label: 'Frame',
              value: inst.frame,
              items: const ['Volledig geleidend', 'Kunststof gedeelten'],
              onChanged: (v) {
                setState(() {
                  _installation = inst.copyWith(frame: v);
                });
                _save();
              },
            ),
            SectionHeader(title: 'Weersomstandigheden'),
            CustomDropdown(
              label: 'Bewolking',
              value: inst.cloudCover,
              items: const [
                'Zwaarbewolkt',
                'Half bewolkt',
                'Lichtbewolkt',
                'Onbewolkt',
              ],
              onChanged: (v) {
                setState(() {
                  _installation = inst.copyWith(cloudCover: v);
                });
                _save();
              },
            ),
            CustomDropdown(
              label: 'Temperatuur',
              value: inst.temperature,
              items: const [
                '30° of warmer',
                '15° - 30°',
                '5° - 15°',
                '0° - 5°',
                '-10° - 0°',
              ],
              onChanged: (v) {
                setState(() {
                  _installation = inst.copyWith(temperature: v);
                });
                _save();
              },
            ),
            SectionHeader(title: 'Documentatie'),
            CustomDropdown(
              label: 'Legplan panelen',
              value: inst.layoutPlan,
              items: const ['Ja', 'Nee', 'N.v.t.'],
              onChanged: (v) {
                setState(() {
                  _installation = inst.copyWith(layoutPlan: v);
                });
                _save();
              },
            ),
            CustomDropdown(
              label: 'Ballastplan',
              value: inst.ballastPlan,
              items: const ['Ja', 'Nee', 'N.v.t.'],
              onChanged: (v) {
                setState(() {
                  _installation = inst.copyWith(ballastPlan: v);
                });
                _save();
              },
            ),
            CustomDropdown(
              label: 'Kabelplan (>1 streng)',
              value: inst.cablePlan,
              items: const ['Ja', 'Nee', 'N.v.t.'],
              onChanged: (v) {
                setState(() {
                  _installation = inst.copyWith(cablePlan: v);
                });
                _save();
              },
            ),
            CustomDropdown(
              label: 'Verklaring constructiebureau m.b.t. dakconstructie',
              value: inst.constructionDeclaration,
              items: const ['Ja', 'Nee', 'N.v.t.'],
              onChanged: (v) {
                setState(() {
                  _installation = inst.copyWith(constructionDeclaration: v);
                });
                _save();
              },
            ),
            CustomDropdown(
              label: 'Installatiegegevens',
              value: inst.installationData,
              items: const ['Ja', 'Nee', 'N.v.t.'],
              onChanged: (v) {
                setState(() {
                  _installation = inst.copyWith(installationData: v);
                });
                _save();
              },
            ),
            SectionHeader(title: 'Omvormers'),
            ..._inverters.map(
              (inv) => Card(
                margin: const EdgeInsets.symmetric(vertical: 4),
                child: ListTile(
                  leading: const Icon(Icons.solar_power,
                      color: Color(0xFF1976D2)),
                  title: Text(inv.displayName),
                  subtitle: inv.location.isNotEmpty
                      ? Text(inv.location)
                      : null,
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.chevron_right),
                      IconButton(
                        icon: const Icon(Icons.delete_outline,
                            color: Colors.red, size: 20),
                        onPressed: () => _deleteInverter(inv),
                      ),
                    ],
                  ),
                  onTap: () async {
                    await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => SolarInverterDetailPage(
                            inverterId: inv.id!,
                            inspectionId: widget.inspectionId),
                      ),
                    );
                    _loadInverters();
                  },
                ),
              ),
            ),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: _addInverter,
              icon: const Icon(Icons.add),
              label: const Text('Omvormer toevoegen'),
            ),
            SectionHeader(title: l10n.photos),
            Row(
              children: [
                Expanded(
                  child: PhotoContainer(
                    label: l10n.roofSetup1,
                    photoPath: inst.photoRoof1Path,
                    height: 150,
                    onPhotoSelected: (path) {
                      setState(() {
                        _installation = inst.copyWith(photoRoof1Path: path);
                      });
                      _save();
                    },
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: PhotoContainer(
                    label: l10n.roofSetup2,
                    photoPath: inst.photoRoof2Path,
                    height: 150,
                    onPhotoSelected: (path) {
                      setState(() {
                        _installation = inst.copyWith(photoRoof2Path: path);
                      });
                      _save();
                    },
                  ),
                ),
              ],
            ),
            Row(
              children: [
                Expanded(
                  child: PhotoContainer(
                    label: l10n.inverter1,
                    photoPath: inst.photoInverter1Path,
                    height: 150,
                    onPhotoSelected: (path) {
                      setState(() {
                        _installation =
                            inst.copyWith(photoInverter1Path: path);
                      });
                      _save();
                    },
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: PhotoContainer(
                    label: l10n.inverter2,
                    photoPath: inst.photoInverter2Path,
                    height: 150,
                    onPhotoSelected: (path) {
                      setState(() {
                        _installation =
                            inst.copyWith(photoInverter2Path: path);
                      });
                      _save();
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            SectionHeader(title: 'Vereffening van de zonnestroom'),
            _buildVereffeningTable(),
            const SizedBox(height: 24),
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
