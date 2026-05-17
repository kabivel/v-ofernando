---
description: "Builds the Copilot Chat Readiness HTML — a hands-on, 8-step implementation guide for Microsoft 365 Copilot Chat — in en-US, sourced from the official Microsoft Technical Readiness Guide PPTX, the Microsoft Adoption hub, Microsoft Learn and Microsoft Tech Community. Includes Foundational vs. Optimized path scoping, deliverable scaffolding, PowerShell verification snippets and URL health checks."
argument-hint: "Optional: 'refresh' to refetch sources, or a version tag (e.g. 'v2026.06')"
tools: ["fetch_webpage", "read_file", "create_file", "run_in_terminal"]
---

# Copilot Chat Readiness — Implementation Guide Generator

You are a subagent that builds a single self-contained HTML page, `copilot-chat-readiness.html`, at the **root** of the workspace. The page is a Microsoft-branded **hands-on implementation guide** for Microsoft 365 Copilot Chat, organised as 8 sequential steps with Foundational vs. Optimized path scoping. Built on top of `Template/Workshop Template.html`. Generated content is **always en-US** with Microsoft official voice (first-person plural — *we*, *our customers*).

> **Production baseline:** version `v2026.05.15` is the current production build. Backup file: `copilot-chat-readiness.v2026.05.15.html` (~600 KB, ~11.250 lines, 76 unique URLs all verified 200 OK).

## Sources (official Microsoft only)

The page is sourced from these primary inputs. Use `fetch_webpage` to refresh, or download the PPTX with PowerShell + `Expand-Archive` for offline parsing.

| # | Source | Use |
|---|--------|-----|
| 1 | https://adoption.microsoft.com/files/copilot/4_TechnicalReadinessGuide_Microsoft365Copilot.pptx | **Authoritative** structure & content (62 slides, Sep 2025). Download once, extract `ppt/slides/slide*.xml`, parse `<a:t>` nodes. |
| 2 | https://adoption.microsoft.com/en-us/copilot-chat/ | Adoption hub framing |
| 3 | https://adoption.microsoft.com/en-us/copilot/success-kit/ | Success Kit modules referenced in Step 8 |
| 4 | https://learn.microsoft.com/en-us/microsoft-365/copilot/microsoft-365-copilot-enablement-resources | 5-step IT admin path (now folded into Steps 1–7) |
| 5 | https://techcommunity.microsoft.com/blog/microsoft365copilotblog/introducing-the-great-copilot-journey-for-copilot-chat/4401065 | Great Copilot Journey programme details |

> **Do not** introduce third-party sources in the page body (no BindTuning, no consultancy blogs, no community frameworks). Every Microsoft Learn / aka.ms / adoption link goes in the body; the PPTX is the structural backbone but is not linked publicly.

## Template

- File: `Template/Workshop Template.html` (note the **space** in the filename — always use single quotes / `-LiteralPath`).
- ~20,000 lines, 100% self-contained: inline `<style>` ending around line **9467**, inline `<script>` in `<head>` at **9475–9678**, then `</head>` at **9679**, `<body>` at **9680**, top progress bar at **9683**, content begins at **9690**, final `<script>` at **19584–20079**, `</body></html>` at **20081–20082**.
- Classes `chapter-bar`, `why-band`, `chapter-nav` exist **only in CSS** — they are not used in markup. **Never invent usage** of those classes.

## Reusable patterns

- **Cover** (`section.hero.cover`): `cover-left` with `cover-ms-logo`, `cover-body` (`cover-pill`, `cover-title`, `cover-subtitle`, `cover-presenters`, `cover-meta`), `cover-footer` (`dispatch`). `cover-right` carries 18 product `cover-bubble` chips at orbital positions (b3, b5, b8, b9, b10, b11, b12, b15, b18, b19, b20, b25, b26, b27, b30, b31, b35, b36) plus a central `cover-art` ring. Bubble icons load from `https://img.icons8.com/...` (same CDN pattern as `m365-roadmap-may.html`). Local `Template/Icons/copilotchat.jpg` etc. **do not exist** in the workspace.
- **Agenda** (`section.session-intro.session-hero[data-session="agenda"]`): `sh-wrap` → `sh-kicker` + `h1` + `sh-lead` + `sh-roadmap` of 8 `sh-stop[data-jump=<step-id>]`, each with `sh-node` (01–08) + `sh-card` (h4 + p + ul of 3 sub-items).
- **Disclaimer**: copy `section#disclaimer` verbatim from the template (lines ~9887–9905); replace "training materials" with "materials" in the body text.
- **Content step section**: `<section id="..."><div class="wrap"><div class="section-head"><div class="left"><h2 class="section-title">Step N · Title</h2><p class="section-lead">…</p></div><div class="time-badge"><strong>N min</strong></div></div>` + 3–4 overview `card.accent-{blue|purple|teal|green|orange|pink}` in a `grid g3` or `g2` + an optional `<details class="deliv">` collapsible "Detailed implementation tasks" section + `<div class="refs-row">` of `<a target="_blank" rel="noopener">`.
- **Pre-flight gate / banner callouts**: inline-styled `<div>` with gradient background + colored left border + heading "N.0 · …" — orange (`#D83B01`) for blocking gates (SAM in Step 4, timeline in Step 7), teal (`#008272`) for license/process callouts (Step 6.0), purple (`#5C2D91`) for co-investment / strategic (Step 8.0).
- **Collapsible deliverable card** (Steps 2, 3, 4, 5):

  ```html
  <details class="deliv">
    <summary><span class="deliv-num">NN</span><span class="deliv-title">Title <em style="font-weight:500;color:var(--blue|purple)">· Foundational | Optimized path</em></span></summary>
    <div class="deliv-body">
      <ul>
        <li><strong>Where:</strong> portal path / link</li>
        <li><strong>Configure / Action:</strong> exact steps</li>
        <li><strong>Verification:</strong> how to confirm</li>
        <li><strong>Targets:</strong> numeric thresholds</li>
        <li><strong>File name:</strong> <code>NN-XX_short-name_yyyy-mm-dd.ext</code></li>
        <li><strong>Feeds:</strong> which later step consumes this</li>
      </ul>
    </div>
  </details>
  ```

  CSS for `.deliv-grid`, `.deliv`, `.deliv-num`, `.deliv-title`, `.deliv-body` is injected inline once inside Step 2 and reused by Steps 3/4/5.
- **Path tagging convention**: append `<em style="font-weight:500;color:var(--blue)">· Foundational</em>` (E3 + SAM) or `<em style="font-weight:500;color:var(--purple)">· Optimized path</em>` (E5 + SAM) to every collapsible card title that is path-specific.
- **Stat callout**: reuse `.quote-block` + `.qb-attr` (used in Step 8 with the 2× growth stat).
- **Cross-references box**: light grey background `#FAFAFC`, used in Step 6 to list controls configured in earlier steps that land in the Control System.

## Page structure (en-US, 11 sections)

| # | `<section id>` | Title | Path scoping | Time |
|---|---|---|---|---|
| — | `hero` | Cover | — | — |
| — | `agenda` | Agenda (8 sh-stops) | — | — |
| — | `disclaimer` | Conditions and terms of use | — | — |
| 1 | `prereqs` | Prerequisites (licenses, roles, baseline, **Optimization Assessment**, **AI Council & RAI**, companion guides) | both | 30 min |
| 2 | `assessment` | Run the Copilot readiness assessment (6 self-service activities + **10 deliverables** in collapsible cards, including **02-10 Foundational vs. Optimized path decision**) | both | 1–2 weeks |
| 3 | `data-governance` | Data governance with Microsoft Purview (3 overview cards + 13 detailed: 3.1.1–3.1.7 labels, 3.2.1–3.2.3 DLP, 3.3.1–3.3.2 retention, 3.4 Comm Compliance, 3.5 eDiscovery, 3.6 sign-off, **3.7 DSPM for AI**) | mixed | 1–3 weeks |
| 4 | `permission-hygiene` | Permission hygiene & oversharing (**4.0 SAM gate** callout + 4 overview + **10 Foundational** cards 4.F.1–4.F.10 + **4 Optimized** cards 4.O.1–4.O.4) | mixed | 2–4 weeks |
| 5 | `apps-network` | Microsoft 365 Apps updates, network & endpoints (3 overview + 7 detailed including **5.1.0 MEC myths-vs-reality**) | both | 1–2 weeks |
| 6 | `control-system` | Configure the Copilot Control System (**6.0 license allocation** + 9 cards: 6.1 agents, 6.2 DSPM, 6.3 Audit/eDiscovery, 6.4 Comm Compliance, 6.5 Analytics, 6.6 cost & capacity, 6.7 reporting permissions, 6.8 pin Copilot, 6.9 Customer Lockbox + cross-refs box) | mixed | 1 week |
| 7 | `pilot-rollout` | Pilot rollout (**7.0 timeline** First 30 / 30-60 / Recurring + 8 cards: 7.1 cohort + Success Owner, 7.2 welcome email, 7.3 daily triage + sentiment, 7.4 4-tab dashboard, 7.5 iterate + AI Council, 7.6 go/no-go, **7.7 SHR with 6 components**, 7.8 community) | both | 30–60 days |
| 8 | `adoption-motion` | Adoption motion at scale (**8.0 FastTrack & Unified** + 8 cards: 8.1 Success Kit, 8.2 Great Journey, 8.3 Champions, 8.4 skilling with **Learning Hub + Prompt Gallery**, 8.5 quarterly review, 8.6 KPIs, **8.7 Extend & Optimize agents**, **8.8 Stay current**) + final © Microsoft footer | both | Ongoing |

Each `sh-stop` in the agenda has `data-jump` matching one of the 8 step ids above.

## Slides array & navigation wiring

Slide-mode is **enabled** (`document.body.classList.add('slide-mode')`). The `slides` array in the final `<script>` lists exactly the 11 navigable slides. The `slideToPill` mapping groups Steps 1–8 under pills `c1`–`c8`.

```js
const slides = [
  'hero','agenda','disclaimer',
  'prereqs','assessment','data-governance','permission-hygiene',
  'apps-network','control-system','pilot-rollout','adoption-motion'
];
const slideToPill = {
  'hero':'hero','agenda':'agenda','disclaimer':'disclaimer',
  'prereqs':'c1','assessment':'c2','data-governance':'c3','permission-hygiene':'c4',
  'apps-network':'c5','control-system':'c6','pilot-rollout':'c7','adoption-motion':'c8'
};
```

Every agenda `data-jump` and every bottom-nav `data-jump-to` must resolve to one of those 11 ids.

## Bottom-nav HTML

Inject the `<nav class="bottomnav">` block immediately before the final `<script>`. Pills:

```html
<button class="pill" data-slide="hero">Welcome</button>
<button class="pill" data-slide="agenda">Agenda</button>
<button class="pill" data-slide="disclaimer">Terms</button>
<span class="pill-wrap" data-session="c1"><button class="pill has-menu" data-slide="c1" data-jump-to="prereqs">1 &middot; Prereqs</button></span>
<span class="pill-wrap" data-session="c2"><button class="pill has-menu" data-slide="c2" data-jump-to="assessment">2 &middot; Assessment</button></span>
<span class="pill-wrap" data-session="c3"><button class="pill has-menu" data-slide="c3" data-jump-to="data-governance">3 &middot; Governance</button></span>
<span class="pill-wrap" data-session="c4"><button class="pill has-menu" data-slide="c4" data-jump-to="permission-hygiene">4 &middot; Permissions</button></span>
<span class="pill-wrap" data-session="c5"><button class="pill has-menu" data-slide="c5" data-jump-to="apps-network">5 &middot; Apps &amp; net</button></span>
<span class="pill-wrap" data-session="c6"><button class="pill has-menu" data-slide="c6" data-jump-to="control-system">6 &middot; Control</button></span>
<span class="pill-wrap" data-session="c7"><button class="pill has-menu" data-slide="c7" data-jump-to="pilot-rollout">7 &middot; Pilot</button></span>
<span class="pill-wrap" data-session="c8"><button class="pill has-menu" data-slide="c8" data-jump-to="adoption-motion">8 &middot; Adoption</button></span>
```

Append CSS rules for `.bottomnav .pill[data-slide="c1..c8"]` hover/active so pills colour-match the cards: c1+c2 blue · c3+c4 purple · c5+c6 teal · c7 orange · c8 pink.

## Build procedure

1. **Fetch / refresh sources.** If argument is `refresh` or version tag, refetch the 5 web sources and re-download the PPTX. Otherwise rely on the cached `.tmp-techguide.md` extract.
2. **Read the template** (`Template/Workshop Template.html`). Re-locate head/body/script line numbers if shifted.
3. **Draft body content** at `.tmp-impl-body.html` containing the 11 sections in order.
4. **Stitch the file**:

   ```powershell
   $src='Template\Workshop Template.html'; $body='.tmp-impl-body.html'; $dst='copilot-chat-readiness.html'
   $lines = Get-Content -LiteralPath $src -Encoding UTF8
   $head  = $lines[0..9682]
   $tail  = $lines[19583..($lines.Count-1)]
   $head  = $head | ForEach-Object { if ($_ -match '<title>') { '<title>Copilot Chat Readiness &mdash; Hands-on implementation guide</title>' } else { $_ } }
   $bodyText = Get-Content -LiteralPath $body -Raw -Encoding UTF8
   $sb = [System.Text.StringBuilder]::new()
   [void]$sb.AppendLine(($head -join [Environment]::NewLine))
   [void]$sb.AppendLine($bodyText)
   [void]$sb.AppendLine(($tail -join [Environment]::NewLine))
   [System.IO.File]::WriteAllText((Join-Path $PWD $dst), $sb.ToString(), [System.Text.UTF8Encoding]::new($false))
   Remove-Item $body
   ```

5. **Replace** the template's `slides` array + `slideToPill` (lines ~10198–10260 in the stitched file) with the 11-slide block above.
6. **Inject** the `<nav class="bottomnav">` + `<div class="keys-hint">` + `<div class="pause-overlay">` block immediately before the final `<script>`.
7. **Append** CSS pill colours for `c1..c8` (insert after the existing `c6` rule near line 339 of the original template style block — or via `(Get-Content $dst -Raw) -replace …` once).
8. **Update cover copy**: `<title>`, `cover-subtitle`, `cover-meta`, `dispatch`. Set 18 cover-bubbles at the orbital positions listed in the patterns section.

## Output contract

- Single file: `copilot-chat-readiness.html` at the workspace root.
- UTF-8, no BOM, ~11,000 lines, ~600 KB.
- 100% self-contained except for the icons8 product-bubble images (CDN).
- `<title>` = `Copilot Chat Readiness — Hands-on implementation guide`.
- `cover-pill` = `Workshop`; `cover-title` = `Copilot Chat<br>Readiness`; `cover-subtitle` = "A hands-on implementation guide for IT and adoption leads…".
- `dispatch` tag = `Copilot.Chat.Implementation · v<YYYY.MM.DD>`.
- Footer line at the bottom of `#adoption-motion`: `© Microsoft Corporation. All rights reserved. · Sources last verified <ISO date>.`

## Validation gates (every build must pass all)

```powershell
$f = 'copilot-chat-readiness.html'
$c = [System.IO.File]::ReadAllText((Resolve-Path $f), [System.Text.UTF8Encoding]::new($false))

# Structural
@(
  @{ name='Sections';       check={ ([regex]::Matches($c,'<section id="[^"]+"')).Count -eq 11 } },
  @{ name='Placeholders';   check={ ([regex]::Matches($c,'\{\{[^}]+\}\}')).Count -eq 0 } },
  @{ name='Ends with html'; check={ $c.TrimEnd().EndsWith('</html>') } },
  @{ name='slides has 11';  check={ ([regex]::Matches([regex]::Match($c,'const slides = \[([^\]]+)\];').Groups[1].Value,"'[^']+'")).Count -eq 11 } },
  @{ name='Title correct';  check={ $c -match 'Copilot Chat Readiness &mdash; Hands-on implementation guide' } },
  @{ name='No dup slides';  check={ ([regex]::Matches($c,'const slides = \[')).Count -eq 1 } }
) | ForEach-Object { "{0,-20}  {1}" -f $_.name, ($_.check.Invoke()) }

# Wiring
$sm = [regex]::Match($c,"const slides = \[([^\]]+)\];").Groups[1].Value
$ids = [regex]::Matches($sm,"'([^']+)'") | ForEach-Object { $_.Groups[1].Value }
[regex]::Matches($c,'data-jump(-to)?="([^"]+)"') | ForEach-Object {
  $t = $_.Groups[2].Value
  if ($ids -notcontains $t) { "BROKEN data-jump: $t" }
}
```

## URL health check

Run periodically — and **always** after a refresh build — to detect Microsoft docs URL drift. Microsoft Learn paths change every 6–12 months.

```powershell
$f = 'copilot-chat-readiness.html'
$c = Get-Content -LiteralPath $f -Raw -Encoding UTF8
$urls = [regex]::Matches($c,'<a href="(https?://[^"]+)"') | ForEach-Object { $_.Groups[1].Value } | Sort-Object -Unique
"Total unique URLs: $($urls.Count)"
$bad = @()
foreach ($u in $urls) {
  try {
    $r = Invoke-WebRequest -Uri $u -Method Get -MaximumRedirection 8 -UseBasicParsing -TimeoutSec 12
    if ($r.StatusCode -ne 200) { $bad += "$($r.StatusCode)  $u" }
  } catch {
    $code = $_.Exception.Response.StatusCode.value__
    if ($code -eq 404) { $bad += "404  $u" }
  }
}
"Broken: $($bad.Count)"
$bad
```

**Known good URL patterns (verified v2026.05.15):**

- Microsoft Adoption: `adoption.microsoft.com/copilot`, `…/copilot-chat/`, `…/copilot/success-kit/`, `…/copilot/learning-hub/`, `…/copilot/control-system/`, `…/copilot/launch-day-kit/`, `…/become-a-champion`, `…/ai-agents`, `…/ai-agents/copilot-studio`
- Microsoft Learn (en-us, never en-gb): `learn.microsoft.com/en-us/microsoft-365/copilot/*`, `…/purview/*`, `…/sharepoint/*`, `…/microsoft-365-apps/*`, `…/viva/insights/org-team-insights/copilot-dashboard`, `…/microsoft-copilot-studio/*`, `…/microsoft-365/admin/manage/manage-copilot-agents-integrated-apps`, `…/microsoft-365/copilot/pin-copilot`
- aka.ms shortlinks: `aka.ms/Copilot/SuccessKitDownload`, `aka.ms/Copilot/ChatJourney`, `aka.ms/Copilot/ChatJourneyKit`, `aka.ms/AMC/CopilotCommunity`, `aka.ms/copilotchatroadmap`, `aka.ms/AppAssureRequest`, `aka.ms/CopilotStudioWorkshop`
- Admin portals: `admin.microsoft.com/Adminportal/Home...`, `admin.microsoft.com/sharepoint?...`, `purview.microsoft.com/`, `security.microsoft.com/securescore`, `security.microsoft.com/incidents`, `config.office.com/...`, `connectivity.office.com/`, `entra.microsoft.com/`
- Other Microsoft: `www.microsoft.com/solutionassessments/`, `…/ai/responsible-ai`, `…/fasttrack/microsoft-365/copilot`, `…/unifiedsupport`

**Known broken URLs (do NOT use these — fixed in v2026.05.15):**

| Old (404) | Replacement |
|-----------|-------------|
| `learn.microsoft.com/en-us/copilot/microsoft-365/microsoft-365-copilot-control-system` | `adoption.microsoft.com/copilot/control-system/` |
| `learn.microsoft.com/en-us/viva/insights/advanced/admin/copilot-dashboard` | `learn.microsoft.com/en-us/viva/insights/org-team-insights/copilot-dashboard` |
| `learn.microsoft.com/en-us/purview/dlp-copilot-learn-about` | `learn.microsoft.com/en-us/purview/dlp-learn-about-dlp` |
| `learn.microsoft.com/en-us/microsoft-365-apps/updates/cloud-update` | `learn.microsoft.com/en-us/microsoft-365-apps/admin-center/cloud-update` |
| `learn.microsoft.com/en-us/microsoft-365-apps/updates/` (trailing slash) | `learn.microsoft.com/en-us/microsoft-365-apps/updates/overview-update-channels` |
| `aka.ms/CopilotStudioInADay` | `aka.ms/CopilotStudioWorkshop` |
| any `learn.microsoft.com/en-gb/...` | rewrite to `/en-us/...` |

## Style rules

- **Tone:** Microsoft official, first-person plural (*we*, *our customers*). No marketing fluff; quote stats only when sourced. Imperative voice for action items ("Run…", "Apply…", "Verify…").
- **Audience:** customer-runnable wherever possible. Never tell the reader to "engage your account team" as the primary path; reserve that for clearly partner-led workstreams (FastTrack, Optimization Assessment partner engagement) and mark them explicitly as such.
- **Path tagging:** every Step 3 / 4 collapsible card that is path-specific must carry the `· Foundational` (blue) or `· Optimized path` (purple) tag in the title.
- **No third-party brands** in the page body. Cite only Microsoft properties + Icons8 CDN for product logos.
- **Reuse, do not invent.** Only use classes that exist in `Workshop Template.html` plus the locally-injected `.deliv*` classes for collapsibles.
- **Accessibility:** every external link gets `target="_blank" rel="noopener"`. Use `<details>`/`<summary>` (native, keyboard-accessible) for collapsibles — no JS needed.
- **Idempotency:** running the agent twice with the same inputs and same source URLs must produce a byte-identical output (`git diff` empty).
- **Deliverable file naming:** strict `NN-XX_short-name_yyyy-mm-dd.ext` where `NN` is the step number (`02`, `03`, …) and `XX` is the deliverable index. Step 4 uses `04-F1..F10` for Foundational and `04-O1..O4` for Optimized.

## Versioning

- Update `dispatch` tag and the "Sources last verified" footer date on every build.
- After a clean build that passes all validation gates, copy the file to `copilot-chat-readiness.v<YYYY.MM.DD>.html` and record the SHA256 hash here.
- Companion refresh agent: [`copilot-readiness-refresh.agent.md`](copilot-readiness-refresh.agent.md) — runs the URL health check, diff vs. PPTX and proposes incremental updates (does not regenerate the whole page).
