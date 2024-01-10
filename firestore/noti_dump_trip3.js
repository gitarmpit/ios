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
    console.log("waiting for coords");
    const coordinatesSnapshot = await coordinatesRef.get();
    console.log("done waiting for coords");
    coordinatesSnapshot.forEach(function (doc) {
      const data = doc.data();
      //console.log("data: " + data);
      console.log(doc.id, "lat:" + data.lat + ", long:" + data.long);
    });
  } catch (error) {
    console.error('Error dumping trip:', error);
  }
}

async function dumpTrip(tripName) {
  try {

    const tripRef = db.collection('trips').doc(tripName);
    const doc = await tripRef.get();
    if (doc.exists) {
      const data = doc.data();
      console.log('Document:', data.ts.toDate());
      const coordinatesRef = doc.ref.collection('points');
      await listCoords(coordinatesRef);
      console.log('All done');
    } else {
      console.log('No matching document found for trip name:', tripName);
    }
    app.delete();

  } catch (error) {
    console.error('Error retrieving documents:', error);
  }
}

dumpTrip(process.argv[2]);

