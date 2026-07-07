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
import '../models/solar_inverter.dart';
import '../models/solar_string_measurement.dart';
import '../services/database_service.dart';
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

class SolarInverterDetailPage extends StatefulWidget {
  final int inverterId;
  final int inspectionId;

  const SolarInverterDetailPage({super.key, required this.inverterId, required this.inspectionId});

  @override
  State<SolarInverterDetailPage> createState() =>
      _SolarInverterDetailPageState();
}

class _SolarInverterDetailPageState extends State<SolarInverterDetailPage> {
  final _db = DatabaseService();

  final _locationController = TextEditingController();
  final _locationAController = TextEditingController();
  final _locationBController = TextEditingController();
  final _inverterNameController = TextEditingController();
  final _inverterBrandController = TextEditingController();
  final _inverterTypeController = TextEditingController();
  final _inverterIpController = TextEditingController();
  final _inverterIsolationClassController = TextEditingController();
  final _inverterMaxVdcController = TextEditingController();
  final _inverterMaxIdcController = TextEditingController();
  final _inverterIscPvController = TextEditingController();
  final _inverterInomController = TextEditingController();
  final _panelBrandController = TextEditingController();
  final _panelTypeController = TextEditingController();
  final _panelShortCircuitCurrentController = TextEditingController();
  final _panelOpenCircuitVoltageController = TextEditingController();
  final _protectionController = TextEditingController();
  final _cableController = TextEditingController();

  SolarInverter? _inverter;
  List<SolarStringMeasurement> _measurements = [];
  List<String> _locationOptions = [];
  List<String> _locationAOptions = [];
  List<String> _locationBOptions = [];
  // Per-row controllers indexed by measurement id
  final Map<int, _RowControllers> _rowControllers = {};
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final inv = await _db.getSolarInverter(widget.inverterId);
    if (inv == null) {
      if (mounted) Navigator.pop(context);
      return;
    }
    final measurements = await _db.getSolarStringMeasurements(widget.inverterId);
    final locationStandards = await _db.getStandards('location');
    final locationAStandards = await _db.getStandards('location_a');
    final locationBStandards = await _db.getStandards('location_b');

    _locationController.text = inv.location;
    _locationAController.text = inv.locationA;
    _locationBController.text = inv.locationB;
    _inverterNameController.text = inv.inverterName;
    _inverterBrandController.text = inv.inverterBrand;
    _inverterTypeController.text = inv.inverterType;
    _inverterIpController.text = inv.inverterIp;
    _inverterIsolationClassController.text = inv.inverterIsolationClass;
    _inverterMaxVdcController.text = inv.inverterMaxVdc;
    _inverterMaxIdcController.text = inv.inverterMaxIdc;
    _inverterIscPvController.text = inv.inverterIscPv;
    _inverterInomController.text = inv.inverterInom;
    _panelBrandController.text = inv.panelBrand;
    _panelTypeController.text = inv.panelType;
    _panelShortCircuitCurrentController.text = inv.panelShortCircuitCurrent;
    _panelOpenCircuitVoltageController.text = inv.panelOpenCircuitVoltage;
    _protectionController.text = inv.protection;
    _cableController.text = inv.cable;

    for (final m in measurements) {
      _rowControllers[m.id!] = _RowControllers.from(m);
    }

    setState(() {
      _inverter = inv;
      _measurements = measurements;
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
    _saveInverter();
  }

  Future<void> _pickLocationA() async {
    final picked = await showDialog<String>(
      context: context,
      builder: (ctx) => LocationPickerDialog(options: _locationAOptions),
    );
    if (picked == null) return;
    _locationAController.text = picked;
    _saveInverter();
  }

  Future<void> _pickLocationB() async {
    final picked = await showDialog<String>(
      context: context,
      builder: (ctx) => LocationPickerDialog(options: _locationBOptions),
    );
    if (picked == null) return;
    _locationBController.text = picked;
    _saveInverter();
  }

  Future<void> _saveInverter() async {
    if (_inverter == null) return;
    final updated = _inverter!.copyWith(
      location: _locationController.text,
      locationA: _locationAController.text,
      locationB: _locationBController.text,
      inverterName: _inverterNameController.text,
      inverterBrand: _inverterBrandController.text,
      inverterType: _inverterTypeController.text,
      inverterIp: _inverterIpController.text,
      inverterIsolationClass: _inverterIsolationClassController.text,
      inverterMaxVdc: _inverterMaxVdcController.text,
      inverterMaxIdc: _inverterMaxIdcController.text,
      inverterIscPv: _inverterIscPvController.text,
      inverterInom: _inverterInomController.text,
      panelBrand: _panelBrandController.text,
      panelType: _panelTypeController.text,
      panelShortCircuitCurrent: _panelShortCircuitCurrentController.text,
      panelOpenCircuitVoltage: _panelOpenCircuitVoltageController.text,
      protection: _protectionController.text,
      cable: _cableController.text,
    );
    await _db.updateSolarInverter(updated);
    _inverter = updated;
  }

  Future<void> _saveRow(SolarStringMeasurement m) async {
    final rc = _rowControllers[m.id!];
    if (rc == null) return;
    final updated = m.copyWith(
      strang: rc.strang.text,
      panelCount: rc.panelCount.text,
      irradiation: rc.irradiation.text,
      cellTemp: rc.cellTemp.text,
      uoc: rc.uoc.text,
      isc: rc.isc.text,
      riso: rc.riso.text,
    );
    await _db.updateSolarStringMeasurement(updated);
    final idx = _measurements.indexWhere((x) => x.id == m.id);
    if (idx != -1) _measurements[idx] = updated;
  }

  Future<void> _addRow() async {
    final newM = SolarStringMeasurement(solarInverterId: widget.inverterId);
    final id = await _db.insertSolarStringMeasurement(newM);
    final withId = SolarStringMeasurement(
      id: id,
      solarInverterId: widget.inverterId,
    );
    _rowControllers[id] = _RowControllers.from(withId);
    setState(() {
      _measurements.add(withId);
    });
  }

  Future<void> _deleteRow(SolarStringMeasurement m) async {
    await _db.deleteSolarStringMeasurement(m.id!);
    _rowControllers.remove(m.id);
    setState(() {
      _measurements.removeWhere((x) => x.id == m.id);
    });
  }

  Future<void> _duplicateRow(SolarStringMeasurement m) async {
    await _saveRow(m);
    final rc = _rowControllers[m.id!]!;
    final copy = SolarStringMeasurement(
      solarInverterId: widget.inverterId,
      strang: rc.strang.text,
      panelCount: rc.panelCount.text,
      irradiation: rc.irradiation.text,
      cellTemp: rc.cellTemp.text,
      uoc: rc.uoc.text,
      isc: rc.isc.text,
      riso: rc.riso.text,
    );
    final id = await _db.insertSolarStringMeasurement(copy);
    final withId = copy.copyWith(id: id);
    _rowControllers[id] = _RowControllers.from(withId);
    final insertIdx = _measurements.indexWhere((x) => x.id == m.id) + 1;
    setState(() {
      _measurements.insert(insertIdx, withId);
    });
  }

  @override
  void dispose() {
    _saveInverter();
    _locationController.dispose();
    _locationAController.dispose();
    _locationBController.dispose();
    _inverterNameController.dispose();
    _inverterBrandController.dispose();
    _inverterTypeController.dispose();
    _inverterIpController.dispose();
    _inverterIsolationClassController.dispose();
    _inverterMaxVdcController.dispose();
    _inverterMaxIdcController.dispose();
    _inverterIscPvController.dispose();
    _inverterInomController.dispose();
    _panelBrandController.dispose();
    _panelTypeController.dispose();
    _panelShortCircuitCurrentController.dispose();
    _panelOpenCircuitVoltageController.dispose();
    _protectionController.dispose();
    _cableController.dispose();
    for (final rc in _rowControllers.values) {
      rc.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Omvormer')),
        body: Column(
          children: [
            _NavBar(inspectionId: widget.inspectionId),
            const Expanded(child: Center(child: CircularProgressIndicator())),
          ],
        ),
      );
    }

    final inv = _inverter!;

    return Scaffold(
      appBar: AppBar(
        title: Text(inv.displayName.isNotEmpty ? inv.displayName : 'Omvormer'),
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
            SizedBox(
              width: 140,
              child: PhotoContainer(
                label: 'Foto',
                photoPath: inv.photoPath,
                height: 110,
                onPhotoSelected: (path) {
                  setState(() {
                    _inverter = inv.copyWith(photoPath: path);
                  });
                  _saveInverter();
                },
              ),
            ),
            LocationRow(
              label: 'Locatie',
              controller: _locationController,
              onChanged: (_) => _saveInverter(),
              onPick: _locationOptions.isEmpty ? null : _pickLocation,
            ),
            LocationRow(
              label: 'Locatie A',
              controller: _locationAController,
              onChanged: (_) => _saveInverter(),
              onPick: _locationAOptions.isEmpty ? null : _pickLocationA,
            ),
            LocationRow(
              label: 'Locatie B',
              controller: _locationBController,
              onChanged: (_) => _saveInverter(),
              onPick: _locationBOptions.isEmpty ? null : _pickLocationB,
            ),
            SectionHeader(title: 'Omvormer'),
            CustomTextField(
              label: 'Naam/ code omvormer',
              controller: _inverterNameController,
              onChanged: (_) => _saveInverter(),
            ),
            Row(
              children: [
                Expanded(
                  child: CustomTextField(
                    label: 'Merk',
                    controller: _inverterBrandController,
                    onChanged: (_) => _saveInverter(),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: CustomTextField(
                    label: 'Type',
                    controller: _inverterTypeController,
                    onChanged: (_) => _saveInverter(),
                  ),
                ),
              ],
            ),
            Row(
              children: [
                Expanded(
                  child: CustomTextField(
                    label: 'IP',
                    controller: _inverterIpController,
                    onChanged: (_) => _saveInverter(),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: CustomTextField(
                    label: 'Isolatieklasse',
                    controller: _inverterIsolationClassController,
                    onChanged: (_) => _saveInverter(),
                  ),
                ),
              ],
            ),
            Row(
              children: [
                Expanded(
                  child: CustomTextField(
                    label: 'Max VDC',
                    controller: _inverterMaxVdcController,
                    onChanged: (_) => _saveInverter(),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: CustomTextField(
                    label: 'Max IDC',
                    controller: _inverterMaxIdcController,
                    onChanged: (_) => _saveInverter(),
                  ),
                ),
              ],
            ),
            Row(
              children: [
                Expanded(
                  child: CustomTextField(
                    label: 'Isc pv',
                    controller: _inverterIscPvController,
                    onChanged: (_) => _saveInverter(),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: CustomTextField(
                    label: 'Inom',
                    controller: _inverterInomController,
                    onChanged: (_) => _saveInverter(),
                  ),
                ),
              ],
            ),
            SectionHeader(title: 'Paneel'),
            Row(
              children: [
                Expanded(
                  child: CustomTextField(
                    label: 'Merk',
                    controller: _panelBrandController,
                    onChanged: (_) => _saveInverter(),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: CustomTextField(
                    label: 'Type',
                    controller: _panelTypeController,
                    onChanged: (_) => _saveInverter(),
                  ),
                ),
              ],
            ),
            Row(
              children: [
                Expanded(
                  child: CustomTextField(
                    label: 'Short-circuit current',
                    controller: _panelShortCircuitCurrentController,
                    onChanged: (_) => _saveInverter(),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: CustomTextField(
                    label: 'Open-circuit voltage',
                    controller: _panelOpenCircuitVoltageController,
                    onChanged: (_) => _saveInverter(),
                  ),
                ),
              ],
            ),
            SectionHeader(title: 'Leiding'),
            Row(
              children: [
                Expanded(
                  child: CustomTextField(
                    label: 'Beveiliging',
                    controller: _protectionController,
                    onChanged: (_) => _saveInverter(),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: CustomTextField(
                    label: 'Leiding',
                    controller: _cableController,
                    onChanged: (_) => _saveInverter(),
                  ),
                ),
              ],
            ),
            SectionHeader(title: 'Strengmeting(en)'),
            _buildMeasurementsTable(),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: _addRow,
              icon: const Icon(Icons.add),
              label: const Text('Streng toevoegen'),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () async {
                final messenger = ScaffoldMessenger.of(context);
                final navigator = Navigator.of(context);
                await _saveInverter();
                for (final m in _measurements) {
                  await _saveRow(m);
                }
                if (!mounted) return;
                messenger.showSnackBar(
                  const SnackBar(content: Text('Opgeslagen')),
                );
                navigator.pop();
              },
              child: const Text('Opslaan'),
            ),
          ],
        ),
      ),
          ),
        ],
      ),
    );
  }

  Widget _buildMeasurementsTable() {
    if (_measurements.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 8),
        child: Text(
          'Nog geen strengmetingen.',
          style: TextStyle(color: Colors.grey),
        ),
      );
    }

    const headerStyle = TextStyle(
      fontSize: 11,
      fontWeight: FontWeight.bold,
      color: Color(0xFF1976D2),
    );
    const colWidths = [52.0, 62.0, 72.0, 72.0, 62.0, 62.0, 62.0];
    final headers = [
      'Streng',
      'Aantal pan.',
      'Instraling\nW/m²',
      'Cel/\nbuiten °C',
      'Uoc\n(VDC)',
      'Isc\n[A]',
      'Riso\n[MΩ]',
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header row
          Row(
            children: [
              for (int i = 0; i < headers.length; i++)
                SizedBox(
                  width: colWidths[i],
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 4, vertical: 4),
                    child: Text(headers[i], style: headerStyle),
                  ),
                ),
              const SizedBox(width: 80),
            ],
          ),
          const Divider(height: 1),
          // Data rows
          for (final m in _measurements)
            _buildMeasurementRow(m, colWidths),
        ],
      ),
    );
  }

  Widget _buildMeasurementRow(
      SolarStringMeasurement m, List<double> colWidths) {
    final rc = _rowControllers[m.id!]!;
    final controllers = [
      rc.strang,
      rc.panelCount,
      rc.irradiation,
      rc.cellTemp,
      rc.uoc,
      rc.isc,
      rc.riso,
    ];

    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          for (int i = 0; i < controllers.length; i++)
            SizedBox(
              width: colWidths[i],
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: SizedBox(
                  height: 36,
                  child: TextFormField(
                    controller: controllers[i],
                    onChanged: (_) => _saveRow(m),
                    style: const TextStyle(fontSize: 13),
                    decoration: const InputDecoration(
                      isDense: true,
                      contentPadding:
                          EdgeInsets.symmetric(horizontal: 6, vertical: 8),
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
              ),
            ),
          SizedBox(
            width: 40,
            child: IconButton(
              icon: const Icon(Icons.content_copy,
                  size: 36, color: Colors.grey),
              padding: EdgeInsets.zero,
              tooltip: 'Dupliceer rij',
              onPressed: () => _duplicateRow(m),
            ),
          ),
          SizedBox(
            width: 40,
            child: IconButton(
              icon: const Icon(Icons.delete_outline,
                  size: 36, color: Colors.red),
              padding: EdgeInsets.zero,
              onPressed: () => _deleteRow(m),
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

class _RowControllers {
  final TextEditingController strang;
  final TextEditingController panelCount;
  final TextEditingController irradiation;
  final TextEditingController cellTemp;
  final TextEditingController uoc;
  final TextEditingController isc;
  final TextEditingController riso;

  _RowControllers({
    required this.strang,
    required this.panelCount,
    required this.irradiation,
    required this.cellTemp,
    required this.uoc,
    required this.isc,
    required this.riso,
  });

  factory _RowControllers.from(SolarStringMeasurement m) {
    return _RowControllers(
      strang: TextEditingController(text: m.strang),
      panelCount: TextEditingController(text: m.panelCount),
      irradiation: TextEditingController(text: m.irradiation),
      cellTemp: TextEditingController(text: m.cellTemp),
      uoc: TextEditingController(text: m.uoc),
      isc: TextEditingController(text: m.isc),
      riso: TextEditingController(text: m.riso),
    );
  }

  void dispose() {
    strang.dispose();
    panelCount.dispose();
    irradiation.dispose();
    cellTemp.dispose();
    uoc.dispose();
    isc.dispose();
    riso.dispose();
  }
}
