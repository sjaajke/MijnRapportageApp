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
import '../models/checklist_template.dart';
import '../services/database_service.dart';

class ChecklistTemplateDetailPage extends StatefulWidget {
  final int templateId;

  const ChecklistTemplateDetailPage({super.key, required this.templateId});

  @override
  State<ChecklistTemplateDetailPage> createState() =>
      _ChecklistTemplateDetailPageState();
}

class _ChecklistTemplateDetailPageState
    extends State<ChecklistTemplateDetailPage> {
  final _db = DatabaseService();
  final _nameController = TextEditingController();
  ChecklistTemplate? _template;
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
    final list = await _db.getChecklistTemplates();
    final template = list.where((t) => t.id == widget.templateId).firstOrNull;
    if (!mounted) return;
    setState(() {
      _template = template;
      _nameController.text = template?.name ?? '';
      _loading = false;
    });
  }

  Future<void> _persist(ChecklistTemplate updated) async {
    setState(() => _template = updated);
    await _db.updateChecklistTemplate(updated);
  }

  void _saveName() {
    final t = _template;
    if (t == null) return;
    _persist(t.copyWith(name: _nameController.text));
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

    final t = _template;
    if (t == null) return;
    await _persist(t.copyWith(items: [...t.items, label]));
  }

  Future<void> _editItem(int index) async {
    final t = _template;
    if (t == null) return;
    final controller = TextEditingController(text: t.items[index]);
    final label = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Item bewerken'),
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
              child: const Text('Opslaan')),
        ],
      ),
    );
    controller.dispose();
    if (label == null || label.isEmpty) return;
    final items = List<String>.from(t.items);
    items[index] = label;
    await _persist(t.copyWith(items: items));
  }

  Future<void> _deleteItem(int index) async {
    final t = _template;
    if (t == null) return;
    final items = List<String>.from(t.items)..removeAt(index);
    await _persist(t.copyWith(items: items));
  }

  Future<void> _reorderItems(int oldIndex, int newIndex) async {
    final t = _template;
    if (t == null) return;
    final items = List<String>.from(t.items);
    if (newIndex > oldIndex) newIndex -= 1;
    final item = items.removeAt(oldIndex);
    items.insert(newIndex, item);
    await _persist(t.copyWith(items: items));
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    final t = _template;
    if (t == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Standaard checklijst')),
        body: const Center(child: Text('Checklijst niet gevonden.')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(t.name.isNotEmpty ? t.name : 'Standaard checklijst'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Naam standaard checklijst',
                border: OutlineInputBorder(),
              ),
              textCapitalization: TextCapitalization.sentences,
              onChanged: (_) => _saveName(),
            ),
          ),
          Expanded(
            child: t.items.isEmpty
                ? Center(
                    child: Text(
                      'Nog geen items toegevoegd.',
                      style: TextStyle(color: Colors.grey.shade600),
                    ),
                  )
                : ReorderableListView.builder(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    itemCount: t.items.length,
                    onReorder: _reorderItems,
                    buildDefaultDragHandles: false,
                    itemBuilder: (context, index) {
                      final label = t.items[index];
                      return ListTile(
                        key: ValueKey('$index-$label'),
                        title: Text(label),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.edit_outlined, size: 20),
                              onPressed: () => _editItem(index),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete_outline,
                                  color: Colors.red, size: 20),
                              onPressed: () => _deleteItem(index),
                            ),
                            ReorderableDragStartListener(
                              index: index,
                              child: const Icon(Icons.drag_handle),
                            ),
                          ],
                        ),
                        onTap: () => _editItem(index),
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
