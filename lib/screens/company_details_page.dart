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
import '../models/company_details.dart';
import '../models/company_inspector.dart';
import '../models/measurement_instrument.dart';
import '../services/database_service.dart';
import '../widgets/custom_text_field.dart';
import '../widgets/photo_container.dart';
import '../widgets/section_header.dart';
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
  final _herstelFirebaseProjectId = TextEditingController();
  final _herstelFirebaseStorageBucket = TextEditingController();
  final _herstelWebDomain = TextEditingController();

  CompanyDetails? _details;
  List<CompanyInspector> _inspectors = [];
  List<MeasurementInstrument> _instruments = [];
  bool _loading = true;

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

    if (details != null) {
      _companyName.text = details.companyName;
      _address.text = details.address;
      _postalCity.text = details.postalCity;
      _phone.text = details.phone;
      _email.text = details.email;
      _contactPerson.text = details.contactPerson;
      _herstelFirebaseProjectId.text = details.herstelFirebaseProjectId;
      _herstelFirebaseStorageBucket.text = details.herstelFirebaseStorageBucket;
      _herstelWebDomain.text = details.herstelWebDomain;
    }

    setState(() {
      _details = details;
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
      herstelFirebaseProjectId: _herstelFirebaseProjectId.text,
      herstelFirebaseStorageBucket: _herstelFirebaseStorageBucket.text,
      herstelWebDomain: _herstelWebDomain.text,
    );
    await _db.saveCompanyDetails(updated);
    _details = updated;
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
      MaterialPageRoute(
        builder: (_) => const InspectorDetailPage(),
      ),
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
            child:
                Text(l10n.delete, style: const TextStyle(color: Colors.red)),
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
      MaterialPageRoute(
        builder: (_) => const MeasurementInstrumentPage(),
      ),
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
            l10n.deleteMeasurementInstrumentConfirm(instrument.displayName)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l10n.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child:
                Text(l10n.delete, style: const TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    await _db.deleteMeasurementInstrument(instrument.id!);
    await _refreshInstruments();
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
      appBar: AppBar(title: Text(l10n.companyDetails)),
      body: SingleChildScrollView(
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
                        onPhotoSelected: (path) {
                          setState(() => _details = _details?.copyWith(logoPath: path));
                          _autoSave();
                        },
                      ),
                      const SizedBox(height: 12),
                      PhotoContainer(
                        label: 'Logo SCIOS',
                        photoPath: _details?.logoSciosPath,
                        height: 150,
                        onPhotoSelected: (path) {
                          setState(() => _details = _details?.copyWith(logoSciosPath: path));
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
                    onPhotoSelected: (path) {
                      setState(() => _details = _details?.copyWith(logoTitelpaginaPath: path));
                      _autoSave();
                    },
                  ),
                ),
              ],
            ),

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
              ..._inspectors.map((inspector) => Card(
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
                            icon:
                                const Icon(Icons.delete, color: Colors.red),
                            onPressed: () => _deleteInspector(inspector),
                          ),
                        ],
                      ),
                    ),
                  )),

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
                final inspectorName =
                    _inspectorNameForId(instrument.inspectorId);
                return Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    title: Text(
                      [instrument.fabrikant, instrument.model]
                          .where((s) => s.isNotEmpty)
                          .join(' '),
                    ),
                    subtitle: _buildInstrumentSubtitle(
                        instrument, inspectorName),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.edit),
                          onPressed: () => _editInstrument(instrument),
                        ),
                        IconButton(
                          icon:
                              const Icon(Icons.delete, color: Colors.red),
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
      ),
    );
  }

  Widget? _buildInstrumentSubtitle(
      MeasurementInstrument i, String inspectorName) {
    final line1 = <String>[];
    if (i.serienummer.isNotEmpty) line1.add('SN: ${i.serienummer}');
    if (inspectorName.isNotEmpty) line1.add(inspectorName);
    if (i.status.isNotEmpty) line1.add(i.status);

    final line2 = <String>[];
    if (i.kalibratiedatum.isNotEmpty) line2.add('Kal.: ${i.kalibratiedatum}');
    if (i.herkalibratiedatum.isNotEmpty) line2.add('Herk.: ${i.herkalibratiedatum}');

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
