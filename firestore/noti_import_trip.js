const fs = require('fs');
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

const tripImport = async (fileName) => {
  try {
    // Read the JSON file
    const jsonData = fs.readFileSync(fileName, 'utf8');

    // Parse the JSON data
    const tripData = JSON.parse(jsonData);

    const { speedAvg, distance, ts, points } = tripData;
    const timestamp = new firebase.firestore.Timestamp(
      ts.seconds,
      ts.nanoseconds
    );

    // Create a new trip document in the "trips" collection
    const tripRef = db.collection('trips').doc(tripData.id + " - 2");
    await tripRef.set({
      speedAvg,
      distance,
      ts: timestamp,
    });

    const pointsCollectionRef = tripRef.collection('points');

    for (let i = 0; i < tripData.points.length; i++) {
      const point = tripData.points[i].data;
      console.log ("importing " + tripData.points[i].id); 
      await pointsCollectionRef.doc(tripData.points[i].id).set(point);
    }
    console.log('Trip imported successfully.');
    app.delete();

  } catch (error) {
    console.error('Error importing trip:', error);
  }
};

tripImport(process.argv[2]);
