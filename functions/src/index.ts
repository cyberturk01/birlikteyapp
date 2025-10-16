import * as admin from "firebase-admin";
import { getFirestore, FieldValue } from "firebase-admin/firestore";
import { onSchedule } from "firebase-functions/v2/scheduler";

admin.initializeApp();
const db = getFirestore();
const MINUTES = (n: number) => n * 60 * 1000;
const DAYS = (n: number) => n * 24 * 60 * 60 * 1000;

export const autoTurnOffSharing = onSchedule(
  { schedule: "every 5 minutes", timeZone: "Europe/Berlin", region: "europe-west3" },
  async () => {
    const cutoff = Date.now() - MINUTES(15);
    const snap = await db.collectionGroup("locations")
      .where("isSharing", "==", true)
      .where("updatedAt", "<", new Date(cutoff))
      .get();

    if (snap.empty) return;
    const batch = db.bulkWriter();
    snap.docs.forEach((doc) =>
      batch.update(doc.ref, { isSharing: false, autoOffAt: FieldValue.serverTimestamp() })
    );
    await batch.close();
  }
);

export const pruneStaleLocations = onSchedule(
  { schedule: "every day 03:15", timeZone: "Europe/Berlin", region: "europe-west3" },
  async () => {
    const cutoff = Date.now() - DAYS(7);
    const snap = await db.collectionGroup("locations")
      .where("isSharing", "==", false)
      .where("updatedAt", "<", new Date(cutoff))
      .get();

    if (snap.empty) return;
    const batch = db.bulkWriter();
    snap.docs.forEach((doc) =>
      batch.update(doc.ref, {
        lat: FieldValue.delete(),
        lng: FieldValue.delete(),
        accuracy: FieldValue.delete(),
        speed: FieldValue.delete(),
        heading: FieldValue.delete(),
        stale: true
      })
    );
    await batch.close();
  }
);
