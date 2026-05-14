const admin = require("firebase-admin");
const serviceAccount = require("../serviceAccountKey.json");

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount),
  projectId: "quik-aman-erp",
});

const db = admin.firestore();

async function main() {
  const companyId = process.argv[2];
  const email = process.argv[3];
  const role = process.argv[4];

  if (!companyId || !email || !role) {
    throw new Error(
      "Usage: node scripts/create_user_profile.js <companyId> <email> <role>"
    );
  }

  let user;

  try {
    user = await admin.auth().getUserByEmail(email);
    console.log("Auth user already exists:", user.uid);
  } catch (e) {
    if (e.code === "auth/user-not-found") {
      user = await admin.auth().createUser({
        email,
        emailVerified: true,
        password: "ChangeMe@12345",
        displayName: email,
        disabled: false,
      });
      console.log("Auth user created:", user.uid);
    } else {
      throw e;
    }
  }

  const uid = user.uid;

  const data = {
    uid,
    email,
    role,
    companyId,
    companyName: companyId,
    isActive: true,
    createdByScript: true,
    updatedAt: admin.firestore.FieldValue.serverTimestamp(),
  };

  await db.collection("users").doc(uid).set(data, { merge: true });

  await db.collection("companies").doc(companyId).set(
    {
      companyId,
      name: companyId,
      isActive: true,
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    },
    { merge: true }
  );

  await db
    .collection("companies")
    .doc(companyId)
    .collection("users")
    .doc(uid)
    .set(data, { merge: true });

  console.log("Done.");
  console.log("Email:", email);
  console.log("UID:", uid);
  console.log("Company:", companyId);
  console.log("Role:", role);
}

main().catch((error) => {
  console.error("Failed:", error);
  process.exit(1);
});