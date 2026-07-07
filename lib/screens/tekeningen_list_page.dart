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
import 'package:file_selector/file_selector.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import '../models/tekening.dart';
import '../services/database_service.dart';
import 'tekening_detail_page.dart';

class TekeningenListPage extends StatefulWidget {
  final int inspectionId;

  const TekeningenListPage({super.key, required this.inspectionId});

  @override
  State<TekeningenListPage> createState() => _TekeningenListPageState();
}

class _TekeningenListPageState extends State<TekeningenListPage> {
  final _db = DatabaseService();
  List<Tekening> _tekeningen = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final list = await _db.getTekeningen(widget.inspectionId);
    if (mounted) {
      setState(() {
        _tekeningen = list;
        _loading = false;
      });
    }
  }

  Future<void> _pickAndAdd() async {
    const typeGroup = XTypeGroup(
      label: 'Tekeningen',
      extensions: ['jpg', 'jpeg', 'png', 'pdf'],
    );
    final file = await openFile(acceptedTypeGroups: [typeGroup]);
    if (file == null) return;

    final ext = p.extension(file.path).toLowerCase().replaceAll('.', '');
    final bestandType = ext == 'pdf' ? 'pdf' : 'jpeg';

    final docs = await getApplicationDocumentsDirectory();
    final destDir = Directory(p.join(docs.path, 'tekeningen'));
    await destDir.create(recursive: true);
    final dest = p.join(
        destDir.path, '${DateTime.now().millisecondsSinceEpoch}.$ext');
    await File(file.path).copy(dest);

    final naam = p.basenameWithoutExtension(file.name);

    final id = await _db.insertTekening(Tekening(
      inspectionId: widget.inspectionId,
      naam: naam,
      bestandPad: dest,
      bestandType: bestandType,
    ));

    await _load();

    if (mounted) {
      final created = _tekeningen.firstWhere(
        (t) => t.id == id,
        orElse: () => Tekening(
            inspectionId: widget.inspectionId,
            naam: naam,
            bestandPad: dest,
            bestandType: bestandType),
      );
      _openTekening(created);
    }
  }

  void _openTekening(Tekening tekening) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => TekeningDetailPage(tekening: tekening),
      ),
    ).then((_) => _load());
  }

  Future<void> _deleteTekening(Tekening tekening) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Tekening verwijderen'),
        content: Text(
            'Weet u zeker dat u "${tekening.naam}" wilt verwijderen?\nAlle bijbehorende pins worden ook verwijderd.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Annuleren')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Verwijderen',
                style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (confirmed == true && tekening.id != null) {
      await _db.deleteTekening(tekening.id!);
      final file = File(tekening.bestandPad);
      if (await file.exists()) await file.delete();
      await _load();
    }
  }

  Future<void> _renameTekening(Tekening tekening) async {
    final controller = TextEditingController(text: tekening.naam);
    final result = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Naam wijzigen'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(
              labelText: 'Naam', border: OutlineInputBorder()),
          textCapitalization: TextCapitalization.sentences,
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Annuleren')),
          TextButton(
              onPressed: () => Navigator.pop(ctx, controller.text.trim()),
              child: const Text('Opslaan')),
        ],
      ),
    );
    controller.dispose();
    if (result != null && result.isNotEmpty && tekening.id != null) {
      await _db.updateTekening(tekening.copyWith(naam: result));
      await _load();
    }
  }

  IconData _typeIcon(String bestandType) {
    if (bestandType == 'pdf') return Icons.picture_as_pdf;
    return Icons.image_outlined;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tekening inspectie'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            tooltip: 'Tekening toevoegen',
            onPressed: _pickAndAdd,
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _tekeningen.isEmpty
              ? _buildEmpty()
              : _buildList(),
      floatingActionButton: _tekeningen.isNotEmpty
          ? FloatingActionButton(
              onPressed: _pickAndAdd,
              tooltip: 'Tekening toevoegen',
              child: const Icon(Icons.add),
            )
          : null,
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.map_outlined, size: 64, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            Text(
              'Nog geen tekeningen toegevoegd.',
              style: TextStyle(color: Colors.grey.shade600, fontSize: 16),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Ondersteunde formaten: JPEG, PNG, PDF.\n'
              'AutoCad tekeningen: exporteer eerst naar PDF vanuit AutoCAD.',
              style: TextStyle(color: Colors.grey.shade500, fontSize: 13),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _pickAndAdd,
              icon: const Icon(Icons.add),
              label: const Text('Tekening toevoegen'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildList() {
    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: _tekeningen.length,
      itemBuilder: (_, index) {
        final tekening = _tekeningen[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: ListTile(
            leading: Icon(
              _typeIcon(tekening.bestandType),
              color: const Color(0xFF1976D2),
              size: 32,
            ),
            title: Text(
              tekening.naam.isNotEmpty ? tekening.naam : '(naamloos)',
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
            subtitle: Text(
              tekening.bestandType.toUpperCase(),
              style: const TextStyle(fontSize: 12),
            ),
            trailing: PopupMenuButton<String>(
              onSelected: (value) {
                if (value == 'rename') _renameTekening(tekening);
                if (value == 'delete') _deleteTekening(tekening);
              },
              itemBuilder: (_) => [
                const PopupMenuItem(
                  value: 'rename',
                  child: ListTile(
                    leading: Icon(Icons.edit),
                    title: Text('Naam wijzigen'),
                    dense: true,
                  ),
                ),
                const PopupMenuItem(
                  value: 'delete',
                  child: ListTile(
                    leading: Icon(Icons.delete, color: Colors.red),
                    title: Text('Verwijderen',
                        style: TextStyle(color: Colors.red)),
                    dense: true,
                  ),
                ),
              ],
            ),
            onTap: () => _openTekening(tekening),
          ),
        );
      },
    );
  }
}
