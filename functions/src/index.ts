import {setGlobalOptions} from "firebase-functions";
import {HttpsError, onCall} from "firebase-functions/https";
import {initializeApp} from "firebase-admin/app";
import {getFirestore} from "firebase-admin/firestore";

initializeApp();

setGlobalOptions({ maxInstances: 10 });

const db = getFirestore();

export const deleteAccount = onCall(async (request) => {
  if (!request.auth) {
    throw new HttpsError(
      "unauthenticated",
      "Du musst angemeldet sein, um deinen Account zu löschen.",
    );
  }

  const uid = request.auth.uid;

  const adminDoc = await db.collection("admin").doc(uid).get();

  const isActiveAdmin =
    adminDoc.exists && adminDoc.data()?.active === true;

  if (isActiveAdmin) {
    const activeAdmins = await db
      .collection("admin")
      .where("active", "==", true)
      .get();

    if (activeAdmins.size <= 1) {
      throw new HttpsError(
        "failed-precondition",
        "Der letzte aktive Administrator kann seinen Account nicht löschen.",
      );
    }
 }
 return {
    allowed: true,
    message: "Accountlöschung darf gestartet werden.",
  };
});