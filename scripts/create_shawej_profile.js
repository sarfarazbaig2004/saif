const admin = require("firebase-admin");
const serviceAccount = require("../serviceAccountKey.json");

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount),
  projectId: "quik-aman-erp",
});

const db = admin.firestore();

async function main() {
  const email = "shawej.s@amaninfradeveloper.co.in";

  const companyId = process.argv[2];

  if (!companyId) {
    throw new Error("Company ID missing");
  }

  const user = await admin.auth().getUserByEmail(email);
  const uid = user.uid;

  const companyNameMap = {
    "aman-infra": "AMAN Infra Developer",
    "memco": "MEMCO",
  };

  const companyName = companyNameMap[companyId] || companyId;

  const userData = {
    uid,
    email,
    name: "Shawej Siddiqui",
    role: "MANAGER",
    designation: "Factory Head",
    department: "Production, Purchase, Safety & Dispatch",
    companyId,
    companyName,
    isActive: true,
    updatedAt: admin.firestore.FieldValue.serverTimestamp(),
  };

  // Root user profile
  await db.collection("users").doc(uid).set(userData, {
    merge: true,
  });

  // Company master
  await db.collection("companies").doc(companyId).set(
    {
      companyId,
      name: companyName,
      isActive: true,
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    },
    { merge: true }
  );

  // Company user profile
  await db
    .collection("companies")
    .doc(companyId)
    .collection("users")
    .doc(uid)
    .set(userData, {
      merge: true,
    });

  console.log("Done.");
  console.log("Company:", companyId);
  console.log("UID:", uid);
}

main().catch((error) => {
  console.error("Failed:", error);
  process.exit(1);
});