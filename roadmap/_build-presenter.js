const fs = require('fs');
let html = fs.readFileSync('roadmap/m365-roadmap-may.html', 'utf8');

// ── 1. Speaker notes: direct speech for each feature ──
const notes = {
  '559478': "Alright, let's kick off with Copilot in PowerPoint. Users can now pick which AI image model they want — GPT Image from OpenAI, Flux from Black Forest Lab, or Microsoft's own MAI-Image. Think of it as choosing your camera lens before a shoot. The key takeaway: you're no longer locked into a single model. If your marketing team prefers one style over another, they choose. This is already live.",
  '553214': "Next — Microsoft refreshed the Access Denied page. Sounds boring, right? But here's why it matters: when users hit a permissions wall on SharePoint, OneDrive, or a meeting recording, the old page was confusing. The new Fluent design actually tells them what happened and how to request access. Fewer helpdesk tickets. Already launched.",
  '559261': "For the compliance folks — Purview now supports retention policies for Teams call logs. Until now, those CDR logs were kept forever. If you're in a regulated industry — banking, healthcare — you likely have rules about how long call metadata can be retained. This finally lets you set those boundaries. Launched and available now.",
  '557716': "Teams Phone multi-line — exciting for front-desk staff, receptionists, anyone juggling multiple roles. You can now assign up to 10 phone numbers to a single user. Works across desktop, mobile, and Teams devices. No more switching accounts or carrying two phones. If you have call center or reception scenarios, start planning for this.",
  '559418': "Copilot coaching in Outlook — this changes how people write emails. Instead of drafting and then asking Copilot to review separately, Copilot now watches as you type and offers coaching suggestions right in the chat pane. 'Hey, your tone is a bit aggressive here' or 'Consider shortening this paragraph.' And it can apply the fix directly. Rolling out now — your users may already see it.",
  '558254': "Quick quality-of-life improvement: when you copy-paste messages in Teams that contain @mentions or shared contacts, they used to break — just plain text. Now Teams is smart about it. If the destination supports the mention, it keeps it. If not, graceful fallback. Small change, big time-saver.",
  '552595': "Mac users, you're finally getting parity. Copilot in Outlook for Mac now lets you draft, edit, and format emails conversationally — same agentic experience that Windows and web users have had. If you have a mixed-platform environment, this closes a gap your Mac users have been asking about.",
  '559605': "Chat clutter in Teams is a real problem. Microsoft is adding built-in sections that automatically group muted chats and, optionally, meeting chats. Muted chats grouped by default; meeting chats off by default but you can turn them on. Your important conversations won't get buried under 47 meeting chats anymore. Rolling out now.",
  '559611': "For presenters on Mac — you can now share a single window and let participants annotate directly on it. Before, you had to share your full desktop for annotations to work — everyone could see your messy desktop, your Slack messages, everything. Now: share just PowerPoint, let people draw on it, keep your privacy. Great for workshops and training.",
  '561493': "Looking ahead to June — custom backgrounds for Teams events. Organizers will be able to upload branded backgrounds for the 'Manage what attendees see' experience. Think company logos, event themes, conference branding. Requires Teams Premium. Still in development, but if you're planning a big event for Q3, keep this on your radar.",
  '561549': "Also coming in June — a room builder tool in the Teams Rooms Pro Management portal. Instead of configuring rooms through spreadsheets and guesswork, IT managers get a visual drag-and-drop tool to design traditional, signature, and flex meeting spaces. If you're standardizing meeting rooms across offices, this will save you weeks.",
  '561485': "For government cloud customers — Copilot in Forms is coming to GCC, GCC High, and DoD. Full experience: drafting forms with AI, distribution, insights, rewriting questions. Target is September 2026. If you're in a government environment, add this to your adoption roadmap.",
  '561330': "Cross-tenant message recall in Exchange — huge for organizations that work closely with partners. Today you can only recall within your own org. Soon, if a partner adds you to their recall allow list, you can pull back that accidentally-sent email across tenant boundaries. August 2026 target. Plan your allow-list strategy now.",
  '557190': "Purview DLP is getting a file quarantine action for SharePoint and OneDrive. When a DLP policy triggers, instead of just alerting, it can move the file to a locked-down quarantine folder — instantly revoking access while keeping it for investigation. This is the enforcement action security teams have been requesting for years. June 2026.",
  '560547': "Last one — users can report suspicious external users directly in Teams. The report goes straight to the Teams admin center. Think of it as a 'see something, say something' button for your digital workspace. Phishing, impersonation, social engineering — your end users become an active layer of defense. June 2026."
};

// ── 2. Inject notes field into each feature in the JS array ──
for (const [id, note] of Object.entries(notes)) {
  const escaped = note.replace(/\\/g, '\\\\').replace(/"/g, '\\"');
  const regex = new RegExp('(\\{ id:"' + id + '"[^}]+)(\\})');
  html = html.replace(regex, (m, before, close) => {
    return before + ',\n    notes:"' + escaped + '" ' + close;
  });
}

// ── 3. Section transition notes ──
const sectionNotesBlock = `
const SECTION_NOTES = {
  opening: "Good morning everyone. I'm Fernando Olímpio — 22 years in Microsoft infrastructure, over a hundred M365 migrations, and about 30 Copilot rollouts across LATAM. Today I'll walk you through the May 2026 Microsoft 365 Roadmap — what's already live, what's rolling out right now, and what's coming next. I've grouped these by status so you can prioritize what needs action today versus what to plan for. Let's dive in.",
  launched: "Let's start with what's already shipped. These features are live in your tenant right now — no waiting, no preview ring. If you haven't seen them yet, check your release settings.",
  rolling: "Now let's look at what's actively rolling out. These are hitting tenants in waves — you might already have some, or they could show up this week. This is the heads-up section.",
  indev: "Finally, the forward-looking items. Still in development — not in your tenant yet, but on the official roadmap with target dates. This is where you plan, not react.",
  closing: "That's the May 2026 roundup. My recommendations: one, check your Copilot Outlook experience — coaching is live. Two, if you're regulated, look at Purview retention for Teams call logs immediately. Three, start planning for DLP quarantine and cross-tenant recall — game-changers coming next quarter. Questions?"
};
`;

html = html.replace(
  /(const FEATURES = \[[\s\S]*?\]\s*;)/,
  '$1\n' + sectionNotesBlock
);

// ── 4. CSS for speaker notes ──
const notesCss = `
  /* ============ SPEAKER NOTES (presenter version) ============ */
  .notes-toggle{position:fixed;top:70px;right:18px;z-index:60;background:linear-gradient(135deg,#D83B01,#B7472A);color:#fff;border:none;padding:10px 16px;border-radius:10px;cursor:pointer;font-weight:700;font-size:13px;box-shadow:0 4px 14px rgba(216,59,1,.4);display:flex;align-items:center;gap:6px;transition:transform .15s}
  .notes-toggle:hover{transform:translateY(-2px)}
  body.hide-notes .speaker-note,body.hide-notes .section-note{display:none}
  body.hide-notes .notes-toggle{opacity:.5}
  .speaker-note{background:linear-gradient(135deg,#FFF4CE,#FFEAB0);border:1px solid #F2C811;border-radius:10px;padding:14px 18px;margin:8px 0 0;font-size:13.5px;line-height:1.65;color:#1a1a1a;position:relative}
  .speaker-note::before{content:'\\1F3A4  SAY:';font-weight:800;color:#D83B01;display:block;margin-bottom:6px;font-size:11px;letter-spacing:.12em}
  body:not(.light) .speaker-note{background:linear-gradient(135deg,#3d2e0a,#2e2207);border-color:#7a6520;color:#f5e6b8}
  body:not(.light) .speaker-note::before{color:#ffb347}
  .section-note{max-width:1200px;margin:14px auto;padding:16px 22px;background:linear-gradient(135deg,#FFF4CE,#FFEAB0);border:1px solid #F2C811;border-radius:12px;font-size:14px;line-height:1.65;color:#1a1a1a}
  .section-note::before{content:'\\1F3A4  SAY:';font-weight:800;color:#D83B01;display:block;margin-bottom:6px;font-size:11px;letter-spacing:.12em}
  body:not(.light) .section-note{background:linear-gradient(135deg,#3d2e0a,#2e2207);border-color:#7a6520;color:#f5e6b8}
  body:not(.light) .section-note::before{color:#ffb347}
  .presenter-banner{max-width:1200px;margin:0 auto 10px;padding:10px 22px;background:#D83B01;color:#fff;border-radius:10px;font-size:12px;font-weight:700;letter-spacing:.1em;text-transform:uppercase;text-align:center}
  @media print{.notes-toggle,.presenter-banner,.bottomnav{display:none}.speaker-note,.section-note{break-inside:avoid;page-break-inside:avoid}}
`;
html = html.replace('</style>', notesCss + '\n</style>');

// ── 5. Toggle button after header ──
html = html.replace(
  '</header>',
  `</header>
<button class="notes-toggle" onclick="document.body.classList.toggle('hide-notes');this.textContent=document.body.classList.contains('hide-notes')?'Show Notes':'Hide Notes'">Hide Notes</button>`
);

// ── 6. Internal banner before cover ──
html = html.replace(
  '<div class="page-view active" id="view-cover"',
  '<div class="presenter-banner">⚠ INTERNAL — PRESENTER VERSION WITH SPEAKER NOTES — NOT FOR CLIENT DISTRIBUTION</div>\n<div class="page-view active" id="view-cover"'
);

// ── 7. Modify renderHome: add notes below each card ──
html = html.replace(
  '      <div class="footer"><span class="open">Open tab →</span><span>${f.date} · id ${f.id}</span></div>\n    </article>',
  '      <div class="footer"><span class="open">Open tab →</span><span>${f.date} · id ${f.id}</span></div>\n      ${f.notes ? \'<div class="speaker-note">\' + f.notes + \'</div>\' : \'\'}\n    </article>'
);

// ── 8. Modify renderDetail: show notes above SHARE ──
html = html.replace(
  '        <div class="share">SHARE</div>',
  '        ${f.notes ? \'<div class="speaker-note" style="margin:18px 0">\' + f.notes + \'</div>\' : \'\'}\n        <div class="share">SHARE</div>'
);

// ── 9. Section note rendering function + hook into render() ──
const fnCode = `
// Inject section transition notes
function renderSectionNotes(){
  document.querySelectorAll('.section-note').forEach(n=>n.remove());
  const st = document.getElementById('status').value;
  const view = document.getElementById('view');
  if(activeTab!=='home') return;
  if(!st){
    const d=document.createElement('div');d.className='section-note';d.textContent=SECTION_NOTES.opening;
    view.parentNode.insertBefore(d,view);
  }
  const k=st==='Launched'?'launched':st==='Rolling out'?'rolling':st==='In development'?'indev':null;
  if(k&&SECTION_NOTES[k]){const d=document.createElement('div');d.className='section-note';d.textContent=SECTION_NOTES[k];view.parentNode.insertBefore(d,view);}
}
`;
html = html.replace('populateFilters();', fnCode + '\npopulateFilters();');
html = html.replace(
  'if(activeTab==="home") renderHome(list); else renderDetail(activeTab);',
  'if(activeTab==="home") renderHome(list); else renderDetail(activeTab);\n  renderSectionNotes();'
);

// ── 10. Title ──
html = html.replace(
  '<title>Microsoft 365 Roadmap — May 2026</title>',
  '<title>[PRESENTER] Microsoft 365 Roadmap — May 2026</title>'
);

fs.writeFileSync('roadmap/m365-roadmap-may.presenter.html', html, 'utf8');
const sz = (fs.statSync('roadmap/m365-roadmap-may.presenter.html').size / 1024).toFixed(1);
console.log('OK: roadmap/m365-roadmap-may.presenter.html (' + sz + ' KB)');
console.log('Notes: ' + Object.keys(notes).length + ' features + 5 section scripts');
