import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) return web;
    return const FirebaseOptions(
      apiKey: 'AIzaSyDhtMouDlsGsN1ggy1RVzdCvAzMR1ymAVU',
      appId: '1:173655924558:android:8bdd61b58d05b38c7b881f',
      messagingSenderId: '173655924558',
      projectId: 'okeymatik-1d379',
      storageBucket: 'okeymatik-1d379.firebasestorage.app',
      databaseURL: 'https://okeymatik-1d379-default-rtdb.europe-west1.firebasedatabase.app',
    );
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyDhtMouDlsGsN1ggy1RVzdCvAzMR1ymAVU',
    appId: '1:173655924558:web:8bdd61b58d05b38c7b881f',
    messagingSenderId: '173655924558',
    projectId: 'okeymatik-1d379',
    authDomain: 'okeymatik-1d379.firebaseapp.com',
    storageBucket: 'okeymatik-1d379.firebasestorage.app',
    databaseURL: 'https://okeymatik-1d379-default-rtdb.europe-west1.firebasedatabase.app',
  );
}
