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
import 'package:shared_preferences/shared_preferences.dart';

/// Bewaart de standaard "Naam uitvoerder" voor herstelmeldingen, zodat die
/// maar één keer ingesteld hoeft te worden en daarna automatisch wordt
/// ingevuld zodra een gebrek als hersteld wordt gemarkeerd.
class HerstelDefaultsService {
  static const _prefUitvoerder = 'herstel_standaard_uitvoerder';

  static Future<String> getUitvoerder() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_prefUitvoerder) ?? '';
  }

  static Future<void> setUitvoerder(String naam) async {
    final prefs = await SharedPreferences.getInstance();
    final trimmed = naam.trim();
    if (trimmed.isEmpty) {
      await prefs.remove(_prefUitvoerder);
    } else {
      await prefs.setString(_prefUitvoerder, trimmed);
    }
  }

  /// Datum van vandaag in hetzelfde formaat als de datumkiezer (dd-mm-jjjj).
  static String vandaag() {
    final now = DateTime.now();
    return '${now.day.toString().padLeft(2, '0')}-${now.month.toString().padLeft(2, '0')}-${now.year}';
  }

  /// Toont een dialoog om de standaard uitvoerder in te stellen. Geeft de
  /// opgeslagen naam terug, of null als de gebruiker annuleert.
  static Future<String?> showInstellenDialog(
    BuildContext context, {
    String voorstel = '',
  }) async {
    final huidig = await getUitvoerder();
    if (!context.mounted) return null;
    final controller = TextEditingController(
      text: voorstel.trim().isNotEmpty ? voorstel.trim() : huidig,
    );
    final result = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Standaard uitvoerder'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Deze naam wordt automatisch ingevuld zodra een gebrek als '
              'hersteld wordt gemarkeerd.',
              style: TextStyle(fontSize: 13),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: controller,
              autofocus: true,
              decoration: const InputDecoration(
                labelText: 'Naam uitvoerder',
                border: OutlineInputBorder(),
              ),
              onSubmitted: (v) => Navigator.pop(ctx, v),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Annuleren'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, controller.text),
            child: const Text('Opslaan'),
          ),
        ],
      ),
    );
    controller.dispose();
    if (result == null) return null;
    await setUitvoerder(result);
    return result.trim();
  }
}
