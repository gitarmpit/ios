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

const firestore = firebase.firestore();


firestore
  .collection("debug")
  .get()
  .then(function(querySnapshot) {
    querySnapshot.forEach(function(doc) {
      console.log(doc.id, '=>', doc.data());
    });
  })
  .then(() => {
      console.log('done.');
      app.delete();
      // database.disableNetwork(); // Another way to do this, though not as clean
  })
  .catch(function(error) {
    console.error('Error getting documents: ', error);
  });