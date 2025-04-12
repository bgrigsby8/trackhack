// File: lib/firebase_options.dart
// Generated file. Do not edit.
import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart' show kIsWeb;

/// Default [FirebaseOptions] for use with your Firebase apps.
///
/// Example:
/// ```dart
// / import 'firebase_options.dart';
// / // ...
// / await Firebase.initializeApp(
// /   options: DefaultFirebaseOptions.currentPlatform,
// / );
/// ```
class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return web;
    }
    // Fallback for other platforms
    return web;
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyCG-odlqFKXggITvILs6-0SfFHTe8MWM0g',
    appId: '1:48132114949:web:2870395048e9b1dcf4ea6c',
    databaseURL:
        "https://console.firebase.google.com/u/1/project/trackhack-dbd7c/firestore/databases/-default-/data",
    messagingSenderId: '48132114949',
    projectId: 'trackhack-dbd7c',
    authDomain: 'trackhack-dbd7c.firebaseapp.com',
    storageBucket: 'trackhack-dbd7c.firebasestorage.app',
  );
}
