const functions = require("firebase-functions");
const admin = require("firebase-admin");
const crypto = require("crypto");

if (!admin.apps.length) {
  admin.initializeApp();
}

const db = admin.firestore();

// Shared by both the onCreate trigger below (brand-new accounts) and the
// ensureSubjectId callable (accounts created before this migration shipped,
// which onCreate never ran for, plus repair if a prior attempt only got as
// far as the claim or only as far as the doc write). Idempotent: reuses an
// existing subjectId already on the user doc instead of minting a second
// one, so calling this more than once for the same uid never orphans
// previously-written diary data from an earlier subjectId.
async function ensureSubjectIdForUser(uid) {
  const userRef = db.collection("users").doc(uid);
  const snap = await userRef.get();
  const existing = snap.exists ? snap.data().subjectId : undefined;
  const subjectId = existing || crypto.randomUUID();

  await Promise.all([
    admin.auth().setCustomUserClaims(uid, { subjectId }),
    userRef.set({ subjectId }, { merge: true }),
  ]);

  return subjectId;
}

// Assigns a random, opaque subjectId to every new account, once. Stored two
// places:
//  - users/{uid}.subjectId - the client's source of truth (it already fetches
//    this doc for trackedMetricKeys etc., so no new read is needed to use
//    it).
//  - a custom claim on the ID token (request.auth.token.subjectId) - lets
//    Firestore rules check ownership of the pseudonymous clinical
//    collections (diary_entries, dashboard, health_samples) without an
//    extra get() read per request.
//
// Deliberately NOT stored as a reference back to users/{uid} on the clinical
// side - the linkage from a diary_entries/dashboard/health_samples doc back
// to a named person only exists by cross-referencing FROM the identified
// side (this doc, gated by the owner's own auth), not by embedding a pointer
// on every clinical document someone with read access might open directly.
//
// This trigger alone doesn't cover accounts that existed before this
// function was deployed (onCreate only ever fires once, at creation time) -
// see the ensureSubjectId callable below for those.
exports.assignSubjectId = functions.auth.user().onCreate(async (user) => {
  await ensureSubjectIdForUser(user.uid);
});

// Callable the client invokes (see ensureSubjectIdReady in auth_util.dart)
// right after sign-in/sign-up and once at app startup for a resumed
// session. Covers two gaps the onCreate trigger alone leaves:
//  1. Backfill - accounts created before this migration shipped never had
//     onCreate fire for them, so without this they're permanently locked
//     out of diary_entries/dashboard/health_samples (firestore.rules checks
//     request.auth.token.subjectId, which they'd never have).
//  2. The token-refresh race - a brand-new ID token doesn't carry a custom
//     claim set moments ago until the client explicitly refreshes it
//     (Firebase only does that naturally on its own up-to-~1hr cycle). The
//     client calls this, then forces a refresh, instead of waiting on that.
// Safe to call unconditionally and repeatedly - idempotent per user, and
// cheap (one read, and only writes when something is actually missing -
// see the client-side fast path in ensureSubjectIdReady that skips calling
// this at all once both the doc and the token claim already agree).
exports.ensureSubjectId = functions.https.onCall(async (data, context) => {
  if (!context.auth) {
    throw new functions.https.HttpsError(
      "unauthenticated",
      "Must be signed in to request a subjectId."
    );
  }
  const subjectId = await ensureSubjectIdForUser(context.auth.uid);
  return { subjectId };
});
