const fs = require('fs');
const readline = require('readline');

async function extractTests() {

  const testsFile = __dirname + '/testsToRun.txt';
  await fs.promises.writeFile(testsFile, 'all');

  const lines = readline.createInterface({
    input: fs.createReadStream(__dirname + '/pr_body.txt'),
    crlfDelay: Infinity
  });

  for await (const line of lines) {
    if (line.includes('Apex::[') && line.includes(']::Apex')) {

      const tests = line
        .replace('Apex::[', '')
        .replace(']::Apex', '')
        .trim();

      await fs.promises.writeFile(testsFile, tests);
      await fs.promises.appendFile(testsFile, '\n');
    }
  }
}

extractTests();
