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
      appBar: AppBar(title: Text(l10n.inleidingTitle)),
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
