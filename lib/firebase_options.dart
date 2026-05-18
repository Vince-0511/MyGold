import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    return android;
  }

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyD69VtbUajdsks9G2SeL3yPOUGmY11dwas',
    appId: '1:111341108655:web:c8df61f1a66298dc97c35a',
    messagingSenderId: '111341108655',
    projectId: 'mygold-6bdac',
    storageBucket: 'mygold-6bdac.firebasestorage.app',
  );
}
