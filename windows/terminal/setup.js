#!/usr/bin/env node

const fs = require('fs');
const jsonc = require('jsonc-parser');

function loadJson(filePath) {
  const jsonString = fs.readFileSync(filePath, 'UTF-8');
  return jsonc.parse(jsonString);
}

const targetFile = process.argv[2];

const newSettings = loadJson(__dirname + '/settings.json');
const curSettings = loadJson(targetFile);

for (let scheme in newSettings.schemes) {
  curSettings.schemes.add(scheme);
}



