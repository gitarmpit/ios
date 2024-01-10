const fs = require('fs');
const path = require('path');

const folderPath = '/path/to/folder'; // Replace with the path to your folder

fs.readdir(folderPath, (err, files) => {
  if (err) {
    console.error('Error reading folder:', err);
    return;
  }

  const fileList = [];
  files.forEach((file) => {
    const filePath = path.join(folderPath, file);
  });

  console.log('List of files:');
  fileList.forEach((file) => {
    console.log(file);
  });
});

/////////////////////////////////////////////////////
// separate func 

fs.readdir(folderPath, handleFolderContents);

function handleFolderContents(err, files) {
  if (err) {
    console.error('Error reading folder:', err);
    return;
  }

  const fileList = [];
  files.forEach((file) => {
    const filePath = path.join(folderPath, file);
  });

  console.log('List of files:');
  fileList.forEach((file) => {
    console.log(file);
  });
}

///////////////////////////

files.forEach(processFile);

function processFile(file) {
  const filePath = path.join(folderPath, file);
  // ... Do something with the file
}

