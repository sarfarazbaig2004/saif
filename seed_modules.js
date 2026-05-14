const admin = require('firebase-admin');

const serviceAccount = require('./serviceAccountKey.json');

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount),
});

const db = admin.firestore();

const companyId = 'aman-infra';

const modules = [
  { id: 'administration', displayName: 'Administration', sortOrder: 10 },
  { id: 'crm', displayName: 'CRM', sortOrder: 20 },
  { id: 'sales', displayName: 'Sales', sortOrder: 30 },
  { id: 'purchase', displayName: 'Purchase', sortOrder: 40 },
  { id: 'inventory', displayName: 'Inventory', sortOrder: 50 },
  { id: 'production', displayName: 'Production', sortOrder: 60 },
  { id: 'dispatch', displayName: 'Dispatch', sortOrder: 70 },
  { id: 'finance', displayName: 'Finance', sortOrder: 80 },
  { id: 'hr', displayName: 'HR', sortOrder: 90 },
  { id: 'reports', displayName: 'Reports', sortOrder: 100 },
  { id: 'settings', displayName: 'Settings', sortOrder: 110 },
];

async function seedModules() {
  const batch = db.batch();

  for (const m of modules) {
    const ref = db
      .collection('companies')
      .doc(companyId)
      .collection('modules')
      .doc(m.id);

    batch.set(ref, {
      ...m,
      enabled: true,
      isEnabled: true,
      companyId,
      tenantId: companyId,
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    }, { merge: true });
  }

  await batch.commit();
  console.log('Aman Infra modules seeded successfully');
}

seedModules().catch(console.error);
