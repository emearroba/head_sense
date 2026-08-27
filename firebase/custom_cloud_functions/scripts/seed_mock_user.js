// Seeds a mock HeadSense user with 90 days of diary history (with some
// missing days) across the 30 variables currently active in the real
// account's Track tab, plus the always-on headache_intensity + analgesia.
//
// Targets the FIRESTORE_EMULATOR_HOST / FIREBASE_AUTH_EMULATOR_HOST
// emulators only - never touches production. `node_modules` for
// firebase-admin is resolved from firebase/custom_cloud_functions/, so run
// this with that directory as cwd (module resolution for `require` itself
// is based on this file's own path, handled via the absolute path below).
//
// Usage (from firebase/custom_cloud_functions/):
//   FIRESTORE_EMULATOR_HOST=localhost:8080 \
//   FIREBASE_AUTH_EMULATOR_HOST=localhost:9099 \
//   node <path to this file>

const path = require("path");
const admin = require("firebase-admin");

if (!admin.apps.length) {
  admin.initializeApp({ projectId: "head-sense-1111" });
}

const db = admin.firestore();
const authAdmin = admin.auth();

// Reuses the REAL aggregation logic (temporarily exported) so the
// `dashboard` docs the app reads are byte-for-byte what the deployed
// Cloud Function would have produced.
const {
  dateKeyFromDate,
  calculateDashboardForPeriod,
} = require(path.join(
  "C:\\Users\\jmsej\\HeadSense\\head_sense\\firebase\\custom_cloud_functions",
  "update_dashboard_metric.js",
));

const MOCK_EMAIL = "mock.90day@headsense.test";
const MOCK_PASSWORD = "MockUser90Days!";

// ---- The 30 variables toggled ON in Track right now (read off the live
// UI), plus the 2 always-on ones. answerType drives both the value shape
// and whether a `dashboard` doc gets computed (only 'scale' metrics do -
// matches the real trigger's `if (answerType !== 'scale') return;` guard).
const METRICS = [
  { key: "headache_intensity", label: "Headache", type: "scale", docId: "headache_intensity" },
  { key: "analgesia", label: "Painkillers", type: "scale", docId: "analgesia" },
  { key: "kinesophobia", label: "Sensitivity to head and body movements", type: "scale", docId: "movement_sensitivity" },
  { key: "vertigo_external", label: "Vertigo (room spinning)", type: "scale" },
  { key: "productivity", label: "Productivity", type: "scale" },
  { key: "tasks_done", label: "Tasks done", type: "scale" },
  { key: "mental_clarity", label: "Mental clarity", type: "scale" },
  { key: "libido", label: "Libido", type: "scale" },
  { key: "music", label: "Music enjoyment", type: "scale" },
  { key: "low_mood", label: "Low mood", type: "scale" },
  { key: "stress", label: "Stress", type: "scale" },
  { key: "poor_sleep_quality", label: "Poor sleep quality", type: "scale" },
  { key: "abdominal_pain", label: "Stomach discomfort", type: "scale" },
  { key: "stool_quality", label: "Stool quality (Bristol scale)", type: "scale", min: 1, max: 7 },
  { key: "bowel_urgency", label: "Bowel urgency", type: "scale" },
  { key: "tobacco", label: "Tobacco craving", type: "scale" },
  { key: "polyuria", label: "Frequent urination", type: "scale" },
  { key: "trismus", label: "Jaw clenching", type: "scale" },
  { key: "joint_pain", label: "Joint pain", type: "scale" },
  { key: "palpitations", label: "Palpitations", type: "scale" },
  { key: "illness", label: "Feeling generally unwell", type: "scale" },
  { key: "skin_breakout", label: "Skin breakout", type: "scale" },
  { key: "hours_slept", label: "Hours slept", type: "numeric" },
  { key: "alcohol_drinks", label: "Alcoholic drinks", type: "numeric" },
  { key: "water_intake", label: "Water intake", type: "numeric" },
  { key: "bed_time", label: "Bed time", type: "time" },
  { key: "wake_time", label: "Wake time", type: "time" },
  { key: "late_meal", label: "Ate a late meal?", type: "boolean" },
  { key: "large_meal", label: "Ate a large meal?", type: "boolean" },
  { key: "fasting", label: "Fasted today?", type: "boolean" },
  { key: "skipped_meal", label: "Skipped a meal today?", type: "boolean" },
  { key: "on_period", label: "On your period?", type: "boolean" },
];

const TRACKED_KEYS = METRICS.filter(
  (m) => m.key !== "headache_intensity" && m.key !== "analgesia",
).map((m) => m.key);

const TOTAL_DAYS = 90;
// 9 missing days (~10%): a 3-day cluster (life got busy) + scattered
// single misses, none right at the very start/end.
const MISSING_DAY_INDEXES = new Set([5, 6, 7, 20, 38, 50, 64, 77, 86]);

const PERIODS = [
  { type: "last30", days: 30 },
  { type: "last60", days: 60 },
  { type: "last90", days: 90 },
  { type: "last180", days: 180 },
  { type: "last365", days: 365 },
];

function randInt(min, max) {
  return Math.floor(Math.random() * (max - min + 1)) + min;
}
function clamp(v, min, max) {
  return Math.max(min, Math.min(max, v));
}
function skewedLow() {
  const r = Math.random();
  if (r < 0.5) return 0;
  if (r < 0.8) return randInt(1, 3);
  if (r < 0.95) return randInt(4, 6);
  return randInt(7, 10);
}
function skewedHigh() {
  const r = Math.random();
  if (r < 0.4) return randInt(6, 9);
  if (r < 0.7) return randInt(3, 6);
  if (r < 0.9) return randInt(1, 3);
  return 0;
}
function roundHalf(v) {
  return Math.round(v * 2) / 2;
}

function utcDaysAgo(n) {
  const now = new Date();
  return new Date(
    Date.UTC(now.getUTCFullYear(), now.getUTCMonth(), now.getUTCDate() - n, 12, 0, 0),
  );
}

function generateDayValues(state, isPeriodDay) {
  const stress = clamp(
    Math.round(state.prevStress * 0.5 + Math.random() * 10 * 0.5 + (isPeriodDay ? 1 : 0)),
    0,
    10,
  );
  const poorSleep = clamp(
    Math.round(state.prevSleep * 0.5 + Math.random() * 10 * 0.5),
    0,
    10,
  );
  const noise = randInt(-2, 2);
  const headache = clamp(
    Math.round(1 + 0.45 * stress + 0.4 * poorSleep + (isPeriodDay ? 2 : 0) + noise),
    0,
    10,
  );
  const analgesia = headache >= 5 ? randInt(1, 3) : Math.random() < 0.05 ? 1 : 0;

  const values = {
    headache_intensity: headache,
    analgesia,
    stress,
    poor_sleep_quality: poorSleep,
    productivity: clamp(Math.round(8 - 0.5 * headache + randInt(-2, 2)), 0, 10),
    mental_clarity: clamp(Math.round(8 - 0.45 * headache + randInt(-2, 2)), 0, 10),
    tasks_done: clamp(Math.round(7 - 0.4 * headache + randInt(-2, 2)), 0, 10),
    libido: clamp(Math.round(5 - 0.3 * headache + randInt(-2, 2)), 0, 10),
    music: skewedHigh(),
    low_mood: clamp(Math.round(1 + 0.35 * headache + randInt(-2, 2)), 0, 10),
    kinesophobia: clamp(Math.round(0.6 * headache + randInt(-1, 2)), 0, 10),
    vertigo_external: clamp(Math.round(0.4 * headache + randInt(-1, 2)), 0, 10),
    abdominal_pain: skewedLow(),
    stool_quality: randInt(1, 7),
    bowel_urgency: skewedLow(),
    tobacco: skewedLow(),
    polyuria: skewedLow(),
    trismus: clamp(Math.round(0.5 * stress + randInt(-1, 2)), 0, 10),
    joint_pain: skewedLow(),
    palpitations: skewedLow(),
    illness: skewedLow(),
    skin_breakout: skewedLow(),
    hours_slept: clamp(roundHalf(9 - poorSleep * 0.35 + (Math.random() * 2 - 1)), 4, 9.5),
    alcohol_drinks: Math.random() < 0.25 ? randInt(1, 4) : 0,
    water_intake: roundHalf(1 + Math.random() * 3),
    bed_time: randInt(1320, 1439),
    wake_time: randInt(390, 540),
    late_meal: Math.random() < 0.25 ? 1 : 0,
    large_meal: Math.random() < 0.2 ? 1 : 0,
    fasting: Math.random() < 0.05 ? 1 : 0,
    skipped_meal: Math.random() < 0.15 ? 1 : 0,
    on_period: isPeriodDay ? 1 : 0,
  };

  state.prevStress = stress;
  state.prevSleep = poorSleep;
  return values;
}

async function commitInChunks(ops) {
  const CHUNK = 450;
  for (let i = 0; i < ops.length; i += CHUNK) {
    const batch = db.batch();
    for (const op of ops.slice(i, i + CHUNK)) {
      batch.set(op.ref, op.data, { merge: true });
    }
    await batch.commit();
    console.log(`  committed ${Math.min(i + CHUNK, ops.length)}/${ops.length} writes`);
  }
}

async function main() {
  console.log("Creating mock Auth user...");
  let userRecord;
  try {
    userRecord = await authAdmin.getUserByEmail(MOCK_EMAIL);
    console.log(`  already exists: ${userRecord.uid}`);
  } catch (e) {
    userRecord = await authAdmin.createUser({
      email: MOCK_EMAIL,
      password: MOCK_PASSWORD,
      emailVerified: true,
      displayName: "Mock 90-Day User",
    });
    console.log(`  created: ${userRecord.uid}`);
  }
  const uid = userRecord.uid;
  const userRef = db.collection("users").doc(uid);

  const cycleOffset = randInt(0, 27);
  const state = { prevStress: 4, prevSleep: 4 };

  const ops = [];
  let lastCompletedDateKey = "";
  let trailingStreak = 0;

  for (let i = 0; i < TOTAL_DAYS; i++) {
    const date = utcDaysAgo(TOTAL_DAYS - 1 - i);
    const dateKey = dateKeyFromDate(date);
    const isMissing = MISSING_DAY_INDEXES.has(i);

    if (isMissing) {
      trailingStreak = 0;
      continue;
    }

    const cycleDay = (i + cycleOffset) % 28;
    const isPeriodDay = cycleDay < 5;
    const values = generateDayValues(state, isPeriodDay);

    const entryRef = db.collection("diary_entries").doc(`${uid}_${dateKey}`);
    ops.push({
      ref: entryRef,
      data: {
        entryDate: admin.firestore.Timestamp.fromDate(date),
        entryDateKey: dateKey,
        isComplete: true,
        userRef,
        completedAt: admin.firestore.Timestamp.fromDate(date),
        coinsEarned: 0,
      },
    });

    for (const metric of METRICS) {
      const value = values[metric.key];
      ops.push({
        ref: entryRef.collection("responses").doc(metric.key),
        data: {
          metricKey: metric.key,
          metricLabel: metric.label,
          valueNumber: value,
          capturedAt: admin.firestore.Timestamp.fromDate(date),
        },
      });
    }

    lastCompletedDateKey = dateKey;
    trailingStreak++;
  }

  console.log(`Writing ${ops.length} documents (diary_entries + responses)...`);
  await commitInChunks(ops);

  console.log("Writing users/{uid} doc...");
  await userRef.set(
    {
      uid,
      email: MOCK_EMAIL,
      display_name: "Mock 90-Day User",
      plan: "premium",
      studyParticipant: false,
      timezoneName: "Europe/Madrid",
      created_time: admin.firestore.Timestamp.fromDate(utcDaysAgo(TOTAL_DAYS - 1)),
      coins: 240,
      currentStreak: trailingStreak,
      lastDiaryCompletedDateKey: lastCompletedDateKey,
      trackedMetricKeys: TRACKED_KEYS,
      milestoneCoinsClaimed: 0,
      reminder_active: false,
    },
    { merge: true },
  );

  console.log("Computing dashboard aggregates (real Cloud Function logic, called directly)...");
  const scaleMetrics = METRICS.filter((m) => m.type === "scale");
  let done = 0;
  for (const metric of scaleMetrics) {
    for (const period of PERIODS) {
      await calculateDashboardForPeriod({
        userRef,
        userId: uid,
        metricKey: metric.key,
        metricLabel: metric.label,
        metricRef: db.collection("metrics").doc(metric.docId || metric.key),
        trackingDay: TOTAL_DAYS,
        periodType: period.type,
        periodDays: period.days,
      });
      done++;
    }
    console.log(`  ${metric.key} done (${done}/${scaleMetrics.length * PERIODS.length})`);
  }

  console.log("\nDone.");
  console.log(`UID: ${uid}`);
  console.log(`Email: ${MOCK_EMAIL}`);
  console.log(`Password: ${MOCK_PASSWORD}`);
  console.log(`Days written: ${TOTAL_DAYS - MISSING_DAY_INDEXES.size} / ${TOTAL_DAYS}`);
}

main()
  .then(() => process.exit(0))
  .catch((err) => {
    console.error(err);
    process.exit(1);
  });
