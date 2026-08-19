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
import '../../models/nen_gebrek.dart';
import '../../services/database_service.dart';
import '../../services/nen2767_scoring_service.dart';
import 'nen_gebrek_detail_page.dart';

/// Gebreken van één bouwdeel/element-node, met per gebrek de conditiescore
/// en een geaggregeerde conditiescore voor de node als geheel.
class NenGebrekenListPage extends StatefulWidget {
  final int inspectionId;
  final int bouwdeelId;
  final String bouwdeelNaam;

  const NenGebrekenListPage({
    super.key,
    required this.inspectionId,
    required this.bouwdeelId,
    required this.bouwdeelNaam,
  });

  @override
  State<NenGebrekenListPage> createState() => _NenGebrekenListPageState();
}

class _NenGebrekenListPageState extends State<NenGebrekenListPage> {
  final _db = DatabaseService();
  bool _loading = true;
  List<NenGebrek> _gebreken = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _loading = true);
    final gebreken = await _db.getNenGebreken(widget.bouwdeelId);
    if (!mounted) return;
    setState(() {
      _gebreken = gebreken;
      _loading = false;
    });
  }

  Color _scoreColor(int score) {
    switch (score) {
      case 1:
        return Colors.green;
      case 2:
        return Colors.lightGreen;
      case 3:
        return Colors.yellow.shade700;
      case 4:
        return Colors.orange;
      case 5:
        return Colors.deepOrange;
      default:
        return Colors.red;
    }
  }

  Future<void> _create() async {
    final now = DateTime.now().toIso8601String();
    final id = await _db.insertNenGebrek(NenGebrek(
      inspectionId: widget.inspectionId,
      bouwdeelId: widget.bouwdeelId,
      geinspecteerdOp: now,
      createdAt: now,
      updatedAt: now,
    ));
    if (!mounted) return;
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => NenGebrekDetailPage(
          gebrekId: id,
          inspectionId: widget.inspectionId,
        ),
      ),
    );
    _loadData();
  }

  Future<void> _delete(NenGebrek gebrek) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Gebrek verwijderen'),
        content: const Text('Weet u zeker dat u dit gebrek wilt verwijderen?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Annuleren'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Verwijderen', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await _db.deleteNenGebrek(gebrek.id!);
      _loadData();
    }
  }

  @override
  Widget build(BuildContext context) {
    final geaggregeerd = _gebreken.isEmpty
        ? null
        : Nen2767ScoringService.aggregeerConditiescore(_gebreken);
    return Scaffold(
      appBar: AppBar(title: Text(widget.bouwdeelNaam)),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _create,
        icon: const Icon(Icons.add),
        label: const Text('Gebrek'),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                if (geaggregeerd != null)
                  Card(
                    margin: const EdgeInsets.all(12),
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: _scoreColor(geaggregeerd),
                        child: Text(
                          '$geaggregeerd',
                          style: const TextStyle(
                              color: Colors.white, fontWeight: FontWeight.bold),
                        ),
                      ),
                      title: const Text('Geaggregeerde conditiescore'),
                      subtitle: Text(
                          '${_gebreken.length} geregistreerd(e) gebrek(en)'),
                    ),
                  ),
                Expanded(
                  child: _gebreken.isEmpty
                      ? const Center(
                          child: Text(
                            'Nog geen gebreken geregistreerd.',
                            style: TextStyle(color: Colors.grey),
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.only(bottom: 80),
                          itemCount: _gebreken.length,
                          itemBuilder: (context, index) {
                            final gebrek = _gebreken[index];
                            return Card(
                              margin: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 4),
                              child: ListTile(
                                leading: CircleAvatar(
                                  backgroundColor:
                                      _scoreColor(gebrek.conditiescore),
                                  child: Text(
                                    '${gebrek.conditiescore}',
                                    style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold),
                                  ),
                                ),
                                title: Text(
                                  gebrek.gebrekOmschrijving.isNotEmpty
                                      ? gebrek.gebrekOmschrijving
                                      : 'Gebrek #${gebrek.id}',
                                ),
                                subtitle: Text(
                                  '${NenGebrek.ernstLabels[gebrek.ernst] ?? gebrek.ernst} · '
                                  '${gebrek.intensiteit} · '
                                  '${gebrek.omvangPercentage.toStringAsFixed(0)}%'
                                  '${gebrek.locatieDetail.isNotEmpty ? ' · ${gebrek.locatieDetail}' : ''}',
                                ),
                                trailing: IconButton(
                                  icon: const Icon(Icons.delete_outline,
                                      color: Colors.red),
                                  onPressed: () => _delete(gebrek),
                                ),
                                onTap: () async {
                                  await Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => NenGebrekDetailPage(
                                        gebrekId: gebrek.id!,
                                        inspectionId: widget.inspectionId,
                                                                    ),
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
