const h=require('fs').readFileSync('roadmap/m365-roadmap-may.presenter.html','utf8');
const rhStart = h.indexOf('function renderHome');
const rhEnd = h.indexOf('function renderDetail');
const renderHome = h.substring(rhStart, rhEnd);
const rdEnd = h.indexOf('function openFeature');
const renderDetail = h.substring(rhEnd, rdEnd);

console.log('=== CARD VIEW (renderHome) ===');
console.log('Has f.notes:', renderHome.includes('f.notes'));
console.log('Has speaker-note div:', renderHome.includes('speaker-note'));

console.log('=== DETAIL VIEW (renderDetail) ===');
console.log('Has f.notes:', renderDetail.includes('f.notes'));
console.log('Has speaker-note div:', renderDetail.includes('speaker-note'));

console.log('=== SECTION NOTES ===');
console.log('SECTION_NOTES object:', h.includes('const SECTION_NOTES'));
console.log('renderSectionNotes fn:', h.includes('function renderSectionNotes'));
console.log('Called from render():', h.includes('renderSectionNotes();'));

console.log('=== DATA ===');
const noteRx = /notes:"/g;
let nc=0; while(noteRx.exec(h)) nc++;
console.log('Features with notes field:', nc);
const vpRx = /VP PLAY/g;
let vc=0; while(vpRx.exec(h)) vc++;
console.log('Notes with VP PLAY:', vc);
const bfRx = /HOW IT WORKED BEFORE/g;
let bc=0; while(bfRx.exec(h)) bc++;
console.log('Notes with BEFORE:', bc);

console.log('=== TOGGLE ===');
console.log('Toggle button:', h.includes('notes-toggle'));
console.log('hide-notes class:', h.includes('hide-notes'));

console.log('=== NAV ===');
const nav = h.match(/M365 Roadmap · ([^<]+)/);
console.log('Nav bar month:', nav ? nav[1] : 'NOT FOUND');
console.log('April 2026 leak:', h.includes('April 2026'));
