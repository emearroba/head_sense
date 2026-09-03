const functions = require("firebase-functions");
const admin = require("firebase-admin");

if (!admin.apps.length) {
  admin.initializeApp();
}

const db = admin.firestore();

const PERIODS = [
  { type: "last30", days: 30 },
  { type: "last60", days: 60 },
  { type: "last90", days: 90 },
  { type: "last180", days: 180 },
  { type: "last365", days: 365 },
];

// Cambia esta constante por la key exacta que usas en Firestore para los analgésicos/medicación
const PAINKILLER_METRIC_KEY = "analgesia";

const WEEKDAYS_SHORT = ["Su", "M", "Tu", "W", "Th", "F", "Sa"];

function dateKeyFromDate(date) {
  const year = date.getUTCFullYear();
  const month = String(date.getUTCMonth() + 1).padStart(2, "0");
  const day = String(date.getUTCDate()).padStart(2, "0");
  return `${year}-${month}-${day}`;
}

function getCategory(value) {
  if (value === null || value === undefined || isNaN(value)) return "missing";
  if (value === 0) return "crystal";
  if (value <= 3) return "mild";
  if (value <= 6) return "moderate";
  return "severe";
}

function getBarColor(value) {
  if (value === null || value === undefined || isNaN(value)) {
    return "#7E8AA7";
  }

  const roundedValue = Math.round(Number(value));

  const colors = {
    0: "#4A86C5",
    1: "#4FA8B2",
    2: "#58C1A0",
    3: "#63C66F",
    4: "#7ABA5A",
    5: "#9AB857",
    6: "#C8B562",
    7: "#CB9A61",
    8: "#BE8062",
    9: "#C26746",
    10: "#BD3A31",
  };

  return colors[roundedValue] || "#7E8AA7";
}

function calculateStreaks(dailyValues, categoryName) {
  let current = 0;
  let longest = 0;
  let running = 0;

  for (const day of dailyValues) {
    if (day.category === categoryName) {
      running++;
      longest = Math.max(longest, running);
    } else {
      running = 0;
    }
  }

  for (let i = dailyValues.length - 1; i >= 0; i--) {
    if (dailyValues[i].category === categoryName) {
      current++;
    } else {
      break;
    }
  }

  return { current, longest };
}

// Queries diary_entries + their metricKey/painkiller responses once for
// [periodStart, periodEnd]. Callers covering several shorter periods within
// this range can reuse the same maps instead of re-querying per period -
// see the entryDateMaps param on calculateDashboardForPeriod below.
async function fetchEntryDateMaps({ userRef, metricKey, periodStart, periodEnd }) {
  const entriesSnap = await db
    .collection("diary_entries")
    .where("userRef", "==", userRef)
    .where("entryDate", ">=", admin.firestore.Timestamp.fromDate(periodStart))
    .where("entryDate", "<=", admin.firestore.Timestamp.fromDate(periodEnd))
    .get();

  const valueByDate = new Map();
  const painkillerByDate = new Map();

  // PARALELIZACIÓN: Consultar respuestas del síntoma Y de analgésicos
  const responsePromises = entriesSnap.docs.map(async (doc) => {
    const data = doc.data();
    if (!data.entryDate) return null;

    const dateKey = dateKeyFromDate(data.entryDate.toDate());

    // 1. Obtener respuesta de la métrica actual
    const responseSnap = await doc.ref
      .collection("responses")
      .doc(metricKey)
      .get();

    let numericValue = null;
    if (responseSnap.exists) {
      const val = Number(responseSnap.data().valueNumber);
      if (!isNaN(val)) numericValue = val;
    }

    // 2. Obtener respuesta de analgésicos / analgesia
    const pkSnap = await doc.ref
      .collection("responses")
      .doc(PAINKILLER_METRIC_KEY)
      .get();

    let pkValue = 0;
    if (pkSnap.exists) {
      const val = Number(pkSnap.data().valueNumber);
      if (!isNaN(val) && val > 0) {
        pkValue = val;
      }
    }

    return {
      dateKey,
      value: numericValue,
      painkillerUsed: pkValue > 0,
    };
  });

  const fetchedResponses = await Promise.all(responsePromises);

  for (const item of fetchedResponses) {
    if (item) {
      if (item.value !== null) {
        valueByDate.set(item.dateKey, item.value);
      }
      painkillerByDate.set(item.dateKey, item.painkillerUsed);
    }
  }

  return { valueByDate, painkillerByDate };
}

async function calculateDashboardForPeriod({
  userRef,
  userId,
  metricKey,
  metricLabel,
  metricRef,
  trackingDay,
  periodType,
  periodDays,
  // Optional { valueByDate, painkillerByDate } already covering this
  // period's range (see fetchEntryDateMaps) - pass this when computing
  // several periods for the same user/metric back to back so each one
  // doesn't re-query + re-read the same overlapping diary_entries history.
  entryDateMaps,
}) {
  const now = new Date();
  const periodEnd = new Date(
    Date.UTC(
      now.getUTCFullYear(),
      now.getUTCMonth(),
      now.getUTCDate(),
      23,
      59,
      59,
      999,
    ),
  );

  const periodStart = new Date(periodEnd);
  periodStart.setUTCDate(periodStart.getUTCDate() - (periodDays - 1));
  periodStart.setUTCHours(0, 0, 0, 0);

  const { valueByDate, painkillerByDate } =
    entryDateMaps ??
    (await fetchEntryDateMaps({ userRef, metricKey, periodStart, periodEnd }));

  const dailyValues = [];
  let previousValue = null;

  for (let i = 0; i < periodDays; i++) {
    const currentDate = new Date(periodStart);
    currentDate.setUTCDate(periodStart.getUTCDate() + i);

    const dateKey = dateKeyFromDate(currentDate);

    const dayOfWeekIndex = currentDate.getUTCDay();
    const dayOfWeek = WEEKDAYS_SHORT[dayOfWeekIndex];

    const value = valueByDate.has(dateKey) ? valueByDate.get(dateKey) : null;
    const usedPainkiller = painkillerByDate.get(dateKey) || false;

    const category = getCategory(value);
    const barColor = getBarColor(value);

    let deltaFromPreviousDay = null;
    let isSpike = false;

    if (value !== null && previousValue !== null) {
      deltaFromPreviousDay = value - previousValue;
      isSpike = deltaFromPreviousDay >= 2;
    }

    dailyValues.push({
      day: i + 1,
      date: dateKey,
      dayOfWeek,
      dayOfWeekIndex,
      value,
      barColor,
      category,
      isTracked: value !== null,
      usedPainkiller,
      isCrystal: category === "crystal",
      isMild: category === "mild",
      isModerate: category === "moderate",
      isSevere: category === "severe",
      isMissing: category === "missing",
      deltaFromPreviousDay,
      isSpike,
    });

    if (value !== null) {
      previousValue = value;
    }
  }

  let symptomDays = 0;
  let symptomFreeDays = 0;
  let missingDays = 0;
  let painkillerDays = 0;

  let mildSymptomDays = 0;
  let moderateSymptomDays = 0;
  let severeSymptomDays = 0;

  let symptomBurden = 0;
  let maxIntensity = null;
  let minIntensity = null;

  let spikeCount = 0;
  let spikeMagnitudeTotal = 0;

  for (const day of dailyValues) {
    const value = day.value;

    if (day.usedPainkiller) {
      painkillerDays++;
    }

    if (day.isMissing) {
      missingDays++;
      continue;
    }

    maxIntensity =
      maxIntensity === null ? value : Math.max(maxIntensity, value);
    minIntensity =
      minIntensity === null ? value : Math.min(minIntensity, value);

    if (day.isSpike) {
      spikeCount++;
      spikeMagnitudeTotal += day.deltaFromPreviousDay;
    }

    if (value === 0) {
      symptomFreeDays++;
    } else if (value > 0) {
      symptomDays++;
      symptomBurden += value;

      if (value <= 3) {
        mildSymptomDays++;
      } else if (value <= 6) {
        moderateSymptomDays++;
      } else {
        severeSymptomDays++;
      }
    }
  }

  const daysTracked = symptomDays + symptomFreeDays;

  const completionRate = periodDays > 0 ? daysTracked / periodDays : 0;
  const symptomRate = periodDays > 0 ? symptomDays / periodDays : 0;

  const meanIntensityAllDays = periodDays > 0 ? symptomBurden / periodDays : 0;

  const meanIntensityTrackedDays =
    daysTracked > 0 ? symptomBurden / daysTracked : 0;

  const meanIntensitySymptomDays =
    symptomDays > 0 ? symptomBurden / symptomDays : 0;

  const meanSpikeMagnitude =
    spikeCount > 0 ? spikeMagnitudeTotal / spikeCount : 0;

  const diaryStreak = calculateStreaks(
    dailyValues.map((d) => ({
      ...d,
      category: d.isTracked ? "tracked" : "missing",
    })),
    "tracked",
  );

  const crystalStreak = calculateStreaks(dailyValues, "crystal");
  const mildStreak = calculateStreaks(dailyValues, "mild");
  const moderateStreak = calculateStreaks(dailyValues, "moderate");
  const severeStreak = calculateStreaks(dailyValues, "severe");
  const missingStreak = calculateStreaks(dailyValues, "missing");

  const periodHasEnoughData = completionRate >= 0.8;

  const analysisEligible = completionRate >= 0.8 && spikeCount >= 3;

  const distribution = {
    crystal: symptomFreeDays,
    mild: mildSymptomDays,
    moderate: moderateSymptomDays,
    severe: severeSymptomDays,
    missing: missingDays,
  };

  const dashboardDocId = `${userId}_${metricKey}_${periodType}`;
  const dashboardRef = db.collection("dashboard").doc(dashboardDocId);

  // 1. ESCRIBIR/ACTUALIZAR DOCUMENTO PADRE (Ahora incluye painkillerDays)
  await dashboardRef.set(
    {
      userRef,
      userId,

      metricKey,
      metricLabel,
      metricRef,

      periodType,
      periodStart: admin.firestore.Timestamp.fromDate(periodStart),
      periodEnd: admin.firestore.Timestamp.fromDate(periodEnd),
      periodDays,

      trackingDay,

      dailyValues,

      daysTracked,
      missingDays,
      painkillerDays, // <- Días con uso de analgésicos
      completionRate,

      symptomDays,
      symptomFreeDays,
      symptomRate,

      mildSymptomDays,
      moderateSymptomDays,
      severeSymptomDays,

      distribution,

      symptomBurden,
      meanIntensityAllDays,
      meanIntensityTrackedDays,
      meanIntensitySymptomDays,

      maxIntensity,
      minIntensity,

      spikeCount,
      meanSpikeMagnitude,

      currentDiaryStreak: diaryStreak.current,
      longestDiaryStreak: diaryStreak.longest,

      currentCrystalStreak: crystalStreak.current,
      longestCrystalStreak: crystalStreak.longest,

      currentMildStreak: mildStreak.current,
      longestMildStreak: mildStreak.longest,

      currentModerateStreak: moderateStreak.current,
      longestModerateStreak: moderateStreak.longest,

      currentSevereStreak: severeStreak.current,
      longestSevereStreak: severeStreak.longest,

      currentMissingStreak: missingStreak.current,
      longestMissingStreak: missingStreak.longest,

      periodHasEnoughData,
      analysisEligible,

      calculationVersion: "v7_painkiller_support",
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    },
    { merge: true },
  );

  // 2. PURGAR DOCUMENTOS ANTIGUOS FUERA DE ESTE PERIODO
  const existingSubdocsSnap = await dashboardRef
    .collection("daily_values")
    .get();
  const validDates = new Set(dailyValues.map((d) => d.date));

  const deleteBatch = db.batch();
  let deleteCount = 0;

  existingSubdocsSnap.docs.forEach((doc) => {
    if (!validDates.has(doc.id)) {
      deleteBatch.delete(doc.ref);
      deleteCount++;
    }
  });

  if (deleteCount > 0) {
    await deleteBatch.commit();
  }

  // 3. REGISTRAR / ACTUALIZAR LOS DÍAS DEL PERIODO ACTUAL
  const writeBatch = db.batch();

  for (const day of dailyValues) {
    const dayRef = dashboardRef.collection("daily_values").doc(day.date);

    writeBatch.set(dayRef, day, { merge: true });
  }

  await writeBatch.commit();
}

exports.dateKeyFromDate = dateKeyFromDate;
exports.getCategory = getCategory;
exports.getBarColor = getBarColor;
exports.calculateStreaks = calculateStreaks;
// TEMP (mock-data seeding): exposes the real aggregation logic so a seed
// script can call it directly against the emulator without relying on the
// Functions emulator's onWrite trigger. Safe to remove after seeding.
exports.calculateDashboardForPeriod = calculateDashboardForPeriod;

exports.updateDashboardMetric = functions.firestore
  .document("diary_entries/{entryId}/responses/{metricKey}")
  .onWrite(async (change, context) => {
    const metricKey = context.params.metricKey;
    const entryId = context.params.entryId;

    const entryRef = db.collection("diary_entries").doc(entryId);
    const entrySnap = await entryRef.get();

    if (!entrySnap.exists) return null;

    const entryData = entrySnap.data();
    const userRef = entryData.userRef;

    if (!userRef) return null;

    const userId = userRef.id;

    const metricRef = db.collection("metrics").doc(metricKey);
    const metricSnap = await metricRef.get();

    const metricLabel =
      metricSnap.exists && metricSnap.data().metricLabel
        ? metricSnap.data().metricLabel
        : metricKey;

    // The 0-10 crystal/mild/moderate/severe bucketing below is headache-
    // shaped, but the underlying per-day value/dailyValues computation is
    // generic - it just reads whatever numeric answer was stored. So we
    // still compute a dashboard doc for boolean (0/1) and numeric
    // predictors (aerobic_exercise, hours_slept, ...), which is what lets
    // the Patterns "discoveries" feed find connections to them - the
    // severity-bucket fields (isMild/isSevere/etc.) just won't mean
    // anything for those and are ignored by non-scale consumers.
    // 'time' metrics (bed_time/wake_time, stored as minutes-since-midnight)
    // are excluded: their magnitude doesn't compare meaningfully against
    // other metrics without clock-aware formatting the UI doesn't have yet.
    // Metrics without an answerType (e.g. the original headache metric)
    // are treated as scale for backward compatibility.
    const answerType =
      metricSnap.exists && metricSnap.data().answerType
        ? metricSnap.data().answerType
        : "scale";

    if (answerType === "time") {
      return null;
    }

    const firstEntrySnap = await db
      .collection("diary_entries")
      .where("userRef", "==", userRef)
      .orderBy("entryDate", "asc")
      .limit(1)
      .get();

    let trackingDay = 1;

    if (!firstEntrySnap.empty) {
      const firstEntryDate = firstEntrySnap.docs[0].data().entryDate.toDate();

      const today = new Date();
      today.setUTCHours(23, 59, 59, 999);

      trackingDay =
        Math.floor(
          (today.getTime() - firstEntryDate.getTime()) / (1000 * 60 * 60 * 24),
        ) + 1;

      trackingDay = Math.max(1, trackingDay);
    }

    // Todos los periodos (30/60/90/180/365 días) comparten el mismo tramo
    // final de historial: en vez de que cada uno vuelva a consultar
    // diary_entries + responses desde cero (5 queries + 5x lecturas por
    // entrada para el mismo rango solapado), se consulta una sola vez la
    // ventana más ancha (365 días) y se reutiliza para los 5 - esto es lo
    // que multiplicaba una sola escritura en miles de lecturas/escrituras
    // (ver incidente de facturación del 2026-08-30).
    const widestPeriod = PERIODS.reduce((a, b) => (a.days > b.days ? a : b));
    const nowForWidestPeriod = new Date();
    const widestPeriodEnd = new Date(
      Date.UTC(
        nowForWidestPeriod.getUTCFullYear(),
        nowForWidestPeriod.getUTCMonth(),
        nowForWidestPeriod.getUTCDate(),
        23,
        59,
        59,
        999,
      ),
    );
    const widestPeriodStart = new Date(widestPeriodEnd);
    widestPeriodStart.setUTCDate(
      widestPeriodStart.getUTCDate() - (widestPeriod.days - 1),
    );
    widestPeriodStart.setUTCHours(0, 0, 0, 0);

    const entryDateMaps = await fetchEntryDateMaps({
      userRef,
      metricKey,
      periodStart: widestPeriodStart,
      periodEnd: widestPeriodEnd,
    });

    // PARALELIZACIÓN: Ejecutar el cálculo de los 5 periodos al mismo tiempo
    await Promise.all(
      PERIODS.map((period) =>
        calculateDashboardForPeriod({
          userRef,
          userId,
          metricKey,
          metricLabel,
          metricRef,
          trackingDay,
          periodType: period.type,
          periodDays: period.days,
          entryDateMaps,
        }),
      ),
    );

    return null;
  });
