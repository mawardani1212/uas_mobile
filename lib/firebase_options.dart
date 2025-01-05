import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
  show defaultTargetPlatform, kIsWeb, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    return android;
  }

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyA9tUeAtpEtpbgu1aU0KwcFiJpiZy0872w',
    appId: '1:816377949481:android:91d35c7a5b3b801a5c1b38',
    messagingSenderId: '816377949481',
    projectId: 'mawar-auth',
    storageBucket: 'mawar-auth.appspot.com',
  );
}
