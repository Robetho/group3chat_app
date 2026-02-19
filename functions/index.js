const functions = require("firebase-functions");
const admin = require("firebase-admin");

admin.initializeApp();

exports.sendChatNotification = functions.firestore
  .document("messages/{messageId}")
  .onCreate(async (snapshot, context) => {
    const messageData = snapshot.data();
    if (!messageData) return null;

    const senderName = messageData.senderName || "Someone";
    const receiverId = messageData.receiverId;
    const message = messageData.content;

    // Use context.params.messageId to avoid ESLint unused-var error
    const messageId = context.params.messageId;
    console.log(`📩 New message created with ID: ${messageId}`);

    try {
      // Get receiver’s FCM token from Firestore
      const userDoc = await admin.firestore()
        .collection("users")
        .doc(receiverId)
        .get();

      const token = userDoc.get("fcmToken");
      if (!token) {
        console.log(`⚠️ No FCM token for receiver ${receiverId}`);
        return null;
      }

      // Build notification payload using modern API
      const messagePayload = {
        token: token,
        notification: {
          title: senderName,
          body: message,
        },
        data: {
          senderId: messageData.senderId,
          receiverId: receiverId,
          messageId: messageId,
          click_action: "FLUTTER_NOTIFICATION_CLICK",
        },
      };

      // Send notification
      const response = await admin.messaging().send(messagePayload);
      console.log(`✅ Notification sent to ${receiverId}, response: ${response}`);
      return null;
    } catch (error) {
      console.error("❌ Error sending notification:", error.message || error);
      if (error.errorInfo) {
        console.error("Error details:", error.errorInfo);
      }
      return null;
    }
  });
