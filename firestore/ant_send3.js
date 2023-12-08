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

    var tripData = {
      name: timestamp // Set the name to the timestamp if desired
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

function createTrip2() {
  var timestamp = ts();
  var tripId = timestamp; // Custom ID format
  var tripRef = db.collection('trips').doc(tripId); // Use the custom ID

  var tripData = {
    name: timestamp // Set the name to the timestamp if desired
  };

  return tripRef.set(tripData)
    .then(function () {
      console.log('Trip created with ID:', tripId);
      return tripId; // Return the tripId for subsequent use
    })
    .catch(function (error) {
      console.error('Error creating trip:', error);
      throw error; // Throw the error to be caught later
    });
}

createTrip2()
  .then(function (tripId) {
    // Continue with your code in the "then" clause
    console.log('Continuing with trip ID:', tripId);
  })
  .catch(function (error) {
    // Handle the error
    console.error('Error in createTrip:', error);
  });

console.log ("after createTrip");
app.delete();
