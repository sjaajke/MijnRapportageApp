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
import '../widgets/inspection_nav_bar.dart';
import '../l10n/app_localizations.dart';
import '../models/solar_installation.dart';
import '../models/solar_inverter.dart';
import '../services/database_service.dart';
import 'solar_installation_detail_page.dart';
import 'solar_inverter_detail_page.dart';

/// Below this content width the page shows the installation list full-screen
/// and pushes the detail as a separate route; at or above it, a split view
/// shows the list on the left and the selected installation's detail on the
/// right.
const _splitBreakpoint = 800.0;

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
  int? _selectedInstallationId;
  int? _selectedInverterId;

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
      if (_selectedInstallationId != null &&
          !_installations.any((i) => i.id == _selectedInstallationId)) {
        _selectedInstallationId = null;
      }
      if (_selectedInverterId != null &&
          !invertersMap.values
              .any((list) => list.any((i) => i.id == _selectedInverterId))) {
        _selectedInverterId = null;
      }
    });
  }

  Future<void> _create() async {
    final isSplit = MediaQuery.sizeOf(context).width >= _splitBreakpoint;
    final id = await _db.insertSolarInstallation(
      SolarInstallation(inspectionId: widget.inspectionId),
    );
    if (!mounted) return;
    if (isSplit) {
      await _loadData();
      if (!mounted) return;
      setState(() {
        _selectedInstallationId = id;
        _selectedInverterId = null;
      });
      return;
    }
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
      if (_selectedInstallationId == item.id) {
        setState(() => _selectedInstallationId = null);
      }
      await _db.deleteSolarInstallation(item.id!);
      _loadData();
    }
  }

  Future<void> _copyInverter(SolarInverter inverter) async {
    await _db.insertSolarInverter(
      SolarInverter(
        solarInstallationId: inverter.solarInstallationId,
        location: inverter.location,
        locationA: inverter.locationA,
        locationB: inverter.locationB,
        inverterName: inverter.inverterName,
        inverterBrand: inverter.inverterBrand,
        inverterType: inverter.inverterType,
        inverterSerial: inverter.inverterSerial,
        inverterIp: inverter.inverterIp,
        inverterIsolationClass: inverter.inverterIsolationClass,
        inverterMaxVdc: inverter.inverterMaxVdc,
        inverterMaxIdc: inverter.inverterMaxIdc,
        inverterIscPv: inverter.inverterIscPv,
        inverterInom: inverter.inverterInom,
        panelBrand: inverter.panelBrand,
        panelType: inverter.panelType,
        panelShortCircuitCurrent: inverter.panelShortCircuitCurrent,
        panelOpenCircuitVoltage: inverter.panelOpenCircuitVoltage,
        protection: inverter.protection,
        cable: inverter.cable,
        photoPath: inverter.photoPath,
        typePlaatjePath: inverter.typePlaatjePath,
        showInverterFields: inverter.showInverterFields,
        showPanelFields: inverter.showPanelFields,
      ),
    );
    _loadData();
  }

  Future<void> _deleteInverter(SolarInverter inverter) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Omvormer verwijderen'),
        content: const Text(
            'Weet je zeker dat je deze omvormer wilt verwijderen?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Annuleren'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Verwijderen',
                style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      if (_selectedInverterId == inverter.id) {
        setState(() => _selectedInverterId = null);
      }
      await _db.deleteSolarInverter(inverter.id!);
      _loadData();
    }
  }

  Widget _buildFullList(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_installations.isEmpty) {
      return Center(
        child: Text(
          l10n.noInstallations,
          textAlign: TextAlign.center,
          style: const TextStyle(color: Colors.grey),
        ),
      );
    }

    return ListView.builder(
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
                              subtitle: item.isGemarkeerd || item.panelCount != null
                                  ? Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        if (item.isGemarkeerd) ...[
                                          const Tooltip(
                                            message: 'Overgenomen als duplicaat',
                                            child: Icon(Icons.content_copy,
                                                color: Colors.orange, size: 16),
                                          ),
                                          const SizedBox(width: 4),
                                        ],
                                        if (item.panelCount != null)
                                          Text(l10n.panelCount(item.panelCount!)),
                                      ],
                                    )
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
                                      trailing: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          IconButton(
                                            icon: const Icon(
                                                Icons.copy_outlined,
                                                size: 20),
                                            tooltip: 'Omvormer kopiëren',
                                            onPressed: () =>
                                                _copyInverter(inv),
                                          ),
                                          IconButton(
                                            icon: const Icon(
                                                Icons.delete_outline,
                                                color: Colors.red,
                                                size: 20),
                                            onPressed: () =>
                                                _deleteInverter(inv),
                                          ),
                                          const SizedBox(width: 4),
                                          const Icon(Icons.chevron_right),
                                        ],
                                      ),
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
                      );
  }

  Widget _buildSplitList(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_installations.isEmpty) {
      return Center(
        child: Text(
          l10n.noInstallations,
          textAlign: TextAlign.center,
          style: const TextStyle(color: Colors.grey),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.only(bottom: 80),
      itemCount: _installations.length,
      itemBuilder: (context, index) {
        final item = _installations[index];
        final inverters = _invertersByInstallation[item.id!] ?? [];
        final isInstallationActive =
            _selectedInverterId == null && item.id == _selectedInstallationId;
        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              ListTile(
                tileColor: isInstallationActive
                    ? Theme.of(context).colorScheme.primaryContainer
                        .withValues(alpha: 0.4)
                    : null,
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
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (item.isGemarkeerd) ...[
                      const Tooltip(
                        message: 'Overgenomen als duplicaat',
                        child: Icon(Icons.content_copy,
                            color: Colors.orange, size: 18),
                      ),
                      const SizedBox(width: 4),
                    ],
                    IconButton(
                      icon: const Icon(Icons.delete_outline,
                          color: Colors.red),
                      onPressed: () => _delete(item),
                    ),
                    const SizedBox(width: 4),
                    const Icon(Icons.chevron_right),
                  ],
                ),
                onTap: () => setState(() {
                  _selectedInstallationId = item.id;
                  _selectedInverterId = null;
                }),
              ),
              if (inverters.isEmpty)
                const Padding(
                  padding: EdgeInsets.fromLTRB(16, 0, 16, 8),
                  child: Text(
                    'Geen omvormers',
                    style: TextStyle(color: Colors.grey, fontSize: 12),
                  ),
                )
              else
                ...inverters.map((inv) {
                  final isInverterActive = inv.id == _selectedInverterId;
                  return ListTile(
                    dense: true,
                    contentPadding:
                        const EdgeInsets.only(left: 32, right: 16),
                    tileColor: isInverterActive
                        ? Theme.of(context).colorScheme.primaryContainer
                            .withValues(alpha: 0.4)
                        : null,
                    leading: const Icon(Icons.electric_bolt,
                        color: Color(0xFF1976D2), size: 20),
                    title: Text(inv.displayName),
                    subtitle: inv.locationFull.isNotEmpty
                        ? Text(inv.locationFull)
                        : null,
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.copy_outlined, size: 20),
                          tooltip: 'Omvormer kopiëren',
                          onPressed: () => _copyInverter(inv),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete_outline,
                              color: Colors.red, size: 20),
                          onPressed: () => _deleteInverter(inv),
                        ),
                        const SizedBox(width: 4),
                        const Icon(Icons.chevron_right),
                      ],
                    ),
                    onTap: () => setState(() {
                      _selectedInverterId = inv.id;
                      _selectedInstallationId = null;
                    }),
                  );
                }),
              const SizedBox(height: 4),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDetailPane(BuildContext context) {
    final selectedInverterId = _selectedInverterId;
    if (selectedInverterId != null) {
      return SolarInverterDetailView(
        key: ValueKey('inverter-$selectedInverterId'),
        inverterId: selectedInverterId,
        inspectionId: widget.inspectionId,
        onSavedAndClose: () => setState(() => _selectedInverterId = null),
        onNotFound: () => setState(() => _selectedInverterId = null),
        onInverterUpdated: (updated) {
          setState(() {
            final list = _invertersByInstallation[updated.solarInstallationId];
            if (list != null) {
              final idx = list.indexWhere((i) => i.id == updated.id);
              if (idx >= 0) list[idx] = updated;
            }
          });
        },
      );
    }

    final selectedInstallationId = _selectedInstallationId;
    if (selectedInstallationId == null) {
      return const Center(
        child: Text(
          'Selecteer een zonnestroominstallatie of omvormer om de details te bekijken.',
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.grey),
        ),
      );
    }
    return SolarInstallationDetailView(
      key: ValueKey('installation-$selectedInstallationId'),
      installationId: selectedInstallationId,
      inspectionId: widget.inspectionId,
      onSavedAndClose: () => setState(() => _selectedInstallationId = null),
      onNotFound: () => setState(() => _selectedInstallationId = null),
      onInstallationUpdated: (updated) {
        setState(() {
          final idx = _installations.indexWhere((i) => i.id == updated.id);
          if (idx >= 0) _installations[idx] = updated;
        });
      },
    );
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
          InspectionNavBar(inspectionId: widget.inspectionId, current: NavSection.solar),
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final isSplit = constraints.maxWidth >= _splitBreakpoint;
                if (!isSplit) {
                  return _buildFullList(context);
                }
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    SizedBox(
                      width: 380,
                      child: _buildSplitList(context),
                    ),
                    const VerticalDivider(width: 1),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: _buildDetailPane(context),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
