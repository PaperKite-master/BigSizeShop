const admin = require('firebase-admin');
const { getMessaging } = require('firebase-admin/messaging');
const fs = require('fs');

let firebaseApp = null;
let messaging = null;
let isMock = false;

try {
  const serviceAccountPath = process.env.FIREBASE_SERVICE_ACCOUNT_PATH;
  const privateKey = process.env.FIREBASE_PRIVATE_KEY;
  const clientEmail = process.env.FIREBASE_CLIENT_EMAIL;
  const projectId = process.env.FIREBASE_PROJECT_ID;

  const getCert = (config) => {
    if (admin.credential && typeof admin.credential.cert === 'function') {
      return admin.credential.cert(config);
    }
    return admin.cert(config);
  };

  if (serviceAccountPath && fs.existsSync(serviceAccountPath)) {
    const serviceAccount = JSON.parse(fs.readFileSync(serviceAccountPath, 'utf8'));
    firebaseApp = admin.initializeApp({
      credential: getCert(serviceAccount),
    });
    messaging = getMessaging(firebaseApp);
    console.log('[Firebase] Initialized using service account file:', serviceAccountPath);
  } else if (privateKey && clientEmail && projectId) {
    const formattedPrivateKey = privateKey.replace(/\\n/g, '\n');
    firebaseApp = admin.initializeApp({
      credential: getCert({
        projectId,
        clientEmail,
        privateKey: formattedPrivateKey,
      }),
    });
    messaging = getMessaging(firebaseApp);
    console.log('[Firebase] Initialized using environment variables.');
  } else {
    isMock = true;
    console.warn('[Firebase] Warning: No Firebase credentials found. Push notifications will run in MOCK mode (logged to console).');
  }
} catch (error) {
  isMock = true;
  console.error('[Firebase] Error initializing Firebase Admin SDK. Falling back to MOCK mode:', error.message);
}

module.exports = {
  admin,
  firebaseApp,
  messaging,
  isMock,
};

