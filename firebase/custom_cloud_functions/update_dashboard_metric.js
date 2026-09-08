const functions = require("firebase-functions");
const admin = require("firebase-admin");
// Modular import instead of the admin.firestore.Timestamp/FieldValue
// namespace statics - under the Functions Emulator's runtime (older
// firebase-functions + admin SDK combo this project pins), those statics
// come back undefined even though admin.firestore() itself works fine, and
// the trigger below crashes with "Cannot read properties of undefined
// (reading 'fromDate')" on every invocation. This form works in both the
// emulator and deployed.
const { Timestamp, FieldValue } = require("firebase-admin/firestore");

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

// Finds the day a subject's very first diary entry was tracked, to compute
// "day N of tracking". A single limit(1) query regardless of how much
// history exists - O(1), not part of the per-write history rescan this file
// used to do.
async function computeTrackingDay(subjectId) {
  const firstEntrySnap = await db
    .collection("diary_entries")
    .where("subjectId", "==", subjectId)
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

// Builds one dashboard doc's full field set from an already-assembled
// dailyValues array - pure (no Firestore access), so it's the single source
// of truth for the category/streak/spike aggregate math shared by the
// incremental per-write path below AND by dev/test tooling that seeds a
// whole window of synthetic history in one shot (scripts/seed_mock_user.js)
// without wanting to replay hundreds of incremental writes just to get the
// same aggregates.
function buildDashboardDoc({
  subjectId,
  metricKey,
  metricLabel,
  metricRef,
  trackingDay,
  periodType,
  periodDays,
  periodStart,
  periodEnd,
  dailyValues,
}) {
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

  return {
    subjectId,

    metricKey,
    metricLabel,
    metricRef,

    periodType,
    periodStart: Timestamp.fromDate(periodStart),
    periodEnd: Timestamp.fromDate(periodEnd),
    periodDays,

    trackingDay,

    dailyValues,

    daysTracked,
    missingDays,
    painkillerDays,
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

    calculationVersion: "v8_incremental_subjectId",
    updatedAt: FieldValue.serverTimestamp(),
  };
}

// Reads a dashboard/{subjectId}_{metricKey}_{periodType} doc's own prior
// state, splices in the one day that changed, rebuilds the rolling window
// from that in-memory map, hands it to buildDashboardDoc, and writes the
// result back. See buildDashboardDoc's comment for why the aggregate math
// itself lives there instead of here.
//
// Replaces the old approach (re-querying up to `periodDays` diary_entries +
// 2x that many responses sub-reads, for EVERY period, on EVERY answered
// question - see the 2026-08-30 billing incident this caused). Net cost per
// call: 1 read + 1 write, flat regardless of how much history exists.
//
// Known limitation: if this doc doesn't exist yet, the window is rebuilt
// from only the one day passed in - correct for a metric's genuinely first
// answer ever, but means a dashboard doc that got deleted/reset while
// diary_entries history remains would NOT backfill automatically (each
// historical day's write already fired its own onWrite in the past; this
// call only reacts to the day passed in). Not expected in normal operation.
//
// Wrapped in a transaction: read-then-write on the same doc would otherwise
// have a lost-update race if two invocations for the same
// (subjectId, metricKey, periodType) run concurrently (e.g. two questions
// answered back-to-back before the first trigger finishes, or a bulk
// backfill) - confirmed this actually happens under concurrent load while
// testing this change against the emulator. The transaction costs nothing
// extra on the (overwhelmingly common) uncontended path; it only retries
// when there's real contention.
async function updateDashboardDayIncremental({
  subjectId,
  metricKey,
  metricLabel,
  metricRef,
  trackingDay,
  periodType,
  periodDays,
  dateKey,
  newValue,
  usedPainkillerToday,
}) {
  const dashboardDocId = `${subjectId}_${metricKey}_${periodType}`;
  const dashboardRef = db.collection("dashboard").doc(dashboardDocId);

  await db.runTransaction(async (tx) => {
    const existingSnap = await tx.get(dashboardRef);
    const doc = buildDashboardDocForDay({
      existingSnap,
      subjectId,
      metricKey,
      metricLabel,
      metricRef,
      trackingDay,
      periodType,
      periodDays,
      dateKey,
      newValue,
      usedPainkillerToday,
    });
    tx.set(dashboardRef, doc, { merge: true });
  });
}

// The window-splicing part of updateDashboardDayIncremental, pulled out so
// it can run inside db.runTransaction's callback (which Firestore may retry
// on contention - this must stay a pure computation from `existingSnap`,
// with no Firestore reads/writes of its own).
function buildDashboardDocForDay({
  existingSnap,
  subjectId,
  metricKey,
  metricLabel,
  metricRef,
  trackingDay,
  periodType,
  periodDays,
  dateKey,
  newValue,
  usedPainkillerToday,
}) {
  // periodEnd must cover at least `dateKey` (the day actually being
  // written), not just the server's own UTC "today". entryDateKey is
  // stamped client-side from the device's LOCAL calendar day - for a user
  // ahead of UTC (most of Europe/Asia/Australia), "today" on their phone
  // can already be a date the server's UTC clock hasn't reached yet. If
  // periodEnd were pinned to server-UTC-today, the day-enumeration loop
  // below would never produce a slot for that dateKey and the entry would
  // silently vanish from the dashboard until UTC catches up (up to ~14h).
  // Taking the later of the two keeps normal backfills/edits of past days
  // unaffected (their dateKey <= server-UTC-today, so this is a no-op).
  const now = new Date();
  const serverTodayEnd = new Date(
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
  const [entryYear, entryMonth, entryDay] = dateKey.split("-").map(Number);
  const entryDateEnd = new Date(
    Date.UTC(entryYear, entryMonth - 1, entryDay, 23, 59, 59, 999),
  );
  const periodEnd =
    entryDateEnd > serverTodayEnd ? entryDateEnd : serverTodayEnd;
  const periodStart = new Date(periodEnd);
  periodStart.setUTCDate(periodStart.getUTCDate() - (periodDays - 1));
  periodStart.setUTCHours(0, 0, 0, 0);

  // Everything we already know about this metric's history, keyed by date -
  // seeded from the doc's own prior dailyValues (not re-fetched from
  // diary_entries/responses), then patched with the one day that changed.
  const knownByDate = new Map();
  if (existingSnap.exists) {
    const prior = existingSnap.data().dailyValues || [];
    for (const day of prior) {
      knownByDate.set(day.date, day);
    }
  }
  // usedPainkillerToday is optional: the diary-response caller always knows
  // it and passes a real boolean; the health-samples caller has no opinion
  // about painkiller use, so it omits this and whatever was already known
  // for that day (from a prior diary answer) is preserved instead of being
  // clobbered back to false.
  knownByDate.set(dateKey, {
    ...(knownByDate.get(dateKey) || {}),
    value: newValue,
    ...(usedPainkillerToday !== undefined
      ? { usedPainkiller: usedPainkillerToday }
      : {}),
  });

  // Seed the delta calculation with the day immediately before periodStart,
  // not a hardcoded null. Each period (last30/60/90/.../365) rebuilds its
  // window independently, so without this, the first day of every window
  // was structurally unable to register a spike even when the true prior
  // calendar day's value was known - and different-length windows disagreed
  // on the same date's spike status purely because of where their own
  // window happened to start. Because the window is re-anchored to
  // periodEnd on every write and shifts forward by one day between
  // consecutive daily writes, this lookback day is exactly the oldest day
  // the previous stored doc (this same subjectId/metricKey/periodType) had
  // in its own dailyValues, so knownByDate already has it in the common
  // case of day-to-day usage. A real gap (nothing known for that day)
  // correctly falls back to null - consistent with buildDashboardDocForDay
  // never inventing a spike across missing days.
  const dayBeforeStart = new Date(periodStart);
  dayBeforeStart.setUTCDate(dayBeforeStart.getUTCDate() - 1);
  const knownBeforeStart = knownByDate.get(dateKeyFromDate(dayBeforeStart));
  let previousValue =
    knownBeforeStart &&
    knownBeforeStart.value !== null &&
    knownBeforeStart.value !== undefined
      ? knownBeforeStart.value
      : null;

  const dailyValues = [];

  for (let i = 0; i < periodDays; i++) {
    const currentDate = new Date(periodStart);
    currentDate.setUTCDate(periodStart.getUTCDate() + i);
    const dKey = dateKeyFromDate(currentDate);

    const dayOfWeekIndex = currentDate.getUTCDay();
    const dayOfWeek = WEEKDAYS_SHORT[dayOfWeekIndex];

    const known = knownByDate.get(dKey);
    const value =
      known && known.value !== null && known.value !== undefined
        ? known.value
        : null;
    const usedPainkiller = known ? !!known.usedPainkiller : false;

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
      date: dKey,
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

    // Always advance to this day's value (including null for a missing
    // day), rather than only when non-null. Previously a missing day left
    // `previousValue` holding whatever the last-tracked value was, so the
    // next tracked day - possibly a week later - got its delta computed
    // against that stale value and could get flagged as a "spike" purely
    // from the gap, not a real day-over-day jump.
    previousValue = value;
  }

  return buildDashboardDoc({
    subjectId,
    metricKey,
    metricLabel,
    metricRef,
    trackingDay,
    periodType,
    periodDays,
    periodStart,
    periodEnd,
    dailyValues,
  });
}

exports.dateKeyFromDate = dateKeyFromDate;
exports.getCategory = getCategory;
exports.getBarColor = getBarColor;
exports.calculateStreaks = calculateStreaks;
exports.computeTrackingDay = computeTrackingDay;
exports.buildDashboardDoc = buildDashboardDoc;
exports.buildDashboardDocForDay = buildDashboardDocForDay;
exports.updateDashboardDayIncremental = updateDashboardDayIncremental;
exports.WEEKDAYS_SHORT = WEEKDAYS_SHORT;

exports.updateDashboardMetric = functions.firestore
  .document("diary_entries/{entryId}/responses/{metricKey}")
  .onWrite(async (change, context) => {
    const metricKey = context.params.metricKey;
    const entryId = context.params.entryId;

    const entryRef = db.collection("diary_entries").doc(entryId);
    const entrySnap = await entryRef.get();

    if (!entrySnap.exists) return null;

    const entryData = entrySnap.data();
    const subjectId = entryData.subjectId;
    const dateKey = entryData.entryDateKey;

    if (!subjectId || !dateKey) return null;

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

    // Today's new value comes straight off the write event - no read needed
    // for the metric that was actually just answered.
    const afterData = change.after.exists ? change.after.data() : null;
    const rawValue = afterData ? Number(afterData.valueNumber) : NaN;
    const newValue = isNaN(rawValue) ? null : rawValue;

    // Painkiller status for today: already known for free if this write IS
    // the painkiller answer; otherwise one bounded read (not a history
    // rescan) for just today's entry.
    let usedPainkillerToday;
    if (metricKey === PAINKILLER_METRIC_KEY) {
      usedPainkillerToday = newValue !== null && newValue > 0;
    } else {
      const pkSnap = await entryRef
        .collection("responses")
        .doc(PAINKILLER_METRIC_KEY)
        .get();
      const pkValue = pkSnap.exists ? Number(pkSnap.data().valueNumber) : 0;
      usedPainkillerToday = !isNaN(pkValue) && pkValue > 0;
    }

    const trackingDay = await computeTrackingDay(subjectId);

    await Promise.all(
      PERIODS.map((period) =>
        updateDashboardDayIncremental({
          subjectId,
          metricKey,
          metricLabel,
          metricRef,
          trackingDay,
          periodType: period.type,
          periodDays: period.days,
          dateKey,
          newValue,
          usedPainkillerToday,
        }),
      ),
    );

    return null;
  });
