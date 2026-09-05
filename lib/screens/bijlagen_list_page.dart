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
import 'package:pdfx/pdfx.dart' as pdfx;
import '../models/bijlage.dart';
import '../services/database_service.dart';

class BijlagenListPage extends StatefulWidget {
  final int inspectionId;

  const BijlagenListPage({super.key, required this.inspectionId});

  @override
  State<BijlagenListPage> createState() => _BijlagenListPageState();
}

class _BijlagenListPageState extends State<BijlagenListPage> {
  final _db = DatabaseService();
  List<Bijlage> _bijlagen = [];
  final Map<int, int> _pageCounts = {};
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final list = await _db.getBijlagen(widget.inspectionId);
    if (mounted) {
      setState(() {
        _bijlagen = list;
        _loading = false;
      });
    }
    for (final b in list) {
      if (b.id == null || _pageCounts.containsKey(b.id)) continue;
      try {
        final doc = await pdfx.PdfDocument.openFile(b.bestandPad);
        final count = doc.pagesCount;
        await doc.close();
        if (mounted) setState(() => _pageCounts[b.id!] = count);
      } catch (_) {}
    }
  }

  Future<void> _pickAndAdd() async {
    const typeGroup = XTypeGroup(
      label: 'PDF',
      extensions: ['pdf'],
      uniformTypeIdentifiers: ['com.adobe.pdf'],
    );
    final file = await openFile(acceptedTypeGroups: [typeGroup]);
    if (file == null) return;

    final docs = await getApplicationDocumentsDirectory();
    final destDir = Directory(p.join(docs.path, 'bijlagen'));
    await destDir.create(recursive: true);
    final dest =
        p.join(destDir.path, '${DateTime.now().millisecondsSinceEpoch}.pdf');
    await File(file.path).copy(dest);

    final naam = p.basenameWithoutExtension(file.name);

    await _db.insertBijlage(Bijlage(
      inspectionId: widget.inspectionId,
      naam: naam,
      bestandPad: dest,
    ));

    await _load();
  }

  Future<void> _deleteBijlage(Bijlage bijlage) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Bijlage verwijderen'),
        content: Text('Weet u zeker dat u "${bijlage.naam}" wilt verwijderen?'),
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
    if (confirmed == true && bijlage.id != null) {
      await _db.deleteBijlage(bijlage.id!);
      final file = File(bijlage.bestandPad);
      if (await file.exists()) await file.delete();
      await _load();
    }
  }

  Future<void> _renameBijlage(Bijlage bijlage) async {
    final controller = TextEditingController(text: bijlage.naam);
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
    if (result != null && result.isNotEmpty && bijlage.id != null) {
      await _db.updateBijlage(bijlage.copyWith(naam: result));
      await _load();
    }
  }

  void _openBijlage(Bijlage bijlage) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => _BijlagePreviewPage(bijlage: bijlage),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Bijlagen'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            tooltip: 'Bijlage toevoegen',
            onPressed: _pickAndAdd,
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _bijlagen.isEmpty
              ? _buildEmpty()
              : _buildList(),
      floatingActionButton: _bijlagen.isNotEmpty
          ? FloatingActionButton(
              onPressed: _pickAndAdd,
              tooltip: 'Bijlage toevoegen',
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
            Icon(Icons.attach_file, size: 64, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            Text(
              'Nog geen bijlagen toegevoegd.',
              style: TextStyle(color: Colors.grey.shade600, fontSize: 16),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Voeg PDF-documenten toe, zoals certificaten of meetrapporten.\n'
              'Ze worden als bijlage achteraan het rapport toegevoegd.',
              style: TextStyle(color: Colors.grey.shade500, fontSize: 13),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _pickAndAdd,
              icon: const Icon(Icons.add),
              label: const Text('Bijlage toevoegen'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildList() {
    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: _bijlagen.length,
      itemBuilder: (_, index) {
        final bijlage = _bijlagen[index];
        final pageCount = bijlage.id != null ? _pageCounts[bijlage.id!] : null;
        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: ListTile(
            leading: const Icon(Icons.picture_as_pdf,
                color: Color(0xFF1976D2), size: 32),
            title: Text(
              bijlage.naam.isNotEmpty ? bijlage.naam : '(naamloos)',
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
            subtitle: Text(
              pageCount == null
                  ? 'PDF'
                  : pageCount == 1
                      ? 'PDF · 1 pagina'
                      : 'PDF · $pageCount pagina\'s',
              style: const TextStyle(fontSize: 12),
            ),
            trailing: PopupMenuButton<String>(
              onSelected: (value) {
                if (value == 'rename') _renameBijlage(bijlage);
                if (value == 'delete') _deleteBijlage(bijlage);
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
            onTap: () => _openBijlage(bijlage),
          ),
        );
      },
    );
  }
}

class _BijlagePreviewPage extends StatefulWidget {
  final Bijlage bijlage;

  const _BijlagePreviewPage({required this.bijlage});

  @override
  State<_BijlagePreviewPage> createState() => _BijlagePreviewPageState();
}

class _BijlagePreviewPageState extends State<_BijlagePreviewPage> {
  pdfx.PdfControllerPinch? _controller;
  String? _error;

  @override
  void initState() {
    super.initState();
    _controller = pdfx.PdfControllerPinch(
      document: pdfx.PdfDocument.openFile(widget.bijlage.bestandPad)
          .catchError((e) {
        setState(() => _error = 'Kan PDF niet openen: $e');
        throw e;
      }),
    );
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.bijlage.naam)),
      body: _error != null
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(_error!, textAlign: TextAlign.center),
              ),
            )
          : pdfx.PdfViewPinch(controller: _controller!),
    );
  }
}
