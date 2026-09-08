import 'dart:async';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../auth_manager.dart';
import '../base_auth_user_provider.dart';
import '../../flutter_flow/flutter_flow_util.dart';

import '/backend/backend.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:stream_transform/stream_transform.dart';
import 'firebase_auth_manager.dart';

export 'firebase_auth_manager.dart';

final _authManager = FirebaseAuthManager();
FirebaseAuthManager get authManager => _authManager;

String get currentUserEmail =>
    currentUserDocument?.email ?? currentUser?.email ?? '';

String get currentUserUid => currentUser?.uid ?? '';

/// The pseudonymous id the pseudonymous clinical collections
/// (diary_entries, dashboard, health_samples) are keyed by - never the
/// Firebase Auth uid. Assigned once per account by the assignSubjectId
/// cloud function and read here off the already-loaded user doc (see
/// currentUserDocument below), not the ID token, so there's no
/// token-refresh race right after sign-up. Empty until the cloud function's
/// write has synced - callers writing diary data should treat an empty
/// value as "not ready yet" rather than a valid key.
String get currentSubjectId => currentUserDocument?.subjectId ?? '';

/// Makes sure the signed-in user has a working subjectId: present on their
/// `users/{uid}` doc AND on their cached ID token's custom claims (Firestore
/// rules check the token claim, not the doc, to own diary_entries/
/// dashboard/health_samples - see firestore.rules). Two gaps this closes
/// that the assignSubjectId onCreate trigger alone doesn't:
///  1. Accounts created before that trigger shipped never got a subjectId
///     at all and are otherwise locked out permanently.
///  2. A brand-new account's cached ID token doesn't carry a claim set
///     moments ago until explicitly refreshed - without forcing that here,
///     the first diary write races Firebase's natural (up to ~1hr) token
///     refresh and gets rejected with permission-denied.
///
/// Safe to call repeatedly - the fast path below (doc and token claim
/// already agree) is a single read with no cloud function round trip or
/// writes. Call this after sign-in/sign-up and once at app startup for a
/// resumed session (see firebase_auth_manager.dart / main.dart), and before
/// any write that depends on currentSubjectId being non-empty.
Future<String> ensureSubjectIdReady() async {
  final user = FirebaseAuth.instance.currentUser;
  if (user == null) return '';

  final userRef = UsersRecord.collection.doc(user.uid);
  final doc = await UsersRecord.getDocumentOnce(userRef);
  final tokenResult = await user.getIdTokenResult();
  final tokenSubjectId = tokenResult.claims?['subjectId'] as String?;

  if (doc.subjectId.isNotEmpty && tokenSubjectId == doc.subjectId) {
    currentUserDocument = doc;
    return doc.subjectId;
  }

  final result = await FirebaseFunctions.instance
      .httpsCallable('ensureSubjectId')
      .call<Map<String, dynamic>>();
  final subjectId = result.data['subjectId'] as String;

  // The claim set above only lands in a freshly-minted ID token - force
  // that now instead of waiting on it to happen naturally.
  await user.getIdToken(true);

  currentUserDocument = await UsersRecord.getDocumentOnce(userRef);
  return subjectId;
}

String get currentUserDisplayName =>
    currentUserDocument?.displayName ?? currentUser?.displayName ?? '';

String get currentUserPhoto =>
    currentUserDocument?.photoUrl ?? currentUser?.photoUrl ?? '';

String get currentPhoneNumber =>
    currentUserDocument?.phoneNumber ?? currentUser?.phoneNumber ?? '';

String get currentJwtToken => _currentJwtToken ?? '';

bool get currentUserEmailVerified => currentUser?.emailVerified ?? false;

/// Create a Stream that listens to the current user's JWT Token, since Firebase
/// generates a new token every hour.
String? _currentJwtToken;
final jwtTokenStream = FirebaseAuth.instance
    .idTokenChanges()
    .map((user) async => _currentJwtToken = await user?.getIdToken())
    .asBroadcastStream();

DocumentReference? get currentUserReference =>
    loggedIn ? UsersRecord.collection.doc(currentUser!.uid) : null;

UsersRecord? currentUserDocument;
final authenticatedUserStream = FirebaseAuth.instance
    .authStateChanges()
    .map<String>((user) => user?.uid ?? '')
    .switchMap(
      (uid) => uid.isEmpty
          ? Stream.value(null)
          : UsersRecord.getDocument(UsersRecord.collection.doc(uid))
              .handleError((_) {}),
    )
    .map((user) {
  currentUserDocument = user;

  return currentUserDocument;
}).asBroadcastStream();

class AuthUserStreamWidget extends StatelessWidget {
  const AuthUserStreamWidget({Key? key, required this.builder})
      : super(key: key);

  final WidgetBuilder builder;

  @override
  Widget build(BuildContext context) => StreamBuilder(
        stream: authenticatedUserStream,
        builder: (context, _) => builder(context),
      );
}
