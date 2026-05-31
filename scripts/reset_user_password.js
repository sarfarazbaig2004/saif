const admin = require("firebase-admin");

admin.initializeApp({
  credential: admin.credential.applicationDefault(),
});

async function resetPassword() {
  const email = "shawej.s@amaninfradeveloper.co.in";
  const newPassword = "Temp@12345";

  const user = await admin.auth().getUserByEmail(email);

  await admin.auth().updateUser(user.uid, {
    password: newPassword,
    disabled: false,
  });

  console.log(`Password reset successful for ${email}`);
}

resetPassword().catch((err) => {
  console.error(err);
  process.exit(1);
});
