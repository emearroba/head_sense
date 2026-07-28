const admin = require("firebase-admin/app");
admin.initializeApp();

const scheduledReminders = require("./scheduled_reminders.js");
exports.scheduledReminders = scheduledReminders.scheduledReminders;
const updateDashboardMetric = require("./update_dashboard_metric.js");
exports.updateDashboardMetric = updateDashboardMetric.updateDashboardMetric;
