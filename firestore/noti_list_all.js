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
    coordinatesSnapshot.forEach(function (coordinateDoc) {
      const coordinateData = coordinateDoc.data();
      console.log('Coordinate:', coordinateDoc.id, coordinateData);
    });
  } catch (error) {
    console.error('Error deleting documents:', error);
  }
}

async function listTrips() {
  try {
    const collectionRef = db.collection('trips');

    const querySnapshot = await collectionRef.get();
    querySnapshot.forEach(async function (doc) {
      const data = doc.data();
      console.log('Document:' + doc.id + ", " + data.id + ", " + data.ts.toDate());
      const coordinatesRef = doc.ref.collection('coordinates');
      await listCoords(coordinatesRef);
    });

    console.log('All done');
    app.delete();
  } catch (error) {
    console.error('Error deleting documents:', error);
  }
}

listTrips();
