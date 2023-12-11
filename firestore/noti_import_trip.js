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

const jsonData = fs.readFileSync('points.json', 'utf-8');
const pointsData = JSON.parse(jsonData);

const tripRef = db.collection('trips').doc(tripName);
tripRef.set({}).then(() => {
  console.log("trip created");
})


const pointsCollection = tripRef.collection('points');

let seq = 0;

pointsData.forEach((point) => {
  const sseq = seq.toString().padStart(4, '0');
  const pointRef = pointsCollection.doc(sseq);
  ++seq;

  pointRef.set(point)
    .then(() => {
      console.log(`Point with ID ${seq} added successfully.`);
    })
    .catch((error) => {
      console.error(`Error adding point with ID ${seq}:`, error);
    });
});
