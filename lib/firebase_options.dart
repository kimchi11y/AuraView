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
        return ios;
      case TargetPlatform.macOS:
        return macos;
      case TargetPlatform.windows:
        return windows;
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

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyBd13_jTybGbtNQKr0-7MP_hddoPzPvwgE',
    appId: '1:126246467094:web:db69dc2991b07d2af96737',
    messagingSenderId: '126246467094',
    projectId: 'auraview-e3e24',
    authDomain: 'auraview-e3e24.firebaseapp.com',
    storageBucket: 'auraview-e3e24.firebasestorage.app',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyBLVl9F-TUhazynfmrwejpyoeaa6c78wPY',
    appId: '1:126246467094:android:ffae1088e4d6b829f96737',
    messagingSenderId: '126246467094',
    projectId: 'auraview-e3e24',
    storageBucket: 'auraview-e3e24.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyCXBhpVjiZtxTYx9D47PLng-0LUVTOR3sk',
    appId: '1:126246467094:ios:4e894bd16f8c7b21f96737',
    messagingSenderId: '126246467094',
    projectId: 'auraview-e3e24',
    storageBucket: 'auraview-e3e24.firebasestorage.app',
    iosBundleId: 'com.example.auraView',
  );

  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: 'AIzaSyCXBhpVjiZtxTYx9D47PLng-0LUVTOR3sk',
    appId: '1:126246467094:ios:4e894bd16f8c7b21f96737',
    messagingSenderId: '126246467094',
    projectId: 'auraview-e3e24',
    storageBucket: 'auraview-e3e24.firebasestorage.app',
    iosBundleId: 'com.example.auraView',
  );

  static const FirebaseOptions windows = FirebaseOptions(
    apiKey: 'AIzaSyBd13_jTybGbtNQKr0-7MP_hddoPzPvwgE',
    appId: '1:126246467094:web:c7112bf42a830c4ff96737',
    messagingSenderId: '126246467094',
    projectId: 'auraview-e3e24',
    authDomain: 'auraview-e3e24.firebaseapp.com',
    storageBucket: 'auraview-e3e24.firebasestorage.app',
  );
}
