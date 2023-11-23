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
const documentRef = db.doc('locations/distance');

const soundFiles = [
 'sounds/birdsmstone.mp3',
 'sounds/bullfrog_1_call.mp3',
 'sounds/chirps.mp3',
 'sounds/cricket.mp3',
 'sounds/cricket_10.mp3',
 'sounds/cricket_short.mp3',
 'sounds/d_chord_guitar.mp3',
 'sounds/disneyland_re_entry.mp3',
 'sounds/e_m_m_i_chirps.mp3',
 'sounds/goose_honk.mp3',
 'sounds/migos_chirpin.mp3',
 'sounds/notify.wav',
 'sounds/samsung_whistle.mp3',
 'sounds/sheep.mp3',
 'sounds/twitterriffic_chirp.mp3',
 'sounds/untitled_goose_honk.mp3',
];



// Get references to HTML elements
const startButton = document.getElementById('start-button');
const stopButton = document.getElementById('stop-button');
const saveLogButton = document.getElementById("saveLogButton");
const dataWindow = document.getElementById('data-window');
const errorMessage = document.getElementById('error-message');

let unsubscribe;

// Function to add data to the data window
function addDataToWindow(data) {
  const newItem = document.createElement('p');

  const someKey = data.some_key;
  const anotherKey = data.another_key;

  // Use the retrieved values as needed
  newItem.innerHTML = data['ts'] + ":&nbsp;&nbsp;&nbsp;&nbsp;From home: " + data.distanceFromHome.padStart(25, '\u00A0') + ", Total: " + data.totalDistance;
  newItem.style.lineHeight = '1.5';
  newItem.style.marginBottom = '0';
  newItem.style.marginTop = '0';
  
//newItem.textContent = JSON.stringify(data);
  dataWindow.appendChild(newItem);
  dataWindow.scrollTop = dataWindow.scrollHeight;
}

// Function to display error message
function displayError(message) {
  errorMessage.textContent = message;
}


function playRandomSound() {
  const randomIndex = Math.floor(Math.random() * soundFiles.length);
  const randomSound = soundFiles[randomIndex];

  const audio = new Audio();
  audio.src = randomSound;
  audio.play();
}

function reset() {
  if (unsubscribe) {
    unsubscribe();
    unsubscribe = null;
  }
  dataWindow.innerHTML = '';
  displayError(''); // Clear any previous error message
}

// Start button click event handler
startButton.addEventListener('click', function () {
  try {
    reset();
    unsubscribe = documentRef.onSnapshot(function (doc) {
      const source = doc.metadata.hasPendingWrites ? 'Local' : 'Server';
      const data = doc.data();
      console.log(source, data['ts']);
      playRandomSound();
      addDataToWindow(data);
    });
    displayError(''); // Clear any previous error message
  } catch (error) {
    displayError('An error occurred: ' + error.message);
  }
});

// Stop button click event handler
stopButton.addEventListener('click', reset);

saveLogButton.addEventListener("click", function () {
  const filename = prompt("Enter a filename:");

  if (filename) {
      const logContents = dataWindow.innerText;

      const blob = new Blob([logContents], { type: "text/plain" });

      const url = URL.createObjectURL(blob);

      const link = document.createElement("a");
      link.href = url;
      link.download = filename;

      link.click();

      URL.revokeObjectURL(url);
      link.remove();
  }
});

