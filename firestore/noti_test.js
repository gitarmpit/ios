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

//const cref = db.doc('trips/2023-12-10 22:11:06').collection('points');


async function iterateThroughPoints() {
  const pointsCollection = db
    .collection('trips')
    .doc('2023-12-10 22:11:06')
    .collection('points');

  try {
    const querySnapshot = await pointsCollection.get();

    querySnapshot.forEach((doc) => {
      const pointData = doc.data();
      // Do something with the data...
      console.log(pointData.lat);
    });
  } catch (error) {
    // Handle any errors that occur during the retrieval
    console.error('Error retrieving points:', error);
  }
}

// Call the function to start iterating through the points
iterateThroughPoints();