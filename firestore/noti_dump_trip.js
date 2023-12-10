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



function listCoords(coordinatesRef) {
 coordinatesRef.get()
          .then(function(coordinatesSnapshot) {
            console.log("cs: " + coordinatesSnapshot);  
            coordinatesSnapshot.forEach(function(doc) {
              const data = doc.data();
	      console.log("data: " + data);	
              //console.log('Coordinate:', doc.id, "lat:" + data.latitude + ", long:" + data.longitude);
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

dumpTrip(process.argv[2]);


