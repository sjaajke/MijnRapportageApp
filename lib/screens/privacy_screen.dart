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

class PrivacyScreen extends StatelessWidget {
  const PrivacyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.privacyTitel),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l10n.privacyTitel,
                style: textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Text(
              l10n.privacyBijgewerkt,
              style: textTheme.bodySmall?.copyWith(color: colorScheme.outline),
            ),
            const SizedBox(height: 8),
            Text(
              l10n.privacyIntro,
              style: textTheme.bodyMedium,
            ),
            const SizedBox(height: 24),
            _Sectie(
              nummer: '1',
              titel: l10n.privacy1Titel,
              body: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(l10n.privacy1Intro),
                  const SizedBox(height: 8),
                  ...l10n.privacy1Bullets.map((item) => _BulletRij(text: item)),
                  const SizedBox(height: 8),
                  Text(l10n.privacy1Slot),
                ],
              ),
            ),
            _Sectie(
              nummer: '2',
              titel: l10n.privacy2Titel,
              body: Text(l10n.privacy2Body),
            ),
            _Sectie(
              nummer: '3',
              titel: l10n.privacy3Titel,
              body: Text(l10n.privacy3Body),
            ),
            _Sectie(
              nummer: '4',
              titel: l10n.privacy4Titel,
              body: Text(l10n.privacy4Body),
            ),
            _Sectie(
              nummer: '5',
              titel: l10n.privacy5Titel,
              body: Text(l10n.privacy5Body),
            ),
            _Sectie(
              nummer: '6',
              titel: l10n.privacy6Titel,
              body: Text(l10n.privacy6Body),
            ),
            _Sectie(
              nummer: '7',
              titel: l10n.privacy7Titel,
              body: Text(l10n.privacy7Body),
            ),
            _Sectie(
              nummer: '8',
              titel: l10n.privacy8Titel,
              body: Text(l10n.privacy8Body),
            ),
            _Sectie(
              nummer: '9',
              titel: l10n.privacy9Titel,
              body: Text(l10n.privacy9Body),
            ),
            _Sectie(
              nummer: '10',
              titel: l10n.privacy10Titel,
              body: Text(l10n.privacy10Body),
            ),
            _Sectie(
              nummer: '11',
              titel: l10n.privacy11Titel,
              body: Text(l10n.privacy11Body),
            ),
          ],
        ),
      ),
    );
  }
}

class _Sectie extends StatelessWidget {
  const _Sectie({required this.nummer, required this.titel, required this.body});

  final String nummer;
  final String titel;
  final Widget body;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$nummer. $titel',
            style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          body,
        ],
      ),
    );
  }
}

class _BulletRij extends StatelessWidget {
  const _BulletRij({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('• ', style: TextStyle(fontSize: 16)),
          Expanded(child: Text(text)),
        ],
      ),
    );
  }
}
