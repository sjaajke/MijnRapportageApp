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
import '../models/solar_installation.dart';
import '../models/solar_inverter.dart';
import '../services/database_service.dart';
import 'home_page.dart';
import 'inspection_menu_page.dart';
import 'switchboards_list_page.dart';
import 'solar_installation_detail_page.dart';
import 'solar_inverter_detail_page.dart';
import 'defects_list_page.dart';

class SolarInstallationsListPage extends StatefulWidget {
  final int inspectionId;

  const SolarInstallationsListPage({super.key, required this.inspectionId});

  @override
  State<SolarInstallationsListPage> createState() =>
      _SolarInstallationsListPageState();
}

class _SolarInstallationsListPageState
    extends State<SolarInstallationsListPage> {
  final _db = DatabaseService();
  List<SolarInstallation> _installations = [];
  Map<int, List<SolarInverter>> _invertersByInstallation = {};
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _loading = true);
    final items = await _db.getSolarInstallations(widget.inspectionId);
    final invertersMap = <int, List<SolarInverter>>{};
    for (final inst in items) {
      invertersMap[inst.id!] =
          await _db.getSolarInverters(inst.id!);
    }
    setState(() {
      _installations = items;
      _invertersByInstallation = invertersMap;
      _loading = false;
    });
  }

  Future<void> _create() async {
    final id = await _db.insertSolarInstallation(
      SolarInstallation(inspectionId: widget.inspectionId),
    );
    if (!mounted) return;
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => SolarInstallationDetailPage(
            installationId: id, inspectionId: widget.inspectionId),
      ),
    );
    _loadData();
  }

  Future<void> _delete(SolarInstallation item) async {
    final l10n = AppLocalizations.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.deleteInstallation),
        content: Text(l10n.deleteInstallationConfirm),
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
      await _db.deleteSolarInstallation(item.id!);
      _loadData();
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.solarTitle)),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _create,
        icon: const Icon(Icons.add),
        label: Text(l10n.newInstallation),
      ),
      body: Column(
        children: [
          _NavBar(inspectionId: widget.inspectionId),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _installations.isEmpty
                    ? Center(
                        child: Text(
                          l10n.noInstallations,
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: Colors.grey),
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.only(bottom: 80),
                        itemCount: _installations.length,
                        itemBuilder: (context, index) {
                          final item = _installations[index];
                          final inverters =
                              _invertersByInstallation[item.id!] ?? [];
                          return Card(
                            margin: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 4),
                            child: ExpansionTile(
                              key: PageStorageKey(item.id),
                              leading: const Icon(Icons.solar_power,
                                  color: Color(0xFF1976D2)),
                              title: Text(
                                item.location.isNotEmpty
                                    ? item.location
                                    : l10n.installationNumber(item.id!),
                              ),
                              subtitle: item.panelCount != null
                                  ? Text(l10n.panelCount(item.panelCount!))
                                  : null,
                              children: [
                                // Action row
                                Padding(
                                  padding:
                                      const EdgeInsets.fromLTRB(16, 0, 16, 4),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.end,
                                    children: [
                                      TextButton.icon(
                                        icon: const Icon(Icons.edit_outlined,
                                            size: 18),
                                        label: const Text('Bewerken'),
                                        onPressed: () async {
                                          await Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (_) =>
                                                  SolarInstallationDetailPage(
                                                      installationId: item.id!,
                                                      inspectionId: widget.inspectionId),
                                            ),
                                          );
                                          _loadData();
                                        },
                                      ),
                                      TextButton.icon(
                                        icon: const Icon(Icons.delete_outline,
                                            size: 18),
                                        label: const Text('Verwijderen'),
                                        style: TextButton.styleFrom(
                                            foregroundColor: Colors.red),
                                        onPressed: () => _delete(item),
                                      ),
                                    ],
                                  ),
                                ),
                                const Divider(height: 1),
                                // Inverter list
                                if (inverters.isEmpty)
                                  const Padding(
                                    padding: EdgeInsets.fromLTRB(16, 8, 16, 12),
                                    child: Text(
                                      'Geen omvormers',
                                      style: TextStyle(color: Colors.grey),
                                    ),
                                  )
                                else
                                  ...inverters.map(
                                    (inv) => ListTile(
                                      contentPadding: const EdgeInsets.only(
                                          left: 32, right: 16),
                                      leading: const Icon(Icons.electric_bolt,
                                          color: Color(0xFF1976D2), size: 20),
                                      title: Text(inv.displayName),
                                      subtitle: inv.locationFull.isNotEmpty
                                          ? Text(inv.locationFull)
                                          : null,
                                      trailing:
                                          const Icon(Icons.chevron_right),
                                      onTap: () async {
                                        await Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (_) =>
                                                SolarInverterDetailPage(
                                                    inverterId: inv.id!,
                                                    inspectionId: widget.inspectionId),
                                          ),
                                        );
                                        _loadData();
                                      },
                                    ),
                                  ),
                              ],
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
