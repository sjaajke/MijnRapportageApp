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
import '../models/inspection_detail.dart';
import '../services/database_service.dart';
import '../widgets/custom_text_field.dart';
import '../widgets/section_header.dart';

class HerstelverklaringPage extends StatefulWidget {
  final int inspectionId;

  const HerstelverklaringPage({super.key, required this.inspectionId});

  @override
  State<HerstelverklaringPage> createState() => _HerstelverklaringPageState();
}

class _HerstelverklaringPageState extends State<HerstelverklaringPage> {
  final _db = DatabaseService();
  final _omschrijving = TextEditingController();

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
      _omschrijving.text = detail.herstelVerklaring;
    }
    setState(() {
      _detail = detail;
      _loading = false;
    });
  }

  Future<void> _autoSave() async {
    if (_detail == null) return;
    final updated = _detail!.copyWith(herstelVerklaring: _omschrijving.text);
    await _db.updateInspectionDetail(updated);
    _detail = updated;
  }

  @override
  void dispose() {
    _autoSave();
    _omschrijving.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Herstelverklaring')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Herstelverklaring')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SectionHeader(title: 'Herstelwerkzaamheden'),
            const SizedBox(height: 8),
            Expanded(
              child: CustomTextField(
                label: 'Herstelverklaring',
                controller: _omschrijving,
                onChanged: (_) => _autoSave(),
                expands: true,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
