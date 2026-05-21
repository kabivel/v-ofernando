const h = require('fs').readFileSync('roadmap/m365-roadmap-may.html','utf8');
const needle = 'id:"559418"';
let pos = 0, locs = [];
while (true) {
  const i = h.indexOf(needle, pos);
  if (i === -1) break;
  locs.push(i);
  pos = i + 1;
}
const scriptPos = h.indexOf('const FEATURES = [');
console.log('const FEATURES starts at char:', scriptPos);
console.log('Occurrences of', needle, ':', locs.length);
locs.forEach((p, i) => console.log('  #' + i + ' at char ' + p + ' -> ' + (p < scriptPos ? 'COMMENT' : 'JS BLOCK')));

// Now check the build script logic
console.log('\n--- Simulating build injection ---');
const splitPos = h.indexOf('const FEATURES = [');
let commentPart = h.substring(0, splitPos);
let jsPart = h.substring(splitPos);

const testId = '559418';
const testNote = 'TEST NOTE HERE';
const regex = new RegExp('(\\{ id:"' + testId + '"[^}]+)(\\})');
const before = jsPart.match(regex);
console.log('Regex matches in jsPart:', !!before);
if (before) {
  console.log('Match starts at jsPart char:', before.index);
  console.log('Match snippet:', before[0].substring(0, 80) + '...');
}

// Check if the regex [^}]+ is too greedy or not greedy enough
const allFeatures = jsPart.match(/\{ id:"559418"[\s\S]*?\}/);
console.log('\nFull feature block length:', allFeatures ? allFeatures[0].length : 'NOT FOUND');
console.log('Contains closing }:', allFeatures ? allFeatures[0].endsWith('}') : false);

// The problem: does the feature have a } inside desc that stops the regex?
const descMatch = jsPart.match(/id:"559418"[\s\S]*?desc:"([^"]*)"/);
console.log('Desc for 559418:', descMatch ? descMatch[1].substring(0, 80) + '...' : 'NOT FOUND');
