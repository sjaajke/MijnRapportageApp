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

import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform => web;

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyA96-7D2Edn0yXWYLExIY0rrPj7W3qEKHk',
    appId: '1:978448700820:web:eb7adcd26b405e5c01eb81',
    messagingSenderId: '978448700820',
    projectId: 'mijnrapportageapp',
    authDomain: 'mijnrapportageapp.firebaseapp.com',
    storageBucket: 'mijnrapportageapp.firebasestorage.app',
    measurementId: 'G-VY47543DKC',
  );
}
