const test = require("node:test");
const assert = require("node:assert/strict");

const {
  dateKeyFromDate,
  getCategory,
  getBarColor,
  calculateStreaks,
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
