// Direct injection: read the presenter HTML file and inject notes into the ACTUAL JS block
const fs = require('fs');
let html = fs.readFileSync('roadmap/m365-roadmap-may.presenter.html', 'utf8');

const notes = {
  '559478': `Let me start with Copilot image generation in PowerPoint — and this one is a strategic shift worth your attention. ⏪ HOW IT WORKED BEFORE: Your teams had exactly one AI model for image generation — whatever Microsoft defaulted to. If the output didn't match your brand aesthetic, the workaround was leaving PowerPoint entirely — Canva, Adobe, Midjourney — then re-importing. That's context-switching at scale, and it killed velocity. 🆕 WHAT CHANGED: Users now choose their model — OpenAI GPT Image, Black Forest Lab Flux, Microsoft MAI-Image, and more — directly inside PowerPoint. Think of it as giving your creative teams a multi-lens camera instead of a fixed-focus disposable. 📌 VP PLAY: This is an adoption accelerator for Copilot licensing ROI. If your marketing or comms teams pushed back on Copilot because image quality wasn't there, that objection just disappeared. I'd recommend a targeted pilot with your brand and comms leads — measure time-to-deck before and after. Already live.`,
  '553214': `This next one looks small on paper but has outsized impact on your support cost baseline — the Access Denied page redesign. ⏪ HOW IT WORKED BEFORE: When an employee hit a permissions wall on SharePoint, OneDrive, or a meeting recording, they got a cryptic error page. No guidance, no self-service. The result? A helpdesk ticket every single time — and in large orgs, that's thousands of tickets per quarter just for access requests. 🆕 WHAT CHANGED: The new page uses Fluent design with clear messaging — it tells the user exactly what they don't have access to, who owns it, and gives them a one-click request button. It also covers meeting recordings, which was a blind spot before. 📌 VP PLAY: If you're tracking IT cost-per-ticket, this is a measurable win. I'd ask your service desk team to baseline access-related ticket volume now so you can show the delta in 90 days. Already launched — no action needed to enable it.`,
  '559261': `Now a critical one for regulated industries — Purview retention for Teams call logs. ⏪ HOW IT WORKED BEFORE: Teams stored CDR — Call Detail Records — indefinitely. There was no built-in way to set a retention ceiling. If your legal or compliance team mandated a maximum retention period — say, 12 months for GDPR or 7 years for FINRA — you had to build custom solutions or accept the compliance gap. That gap was audit risk. 🆕 WHAT CHANGED: You can now define retention policies specifically for Teams call logs through Purview Data Lifecycle Management. Set it, enforce it, audit it — same tooling you already use for email and chat retention. 📌 VP PLAY: If you're in financial services, healthcare, or any sector with data minimization requirements, this needs to go to your compliance team this week. The conversation is simple: We now have native controls for call log retention — do our current policies need updating? Launched and available today.`,
  '557716': `Teams Phone multi-line — this one changes the economics of telephony for several of your business units. ⏪ HOW IT WORKED BEFORE: One user, one number. If someone needed to be reachable on a main office line, a department line, and their direct line, you either bought multiple licenses, set up complex call groups, or — what I've seen in most orgs — just gave them a second phone. That's hardware cost, management overhead, and user frustration. 🆕 WHAT CHANGED: A single user can now have up to 10 phone numbers assigned. Full support across desktop, mobile, and Teams devices. They see all lines, pick up on any, make outbound calls from whichever identity makes sense. 📌 VP PLAY: Think about your reception desks, executive assistants, regional managers who cover multiple offices, or anyone in a shared-services model. This potentially eliminates secondary devices and simplifies your telephony architecture. I'd model the cost savings against your current PBX or multi-license setup. Already live.`,
  '559418': `Copilot coaching in Outlook — this is one of the highest-ROI Copilot features I've seen, and here's why it matters at VP level. ⏪ HOW IT WORKED BEFORE: Writing assistance in Outlook was reactive. You'd compose an email, then manually open Copilot and say review this or make it more professional. Two separate steps, low adoption because people forget or don't bother. The result: Copilot licenses underutilized, and email quality stays uneven — especially in customer-facing comms. 🆕 WHAT CHANGED: Copilot now coaches proactively as you draft. It surfaces suggestions in the chat pane — tone, clarity, length — and can apply them with one click. It's the difference between having a writing coach you have to call versus one sitting next to you. 📌 VP PLAY: This is your Copilot adoption story for the next board update. It's the feature that makes AI feel invisible and useful — no prompt engineering, no extra steps. For customer-facing teams, sales, and executive comms, this directly improves communication quality at scale. Rolling out now — ask your IT team to confirm it's enabled.`,
  '558254': `Copy-paste for @mentions and shared contacts in Teams — this is a friction remover that saves more time than it sounds. ⏪ HOW IT WORKED BEFORE: When someone copied a message from one Teams chat and pasted it into another, all the @mentions turned into dead plain text. The person's name was there, but it wasn't clickable — no profile card, no notification to that person. People had to manually re-tag everyone. In cross-functional project channels where context gets forwarded constantly, this added up. 🆕 WHAT CHANGED: Teams now intelligently preserves @mentions and shared contacts when pasting. If the destination supports it, the link stays live. If not — say you're pasting into an email — it degrades gracefully to text. No more manual re-tagging. 📌 VP PLAY: This is a collaboration velocity improvement. It won't show up in a business case on its own, but it's the kind of micro-friction that, multiplied across thousands of users, adds up to hours per week reclaimed. No action needed — just be aware it's rolling out.`,
  '552595': `Copilot conversational drafting comes to Outlook for Mac — and this is about closing a platform parity gap that was creating internal friction. ⏪ HOW IT WORKED BEFORE: Windows and web users could draft, edit, and format emails side-by-side with Copilot using the same agentic experience available in Word and Excel. Mac users? They were left out. In organizations where leadership often runs on Mac, this created a visible gap — your execs couldn't do what their direct reports on Windows could. 🆕 WHAT CHANGED: Full Copilot conversational email experience is now live on Outlook for Mac. Draft from scratch, refine tone, reformat — all through natural conversation in the Copilot pane. Same engine, same capabilities. 📌 VP PLAY: If your leadership team or creative departments run Mac-heavy, this removes the number-one Copilot adoption blocker for those users. I'd send a targeted enablement note to your Mac user population — they've been waiting for this. Rolling out now.`,
  '559605': `Chat organization in Teams — this directly addresses one of the top complaints I hear in every enterprise: I can't find anything in my chat list. ⏪ HOW IT WORKED BEFORE: Every chat — active project, muted group, one-off meeting chat — sat in one flat list sorted by recency. If you muted a noisy group, it could still jump to the top with every message. Meeting chats from three months ago cluttered your view. The only option was manual pinning, which doesn't scale. 🆕 WHAT CHANGED: Teams now auto-groups muted chats into a collapsible section — on by default. Meeting chats can also be grouped separately — off by default, but one toggle to enable. It's an intelligent inbox for your chat list. 📌 VP PLAY: This is a focus and productivity story. Your knowledge workers spend significant time in Teams — reducing navigation friction directly impacts deep-work time. No rollout action needed, but I'd recommend mentioning it in your next internal comms update so users know it's there. Rolling out now.`,
  '559611': `Single-window annotation sharing on macOS — this is a training and workshop enabler. ⏪ HOW IT WORKED BEFORE: On Mac, if you wanted meeting participants to annotate on shared content, you had to share your entire desktop. That meant every notification, every open app, every browser tab was visible. For trainers, consultants, and anyone running interactive sessions, this was a dealbreaker — either sacrifice privacy or lose the collaborative annotation feature. 🆕 WHAT CHANGED: Presenters on Mac can now share a single application window and enable participant annotations on just that window. Desktop stays private, collaboration stays interactive. 📌 VP PLAY: If your organization runs internal training, client workshops, or design reviews on Mac, this unlocks interactive sessions without the security and privacy exposure. Think L&D teams, consulting engagements, executive briefings. Rolling out now.`,
  '561493': `Custom backgrounds for Teams events — this is a brand governance play for your corporate events team. ⏪ HOW IT WORKED BEFORE: In Teams town halls and webinars, organizers using Manage what attendees see were limited to default Microsoft backgrounds. If you wanted branded visuals — your company logo, event-specific artwork, a product launch theme — you had to work around it with green-screen setups or third-party streaming tools. It looked inconsistent and unprofessional at enterprise scale. 🆕 WHAT CHANGED: Organizers and presenters with production tools access can now upload custom backgrounds directly. Your brand team designs it, your event team uploads it, attendees see a polished, on-brand experience. 📌 VP PLAY: If you run quarterly town halls, customer-facing webinars, or investor events, coordinate with your brand and comms teams now to prepare background assets. Requires Teams Premium. Targeting June 2026 — plan for Q3 events.`,
  '561549': `Teams room builder in the Pro Management portal — this changes how you scale meeting room deployments. ⏪ HOW IT WORKED BEFORE: Designing and standardizing Teams Rooms across multiple offices meant spreadsheets, vendor catalogs, and a lot of back-and-forth between IT, facilities, and procurement. There was no unified tool to visualize a room layout, select compatible equipment, and push a standard configuration. Every office ended up slightly different. 🆕 WHAT CHANGED: A visual, interactive room builder inside the Pro Management portal. IT managers pick a room type — traditional, signature, or flex — select equipment from filtered options, and create reusable standards. It's essentially a digital twin for your meeting spaces before you buy hardware. 📌 VP PLAY: If you have a workplace modernization or hybrid-space initiative on your roadmap, this tool accelerates planning and ensures consistency. I'd loop in your workplace strategy and facilities teams for a demo once it's available. Requires Teams Rooms Pro. June 2026.`,
  '561485': `Copilot in Forms for US Government clouds — this extends AI-assisted survey creation to GCC, GCC High, and DoD. ⏪ HOW IT WORKED BEFORE: Government cloud tenants were excluded from Copilot in Forms. That meant agencies and contractors still built surveys manually — writing every question, designing distribution, and analyzing results without AI assistance. Commercial tenants had this for months; government was waiting. 🆕 WHAT CHANGED: The full Copilot experience comes to gov clouds — draft with AI, distribute, monitor, get insights, rewrite questions, generate answer explanations. Same feature set commercial has today. 📌 VP PLAY: If any of your lines of business operate in government cloud environments, add this to your FY27 Copilot adoption roadmap. Target is September 2026 — enough lead time to align licensing and change management. Plan the pilot now.`,
  '561330': `Cross-tenant message recall in Exchange Online — this addresses one of the most requested features in multi-org collaboration scenarios. ⏪ HOW IT WORKED BEFORE: Message recall only worked within your own tenant. If an employee accidentally sent a confidential board deck to a vendor, a partner, or a client — you had no recall option. The only remediation was calling the recipient and hoping they hadn't opened it yet. For regulated data, that's an incident with reporting obligations. 🆕 WHAT CHANGED: Cross-tenant recall is coming. If the receiving organization adds your tenant to their recall allow list, you can pull back messages sent across organizational boundaries. It's mutual — both sides opt in. 📌 VP PLAY: This is a data governance conversation for your CISO and your key partnership relationships. My recommendation: identify your top five external collaboration partners and start the allow-list conversation now, before the feature ships. August 2026 target.`,
  '557190': `DLP file quarantine for SharePoint and OneDrive — this is the enforcement action security teams have been asking for since DLP launched. ⏪ HOW IT WORKED BEFORE: When a DLP policy detected sensitive content in SharePoint or OneDrive, you had limited options — alert the admin, show a policy tip to the user, or block sharing. But the file itself stayed in place. Users could still access, copy, or download it while you investigated. The gap between detection and remediation was a window of exposure. 🆕 WHAT CHANGED: DLP can now automatically quarantine the file — moving it to a restricted, admin-controlled location, instantly revoking access for all users. The file is preserved for investigation but locked down from the moment the policy triggers. Zero user access during review. 📌 VP PLAY: This closes the detection-to-remediation gap and is a significant upgrade to your data protection posture. For organizations handling PII, financial data, or IP, this should go into your DLP policy review immediately. I'd recommend your security team model which existing policies should add quarantine as an action. June 2026.`,
  '560547': `And finally — end-user reporting of suspicious external users directly in Teams. ⏪ HOW IT WORKED BEFORE: If a user encountered a suspicious external contact in Teams — potential phishing, impersonation, social engineering — their only option was to block that person individually or submit a generic IT ticket. There was no structured reporting channel, and the signal never reached the security team in a useful format. You were blind to threats your users could see. 🆕 WHAT CHANGED: A built-in Report action for external users in Teams. Reports go directly to the Teams admin center, giving your security operations team real-time visibility into suspicious interactions — organized, searchable, actionable. 📌 VP PLAY: This turns every employee into a sensor in your security perimeter. For organizations investing in security culture and zero-trust architecture, this is a force multiplier. I'd coordinate with your security awareness team to include this in their next training update once it ships. June 2026.`
};

// Strategy: find each feature in the JS block and add the notes field
// The JS features look like: desc:"..." },
// We need to change them to: desc:"...", notes:"..." },

const scriptStart = html.indexOf('<script>\nconst FEATURES');
if (scriptStart === -1) {
  // try with \r\n
  const alt = html.indexOf('<script>\r\nconst FEATURES');
  if (alt === -1) { console.error('FATAL: Cannot find script+FEATURES'); process.exit(1); }
}

let count = 0;
for (const [id, note] of Object.entries(notes)) {
  // Escape for JS double-quoted string
  const escaped = note.replace(/\\/g, '\\\\').replace(/"/g, '\\"');
  
  // Find ALL positions of this feature ID
  const needle = 'id:"' + id + '"';
  let pos = 0;
  const positions = [];
  while (true) {
    const i = html.indexOf(needle, pos);
    if (i === -1) break;
    positions.push(i);
    pos = i + 1;
  }
  
  // Only target positions AFTER the <script> tag (the actual JS block)
  const scriptPos = html.indexOf('<script>');
  const jsPositions = positions.filter(p => p > scriptPos);
  
  if (jsPositions.length === 0) {
    console.error('WARNING: Feature', id, 'not found in JS block');
    continue;
  }
  
  // Take the first JS position
  const featStart = jsPositions[0];
  
  // Find the closing " }, of this feature (after desc:"...")
  // Look for the pattern: desc:"<content>" },
  const descStart = html.indexOf('desc:"', featStart);
  if (descStart === -1 || descStart > featStart + 2000) {
    console.error('WARNING: desc not found for', id);
    continue;
  }
  
  // Find the end of desc value - look for the pattern: " },
  // We need to find the closing quote of desc, then the space and },
  let inStr = true;
  let j = descStart + 6; // skip past desc:"
  while (j < html.length) {
    if (html[j] === '\\' && html[j+1] === '"') { j += 2; continue; } // escaped quote
    if (html[j] === '"') { inStr = false; break; }
    j++;
  }
  // j is now at the closing " of desc
  // The pattern after is: " },  or  " }
  // Find the }, after it
  const closeSearch = html.substring(j, j + 20);
  const closeBrace = closeSearch.indexOf('}');
  if (closeBrace === -1) {
    console.error('WARNING: closing brace not found for', id);
    continue;
  }
  
  // Insert notes field before the closing }
  const insertPos = j + closeBrace; // position of }
  const before = html.substring(0, insertPos);
  const after = html.substring(insertPos);
  
  // Check if notes already injected
  const nearby = html.substring(featStart, insertPos);
  if (nearby.includes('notes:')) {
    console.log('SKIP:', id, '(notes already present)');
    continue;
  }
  
  html = before + ',\n    notes:"' + escaped + '" ' + after;
  count++;
  console.log('OK:', id);
}

fs.writeFileSync('roadmap/m365-roadmap-may.presenter.html', html, 'utf8');
console.log('\nInjected notes into', count, 'features');
console.log('File size:', (fs.statSync('roadmap/m365-roadmap-may.presenter.html').size / 1024).toFixed(1), 'KB');

// Verify
const result = fs.readFileSync('roadmap/m365-roadmap-may.presenter.html', 'utf8');
const jsBlock = result.substring(result.indexOf('<script>'));
const noteCount = (jsBlock.match(/notes:"/g) || []).length;
console.log('Verified notes in JS <script> block:', noteCount);
