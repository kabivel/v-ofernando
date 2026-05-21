const fs = require('fs');
let h = fs.readFileSync('roadmap/m365-roadmap-may.presenter.html', 'utf8');

// Replace emoji section markers with plain text + newlines
// Notes are in JS double-quoted strings, so \n creates a line break
h = h.replaceAll('\u23EA HOW IT WORKED BEFORE:', '\\nBEFORE:\\n');
h = h.replaceAll('\uD83C\uDD95 WHAT CHANGED:', '\\nWHAT CHANGED:\\n');
h = h.replaceAll('\uD83D\uDCCC VP PLAY:', '\\nVP PLAY:\\n');

// Also handle the unicode versions just in case
h = h.replaceAll('⏪ HOW IT WORKED BEFORE:', '\\nBEFORE:\\n');
h = h.replaceAll('🆕 WHAT CHANGED:', '\\nWHAT CHANGED:\\n');
h = h.replaceAll('📌 VP PLAY:', '\\nVP PLAY:\\n');

// Add line breaks after sentences ending with period+space in notes
// Only inside notes:"..." fields - do this carefully
// Split on notes:" and process each one
const parts = h.split('notes:"');
for (let i = 1; i < parts.length; i++) {
  const endQuote = parts[i].indexOf('" }');
  if (endQuote === -1) continue;
  let note = parts[i].substring(0, endQuote);
  // Add \n after each sentence (period followed by space and uppercase letter)
  note = note.replace(/\. ([A-Z])/g, '.\\n$1');
  parts[i] = note + parts[i].substring(endQuote);
}
h = parts.join('notes:"');

fs.writeFileSync('roadmap/m365-roadmap-may.presenter.html', h, 'utf8');

// Count
const beforeCount = (h.match(/BEFORE:/g) || []).length;
const changedCount = (h.match(/WHAT CHANGED:/g) || []).length;
const vpCount = (h.match(/VP PLAY:/g) || []).length;
console.log('BEFORE:', beforeCount, '| WHAT CHANGED:', changedCount, '| VP PLAY:', vpCount);
console.log('File size:', (fs.statSync('roadmap/m365-roadmap-may.presenter.html').size / 1024).toFixed(1), 'KB');
