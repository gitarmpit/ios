const admin = require('firebase-admin');
var serviceAccount = require("./noti-27763-firebase-adminsdk-50m9m-ad8c3491a8.json");

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount),
  databaseURL: "https://noti-27763-default-rtdb.firebaseio.com"
});


// Get Firestore instance
const firestore = admin.firestore();


// Get all collections in Firestore
async function getCollections() {
  const collections = await firestore.listCollections();
  const collectionNames = collections.map((collection) => collection.id);
  return collectionNames;
}

// Usage example
getCollections()
  .then((collectionNames) => {
    console.log(collectionNames);
  })
  .catch((error) => {
    console.error('Error getting collections:', error);
  });
