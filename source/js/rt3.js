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

const documentRef = db.doc('locations/distance');

// Set up the listener using onSnapshot
const unsubscribe = documentRef.onSnapshot(function(doc) {
  const source = doc.metadata.hasPendingWrites ? 'Local' : 'Server';
  var d = doc.data()
  console.log(source, d.ts + ":  From home: " + d.distanceFromHome.padStart(25, ' ') + ", Total: " + d.totalDistance );
});
