const fs = require('fs');

const firebase = require('firebase/compat/app');
const { create } = require('domain');
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

const documentRef = db.doc('debug/debug');

function ts() {
  const date = new Date();

  const hours = date.getHours().toString().padStart(2, "0");
  const minutes = date.getMinutes().toString().padStart(2, "0");
  const seconds = date.getSeconds().toString().padStart(2, "0");

  return `${hours}:${minutes}:${seconds}`;
}


function ts2() {
  const now = new Date();

  const year = now.getFullYear();
  const month = String(now.getMonth() + 1).padStart(2, '0');
  const day = String(now.getDate()).padStart(2, '0');
  const hours = String(now.getHours()).padStart(2, '0');
  const minutes = String(now.getMinutes()).padStart(2, '0');
  const seconds = String(now.getSeconds()).padStart(2, '0');

  const timestamp = `${year}-${month}-${day}.${hours}-${minutes}-${seconds}`;
  return timestamp;
}

var unsubscribe = null;
var fname = "";

function createLog() {
  fname = "G:\\My Drive\\logs\\2\\ant." + ts2() + ".txt";
}

var skip = false;

function subscribe() {

  if (unsubscribe !== null) {
    skip = true;
    unsubscribe();
  }

  // new file at 7am
  var currentHour = new Date().getHours();
  if (currentHour === 7) {
    createLog();
  }

  unsubscribe = documentRef.onSnapshot(function (doc) {
    var d = doc.data()
    if (!skip) {
      try {
        var fd = fs.openSync(fname, 'a')
        fs.writeSync(fd, ts() + ": " + d.ts + ": " + d.msg + "\n");
        fs.closeSync(fd)
      }
      catch (error) {
        console.log("io error: " + error)
      }
    }
    else {
      skip = false;
    }
  });

  setTimeout(subscribe, 3600 * 1000);

}

createLog();
subscribe();

