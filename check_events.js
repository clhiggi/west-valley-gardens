
const admin = require('firebase-admin');
const serviceAccount = require('./serviceAccountKey.json');

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount)
});

const db = admin.firestore();

async function getEvents() {
  const eventsCollection = db.collection('events');
  const snapshot = await eventsCollection.get();
  if (snapshot.empty) {
    console.log('No documents found in the events collection.');
    return;
  }
  snapshot.forEach(doc => {
    console.log(doc.id, '=>', doc.data());
  });
}

getEvents();
