import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) return web;

    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      case TargetPlatform.macOS:
        return macos;
      case TargetPlatform.windows:
        return windows;
      case TargetPlatform.linux:
        return linux;
      default:
        return web;
    }
  }

  // ✅ WEB — REAL Firebase config (from console)
  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyDfR-0N8962BdVQplJORolq75gyY6Jae4s',
    appId: '1:506690888246:web:d15e4b31f1319bf0a1ee97',
    messagingSenderId: '506690888246',
    projectId: 'pawtopia-7db32',
    authDomain: 'pawtopia-7db32.firebaseapp.com',
    storageBucket: 'pawtopia-7db32.firebasestorage.app',
  );

  // ⏳ ANDROID — will be set after adding Android app in Firebase Console
  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'TEMP',
    appId: 'TEMP',
    messagingSenderId: 'TEMP',
    projectId: 'pawtopia-7db32',
    storageBucket: 'pawtopia-7db32.firebasestorage.app',
  );

  // ⏳ iOS — later
  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'TEMP',
    appId: 'TEMP',
    messagingSenderId: 'TEMP',
    projectId: 'pawtopia-7db32',
    storageBucket: 'pawtopia-7db32.firebasestorage.app',
    iosBundleId: 'TEMP',
  );

  static const FirebaseOptions macos = ios;
  static const FirebaseOptions windows = web;
  static const FirebaseOptions linux = web;
}
