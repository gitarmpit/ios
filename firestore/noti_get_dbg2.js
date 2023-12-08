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


async function fetchDebugData() {
  try {
    const querySnapshot = await db.collection("debug").get();
    querySnapshot.forEach((doc) => {
      console.log(doc.id, '=>', doc.data());
    });

    console.log('done.');
    app.delete();
    // database.disableNetwork(); // Another way to do this, though not as clean
  } catch (error) {
    console.error('Error getting documents: ', error);
  }
}

fetchDebugData();
console.log('after fetch');
