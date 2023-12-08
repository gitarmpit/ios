const fs = require('fs');

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
console.log = function(message) {
  logStream.write(message + '\n');
  process.stdout.write(message + '\n');
};

const db = firebase.firestore();

const documentRef = db.doc('debug/debug');

var logStream = null;


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

function subscribe() {
  if (unsubscribe !== null) {
    unsubscribe();
    if (logStream !== null) {
      logStream.end();
    }
  }

  const fname = "noti." + ts2();
  logStream = fs.createWriteStream(fname, { flags: 'a' });

  unsubscribe = documentRef.onSnapshot(function(doc) {
    const source = doc.metadata.hasPendingWrites ? 'Local' : 'Server';
    var d = doc.data()
    console.log(ts() + ": " + d.ts + ": " + d.msg );
  });
  
}

subscribe();
setInterval(subscribe, 3600*24*1000);

