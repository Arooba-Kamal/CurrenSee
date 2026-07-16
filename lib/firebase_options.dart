import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart' show defaultTargetPlatform, kIsWeb, TargetPlatform;

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
        return linux;
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  // ✅ WEB - Your correct values
  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyA7-nAvM22YPPIF1VtGA84xkuHyS3qG-Ec',
    appId: '1:68772374307:web:4a2da96ca491dbdbe04e96',
    messagingSenderId: '68772374307',
    projectId: 'currensee-71845',
    authDomain: 'currensee-71845.firebaseapp.com',
    storageBucket: 'currensee-71845.firebasestorage.app',
  );

  // ✅ ANDROID - Your correct values
  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyA7-nAvM22YPPIF1VtGA84xkuHyS3qG-Ec',
    appId: '1:68772374307:android:751399d94246e1d0e04e96',
    messagingSenderId: '68772374307',
    projectId: 'currensee-71845',
    authDomain: 'currensee-71845.firebaseapp.com',
    storageBucket: 'currensee-71845.firebasestorage.app',
  );

  // ✅ iOS - Your correct values
  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyA7-nAvM22YPPIF1VtGA84xkuHyS3qG-Ec',
    appId: '1:68772374307:ios:1bba202b406f80b0e04e96',
    messagingSenderId: '68772374307',
    projectId: 'currensee-71845',
    authDomain: 'currensee-71845.firebaseapp.com',
    storageBucket: 'currensee-71845.firebasestorage.app',
    iosClientId: '68772374307-abcdefghijklmnopqrstuvwxyz.apps.googleusercontent.com', // 🔥 iOS Client ID daalein
    iosBundleId: 'com.example.currensee',
  );

  // ✅ macOS - Same as iOS with different appId
  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: 'AIzaSyA7-nAvM22YPPIF1VtGA84xkuHyS3qG-Ec',
    appId: '1:68772374307:ios:1bba202b406f80b0e04e96', // macOS ke liye alag appId
    messagingSenderId: '68772374307',
    projectId: 'currensee-71845',
    authDomain: 'currensee-71845.firebaseapp.com',
    storageBucket: 'currensee-71845.firebasestorage.app',
    iosClientId: '68772374307-abcdefghijklmnopqrstuvwxyz.apps.googleusercontent.com',
    iosBundleId: 'com.example.currensee',
  );

  // ✅ Windows - Web config se hi kaam chalega
  static const FirebaseOptions windows = FirebaseOptions(
    apiKey: 'AIzaSyA7-nAvM22YPPIF1VtGA84xkuHyS3qG-Ec',
    appId: '1:68772374307:web:4a2da96ca491dbdbe04e96',
    messagingSenderId: '68772374307',
    projectId: 'currensee-71845',
    authDomain: 'currensee-71845.firebaseapp.com',
    storageBucket: 'currensee-71845.firebasestorage.app',
  );

  // ✅ Linux - Web config se hi kaam chalega
  static const FirebaseOptions linux = FirebaseOptions(
    apiKey: 'AIzaSyA7-nAvM22YPPIF1VtGA84xkuHyS3qG-Ec',
    appId: '1:68772374307:web:4a2da96ca491dbdbe04e96',
    messagingSenderId: '68772374307',
    projectId: 'currensee-71845',
    authDomain: 'currensee-71845.firebaseapp.com',
    storageBucket: 'currensee-71845.firebasestorage.app',
  );
}