require('dotenv').config();
const { sendPushNotification, sendBroadcastNotification } = require('../src/modules/notification/services/notification.service');
const { prisma } = require('../src/common/config/prisma');

async function test() {
  console.log('--- START PUSH NOTIFICATION VERIFICATION SCRIPT ---');
  
  // 1. Fetch or create a test user
  console.log('1. Checking for a test user in DB...');
  let user = await prisma.user.findFirst();
  
  if (!user) {
    console.log('No user found in database. Creating a temp test user...');
    user = await prisma.user.create({
      data: {
        fullName: 'Test Push User',
        email: 'testpush@example.com',
        password: 'dummyhashedpassword123',
        role: 'USER',
        fcmToken: 'mock-fcm-token-12345'
      }
    });
    console.log(`Created temp test user: ${user.id} (${user.email})`);
  } else {
    console.log(`Found test user: ${user.id} (${user.email}), current FCM token: ${user.fcmToken}`);
    if (!user.fcmToken) {
      console.log('Updating user with a mock FCM token...');
      user = await prisma.user.update({
        where: { id: user.id },
        data: { fcmToken: 'mock-fcm-token-12345' }
      });
      console.log(`Updated FCM Token for user ${user.id}`);
    }
  }

  // 2. Test sendPushNotification (Individual)
  console.log('\n2. Testing individual push notification (sendPushNotification)...');
  await sendPushNotification(
    user.id,
    'Kiểm tra đơn hàng',
    'Đơn hàng #12345 của bạn đã được chuyển trạng thái sang SHIPPING.',
    { orderId: '12345', status: 'SHIPPED' }
  );

  // Check if notification record was created in the database
  const lastNotification = await prisma.notification.findFirst({
    where: { userId: user.id },
    orderBy: { created_at: 'desc' }
  });

  if (lastNotification && lastNotification.title === 'Kiểm tra đơn hàng') {
    console.log(`Success: Notification record created in DB. Title: "${lastNotification.title}", Content: "${lastNotification.content}"`);
  } else {
    console.error('Error: Notification record was not found or has wrong title.');
  }

  // 3. Test sendBroadcastNotification (Multicast)
  console.log('\n3. Testing broadcast notification (sendBroadcastNotification)...');
  const broadcastResult = await sendBroadcastNotification(
    'Khuyến mãi mùa hè!',
    'Giảm giá 20% cho tất cả đơn hàng từ hôm nay!',
    { promoCode: 'SUMMER20' }
  );

  console.log('Broadcast results:', broadcastResult);

  // Check if broadcast notification was created for this user in DB
  const promoNotification = await prisma.notification.findFirst({
    where: { userId: user.id, title: 'Khuyến mãi mùa hè!' },
    orderBy: { created_at: 'desc' }
  });

  if (promoNotification) {
    console.log(`Success: Broadcast notification record created in DB. Title: "${promoNotification.title}"`);
  } else {
    console.error('Error: Broadcast notification record not found in DB.');
  }

  console.log('\n--- VERIFICATION SCRIPT COMPLETED ---');
}

test()
  .catch(err => {
    console.error('Test script failed with error:', err);
    process.exit(1);
  })
  .finally(async () => {
    await prisma.$disconnect();
  });
