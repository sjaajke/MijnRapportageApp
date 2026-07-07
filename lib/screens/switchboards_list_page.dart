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
import '../models/switchboard.dart';
import '../services/database_service.dart';
import 'home_page.dart';
import 'inspection_menu_page.dart';
import 'switchboard_detail_page.dart';
import 'solar_installations_list_page.dart';
import 'defects_list_page.dart';

class SwitchboardsListPage extends StatefulWidget {
  final int inspectionId;

  const SwitchboardsListPage({super.key, required this.inspectionId});

  @override
  State<SwitchboardsListPage> createState() => _SwitchboardsListPageState();
}

class _SwitchboardsListPageState extends State<SwitchboardsListPage> {
  final _db = DatabaseService();
  List<Switchboard> _switchboards = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _loading = true);
    final items = await _db.getSwitchboards(widget.inspectionId);
    setState(() {
      _switchboards = items;
      _loading = false;
    });
  }

  Future<void> _createSwitchboard() async {
    final id = await _db.insertSwitchboard(
      Switchboard(inspectionId: widget.inspectionId),
    );
    if (!mounted) return;
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => SwitchboardDetailPage(switchboardId: id, inspectionId: widget.inspectionId),
      ),
    );
    _loadData();
  }

  Future<void> _deleteSwitchboard(Switchboard sb) async {
    final l10n = AppLocalizations.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.deleteSwitchboard),
        content: Text(l10n.deleteSwitchboardConfirm),
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
      await _db.deleteSwitchboard(sb.id!);
      _loadData();
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.switchboardsTitle)),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _createSwitchboard,
        icon: const Icon(Icons.add),
        label: Text(l10n.newSwitchboard),
      ),
      body: Column(
        children: [
          _NavBar(inspectionId: widget.inspectionId),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _switchboards.isEmpty
                    ? Center(
                        child: Text(
                          l10n.noSwitchboards,
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: Colors.grey),
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.only(bottom: 80),
                        itemCount: _switchboards.length,
                        itemBuilder: (context, index) {
                          final sb = _switchboards[index];
                          return Card(
                            margin: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 4),
                            child: ListTile(
                              leading: const Icon(Icons.electrical_services,
                                  color: Color(0xFF1976D2)),
                              title: Text(
                                sb.name.isNotEmpty
                                    ? sb.name
                                    : l10n.switchboardNumber(sb.id!),
                              ),
                              subtitle: sb.locationFull.isNotEmpty
                                  ? Text(sb.locationFull)
                                  : null,
                              trailing: IconButton(
                                icon: const Icon(Icons.delete_outline,
                                    color: Colors.red),
                                onPressed: () => _deleteSwitchboard(sb),
                              ),
                              onTap: () async {
                                await Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => SwitchboardDetailPage(
                                        switchboardId: sb.id!,
                                        inspectionId: widget.inspectionId),
                                  ),
                                );
                                _loadData();
                              },
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}

class _NavBar extends StatelessWidget {
  final int inspectionId;
  const _NavBar({required this.inspectionId});

  @override
  Widget build(BuildContext context) {
    return Material(
      elevation: 2,
      child: SizedBox(
        height: 56,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _btn(context, Icons.list_outlined, 'Inspecties',
                () => Navigator.pushAndRemoveUntil(context, MaterialPageRoute(
                      builder: (_) => HomePage()), (route) => false)),
            _btn(context, Icons.home_outlined, 'Inspectie',
                () => Navigator.push(context, MaterialPageRoute(
                      builder: (_) => InspectionMenuPage(inspectionId: inspectionId)))),
            _btn(context, Icons.electrical_services, 'Verdelers',
                () => Navigator.push(context, MaterialPageRoute(
                      builder: (_) => SwitchboardsListPage(inspectionId: inspectionId)))),
            _btn(context, Icons.solar_power, 'Zonnestroom',
                () => Navigator.push(context, MaterialPageRoute(
                      builder: (_) => SolarInstallationsListPage(inspectionId: inspectionId)))),
            _btn(context, Icons.warning_amber, 'Gebreken',
                () => Navigator.push(context, MaterialPageRoute(
                      builder: (_) => DefectsListPage(inspectionId: inspectionId)))),
          ],
        ),
      ),
    );
  }

  Widget _btn(BuildContext context, IconData icon, String label, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 22, color: const Color(0xFF1976D2)),
            Text(label, style: const TextStyle(fontSize: 10, color: Color(0xFF1976D2))),
          ],
        ),
      ),
    );
  }
}
