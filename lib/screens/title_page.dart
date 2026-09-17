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
import '../l10n/app_localizations.dart';
import '../models/company_details.dart';
import '../models/general_data.dart';
import '../models/title_page.dart' as model;
import '../services/database_service.dart';
import '../widgets/custom_text_field.dart';
import '../widgets/photo_container.dart';
import '../widgets/title_page_preview.dart';
import 'general_data_page.dart';

class TitlePageScreen extends StatefulWidget {
  final int inspectionId;

  const TitlePageScreen({super.key, required this.inspectionId});

  @override
  State<TitlePageScreen> createState() => _TitlePageScreenState();
}

class _TitlePageScreenState extends State<TitlePageScreen> {
  final _db = DatabaseService();
  final _titleController = TextEditingController();
  final _subtitleController = TextEditingController();
  final _dateController = TextEditingController();
  final _dateEndController = TextEditingController();
  final _codeController = TextEditingController();
  final _projectController = TextEditingController();

  model.TitlePage? _titlePage;
  CompanyDetails? _companyDetails;
  GeneralData? _generalData;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    var tp = await _db.getOrCreateTitlePage(widget.inspectionId);
    if (tp.inspectionDate.isEmpty) {
      tp = tp.copyWith(
          inspectionDate: DateFormat('dd-MM-yyyy').format(DateTime.now()));
      await _db.updateTitlePage(tp);
    }

    _titleController.text = tp.title;
    _subtitleController.text = tp.subtitle;
    _dateController.text = tp.inspectionDate;
    _dateEndController.text = tp.inspectionDateEnd;
    _codeController.text = tp.identificationCode;
    _projectController.text = tp.projectNumber;

    final companyDetails = await _db.getCompanyDetails();
    final generalData = await _db.getGeneralData(widget.inspectionId);

    setState(() {
      _titlePage = tp;
      _companyDetails = companyDetails;
      _generalData = generalData;
      _loading = false;
    });
  }

  Future<void> _autoSave() async {
    if (_titlePage == null) return;
    final updated = _titlePage!.copyWith(
      title: _titleController.text,
      subtitle: _subtitleController.text,
      inspectionDate: _dateController.text,
      inspectionDateEnd: _dateEndController.text,
      identificationCode: _codeController.text,
      projectNumber: _projectController.text,
    );
    await _db.updateTitlePage(updated);
    _titlePage = updated;
  }

  Future<void> _saveLayout(model.TitlePage updated) async {
    await _db.updateTitlePage(updated);
    setState(() => _titlePage = updated);
  }

  Future<void> _loadLayoutFromCompanyDefaults() async {
    if (_titlePage == null) return;
    final messenger = ScaffoldMessenger.of(context);
    final d = await _db.getTitlePageLayoutDefaults();
    if (d == null) {
      messenger.showSnackBar(
        const SnackBar(
          content: Text('Geen standaardlayout gevonden in bedrijfsgegevens'),
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }
    await _saveLayout(_titlePage!.copyWith(
      titleX: d['title_x'], titleY: d['title_y'],
      titleW: d['title_w'], titleH: d['title_h'],
      subtitleX: d['subtitle_x'], subtitleY: d['subtitle_y'],
      subtitleW: d['subtitle_w'], subtitleH: d['subtitle_h'],
      photoX: d['photo_x'], photoY: d['photo_y'],
      photoW: d['photo_w'], photoH: d['photo_h'],
      dateX: d['date_x'], dateY: d['date_y'],
      dateW: d['date_w'], dateH: d['date_h'],
      codeX: d['code_x'], codeY: d['code_y'],
      codeW: d['code_w'], codeH: d['code_h'],
      projectX: d['project_x'], projectY: d['project_y'],
      projectW: d['project_w'], projectH: d['project_h'],
      logoX: d['logo_x'], logoY: d['logo_y'],
      logoW: d['logo_w'], logoH: d['logo_h'],
      addressNameX: d['address_name_x'], addressNameY: d['address_name_y'],
      addressNameW: d['address_name_w'], addressNameH: d['address_name_h'],
    ));
    messenger.showSnackBar(
      const SnackBar(
        content: Text('Positie & afmetingen opgehaald uit bedrijfsgegevens'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  @override
  void dispose() {
    _autoSave();
    _titleController.dispose();
    _subtitleController.dispose();
    _dateController.dispose();
    _dateEndController.dispose();
    _codeController.dispose();
    _projectController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    if (_loading) {
      return Scaffold(
        appBar: AppBar(title: Text(l10n.titlePageTitle)),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(title: Text(l10n.titlePageTitle)),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ── Draggable + resizable A4 preview ──────────────
            TitlePagePreview(
              titlePage: _titlePage!,
              titleText: _titleController.text,
              subtitleText: _subtitleController.text,
              onLayoutChanged: _saveLayout,
              effectiveLogoPath: _titlePage?.logoTitelpaginaPath ?? _companyDetails?.logoTitelpaginaPath,
              sciosLogoPath: _companyDetails?.logoSciosPath,
              addressNameText: _generalData?.inspectionAddressName ?? '',
              locked: _titlePage!.layoutLocked,
              onToggleLock: () => _saveLayout(
                  _titlePage!.copyWith(layoutLocked: !_titlePage!.layoutLocked)),
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
                    locked: _titlePage!.layoutLocked,
                    label: 'Titel',
                    cx: _titlePage!.titleX, cy: _titlePage!.titleY,
                    w: _titlePage!.titleW, h: _titlePage!.titleH,
                    onChanged: (cx, cy, w, h) => _saveLayout(_titlePage!.copyWith(
                        titleX: cx, titleY: cy, titleW: w, titleH: h)),
                  ),
                  PositionSizeRow(
                    locked: _titlePage!.layoutLocked,
                    label: 'Subtitel',
                    cx: _titlePage!.subtitleX, cy: _titlePage!.subtitleY,
                    w: _titlePage!.subtitleW, h: _titlePage!.subtitleH,
                    onChanged: (cx, cy, w, h) => _saveLayout(_titlePage!.copyWith(
                        subtitleX: cx, subtitleY: cy, subtitleW: w, subtitleH: h)),
                  ),
                  PositionSizeRow(
                    locked: _titlePage!.layoutLocked,
                    label: 'Foto',
                    cx: _titlePage!.photoX, cy: _titlePage!.photoY,
                    w: _titlePage!.photoW, h: _titlePage!.photoH,
                    onChanged: (cx, cy, w, h) => _saveLayout(_titlePage!.copyWith(
                        photoX: cx, photoY: cy, photoW: w, photoH: h)),
                  ),
                  PositionSizeRow(
                    locked: _titlePage!.layoutLocked,
                    label: 'Inspectiedatum',
                    cx: _titlePage!.dateX, cy: _titlePage!.dateY,
                    w: _titlePage!.dateW, h: _titlePage!.dateH,
                    onChanged: (cx, cy, w, h) => _saveLayout(_titlePage!.copyWith(
                        dateX: cx, dateY: cy, dateW: w, dateH: h)),
                  ),
                  PositionSizeRow(
                    locked: _titlePage!.layoutLocked,
                    label: 'Identificatiecode',
                    cx: _titlePage!.codeX, cy: _titlePage!.codeY,
                    w: _titlePage!.codeW, h: _titlePage!.codeH,
                    onChanged: (cx, cy, w, h) => _saveLayout(_titlePage!.copyWith(
                        codeX: cx, codeY: cy, codeW: w, codeH: h)),
                  ),
                  PositionSizeRow(
                    locked: _titlePage!.layoutLocked,
                    label: 'Projectnummer',
                    cx: _titlePage!.projectX, cy: _titlePage!.projectY,
                    w: _titlePage!.projectW, h: _titlePage!.projectH,
                    onChanged: (cx, cy, w, h) => _saveLayout(_titlePage!.copyWith(
                        projectX: cx, projectY: cy, projectW: w, projectH: h)),
                  ),
                  PositionSizeRow(
                    locked: _titlePage!.layoutLocked,
                    label: 'Inspectieadres',
                    cx: _titlePage!.addressNameX, cy: _titlePage!.addressNameY,
                    w: _titlePage!.addressNameW, h: _titlePage!.addressNameH,
                    onChanged: (cx, cy, w, h) => _saveLayout(_titlePage!.copyWith(
                        addressNameX: cx, addressNameY: cy, addressNameW: w, addressNameH: h)),
                  ),
                  PositionSizeRow(
                    locked: _titlePage!.layoutLocked,
                    label: 'Logo (SCIOS)',
                    cx: _titlePage!.logoX, cy: _titlePage!.logoY,
                    w: _titlePage!.logoW, h: _titlePage!.logoH,
                    onChanged: (cx, cy, w, h) => _saveLayout(_titlePage!.copyWith(
                        logoX: cx, logoY: cy, logoW: w, logoH: h)),
                  ),
                ],
              ),
            ),
            Wrap(
              alignment: WrapAlignment.end,
              spacing: 8,
              children: [
                TextButton.icon(
                  onPressed: _titlePage == null ? null : _loadLayoutFromCompanyDefaults,
                  icon: const Icon(Icons.download_outlined, size: 18),
                  label: const Text('Ophalen uit bedrijfsgegevens'),
                ),
                TextButton.icon(
                  onPressed: _titlePage == null ? null : () async {
                    final messenger = ScaffoldMessenger.of(context);
                    await _db.saveTitlePageLayoutDefaults(_titlePage!);
                    messenger.showSnackBar(
                      const SnackBar(
                        content: Text('Lay-out opgeslagen als standaard'),
                        duration: Duration(seconds: 2),
                      ),
                    );
                  },
                  icon: const Icon(Icons.save_alt, size: 18),
                  label: const Text('Sla op als standaard'),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // ── Form fields ────────────────────────────────────
            CustomTextField(
              label: l10n.titleLabel,
              controller: _titleController,
              onChanged: (_) {
                _autoSave();
                setState(() {});
              },
            ),
            CustomTextField(
              label: l10n.subtitleLabel,
              controller: _subtitleController,
              onChanged: (_) => _autoSave(),
            ),
            const SizedBox(height: 16),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: 2,
                  child: PhotoContainer(
                    photoPath: _titlePage?.photoPath,
                    label: l10n.addPhoto,
                    aspectRatio: 4 / 3,
                    onPhotoSelected: (path) {
                      setState(() {
                        _titlePage = _titlePage!.copyWith(photoPath: path);
                      });
                      _autoSave();
                    },
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  flex: 2,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: CustomTextField(
                              label: l10n.inspectionDate,
                              controller: _dateController,
                              onChanged: (_) => _autoSave(),
                              readOnly: true,
                              onTap: () async {
                                final date = await showDatePicker(
                                  context: context,
                                  initialDate: DateTime.now(),
                                  firstDate: DateTime(2020),
                                  lastDate: DateTime(2030),
                                );
                                if (date != null) {
                                  _dateController.text =
                                      DateFormat('dd-MM-yyyy').format(date);
                                  _autoSave();
                                }
                              },
                              onClear: () {
                                setState(() => _dateController.clear());
                                _autoSave();
                              },
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: CustomTextField(
                              label: l10n.inspectionDateEnd,
                              controller: _dateEndController,
                              onChanged: (_) => _autoSave(),
                              readOnly: true,
                              onTap: () async {
                                final date = await showDatePicker(
                                  context: context,
                                  initialDate: DateTime.now(),
                                  firstDate: DateTime(2020),
                                  lastDate: DateTime(2030),
                                );
                                if (date != null) {
                                  _dateEndController.text =
                                      DateFormat('dd-MM-yyyy').format(date);
                                  _autoSave();
                                }
                              },
                              onClear: () {
                                setState(() => _dateEndController.clear());
                                _autoSave();
                              },
                            ),
                          ),
                        ],
                      ),
                      _TextColorRow(
                        label: l10n.inspectionDate.isNotEmpty
                            ? (_titlePage!.inspectionDateEnd.isNotEmpty
                                ? 'Tekstkleur Inspectieperiode'
                                : 'Tekstkleur Inspectiedatum')
                            : 'Tekstkleur Datum',
                        isWhite: _titlePage!.dateColorWhite,
                        onChanged: (val) async {
                          final updated = _titlePage!.copyWith(dateColorWhite: val);
                          await _db.updateTitlePage(updated);
                          setState(() => _titlePage = updated);
                        },
                      ),
                      CustomTextField(
                        label: l10n.identificationCode,
                        controller: _codeController,
                        onChanged: (_) => _autoSave(),
                      ),
                      _TextColorRow(
                        label: 'Tekstkleur Identificatiecode',
                        isWhite: _titlePage!.codeColorWhite,
                        onChanged: (val) async {
                          final updated = _titlePage!.copyWith(codeColorWhite: val);
                          await _db.updateTitlePage(updated);
                          setState(() => _titlePage = updated);
                        },
                      ),
                      CustomTextField(
                        label: l10n.projectNumber,
                        controller: _projectController,
                        onChanged: (_) => _autoSave(),
                      ),
                      _TextColorRow(
                        label: 'Tekstkleur Projectnummer',
                        isWhite: _titlePage!.projectColorWhite,
                        onChanged: (val) async {
                          final updated = _titlePage!.copyWith(projectColorWhite: val);
                          await _db.updateTitlePage(updated);
                          setState(() => _titlePage = updated);
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (_companyDetails?.logoSciosPath != null &&
                File(_companyDetails!.logoSciosPath!).existsSync()) ...[
              const SizedBox(height: 8),
              SwitchListTile(
                title: const Text('Logo SCIOS tonen in PDF'),
                value: _titlePage!.showSciosLogo,
                onChanged: (val) async {
                  final updated = _titlePage!.copyWith(showSciosLogo: val);
                  await _db.updateTitlePage(updated);
                  setState(() => _titlePage = updated);
                },
                contentPadding: EdgeInsets.zero,
              ),
            ],
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () async {
                final navigator = Navigator.of(context);
                await _autoSave();
                if (!mounted) return;
                navigator.push(
                  MaterialPageRoute(
                    builder: (_) => GeneralDataPage(
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

// ── Text colour toggle (black / white) for PDF fields ────────────────────────

class _TextColorRow extends StatelessWidget {
  final String label;
  final bool isWhite;
  final ValueChanged<bool> onChanged;

  const _TextColorRow({
    required this.label,
    required this.isWhite,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Text(label,
              style: Theme.of(context)
                  .textTheme
                  .bodySmall
                  ?.copyWith(color: Colors.grey.shade700)),
          const Spacer(),
          SegmentedButton<bool>(
            segments: const [
              ButtonSegment(
                value: false,
                label: Text('Zwart'),
                icon: Icon(Icons.circle, size: 12, color: Colors.black),
              ),
              ButtonSegment(
                value: true,
                label: Text('Wit'),
                icon: Icon(Icons.circle_outlined, size: 12),
              ),
            ],
            selected: {isWhite},
            onSelectionChanged: (s) => onChanged(s.first),
            style: const ButtonStyle(
              visualDensity: VisualDensity.compact,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
          ),
        ],
      ),
    );
  }
}
