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
import '../l10n/handleiding_localizations.dart';

const _kAccent = Color(0xFF1976D2);

/// Quickstart-handleiding — hoe gebruik je de app?
class HandleidingPage extends StatelessWidget {
  const HandleidingPage({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.hdlTitel)),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _HandleidingCard(
              titel: l10n.hdlIntroTitel,
              icoon: Icons.info_outline,
              tekst: l10n.hdlIntroTekst,
            ),
            const SizedBox(height: 8),
            _HandleidingCard(
              titel: l10n.hdlStap1Titel,
              icoon: Icons.note_add_outlined,
              tekst: l10n.hdlStap1Tekst,
            ),
            const SizedBox(height: 8),
            _HandleidingCard(
              titel: l10n.hdlStap2Titel,
              icoon: Icons.description_outlined,
              tekst: l10n.hdlStap2Tekst,
            ),
            const SizedBox(height: 8),
            _HandleidingCard(
              titel: l10n.hdlStap3Titel,
              icoon: Icons.rule_outlined,
              tekst: l10n.hdlStap3Tekst,
            ),
            const SizedBox(height: 8),
            _HandleidingCard(
              titel: l10n.hdlStap4Titel,
              icoon: Icons.electrical_services_outlined,
              tekst: l10n.hdlStap4Tekst,
            ),
            const SizedBox(height: 8),
            _HandleidingCard(
              titel: l10n.hdlStap5Titel,
              icoon: Icons.fact_check_outlined,
              tekst: l10n.hdlStap5Tekst,
            ),
            const SizedBox(height: 8),
            _HandleidingCard(
              titel: l10n.hdlStap6Titel,
              icoon: Icons.picture_as_pdf_outlined,
              tekst: l10n.hdlStap6Tekst,
            ),
            const SizedBox(height: 16),
            _HandleidingCard(
              titel: l10n.hdlInstellingenTitel,
              icoon: Icons.settings_outlined,
              tekst: l10n.hdlInstellingenTekst,
            ),
            const SizedBox(height: 8),
            _HandleidingCard(
              titel: l10n.hdlDelenTitel,
              icoon: Icons.share_outlined,
              tekst: l10n.hdlDelenTekst,
            ),
            const SizedBox(height: 8),
            _TipsSectie(l10n: l10n),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}

// ── Sectiekaart ────────────────────────────────────────────────────────────

class _HandleidingCard extends StatelessWidget {
  const _HandleidingCard({
    required this.titel,
    required this.icoon,
    required this.tekst,
  });

  final String titel;
  final IconData icoon;
  final String tekst;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icoon, size: 20, color: _kAccent),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    titel,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: _kAccent,
                    ),
                  ),
                ),
              ],
            ),
            const Divider(height: 16),
            Text(tekst, style: const TextStyle(height: 1.4)),
          ],
        ),
      ),
    );
  }
}

// ── Tips ───────────────────────────────────────────────────────────────────

class _TipsSectie extends StatelessWidget {
  const _TipsSectie({required this.l10n});

  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.lightbulb_outline, size: 20, color: _kAccent),
                const SizedBox(width: 8),
                Text(
                  l10n.hdlTipsTitel,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: _kAccent,
                  ),
                ),
              ],
            ),
            const Divider(height: 16),
            _TipRij(tekst: l10n.hdlTip1),
            const SizedBox(height: 6),
            _TipRij(tekst: l10n.hdlTip2),
            const SizedBox(height: 6),
            _TipRij(tekst: l10n.hdlTip3),
            const SizedBox(height: 6),
            _TipRij(tekst: l10n.hdlTip4),
            const SizedBox(height: 6),
            _TipRij(tekst: l10n.hdlTip5),
          ],
        ),
      ),
    );
  }
}

class _TipRij extends StatelessWidget {
  const _TipRij({required this.tekst});
  final String tekst;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 1),
      child: Text(tekst, style: const TextStyle(height: 1.4)),
    );
  }
}
