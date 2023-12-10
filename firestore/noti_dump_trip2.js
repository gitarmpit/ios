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



async function listCoords(coordinatesRef) {
  try {
    const coordinatesSnapshot = await coordinatesRef.get();
    coordinatesSnapshot.forEach(function (doc) {
      const data = doc.data();
      //console.log("data: " + data);
      console.log('Coordinate:', doc.id, "lat:" + data.latitude + ", long:" + data.longitude);
    });
  } catch (error) {
    console.error('Error dumping trip:', error);
  }
}

async function dumpTrip(tripName) {
  try {
    const collectionRef = db.collection('trips');

    const querySnapshot = await collectionRef
      .where('id', '==', tripName)
      .limit(1)
      .get();

    if (!querySnapshot.empty) {
      const doc = querySnapshot.docs[0];
      const data = doc.data();
      console.log('Document:', data.ts.toDate());

      const coordinatesRef = doc.ref.collection('coordinates');
      await listCoords(coordinatesRef);
      console.log('All done');
      app.delete();
    } else {
      console.log('No matching document found for trip name:', tripName);
    }

  } catch (error) {
    console.error('Error retrieving documents:', error);
  }
}

dumpTrip(process.argv[2]);

