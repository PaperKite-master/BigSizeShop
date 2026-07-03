const { admin, messaging, isMock } = require('../../../common/config/firebase');
const { prisma } = require('../../../common/config/prisma');
const notificationRepository = require('../repositories/notification.repository');

async function sendPushNotification(userId, title, body, data = {}) {
  // 1. Create a notification record in the database
  try {
    await notificationRepository.createNotification(userId, title, body);
  } catch (err) {
    console.error('[Notification Service] Error creating database notification:', err.message);
  }

  // 2. Fetch the user to get their FCM Token
  const user = await prisma.user.findUnique({
    where: { id: userId },
    select: { fcmToken: true },
  });

  if (!user) {
    console.warn(`[Notification Service] User with ID ${userId} not found.`);
    return;
  }

  if (isMock) {
    console.log(`[Mock Push Notification] User: ${userId} | Title: "${title}" | Body: "${body}" | Data:`, data);
    return;
  }

  if (!user.fcmToken) {
    console.log(`[Notification Service] User: ${userId} has no registered FCM Token.`);
    return;
  }

  const message = {
    notification: {
      title,
      body,
    },
    data: {
      ...data,
      click_action: 'FLUTTER_NOTIFICATION_CLICK',
    },
    token: user.fcmToken,
  };

  try {
    await messaging.send(message);
    console.log(`[Notification Service] Push notification successfully sent to User ID ${userId}`);
  } catch (err) {
    console.error(`[Notification Service] Firebase error sending notification to User ID ${userId}:`, err.message);
    // If the token is invalid/expired, remove it
    if (
      err.code === 'messaging/invalid-registration-token' ||
      err.code === 'messaging/registration-token-not-registered'
    ) {
      await prisma.user.update({
        where: { id: userId },
        data: { fcmToken: null },
      });
      console.log(`[Notification Service] Cleared invalid FCM token for User ID ${userId}`);
    }
  }
}

async function sendBroadcastNotification(title, body, data = {}) {
  // 1. Fetch all users from the database
  const users = await prisma.user.findMany({
    select: { id: true, fcmToken: true },
  });

  if (users.length === 0) {
    console.log('[Notification Service] No users found to broadcast to.');
    return { sentCount: 0 };
  }

  // 2. Create notification records in the database for all users in bulk
  const notificationsData = users.map((user) => ({
    userId: user.id,
    title,
    content: body,
  }));

  try {
    await notificationRepository.createManyNotifications(notificationsData);
    console.log(`[Notification Service] Created DB notification records for ${users.length} users.`);
  } catch (err) {
    console.error('[Notification Service] Error creating bulk notifications in DB:', err.message);
  }

  // 3. Extract active FCM tokens
  const activeTokens = users
    .map((u) => u.fcmToken)
    .filter((token) => token !== null && token !== undefined && token !== '');

  if (activeTokens.length === 0) {
    console.log('[Notification Service] No active FCM tokens registered for broadcast.');
    return { sentCount: 0, tokenCount: 0 };
  }

  if (isMock) {
    console.log(`[Mock Broadcast Notification] Title: "${title}" | Body: "${body}" | Tokens count: ${activeTokens.length}`);
    return { sentCount: activeTokens.length, tokenCount: activeTokens.length, isMock: true };
  }

  // 4. Send multicast notification
  const message = {
    notification: {
      title,
      body,
    },
    data: {
      ...data,
      click_action: 'FLUTTER_NOTIFICATION_CLICK',
    },
    tokens: activeTokens,
  };

  try {
    const response = await messaging.sendEachForMulticast(message);
    console.log(`[Notification Service] Broadcast sent. Success: ${response.successCount}, Failure: ${response.failureCount}`);
    
    // Clean up failed tokens if needed (response.responses matches index of activeTokens)
    if (response.failureCount > 0) {
      const tokensToRemove = [];
      response.responses.forEach((resp, idx) => {
        if (!resp.success) {
          const err = resp.error;
          if (
            err &&
            (err.code === 'messaging/invalid-registration-token' ||
              err.code === 'messaging/registration-token-not-registered')
          ) {
            tokensToRemove.push(activeTokens[idx]);
          }
        }
      });

      if (tokensToRemove.length > 0) {
        await prisma.user.updateMany({
          where: { fcmToken: { in: tokensToRemove } },
          data: { fcmToken: null },
        });
        console.log(`[Notification Service] Cleaned up ${tokensToRemove.length} invalid tokens during broadcast.`);
      }
    }

    return {
      sentCount: response.successCount,
      tokenCount: activeTokens.length,
    };
  } catch (err) {
    console.error('[Notification Service] Error sending multicast message:', err.message);
    throw err;
  }
}

module.exports = {
  sendPushNotification,
  sendBroadcastNotification,
};
