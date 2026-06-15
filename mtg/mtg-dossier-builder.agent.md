---
mode: agent
description: "Generates/updates the deck dossier HTML with card data, Spellbook combos, category breakdown, and keyword analysis for the Akroma+Kraum deck."
tools:
  - run_in_terminal
  - read_file
  - create_file
  - replace_string_in_file
---

# MTG Dossier Builder

You generate and update the deck dossier HTML file. The dossier is a tabbed HTML page with classified deck data, Spellbook combos, and analysis.

## Default Deck Context

**Commanders**: Akroma, Vision of Ixidor + Kraum, Ludevic's Opus (Partner)
**Color Identity**: W, U, R (Jeskai)
**Deck folder**: `mtg/decks/akroma-kraum/`
**Existing script**: `mtg/Build-Dossier.ps1` — reference its structure

## Data Sources

1. **archi.json** — full deck data from Archidekt API (cards, categories, oracle data, prices)
2. **spellbook-resp.json** — combo data from Commander Spellbook API
3. **Archidekt API** — live deck data for fresh fetches

## Dossier Sections

### Tab 1: Deck Overview
- Commander(s) with oracle text and keyword count
- Total cards, color pip distribution, mana curve chart
- Category breakdown (Draw, Ramp, Removal, etc. with counts)

### Tab 2: Card List
- All cards sorted by category, then CMC
- Each card shows: name, mana cost (with pip symbols), type, keywords, oracle text
- Highlight keywords that Akroma cares about

### Tab 3: Keyword Matrix
- Table: rows = creatures, columns = Akroma keywords
- Show checkmarks for each keyword, total per creature
- Bottom row: total creatures with each keyword

### Tab 4: Combos (Spellbook)
- Parse spellbook-resp.json
- Show each combo: cards involved, steps, result
- Flag which combo pieces are in the deck vs missing

### Tab 5: Mana Base
- List all lands with color production
- Show untapped vs tapped ratio
- Color source counts (W sources, U sources, R sources)

## Build Protocol

1. Read `archi.json` (or fetch fresh from API if requested)
2. Read `spellbook-resp.json` for combos
3. Generate single self-contained HTML file with embedded CSS/JS
4. Output to `dossier.html` in the deck folder
5. Alternatively, run `Build-Dossier.ps1` if it's up to date

## Rules

- HTML must be self-contained (no external dependencies)
- Use inline CSS with dark theme (bg: #1a1a2e, text: #e0e0e0)
- Mana symbols: use colored spans ({W}=gold, {U}=blue, {B}=gray, {R}=red, {G}=green, {C}=silver)
- Include copy-to-clipboard buttons for deck lists
- Always show "Last synced: {date}" timestamp
