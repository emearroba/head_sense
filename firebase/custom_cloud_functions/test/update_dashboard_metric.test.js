const test = require("node:test");
const assert = require("node:assert/strict");

const {
  dateKeyFromDate,
  getCategory,
  getBarColor,
  calculateStreaks,
  buildDashboardDocForDay,
} = require("../update_dashboard_metric.js");

test("dateKeyFromDate formats as yyyy-mm-dd with zero padding, in UTC", () => {
  assert.equal(
    dateKeyFromDate(new Date(Date.UTC(2026, 0, 5, 23, 59, 59))),
    "2026-01-05",
  );
  assert.equal(
    dateKeyFromDate(new Date(Date.UTC(2026, 11, 31))),
    "2026-12-31",
  );
});

test("getCategory classifies missing values", () => {
  assert.equal(getCategory(null), "missing");
  assert.equal(getCategory(undefined), "missing");
  assert.equal(getCategory(NaN), "missing");
});

test("getCategory classifies severity bands at their boundaries", () => {
  assert.equal(getCategory(0), "crystal");
  assert.equal(getCategory(3), "mild");
  assert.equal(getCategory(3.5), "moderate");
  assert.equal(getCategory(6), "moderate");
  assert.equal(getCategory(6.5), "severe");
  assert.equal(getCategory(10), "severe");
});

test("getBarColor returns the mapped color for each rounded intensity 0-10", () => {
  assert.equal(getBarColor(0), "#4A86C5");
  assert.equal(getBarColor(3.4), "#63C66F"); // rounds to 3
  assert.equal(getBarColor(10), "#BD3A31");
});

test("getBarColor falls back to gray for missing or out-of-range values", () => {
  assert.equal(getBarColor(null), "#7E8AA7");
  assert.equal(getBarColor(undefined), "#7E8AA7");
  assert.equal(getBarColor(NaN), "#7E8AA7");
  assert.equal(getBarColor(11), "#7E8AA7");
});

test("calculateStreaks finds the longest run and the current trailing run", () => {
  const days = [
    { category: "mild" },
    { category: "severe" },
    { category: "severe" },
    { category: "severe" },
    { category: "mild" },
    { category: "severe" },
    { category: "severe" },
  ];

  const result = calculateStreaks(days, "severe");

  assert.equal(result.longest, 3);
  assert.equal(result.current, 2);
});

test("calculateStreaks returns zero when the category never occurs", () => {
  const days = [{ category: "mild" }, { category: "moderate" }];

  assert.deepEqual(calculateStreaks(days, "severe"), {
    current: 0,
    longest: 0,
  });
});

test("calculateStreaks treats an unbroken run of matches as both current and longest", () => {
  const days = [
    { category: "crystal" },
    { category: "crystal" },
    { category: "crystal" },
  ];

  assert.deepEqual(calculateStreaks(days, "crystal"), {
    current: 3,
    longest: 3,
  });
});

test("buildDashboardDocForDay includes dateKey's day even when it is ahead of the server's own UTC today (timezone-ahead-of-UTC user)", () => {
  // Simulates a user whose local calendar day (what entryDateKey is
  // stamped from) has already rolled over past the server's UTC date -
  // true for anyone in a positive UTC offset around their local midnight.
  const futureDateKey = "2099-12-31";

  const doc = buildDashboardDocForDay({
    existingSnap: { exists: false },
    subjectId: "subj1",
    metricKey: "headache",
    metricLabel: "Headache",
    metricRef: "metrics/headache",
    trackingDay: 1,
    periodType: "last30",
    periodDays: 30,
    dateKey: futureDateKey,
    newValue: 7,
    usedPainkillerToday: false,
  });

  const lastDay = doc.dailyValues[doc.dailyValues.length - 1];
  assert.equal(
    lastDay.date,
    futureDateKey,
    "the day just written must be the window's last slot, not silently dropped",
  );
  assert.equal(lastDay.value, 7);
  assert.equal(lastDay.isTracked, true);
});

test("buildDashboardDocForDay does not flag a spike across a gap of missing days", () => {
  const today = new Date();
  const dateKeyForOffset = (daysAgo) => {
    const d = new Date(
      Date.UTC(today.getUTCFullYear(), today.getUTCMonth(), today.getUTCDate()),
    );
    d.setUTCDate(d.getUTCDate() - daysAgo);
    return dateKeyFromDate(d);
  };

  // 4 days ago had a tracked value of 2; the 3 days since (including
  // yesterday) were never logged; today's value is 5, a +3 jump from the
  // last tracked value but with a 3-day gap in between - not a real
  // day-over-day spike.
  const existingSnap = {
    exists: true,
    data: () => ({
      dailyValues: [{ date: dateKeyForOffset(4), value: 2 }],
    }),
  };

  const doc = buildDashboardDocForDay({
    existingSnap,
    subjectId: "subj1",
    metricKey: "headache",
    metricLabel: "Headache",
    metricRef: "metrics/headache",
    trackingDay: 5,
    periodType: "last30",
    periodDays: 30,
    dateKey: dateKeyForOffset(0),
    newValue: 5,
    usedPainkillerToday: false,
  });

  const todayEntry = doc.dailyValues[doc.dailyValues.length - 1];
  assert.equal(todayEntry.date, dateKeyForOffset(0));
  assert.equal(
    todayEntry.deltaFromPreviousDay,
    null,
    "no meaningful delta is available right after a multi-day gap",
  );
  assert.equal(todayEntry.isSpike, false);
});

test("buildDashboardDocForDay detects a spike on the very first day of a short window, using history from just before periodStart", () => {
  const today = new Date();
  const dateKeyForOffset = (daysAgo) => {
    const d = new Date(
      Date.UTC(today.getUTCFullYear(), today.getUTCMonth(), today.getUTCDate()),
    );
    d.setUTCDate(d.getUTCDate() - daysAgo);
    return dateKeyFromDate(d);
  };

  const periodDays = 5; // window covers offsets 4,3,2,1,0 - periodStart is offset 4
  const dayBeforeWindowKey = dateKeyForOffset(periodDays); // offset 5, one day before periodStart

  // This same subjectId/metricKey/periodType's own previously stored doc
  // already knew about the day right before this window starts (true in
  // the common case of day-to-day usage, since the window shifts forward
  // by one day between consecutive daily writes).
  const existingSnap = {
    exists: true,
    data: () => ({
      dailyValues: [{ date: dayBeforeWindowKey, value: 2 }],
    }),
  };

  const doc = buildDashboardDocForDay({
    existingSnap,
    subjectId: "subj1",
    metricKey: "headache",
    metricLabel: "Headache",
    metricRef: "metrics/headache",
    trackingDay: 6,
    periodType: "last5", // stand-in for a short rolling window like last30
    periodDays,
    dateKey: dateKeyForOffset(periodDays - 1), // the window's own first day
    newValue: 5,
    usedPainkillerToday: false,
  });

  const firstDayOfWindow = doc.dailyValues[0];
  assert.equal(firstDayOfWindow.date, dateKeyForOffset(periodDays - 1));
  assert.equal(
    firstDayOfWindow.deltaFromPreviousDay,
    3,
    "the window's first day must still see the real prior-day value, not treat itself as having no predecessor",
  );
  assert.equal(firstDayOfWindow.isSpike, true);
});
