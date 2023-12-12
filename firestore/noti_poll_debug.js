const fs = require('fs');

const firebase = require('firebase/compat/app');
const { create } = require('domain');
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

var fd = null;
var unsubscribe = null;

function createLog() {
  if (fd !== null) {
      fs.closeSync(fd)
  }
  const fname = "G:\\My Drive\\logs\\2\\noti." + ts2() + ".txt";
  fd = fs.openSync(fname, 'w')
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
      fs.writeSync(fd, ts() + ": " + d.ts + ": " + d.msg + "\n");
    }
    else {
      skip = false;
    }
  });

  setTimeout(subscribe, 3600 * 1000);

}

createLog();
subscribe();

