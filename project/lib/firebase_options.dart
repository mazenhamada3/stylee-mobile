// ⚠️  THIS FILE IS A PLACEHOLDER.
// Run `flutterfire configure` in your project root to auto-generate this file.
// See SETUP.md for full step-by-step instructions.

import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) return web;
    switch (defaultTargetPlatform) {
      case TargetPlatform.android: return android;
      case TargetPlatform.iOS:     return ios;
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  // ──────────────────────────────────────────────────────────────────────────
  // Replace the placeholder values below with your actual Firebase config.
  // The easiest way: run `flutterfire configure` and let it overwrite this file.
  // ──────────────────────────────────────────────────────────────────────────

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyBuLpQDfljjGviynS0gVkhUO8ASHL40XSs',
    appId: '1:307032636046:android:646bb6623e024bb7ca27df',
    messagingSenderId: '307032636046',
    projectId: 'stylee-app-4b6cb',
    storageBucket: 'stylee-app-4b6cb.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyA_kLaHrmGxTPbhCfJWijTWWsy-dFEoQN4',
    appId: '1:307032636046:ios:420856cfac5a4193ca27df',
    messagingSenderId: '307032636046',
    projectId: 'stylee-app-4b6cb',
    storageBucket: 'stylee-app-4b6cb.firebasestorage.app',
    iosBundleId: 'com',
  );

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyD-35esiyRYdkpEKDq12xupkeE40UyxDlI',
    appId: '1:307032636046:web:0aebe8bfcf9014a1ca27df',
    messagingSenderId: '307032636046',
    projectId: 'stylee-app-4b6cb',
    authDomain: 'stylee-app-4b6cb.firebaseapp.com',
    storageBucket: 'stylee-app-4b6cb.firebasestorage.app',
  );

}