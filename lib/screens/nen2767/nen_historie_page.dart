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

/// Vergelijkt conditiescores per bouwdeel (gematcht op naam) tussen deze
/// inspectie en eerdere inspecties van hetzelfde object (gekoppeld via
/// objectcode in de objectgegevens).
class NenHistoriePage extends StatefulWidget {
  final int inspectionId;
  final String objectcode;

  const NenHistoriePage({
    super.key,
    required this.inspectionId,
    required this.objectcode,
  });

  @override
  State<NenHistoriePage> createState() => _NenHistoriePageState();
}

class _HistorieRij {
  final String naam;
  final Map<int, int> scorePerInspectie; // inspectionId -> conditiescore
  _HistorieRij(this.naam, this.scorePerInspectie);
}

class _NenHistoriePageState extends State<NenHistoriePage> {
  final _db = DatabaseService();
  bool _loading = true;
  List<int> _inspectionIds = [];
  Map<int, String> _datumPerInspectie = {};
  List<_HistorieRij> _rijen = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<Map<String, int>> _scorePerBouwdeelnaam(int inspectionId) async {
    final bouwdelen = await _db.getNenBouwdelen(inspectionId);
    final gebreken = await _db.getNenGebrekenVoorInspectie(inspectionId);
    final gebrekenPerNode = <int, List<NenGebrek>>{};
    for (final g in gebreken) {
      gebrekenPerNode.putIfAbsent(g.bouwdeelId, () => []).add(g);
    }
    final result = <String, int>{};
    for (final b in bouwdelen) {
      final eigen = gebrekenPerNode[b.id];
      if (eigen != null && eigen.isNotEmpty) {
        result[b.naam] = Nen2767ScoringService.aggregeerConditiescore(eigen);
      }
    }
    return result;
  }

  Future<void> _loadData() async {
    setState(() => _loading = true);
    if (widget.objectcode.isEmpty) {
      setState(() => _loading = false);
      return;
    }
    final anderen = await _db.getNenInspectionIdsVoorObjectcode(
      widget.objectcode,
      excludeInspectionId: widget.inspectionId,
    );
    final ids = [widget.inspectionId, ...anderen];
    final datums = <int, String>{};
    for (final id in ids) {
      final inspection = await _db.getInspection(id);
      datums[id] = inspection?.createdAt.split('T').first ?? '';
    }

    final naamSet = <String>{};
    final scoresPerInspectie = <int, Map<String, int>>{};
    for (final id in ids) {
      final scores = await _scorePerBouwdeelnaam(id);
      scoresPerInspectie[id] = scores;
      naamSet.addAll(scores.keys);
    }

    final rijen = naamSet.map((naam) {
      final scorePerInspectie = <int, int>{};
      for (final id in ids) {
        final score = scoresPerInspectie[id]?[naam];
        if (score != null) scorePerInspectie[id] = score;
      }
      return _HistorieRij(naam, scorePerInspectie);
    }).toList()
      ..sort((a, b) => a.naam.compareTo(b.naam));

    if (!mounted) return;
    setState(() {
      _inspectionIds = ids;
      _datumPerInspectie = datums;
      _rijen = rijen;
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Historie')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : widget.objectcode.isEmpty
              ? const Center(
                  child: Padding(
                    padding: EdgeInsets.all(24),
                    child: Text(
                      'Vul eerst een objectcode in bij de objectgegevens om '
                      'inspecties van hetzelfde object te koppelen en te '
                      'vergelijken.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey),
                    ),
                  ),
                )
              : _inspectionIds.length <= 1
                  ? const Center(
                      child: Text(
                        'Geen eerdere inspecties gevonden met dezelfde '
                        'objectcode.',
                        style: TextStyle(color: Colors.grey),
                      ),
                    )
                  : SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: DataTable(
                        columns: [
                          const DataColumn(label: Text('Bouwdeel')),
                          for (final id in _inspectionIds)
                            DataColumn(
                              label: Text(
                                id == widget.inspectionId
                                    ? 'Nu (${_datumPerInspectie[id]})'
                                    : _datumPerInspectie[id] ?? '$id',
                              ),
                            ),
                        ],
                        rows: [
                          for (final rij in _rijen)
                            DataRow(cells: [
                              DataCell(Text(rij.naam)),
                              for (final id in _inspectionIds)
                                DataCell(
                                  rij.scorePerInspectie[id] == null
                                      ? const Text('-')
                                      : CircleAvatar(
                                          radius: 12,
                                          backgroundColor: _scoreColor(
                                              rij.scorePerInspectie[id]!),
                                          child: Text(
                                            '${rij.scorePerInspectie[id]}',
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 11,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                ),
                            ]),
                        ],
                      ),
                    ),
    );
  }
}
