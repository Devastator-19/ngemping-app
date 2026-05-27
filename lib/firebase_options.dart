import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) throw UnsupportedError('Web not supported');
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyCyhQ2lThfVWNmq1gk5fN9UuXd88nHpRR8',
    appId: '1:117593786021:android:3176eb18490b458e2fef4c',
    messagingSenderId: '117593786021',
    projectId: 'ngemping-app',
    storageBucket: 'ngemping-app.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyBqZwqle71NBIlte7H7x3EQ0Ca4GKbgS4k',
    appId: '1:117593786021:ios:bfdaaa8c33938d322fef4c',
    messagingSenderId: '117593786021',
    projectId: 'ngemping-app',
    storageBucket: 'ngemping-app.firebasestorage.app',
    iosBundleId: 'com.outzy.app',
  );
}
