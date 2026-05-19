const admin = require('firebase-admin');

const serviceAccount = require('./serviceAccountKey.json');

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount),
});

const db = admin.firestore();

const companyId = 'aman-infra';

const modules = [
  { id: 'dashboard', displayName: 'Dashboard', sortOrder: 10 },
  { id: 'crm', displayName: 'CRM', sortOrder: 20 },
  { id: 'sales', displayName: 'Sales', sortOrder: 30 },
  { id: 'customer_po', displayName: 'Customer PO', sortOrder: 40 },
  { id: 'projects_job_cards', displayName: 'Projects & Job Cards', sortOrder: 50 },
  { id: 'planning_scheduling', displayName: 'Planning & Scheduling', sortOrder: 60 },
  { id: 'engineering', displayName: 'Engineering', sortOrder: 70 },
  { id: 'inventory_store', displayName: 'Inventory & Store', sortOrder: 80 },
  { id: 'purchase', displayName: 'Purchase', sortOrder: 90 },
  { id: 'production', displayName: 'Production', sortOrder: 100 },
  { id: 'contractor_job_work', displayName: 'Contractor Job Work', sortOrder: 110 },
  { id: 'galvanizing', displayName: 'Galvanizing', sortOrder: 120 },
  { id: 'inspection_qa', displayName: 'Inspection / QA', sortOrder: 130 },
  { id: 'dispatch', displayName: 'Dispatch', sortOrder: 140 },
  { id: 'hr_admin', displayName: 'HR / Labour', sortOrder: 150 },
  { id: 'finance', displayName: 'Finance', sortOrder: 160 },
  { id: 'reports', displayName: 'Reports', sortOrder: 170 },
  { id: 'administration', displayName: 'Administration', sortOrder: 180 },
  { id: 'settings', displayName: 'Settings', sortOrder: 190 },
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
  console.log(`Seeded ${modules.length} Aman Infra modules successfully`);
}

seedModules()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
