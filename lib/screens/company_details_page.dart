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

import 'package:desktop_drop/desktop_drop.dart';
import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
import '../l10n/app_localizations.dart';
import '../models/company_details.dart';
import '../models/company_inspector.dart';
import '../models/measurement_instrument.dart';
import '../models/title_page.dart' as model;
import '../services/company_details_export_service.dart';
import '../services/database_service.dart';
import '../widgets/custom_text_field.dart';
import '../widgets/photo_container.dart';
import '../widgets/section_header.dart';
import '../widgets/title_page_preview.dart';
import 'measurement_instrument_page.dart';
import 'inspector_detail_page.dart';

class CompanyDetailsPage extends StatefulWidget {
  const CompanyDetailsPage({super.key});

  @override
  State<CompanyDetailsPage> createState() => _CompanyDetailsPageState();
}

class _CompanyDetailsPageState extends State<CompanyDetailsPage> {
  final _db = DatabaseService();

  final _companyName = TextEditingController();
  final _address = TextEditingController();
  final _postalCity = TextEditingController();
  final _phone = TextEditingController();
  final _email = TextEditingController();
  final _contactPerson = TextEditingController();
  final _finalResponsible = TextEditingController();
  final _herstelFirebaseProjectId = TextEditingController();
  final _herstelFirebaseStorageBucket = TextEditingController();
  final _herstelWebDomain = TextEditingController();

  CompanyDetails? _details;
  List<CompanyInspector> _inspectors = [];
  List<MeasurementInstrument> _instruments = [];
  model.TitlePage? _layoutDefaults;
  bool _layoutLocked = false;
  bool _loading = true;
  bool _exporting = false;
  bool _importing = false;
  bool _dragging = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    var details = await _db.getCompanyDetails();
    if (details == null) {
      details = CompanyDetails();
      await _db.saveCompanyDetails(details);
      details = await _db.getCompanyDetails();
    }
    final inspectors = await _db.getCompanyInspectors();
    final instruments = await _db.getAllMeasurementInstruments();
    final d = await _db.getTitlePageLayoutDefaults();
    final layoutDefaults = model.TitlePage(
      inspectionId: 0,
      titleX: d?['title_x'] ?? 0.5, titleY: d?['title_y'] ?? 0.15,
      titleW: d?['title_w'] ?? 0.80, titleH: d?['title_h'] ?? 0.10,
      subtitleX: d?['subtitle_x'] ?? 0.5, subtitleY: d?['subtitle_y'] ?? 0.26,
      subtitleW: d?['subtitle_w'] ?? 0.70, subtitleH: d?['subtitle_h'] ?? 0.07,
      photoX: d?['photo_x'] ?? 0.5, photoY: d?['photo_y'] ?? 0.50,
      photoW: d?['photo_w'] ?? 0.60, photoH: d?['photo_h'] ?? 0.35,
      dateX: d?['date_x'] ?? 0.5, dateY: d?['date_y'] ?? 0.78,
      dateW: d?['date_w'] ?? 0.70, dateH: d?['date_h'] ?? 0.065,
      codeX: d?['code_x'] ?? 0.5, codeY: d?['code_y'] ?? 0.86,
      codeW: d?['code_w'] ?? 0.70, codeH: d?['code_h'] ?? 0.065,
      projectX: d?['project_x'] ?? 0.5, projectY: d?['project_y'] ?? 0.93,
      projectW: d?['project_w'] ?? 0.70, projectH: d?['project_h'] ?? 0.065,
      logoX: d?['logo_x'] ?? 0.82, logoY: d?['logo_y'] ?? 0.07,
      logoW: d?['logo_w'] ?? 0.30, logoH: d?['logo_h'] ?? 0.12,
      addressNameX: d?['address_name_x'] ?? 0.5, addressNameY: d?['address_name_y'] ?? 0.72,
      addressNameW: d?['address_name_w'] ?? 0.70, addressNameH: d?['address_name_h'] ?? 0.065,
    );

    if (details != null) {
      _companyName.text = details.companyName;
      _address.text = details.address;
      _postalCity.text = details.postalCity;
      _phone.text = details.phone;
      _email.text = details.email;
      _contactPerson.text = details.contactPerson;
      _finalResponsible.text = details.finalResponsible;
      _herstelFirebaseProjectId.text = details.herstelFirebaseProjectId;
      _herstelFirebaseStorageBucket.text = details.herstelFirebaseStorageBucket;
      _herstelWebDomain.text = details.herstelWebDomain;
    }

    setState(() {
      _details = details;
      _layoutDefaults = layoutDefaults;
      _inspectors = inspectors;
      _instruments = instruments;
      _loading = false;
    });
  }

  Future<void> _autoSave() async {
    if (_details == null) return;
    final updated = _details!.copyWith(
      companyName: _companyName.text,
      address: _address.text,
      postalCity: _postalCity.text,
      phone: _phone.text,
      email: _email.text,
      contactPerson: _contactPerson.text,
      finalResponsible: _finalResponsible.text,
      herstelFirebaseProjectId: _herstelFirebaseProjectId.text,
      herstelFirebaseStorageBucket: _herstelFirebaseStorageBucket.text,
      herstelWebDomain: _herstelWebDomain.text,
    );
    await _db.saveCompanyDetails(updated);
    _details = updated;
  }

  // ── Titelpagina: positie & afmetingen (standaard) ──────────────────────────

  Future<void> _saveLayoutDefault(model.TitlePage updated) async {
    await _db.saveTitlePageLayoutDefaults(updated);
    if (!mounted) return;
    setState(() => _layoutDefaults = updated);
  }

  Future<void> _refreshInspectors() async {
    final inspectors = await _db.getCompanyInspectors();
    if (!mounted) return;
    setState(() => _inspectors = inspectors);
  }

  Future<void> _refreshInstruments() async {
    final instruments = await _db.getAllMeasurementInstruments();
    if (!mounted) return;
    setState(() => _instruments = instruments);
  }

  // ── Inspectors ──────────────────────────────────────────────────────────────

  Future<void> _addInspector() async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => const InspectorDetailPage()),
    );
    if (result == true) await _refreshInspectors();
  }

  Future<void> _editInspector(CompanyInspector inspector) async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => InspectorDetailPage(inspector: inspector),
      ),
    );
    if (result == true) await _refreshInspectors();
  }

  Future<void> _deleteInspector(CompanyInspector inspector) async {
    final l10n = AppLocalizations.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.deleteInspectorTitle),
        content: Text(l10n.deleteInspectorConfirm(inspector.name)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l10n.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(l10n.delete, style: const TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    await _db.deleteCompanyInspector(inspector.id!);
    await _refreshInspectors();
  }

  // ── Instruments ──────────────────────────────────────────────────────────────

  Future<void> _addInstrument() async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => const MeasurementInstrumentPage()),
    );
    if (result == true) await _refreshInstruments();
  }

  Future<void> _editInstrument(MeasurementInstrument instrument) async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => MeasurementInstrumentPage(instrument: instrument),
      ),
    );
    if (result == true) await _refreshInstruments();
  }

  Future<void> _deleteInstrument(MeasurementInstrument instrument) async {
    final l10n = AppLocalizations.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.deleteMeasurementInstrument),
        content: Text(
          l10n.deleteMeasurementInstrumentConfirm(instrument.displayName),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l10n.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(l10n.delete, style: const TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    await _db.deleteMeasurementInstrument(instrument.id!);
    await _refreshInstruments();
  }

  // ── Export ───────────────────────────────────────────────────────────────

  Future<void> _exportToExcel() async {
    if (_details == null) return;
    final l10n = AppLocalizations.of(context);
    setState(() => _exporting = true);
    try {
      await CompanyDetailsExportService().exportExcelAndShare(
        details: _details!,
        inspectors: _inspectors,
        instruments: _instruments,
        layoutDefaults: _layoutDefaults,
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(l10n.exportFailed(e))));
      }
    } finally {
      if (mounted) setState(() => _exporting = false);
    }
  }

  Future<void> _pickAndImport() async {
    const xlsxType = XTypeGroup(
      label: 'Excel',
      extensions: ['xlsx'],
      uniformTypeIdentifiers: ['org.openxmlformats.spreadsheetml.sheet'],
    );
    final file = await openFile(acceptedTypeGroups: [xlsxType]);
    if (file == null) return;
    await _runImport(file.path);
  }

  Future<void> _runImport(String path) async {
    final l10n = AppLocalizations.of(context);
    if (!path.toLowerCase().endsWith('.xlsx')) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l10n.selectXlsxFile)));
      return;
    }

    setState(() => _importing = true);
    try {
      final result = await CompanyDetailsExportService().importExcel(path);
      await _loadData();
      if (mounted) {
        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            title: Text(l10n.importComplete),
            content: Text(
              l10n.companyImportResult(
                companyInfoUpdated: result.companyInfoUpdated,
                inspectorsInserted: result.inspectorsInserted,
                inspectorsUpdated: result.inspectorsUpdated,
                instrumentsInserted: result.instrumentsInserted,
                instrumentsUpdated: result.instrumentsUpdated,
                layoutUpdated: result.layoutUpdated,
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('OK'),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(l10n.exportFailed(e))));
      }
    } finally {
      if (mounted) setState(() => _importing = false);
    }
  }

  String _inspectorNameForId(int? inspectorId) {
    if (inspectorId == null) return '';
    final match = _inspectors.where((i) => i.id == inspectorId);
    return match.isNotEmpty ? match.first.name : '';
  }

  @override
  void dispose() {
    _autoSave();
    _companyName.dispose();
    _address.dispose();
    _postalCity.dispose();
    _phone.dispose();
    _email.dispose();
    _contactPerson.dispose();
    _finalResponsible.dispose();
    _herstelFirebaseProjectId.dispose();
    _herstelFirebaseStorageBucket.dispose();
    _herstelWebDomain.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    if (_loading) {
      return Scaffold(
        appBar: AppBar(title: Text(l10n.companyDetails)),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.companyDetails),
        actions: [
          IconButton(
            icon: _importing
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.upload_file_outlined),
            tooltip: l10n.importFromExcel,
            onPressed: _importing ? null : _pickAndImport,
          ),
          IconButton(
            icon: _exporting
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.table_chart_outlined),
            tooltip: l10n.exportToExcel,
            onPressed: _exporting ? null : _exportToExcel,
          ),
        ],
      ),
      body: DropTarget(
        onDragEntered: (_) => setState(() => _dragging = true),
        onDragExited: (_) => setState(() => _dragging = false),
        onDragDone: (detail) {
          setState(() => _dragging = false);
          if (detail.files.isNotEmpty) {
            _runImport(detail.files.first.path);
          }
        },
        child: Stack(
          children: [
            _buildForm(l10n),
            if (_dragging)
              Container(
                color: Colors.blue.withValues(alpha: 0.15),
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.upload_file,
                        size: 64,
                        color: Colors.blue,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        l10n.dropXlsxHere,
                        style: TextStyle(
                          fontSize: 18,
                          color: Colors.blue.shade800,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildForm(AppLocalizations l10n) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ── Bedrijfslogo ───────────────────────────────────────────────
          SectionHeader(title: l10n.companyLogo),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  children: [
                    PhotoContainer(
                      label: l10n.logo,
                      photoPath: _details?.logoPath,
                      height: 150,
                      fit: BoxFit.contain,
                      onPhotoSelected: (path) {
                        setState(
                          () => _details = _details?.copyWith(logoPath: path),
                        );
                        _autoSave();
                      },
                    ),
                    const SizedBox(height: 12),
                    PhotoContainer(
                      label: 'Logo SCIOS',
                      photoPath: _details?.logoSciosPath,
                      height: 150,
                      fit: BoxFit.contain,
                      onPhotoSelected: (path) {
                        setState(
                          () => _details = _details?.copyWith(
                            logoSciosPath: path,
                          ),
                        );
                        _autoSave();
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: PhotoContainer(
                  label: 'Logo titelpagina',
                  photoPath: _details?.logoTitelpaginaPath,
                  height: 450,
                  fit: BoxFit.contain,
                  onPhotoSelected: (path) {
                    setState(
                      () => _details = _details?.copyWith(
                        logoTitelpaginaPath: path,
                      ),
                    );
                    _autoSave();
                  },
                ),
              ),
            ],
          ),

          // ── Titelpagina: positie & afmetingen (standaard) ───────────────
          SectionHeader(title: 'Titelpagina — positie & afmetingen'),
          Padding(
            padding: const EdgeInsets.only(bottom: 8.0),
            child: Text(
              'Deze standaardlayout wordt gebruikt als startpunt voor de titelpagina '
              'van elke nieuwe inspectie.',
              style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
            ),
          ),
          if (_layoutDefaults != null) ...[
            TitlePagePreview(
              titlePage: _layoutDefaults!,
              titleText: 'Titel',
              subtitleText: 'Subtitel',
              effectiveLogoPath: _details?.logoTitelpaginaPath,
              sciosLogoPath: _details?.logoSciosPath,
              addressNameText: 'Inspectieadres',
              locked: _layoutLocked,
              onToggleLock: () => setState(() => _layoutLocked = !_layoutLocked),
              onLayoutChanged: _saveLayoutDefault,
            ),
            const SizedBox(height: 8),
            Theme(
              data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
              child: ExpansionTile(
                tilePadding: EdgeInsets.zero,
                childrenPadding: const EdgeInsets.only(bottom: 8),
                title: const Text(
                  'Positie & afmetingen (voorbeeldpagina)',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                ),
                children: [
                  PositionSizeRow(
                    locked: _layoutLocked,
                    label: 'Titel',
                    cx: _layoutDefaults!.titleX, cy: _layoutDefaults!.titleY,
                    w: _layoutDefaults!.titleW, h: _layoutDefaults!.titleH,
                    onChanged: (cx, cy, w, h) => _saveLayoutDefault(_layoutDefaults!.copyWith(
                        titleX: cx, titleY: cy, titleW: w, titleH: h)),
                  ),
                  PositionSizeRow(
                    locked: _layoutLocked,
                    label: 'Subtitel',
                    cx: _layoutDefaults!.subtitleX, cy: _layoutDefaults!.subtitleY,
                    w: _layoutDefaults!.subtitleW, h: _layoutDefaults!.subtitleH,
                    onChanged: (cx, cy, w, h) => _saveLayoutDefault(_layoutDefaults!.copyWith(
                        subtitleX: cx, subtitleY: cy, subtitleW: w, subtitleH: h)),
                  ),
                  PositionSizeRow(
                    locked: _layoutLocked,
                    label: 'Foto',
                    cx: _layoutDefaults!.photoX, cy: _layoutDefaults!.photoY,
                    w: _layoutDefaults!.photoW, h: _layoutDefaults!.photoH,
                    onChanged: (cx, cy, w, h) => _saveLayoutDefault(_layoutDefaults!.copyWith(
                        photoX: cx, photoY: cy, photoW: w, photoH: h)),
                  ),
                  PositionSizeRow(
                    locked: _layoutLocked,
                    label: 'Inspectiedatum',
                    cx: _layoutDefaults!.dateX, cy: _layoutDefaults!.dateY,
                    w: _layoutDefaults!.dateW, h: _layoutDefaults!.dateH,
                    onChanged: (cx, cy, w, h) => _saveLayoutDefault(_layoutDefaults!.copyWith(
                        dateX: cx, dateY: cy, dateW: w, dateH: h)),
                  ),
                  PositionSizeRow(
                    locked: _layoutLocked,
                    label: 'Identificatiecode',
                    cx: _layoutDefaults!.codeX, cy: _layoutDefaults!.codeY,
                    w: _layoutDefaults!.codeW, h: _layoutDefaults!.codeH,
                    onChanged: (cx, cy, w, h) => _saveLayoutDefault(_layoutDefaults!.copyWith(
                        codeX: cx, codeY: cy, codeW: w, codeH: h)),
                  ),
                  PositionSizeRow(
                    locked: _layoutLocked,
                    label: 'Projectnummer',
                    cx: _layoutDefaults!.projectX, cy: _layoutDefaults!.projectY,
                    w: _layoutDefaults!.projectW, h: _layoutDefaults!.projectH,
                    onChanged: (cx, cy, w, h) => _saveLayoutDefault(_layoutDefaults!.copyWith(
                        projectX: cx, projectY: cy, projectW: w, projectH: h)),
                  ),
                  PositionSizeRow(
                    locked: _layoutLocked,
                    label: 'Inspectieadres',
                    cx: _layoutDefaults!.addressNameX, cy: _layoutDefaults!.addressNameY,
                    w: _layoutDefaults!.addressNameW, h: _layoutDefaults!.addressNameH,
                    onChanged: (cx, cy, w, h) => _saveLayoutDefault(_layoutDefaults!.copyWith(
                        addressNameX: cx, addressNameY: cy, addressNameW: w, addressNameH: h)),
                  ),
                  PositionSizeRow(
                    locked: _layoutLocked,
                    label: 'Logo (SCIOS)',
                    cx: _layoutDefaults!.logoX, cy: _layoutDefaults!.logoY,
                    w: _layoutDefaults!.logoW, h: _layoutDefaults!.logoH,
                    onChanged: (cx, cy, w, h) => _saveLayoutDefault(_layoutDefaults!.copyWith(
                        logoX: cx, logoY: cy, logoW: w, logoH: h)),
                  ),
                ],
              ),
            ),
          ],

          // ── Bedrijfsinformatie ─────────────────────────────────────────
          SectionHeader(title: l10n.companyInfo),
          CustomTextField(
            label: l10n.companyNameField,
            controller: _companyName,
            onChanged: (_) => _autoSave(),
          ),
          CustomTextField(
            label: l10n.address,
            controller: _address,
            onChanged: (_) => _autoSave(),
          ),
          CustomTextField(
            label: l10n.postalCity,
            controller: _postalCity,
            onChanged: (_) => _autoSave(),
          ),
          CustomTextField(
            label: l10n.phone,
            controller: _phone,
            onChanged: (_) => _autoSave(),
            keyboardType: TextInputType.phone,
          ),
          CustomTextField(
            label: l10n.emailLabel,
            controller: _email,
            onChanged: (_) => _autoSave(),
            keyboardType: TextInputType.emailAddress,
          ),
          CustomTextField(
            label: l10n.contactPerson,
            controller: _contactPerson,
            onChanged: (_) => _autoSave(),
          ),
          CustomTextField(
            label: l10n.finalResponsible,
            controller: _finalResponsible,
            onChanged: (_) => _autoSave(),
          ),

          // ── Herstel-koppeling (Firebase) ────────────────────────────────
          SectionHeader(title: l10n.herstelFirebaseSectionTitle),
          CustomTextField(
            label: l10n.herstelFirebaseProjectId,
            controller: _herstelFirebaseProjectId,
            onChanged: (_) => _autoSave(),
          ),
          CustomTextField(
            label: l10n.herstelFirebaseStorageBucket,
            controller: _herstelFirebaseStorageBucket,
            onChanged: (_) => _autoSave(),
          ),
          CustomTextField(
            label: l10n.herstelWebDomain,
            controller: _herstelWebDomain,
            hint: 'mijnrapportageapp.web.app',
            onChanged: (_) => _autoSave(),
          ),
          Padding(
            padding: const EdgeInsets.only(bottom: 8.0),
            child: Text(
              l10n.herstelFirebaseNote,
              style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
            ),
          ),

          // ── Inspecteurs ────────────────────────────────────────────────
          SectionHeader(title: l10n.inspectorsSectionTitle),
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              onPressed: _addInspector,
              icon: const Icon(Icons.add),
              label: Text(l10n.addInspector),
            ),
          ),
          if (_inspectors.isEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 8.0),
              child: Text(
                l10n.noInspectorsAdded,
                style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
              ),
            )
          else
            ..._inspectors.map(
              (inspector) => Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: ListTile(
                  title: Text(inspector.name),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit),
                        onPressed: () => _editInspector(inspector),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () => _deleteInspector(inspector),
                      ),
                    ],
                  ),
                ),
              ),
            ),

          // ── Meetinstrumenten ───────────────────────────────────────────
          SectionHeader(title: l10n.measurementInstrumentsSectionTitle),
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              onPressed: _addInstrument,
              icon: const Icon(Icons.add),
              label: Text(l10n.addMeasurementInstrument),
            ),
          ),
          if (_instruments.isEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 8.0),
              child: Text(
                l10n.noMeasurementInstrumentsAdded,
                style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
              ),
            )
          else
            ..._instruments.map((instrument) {
              final inspectorName = _inspectorNameForId(instrument.inspectorId);
              return Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: ListTile(
                  title: Text(
                    [
                      instrument.fabrikant,
                      instrument.model,
                    ].where((s) => s.isNotEmpty).join(' '),
                  ),
                  subtitle: _buildInstrumentSubtitle(instrument, inspectorName),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit),
                        onPressed: () => _editInstrument(instrument),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () => _deleteInstrument(instrument),
                      ),
                    ],
                  ),
                ),
              );
            }),

          const SizedBox(height: 16),
          Text(
            l10n.autoFillNote,
            style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget? _buildInstrumentSubtitle(
    MeasurementInstrument i,
    String inspectorName,
  ) {
    final line1 = <String>[];
    if (i.serienummer.isNotEmpty) line1.add('SN: ${i.serienummer}');
    if (inspectorName.isNotEmpty) line1.add(inspectorName);
    if (i.status.isNotEmpty) line1.add(i.status);

    final line2 = <String>[];
    if (i.kalibratiedatum.isNotEmpty) line2.add('Kal.: ${i.kalibratiedatum}');
    if (i.herkalibratiedatum.isNotEmpty) {
      line2.add('Herk.: ${i.herkalibratiedatum}');
    }

    if (line1.isEmpty && line2.isEmpty) return null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (line1.isNotEmpty)
          Text(
            line1.join(' · '),
            style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
          ),
        if (line2.isNotEmpty)
          Text(
            line2.join('   '),
            style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
          ),
      ],
    );
  }
}
