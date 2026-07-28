import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

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
}
