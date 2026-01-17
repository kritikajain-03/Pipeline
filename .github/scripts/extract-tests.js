const fs = require('fs');
const event = JSON.parse(fs.readFileSync(process.env.GITHUB_EVENT_PATH));
const body = event.pull_request?.body || '';

let testsToRun = 'all';
const match = body.match(/Apex::\[(.*?)\]::Apex/);
if (match && match[1]) {
  testsToRun = match[1].trim();
}

fs.writeFileSync('testsToRun.txt', testsToRun);
console.log('Tests to run:', testsToRun);
