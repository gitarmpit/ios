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

let long = 39.98081;
let lat = -86.05617;
let distance = 0;
let durationInSeconds = 0;
let speedSum = 0;
let count = 0;

async function addPoint() {
  long += 0.00009; // Increase longitude by 10 meters (adjust this value as needed)
  distance += 10; // Increase distance by 10 meters
  durationInSeconds += 10; // Increase duration by 10 seconds

  const speed = Math.random() + 1; // Generate random speed between 1 and 2 m/s
  speedSum += speed;
  count++;

  const speedAvg = speedSum / count;

  let doc = db.collection('trips').doc('current');
  const data = {
    longitude: long,
    latitude: lat,
    distance: distance,
    duration: formatDuration(durationInSeconds),
    speed: speed,
    speedAvg: speedAvg,
  };
  await doc.set(data);
}

function formatDuration(durationInSeconds) {
  const hours = Math.floor(durationInSeconds / 3600);
  const minutes = Math.floor((durationInSeconds % 3600) / 60);
  const seconds = durationInSeconds % 60;
  return `${padZero(hours)}:${padZero(minutes)}:${padZero(seconds)}`;
}

function padZero(number) {
  return number.toString().padStart(2, '0');
}

setInterval(addPoint, 2000); // Call addPoint every second
