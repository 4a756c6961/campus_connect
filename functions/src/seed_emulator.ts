import {initializeApp} from "firebase-admin/app";
import {getAuth} from "firebase-admin/auth";
import {getStorage} from "firebase-admin/storage";
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

const testPassword = process.env.SEED_TEST_PASSWORD;

if (!testPassword) {
  throw new Error(
    "Abbruch: SEED_TEST_PASSWORD ist nicht gesetzt.",
  );
}

initializeApp({
  projectId,
  storageBucket: "campusconnect-3f38d.firebasestorage.app",
});

const db = getFirestore();
const auth = getAuth();
const bucket = getStorage().bucket();

const normalUid = "test-normal-user";
const admin1Uid = "test-admin-1";
const admin2Uid = "test-admin-2";

const testUsers = [
  {
    uid: normalUid,
    email: "normal@test.de",
    password: testPassword,
    displayName: "Normal User",
  },
  {
    uid: admin1Uid,
    email: "admin1@test.de",
    password: testPassword,
    displayName: "Admin 1",
  },
  {
    uid: admin2Uid,
    email: "admin2@test.de",
    password: testPassword,
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

  // Admin 1 folgt Normal User.
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

  // Testpost von Admin 1.
  const testPostId = "test-post-admin-1";
  const postRef = db.collection("posts").doc(testPostId);

  await postRef.set({
    userId: admin1Uid,
    userName: "Admin 1",
    text: "Testpost für die Accountlöschung",
    createdAt: FieldValue.serverTimestamp(),
  });

  // Like vom Normal User – muss verschwinden.
  await postRef.collection("likes").doc(normalUid).set({
    userId: normalUid,
    createdAt: FieldValue.serverTimestamp(),
  });

  // Like von Admin 2 – muss bestehen bleiben.
  await postRef.collection("likes").doc(admin2Uid).set({
    userId: admin2Uid,
    createdAt: FieldValue.serverTimestamp(),
  });

  // Kommentar vom Normal User – muss verschwinden.
  await postRef.collection("comments").doc("comment-normal-user").set({
    userId: normalUid,
    text: "Kommentar vom Normal User",
    createdAt: FieldValue.serverTimestamp(),
  });

  // Kommentar von Admin 2 – muss bestehen bleiben.
  await postRef.collection("comments").doc("comment-admin-2").set({
    userId: admin2Uid,
    text: "Kommentar von Admin 2",
    createdAt: FieldValue.serverTimestamp(),
  });
  // ---------------------------------------------------------
  // Notifications für Account-Deletion-Test
  // ---------------------------------------------------------

  // Notification von Normal User an Admin 1.
  // MUSS bei Löschung des Normal Users verschwinden.
  await db
    .collection("users")
    .doc(admin1Uid)
    .collection("notifications")
    .doc("notification-from-normal")
    .set({
      type: "like",
      senderId: normalUid,
      senderName: "Normal User",
      senderPhotoUrl: null,
      postId: testPostId,
      message: "Normal User gefällt dein Beitrag.",
      isRead: false,
      createdAt: FieldValue.serverTimestamp(),
    });

  // Notification von Admin 2 an Admin 1.
  // MUSS bestehen bleiben.
  await db
    .collection("users")
    .doc(admin1Uid)
    .collection("notifications")
    .doc("notification-from-admin-2")
    .set({
      type: "like",
      senderId: admin2Uid,
      senderName: "Admin 2",
      senderPhotoUrl: null,
      postId: testPostId,
      message: "Admin 2 gefällt dein Beitrag.",
      isRead: false,
      createdAt: FieldValue.serverTimestamp(),
    });

  // Eigene Notification des Normal Users.
  // Die komplette Notification-Subcollection des
  // zu löschenden Nutzers MUSS verschwinden.
  await db
    .collection("users")
    .doc(normalUid)
    .collection("notifications")
    .doc("notification-for-normal")
    .set({
      type: "follow",
      senderId: admin1Uid,
      senderName: "Admin 1",
      senderPhotoUrl: null,
      postId: null,
      message: "Admin 1 folgt dir jetzt.",
      isRead: false,
      createdAt: FieldValue.serverTimestamp(),
    });

  // Eigene Notification des Normal Users.
  // Die komplette Notification-Subcollection des
  // zu löschenden Nutzers MUSS verschwinden.
  await db
    .collection("users")
    .doc(normalUid)
    .collection("notifications")
    .doc("notification-for-normal")
    .set({
      type: "follow",
      senderId: admin1Uid,
      senderName: "Admin 1",
      senderPhotoUrl: null,
      postId: null,
      message: "Admin 1 folgt dir jetzt.",
      isRead: false,
      createdAt: FieldValue.serverTimestamp(),
    });

  // Testpost vom Normal User.
  // Dieser komplette Post MUSS bei der Accountlöschung verschwinden.
  const normalUserPostId = "test-post-normal-user";
  const normalUserPostRef = db.collection("posts").doc(normalUserPostId);

  await normalUserPostRef.set({
    userId: normalUid,
    userName: "Normal User",
    text: "Dieser Post gehört dem zu löschenden Nutzer.",
    createdAt: FieldValue.serverTimestamp(),
  });

  // Like von Admin 1 auf dem Post des Normal Users.
  // Muss zusammen mit dem Post verschwinden.
  await normalUserPostRef.collection("likes").doc(admin1Uid).set({
    userId: admin1Uid,
    createdAt: FieldValue.serverTimestamp(),
  });

  // Like von Admin 2 auf dem Post des Normal Users.
  // Muss zusammen mit dem Post verschwinden.
  await normalUserPostRef.collection("likes").doc(admin2Uid).set({
    userId: admin2Uid,
    createdAt: FieldValue.serverTimestamp(),
  });

  // Kommentar von Admin 1 auf dem Post des Normal Users.
  // Muss zusammen mit dem Post verschwinden.
  await normalUserPostRef
    .collection("comments")
    .doc("comment-admin-1-on-normal-post")
    .set({
      userId: admin1Uid,
      text: "Kommentar auf dem Post vom Normal User",
      createdAt: FieldValue.serverTimestamp(),
    });

  // ---------------------------------------------------------
  // Reports für Account-Deletion-Test
  // ---------------------------------------------------------

  // Report vom Normal User über Admin 1.
  // MUSS bei Löschung des Normal Users verschwinden.
  await db.collection("reports").doc("report-normal-about-admin-post").set({
    postId: testPostId,
    reporterUserId: normalUid,
    reportedUserId: admin1Uid,
    reason: "other",
    status: "open",
    createdAt: FieldValue.serverTimestamp(),
  });

  // Report von Admin 2 über den Normal User.
  // MUSS bei Löschung des Normal Users verschwinden.
  await db.collection("reports").doc("report-admin-2-about-normal-post").set({
    postId: normalUserPostId,
    reporterUserId: admin2Uid,
    reportedUserId: normalUid,
    reason: "other",
    status: "open",
    createdAt: FieldValue.serverTimestamp(),
  });

  // Report von Admin 2 über Admin 1.
  // MUSS bestehen bleiben.
  await db.collection("reports").doc("report-admin-2-about-admin-1").set({
    postId: testPostId,
    reporterUserId: admin2Uid,
    reportedUserId: admin1Uid,
    reason: "spam",
    status: "open",
    createdAt: FieldValue.serverTimestamp(),
  });

  // ---------------------------------------------------------
  // Direkte User-Subcollections für Account-Deletion-Test
  // ---------------------------------------------------------

  // Verborgener Post des Normal Users.
  // MUSS bei Löschung des Normal Users verschwinden.
  await db
    .collection("users")
    .doc(normalUid)
    .collection("hiddenPosts")
    .doc(testPostId)
    .set({
      postId: testPostId,
      createdAt: FieldValue.serverTimestamp(),
    });

  // FCM-Token des Normal Users.
  // MUSS bei Löschung des Normal Users verschwinden.
  await db
    .collection("users")
    .doc(normalUid)
    .collection("fcmTokens")
    .doc("test-token-1")
    .set({
      token: "local-emulator-token",
      platform: "test",
      createdAt: FieldValue.serverTimestamp(),
    });

  // ---------------------------------------------------------
  // Storage-Dateien für Account-Deletion-Test
  // ---------------------------------------------------------

  await bucket.file(`profile_images/${normalUid}/profile.jpg`).save(
    Buffer.from("fake profile image"),
    {
      contentType: "image/jpeg",
    },
  );

  await bucket.file(`profilePictures/${normalUid}/profile.jpg`).save(
    Buffer.from("fake legacy profile image"),
    {
      contentType: "image/jpeg",
    },
  );

  await bucket.file(`post_images/${normalUid}/test-post-image.jpg`).save(
    Buffer.from("fake post image"),
    {
      contentType: "image/jpeg",
    },
  );

  await bucket.file(`profile_images/${admin1Uid}/profile.jpg`).save(
    Buffer.from("fake admin profile image"),
    {
      contentType: "image/jpeg",
    },
  );
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
