// File generated based on your Firebase project configuration.
// Project: quizme-1f9fc

import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return web;
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for ios - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
      case TargetPlatform.macOS:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for macos - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
      case TargetPlatform.windows:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for windows - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
      case TargetPlatform.linux:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for linux - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyBNjktAdNzOouiv23zTalOHKxrPWmOhl7w',
    appId: '1:578375040633:android:fde551e7b9f922d2865ea8',
    messagingSenderId: '578375040633',
    projectId: 'quizme-1f9fc',
    storageBucket: 'quizme-1f9fc.firebasestorage.app',
  );

  // TODO: Add web configuration from Firebase Console
  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyCpA8aWNJXAuAmXhbQBqFPhJICFj836hYU',
    appId: '1:578375040633:web:f639b43b575c81c6865ea8',
    messagingSenderId: '578375040633',
    projectId: 'quizme-1f9fc',
    storageBucket: 'quizme-1f9fc.firebasestorage.app',
    authDomain: 'quizme-1f9fc.firebaseapp.com',
    measurementId: 'G-TVVW003HBS',
  );
}
