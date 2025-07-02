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
    apiKey: 'AIzaSyBUhjUupXUN6yAgSqRf9Ipi-zMmU0_7ciE',
    appId: '1:1030987145623:web:486588da94e7193ae024d2',
    messagingSenderId: '1030987145623',
    projectId: 'arandas-ai',
    authDomain: 'arandas-ai.firebaseapp.com',
    storageBucket: 'arandas-ai.firebasestorage.app',
    measurementId: 'G-HPDWBTV2PP',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyCW9OaIdKIIo0OHjtvKgYk6xYLGZDnrGVc',
    appId: '1:1030987145623:android:91291e002bb94bdce024d2',
    messagingSenderId: '1030987145623',
    projectId: 'arandas-ai',
    storageBucket: 'arandas-ai.firebasestorage.app',
  );

  static const FirebaseOptions windows = FirebaseOptions(
    apiKey: 'AIzaSyBUhjUupXUN6yAgSqRf9Ipi-zMmU0_7ciE',
    appId: '1:1030987145623:web:4bb3bafc37aaea6ce024d2',
    messagingSenderId: '1030987145623',
    projectId: 'arandas-ai',
    authDomain: 'arandas-ai.firebaseapp.com',
    storageBucket: 'arandas-ai.firebasestorage.app',
    measurementId: 'G-22YVH691KG',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyBVngwIkTf_1SUpmBi2iZlJpZe-9-EmkbU',
    appId: '1:1030987145623:ios:6a1640bd6ae852b5e024d2',
    messagingSenderId: '1030987145623',
    projectId: 'arandas-ai',
    storageBucket: 'arandas-ai.firebasestorage.app',
    iosClientId: '1030987145623-01r8oa90e3vpj20bjqjv0dv20op3pscl.apps.googleusercontent.com',
    iosBundleId: 'com.arandas.posSystem',
  );

  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: 'AIzaSyBVngwIkTf_1SUpmBi2iZlJpZe-9-EmkbU',
    appId: '1:1030987145623:ios:6a1640bd6ae852b5e024d2',
    messagingSenderId: '1030987145623',
    projectId: 'arandas-ai',
    storageBucket: 'arandas-ai.firebasestorage.app',
    iosClientId: '1030987145623-01r8oa90e3vpj20bjqjv0dv20op3pscl.apps.googleusercontent.com',
    iosBundleId: 'com.arandas.posSystem',
  );

}