const firebase = require('firebase/compat/app');
require('firebase/auth');
require('firebase/compat/firestore');

const firebaseConfig = {
  apiKey: "AIzaSyBuKZQMqNS72hrTtx2r0bzB3ZOKe3zPzIQ",
  authDomain: "noti-27763.firebaseapp.com",
  projectId: "noti-27763",
  storageBucket: "noti-27763.appspot.com",
  messagingSenderId: "436603702917",
  appId: "1:436603702917:web:7c9af0cf7eb2d16b16e3ec"
};

const app = firebase.initializeApp(firebaseConfig);

const db = firebase.firestore();

async function deleteAllTrips() {
  const collectionRef = db.collection('trips');

  try {
    const querySnapshot = await collectionRef.get();

    for (const doc of querySnapshot.docs) {
      await deleteDocumentAndSubcollections(doc.ref);
    }

    console.log('All done');
    process.exit(); // Exit the Node.js process
  } catch (error) {
    console.error('Error deleting documents:', error);
    process.exit(1); // Exit with an error code
  }
}

async function deleteDocumentAndSubcollections(docRef) {
  const coordinatesRef = docRef.collection('points');
  const querySnapshot = await coordinatesRef.get();

  for (const doc of querySnapshot.docs) {
    await doc.ref.delete();
  }

  console.log('Subcollection documents deleted:', coordinatesRef.path);

  await docRef.delete();
  console.log('Document deleted:', docRef.id);
}

deleteAllTrips();
