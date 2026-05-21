const fs = require('fs');
const h = fs.readFileSync('roadmap/m365-roadmap-may.html', 'utf8');
const js = h.substring(h.indexOf('const FEATURES = ['));

// Find the feature 559418
const needle = 'id:"559418"';
const start = js.indexOf(needle) - 2; // back to the {
const chunk = js.substring(start, start + 600);

console.log('=== Raw feature object (first 600 chars) ===');
console.log(chunk);
console.log('\n=== Closing brace analysis ===');
for (let i = 0; i < chunk.length; i++) {
  if (chunk[i] === '}') {
    console.log('} at offset', i, ':', JSON.stringify(chunk.substring(i - 10, i + 5)));
    break;
  }
}

// Now try the actual regex from the build script
const regex = new RegExp('(\\{ id:"559418"[^}]+)(\\})');
const m = js.match(regex);
if (m) {
  console.log('\n=== Regex match ===');
  console.log('Full match length:', m[0].length);
  console.log('Last 60 chars of match:', m[0].substring(m[0].length - 60));
} else {
  console.log('\n❌ Regex did NOT match');
}

// Try the replacement
let testJs = js;
testJs = testJs.replace(regex, (match, before, close) => {
  return before + ',\n    notes:"TEST" ' + close;
});

// Check if replacement worked
const check = testJs.indexOf('notes:"TEST"');
console.log('\nReplacement result:', check > -1 ? 'SUCCESS at pos ' + check : 'FAILED');

// Double-check: what does the source file have between features?
const afterMatch = js.substring(start, start + 450);
const closingPattern = afterMatch.match(/"\s*\}/);
if (closingPattern) {
  console.log('\nFeature closing pattern:', JSON.stringify(closingPattern[0]));
  console.log('At index in chunk:', closingPattern.index);
}
