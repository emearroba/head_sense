const admin = require("firebase-admin/app");
admin.initializeApp();

const assignSubjectId = require("./assign_subject_id.js");
exports.assignSubjectId = assignSubjectId.assignSubjectId;
exports.ensureSubjectId = assignSubjectId.ensureSubjectId;
const scheduledReminders = require("./scheduled_reminders.js");
exports.scheduledReminders = scheduledReminders.scheduledReminders;
const updateDashboardMetric = require("./update_dashboard_metric.js");
exports.updateDashboardMetric = updateDashboardMetric.updateDashboardMetric;
const aggregateHealthSamples = require("./aggregate_health_samples.js");
exports.aggregateHealthSamples = aggregateHealthSamples.aggregateHealthSamples;
