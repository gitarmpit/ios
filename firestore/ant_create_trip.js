const firebase = require('firebase/compat/app');
require('firebase/auth');
require('firebase/compat/firestore');

const firebaseConfig = {
  apiKey: "AIzaSyCD64bdXEW2qybbkcmQlAnW7LC52u50RGg",
  authDomain: "anatoly.firebaseapp.com",
  projectId: "anatoly",
  storageBucket: "anatoly.appspot.com",
  messagingSenderId: "66148611453",
  appId: "1:66148611453:web:232098e729298c15180814"
};

const app = firebase.initializeApp(firebaseConfig);

const db = firebase.firestore();

function ts() {
  const now = new Date();

  const year = now.getFullYear();
  const month = String(now.getMonth() + 1).padStart(2, '0');
  const day = String(now.getDate()).padStart(2, '0');
  const hours = String(now.getHours()).padStart(2, '0');
  const minutes = String(now.getMinutes()).padStart(2, '0');
  const seconds = String(now.getSeconds()).padStart(2, '0');

  const timestamp = `${year}-${month}-${day} ${hours}:${minutes}:${seconds}`;
  return timestamp;
}

function createTrip() {
  return new Promise((resolve, reject) => {
    var tripId = ts(); // Custom ID format
    var tripRef = db.collection('trips').doc(tripId); // Use the custom ID
    var timestamp = firebase.firestore.Timestamp.now();
    var tripData = {
      id: tripId, // Set the name to the timestamp if desired
      ts: timestamp
    };

    tripRef.set(tripData)
      .then(function () {
        console.log('Trip created with ID:', tripId);
        resolve(tripId); // Resolve the promise with the tripId
      })
      .catch(function (error) {
        console.error('Error creating trip:', error);
        reject(error); // Reject the promise with the error
      });
  });
}

function addCoordinate(tripId, seq, longitude, latitude) {
  const coordinatesRef = db.collection('trips').doc(tripId).collection('coordinates');

  const coordinateData = {
    longitude: longitude,
    latitude: latitude,
  };

  coordinatesRef
    .doc(seq.toString().padStart(3, '0'))
    .set(coordinateData)
    .then((docRef) => {
      console.log('Coordinate added to trip:', tripId);
    })
    .catch((error) => {
      console.error('Error adding coordinate:', error);
    });
}

createTrip()
  .then(function (tripId) {
    console.log('Continuing with trip ID:', tripId);
    let lat = 39.98081;
    let seq = 0;
    setInterval(() => {
      addCoordinate(tripId, seq, lat, -86.05617);
      lat += 0.00001;
      seq += 1;
    }, 1000);

  })
  .catch(function (error) {
    // Handle the error
    console.error('Error in createTrip:', error);
  });

console.log("after createTrip");