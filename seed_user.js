const admin = require('firebase-admin');

const serviceAccount = require('./serviceAccountKey.json');

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount),
});

const db = admin.firestore();

async function seed() {
  const uid = 'g5utWAamxvVYdfYDjj1IwBUGkh13';

  await db.collection('users').doc(uid).set({
    companyId: 'aman-infra',
    email: 'genzprotech@gmail.com',
    isActive: true,
    role: 'SOFTWARE_SUPER_ADMIN',
  }, { merge: true });

  console.log('Root user document created successfully');
}

seed().catch(console.error);