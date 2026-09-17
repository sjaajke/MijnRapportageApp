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
import '../models/checklist_item_entry.dart';
import '../services/database_service.dart';
import '../widgets/checklist_item.dart';

class ChecklistDetailPage extends StatefulWidget {
  final int inspectionId;
  final int checklistId;

  const ChecklistDetailPage({
    super.key,
    required this.inspectionId,
    required this.checklistId,
  });

  @override
  State<ChecklistDetailPage> createState() => _ChecklistDetailPageState();
}

class _ChecklistDetailPageState extends State<ChecklistDetailPage> {
  final _db = DatabaseService();
  final _nameController = TextEditingController();
  Checklist? _checklist;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final list = await _db.getChecklists(widget.inspectionId);
    final checklist = list.where((c) => c.id == widget.checklistId).firstOrNull;
    if (!mounted) return;
    setState(() {
      _checklist = checklist;
      _nameController.text = checklist?.name ?? '';
      _loading = false;
    });
  }

  Future<void> _persist(Checklist updated) async {
    setState(() => _checklist = updated);
    await _db.updateChecklist(updated);
  }

  void _saveName() {
    final c = _checklist;
    if (c == null) return;
    _persist(c.copyWith(name: _nameController.text));
  }

  Future<void> _addItem() async {
    final controller = TextEditingController();
    final label = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Item toevoegen'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(
              labelText: 'Omschrijving', border: OutlineInputBorder()),
          textCapitalization: TextCapitalization.sentences,
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Annuleren')),
          TextButton(
              onPressed: () => Navigator.pop(ctx, controller.text.trim()),
              child: const Text('Toevoegen')),
        ],
      ),
    );
    controller.dispose();
    if (label == null || label.isEmpty) return;

    final c = _checklist;
    if (c == null) return;
    final nextId =
        (c.items.isEmpty ? 0 : c.items.map((e) => e.id).reduce((a, b) => a > b ? a : b)) + 1;
    await _persist(c.copyWith(
      items: [...c.items, ChecklistItemEntry(id: nextId, label: label)],
    ));
  }

  Future<void> _setItemValue(ChecklistItemEntry item, String value) async {
    final c = _checklist;
    if (c == null) return;
    final items = c.items
        .map((e) => e.id == item.id ? e.copyWith(value: value) : e)
        .toList();
    await _persist(c.copyWith(items: items));
  }

  Future<void> _deleteItem(ChecklistItemEntry item) async {
    final c = _checklist;
    if (c == null) return;
    final items = c.items.where((e) => e.id != item.id).toList();
    await _persist(c.copyWith(items: items));
  }

  Future<void> _reorderItems(int oldIndex, int newIndex) async {
    final c = _checklist;
    if (c == null) return;
    final items = List<ChecklistItemEntry>.from(c.items);
    if (newIndex > oldIndex) newIndex -= 1;
    final item = items.removeAt(oldIndex);
    items.insert(newIndex, item);
    await _persist(c.copyWith(items: items));
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    final c = _checklist;
    if (c == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Checklijst')),
        body: const Center(child: Text('Checklijst niet gevonden.')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(c.name.isNotEmpty ? c.name : 'Checklijst'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Naam checklijst',
                border: OutlineInputBorder(),
              ),
              textCapitalization: TextCapitalization.sentences,
              onChanged: (_) => _saveName(),
            ),
          ),
          Expanded(
            child: c.items.isEmpty
                ? Center(
                    child: Text(
                      'Nog geen items toegevoegd.',
                      style: TextStyle(color: Colors.grey.shade600),
                    ),
                  )
                : ReorderableListView.builder(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 4),
                    itemCount: c.items.length,
                    onReorder: _reorderItems,
                    buildDefaultDragHandles: false,
                    itemBuilder: (context, index) {
                      final item = c.items[index];
                      return Padding(
                        key: ValueKey(item.id),
                        padding: const EdgeInsets.symmetric(vertical: 2),
                        child: Row(
                          children: [
                            Expanded(
                              child: ChecklistItem(
                                label: item.label,
                                value: item.value,
                                onChanged: (v) => _setItemValue(item, v),
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete_outline,
                                  color: Colors.red, size: 20),
                              onPressed: () => _deleteItem(item),
                            ),
                            ReorderableDragStartListener(
                              index: index,
                              child: const Icon(Icons.drag_handle),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _addItem,
        icon: const Icon(Icons.add),
        label: const Text('Item toevoegen'),
      ),
    );
  }
}
