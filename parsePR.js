// parsePR.js
const fs = require('fs');

const prBody = fs.readFileSync('./pr_body.txt', 'utf8');

const regex = /Apex::\[(.*?)\]::Apex/;
const match = prBody.match(regex);

let tests = 'all';

if (match && match[1]) {
  tests = match[1].trim();
}

fs.writeFileSync('testsToRun.txt', tests);
