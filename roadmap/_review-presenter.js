const fs = require('fs');
const h = fs.readFileSync('roadmap/m365-roadmap-may.presenter.html','utf8');

console.log('═══════════════════════════════════════════');
console.log('  PRESENTER FILE REVIEW');
console.log('═══════════════════════════════════════════\n');

// 1. Placeholders
const pl = h.match(/\{\{(MONTH_YEAR|MONTH_SLUG|VERSION|ISO_DATE|HEADLINE|SUBHEAD|FEATURES_JSON)\}\}/g);
console.log('Unfilled placeholders:', pl || 'NONE ✅');

// 2. Avanade leak
console.log('Avanade leak:', h.includes('Avanade') ? '❌ FOUND' : 'NONE ✅');

// 3. Presenter elements
console.log('\n── Presenter Structure ──');
console.log('INTERNAL banner:', h.includes('NOT FOR CLIENT DISTRIBUTION') ? '✅' : '❌ MISSING');
console.log('Notes toggle btn:', h.includes('notes-toggle') ? '✅' : '❌ MISSING');
console.log('SECTION_NOTES obj:', h.includes('SECTION_NOTES') ? '✅' : '❌ MISSING');
console.log('renderSectionNotes:', h.includes('renderSectionNotes') ? '✅' : '❌ MISSING');
console.log('Title [PRESENTER]:', h.includes('[PRESENTER]') ? '✅' : '❌ MISSING');
console.log('speaker-note CSS:', h.includes('.speaker-note{') ? '✅' : '❌ MISSING');
console.log('Presenter bio:', h.includes('Fernando') ? '✅' : '❌ MISSING');
console.log('Dark mode notes:', h.includes('body:not(.light) .speaker-note') ? '✅' : '❌ MISSING');
console.log('Print CSS:', h.includes('@media print') ? '✅' : '❌ MISSING');

// 4. Notes count
const noteMatches = h.match(/notes:"/g);
console.log('\n── Speaker Notes Injection ──');
console.log('Feature notes injected:', noteMatches ? noteMatches.length + '/15' : '❌ 0');

// 5. Card + detail rendering
console.log('Notes in card view:', h.includes('f.notes ?') ? '✅' : '❌ MISSING');
console.log('Notes in detail view:', h.includes('speaker-note" style="margin:18px') ? '✅' : '❌ MISSING');

// 6. Check 3 sections in each note
console.log('\n── Note Content Quality ──');
const ids = ['559478','553214','559261','557716','559418','558254','552595','559605','559611','561493','561549','561485','561330','557190','560547'];
let allGood = true;
for (const id of ids) {
  const rx = new RegExp('id:"' + id + '"[\\s\\S]{0,2000}?notes:"([\\s\\S]*?)"\\s*\\}');
  const m = h.match(rx);
  if (!m) {
    console.log('  ' + id + ': ❌ note not found');
    allGood = false;
    continue;
  }
  const note = m[1];
  const hasBefore = note.includes('HOW IT WORKED BEFORE');
  const hasNew = note.includes('WHAT CHANGED');
  const hasVP = note.includes('VP PLAY');
  if (!hasBefore || !hasNew || !hasVP) {
    console.log('  ' + id + ': ' + (hasBefore?'✅':'❌') + ' Before  ' + (hasNew?'✅':'❌') + ' Changed  ' + (hasVP?'✅':'❌') + ' VP Play');
    allGood = false;
  }
}
if (allGood) console.log('  All 15 notes have ⏪ Before + 🆕 Changed + 📌 VP Play ✅');

// 7. Section scripts
console.log('\n── Section Transition Scripts ──');
const sections = ['opening','launched','rolling','indev','closing'];
for (const s of sections) {
  console.log('  ' + s + ':', h.includes(s + ':') ? '✅' : '❌ MISSING');
}

// 8. Client version stays clean
console.log('\n── Client Version Isolation ──');
const client = fs.readFileSync('roadmap/m365-roadmap-may.html','utf8');
console.log('No speaker-note:', !client.includes('speaker-note') ? '✅ CLEAN' : '❌ LEAKED');
console.log('No SECTION_NOTES:', !client.includes('SECTION_NOTES') ? '✅ CLEAN' : '❌ LEAKED');
console.log('No INTERNAL banner:', !client.includes('NOT FOR CLIENT') ? '✅ CLEAN' : '❌ LEAKED');
console.log('No [PRESENTER] title:', !client.includes('[PRESENTER]') ? '✅ CLEAN' : '❌ LEAKED');

// 9. File sizes
const pSize = (fs.statSync('roadmap/m365-roadmap-may.presenter.html').size/1024).toFixed(1);
const cSize = (fs.statSync('roadmap/m365-roadmap-may.html').size/1024).toFixed(1);
console.log('\n── File Sizes ──');
console.log('  Client:    ' + cSize + ' KB');
console.log('  Presenter: ' + pSize + ' KB (+' + (pSize - cSize).toFixed(1) + ' KB notes)');

console.log('\n═══════════════════════════════════════════');
console.log('  REVIEW COMPLETE');
console.log('═══════════════════════════════════════════');
