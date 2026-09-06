// Script de un solo uso: da de alta en la colección `metrics` los 3
// metricKeys que alimenta aggregate_health_samples.js, para que aparezcan
// en los pickers de "Track your variables"/"Connections" igual que
// cualquier otro predictor (aerobic_exercise, hours_slept, ...).
//
// Uso:
//   cd firebase/custom_cloud_functions
//   GOOGLE_APPLICATION_CREDENTIALS=<ruta a tu service account> node seed_health_metrics.js
// (o, contra el emulador: FIRESTORE_EMULATOR_HOST=localhost:8080 node seed_health_metrics.js)
//
// Idempotente: usa el metricKey como id del doc y `merge: true`, así que
// se puede volver a correr sin duplicar ni pisar campos no listados aquí.

const admin = require("firebase-admin");

if (!admin.apps.length) {
  admin.initializeApp();
}

const db = admin.firestore();

const METRICS = [
  {
    metricKey: "health_sleep_hours",
    metricLabel: "Sleep (hours)",
    domain: "sleep",
    answerType: "numeric",
    unit: "hours",
    isPredictor: true,
    isActive: true,
    isFree: true,
    description: "Hours asleep, synced automatically from Apple Health / Health Connect.",
  },
  {
    metricKey: "health_steps",
    metricLabel: "Steps",
    domain: "activity",
    answerType: "numeric",
    unit: "steps",
    isPredictor: true,
    isActive: true,
    isFree: true,
    description: "Daily step count, synced automatically from Apple Health / Health Connect.",
  },
  {
    metricKey: "health_resting_hr",
    metricLabel: "Resting heart rate",
    domain: "cardiovascular",
    answerType: "numeric",
    unit: "bpm",
    isPredictor: true,
    isActive: true,
    isFree: true,
    description: "Resting heart rate, synced automatically from Apple Health / Health Connect.",
  },
];

async function seed() {
  const batch = db.batch();
  for (const metric of METRICS) {
    const ref = db.collection("metrics").doc(metric.metricKey);
    batch.set(ref, metric, { merge: true });
  }
  await batch.commit();
  console.log(`Seeded ${METRICS.length} metrics: ${METRICS.map((m) => m.metricKey).join(", ")}`);
}

seed()
  .then(() => process.exit(0))
  .catch((err) => {
    console.error(err);
    process.exit(1);
  });
