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

let tripName = process.argv[2];

const app = firebase.initializeApp(firebaseConfig);
const db = firebase.firestore();

const exportTrip = async (tripName) => {
  try {
    const tripRef = db.collection('trips').doc(tripName);
    const tripSnapshot = await tripRef.get();

    if (tripSnapshot.exists) {
      const tripData = tripSnapshot.data();

      const pointsSnapshot = await tripRef.collection('points').get();
      const pointsData = [];

      pointsSnapshot.forEach((pointDoc) => {
        const pointData = {
          id: pointDoc.id,
          data: pointDoc.data(),
        };
        pointsData.push(pointData);
      });

      tripData.points = pointsData;

      const jsonData = JSON.stringify(tripData, null, 2);

      fs.writeFileSync('exported_trip2.json', jsonData);

      console.log(`Trip "${tripName}" exported successfully.`);
      app.delete();
    } else {
      console.log(`Trip "${tripName}" does not exist.`);
    }
  } catch (error) {
    console.error('Error exporting trip:', error);
  }
};

exportTrip(process.argv[2]);
