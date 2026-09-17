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
import '../models/checklist.dart';
import '../services/database_service.dart';
import 'checklist_detail_page.dart';

class ChecklistsListPage extends StatefulWidget {
  final int inspectionId;

  const ChecklistsListPage({super.key, required this.inspectionId});

  @override
  State<ChecklistsListPage> createState() => _ChecklistsListPageState();
}

class _ChecklistsListPageState extends State<ChecklistsListPage> {
  final _db = DatabaseService();
  List<Checklist> _checklists = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final list = await _db.getChecklists(widget.inspectionId);
    if (mounted) {
      setState(() {
        _checklists = list;
        _loading = false;
      });
    }
  }

  Future<void> _createChecklist() async {
    final controller = TextEditingController();
    final name = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Nieuwe checklijst'),
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
              child: const Text('Aanmaken')),
        ],
      ),
    );
    controller.dispose();
    if (name == null || name.isEmpty) return;

    final id = await _db.insertChecklist(Checklist(
      inspectionId: widget.inspectionId,
      name: name,
      sortOrder: _checklists.length,
    ));
    await _load();
    if (!mounted) return;
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ChecklistDetailPage(
          inspectionId: widget.inspectionId,
          checklistId: id,
        ),
      ),
    );
    _load();
  }

  Future<void> _deleteChecklist(Checklist checklist) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Checklijst verwijderen'),
        content:
            Text('Weet u zeker dat u "${checklist.name}" wilt verwijderen?'),
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
    if (confirmed == true && checklist.id != null) {
      await _db.deleteChecklist(checklist.id!);
      await _load();
    }
  }

  Future<void> _reorderChecklists(int oldIndex, int newIndex) async {
    setState(() {
      if (newIndex > oldIndex) newIndex -= 1;
      final checklist = _checklists.removeAt(oldIndex);
      _checklists.insert(newIndex, checklist);
    });
    await _db.updateChecklistOrder(
      _checklists.map((c) => c.id!).toList(),
    );
  }

  Future<void> _openChecklist(Checklist checklist) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ChecklistDetailPage(
          inspectionId: widget.inspectionId,
          checklistId: checklist.id!,
        ),
      ),
    );
    _load();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Checklijsten'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            tooltip: 'Checklijst toevoegen',
            onPressed: _createChecklist,
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _checklists.isEmpty
              ? _buildEmpty()
              : _buildList(),
      floatingActionButton: _checklists.isNotEmpty
          ? FloatingActionButton(
              onPressed: _createChecklist,
              tooltip: 'Checklijst toevoegen',
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
            Icon(Icons.checklist, size: 64, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            Text(
              'Nog geen checklijsten aangemaakt.',
              style: TextStyle(color: Colors.grey.shade600, fontSize: 16),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Maak eigen checklijsten met vrij in te vullen items,\n'
              'te beantwoorden met Ja, Nee of N.v.t.',
              style: TextStyle(color: Colors.grey.shade500, fontSize: 13),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _createChecklist,
              icon: const Icon(Icons.add),
              label: const Text('Checklijst toevoegen'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildList() {
    return ReorderableListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: _checklists.length,
      onReorder: _reorderChecklists,
      buildDefaultDragHandles: false,
      itemBuilder: (context, index) {
        final checklist = _checklists[index];
        final total = checklist.items.length;
        final answered =
            checklist.items.where((i) => i.value != 'N.v.t.').length;
        return Card(
          key: ValueKey(checklist.id),
          margin: const EdgeInsets.only(bottom: 8),
          child: ListTile(
            leading: const Icon(Icons.checklist,
                color: Color(0xFF1976D2), size: 32),
            title: Text(
              checklist.name.isNotEmpty ? checklist.name : '(naamloos)',
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
            subtitle: Text(
              total == 0 ? 'Geen items' : '$answered/$total ingevuld',
              style: const TextStyle(fontSize: 12),
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.delete_outline, color: Colors.red),
                  onPressed: () => _deleteChecklist(checklist),
                ),
                const Icon(Icons.chevron_right),
                const SizedBox(width: 4),
                ReorderableDragStartListener(
                  index: index,
                  child: const Icon(Icons.drag_handle),
                ),
              ],
            ),
            onTap: () => _openChecklist(checklist),
          ),
        );
      },
    );
  }
}
