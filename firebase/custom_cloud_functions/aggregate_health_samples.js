const functions = require("firebase-functions");
const admin = require("firebase-admin");

if (!admin.apps.length) {
  admin.initializeApp();
}

const db = admin.firestore();

const { calculateDashboardForPeriod, dateKeyFromDate } = require("./update_dashboard_metric.js");

// Mismas 5 ventanas que update_dashboard_metric.js (no se reexporta esa
// constante desde ahí para no tocar ese archivo - si cambian las ventanas
// del dashboard de síntomas, replicar el cambio aquí).
const PERIODS = [
  { type: "last30", days: 30 },
  { type: "last60", days: 60 },
  { type: "last90", days: 90 },
  { type: "last180", days: 180 },
  { type: "last365", days: 365 },
];

// type de HealthDataType (health_sync_service.dart) -> metricKey del
// catálogo `metrics` + cómo colapsar varias muestras del mismo día en un
// solo valor diario. `transform` pasa el valor crudo (tal como llega de
// HealthKit/Health Connect, ya en la unidad nativa del paquete `health`) a
// la unidad que se le muestra al usuario.
const HEALTH_TYPE_CONFIG = {
  SLEEP_ASLEEP: {
    metricKey: "health_sleep_hours",
    metricLabel: "Sleep (hours)",
    aggregate: "sum",
    // SLEEP_ASLEEP llega en minutos (ver health_data_point.dart del
    // paquete `health`) - lo pasamos a horas.
    transform: (minutes) => minutes / 60,
  },
  STEPS: {
    metricKey: "health_steps",
    metricLabel: "Steps",
    aggregate: "sum",
    transform: (steps) => steps,
  },
  RESTING_HEART_RATE: {
    metricKey: "health_resting_hr",
    metricLabel: "Resting heart rate",
    aggregate: "avg",
    transform: (bpm) => bpm,
  },
};

async function computeTrackingDay(userRef) {
  const firstEntrySnap = await db
    .collection("diary_entries")
    .where("userRef", "==", userRef)
    .orderBy("entryDate", "asc")
    .limit(1)
    .get();

  if (firstEntrySnap.empty) return 1;

  const firstEntryDate = firstEntrySnap.docs[0].data().entryDate.toDate();
  const today = new Date();
  today.setUTCHours(23, 59, 59, 999);

  const trackingDay =
    Math.floor((today.getTime() - firstEntryDate.getTime()) / (1000 * 60 * 60 * 24)) + 1;

  return Math.max(1, trackingDay);
}

// Agrupa las muestras crudas de `health_samples` (un `type` concreto) por
// día local (dateKeyFromDate) y las colapsa según `aggregate` - análogo a
// fetchEntryDateMaps() en update_dashboard_metric.js, pero leyendo de
// health_samples en vez de diary_entries/responses.
async function buildValueByDate({ userId, type, aggregate, transform, periodStart, periodEnd }) {
  const samplesSnap = await db
    .collection("users")
    .doc(userId)
    .collection("health_samples")
    .where("type", "==", type)
    .where("startDate", ">=", admin.firestore.Timestamp.fromDate(periodStart))
    .where("startDate", "<=", admin.firestore.Timestamp.fromDate(periodEnd))
    .get();

  const rawValuesByDate = new Map();

  samplesSnap.docs.forEach((doc) => {
    const data = doc.data();
    if (!data.startDate || typeof data.value !== "number") return;

    const dateKey = dateKeyFromDate(data.startDate.toDate());
    const list = rawValuesByDate.get(dateKey) ?? [];
    list.push(data.value);
    rawValuesByDate.set(dateKey, list);
  });

  const valueByDate = new Map();
  for (const [dateKey, values] of rawValuesByDate.entries()) {
    const collapsed =
      aggregate === "avg"
        ? values.reduce((a, b) => a + b, 0) / values.length
        : values.reduce((a, b) => a + b, 0);
    valueByDate.set(dateKey, transform(collapsed));
  }

  return valueByDate;
}

exports.aggregateHealthSamples = functions.firestore
  .document("users/{userId}/health_samples/{sampleId}")
  .onWrite(async (change, context) => {
    const { userId } = context.params;

    const sampleData = change.after.exists ? change.after.data() : change.before.data();
    if (!sampleData) return null;

    const config = HEALTH_TYPE_CONFIG[sampleData.type];
    if (!config) return null; // tipo de muestra que aún no mapeamos a un metricKey

    const userRef = db.collection("users").doc(userId);
    const metricRef = db.collection("metrics").doc(config.metricKey);

    const trackingDay = await computeTrackingDay(userRef);

    const widestPeriod = PERIODS.reduce((a, b) => (a.days > b.days ? a : b));
    const periodEnd = new Date();
    periodEnd.setUTCHours(23, 59, 59, 999);
    const periodStart = new Date(periodEnd);
    periodStart.setUTCDate(periodStart.getUTCDate() - (widestPeriod.days - 1));
    periodStart.setUTCHours(0, 0, 0, 0);

    const valueByDate = await buildValueByDate({
      userId,
      type: sampleData.type,
      aggregate: config.aggregate,
      transform: config.transform,
      periodStart,
      periodEnd,
    });

    // calculateDashboardForPeriod es agnóstica a la fuente de los datos
    // (ver update_dashboard_metric.js) - se reutiliza tal cual, sin
    // duplicar el cálculo de ventanas/rachas/streaks.
    await Promise.all(
      PERIODS.map((period) =>
        calculateDashboardForPeriod({
          userRef,
          userId,
          metricKey: config.metricKey,
          metricLabel: config.metricLabel,
          metricRef,
          trackingDay,
          periodType: period.type,
          periodDays: period.days,
          entryDateMaps: { valueByDate, painkillerByDate: new Map() },
        }),
      ),
    );

    return null;
  });
