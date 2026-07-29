const test = require("node:test");
const assert = require("node:assert/strict");

const { Timestamp } = require("firebase-admin/firestore");
const { getNextReminderDate } = require("../scheduled_reminders.js");

test("getNextReminderDate returns null with no scheduled time or frequency", () => {
  assert.equal(getNextReminderDate(null, "daily"), null);
  assert.equal(
    getNextReminderDate(Timestamp.fromDate(new Date()), null),
    null,
  );
});

test("getNextReminderDate advances interval frequencies by the right number of minutes", () => {
  const start = new Date("2026-07-29T10:00:00.000Z");
  const scheduledTime = Timestamp.fromDate(start);

  assert.equal(
    getNextReminderDate(scheduledTime, "every_30_min").toISOString(),
    "2026-07-29T10:30:00.000Z",
  );
  assert.equal(
    getNextReminderDate(scheduledTime, "every_60_min").toISOString(),
    "2026-07-29T11:00:00.000Z",
  );
  assert.equal(
    getNextReminderDate(scheduledTime, "every_90_min").toISOString(),
    "2026-07-29T11:30:00.000Z",
  );
});

test("getNextReminderDate advances daily and weekly frequencies by a day/week", () => {
  const start = new Date("2026-07-29T10:00:00.000Z");
  const scheduledTime = Timestamp.fromDate(start);

  assert.equal(
    getNextReminderDate(scheduledTime, "daily").toISOString(),
    "2026-07-30T10:00:00.000Z",
  );
  assert.equal(
    getNextReminderDate(scheduledTime, "weekly").toISOString(),
    "2026-08-05T10:00:00.000Z",
  );
});

test("getNextReminderDate returns null for a one-time (\"none\") reminder", () => {
  const scheduledTime = Timestamp.fromDate(new Date("2026-07-29T10:00:00.000Z"));
  assert.equal(getNextReminderDate(scheduledTime, "none"), null);
});

test("getNextReminderDate returns null for an unrecognized frequency", () => {
  const scheduledTime = Timestamp.fromDate(new Date("2026-07-29T10:00:00.000Z"));
  assert.equal(getNextReminderDate(scheduledTime, "monthly"), null);
});
