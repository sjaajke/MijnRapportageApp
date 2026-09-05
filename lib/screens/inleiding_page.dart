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
import '../models/inspection_detail.dart';
import '../services/database_service.dart';
import '../utils/inleiding_placeholders.dart';
import '../widgets/custom_text_field.dart';
import '../widgets/section_header.dart';

class InleidingPage extends StatefulWidget {
  final int inspectionId;

  const InleidingPage({super.key, required this.inspectionId});

  @override
  State<InleidingPage> createState() => _InleidingPageState();
}

class _InleidingPageState extends State<InleidingPage> {
  final _db = DatabaseService();
  final _inleidingCtrl = TextEditingController();

  InspectionDetail? _detail;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    var detail = await _db.getInspectionDetail(widget.inspectionId);
    if (detail == null) {
      await _db.insertInspectionDetail(
          InspectionDetail(inspectionId: widget.inspectionId));
      detail = await _db.getInspectionDetail(widget.inspectionId);
    }
    if (detail != null) {
      _inleidingCtrl.text = detail.inleiding;
    }
    setState(() {
      _detail = detail;
      _loading = false;
    });
  }

  Future<void> _autoSave() async {
    if (_detail == null) return;
    final updated = _detail!.copyWith(inleiding: _inleidingCtrl.text);
    await _db.updateInspectionDetail(updated);
    _detail = updated;
  }

  Future<void> _refreshFromTemplate() async {
    final detail = _detail;
    if (detail == null || detail.typeRapport.isEmpty) return;

    final templates = await _db.getReportTemplates();
    final matches =
        templates.where((t) => t.typeRapport == detail.typeRapport);
    if (matches.isEmpty) return;
    final template = matches.first;

    final generalData = await _db.getGeneralData(widget.inspectionId);
    final titlePage = await _db.getTitlePage(widget.inspectionId);

    final inleiding = fillInleidingPlaceholders(
      template.inleiding,
      generalData: generalData,
      titlePage: titlePage,
    );

    setState(() => _inleidingCtrl.text = inleiding);
    await _autoSave();
  }

  Future<void> _confirmRefreshFromTemplate() async {
    final l10n = AppLocalizations.of(context);
    if (_detail == null || _detail!.typeRapport.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.isNl
              ? 'Selecteer eerst een rapport type.'
              : 'Please select a report type first.'),
        ),
      );
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.isNl ? 'Tekst opnieuw ophalen' : 'Reload text'),
        content: Text(l10n.isNl
            ? 'Dit overschrijft de huidige inleidingstekst met de sjabloontekst en vult de gegevens automatisch opnieuw in. Weet u het zeker?'
            : 'This will overwrite the current introduction text with the template text and automatically fill in the values again. Are you sure?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l10n.isNl ? 'Annuleren' : 'Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(l10n.isNl ? 'Ja, opnieuw ophalen' : 'Yes, reload'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await _refreshFromTemplate();
    }
  }

  @override
  void dispose() {
    _autoSave();
    _inleidingCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    if (_loading) {
      return Scaffold(
        appBar: AppBar(title: Text(l10n.inleidingTitle)),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.inleidingTitle),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: l10n.isNl ? 'Tekst opnieuw ophalen' : 'Reload text',
            onPressed: _confirmRefreshFromTemplate,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SectionHeader(title: l10n.inleidingTitle),
            CustomTextField(
              label: l10n.inleidingLabel,
              controller: _inleidingCtrl,
              onChanged: (_) => _autoSave(),
              maxLines: 20,
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}
