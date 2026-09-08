const functions = require("firebase-functions");
const admin = require("firebase-admin");
// See the comment on this same import in update_dashboard_metric.js - the
// admin.firestore.Timestamp/FieldValue namespace statics come back
// undefined under the Functions Emulator's runtime for this project's
// firebase-functions/admin SDK version combo; the modular import works in
// both the emulator and deployed.
const { Timestamp } = require("firebase-admin/firestore");

if (!admin.apps.length) {
  admin.initializeApp();
}

const db = admin.firestore();

const {
  dateKeyFromDate,
  computeTrackingDay,
  updateDashboardDayIncremental,
} = require("./update_dashboard_metric.js");

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

// Collapses just ONE day's samples of `type` into a single value - a
// bounded, date-range-scoped query (at most however many samples one device
// produced in a day), not a rescan of the whole tracked history. Mirrors
// what buildValueByDate used to do across the entire widest period at once.
async function buildTodayValue({ subjectId, type, aggregate, transform, dateKey }) {
  const dayStart = new Date(`${dateKey}T00:00:00.000Z`);
  const dayEnd = new Date(`${dateKey}T23:59:59.999Z`);

  const samplesSnap = await db
    .collection("subjects")
    .doc(subjectId)
    .collection("health_samples")
    .where("type", "==", type)
    .where("startDate", ">=", Timestamp.fromDate(dayStart))
    .where("startDate", "<=", Timestamp.fromDate(dayEnd))
    .get();

  const values = samplesSnap.docs
    .map((doc) => doc.data().value)
    .filter((v) => typeof v === "number" && !isNaN(v));

  if (values.length === 0) return null;

  const collapsed =
    aggregate === "avg"
      ? values.reduce((a, b) => a + b, 0) / values.length
      : values.reduce((a, b) => a + b, 0);

  return transform(collapsed);
}

exports.aggregateHealthSamples = functions.firestore
  .document("subjects/{subjectId}/health_samples/{sampleId}")
  .onWrite(async (change, context) => {
    const { subjectId } = context.params;

    const sampleData = change.after.exists ? change.after.data() : change.before.data();
    if (!sampleData || !sampleData.startDate) return null;

    const config = HEALTH_TYPE_CONFIG[sampleData.type];
    if (!config) return null; // tipo de muestra que aún no mapeamos a un metricKey

    const metricRef = db.collection("metrics").doc(config.metricKey);
    const dateKey = dateKeyFromDate(sampleData.startDate.toDate());

    const [trackingDay, newValue] = await Promise.all([
      computeTrackingDay(subjectId),
      buildTodayValue({
        subjectId,
        type: sampleData.type,
        aggregate: config.aggregate,
        transform: config.transform,
        dateKey,
      }),
    ]);

    // updateDashboardDayIncremental es agnóstica a la fuente de los datos -
    // se reutiliza tal cual, sin duplicar el cálculo de ventanas/rachas.
    // usedPainkillerToday se omite a propósito (no undefined -> false): un
    // sample de wearable no dice nada sobre uso de analgésicos, así que no
    // debe pisar lo que el diario ya haya registrado ese día.
    await Promise.all(
      PERIODS.map((period) =>
        updateDashboardDayIncremental({
          subjectId,
          metricKey: config.metricKey,
          metricLabel: config.metricLabel,
          metricRef,
          trackingDay,
          periodType: period.type,
          periodDays: period.days,
          dateKey,
          newValue,
        }),
      ),
    );

    return null;
  });
