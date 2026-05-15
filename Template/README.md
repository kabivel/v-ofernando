# Templates

Reusable HTML templates and shared visual assets for the v-ofernando workspace.

## Files

| File | Purpose |
|------|---------|
| `Template.html` | AI Agents Workshop deck — visual reference (cover, bottom-nav patterns) |
| `m365-roadmap.template.html` | Monthly **M365 Roadmap** page template (placeholders below) |
| `Icons/`, `other.icons/`, `partner.icons/` | Local icon assets used by `Template.html` |
| `Screen.prints/` | Screenshots used during template iteration |

## `m365-roadmap.template.html` placeholders

Plain-text replace `{{NAME}}` markers — none of them appear inside JS strings.

| Placeholder | Example | Where |
|-------------|---------|-------|
| `{{MONTH_YEAR}}` | `May 2026` | `<title>`, header brand, cover subtitle, eyebrow |
| `{{MONTH_SLUG}}` | `May` | dispatch tag (cover footer) |
| `{{VERSION}}` | `2026.06` | dispatch tag (cover footer) |
| `{{ISO_DATE}}` | `06/14/2026` (mm/dd/yyyy) | footer source line |
| `{{HEADLINE}}` | `What's shipping this month` | rmhead `<h1>` |
| `{{SUBHEAD}}` | one-paragraph HTML | rmhead description |
| `{{FEATURES_JSON}}` | JS array literal `[{ id, title, product, status, date, short, desc, ... }]` | `const FEATURES = {{FEATURES_JSON}};` |

### Producers / consumers

- **Collector** (data source): [`agent/m365-roadmap.agent.md`](../agent/m365-roadmap.agent.md) — fetches the official Microsoft 365 Roadmap RSS and emits a JSON block.
- **Generator** (page builder): [`agent/m365-roadmap-page.agent.md`](../agent/m365-roadmap-page.agent.md) — reads this template, fills placeholders from the collector's JSON, and writes `m365-roadmap-<month>.html` at the repo root.
