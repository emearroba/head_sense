const functions = require("firebase-functions");
const admin = require("firebase-admin");

if (!admin.apps.length) {
  admin.initializeApp();
}

exports.scheduledReminders = functions.pubsub
  .schedule("every 5 minutes")
  .onRun(async () => {
    const db = admin.firestore();
    const now = admin.firestore.Timestamp.now();

    // Reminders live at users/{uid}/reminders/{id}, so a collectionGroup
    // query is required to find them across all users.
    const remindersGroup = db.collectionGroup("reminders");
    const notificationsRef = db.collection("notifications");

    const snapshot = await remindersGroup
      .where("scheduled_time", "<=", now)
      .where("is_active", "==", true)
      .get();

    if (snapshot.empty) {
      console.log("No reminders due.");
      return null;
    }

    for (const doc of snapshot.docs) {
      const reminder = doc.data();

      const { title, message, scheduled_time, frequency_type, user_ref } =
        reminder;

      if (!user_ref) {
        console.error(`Reminder ${doc.id} missing user_ref`);
        continue;
      }

      await sendPushNotification(title || "Reminder", message || "", user_ref);

      await notificationsRef.add({
        noti_title: title || "Reminder",
        noti_description: message || "",
        noti_created_time: admin.firestore.FieldValue.serverTimestamp(),
        noti_received_by: user_ref,
        noti_read: false,
        reminder_ref: doc.ref,
      });

      const nextDate = getNextReminderDate(scheduled_time, frequency_type);

      if (nextDate) {
        await doc.ref.update({
          scheduled_time: admin.firestore.Timestamp.fromDate(nextDate),
        });
      } else {
        await doc.ref.update({
          is_active: false,
        });
      }
    }

    return null;
  });

// Interval-based frequencies, for reminders that repeat every N minutes
// (screen breaks, hydration, posture) rather than at a fixed time of day.
const INTERVAL_MINUTES_BY_FREQUENCY = {
  every_30_min: 30,
  every_60_min: 60,
  every_90_min: 90,
};

function getNextReminderDate(scheduledTime, frequencyType) {
  if (!scheduledTime || !frequencyType) {
    return null;
  }

  const currentDate = scheduledTime.toDate();

  const intervalMinutes = INTERVAL_MINUTES_BY_FREQUENCY[frequencyType];
  if (intervalMinutes) {
    return new Date(currentDate.getTime() + intervalMinutes * 60 * 1000);
  }

  if (frequencyType === "daily") {
    return new Date(currentDate.getTime() + 24 * 60 * 60 * 1000);
  }

  if (frequencyType === "weekly") {
    return new Date(currentDate.getTime() + 7 * 24 * 60 * 60 * 1000);
  }

  if (frequencyType === "none") {
    return null;
  }

  return null;
}

async function sendPushNotification(title, body, userRef) {
  try {
    const tokensSnapshot = await userRef.collection("fcm_tokens").get();

    if (tokensSnapshot.empty) {
      console.log("No FCM tokens found.");
      return;
    }

    const tokens = tokensSnapshot.docs
      .map((doc) => doc.data().fcm_token)
      .filter(Boolean);

    if (tokens.length === 0) {
      console.log("No valid FCM tokens.");
      return;
    }

    const response = await admin.messaging().sendEachForMulticast({
      notification: {
        title,
        body,
      },
      android: {
        notification: {
          sound: "default",
        },
      },
      apns: {
        payload: {
          aps: {
            sound: "default",
          },
        },
      },
      tokens,
    });

    console.log("Push notification sent:", response);
  } catch (error) {
    console.error("Error sending push notification:", error);
  }
}

exports.getNextReminderDate = getNextReminderDate;
