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

async function deleteAllDocuments(collectionPath) {
  const collectionRef = db.collection(collectionPath);

  try {
    const querySnapshot = await collectionRef.get();
    const deletePromises = [];

    querySnapshot.forEach(function(doc) {
      deletePromises.push(deleteDocumentAndSubcollections(doc.ref));
    });

    await Promise.all(deletePromises);
    console.log('All done');
    process.exit(); // Exit the Node.js process
  } catch (error) {
    console.error('Error deleting documents:', error);
    process.exit(1); // Exit with an error code
  }
}

async function deleteDocumentAndSubcollections(docRef) {
  const coordinatesRef = docRef.collection('coordinates');
  const querySnapshot = await coordinatesRef.get();

  const deletePromises = querySnapshot.docs.map(function(doc) {
    return doc.ref.delete();
  });

  await Promise.all(deletePromises);
  console.log('Subcollection documents deleted:', coordinatesRef.path);

  await docRef.delete();
  console.log('Document deleted:', docRef.id);
}

deleteAllDocuments('trips');

