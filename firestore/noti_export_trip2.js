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

const pointsCollection = db.collection('trips').doc(tripName).collection('points');

pointsCollection.get().then((querySnapshot) => {

  const pointsData = [];
  querySnapshot.forEach((pointDoc) => {
    const pointData = pointDoc.data();
    pointsData.push(pointData);
  });

  // Convert pointsData to JSON
  const pointsJSON = JSON.stringify(pointsData, null, 2);

  // Write pointsJSON to a file
  const fname = "points.json";
  fs.writeFileSync(fname, pointsJSON);

  console.log('Export successful!');
}).catch((error) => {
  console.error('Error fetching documents:', error);
});
