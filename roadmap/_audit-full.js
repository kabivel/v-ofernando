const fs=require('fs');
const p = fs.readFileSync('roadmap/m365-roadmap-may.presenter.html','utf8');
const c = fs.readFileSync('roadmap/m365-roadmap-may.html','utf8');

console.log('══════════════════════════════════════════════');
console.log('  FULL PREMISE AUDIT');
console.log('══════════════════════════════════════════════');

// 1. Feature count
const idRx = /id:"(\d+)"/g;
const jsBlock = c.substring(c.indexOf('const FEATURES'));
const jsIds = new Set();
let m;
while(m=idRx.exec(jsBlock)) jsIds.add(m[1]);
console.log('\n── Features ──');
console.log('Unique features in FEATURES array:', jsIds.size);

// Also count in the HTML comment header
const commentBlock = c.substring(0, c.indexOf('</head>'));
const cIdRx = /id:"(\d+)"/g;
const commentIds = new Set();
while(m=cIdRx.exec(commentBlock)) commentIds.add(m[1]);
console.log('Feature IDs in HTML comment block:', commentIds.size);
const inCommentNotJS = [...commentIds].filter(x=>!jsIds.has(x));
const inJSNotComment = [...jsIds].filter(x=>!commentIds.has(x));
if(inCommentNotJS.length) console.log('  ❌ In comment but NOT in JS:', inCommentNotJS.join(', '));
if(inJSNotComment.length) console.log('  ❌ In JS but NOT in comment:', inJSNotComment.join(', '));
if(!inCommentNotJS.length && !inJSNotComment.length) console.log('  Comment and JS match ✅');

// 2. Status breakdown from JS
const statusRx = /status:"([^"]+)"/g;
const statuses = {};
while(m=statusRx.exec(jsBlock)) statuses[m[1]]=(statuses[m[1]]||0)+1;
console.log('Status breakdown:');
for(const [k,v] of Object.entries(statuses)) console.log('  '+k+': '+v);

// 3. Dates/versions
console.log('\n── Dates & Versions ──');
// dispatch tag
const dispatchMatch = c.match(/M365\.Roadmap\.(\w+)\s*·\s*v([\d.]+)/);
if(dispatchMatch) {
  console.log('Dispatch tag: M365.Roadmap.' + dispatchMatch[1] + ' · v' + dispatchMatch[2]);
  if(dispatchMatch[1]!=='May') console.log('  ❌ Month slug should be "May"');
  if(dispatchMatch[2]!=='2026.05') console.log('  ❌ Version should be "2026.05" not "' + dispatchMatch[2] + '"');
} else {
  console.log('  ❌ Dispatch tag not found');
}

// Footer source date
const footerMatch = c.match(/Roadmap RSS feed \(([^)]+)\)/);
if(footerMatch) {
  console.log('Footer source date: ' + footerMatch[1]);
  if(!footerMatch[1].startsWith('05/')) console.log('  ❌ Should start with 05/ for May');
} else {
  console.log('  ❌ Footer source date not found');
}

// 4. Bottom nav bar text
console.log('\n── Bottom Nav Bar ──');
const navMatch = c.match(/<span>M365 Roadmap · ([^<]+)<\/span>/);
if(navMatch) {
  console.log('Nav brand: "M365 Roadmap · ' + navMatch[1] + '"');
  if(!navMatch[1].includes('May')) console.log('  ❌ Should reference May 2026, not "' + navMatch[1] + '"');
} else {
  console.log('  ❌ Nav brand text not found');
}

// 5. Title tag
console.log('\n── Title Tags ──');
const titleC = c.match(/<title>([^<]+)<\/title>/);
const titleP = p.match(/<title>([^<]+)<\/title>/);
console.log('Client title: ' + (titleC?titleC[1]:'NOT FOUND'));
console.log('Presenter title: ' + (titleP?titleP[1]:'NOT FOUND'));

// 6. Cover subtitle consistency
console.log('\n── Cover Content ──');
const coverSubC = c.match(/cover-subtitle[^>]*>([^<]+)/);
if(coverSubC) console.log('Cover subtitle mentions: ' + (coverSubC[1].includes('May 2026') ? 'May 2026 ✅' : '❌ wrong month'));

// 7. Hardcoded "April" anywhere?
console.log('\n── Stale Month References ──');
const aprilCount = (c.match(/April 2026/g)||[]).length;
console.log('Client "April 2026" occurrences:', aprilCount, aprilCount>0?'❌':'✅');
const aprilCountP = (p.match(/April 2026/g)||[]).length;
console.log('Presenter "April 2026" occurrences:', aprilCountP, aprilCountP>0?'❌':'✅');

// 8. Template references in agent files
console.log('\n── Agent File References ──');
try {
  const a1 = fs.readFileSync('roadmap/m365-roadmap-page.agent.md','utf8');
  console.log('Page agent exists: ✅');
  console.log('  Points to roadmap/m365-roadmap.template.html:', a1.includes('roadmap/m365-roadmap.template.html') ? '✅' : '❌');
  console.log('  Still references Template/:', a1.includes('Template/m365-roadmap') ? '❌ OLD PATH' : '✅ clean');
  console.log('  Output to roadmap/:', a1.includes('roadmap/m365-roadmap-') ? '✅' : '❌');
} catch(e) { console.log('Page agent: ❌ FILE NOT FOUND at roadmap/'); }

try {
  const a2 = fs.readFileSync('roadmap/m365-roadmap.agent.md','utf8');
  console.log('Collector agent exists: ✅');
} catch(e) { console.log('Collector agent: ❌ FILE NOT FOUND at roadmap/'); }

// 9. Template file
console.log('\n── Template File ──');
try {
  const tmpl = fs.readFileSync('roadmap/m365-roadmap.template.html','utf8');
  console.log('Template exists: ✅');
  console.log('Template has Avanade:', tmpl.includes('Avanade') ? '❌' : '✅ clean');
  const tmplNav = tmpl.match(/<span>M365 Roadmap · ([^<]+)<\/span>/);
  if(tmplNav) {
    console.log('Template nav brand: "' + tmplNav[1] + '"');
    if(!tmplNav[1].includes('{{') && !tmplNav[1].includes('MONTH')) console.log('  ❌ Hardcoded month — should use placeholder');
  }
} catch(e) { console.log('Template: ❌ NOT FOUND at roadmap/'); }

// 10. index.html references
console.log('\n── index.html ──');
try {
  const idx = fs.readFileSync('index.html','utf8');
  console.log('index.html exists: ✅');
  console.log('Has Avanade:', idx.includes('Avanade') ? '❌' : '✅ clean');
  const idxNav = idx.match(/<span>M365 Roadmap · ([^<]+)<\/span>/);
  if(idxNav) console.log('index.html nav brand: "' + idxNav[1] + '"');
} catch(e) { console.log('index.html: NOT FOUND'); }

// 11. Presenter specific
console.log('\n── Presenter Specific ──');
const pDispatch = p.match(/M365\.Roadmap\.(\w+)\s*·\s*v([\d.]+)/);
if(pDispatch) {
  console.log('Presenter dispatch: M365.Roadmap.' + pDispatch[1] + ' · v' + pDispatch[2]);
  if(pDispatch[2]!=='2026.05') console.log('  ❌ Version mismatch');
}
const pNavMatch = p.match(/<span>M365 Roadmap · ([^<]+)<\/span>/);
if(pNavMatch) {
  console.log('Presenter nav brand: "' + pNavMatch[1] + '"');
  if(!pNavMatch[1].includes('May')) console.log('  ❌ Should reference May');
}

// 12. Stale files
console.log('\n── Stale / Orphan Files ──');
const roadmapFiles = fs.readdirSync('roadmap');
console.log('Files in roadmap/:');
roadmapFiles.forEach(f => {
  const sz = (fs.statSync('roadmap/'+f).size/1024).toFixed(1);
  console.log('  ' + f.padEnd(45) + sz + ' KB');
});

// 13. HTML well-formedness
console.log('\n── HTML Well-formedness ──');
console.log('Client starts <!DOCTYPE:', c.trimStart().startsWith('<!DOCTYPE') ? '✅' : '❌');
console.log('Client has </html>:', c.includes('</html>') ? '✅' : '❌');
console.log('Client has </body>:', c.includes('</body>') ? '✅' : '❌');
console.log('Presenter has </html>:', p.includes('</html>') ? '✅' : '❌');
console.log('Presenter has </body>:', p.includes('</body>') ? '✅' : '❌');

// 14. Features with dates NOT May 2026 (are we including irrelevant months?)
console.log('\n── Feature Date Relevance ──');
const dateRx = /id:"(\d+)"[^}]*?date:"([^"]+)"/g;
const nonMay = [];
while(m=dateRx.exec(jsBlock)) {
  if(!m[2].includes('May 2026')) nonMay.push(m[1]+' → '+m[2]);
}
if(nonMay.length) {
  console.log('Features NOT targeting May 2026:');
  nonMay.forEach(x=>console.log('  ⚠ '+x));
  console.log('  (These are forward-looking items — verify intentional)');
} else {
  console.log('All features target May 2026 ✅');
}

console.log('\n══════════════════════════════════════════════');
console.log('  END AUDIT');
console.log('══════════════════════════════════════════════');
