import {setGlobalOptions} from "firebase-functions";
import {HttpsError, onCall} from "firebase-functions/https";
import {initializeApp} from "firebase-admin/app";
import {
  FieldValue,
  getFirestore,
} from "firebase-admin/firestore";

initializeApp();

setGlobalOptions({maxInstances: 10});

const db = getFirestore();

async function deleteFollowRelationships(uid: string): Promise<void> {
  const userRef = db.collection("users").doc(uid);

  const [followingSnapshot, followersSnapshot] = await Promise.all([
    userRef.collection("following").get(),
    userRef.collection("followers").get(),
  ]);

  const bulkWriter = db.bulkWriter();

  for (const document of followingSnapshot.docs) {
    const followedUserId = document.id;

    // Gegenreferenz beim gefolgten Nutzer entfernen.
    bulkWriter.delete(
      db
        .collection("users")
        .doc(followedUserId)
        .collection("followers")
        .doc(uid),
    );

    // Eigenen Following-Eintrag entfernen.
    bulkWriter.delete(document.ref);
  }

  for (const document of followersSnapshot.docs) {
    const followerUserId = document.id;

    // Gegenreferenz beim Follower entfernen.
    bulkWriter.delete(
      db
        .collection("users")
        .doc(followerUserId)
        .collection("following")
        .doc(uid),
    );

    // Eigenen Follower-Eintrag entfernen.
    bulkWriter.delete(document.ref);
  }

  await bulkWriter.close();
}

async function deleteUserInteractions(
  collectionName: "likes" | "comments",
  uid: string,
): Promise<number> {
  const snapshot = await db
    .collectionGroup(collectionName)
    .where("userId", "==", uid)
    .get();

  const bulkWriter = db.bulkWriter();

  for (const document of snapshot.docs) {
    bulkWriter.delete(document.ref);
  }

  await bulkWriter.close();

  return snapshot.size;
}

export const deleteAccount = onCall(async (request) => {
  if (!request.auth) {
    throw new HttpsError(
      "unauthenticated",
      "Du musst angemeldet sein, um deinen Account zu löschen.",
    );
  }

  const uid = request.auth.uid;

  const result = await db.runTransaction(async (transaction) => {
    const userRef = db.collection("users").doc(uid);
    const adminRef = db.collection("admin").doc(uid);

    const userDoc = await transaction.get(userRef);
    const adminDoc = await transaction.get(adminRef);

    const alreadyDeleting =
      userDoc.exists &&
      userDoc.data()?.accountStatus === "deleting";

    const isActiveAdmin =
      adminDoc.exists &&
      adminDoc.data()?.active === true;

    // Nur beim ersten Start des Löschprozesses prüfen und Status setzen.
    if (!alreadyDeleting) {
      if (isActiveAdmin) {
        const activeAdminsQuery = db
          .collection("admin")
          .where("active", "==", true);

        const activeAdmins = await transaction.get(
          activeAdminsQuery,
        );

        if (activeAdmins.size <= 1) {
          throw new HttpsError(
            "failed-precondition",
            "Der letzte aktive Administrator kann seinen Account nicht löschen.",
          );
        }
      }

      transaction.set(
        userRef,
        {
          accountStatus: "deleting",
          deletionRequestedAt: FieldValue.serverTimestamp(),
        },
        {merge: true},
      );

      if (isActiveAdmin) {
        transaction.set(
          adminRef,
          {
            active: false,
            deletionPending: true,
            deletionRequestedAt: FieldValue.serverTimestamp(),
          },
          {merge: true},
        );
      }
    }

    return {
      started: !alreadyDeleting,
    };
  });

  async function deleteUserPosts(uid: string): Promise<number> {
  const postsSnapshot = await db
    .collection("posts")
    .where("userId", "==", uid)
    .get();

  const bulkWriter = db.bulkWriter();

  for (const postDocument of postsSnapshot.docs) {
    const [likesSnapshot, commentsSnapshot] = await Promise.all([
      postDocument.ref.collection("likes").get(),
      postDocument.ref.collection("comments").get(),
    ]);

    for (const likeDocument of likesSnapshot.docs) {
      bulkWriter.delete(likeDocument.ref);
    }

    for (const commentDocument of commentsSnapshot.docs) {
      bulkWriter.delete(commentDocument.ref);
    }

    bulkWriter.delete(postDocument.ref);
  }

  await bulkWriter.close();

  return postsSnapshot.size;
}
async function deleteUserReports(uid: string): Promise<number> {
  const [createdReportsSnapshot, receivedReportsSnapshot] = await Promise.all([
    db
      .collection("reports")
      .where("reporterUserId", "==", uid)
      .get(),
    db
      .collection("reports")
      .where("reportedUserId", "==", uid)
      .get(),
  ]);

  const reportRefs = new Map<string, FirebaseFirestore.DocumentReference>();

  for (const document of createdReportsSnapshot.docs) {
    reportRefs.set(document.ref.path, document.ref);
  }

  for (const document of receivedReportsSnapshot.docs) {
    reportRefs.set(document.ref.path, document.ref);
  }

  const bulkWriter = db.bulkWriter();

  for (const reportRef of reportRefs.values()) {
    bulkWriter.delete(reportRef);
  }

  await bulkWriter.close();

  return reportRefs.size;
}

async function deleteDirectUserSubcollections(uid: string): Promise<number> {
  const userRef = db.collection("users").doc(uid);

  const subcollectionNames = [
    "hiddenPosts",
    "fcmTokens",
  ] as const;

  const snapshots = await Promise.all(
    subcollectionNames.map((collectionName) =>
      userRef.collection(collectionName).get(),
    ),
  );

  const bulkWriter = db.bulkWriter();

  let deletedDocuments = 0;

  for (const snapshot of snapshots) {
    for (const document of snapshot.docs) {
      bulkWriter.delete(document.ref);
      deletedDocuments++;
    }
  }

  await bulkWriter.close();

  return deletedDocuments;
}

  // Erst nach erfolgreicher Transaction Follow-Beziehungen, likes und Kommentare bereinigen.
  await deleteFollowRelationships(uid);
  await deleteUserInteractions("likes", uid);
  await deleteUserInteractions("comments", uid);
  await deleteFollowRelationships(uid);
  await deleteUserNotifications(uid); 
  await deleteUserPosts(uid);
  await deleteUserReports(uid);
  await deleteDirectUserSubcollections(uid);
  return {
    allowed: true,
    started: result.started,
    status: "deleting",
    message: result.started
      ? "Die Accountlöschung wurde gestartet."
      : "Die Accountlöschung wird fortgesetzt.",
  };
});
async function deleteUserNotifications(uid: string): Promise<void> {
  const ownNotificationsRef = db
    .collection("users")
    .doc(uid)
    .collection("notifications");

  const ownNotificationsSnapshot = await ownNotificationsRef.get();

  const sentNotificationsSnapshot = await db
    .collectionGroup("notifications")
    .where("senderId", "==", uid)
    .get();

  const bulkWriter = db.bulkWriter();

  for (const document of ownNotificationsSnapshot.docs) {
    bulkWriter.delete(document.ref);
  }

  for (const document of sentNotificationsSnapshot.docs) {
    bulkWriter.delete(document.ref);
  }

  await bulkWriter.close();
}