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
import '../models/general_data.dart';
import '../models/company_inspector.dart';
import '../models/measurement_instrument.dart';
import '../services/database_service.dart';
import '../widgets/custom_text_field.dart';
import '../widgets/section_header.dart';
import 'inspection_details_page.dart';

class GeneralDataPage extends StatefulWidget {
  final int inspectionId;

  const GeneralDataPage({super.key, required this.inspectionId});

  @override
  State<GeneralDataPage> createState() => _GeneralDataPageState();
}

class _GeneralDataPageState extends State<GeneralDataPage> {
  final _db = DatabaseService();

  final _clientCompany = TextEditingController();
  final _clientAddress = TextEditingController();
  final _clientPostalCity = TextEditingController();
  final _clientContact = TextEditingController();
  final _clientPhone = TextEditingController();

  final _installResponsibleName = TextEditingController();
  final _installResponsiblePhone = TextEditingController();

  final _inspAddrName = TextEditingController();
  final _inspAddrStreet = TextEditingController();
  final _inspAddrPostalCity = TextEditingController();
  final _inspAddrContact = TextEditingController();
  final _inspAddrPhone = TextEditingController();

  final _inspectorCompany = TextEditingController();
  final _inspectorAddress = TextEditingController();
  final _inspectorPostalCity = TextEditingController();
  final _inspectorPhone = TextEditingController();
  final _inspectorEmail = TextEditingController();
  final _inspectorContact = TextEditingController();

  GeneralData? _data;
  List<CompanyInspector> _companyInspectors = [];
  Set<String> _selectedInspectors = {};
  List<MeasurementInstrument> _allInstruments = [];
  Set<int> _selectedInstrumentIds = {};
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final companyInspectors = await _db.getCompanyInspectors();
    final allInstruments = await _db.getAllMeasurementInstruments();
    var data = await _db.getGeneralData(widget.inspectionId);
    if (data == null) {
      final company = await _db.getCompanyDetails();
      final inspectorNames = companyInspectors.map((i) => i.name).toList();
      await _db.insertGeneralData(GeneralData(
        inspectionId: widget.inspectionId,
        inspectorCompany: company?.companyName ?? '',
        inspectorAddress: company?.address ?? '',
        inspectorPostalCity: company?.postalCity ?? '',
        inspectorPhone: company?.phone ?? '',
        inspectorEmail: company?.email ?? '',
        inspectorContact: company?.contactPerson ?? '',
        inspectors: _joinInspectors(inspectorNames),
      ));
      data = await _db.getGeneralData(widget.inspectionId);
    }

    if (data != null) {
      _clientCompany.text = data.clientCompany;
      _clientAddress.text = data.clientAddress;
      _clientPostalCity.text = data.clientPostalCity;
      _clientContact.text = data.clientContact;
      _clientPhone.text = data.clientPhone;
      _installResponsibleName.text = data.installationResponsibleName;
      _installResponsiblePhone.text = data.installationResponsiblePhone;
      _inspAddrName.text = data.inspectionAddressName;
      _inspAddrStreet.text = data.inspectionAddressStreet;
      _inspAddrPostalCity.text = data.inspectionAddressPostalCity;
      _inspAddrContact.text = data.inspectionAddressContact;
      _inspAddrPhone.text = data.inspectionAddressPhone;
      _inspectorCompany.text = data.inspectorCompany;
      _inspectorAddress.text = data.inspectorAddress;
      _inspectorPostalCity.text = data.inspectorPostalCity;
      _inspectorPhone.text = data.inspectorPhone;
      _inspectorEmail.text = data.inspectorEmail;
      _inspectorContact.text = data.inspectorContact;
    }

    setState(() {
      _data = data;
      _companyInspectors = companyInspectors;
      _selectedInspectors = _parseInspectors(data?.inspectors ?? '');
      _allInstruments = allInstruments;
      _selectedInstrumentIds =
          _parseInstrumentIds(data?.measurementInstruments ?? '');
      _loading = false;
    });
  }

  Future<void> _autoSave() async {
    if (_data == null) return;
    final updated = _data!.copyWith(
      clientCompany: _clientCompany.text,
      clientAddress: _clientAddress.text,
      clientPostalCity: _clientPostalCity.text,
      clientContact: _clientContact.text,
      clientPhone: _clientPhone.text,
      installationResponsibleName: _installResponsibleName.text,
      installationResponsiblePhone: _installResponsiblePhone.text,
      inspectionAddressName: _inspAddrName.text,
      inspectionAddressStreet: _inspAddrStreet.text,
      inspectionAddressPostalCity: _inspAddrPostalCity.text,
      inspectionAddressContact: _inspAddrContact.text,
      inspectionAddressPhone: _inspAddrPhone.text,
      inspectorCompany: _inspectorCompany.text,
      inspectorAddress: _inspectorAddress.text,
      inspectorPostalCity: _inspectorPostalCity.text,
      inspectorPhone: _inspectorPhone.text,
      inspectorEmail: _inspectorEmail.text,
      inspectorContact: _inspectorContact.text,
      inspectors: _joinInspectors(_orderedSelectedInspectors()),
      measurementInstruments: _joinInstrumentIds(_selectedInstrumentIds),
    );
    await _db.updateGeneralData(updated);
    _data = updated;
  }

  Set<String> _parseInspectors(String raw) {
    return raw
        .split(RegExp(r'[,\n;]+'))
        .map((name) => name.trim())
        .where((name) => name.isNotEmpty)
        .toSet();
  }

  String _joinInspectors(Iterable<String> names) {
    return names.where((name) => name.trim().isNotEmpty).join(', ');
  }

  List<String> _orderedSelectedInspectors() {
    final ordered = <String>[];
    final companyNames = _companyInspectors.map((i) => i.name).toList();
    final companySet = companyNames.map((e) => e.toLowerCase()).toSet();

    for (final name in companyNames) {
      if (_selectedInspectors.contains(name)) {
        ordered.add(name);
      }
    }

    final extras = _selectedInspectors
        .where((name) => !companySet.contains(name.toLowerCase()))
        .toList()
      ..sort();
    ordered.addAll(extras);
    return ordered;
  }

  Set<int> _parseInstrumentIds(String raw) {
    return raw
        .split(',')
        .map((s) => int.tryParse(s.trim()))
        .whereType<int>()
        .toSet();
  }

  String _joinInstrumentIds(Set<int> ids) {
    return ids.map((id) => id.toString()).join(',');
  }

  String _inspectorNameForId(int? inspectorId) {
    if (inspectorId == null) return '';
    final match = _companyInspectors
        .where((i) => i.id == inspectorId)
        .toList();
    return match.isNotEmpty ? match.first.name : '';
  }

  @override
  void dispose() {
    _autoSave();
    _clientCompany.dispose();
    _clientAddress.dispose();
    _clientPostalCity.dispose();
    _clientContact.dispose();
    _clientPhone.dispose();
    _installResponsibleName.dispose();
    _installResponsiblePhone.dispose();
    _inspAddrName.dispose();
    _inspAddrStreet.dispose();
    _inspAddrPostalCity.dispose();
    _inspAddrContact.dispose();
    _inspAddrPhone.dispose();
    _inspectorCompany.dispose();
    _inspectorAddress.dispose();
    _inspectorPostalCity.dispose();
    _inspectorPhone.dispose();
    _inspectorEmail.dispose();
    _inspectorContact.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    if (_loading) {
      return Scaffold(
        appBar: AppBar(title: Text(l10n.generalData)),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(title: Text(l10n.generalData)),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SectionHeader(title: l10n.client),
            CustomTextField(
              label: l10n.companyName,
              controller: _clientCompany,
              onChanged: (_) => _autoSave(),
            ),
            CustomTextField(
              label: l10n.address,
              controller: _clientAddress,
              onChanged: (_) => _autoSave(),
            ),
            CustomTextField(
              label: l10n.postalCity,
              controller: _clientPostalCity,
              onChanged: (_) => _autoSave(),
            ),
            CustomTextField(
              label: l10n.contactPerson,
              controller: _clientContact,
              onChanged: (_) => _autoSave(),
            ),
            CustomTextField(
              label: l10n.phoneNumber,
              controller: _clientPhone,
              onChanged: (_) => _autoSave(),
              keyboardType: TextInputType.phone,
            ),
            SectionHeader(title: l10n.installationResponsible),
            CustomTextField(
              label: l10n.installationResponsible,
              controller: _installResponsibleName,
              onChanged: (_) => _autoSave(),
            ),
            CustomTextField(
              label: l10n.phoneNumber,
              controller: _installResponsiblePhone,
              onChanged: (_) => _autoSave(),
              keyboardType: TextInputType.phone,
            ),
            SectionHeader(title: l10n.inspectionAddress),
            CustomTextField(
              label: l10n.name,
              controller: _inspAddrName,
              onChanged: (_) => _autoSave(),
            ),
            CustomTextField(
              label: l10n.address,
              controller: _inspAddrStreet,
              onChanged: (_) => _autoSave(),
            ),
            CustomTextField(
              label: l10n.postalCity,
              controller: _inspAddrPostalCity,
              onChanged: (_) => _autoSave(),
            ),
            CustomTextField(
              label: l10n.contactPerson,
              controller: _inspAddrContact,
              onChanged: (_) => _autoSave(),
            ),
            CustomTextField(
              label: l10n.phoneNumber,
              controller: _inspAddrPhone,
              onChanged: (_) => _autoSave(),
              keyboardType: TextInputType.phone,
            ),
            SectionHeader(title: l10n.inspectionCompany),
            CustomTextField(
              label: l10n.companyNameField,
              controller: _inspectorCompany,
              onChanged: (_) => _autoSave(),
            ),
            CustomTextField(
              label: l10n.address,
              controller: _inspectorAddress,
              onChanged: (_) => _autoSave(),
            ),
            CustomTextField(
              label: l10n.postalCity,
              controller: _inspectorPostalCity,
              onChanged: (_) => _autoSave(),
            ),
            CustomTextField(
              label: l10n.phone,
              controller: _inspectorPhone,
              onChanged: (_) => _autoSave(),
              keyboardType: TextInputType.phone,
            ),
            CustomTextField(
              label: l10n.emailField,
              controller: _inspectorEmail,
              onChanged: (_) => _autoSave(),
              keyboardType: TextInputType.emailAddress,
            ),
            CustomTextField(
              label: l10n.contactPerson,
              controller: _inspectorContact,
              onChanged: (_) => _autoSave(),
            ),
            const SizedBox(height: 8),
            Text(
              l10n.inspectors,
              style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
            ),
            const SizedBox(height: 6),
            if (_companyInspectors.isEmpty)
              Text(
                l10n.noInspectorsFound,
                style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
              )
            else
              Wrap(
                spacing: 8,
                runSpacing: 4,
                children: _companyInspectors.map((inspector) {
                  final selected = _selectedInspectors.contains(inspector.name);
                  return FilterChip(
                    label: Text(inspector.name),
                    selected: selected,
                    onSelected: (value) {
                      setState(() {
                        if (value) {
                          _selectedInspectors.add(inspector.name);
                        } else {
                          _selectedInspectors.remove(inspector.name);
                        }
                      });
                      _autoSave();
                    },
                  );
                }).toList(),
              ),
            Builder(builder: (context) {
              final companySet =
                  _companyInspectors.map((i) => i.name.toLowerCase()).toSet();
              final extras = _selectedInspectors
                  .where((name) => !companySet.contains(name.toLowerCase()))
                  .toList()
                ..sort();
              if (extras.isEmpty) return const SizedBox.shrink();
              return Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  children: extras
                      .map(
                        (name) => Chip(
                          label: Text(name),
                          onDeleted: () {
                            setState(() {
                              _selectedInspectors.remove(name);
                            });
                            _autoSave();
                          },
                        ),
                      )
                      .toList(),
                ),
              );
            }),
            const SizedBox(height: 16),
            // ── Meetinstrumenten ──────────────────────────────────────────
            SectionHeader(title: l10n.measurementInstrumentsSectionTitle),
            if (_allInstruments.isEmpty)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text(
                  l10n.noMeasurementInstrumentsFound,
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                ),
              )
            else
              Wrap(
                spacing: 8,
                runSpacing: 4,
                children: _allInstruments.map((instrument) {
                  final selected =
                      _selectedInstrumentIds.contains(instrument.id);
                  final inspectorName =
                      _inspectorNameForId(instrument.inspectorId);
                  final chipLabel = [
                    instrument.fabrikant,
                    instrument.model,
                  ].where((s) => s.isNotEmpty).join(' ');
                  return FilterChip(
                    label: Text(chipLabel.isNotEmpty
                        ? chipLabel
                        : instrument.serienummer),
                    tooltip: [
                      if (instrument.serienummer.isNotEmpty)
                        'SN: ${instrument.serienummer}',
                      if (inspectorName.isNotEmpty) inspectorName,
                      if (instrument.status.isNotEmpty) instrument.status,
                    ].join(' · '),
                    selected: selected,
                    onSelected: (value) {
                      setState(() {
                        if (value) {
                          _selectedInstrumentIds.add(instrument.id!);
                        } else {
                          _selectedInstrumentIds.remove(instrument.id);
                        }
                      });
                      _autoSave();
                    },
                  );
                }).toList(),
              ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () async {
                final navigator = Navigator.of(context);
                await _autoSave();
                if (!mounted) return;
                navigator.push(
                  MaterialPageRoute(
                    builder: (_) => InspectionDetailsPage(
                        inspectionId: widget.inspectionId),
                  ),
                );
              },
              child: Text(l10n.next),
            ),
          ],
        ),
      ),
    );
  }
}
