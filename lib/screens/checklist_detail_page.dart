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

/// Standalone page wrapper around [ChecklistDetailView], used when the
/// checklists list is shown full-screen (narrow layouts).
class ChecklistDetailPage extends StatelessWidget {
  final int inspectionId;
  final int checklistId;

  const ChecklistDetailPage({
    super.key,
    required this.inspectionId,
    required this.checklistId,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Checklijst')),
      body: ChecklistDetailView(
        key: ValueKey(checklistId),
        inspectionId: inspectionId,
        checklistId: checklistId,
      ),
    );
  }
}

/// The editable checklist form, extracted so it can be embedded either as a
/// full [ChecklistDetailPage] or inline in a master-detail split view.
class ChecklistDetailView extends StatefulWidget {
  final int inspectionId;
  final int checklistId;

  /// Called whenever the checklist is persisted, so an embedding list can
  /// refresh its summary (name/item count) live.
  final ValueChanged<Checklist>? onChecklistUpdated;

  /// Called if the checklist no longer exists (e.g. deleted elsewhere),
  /// instead of showing a "not found" message.
  final VoidCallback? onNotFound;

  const ChecklistDetailView({
    super.key,
    required this.inspectionId,
    required this.checklistId,
    this.onChecklistUpdated,
    this.onNotFound,
  });

  @override
  State<ChecklistDetailView> createState() => _ChecklistDetailViewState();
}

class _ChecklistDetailViewState extends State<ChecklistDetailView> {
  static const _headerStyle = TextStyle(
    fontSize: 11,
    fontWeight: FontWeight.w600,
    color: Colors.grey,
  );

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
    if (checklist == null) {
      setState(() => _loading = false);
      widget.onNotFound?.call();
      return;
    }
    setState(() {
      _checklist = checklist;
      _nameController.text = checklist.name;
      _loading = false;
    });
  }

  Future<void> _persist(Checklist updated) async {
    setState(() => _checklist = updated);
    await _db.updateChecklist(updated);
    widget.onChecklistUpdated?.call(updated);
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
      return const Center(child: CircularProgressIndicator());
    }
    final c = _checklist;
    if (c == null) {
      return const Center(child: Text('Checklijst niet gevonden.'));
    }

    return Column(
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
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 8, 4),
          child: Row(
            children: [
              const Text('Items', style: TextStyle(fontWeight: FontWeight.w600)),
              const Spacer(),
              TextButton.icon(
                onPressed: _addItem,
                icon: const Icon(Icons.add, size: 18),
                label: const Text('Item toevoegen'),
              ),
            ],
          ),
        ),
        if (c.items.isNotEmpty)
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 4),
            child: Row(
              children: [
                const Expanded(flex: 3, child: SizedBox()),
                Expanded(child: Center(child: Text('Ja', style: _headerStyle))),
                Expanded(child: Center(child: Text('Nee', style: _headerStyle))),
                Expanded(
                    child: Center(child: Text('N.v.t.', style: _headerStyle))),
                const SizedBox(width: 48),
                const SizedBox(width: 24),
              ],
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
                              showOptionLabels: false,
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
    );
  }
}
