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

const unsubscribe = firestore.collection("locations")
  .onSnapshot(function(querySnapshot) {
    querySnapshot.docChanges().forEach(function(change) {
      if (change.type === "added") {
        console.log("New document added: ", change.doc.data());
      }
      if (change.type === "modified") {
        console.log("Modified document: ", change.doc.data());
      }
      if (change.type === "removed") {
        console.log("Removed document: ", change.doc.data());
      }
    });
  });