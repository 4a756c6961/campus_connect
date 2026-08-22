import {initializeApp} from "firebase-admin/app";
import {getAuth} from "firebase-admin/auth";
import {
  FieldValue,
  getFirestore,
} from "firebase-admin/firestore";

const projectId = "campusconnect-3f38d";

if (!process.env.FIRESTORE_EMULATOR_HOST) {
  throw new Error(
    "Abbruch: FIRESTORE_EMULATOR_HOST ist nicht gesetzt.",
  );
}

if (!process.env.FIREBASE_AUTH_EMULATOR_HOST) {
  throw new Error(
    "Abbruch: FIREBASE_AUTH_EMULATOR_HOST ist nicht gesetzt.",
  );
}

initializeApp({projectId});

const db = getFirestore();
const auth = getAuth();

const normalUid = "test-normal-user";
const admin1Uid = "test-admin-1";
const admin2Uid = "test-admin-2";

const testUsers = [
  {
    uid: normalUid,
    email: "normal@test.de",
    password: "Test123!",
    displayName: "Normal User",
  },
  {
    uid: admin1Uid,
    email: "admin1@test.de",
    password: "Test123!",
    displayName: "Admin 1",
  },
  {
    uid: admin2Uid,
    email: "admin2@test.de",
    password: "Test123!",
    displayName: "Admin 2",
  },
];

async function resetAuthUsers(): Promise<void> {
  for (const user of testUsers) {
    try {
      await auth.deleteUser(user.uid);
    } catch (error: unknown) {
      const code = (error as {code?: string}).code;

      if (code !== "auth/user-not-found") {
        throw error;
      }
    }

    await auth.createUser({
      uid: user.uid,
      email: user.email,
      password: user.password,
      displayName: user.displayName,
    });
  }
}

async function clearFollowSubcollection(
  uid: string,
  collectionName: "followers" | "following",
): Promise<void> {
  const snapshot = await db
    .collection("users")
    .doc(uid)
    .collection(collectionName)
    .get();

  if (snapshot.empty) {
    return;
  }

  const writer = db.bulkWriter();

  for (const document of snapshot.docs) {
    writer.delete(document.ref);
  }

  await writer.close();
}

async function seedFirestore(): Promise<void> {
  for (const user of testUsers) {
    await clearFollowSubcollection(user.uid, "followers");
    await clearFollowSubcollection(user.uid, "following");

    await db.collection("users").doc(user.uid).set({
      displayName: user.displayName,
      email: user.email,
    });
  }

  await db.collection("admin").doc(admin1Uid).set({
    active: true,
    createdAt: FieldValue.serverTimestamp(),
  });

  await db.collection("admin").doc(admin2Uid).set({
    active: true,
    createdAt: FieldValue.serverTimestamp(),
  });

  // Normal User folgt Admin 1.
  await db
    .collection("users")
    .doc(normalUid)
    .collection("following")
    .doc(admin1Uid)
    .set({
      createdAt: FieldValue.serverTimestamp(),
    });

  await db
    .collection("users")
    .doc(admin1Uid)
    .collection("followers")
    .doc(normalUid)
    .set({
      createdAt: FieldValue.serverTimestamp(),
    });

  // Normal User folgt Admin 2.
  await db
    .collection("users")
    .doc(normalUid)
    .collection("following")
    .doc(admin2Uid)
    .set({
      createdAt: FieldValue.serverTimestamp(),
    });

  await db
    .collection("users")
    .doc(admin2Uid)
    .collection("followers")
    .doc(normalUid)
    .set({
      createdAt: FieldValue.serverTimestamp(),
    });

  // Admin 1 folgt dem Normal User.
  await db
    .collection("users")
    .doc(admin1Uid)
    .collection("following")
    .doc(normalUid)
    .set({
      createdAt: FieldValue.serverTimestamp(),
    });

  await db
    .collection("users")
    .doc(normalUid)
    .collection("followers")
    .doc(admin1Uid)
    .set({
      createdAt: FieldValue.serverTimestamp(),
    });
}

async function main(): Promise<void> {
  await resetAuthUsers();
  await seedFirestore();

  console.log("✅ Firebase Emulator erfolgreich vorbereitet.");
  console.log("Normal User: normal@test.de");
  console.log("Admin 1: admin1@test.de");
  console.log("Admin 2: admin2@test.de");
}

main().catch((error) => {
  console.error("❌ Emulator-Seeding fehlgeschlagen:", error);
  process.exitCode = 1;
});