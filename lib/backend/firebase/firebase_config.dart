import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

// DEV-ONLY, default-off: when true (via --dart-define=USE_FIREBASE_EMULATOR=true),
// points Firestore/Auth at the local Firebase emulator suite instead of the
// real head-sense-1111 project. Never touches production unless explicitly
// passed at launch. Safe to remove once local mock-data testing is done.
const bool _useFirebaseEmulator =
    bool.fromEnvironment('USE_FIREBASE_EMULATOR', defaultValue: false);

Future initFirebase() async {
  if (kIsWeb) {
    await Firebase.initializeApp(
        options: FirebaseOptions(
            apiKey: "AIzaSyBgnPAj-w5ICjOjdd2MtfWN0KxmFzbgvaY",
            authDomain: "head-sense-1111.firebaseapp.com",
            projectId: "head-sense-1111",
            storageBucket: "head-sense-1111.firebasestorage.app",
            messagingSenderId: "373987499196",
            appId: "1:373987499196:web:2802559309600d0c47c4b9"));
  } else {
    await Firebase.initializeApp();
  }
  if (_useFirebaseEmulator) {
    FirebaseFirestore.instance.useFirestoreEmulator('localhost', 8080);
    await FirebaseAuth.instance.useAuthEmulator('localhost', 9099);
  }
}
