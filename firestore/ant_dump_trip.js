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


function listCoords(collectionPath) {
  const collectionRef = db.collection(collectionPath);

  collectionRef.get()
    .then(function(querySnapshot) {
      querySnapshot.forEach(function(doc) {
        console.log('Document:', doc.id);
      });

      console.log ('All done');
      app.delete();
    })
    .catch(function(error) {
      console.error('Error dumping coords:', error);
    });
}


function listCoords(coordinatesRef) {
 coordinatesRef.get()
          .then(function(coordinatesSnapshot) {
            coordinatesSnapshot.forEach(function(doc) {
              const data = doc.data();
              console.log('Coordinate:', doc.id, "lat:" + data.latitude + ", long:" + data.longitude);
            });
    })
    .catch(function(error) {
      console.error('Error dumping trip:', error);
    });
}


function dumpTrip(tripName) {
  const collectionRef = db.collection('trips');

  collectionRef
    .where('id', '==', tripName)
    .limit(1)
    .get()
    .then(function(querySnapshot) {
      if (!querySnapshot.empty) {
        const doc = querySnapshot.docs[0];
        const data = doc.data();
        console.log('Document:', data.ts.toDate());

        const coordinatesRef = doc.ref.collection('coordinates');
        listCoords(coordinatesRef);
      } else {
        console.log('No matching document found for trip name:', tripName);
      }

      console.log('All done');
    })
    .catch(function(error) {
      console.error('Error retrieving documents:', error);
    });
}

dumpTrip('2023-12-07 23:07:53');


