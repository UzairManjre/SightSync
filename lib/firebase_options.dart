// File generated manually from GoogleService-Info.plist
// ignore_for_file: lines_longer_than_80_chars, avoid_classes_with_only_static_members
import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) throw UnsupportedError('Web not configured for Firebase yet.');
    switch (defaultTargetPlatform) {
      case TargetPlatform.iOS:
      case TargetPlatform.macOS:
        return ios;
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyDTJZylSHT5LhGcEdlL9gJ6xyKWEkLKsaY',
    appId: '1:434014707756:ios:8b2a9d6e7020d53b95b189',
    messagingSenderId: '434014707756',
    projectId: 'sightsync-5e1bb',
    storageBucket: 'sightsync-5e1bb.firebasestorage.app',
    iosBundleId: 'com.uzairmanjre.sightsync',
  );
}
