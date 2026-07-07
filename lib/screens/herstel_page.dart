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
import '../models/herstel.dart';
import '../services/database_service.dart';
import '../services/herstel_sync_service.dart';
import '../widgets/custom_text_field.dart';
import '../widgets/photo_container.dart';
import '../widgets/section_header.dart';

class HerstelPage extends StatefulWidget {
  final int defectId;
  final int inspectionId;
  final String defectLabel;

  const HerstelPage({
    super.key,
    required this.defectId,
    required this.inspectionId,
    this.defectLabel = '',
  });

  @override
  State<HerstelPage> createState() => _HerstelPageState();
}

class _HerstelPageState extends State<HerstelPage> {
  final _db = DatabaseService();

  final _naamController = TextEditingController();
  final _datumController = TextEditingController();
  final _toelichtingController = TextEditingController();

  Herstel? _herstel;
  bool _loading = true;
  bool _ophalenBezig = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    var herstel = await _db.getHerstel(widget.defectId);
    if (herstel == null) {
      final id = await _db.insertHerstel(Herstel(defectId: widget.defectId));
      herstel = await _db.getHerstel(widget.defectId);
      herstel ??= Herstel(id: id, defectId: widget.defectId);
    }
    _naamController.text = herstel.naam;
    _datumController.text = herstel.datum;
    _toelichtingController.text = herstel.toelichting;
    setState(() {
      _herstel = herstel;
      _loading = false;
    });
  }

  Future<void> _save() async {
    if (_herstel == null) return;
    final updated = _herstel!.copyWith(
      naam: _naamController.text,
      datum: _datumController.text,
      toelichting: _toelichtingController.text,
    );
    await _db.updateHerstel(updated);
    _herstel = updated;
  }

  Future<void> _ophalen() async {
    final herstel = _herstel;
    final token = herstel?.token;
    if (herstel == null || token == null || token.isEmpty) return;

    setState(() => _ophalenBezig = true);
    final messenger = ScaffoldMessenger.of(context);
    try {
      final submission = await HerstelSyncService().fetch(
        token,
        inspectionId: widget.inspectionId,
      );
      final updated = herstel.copyWith(
        isHersteld: submission.isHersteld,
        naam: submission.naam,
        datum: submission.datum,
        toelichting: submission.toelichting,
        photo1Path: submission.photo1Path ?? herstel.photo1Path,
        photo2Path: submission.photo2Path ?? herstel.photo2Path,
      );
      await _db.updateHerstel(updated);
      if (!mounted) return;
      _naamController.text = updated.naam;
      _datumController.text = updated.datum;
      _toelichtingController.text = updated.toelichting;
      setState(() {
        _herstel = updated;
        _ophalenBezig = false;
      });
      messenger.showSnackBar(
        const SnackBar(content: Text('Herstelmelding opgehaald')),
      );
    } on HerstelSyncNotFoundException catch (e) {
      if (!mounted) return;
      setState(() => _ophalenBezig = false);
      messenger.showSnackBar(SnackBar(content: Text(e.message)));
    } on HerstelSyncException catch (e) {
      if (!mounted) return;
      setState(() => _ophalenBezig = false);
      messenger.showSnackBar(SnackBar(content: Text(e.message)));
    }
  }

  Future<void> _pickDatum() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: now,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked == null) return;
    final formatted =
        '${picked.day.toString().padLeft(2, '0')}-${picked.month.toString().padLeft(2, '0')}-${picked.year}';
    _datumController.text = formatted;
    _save();
  }

  @override
  void dispose() {
    _save();
    _naamController.dispose();
    _datumController.dispose();
    _toelichtingController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Herstel')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    final herstel = _herstel!;

    return Scaffold(
      appBar: AppBar(title: const Text('Herstel')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (widget.defectLabel.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Text(
                  widget.defectLabel,
                  style: const TextStyle(
                    fontSize: 13,
                    color: Colors.grey,
                  ),
                ),
              ),

            // ── Hersteld status ─────────────────────────────────────────
            const SectionHeader(title: 'Status'),
            Card(
              color: herstel.isHersteld
                  ? Colors.green.shade50
                  : Colors.orange.shade50,
              child: SwitchListTile(
                title: Text(
                  herstel.isHersteld ? 'Gebrek hersteld' : 'Nog niet hersteld',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: herstel.isHersteld
                        ? Colors.green.shade800
                        : Colors.orange.shade800,
                  ),
                ),
                secondary: Icon(
                  herstel.isHersteld
                      ? Icons.check_circle
                      : Icons.pending_outlined,
                  color: herstel.isHersteld
                      ? Colors.green.shade700
                      : Colors.orange.shade700,
                ),
                value: herstel.isHersteld,
                activeThumbColor: Colors.green.shade600,
                onChanged: (v) {
                  setState(() {
                    _herstel = herstel.copyWith(isHersteld: v);
                  });
                  _save();
                },
              ),
            ),

            const SizedBox(height: 8),

            // ── Herstelgegevens ─────────────────────────────────────────
            const SectionHeader(title: 'Herstelgegevens'),
            CustomTextField(
              label: 'Naam uitvoerder',
              controller: _naamController,
              onChanged: (_) => _save(),
            ),
            CustomTextField(
              label: 'Datum herstel',
              controller: _datumController,
              hint: 'dd-mm-jjjj',
              readOnly: true,
              onTap: _pickDatum,
              onChanged: (_) => _save(),
            ),

            const SizedBox(height: 8),

            // ── Foto's ──────────────────────────────────────────────────
            const SectionHeader(title: "Foto's"),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: PhotoContainer(
                    label: "Foto 1",
                    photoPath: herstel.photo1Path,
                    aspectRatio: 4 / 3,
                    onPhotoSelected: (path) {
                      setState(() {
                        _herstel = herstel.copyWith(photo1Path: path);
                      });
                      _save();
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: PhotoContainer(
                    label: "Foto 2",
                    photoPath: herstel.photo2Path,
                    aspectRatio: 4 / 3,
                    onPhotoSelected: (path) {
                      setState(() {
                        _herstel = herstel.copyWith(photo2Path: path);
                      });
                      _save();
                    },
                  ),
                ),
              ],
            ),

            const SizedBox(height: 8),

            // ── Toelichting ─────────────────────────────────────────────
            const SectionHeader(title: 'Toelichting'),
            CustomTextField(
              label: 'Toelichting',
              controller: _toelichtingController,
              onChanged: (_) => _save(),
              maxLines: 5,
            ),

            const SizedBox(height: 24),

            ElevatedButton(
              onPressed: () async {
                final messenger = ScaffoldMessenger.of(context);
                final navigator = Navigator.of(context);
                await _save();
                if (!mounted) return;
                messenger.showSnackBar(
                  const SnackBar(content: Text('Opgeslagen')),
                );
                navigator.pop();
              },
              child: const Text('Opslaan'),
            ),

            const SizedBox(height: 8),

            OutlinedButton.icon(
              onPressed: (herstel.token == null || herstel.token!.isEmpty || _ophalenBezig)
                  ? null
                  : _ophalen,
              icon: _ophalenBezig
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.cloud_download_outlined),
              label: Text(
                herstel.token == null || herstel.token!.isEmpty
                    ? 'Genereer eerst een PDF met QR-code'
                    : 'Ophalen',
              ),
            ),

            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}
