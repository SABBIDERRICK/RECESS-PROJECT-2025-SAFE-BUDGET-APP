// lib/firebase_options.dart

import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, TargetPlatform, kIsWeb;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return web;
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      case TargetPlatform.macOS:
        return macos;
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: "AIzaSyDKZBWzlquwhSZxdB6B9hNuAX_3TWoN-OA",
    authDomain: "safe-budget-2025.firebaseapp.com",
    projectId: "safe-budget-2025",
    storageBucket: "safe-budget-2025.firebasestorage.app",
    messagingSenderId: "551169168082",
    appId: "1:551169168082:web:b599c82c1a589395ee530b",
    measurementId: null,
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: "AIzaSyDKZBWzlquwhSZxdB6B9hNuAX_3TWoN-OA",
    appId: "1:551169168082:web:b599c82c1a589395ee530b",
    messagingSenderId: "551169168082",
    projectId: "safe-budget-2025",
    storageBucket: "safe-budget-2025.firebasestorage.app",
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: "AIzaSyDKZBWzlquwhSZxdB6B9hNuAX_3TWoN-OA",
    appId: "1:551169168082:web:b599c82c1a589395ee530b",
    messagingSenderId: "551169168082",
    projectId: "safe-budget-2025",
    storageBucket: "safe-budget-2025.firebasestorage.app",
    iosClientId: "",
    iosBundleId: "",
  );

  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: "AIzaSyDKZBWzlquwhSZxdB6B9hNuAX_3TWoN-OA",
    appId: "1:551169168082:web:b599c82c1a589395ee530b",
    messagingSenderId: "551169168082",
    projectId: "safe-budget-2025",
    storageBucket: "safe-budget-2025.firebasestorage.app",
    iosClientId: "",
    iosBundleId: "",
  );
}
