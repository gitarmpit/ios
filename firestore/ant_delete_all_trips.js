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

function deleteAllDocuments(collectionPath) {
  const collectionRef = db.collection(collectionPath);

  collectionRef.get()
    .then(function(querySnapshot) {
      querySnapshot.forEach(function(doc) {
        deleteDocumentAndSubcollections(doc.ref);
        console.log('Document deleted:', doc.id);
      });

      console.log('All done');
    })
    .catch(function(error) {
      console.error('Error deleting documents:', error);
    });
}


function deleteDocumentAndSubcollections(docRef) {
  const coordinatesRef = docRef.collection('coordinates');
  coordinatesRef.get().then(function(querySnapshot) {
    querySnapshot.forEach(function(doc) {
      doc.ref.delete();
      console.log('Subcollection document deleted:', doc.id);
    });
    docRef.delete();
    console.log('Document deleted:', docRef.id);
  });
}

deleteAllDocuments('trips');

