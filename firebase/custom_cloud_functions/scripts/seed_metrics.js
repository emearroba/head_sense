// One-off seed script for the `metrics` catalog (predictors + outcomes).
// Does NOT touch `headache` or `analgesia` (painkillers) - those already
// exist and stay always-on/free per the app's design.
//
// Usage (from firebase/custom_cloud_functions/):
//   npm install
//   GOOGLE_APPLICATION_CREDENTIALS=/path/to/serviceAccountKey.json node scripts/seed_metrics.js
//
// Safe to re-run: writes are `set(..., {merge: true})` keyed by metricKey,
// so existing docs (including any you've hand-edited) are updated, not
// duplicated or wiped.

const admin = require("firebase-admin");

if (!admin.apps.length) {
  admin.initializeApp({ projectId: "head-sense-1111" });
}

const db = admin.firestore();

// Everything (outcomes AND predictors) is grouped by `domain` now - the
// Track tab and diary section by domain, there's no separate "Predictors"
// bucket in the UI anymore. `isPredictor` is kept on the doc for future
// correlation analysis even though it no longer drives grouping.
const DEFAULTS = {
  scaleMin: 0,
  scaleMax: 10,
  answerType: "scale",
  isPredictor: false,
  isActive: true,
  isFree: false,
  step: 1,
  unit: "",
};

function scale(metricKey, metricLabel, domain, extra = {}) {
  return { metricKey, metricLabel, domain, ...DEFAULTS, ...extra };
}

function boolean(metricKey, metricLabel, domain, extra = {}) {
  return scale(metricKey, metricLabel, domain, {
    scaleMin: 0,
    scaleMax: 1,
    answerType: "boolean",
    isPredictor: true,
    ...extra,
  });
}

function numeric(metricKey, metricLabel, domain, extra = {}) {
  return scale(metricKey, metricLabel, domain, {
    answerType: "numeric",
    isPredictor: true,
    ...extra,
  });
}

function time(metricKey, metricLabel, domain, extra = {}) {
  // Stored as minutes-since-midnight (0-1439) in valueNumber.
  return scale(metricKey, metricLabel, domain, {
    scaleMin: 0,
    scaleMax: 1439,
    answerType: "time",
    isPredictor: true,
    ...extra,
  });
}

const METRICS = [
  // Sensitivities: migraine-canonical sensory symptoms.
  scale("photophobia", "Light sensitivity", "sensitivities"),
  scale("phonophobia", "Sound sensitivity", "sensitivities"),
  scale("osmophobia", "Smell sensitivity", "sensitivities"),
  // Movement sensitivity is NOT here: it already existed as a separate
  // legacy doc (id "movement_sensitivity", metricKey field "kinesophobia")
  // predating this script. We keep that original doc (see
  // LEGACY_DOC_UPDATES below) instead of the duplicate this script used to
  // create at doc id "kinesophobia".

  // Perceptions: vestibular / dissociative symptoms.
  scale("dizziness", "Dizziness", "perceptions"),
  scale("motion_sickness", "Motion sickness", "perceptions"),
  scale("vertigo_external", "Vertigo (room spinning)", "perceptions"),
  scale("vertigo_internal", "Vertigo (you're spinning)", "perceptions"),
  scale("derealisation", "Derealisation (world feels unreal)", "perceptions"),
  scale(
    "depersonalisation",
    "Depersonalisation (detached from self)",
    "perceptions",
  ),

  // Productivity & cognitive
  scale("productivity", "Productivity", "productivity"),
  scale("brain_fog", "Brain fog", "productivity"),
  scale("memory_problems", "Memory problems", "productivity"),
  scale(
    "word_finding_difficulties",
    "Word-finding difficulties",
    "productivity",
  ),
  scale("focus", "Focus", "productivity"),
  scale("tasks_done", "Tasks done", "productivity"),
  scale("mental_clarity", "Mental clarity", "productivity"),

  // Mood & social
  scale("happiness", "Happiness", "mood"),
  scale("elation", "Elation", "mood"),
  scale("laughter", "Laughter", "mood"),
  scale("calm", "Calm", "mood"),
  scale("crying", "Crying", "mood"),
  scale("irritability", "Irritability", "mood"),
  scale("libido", "Libido", "mood"),
  scale("music", "Music enjoyment", "mood"),
  scale("energy", "Energy", "mood"),
  scale("motivation", "Motivation", "mood"),
  scale("sadness", "Sadness", "mood"),
  scale("low_mood", "Low mood", "mood"),
  scale("stress", "Stress", "mood"),

  // Sleep & fatigue
  scale("insomnia", "Insomnia", "sleep_fatigue"),
  scale("restlessness", "Restlessness", "sleep_fatigue"),
  scale("fatigue", "Body tiredness", "sleep_fatigue"),
  scale("yawning", "Yawning", "sleep_fatigue"),
  scale("lethargy", "Sleepy", "sleep_fatigue"),
  scale("poor_sleep_quality", "Poor sleep quality", "sleep_fatigue"),
  numeric("hours_slept", "Hours slept", "sleep_fatigue", {
    scaleMax: 14,
    step: 0.5,
    unit: "hours",
  }),
  time("bed_time", "Bed time", "sleep_fatigue"),
  time("wake_time", "Wake time", "sleep_fatigue"),

  // Gastrointestinal
  scale("nausea", "Nausea", "gi"),
  scale("diarrhoea", "Diarrhoea", "gi"),
  scale("constipation", "Constipation", "gi"),
  scale("bloated", "Bloating", "gi"),
  scale("abdominal_pain", "Stomach discomfort", "gi"),
  scale("gas", "Gas", "gi"),
  scale("stool_quality", "Stool quality (Bristol scale)", "gi", {
    scaleMin: 1,
    scaleMax: 7,
    minLabel: "Type 1 (hard lumps)",
    maxLabel: "Type 7 (watery)",
  }),
  scale("bowel_urgency", "Bowel urgency", "gi"),
  scale("reflux", "Reflux", "gi"),

  // Food, drinks and cravings
  scale("appetite", "Appetite", "food_cravings"),
  scale("crav_sweet", "Sweet cravings", "food_cravings"),
  scale("crav_carbs", "Carb cravings", "food_cravings"),
  scale("crav_salt", "Salt cravings", "food_cravings"),
  scale("crav_fat", "Fatty food cravings", "food_cravings"),
  scale("tobacco", "Tobacco craving", "food_cravings"),
  scale("caffeinated_drinks", "Caffeinated drinks", "food_cravings", {
    isPredictor: true,
    unit: "drinks",
  }),
  scale("alcohol_drinks", "Alcoholic drinks", "food_cravings", {
    isPredictor: true,
    unit: "drinks",
  }),
  numeric("water_intake", "Water intake", "food_cravings", {
    scaleMax: 15,
    unit: "glasses",
  }),
  boolean("late_meal", "Ate a late meal?", "food_cravings"),
  boolean("large_meal", "Ate a large meal?", "food_cravings"),
  boolean("fasting", "Fasted today?", "food_cravings"),
  boolean("skipped_meal", "Skipped a meal today?", "food_cravings"),

  // Genito-urinary
  scale("polyuria", "Frequent urination", "genito_urinary"),
  boolean("on_period", "On your period?", "genito_urinary"),

  // Head and neck symptoms (ENT / musculoskeletal)
  scale("lacrimation", "Watery eyes", "ent_physical"),
  scale("dark_circles", "Dark circles", "ent_physical"),
  scale("red_nose", "Red nose", "ent_physical"),
  scale("rhinorrhoea", "Runny nose", "ent_physical"),
  scale("ear_fullness", "Ear fullness", "ent_physical"),
  scale("tinnitus", "Tinnitus (ringing in ears)", "ent_physical"),
  scale("neck_stiffness", "Neck stiffness", "ent_physical"),
  scale("trismus", "Jaw clenching", "ent_physical"),

  // Physical
  scale("joint_pain", "Joint pain", "physical"),
  scale("muscle_pain", "Muscle pain", "physical"),
  scale("back_pain", "Back pain", "physical"),
  scale("palpitations", "Palpitations", "physical"),
  scale("shortness_of_breath", "Shortness of breath", "physical"),
  scale("weakness", "Weakness", "physical"),
  scale("pins_and_needles", "Pins and needles", "physical"),
  scale("swelling", "Swelling", "physical"),
  scale("illness", "Feeling generally unwell", "physical"),
  scale("skin_breakout", "Skin breakout", "physical"),
  scale("itching", "Itching", "physical"),

  // Exercise
  numeric("steps", "Steps", "exercise", { scaleMax: 30000, step: 500 }),
  boolean("aerobic_exercise", "Did cardio today?", "exercise"),
  boolean("weights", "Lifted weights today?", "exercise"),
].map((m, i) => ({ ...m, order: 100 + i }));

// Superseded by the single "appetite" metric above, or by a legacy doc kept
// under its own id (see LEGACY_DOC_UPDATES) - soft-deleted (kept in
// Firestore, just hidden) rather than removed, in case there's existing
// response data under these keys.
const DEACTIVATED_METRIC_KEYS = ["hungry", "hyporexia", "kinesophobia"];

// Pre-existing docs whose Firestore doc id doesn't match their metricKey
// field, so they can't go through the metricKey-keyed METRICS loop above.
// Only touch the fields we actually mean to change; leave the rest (incl.
// answerType/minLabel/maxLabel/isFree) as originally set.
const LEGACY_DOC_UPDATES = {
  movement_sensitivity: {
    metricLabel: "Sensitivity to head and body movements",
    domain: "sensitivities",
  },
};

async function seed() {
  const batch = db.batch();
  for (const metric of METRICS) {
    const ref = db.collection("metrics").doc(metric.metricKey);
    batch.set(ref, metric, { merge: true });
  }
  for (const metricKey of DEACTIVATED_METRIC_KEYS) {
    const ref = db.collection("metrics").doc(metricKey);
    batch.set(ref, { isActive: false }, { merge: true });
  }
  for (const [docId, updates] of Object.entries(LEGACY_DOC_UPDATES)) {
    const ref = db.collection("metrics").doc(docId);
    batch.set(ref, updates, { merge: true });
  }
  await batch.commit();
  console.log(
    `Seeded ${METRICS.length} metrics, deactivated ${DEACTIVATED_METRIC_KEYS.length}, updated ${Object.keys(LEGACY_DOC_UPDATES).length} legacy doc(s).`,
  );
}

seed()
  .then(() => process.exit(0))
  .catch((err) => {
    console.error(err);
    process.exit(1);
  });
