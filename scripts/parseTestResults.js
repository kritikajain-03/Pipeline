const fs = require('fs');

const inputFile = process.argv[2];
const outputFile = process.argv[3];

const results = JSON.parse(fs.readFileSync(inputFile, 'utf8'));

let html = `<html><head><title>Test Report</title></head><body>`;
html += `<h1>Salesforce Test Validation Report</h1>`;
html += `<ul>`;

if (results.result && results.result.tests) {
  results.result.tests.forEach(test => {
    html += `<li><strong>${test.name}</strong>: ${test.outcome}`;
    if (test.message) {
      html += `<br/>Error: ${test.message}`;
    }
    html += `</li>`;
  });
}

html += `</ul></body></html>`;
fs.writeFileSync(outputFile, html);
