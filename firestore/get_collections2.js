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

 db.listCollections().toArray(function(err, items) {
        console.log(items)
    });

//db.listCollections().then(collections => {
//  for (let collection of collections) {
//    console.log(`Found collection with id: ${collection.id}`);
//  }
//});