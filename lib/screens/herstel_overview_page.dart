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
import '../models/defect.dart';
import '../models/herstel.dart';
import '../services/database_service.dart';
import '../services/herstel_sync_service.dart';
import '../widgets/custom_text_field.dart';
import '../widgets/photo_container.dart';
import '../widgets/section_header.dart';

class HerstelOverviewPage extends StatefulWidget {
  final int inspectionId;

  const HerstelOverviewPage({super.key, required this.inspectionId});

  @override
  State<HerstelOverviewPage> createState() => _HerstelOverviewPageState();
}

class _HerstelOverviewPageState extends State<HerstelOverviewPage> {
  final _db = DatabaseService();
  List<Defect> _defects = [];
  Map<int, Herstel> _herstelen = {};
  int? _selectedDefectId;
  bool _loading = true;
  bool _syncing = false;
  bool _pushing = false;
  int _refreshToken = 0;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _loading = true);
    final defects = await _db.getDefects(widget.inspectionId);
    final herstelen = <int, Herstel>{};
    for (final d in defects) {
      if (d.id != null) {
        final herstel = await _db.getHerstel(d.id!);
        if (herstel != null) herstelen[d.id!] = herstel;
      }
    }
    setState(() {
      _defects = defects;
      _herstelen = herstelen;
      if (_selectedDefectId == null ||
          !defects.any((d) => d.id == _selectedDefectId)) {
        _selectedDefectId = defects.isNotEmpty ? defects.first.id : null;
      }
      _loading = false;
    });
  }

  Future<void> _syncAll() async {
    final withToken = _herstelen.entries
        .where((e) => (e.value.token ?? '').isNotEmpty)
        .toList();
    final messenger = ScaffoldMessenger.of(context);
    if (withToken.isEmpty) {
      messenger.showSnackBar(
        const SnackBar(
          content: Text('Geen gebreken met een herstel-QR gevonden'),
        ),
      );
      return;
    }

    setState(() => _syncing = true);
    var updated = 0;
    var notFound = 0;
    var failed = 0;

    for (final entry in withToken) {
      final defectId = entry.key;
      final herstel = entry.value;
      try {
        final submission = await HerstelSyncService().fetch(
          herstel.token!,
          inspectionId: widget.inspectionId,
        );
        final result = herstel.copyWith(
          isHersteld: submission.isHersteld,
          naam: submission.naam,
          datum: submission.datum,
          toelichting: submission.toelichting,
          photo1Path: submission.photo1Path ?? herstel.photo1Path,
          photo2Path: submission.photo2Path ?? herstel.photo2Path,
        );
        await _db.updateHerstel(result);
        _herstelen[defectId] = result;
        updated++;
      } on HerstelSyncNotFoundException {
        notFound++;
      } on HerstelSyncException {
        failed++;
      }
    }

    if (!mounted) return;
    setState(() {
      _syncing = false;
      _refreshToken++;
    });
    messenger.showSnackBar(
      SnackBar(
        content: Text(
          '$updated bijgewerkt'
          '${notFound > 0 ? ', $notFound nog geen inzending' : ''}'
          '${failed > 0 ? ', $failed mislukt' : ''}',
        ),
      ),
    );
  }

  /// Stuurt alle lokaal als "hersteld" gemarkeerde gebreken in één keer naar
  /// Firestore. Bestaat er al een externe inzending voor een gebrek (via het
  /// QR-webformulier), dan blijft die leidend en wordt de lokale versie
  /// overgeslagen — zie [HerstelPushOutcome.alreadySubmitted].
  Future<void> _pushAll() async {
    final repaired = _herstelen.entries
        .where((e) => e.value.isHersteld)
        .toList();
    final messenger = ScaffoldMessenger.of(context);
    if (repaired.isEmpty) {
      messenger.showSnackBar(
        const SnackBar(
          content: Text('Geen herstelde gebreken om te versturen.'),
        ),
      );
      return;
    }

    setState(() => _pushing = true);
    var pushed = 0;
    var alreadySubmitted = 0;
    final failures = <String>[];
    final sync = HerstelSyncService();

    for (final entry in repaired) {
      final defectId = entry.key;
      var herstel = entry.value;
      final token = (herstel.token ?? '').isEmpty
          ? await _db.ensureHerstelToken(defectId)
          : herstel.token!;
      if (herstel.token != token) {
        herstel = herstel.copyWith(token: token);
        _herstelen[defectId] = herstel;
      }
      final result = await sync.push(token, herstel);
      switch (result.outcome) {
        case HerstelPushOutcome.pushed:
          pushed++;
          break;
        case HerstelPushOutcome.alreadySubmitted:
          alreadySubmitted++;
          break;
        case HerstelPushOutcome.failed:
          final defect = _defects.where((d) => d.id == defectId).firstOrNull;
          final label = defect != null && defect.locationFull.isNotEmpty
              ? defect.locationFull
              : 'Gebrek #$defectId';
          failures.add('$label: ${result.error ?? 'onbekende fout'}');
          break;
      }
    }

    if (!mounted) return;
    setState(() => _pushing = false);
    messenger.showSnackBar(
      SnackBar(
        content: Text(
          '$pushed verstuurd, $alreadySubmitted al ingezonden overgeslagen'
          '${failures.isNotEmpty ? ', ${failures.length} mislukt' : ''}.',
        ),
      ),
    );

    if (failures.isNotEmpty) {
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Mislukte uploads'),
          content: SingleChildScrollView(
            child: Text(failures.join('\n\n')),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Sluiten'),
            ),
          ],
        ),
      );
    }
  }

  Color _classificationColor(String classification) {
    switch (classification) {
      case 'Rd':
        return Colors.red;
      case 'Or':
        return Colors.orange;
      case 'Ge':
        return Colors.yellow.shade700;
      case 'Bl':
        return Colors.blue;
      case 'Pa':
        return Colors.purple;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final selectedDefect = _defects
        .where((d) => d.id == _selectedDefectId)
        .cast<Defect?>()
        .firstOrNull;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Herstel'),
        actions: [
          if (_herstelen.values.any((h) => h.isHersteld))
            IconButton(
              icon: _pushing
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.cloud_upload_outlined),
              tooltip: 'Herstelde gebreken naar Firebase sturen',
              onPressed: _pushing ? null : _pushAll,
            ),
          if (_defects.isNotEmpty)
            IconButton(
              icon: _syncing
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.cloud_sync_outlined),
              tooltip: 'Alle herstelmeldingen ophalen',
              onPressed: _syncing ? null : _syncAll,
            ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _defects.isEmpty
          ? const Center(
              child: Text(
                'Geen gebreken voor deze inspectie',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey),
              ),
            )
          : Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SizedBox(
                  width: 320,
                  child: ListView.builder(
                    itemCount: _defects.length,
                    itemBuilder: (context, index) {
                      final defect = _defects[index];
                      final herstel = _herstelen[defect.id];
                      final isSelected = defect.id == _selectedDefectId;
                      return Container(
                        color: isSelected
                            ? Theme.of(context)
                                  .colorScheme
                                  .primaryContainer
                                  .withValues(alpha: 0.4)
                            : null,
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: _classificationColor(
                              defect.classification,
                            ),
                            radius: 16,
                            child: Text(
                              defect.classification,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          title: Text(
                            defect.locationFull.isNotEmpty
                                ? defect.locationFull
                                : 'Gebrek #${defect.id}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          subtitle: Text(
                            herstel != null && herstel.isHersteld
                                ? 'Hersteld'
                                : 'Nog niet hersteld',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: herstel != null && herstel.isHersteld
                                  ? Colors.green.shade700
                                  : Colors.orange.shade700,
                            ),
                          ),
                          selected: isSelected,
                          onTap: () =>
                              setState(() => _selectedDefectId = defect.id),
                        ),
                      );
                    },
                  ),
                ),
                const VerticalDivider(width: 1),
                Expanded(
                  child: selectedDefect == null
                      ? const Center(
                          child: Text(
                            'Selecteer een gebrek',
                            style: TextStyle(color: Colors.grey),
                          ),
                        )
                      : _DetailPanel(
                          key: ValueKey('${selectedDefect.id}_$_refreshToken'),
                          defect: selectedDefect,
                          onHerstelSaved: (herstel) => setState(() {
                            _herstelen[selectedDefect.id!] = herstel;
                          }),
                        ),
                ),
              ],
            ),
    );
  }
}

extension _FirstOrNull<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}

class _DetailPanel extends StatefulWidget {
  final Defect defect;
  final ValueChanged<Herstel> onHerstelSaved;

  const _DetailPanel({
    super.key,
    required this.defect,
    required this.onHerstelSaved,
  });

  @override
  State<_DetailPanel> createState() => _DetailPanelState();
}

class _DetailPanelState extends State<_DetailPanel> {
  final _db = DatabaseService();
  final _naamController = TextEditingController();
  final _datumController = TextEditingController();
  final _toelichtingController = TextEditingController();

  Herstel? _herstel;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    var herstel = await _db.getHerstel(widget.defect.id!);
    if (herstel == null) {
      final id = await _db.insertHerstel(Herstel(defectId: widget.defect.id!));
      herstel = await _db.getHerstel(widget.defect.id!);
      herstel ??= Herstel(id: id, defectId: widget.defect.id!);
    }
    if (!mounted) return;
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
    widget.onHerstelSaved(updated);
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
      return const Center(child: CircularProgressIndicator());
    }

    final defect = widget.defect;
    final herstel = _herstel!;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Gebrek ──────────────────────────────────────────────────
          const SectionHeader(title: 'Gebrek'),
          Text(
            defect.locationFull.isNotEmpty
                ? defect.locationFull
                : 'Gebrek #${defect.id}',
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
          if (defect.installationComponent.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Text(
                defect.installationComponent,
                style: TextStyle(color: Colors.grey.shade700, fontSize: 13),
              ),
            ),
          if (defect.description.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(defect.description),
            ),
          if (defect.toelichting.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              defect.toelichting,
              style: TextStyle(color: Colors.grey.shade700, fontSize: 13),
            ),
          ],
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: _ReadOnlyPhoto(
                  label: 'Foto 1',
                  photoPath: defect.photo1Path,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _ReadOnlyPhoto(
                  label: 'Foto 2',
                  photoPath: defect.photo2Path,
                ),
              ),
            ],
          ),

          const Divider(height: 32),

          // ── Herstel ─────────────────────────────────────────────────
          const SectionHeader(title: 'Herstel'),
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
                setState(() => _herstel = herstel.copyWith(isHersteld: v));
                _save();
              },
            ),
          ),
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
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: PhotoContainer(
                  label: 'Foto 1',
                  photoPath: herstel.photo1Path,
                  aspectRatio: 4 / 3,
                  onPhotoSelected: (path) {
                    setState(() => _herstel = herstel.copyWith(photo1Path: path));
                    _save();
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: PhotoContainer(
                  label: 'Foto 2',
                  photoPath: herstel.photo2Path,
                  aspectRatio: 4 / 3,
                  onPhotoSelected: (path) {
                    setState(() => _herstel = herstel.copyWith(photo2Path: path));
                    _save();
                  },
                ),
              ),
            ],
          ),
          CustomTextField(
            label: 'Toelichting',
            controller: _toelichtingController,
            onChanged: (_) => _save(),
            maxLines: 4,
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}

class _ReadOnlyPhoto extends StatelessWidget {
  final String label;
  final String? photoPath;

  const _ReadOnlyPhoto({required this.label, required this.photoPath});

  @override
  Widget build(BuildContext context) {
    final hasPhoto = photoPath != null && File(photoPath!).existsSync();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
        const SizedBox(height: 4),
        AspectRatio(
          aspectRatio: 4 / 3,
          child: Container(
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade400),
              borderRadius: BorderRadius.circular(8),
              color: Colors.grey.shade100,
            ),
            child: hasPhoto
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.file(File(photoPath!), fit: BoxFit.cover),
                  )
                : Center(
                    child: Icon(
                      Icons.photo_outlined,
                      color: Colors.grey.shade500,
                    ),
                  ),
          ),
        ),
      ],
    );
  }
}
