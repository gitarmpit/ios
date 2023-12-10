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

async function createTrip() {
  try {
    const tripId = ts(); // Custom ID format
    const tripRef = db.collection('trips').doc(tripId); // Use the custom ID
    const timestamp = firebase.firestore.Timestamp.now();
    const tripData = {
      id: tripId, // Set the name to the timestamp if desired
      ts: timestamp
    };

    await tripRef.set(tripData);

    return tripId; // Return the tripId
  } catch (error) {
    console.error('Error creating trip:', error);
    throw error; // Throw the error
  }
}


async function addCoordinate(tripId, seq, longitude, latitude) {
  try {
    const coordinatesRef = db.collection('trips').doc(tripId).collection('coordinates');

    const coordinateData = {
      longitude: longitude,
      latitude: latitude,
    };

    await coordinatesRef.doc(seq).set(coordinateData);
    console.log('Coordinate added to trip:', tripId);
  } catch (error) {
    console.error('Error adding coordinate:', error);
  }
}

async function main() {
  try {
    const tripId = await createTrip();
    console.log('Trip created:', tripId);
    let lat = 39.98081;
    let seq = 0;
    for (let i = 0; i < 10; ++i)
    {
      try {
        const sseq = seq.toString().padStart(3, '0');
        await addCoordinate(tripId, sseq, lat, -86.05617);
        await new Promise(resolve => setTimeout(resolve, 1000));
        lat += 0.00001;
        seq += 1;
      } catch (error) {
        console.error('Error in timer handler:', error);
      }
    }

    app.delete();

    // Other code that uses the tripId
  } catch (error) {
    console.error('Error creating trip:', error);
  }
}


// Call the async function
main();