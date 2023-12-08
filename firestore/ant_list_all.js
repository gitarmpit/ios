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
      console.error('Error deleting documents:', error);
    });
}


function listCoords(coordinatesRef) {
 coordinatesRef.get()
          .then(function(coordinatesSnapshot) {
            coordinatesSnapshot.forEach(function(coordinateDoc) {
              const coordinateData = coordinateDoc.data();
              console.log('Coordinate:', coordinateDoc.id, coordinateData);
            });
    })
    .catch(function(error) {
      console.error('Error deleting documents:', error);
    });
}

function listTrips() {
  const collectionRef = db.collection('trips');

  collectionRef.get()
    .then(function(querySnapshot) {
      querySnapshot.forEach(function(doc) {
        const data = doc.data();
        console.log('Document:' +  doc.id + ", " + data.id + ", " + data.ts.toDate());
	const coordinatesRef = doc.ref.collection('coordinates');
        listCoords(coordinatesRef);
      });

      console.log ('All done');
      //app.delete();
    })
    .catch(function(error) {
      console.error('Error deleting documents:', error);
    });
}



listTrips();


