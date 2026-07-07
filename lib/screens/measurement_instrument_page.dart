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
import '../models/company_inspector.dart';
import '../models/measurement_instrument.dart';
import '../services/database_service.dart';
import '../widgets/custom_text_field.dart';
import '../widgets/section_header.dart';

class MeasurementInstrumentPage extends StatefulWidget {
  final MeasurementInstrument? instrument;

  const MeasurementInstrumentPage({super.key, this.instrument});

  @override
  State<MeasurementInstrumentPage> createState() =>
      _MeasurementInstrumentPageState();
}

class _MeasurementInstrumentPageState
    extends State<MeasurementInstrumentPage> {
  final _db = DatabaseService();

  final _fabrikant = TextEditingController();
  final _model = TextEditingController();
  final _serienummer = TextEditingController();
  final _kalibratiedatum = TextEditingController();
  final _herkalibratiedatum = TextEditingController();
  final _certificaatnummer = TextEditingController();
  final _kalibratiefrequentie = TextEditingController();
  final _registratienummer = TextEditingController();
  final _status = TextEditingController();

  List<CompanyInspector> _inspectors = [];
  int? _selectedInspectorId;
  bool _loading = true;

  bool get _isNew => widget.instrument == null;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final inspectors = await _db.getCompanyInspectors();
    final instr = widget.instrument;
    if (instr != null) {
      _fabrikant.text = instr.fabrikant;
      _model.text = instr.model;
      _serienummer.text = instr.serienummer;
      _kalibratiedatum.text = instr.kalibratiedatum;
      _herkalibratiedatum.text = instr.herkalibratiedatum;
      _certificaatnummer.text = instr.certificaatnummer;
      _kalibratiefrequentie.text = instr.kalibratiefrequentie;
      _registratienummer.text = instr.registratienummer;
      _status.text = instr.status;
    }
    setState(() {
      _inspectors = inspectors;
      _selectedInspectorId = instr?.inspectorId;
      _loading = false;
    });
  }

  Future<void> _save() async {
    final instrument = MeasurementInstrument(
      id: widget.instrument?.id,
      inspectorId: _selectedInspectorId,
      fabrikant: _fabrikant.text.trim(),
      model: _model.text.trim(),
      serienummer: _serienummer.text.trim(),
      kalibratiedatum: _kalibratiedatum.text.trim(),
      herkalibratiedatum: _herkalibratiedatum.text.trim(),
      certificaatnummer: _certificaatnummer.text.trim(),
      kalibratiefrequentie: _kalibratiefrequentie.text.trim(),
      registratienummer: _registratienummer.text.trim(),
      status: _status.text.trim(),
    );

    if (_isNew) {
      await _db.insertMeasurementInstrument(instrument);
    } else {
      await _db.updateMeasurementInstrument(instrument);
    }

    if (!mounted) return;
    Navigator.pop(context, true);
  }

  @override
  void dispose() {
    _fabrikant.dispose();
    _model.dispose();
    _serienummer.dispose();
    _kalibratiedatum.dispose();
    _herkalibratiedatum.dispose();
    _certificaatnummer.dispose();
    _kalibratiefrequentie.dispose();
    _registratienummer.dispose();
    _status.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    if (_loading) {
      return Scaffold(
        appBar: AppBar(
          title: Text(_isNew
              ? l10n.addMeasurementInstrument
              : l10n.editMeasurementInstrument),
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(_isNew
            ? l10n.addMeasurementInstrument
            : l10n.editMeasurementInstrument),
        actions: [
          TextButton(
            onPressed: _save,
            child: Text(
              l10n.save,
              style: const TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SectionHeader(title: l10n.measurementInstrumentsSectionTitle),
            CustomTextField(
              label: l10n.manufacturer,
              controller: _fabrikant,
            ),
            CustomTextField(
              label: l10n.instrumentModel,
              controller: _model,
            ),
            CustomTextField(
              label: l10n.serialNumber,
              controller: _serienummer,
            ),
            CustomTextField(
              label: l10n.registrationNumber,
              controller: _registratienummer,
            ),
            const SizedBox(height: 16),
            SectionHeader(title: l10n.calibrationSectionTitle),
            CustomTextField(
              label: l10n.calibrationDate,
              controller: _kalibratiedatum,
              hint: 'dd-mm-jjjj',
            ),
            CustomTextField(
              label: l10n.recalibrationDate,
              controller: _herkalibratiedatum,
              hint: 'dd-mm-jjjj',
            ),
            CustomTextField(
              label: l10n.certificateNumber,
              controller: _certificaatnummer,
            ),
            CustomTextField(
              label: l10n.calibrationFrequency,
              controller: _kalibratiefrequentie,
              keyboardType: TextInputType.number,
            ),
            CustomTextField(
              label: l10n.instrumentStatus,
              controller: _status,
              hint: 'bijv. Actief, Indicatief',
            ),
            const SizedBox(height: 16),
            SectionHeader(title: l10n.inspectorsSectionTitle),
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: InputDecorator(
                decoration: InputDecoration(
                  labelText: l10n.linkedInspector,
                  border: const OutlineInputBorder(),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<int?>(
                    value: _selectedInspectorId,
                    isDense: true,
                    items: [
                      DropdownMenuItem<int?>(
                        value: null,
                        child: Text(l10n.noInspectorLinked),
                      ),
                      ..._inspectors.map(
                        (i) => DropdownMenuItem<int?>(
                          value: i.id,
                          child: Text(i.name),
                        ),
                      ),
                    ],
                    onChanged: (value) {
                      setState(() => _selectedInspectorId = value);
                    },
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _save,
              child: Text(l10n.save),
            ),
          ],
        ),
      ),
    );
  }
}
