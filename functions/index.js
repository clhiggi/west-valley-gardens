const functions = require("firebase-functions");
const admin = require("firebase-admin");

admin.initializeApp();

exports.scheduledFlyerCleanup = functions.pubsub
  .schedule("every 24 hours")
  .onRun(async (context) => {
    const now = admin.firestore.Timestamp.now();
    const twoWeeksAgo = admin.firestore.Timestamp.fromMillis(
      now.toMillis() - 14 * 24 * 60 * 60 * 1000
    );

    const eventsRef = admin.firestore().collection("events");
    const snapshot = await eventsRef.where("endTime", "<", twoWeeksAgo).get();

    if (snapshot.empty) {
      console.log("No old events with flyers to delete.");
      return null;
    }

    const promises = [];
    snapshot.forEach((doc) => {
      const event = doc.data();
      if (event.flyerUrl) {
        const flyerPath = new URL(event.flyerUrl).pathname.split("/").pop();
        const file = admin.storage().bucket().file(`flyers/${flyerPath}`);
        promises.push(
          file
            .delete()
            .then(() => {
              return doc.ref.update({ flyerUrl: null });
            })
            .catch((err) => {
              console.error(
                `Failed to delete flyer for event ${doc.id}:`,
                err
              );
            })
        );
      }
    });

    return Promise.all(promises);
  });

exports.updateEventWithFlyer = functions.storage
  .object()
  .onFinalize(async (object) => {
    const filePath = object.name;
    const contentType = object.contentType;
    const bucket = admin.storage().bucket(object.bucket);

    if (!contentType.startsWith("image/")) {
      return console.log("This is not an image.");
    }

    if (!filePath.startsWith("flyers/")) {
      return console.log("File is not in the flyers directory.");
    }

    const fileName = filePath.split("/").pop();
    const eventId = fileName.split(".")[0];

    const file = bucket.file(filePath);
    const [url] = await file.getSignedUrl({
      action: "read",
      expires: "03-09-2491",
    });

    const eventRef = admin.firestore().collection("events").doc(eventId);
    try {
      await eventRef.update({ flyerUrl: url });
      console.log(`Successfully updated event ${eventId} with flyer URL.`);
    } catch (error) {
      console.error(`Error updating event ${eventId}:`, error);
    }
  });
