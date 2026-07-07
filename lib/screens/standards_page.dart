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
import '../models/standard.dart';
import '../services/database_service.dart';

class StandardsPage extends StatefulWidget {
  const StandardsPage({super.key});

  @override
  State<StandardsPage> createState() => _StandardsPageState();
}

class _StandardsPageState extends State<StandardsPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  static const _categoryKeys = [
    'system',
    'protection',
    'karakteristiek',
    'protection_class',
    'cable',
    'cable_length',
    'cable_type',
    'main_switch',
    'main_switch_poles',
    'location',
    'location_a',
    'location_b',
    'aarding',
    'inspection_reason',
  ];

  List<String> _categoryLabels(AppLocalizations l10n) => [
    l10n.catSystem,
    l10n.catProtection,
    l10n.catKarakteristiek,
    l10n.catProtectionClass,
    l10n.catCable,
    l10n.catCableLength,
    l10n.catCableType,
    l10n.catMainSwitch,
    l10n.catMainSwitchPoles,
    l10n.catLocation,
    l10n.catLocationA,
    l10n.catLocationB,
    l10n.catAarding,
    l10n.catInspectionReason,
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _categoryKeys.length, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final labels = _categoryLabels(l10n);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.standards),
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabs: labels.map((label) => Tab(text: label)).toList(),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: List.generate(
          _categoryKeys.length,
          (i) => _StandardsList(
            category: _categoryKeys[i],
            label: labels[i],
          ),
        ),
      ),
    );
  }
}

class _StandardsList extends StatefulWidget {
  final String category;
  final String label;

  const _StandardsList({required this.category, required this.label});

  @override
  State<_StandardsList> createState() => _StandardsListState();
}

class _StandardsListState extends State<_StandardsList>
    with AutomaticKeepAliveClientMixin {
  final _db = DatabaseService();
  List<Standard> _standards = [];
  bool _loading = true;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final items = await _db.getStandards(widget.category);
    setState(() {
      _standards = items;
      _loading = false;
    });
  }

  Future<void> _addStandard() async {
    final l10n = AppLocalizations.of(context);
    final valueController = TextEditingController();
    final displayController = TextEditingController();

    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.addCategory(widget.label)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: valueController,
              decoration: InputDecoration(
                labelText: l10n.value,
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: displayController,
              decoration: InputDecoration(
                labelText: l10n.displayName,
                border: const OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l10n.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(l10n.add),
          ),
        ],
      ),
    );

    if (result == true && valueController.text.isNotEmpty) {
      await _db.insertStandard(Standard(
        category: widget.category,
        value: valueController.text,
        displayName: displayController.text.isNotEmpty
            ? displayController.text
            : valueController.text,
      ));
      _loadData();
    }
  }

  Future<void> _editStandard(Standard standard) async {
    final l10n = AppLocalizations.of(context);
    final valueController = TextEditingController(text: standard.value);
    final displayController =
        TextEditingController(text: standard.displayName);

    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.editCategory(widget.label)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: valueController,
              decoration: InputDecoration(
                labelText: l10n.value,
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: displayController,
              decoration: InputDecoration(
                labelText: l10n.displayName,
                border: const OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l10n.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(l10n.save),
          ),
        ],
      ),
    );

    if (result == true && valueController.text.isNotEmpty) {
      await _db.updateStandard(Standard(
        id: standard.id,
        category: standard.category,
        value: valueController.text,
        displayName: displayController.text.isNotEmpty
            ? displayController.text
            : valueController.text,
      ));
      _loadData();
    }
  }

  Future<void> _deleteStandard(Standard standard) async {
    final l10n = AppLocalizations.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.deleteTitle),
        content: Text(l10n.deleteItemConfirm(standard.displayName)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l10n.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(l10n.delete,
                style: const TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await _db.deleteStandard(standard.id!);
      _loadData();
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final l10n = AppLocalizations.of(context);

    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    return Column(
      children: [
        Expanded(
          child: _standards.isEmpty
              ? Center(child: Text(l10n.noItems))
              : ListView.builder(
                  itemCount: _standards.length,
                  itemBuilder: (context, index) {
                    final standard = _standards[index];
                    return ListTile(
                      title: Text(standard.displayName),
                      subtitle: Text(l10n.valuePrefix(standard.value)),
                      onTap: () => _editStandard(standard),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.edit_outlined),
                            onPressed: () => _editStandard(standard),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete_outline,
                                color: Colors.red),
                            onPressed: () => _deleteStandard(standard),
                          ),
                        ],
                      ),
                    );
                  },
                ),
        ),
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: ElevatedButton.icon(
            onPressed: _addStandard,
            icon: const Icon(Icons.add),
            label: Text(l10n.add),
          ),
        ),
      ],
    );
  }
}
