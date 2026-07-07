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

// Los entrypoint voor het externe Herstel-webformulier, losstaand van de
// hoofdapp (main.dart). Bouwen met:
//   flutter build web -t lib/main_herstel_web.dart --output=build/herstel_web

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'firebase_options.dart';
import 'screens/herstel_submit_page.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  final token = Uri.base.queryParameters['token'];
  runApp(HerstelWebApp(token: token));
}

class HerstelWebApp extends StatelessWidget {
  final String? token;

  const HerstelWebApp({super.key, this.token});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Herstelmelding',
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: const Color(0xFF1976D2),
      ),
      home: token == null || token!.isEmpty
          ? const Scaffold(
              body: Center(
                child: Padding(
                  padding: EdgeInsets.all(24),
                  child: Text(
                    'Ongeldige link: geen token gevonden. Scan de QR-code opnieuw vanaf de PDF.',
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            )
          : HerstelSubmitPage(token: token!),
    );
  }
}
