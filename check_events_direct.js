const admin = require('firebase-admin');

const serviceAccount = {
  "type": "service_account",
  "project_id": "west-valley-gardens-6682-c1018",
  "private_key_id": "f7868520380b372022ab71ac69f97174ca722caa",
  "private_key": "-----BEGIN PRIVATE KEY-----\nMIIEvgIBADANBgkqhkiG9w0BAQEFAASCBKgwggSkAgEAAoIBAQDIzJz62PAc2G/C\nijbuqJsmTxBvQ3/mCeSLz7u6+NvHZ+vQhXUT2cjKtiU5PCkeejTja+Z+e4V7wiP5\ngtIuCVSVz4qW01X6fOYBrgXpI8OqWkQbwKiwY1fPp9WGon6v58odSHBmKF6ZZZAy\n3lRSjgl8snDI2+6IM3OxedfCIBwhhlfKFu+koSDrXidg4Q20qKdsSiMB2vrzPx52\n0BwUp3zKL/3YMwOFAKPExaG4j36Gg5MwQgHWidhC1k9XPsZGgoHChh5znZ+RdtYw\nmAAYQP61xXUak7BnuJAF1sbdYZGQky18kH0mZ4k7U2wKaWNlMqm9F1VZ7Wbb1RS3\nhcvhdXSHAgMBAAECggEAJYegu326exm04b5lf/vBa8qRPsp16C/nKH5+DvceVMnG\nmGWpOTmWPtUGZgkpgknDAtKS9QbvLu9dO/BIilQyHAH7XC9JvZSEhMHa1vVZR8ix\nPCKpJLacnfI3hX9vgD8pVonIgD+BVthVuDw3tGpZuZW8YL5CefBr6jrkqaLIvzcB\nBNmmf6Lp8yO7JjXGTOMyrivukbSmtE68FQJ3LLpRXkHpyVUYf0sRt1kJkW6kAdFH\xySmd82OyLE9Xw0ZtQZZ8xQWA5XpzNN93sG3rr+G18CdXFNmfkBklg1lFvXc/Xow\nPgjXpN73AOdWFTTNfJNcB8HvsnhEFupCx2XsSiYqCQKBgQDl341FEKJYFBwQ/A2V\nBzEDQqB5k29EIRHUDg17UyPGhAdt/O9iIMVarB4zKoO5KSb7aFpC+IwE3q9SyxxF\nz9yq/X02riFDzPE5ySh487TTSeFLlXE+5hmOfqVaYxGIk7VlMW6+cJxdyPPAupW+\nxnAEKP1lr6kH1YDTJUOa/trFFQKBgQDfnx4msfpHYyAZPMitL0PG/qjKGuat4HaO\nhs1zO37cfM4gz7rjMkpan1Ys+5kAcD+9KVn4alUMdoXJO46ELlVwP3GBmY5jBnmk\nTIaHfQLuGJNcmZ8HstebDDhGnv4Wq4ANokgaQbRELH/AHdZNwNR7gUrU974vA7A9\n8SDczedyKwKBgQCYK7zhE3nkxKsvsytqlDAl8F07HhZyC1I6BnN2SDtOlug0L1Ro\nqTj8JSR4ypQYZt2fYB0gaFiIgMGfFUXKESgLKXNSV0M+FtU5Y6ifKPVzSV0TJAKr\nmLciVUQw6ZQZzW4vZuHgv7tDeluiIeIvQD23A0t7nSVQQk3deLWgTUWVYQKBgCFd\nKjB3yXGxNm7NhNth++jKwgA1d0ll/gpRzoFs1QaskEyQ8b9IF5Phxge8Gh3YoYnl\ni4jmxH2xiVB21FKgXxr6PEMr1/SqWKfMyx2X50IC5KmiOfn6EvUNI7BVtG9JczeV\niNByESVCxmSxjvHW3Vz382RG+lclY7w6J78J8Yg1AoGBAL0wBTQ/LxRDDwTsvNwC\nERMyJMm+RW6GHo7IzgzZnSPjQ3cOfjRRWz2wUDFTgHJ+1H9LxPppYAD9v4cq3Gfq\nZS4FlVCubsJEi57xucpfdmlJEvNH4V7DjnG0uykv8GgomR+QkzInIiQ6rXk5G1Go\n7aZyaKdS0M7MMLibxNsixYh7\n-----END PRIVATE KEY-----\n".replace(/\\n/g, '\n'),
  "client_email": "firebase-adminsdk-fbsvc@west-valley-gardens-6682-c1018.iam.gserviceaccount.com",
  "client_id": "115732508085110290333",
  "auth_uri": "https://accounts.google.com/o/oauth2/auth",
  "token_uri": "https://oauth2.googleapis.com/token",
  "auth_provider_x509_cert_url": "https://www.googleapis.com/oauth2/v1/certs",
  "client_x509_cert_url": "https://www.googleapis.com/robot/v1/metadata/x509/firebase-adminsdk-fbsvc%40west-valley-gardens-6682-c1018.iam.gserviceaccount.com",
  "universe_domain": "googleapis.com"
};

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
  console.log('Found the following documents:');
  snapshot.forEach(doc => {
    console.log(doc.id, '=>', doc.data());
  });
}

getEvents();
