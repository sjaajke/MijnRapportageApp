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
import 'package:intl/intl.dart';
import '../models/noodverlichting_installation.dart';
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
import 'noodverlichting_list_page.dart';

const _typeInstallatieOptions = ['Noodverlichtingsinstallatie'];
const _installatieOnderdeelOptions = ['Noodverlichting'];
const _componentFunctieOptions = ['Noodverlichting'];

class NoodverlichtingDetailPage extends StatelessWidget {
  final int installationId;
  final int inspectionId;

  const NoodverlichtingDetailPage({
    super.key,
    required this.installationId,
    required this.inspectionId,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Noodverlichting')),
      body: Column(
        children: [
          _NavBar(inspectionId: inspectionId),
          Expanded(
            child: NoodverlichtingDetailView(
              key: ValueKey(installationId),
              installationId: installationId,
              inspectionId: inspectionId,
            ),
          ),
        ],
      ),
    );
  }
}

/// The editable noodverlichting form, extracted so it can be embedded either
/// as a full [NoodverlichtingDetailPage] or inline in a master-detail split
/// view.
class NoodverlichtingDetailView extends StatefulWidget {
  final int installationId;
  final int inspectionId;

  /// Called after the Save button persists changes, instead of the default
  /// pop-navigation, so an embedding split view can clear the selection.
  final VoidCallback? onSavedAndClose;

  /// Called whenever the installation is persisted, so an embedding list can
  /// refresh its summary (name/location) live.
  final ValueChanged<NoodverlichtingInstallation>? onInstallationUpdated;

  /// Called if the installation no longer exists (e.g. deleted elsewhere),
  /// instead of the default pop-navigation.
  final VoidCallback? onNotFound;

  const NoodverlichtingDetailView({
    super.key,
    required this.installationId,
    required this.inspectionId,
    this.onSavedAndClose,
    this.onInstallationUpdated,
    this.onNotFound,
  });

  @override
  State<NoodverlichtingDetailView> createState() =>
      _NoodverlichtingDetailViewState();
}

class _NoodverlichtingDetailViewState
    extends State<NoodverlichtingDetailView> {
  final _db = DatabaseService();

  final _componentNrController = TextEditingController();
  final _nameController = TextEditingController();
  final _nameCodeController = TextEditingController();
  final _locationController = TextEditingController();
  final _locationAController = TextEditingController();
  final _locationBController = TextEditingController();
  final _merkController = TextEditingController();
  final _lichtbronController = TextEditingController();
  final _accuTypeController = TextEditingController();
  final _typeNoodverlichtingController = TextEditingController();
  final _typeStekerController = TextEditingController();
  final _hoogteController = TextEditingController();
  final _functieController = TextEditingController();
  final _montageController = TextEditingController();
  final _chemieVanDeAccuController = TextEditingController();
  final _jaarVanAanlegController = TextEditingController();
  final _inspectieDatumController = TextEditingController();
  final _inspectieIntervalController = TextEditingController();
  final _herinspectieDatumController = TextEditingController();
  final _opmerkingController = TextEditingController();

  NoodverlichtingInstallation? _installation;
  List<String> _locationOptions = [];
  List<String> _locationAOptions = [];
  List<String> _locationBOptions = [];
  List<String> _opmerkingOptieOptions = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final inst =
        await _db.getNoodverlichtingInstallation(widget.installationId);
    if (inst == null) {
      if (!mounted) return;
      if (widget.onNotFound != null) {
        widget.onNotFound!();
      } else {
        Navigator.pop(context);
      }
      return;
    }

    _componentNrController.text = inst.componentNr?.toString() ?? '';
    _nameController.text = inst.name;
    _nameCodeController.text = inst.nameCode;
    _locationController.text = inst.location;
    _locationAController.text = inst.locationA;
    _locationBController.text = inst.locationB;
    _merkController.text = inst.merk;
    _lichtbronController.text = inst.lichtbron;
    _accuTypeController.text = inst.accuType;
    _typeNoodverlichtingController.text = inst.typeNoodverlichting;
    _typeStekerController.text = inst.typeSteker;
    _hoogteController.text = inst.hoogte;
    _functieController.text = inst.functie;
    _montageController.text = inst.montage;
    _chemieVanDeAccuController.text = inst.chemieVanDeAccu;
    _jaarVanAanlegController.text = inst.jaarVanAanleg;
    _inspectieDatumController.text = inst.inspectieDatum;
    _inspectieIntervalController.text = inst.inspectieInterval;
    _herinspectieDatumController.text = inst.herinspectieDatum;
    _opmerkingController.text = inst.opmerking;

    final locationStandards = await _db.getStandards('location');
    final locationAStandards = await _db.getStandards('location_a');
    final locationBStandards = await _db.getStandards('location_b');
    final constateringen = await _db.getRapportConstateringen();
    final opmerkingOpties = constateringen
        .where((c) => c.groep.trim().toLowerCase() == 'noodverlichting')
        .map((c) => c.tekst.trim())
        .where((t) => t.isNotEmpty)
        .toSet()
        .toList();

    setState(() {
      _installation = inst;
      _locationOptions = locationStandards.map((s) => s.value).toList();
      _locationAOptions = locationAStandards.map((s) => s.value).toList();
      _locationBOptions = locationBStandards.map((s) => s.value).toList();
      _opmerkingOptieOptions = opmerkingOpties;
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

  Future<void> _save() async {
    final installation = _installation;
    if (installation == null) return;
    final updated = installation.copyWith(
      componentNr: int.tryParse(_componentNrController.text),
      clearComponentNr: _componentNrController.text.trim().isEmpty,
      name: _nameController.text,
      nameCode: _nameCodeController.text,
      location: _locationController.text,
      locationA: _locationAController.text,
      locationB: _locationBController.text,
      merk: _merkController.text,
      lichtbron: _lichtbronController.text,
      accuType: _accuTypeController.text,
      typeNoodverlichting: _typeNoodverlichtingController.text,
      typeSteker: _typeStekerController.text,
      hoogte: _hoogteController.text,
      functie: _functieController.text,
      montage: _montageController.text,
      chemieVanDeAccu: _chemieVanDeAccuController.text,
      jaarVanAanleg: _jaarVanAanlegController.text,
      inspectieDatum: _inspectieDatumController.text,
      inspectieInterval: _inspectieIntervalController.text,
      opmerking: _opmerkingController.text,
    );
    await _db.updateNoodverlichtingInstallation(updated);
    _installation = updated;
    _herinspectieDatumController.text = updated.herinspectieDatum;
    widget.onInstallationUpdated?.call(updated);
  }

  Future<void> _pickInspectieDatum() async {
    final date = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (date != null) {
      _inspectieDatumController.text = DateFormat('dd-MM-yyyy').format(date);
      _save();
    }
  }

  Future<void> _removePhoto(String field) async {
    final installation = _installation;
    if (installation == null) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Foto verwijderen'),
        content:
            const Text('Weet je zeker dat je deze foto wilt verwijderen?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Annuleren'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child:
                const Text('Verwijderen', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    final String? photoPath;
    final NoodverlichtingInstallation updated;
    switch (field) {
      case 'accu':
        photoPath = installation.photoAccuPath;
        updated = installation.copyWith(clearPhotoAccuPath: true);
        break;
      case 'stekker':
        photoPath = installation.photoStekkerAansluitingPath;
        updated = installation.copyWith(clearPhotoStekkerAansluitingPath: true);
        break;
      case 'afbeelding':
        photoPath = installation.photoAfbeeldingPath;
        updated = installation.copyWith(clearPhotoAfbeeldingPath: true);
        break;
      case 'type_plaatje':
        photoPath = installation.photoTypePlaatjePath;
        updated = installation.copyWith(clearPhotoTypePlaatjePath: true);
        break;
      case 'pictogram':
        photoPath = installation.photoGebruiktPictogramPath;
        updated =
            installation.copyWith(clearPhotoGebruiktPictogramPath: true);
        break;
      case 'afbeelding_detail':
        photoPath = installation.photoAfbeeldingDetailPath;
        updated = installation.copyWith(clearPhotoAfbeeldingDetailPath: true);
        break;
      default:
        return;
    }

    await _db.updateNoodverlichtingInstallation(updated);
    if (photoPath != null) {
      final file = File(photoPath);
      if (await file.exists()) {
        await file.delete();
      }
    }
    if (!mounted) return;
    setState(() => _installation = updated);
    widget.onInstallationUpdated?.call(updated);
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'R':
        return Colors.red;
      case 'O':
        return Colors.orange;
      default:
        return Colors.green;
    }
  }

  @override
  void dispose() {
    _save();
    _componentNrController.dispose();
    _nameController.dispose();
    _nameCodeController.dispose();
    _locationController.dispose();
    _locationAController.dispose();
    _locationBController.dispose();
    _merkController.dispose();
    _lichtbronController.dispose();
    _accuTypeController.dispose();
    _typeNoodverlichtingController.dispose();
    _typeStekerController.dispose();
    _hoogteController.dispose();
    _functieController.dispose();
    _montageController.dispose();
    _chemieVanDeAccuController.dispose();
    _jaarVanAanlegController.dispose();
    _inspectieDatumController.dispose();
    _inspectieIntervalController.dispose();
    _herinspectieDatumController.dispose();
    _opmerkingController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    final inst = _installation!;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          CustomTextField(
            label: 'Component nr',
            controller: _componentNrController,
            onChanged: (_) => _save(),
            keyboardType: TextInputType.number,
          ),
          CustomTextField(
            label: 'Naam / code',
            controller: _nameController,
            onChanged: (_) => _save(),
          ),
          CustomTextField(
            label: 'Naam code',
            controller: _nameCodeController,
            onChanged: (_) => _save(),
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
          SectionHeader(title: 'Kenmerken'),
          CustomTextField(
            label: 'Merk',
            controller: _merkController,
            onChanged: (_) => _save(),
          ),
          CustomTextField(
            label: 'Lichtbron',
            controller: _lichtbronController,
            onChanged: (_) => _save(),
          ),
          CustomTextField(
            label: 'Accu type',
            controller: _accuTypeController,
            onChanged: (_) => _save(),
          ),
          CustomTextField(
            label: 'Type noodverlichting',
            controller: _typeNoodverlichtingController,
            onChanged: (_) => _save(),
          ),
          CustomTextField(
            label: 'Type steker',
            controller: _typeStekerController,
            onChanged: (_) => _save(),
          ),
          CustomTextField(
            label: 'Hoogte',
            controller: _hoogteController,
            onChanged: (_) => _save(),
          ),
          CustomTextField(
            label: 'Functie',
            controller: _functieController,
            onChanged: (_) => _save(),
          ),
          CustomTextField(
            label: 'Montage',
            controller: _montageController,
            onChanged: (_) => _save(),
          ),
          CustomTextField(
            label: 'Chemie van de accu',
            controller: _chemieVanDeAccuController,
            onChanged: (_) => _save(),
          ),
          SectionHeader(title: 'Inspectie'),
          CustomDropdown(
            label: 'Type installatie',
            value: inst.typeInstallatie,
            items: _typeInstallatieOptions,
            onChanged: (v) {
              setState(() => _installation = inst.copyWith(typeInstallatie: v));
              _save();
            },
          ),
          CustomDropdown(
            label: 'Installatie onderdeel',
            value: inst.installatieOnderdeel,
            items: _installatieOnderdeelOptions,
            onChanged: (v) {
              setState(
                  () => _installation = inst.copyWith(installatieOnderdeel: v));
              _save();
            },
          ),
          CustomDropdown(
            label: 'Componentfunctie',
            value: inst.componentFunctie,
            items: _componentFunctieOptions,
            onChanged: (v) {
              setState(() => _installation = inst.copyWith(componentFunctie: v));
              _save();
            },
          ),
          CustomTextField(
            label: 'Jaar van aanleg',
            controller: _jaarVanAanlegController,
            onChanged: (_) => _save(),
            keyboardType: TextInputType.number,
          ),
          CustomTextField(
            label: 'Inspectie interval (jaar)',
            controller: _inspectieIntervalController,
            onChanged: (_) => _save(),
            keyboardType: TextInputType.number,
          ),
          CustomTextField(
            label: 'Inspectiedatum',
            controller: _inspectieDatumController,
            readOnly: true,
            onTap: _pickInspectieDatum,
          ),
          CustomTextField(
            label: 'Herinspectiedatum',
            controller: _herinspectieDatumController,
            readOnly: true,
          ),
          SectionHeader(title: 'Status'),
          Row(
            children: [
              for (final s in NoodverlichtingInstallation.statusOptions)
                Padding(
                  padding: const EdgeInsets.only(right: 12),
                  child: GestureDetector(
                    onTap: () {
                      setState(() => _installation = inst.copyWith(status: s));
                      _save();
                    },
                    child: Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: _statusColor(s),
                        border: inst.status == s
                            ? Border.all(color: Colors.black87, width: 3)
                            : null,
                      ),
                    ),
                  ),
                ),
            ],
          ),
          SectionHeader(title: 'Foto\'s'),
          Row(
            children: [
              Expanded(
                child: PhotoContainer(
                  label: 'Accu',
                  photoPath: inst.photoAccuPath,
                  aspectRatio: 4 / 3,
                  onPhotoSelected: (path) {
                    setState(() => _installation = inst.copyWith(photoAccuPath: path));
                    _save();
                  },
                  onPhotoRemoved: () => _removePhoto('accu'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: PhotoContainer(
                  label: 'Stekker aansluiting',
                  photoPath: inst.photoStekkerAansluitingPath,
                  aspectRatio: 4 / 3,
                  onPhotoSelected: (path) {
                    setState(() => _installation =
                        inst.copyWith(photoStekkerAansluitingPath: path));
                    _save();
                  },
                  onPhotoRemoved: () => _removePhoto('stekker'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: PhotoContainer(
                  label: 'Afbeelding',
                  photoPath: inst.photoAfbeeldingPath,
                  aspectRatio: 4 / 3,
                  onPhotoSelected: (path) {
                    setState(() =>
                        _installation = inst.copyWith(photoAfbeeldingPath: path));
                    _save();
                  },
                  onPhotoRemoved: () => _removePhoto('afbeelding'),
                ),
              ),
            ],
          ),
          Row(
            children: [
              Expanded(
                child: PhotoContainer(
                  label: 'Type plaatje',
                  photoPath: inst.photoTypePlaatjePath,
                  aspectRatio: 4 / 3,
                  onPhotoSelected: (path) {
                    setState(() => _installation =
                        inst.copyWith(photoTypePlaatjePath: path));
                    _save();
                  },
                  onPhotoRemoved: () => _removePhoto('type_plaatje'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: PhotoContainer(
                  label: 'Gebruikt pictogram',
                  photoPath: inst.photoGebruiktPictogramPath,
                  aspectRatio: 4 / 3,
                  onPhotoSelected: (path) {
                    setState(() => _installation =
                        inst.copyWith(photoGebruiktPictogramPath: path));
                    _save();
                  },
                  onPhotoRemoved: () => _removePhoto('pictogram'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: PhotoContainer(
                  label: 'Afbeelding detail',
                  photoPath: inst.photoAfbeeldingDetailPath,
                  aspectRatio: 4 / 3,
                  onPhotoSelected: (path) {
                    setState(() => _installation =
                        inst.copyWith(photoAfbeeldingDetailPath: path));
                    _save();
                  },
                  onPhotoRemoved: () => _removePhoto('afbeelding_detail'),
                ),
              ),
            ],
          ),
          SectionHeader(title: 'Opmerking'),
          CustomDropdown(
            label: 'Opmerking (voorbeeld)',
            value: inst.opmerkingOptie.isEmpty ? null : inst.opmerkingOptie,
            items: _opmerkingOptieOptions,
            onChanged: (v) {
              setState(() {
                _installation = inst.copyWith(opmerkingOptie: v);
                if (v != null) _opmerkingController.text = v;
              });
              _save();
            },
          ),
          CustomTextField(
            label: 'Opmerking',
            controller: _opmerkingController,
            onChanged: (_) => _save(),
            maxLines: 4,
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () async {
              final navigator = Navigator.of(context);
              final messenger = ScaffoldMessenger.of(context);
              await _save();
              if (!mounted) return;
              messenger
                  .showSnackBar(const SnackBar(content: Text('Opgeslagen')));
              if (widget.onSavedAndClose != null) {
                widget.onSavedAndClose!();
              } else {
                navigator.pop();
              }
            },
            child: const Text('Opslaan'),
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
            _btn(context, Icons.lan, 'Verdelers',
                () => Navigator.push(context, MaterialPageRoute(
                      builder: (_) => SwitchboardsListPage(inspectionId: inspectionId)))),
            _btn(context, Icons.solar_power, 'Zonnestroom',
                () => Navigator.push(context, MaterialPageRoute(
                      builder: (_) => SolarInstallationsListPage(inspectionId: inspectionId)))),
            _btn(context, Icons.emergency, 'Noodverlichting',
                () => Navigator.push(context, MaterialPageRoute(
                      builder: (_) => NoodverlichtingListPage(inspectionId: inspectionId)))),
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
