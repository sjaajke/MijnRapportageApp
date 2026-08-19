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

import 'package:firebase_core/firebase_core.dart';
import '../firebase_options.dart';

/// Initialiseert Firebase zonder ooit een exception naar buiten te laten
/// ontsnappen. Lukt het niet (geen netwerk, geblokkeerde host, verkeerde
/// configuratie), dan blijft de app gewoon draaien: de aanroeper krijgt
/// `false` terug en kan een nette melding tonen en het later opnieuw proberen.
///
/// Alleen het Herstel-webformulier gebruikt de Firebase-SDK's; de hoofdapp
/// praat via REST met Firestore/Storage (zie `HerstelSyncService`) en is dus
/// sowieso niet van deze initialisatie afhankelijk.
class FirebaseBootstrap {
  static const _timeout = Duration(seconds: 15);

  static bool _ready = false;
  static String? _lastError;

  /// Of Firebase bruikbaar is. Zolang dit `false` is, mag er niets via
  /// `FirebaseFirestore.instance` / `FirebaseStorage.instance` lopen.
  static bool get isReady => _ready;

  /// De laatste initialisatiefout, of `null` als er (nog) geen fout was.
  static String? get lastError => _lastError;

  /// Probeert Firebase te initialiseren. Geeft `true` terug als Firebase
  /// (nu of al eerder) klaar is voor gebruik. Veilig om meerdere keren aan te
  /// roepen — bijvoorbeeld als retry vanuit een knop.
  static Future<bool> ensureInitialized() async {
    if (_ready) return true;
    try {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      ).timeout(_timeout);
      _ready = true;
      _lastError = null;
    } catch (e) {
      // Een dubbele initialisatie (bijv. na een hot restart) is geen fout:
      // bestaat er al een app, dan is Firebase alsnog bruikbaar.
      _ready = _hasExistingApp();
      _lastError = _ready ? null : e.toString();
    }
    return _ready;
  }

  static bool _hasExistingApp() {
    try {
      return Firebase.apps.isNotEmpty;
    } catch (_) {
      return false;
    }
  }
}
