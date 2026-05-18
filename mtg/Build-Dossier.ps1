# Builds ishai-vial-dossier.html — a tabbed agent dossier with classified
# deck data, Spellbook combos, and copy-to-clipboard prompts for each
# /mtg-* agent. Reads archi.json + spellbook-resp.json (already fetched).
[CmdletBinding()]
param(
    [string]$DeckJson = "archi.json",
    [string]$ComboJson = "spellbook-resp.json",
    [string]$Out = "ishai-vial-dossier.html"
)
$ErrorActionPreference = 'Stop'

function Html-Escape([string]$s) {
    if ($null -eq $s) { return "" }
    return $s.Replace('&', '&amp;').Replace('<', '&lt;').Replace('>', '&gt;').Replace('"', '&quot;')
}

function Mana-Pips([string]$mc) {
    if (-not $mc) { return "" }
    return [regex]::Replace([regex]::Escape($mc), '\\\{([^}]+)\\\}', {
        param($m)
        $sym = $m.Groups[1].Value.ToLower()
        $bg = switch ($sym) {
            'w' { '#fff8d6' } 'u' { '#aad8f5' } 'b' { '#cfc2bc' } 'r' { '#f6b7a3' } 'g' { '#a3d2a3' } default { '#dcdcdc' }
        }
        return "<span class='mp' style='background:$bg'>$($sym.ToUpper())</span>"
    })
}

$d = Get-Content $DeckJson -Raw | ConvertFrom-Json
$r = (Get-Content $ComboJson -Raw | ConvertFrom-Json).results

$cards = foreach ($c in $d.cards) {
    $name = $c.card.oracleCard.name
    if (-not $name) { continue }
    if ($c.deletedAt) { continue }   # skip soft-deleted cards
    $cats = @($c.categories)
    $section = if ($cats -contains 'Commander') { 'Commander' }
               elseif ($cats -contains 'Sideboard') { 'Sideboard' }
               elseif ($cats -contains 'Maybeboard') { 'Maybeboard' }
               else { 'Mainboard' }
    [PSCustomObject]@{
        Name        = $name
        Qty         = $c.quantity
        Cmc         = [double]($c.card.oracleCard.cmc)
        Mc          = $c.card.oracleCard.manaCost
        Types       = @($c.card.oracleCard.types)
        Text        = ($c.card.oracleCard.text -as [string])
        Colors      = @($c.card.oracleCard.colors)
        Ci          = @($c.card.oracleCard.colorIdentity)
        Cats        = $cats
        Section     = $section
        IsCommander = ($section -eq 'Commander')
    }
}

$commanders = $cards | Where-Object { $_.Section -eq 'Commander' }
$mainboard  = $cards | Where-Object { $_.Section -eq 'Mainboard' }
$sideboard  = $cards | Where-Object { $_.Section -eq 'Sideboard' }
$maybeboard = $cards | Where-Object { $_.Section -eq 'Maybeboard' }
$total      = (($commanders + $mainboard) | Measure-Object Qty -Sum).Sum

# Classification helpers
function Is-Land($c)    { $c.Types -contains 'Land' }
function Is-Creature($c){ $c.Types -contains 'Creature' }
function Is-Artifact($c){ $c.Types -contains 'Artifact' }
function Is-Inst($c)    { $c.Types -contains 'Instant' -or $c.Types -contains 'Sorcery' }
function Is-Rock($c)    { (Is-Artifact $c) -and $c.Cmc -le 3 -and $c.Text -match '(?i)\bAdd\b' }
function Is-Dork($c)    { (Is-Creature $c) -and $c.Cmc -le 2 -and $c.Text -match '(?i)\{T\}:\s*Add' }
function Is-Ritual($c)  { (Is-Inst $c) -and $c.Text -match '(?i)\bAdd\b.*mana|\bAdd\b\s*\{' }
function Is-Draw($c)    {
    if (Is-Land $c) { return $false }
    return $c.Text -match '(?i)\bdraw(?:s)?\s+(?:a|two|three|four|five|seven|x|cards|that many)'
}
function Is-Counter($c) { $c.Text -match '(?i)\bcounter target' }
function Is-Removal($c) { $c.Text -match '(?i)(?:destroy|exile)\s+target' }
function Is-Wipe($c)    { $c.Text -match '(?i)(?:destroy|exile)\s+all|each creature' }
function Is-Tutor($c)   { $c.Text -match '(?i)search your library for' }
function Is-FastMana($c){ $c.Name -match '^(Mana Crypt|Sol Ring|Mana Vault|Mox |Lotus Petal|Lion''s Eye Diamond|Chrome Mox|Jeweled Lotus|Ancient Tomb|City of Traitors|Gemstone Caverns)' }

$lands     = $mainboard | Where-Object { Is-Land $_ }
$rocks     = $mainboard | Where-Object { Is-Rock $_ }
$dorks     = $mainboard | Where-Object { Is-Dork $_ }
$rituals   = $mainboard | Where-Object { Is-Ritual $_ }
$draws     = $mainboard | Where-Object { Is-Draw $_ }
$counters  = $mainboard | Where-Object { Is-Counter $_ }
$removals  = $mainboard | Where-Object { Is-Removal $_ }
$wipes     = $mainboard | Where-Object { Is-Wipe $_ }
$tutors    = $mainboard | Where-Object { Is-Tutor $_ }
$fastmana  = $cards    | Where-Object { Is-FastMana $_ }

# Type distribution (excluding commanders for clarity? include all)
$typeOrder = 'Creature','Planeswalker','Battle','Instant','Sorcery','Artifact','Enchantment','Land'
$typeCounts = [ordered]@{}
foreach ($t in $typeOrder) { $typeCounts[$t] = 0 }
$typeCounts['Other'] = 0
foreach ($c in $mainboard) {
    $bucket = 'Other'
    foreach ($t in $typeOrder) { if ($c.Types -contains $t) { $bucket = $t; break } }
    $typeCounts[$bucket] += $c.Qty
}

# CMC curve (non-land)
$cmcBuckets = [ordered]@{ '0'=0; '1'=0; '2'=0; '3'=0; '4'=0; '5'=0; '6'=0; '7+'=0 }
foreach ($c in $mainboard) {
    if (Is-Land $c) { continue }
    $k = if ($c.Cmc -ge 7) { '7+' } else { [string][math]::Floor($c.Cmc) }
    if ($cmcBuckets.Contains($k)) { $cmcBuckets[$k] += $c.Qty }
}

# Color pips (non-land mana costs)
$pipCounts = [ordered]@{ W=0; U=0; B=0; R=0; G=0 }
foreach ($c in $mainboard) {
    if (Is-Land $c -or -not $c.Mc) { continue }
    foreach ($m in [regex]::Matches($c.Mc, '\{([WUBRG])\}')) {
        $sym = $m.Groups[1].Value.ToUpper()
        $pipCounts[$sym] += $c.Qty
    }
}

# Combo rendering
function ComboLine($v, [hashtable]$deckSet) {
    $names = $v.uses | ForEach-Object { $_.card.name }
    $missing = $names | Where-Object { -not $deckSet[$_.ToLower()] }
    $cards = ($names | ForEach-Object {
        $present = $deckSet[$_.ToLower()]
        $cls = if ($present) { 'card-in' } else { 'card-out' }
        "<span class='$cls'>$(Html-Escape $_)</span>"
    }) -join ' + '
    $produces = ($v.produces | ForEach-Object { $_.feature.name } | Select-Object -First 3) -join ' · '
    $bracket = $v.bracketTag
    $bracketLabel = switch ($bracket) { 'E' { 'B2' } 'R' { 'B3' } 'S' { 'B4' } 'P' { 'cEDH B5' } default { $bracket } }
    $desc = $v.description
    if ($desc) { $desc = ($desc -split "`n" | Select-Object -First 2) -join ' '; if ($desc.Length -gt 220) { $desc = $desc.Substring(0,220) + '…' } }
    $cls2 = if ($missing.Count -eq 0) { 'combo' } else { 'combo near' }
    $missingLabel = if ($missing.Count -gt 0) { " · missing: <strong>$([string]::Join(', ', ($missing | ForEach-Object { Html-Escape $_ })))</strong>" } else { "" }
    return @"
<div class='$cls2'>
  <div class='combo-title'>$cards</div>
  <div class='combo-meta'>$bracketLabel · pop $([math]::Round([double]$v.popularity,0))$missingLabel</div>
  <div class='combo-prod'>→ $(Html-Escape $produces)</div>
  $(if ($desc) { "<div class='combo-desc'>$(Html-Escape $desc)</div>" } else { "" })
</div>
"@
}

$deckSet = @{}
foreach ($c in $cards) { $deckSet[$c.Name.ToLower()] = $true }

# Sort combos
$includedSorted = @($r.included) | Sort-Object { -[double]$_.popularity }
$almostSorted = @($r.almostIncluded) |
    Where-Object { (@($_.uses) | Where-Object { -not $deckSet[$_.card.name.ToLower()] }).Count -eq 1 } |
    Sort-Object { -[double]$_.popularity } |
    Select-Object -First 15

# Build card table row
function CardRow($c) {
    $mc = Mana-Pips $c.Mc
    $name = Html-Escape $c.Name
    return "<tr><td class='qty'>$($c.Qty)×</td><td>$name</td><td>$mc</td><td class='cmc'>$([math]::Floor($c.Cmc))</td><td>$(Html-Escape ([string]::Join(' · ', $c.Types)))</td></tr>"
}
function CardTable($list) {
    if (-not $list -or $list.Count -eq 0) { return "<p class='empty'>No cards in this category.</p>" }
    $rows = ($list | Sort-Object Cmc, Name | ForEach-Object { CardRow $_ }) -join ''
    return "<table><thead><tr><th></th><th>Name</th><th>Cost</th><th>CMC</th><th>Type</th></tr></thead><tbody>$rows</tbody></table>"
}

function Bar($val, $max) {
    $pct = if ($max -gt 0) { [math]::Round(($val / $max) * 100) } else { 0 }
    return "<div class='bar'><div class='bar-fill' style='width:$pct%'></div><span class='bar-val'>$val</span></div>"
}

function PromptBlock([string]$agent, [string]$hint) {
    return @"
<div class='prompt-block'>
  <div class='ph'>Agent prompt</div>
  <code>/mtg-$agent &lt;your question&gt;</code>
  <button onclick="copyPrompt('$agent')">Copy prompt + deck context</button>
  <div class='hint'>$hint</div>
</div>
"@
}

$maxCmc = ($cmcBuckets.Values | Measure-Object -Maximum).Maximum
$maxType = ($typeCounts.Values | Measure-Object -Maximum).Maximum
$maxPip = ($pipCounts.Values | Measure-Object -Maximum).Maximum

$cmcRows = ($cmcBuckets.GetEnumerator() | ForEach-Object {
    "<div class='bar-row'><span class='lbl'>$($_.Key)</span>$(Bar $_.Value $maxCmc)</div>"
}) -join ''
$typeRows = ($typeCounts.GetEnumerator() | Where-Object { $_.Value -gt 0 } | ForEach-Object {
    "<div class='bar-row'><span class='lbl'>$($_.Key.Substring(0,[Math]::Min(4,$_.Key.Length)))</span>$(Bar $_.Value $maxType)</div>"
}) -join ''
$pipRows = ($pipCounts.GetEnumerator() | Where-Object { $_.Value -gt 0 } | ForEach-Object {
    "<div class='bar-row'><span class='lbl'>$($_.Key)</span>$(Bar $_.Value $maxPip)</div>"
}) -join ''

$includedHtml = if ($includedSorted.Count -eq 0) { "<p class='empty'>No confirmed Spellbook combos.</p>" } else { ($includedSorted | ForEach-Object { ComboLine $_ $deckSet }) -join '' }
$nearHtml = if ($almostSorted.Count -eq 0) { "<p class='empty'>No actionable near-combos.</p>" } else { ($almostSorted | ForEach-Object { ComboLine $_ $deckSet }) -join '' }

$deckListMd = "# $($d.name)`n`nCommander(s): $((($commanders | ForEach-Object { $_.Name }) -join ' + '))`nIdentity: $($r.identity)  |  Total: $total`n`n## Decklist`n" +
              (($cards | Sort-Object IsCommander -Descending | ForEach-Object { "- $($_.Qty)x $($_.Name) $($_.Mc) (CMC $([math]::Floor($_.Cmc)))" }) -join "`n")

# JSON-encode deck list once for embedding in JS (clipboard text)
$deckListJson = $deckListMd | ConvertTo-Json -Compress
$combosJson = ($includedSorted + $almostSorted | ForEach-Object {
    $names = ($_.uses | ForEach-Object { $_.card.name }) -join ' + '
    $produces = ($_.produces | ForEach-Object { $_.feature.name }) -join ', '
    "- $names → $produces (B$($_.bracketTag), pop $([math]::Round([double]$_.popularity,0)))"
}) -join "`n"
$combosJsonEnc = $combosJson | ConvertTo-Json -Compress

$commanderNames = ($commanders | ForEach-Object { $_.Name }) -join ' + '

$html = @"
<!doctype html>
<html lang='en'>
<head>
<meta charset='utf-8'>
<title>$(Html-Escape $d.name) — Agent Dossier</title>
<style>
:root {
  --bg: #0f1419;
  --panel: #1a1f2e;
  --panel-2: #232a3d;
  --border: #2d3548;
  --text: #e6e8ec;
  --muted: #8a93a6;
  --accent: #7dd3fc;
  --good: #86efac;
  --warn: #fbbf24;
  --bad: #fca5a5;
}
* { box-sizing: border-box; }
body { margin: 0; font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', system-ui, sans-serif; background: var(--bg); color: var(--text); padding: 16px; }
.container { max-width: 1200px; margin: 0 auto; }
h1 { margin: 0 0 4px; font-size: 24px; }
h2 { margin: 0 0 12px; font-size: 18px; color: var(--accent); border-bottom: 1px solid var(--border); padding-bottom: 6px; }
h3 { margin: 16px 0 6px; font-size: 13px; color: var(--muted); text-transform: uppercase; letter-spacing: 0.5px; }
.meta { color: var(--muted); margin-bottom: 16px; font-size: 13px; }
.meta strong { color: var(--text); }

.tabs { display: flex; gap: 2px; border-bottom: 1px solid var(--border); margin-bottom: 0; flex-wrap: wrap; }
.tab { padding: 8px 14px; cursor: pointer; background: var(--panel); border: 1px solid var(--border); border-bottom: none; border-radius: 4px 4px 0 0; font-size: 13px; color: var(--muted); }
.tab.active { background: var(--panel-2); color: var(--accent); font-weight: 600; }
.tab:hover { color: var(--text); }

.panel { background: var(--panel-2); border: 1px solid var(--border); border-top: none; padding: 18px; min-height: 400px; }
.panel section { display: none; }
.panel section.active { display: block; }

.stat-row { display: flex; gap: 10px; flex-wrap: wrap; margin-bottom: 16px; }
.stat { background: var(--panel); border-radius: 6px; padding: 8px 14px; }
.stat-label { color: var(--muted); font-size: 11px; text-transform: uppercase; }
.stat-value { font-size: 22px; font-weight: 600; }

.grid-3 { display: grid; grid-template-columns: repeat(3, 1fr); gap: 16px; }
.card-panel { background: var(--panel); border: 1px solid var(--border); border-radius: 6px; padding: 14px; }

.bar { background: var(--panel); height: 22px; border-radius: 4px; position: relative; margin: 4px 0; overflow: hidden; }
.bar-fill { background: linear-gradient(90deg, #4f46e5, var(--accent)); height: 100%; }
.bar-val { position: absolute; right: 8px; top: 2px; font-size: 12px; font-weight: 600; }
.bar-row { display: grid; grid-template-columns: 50px 1fr; align-items: center; gap: 8px; font-size: 13px; }
.bar-row .lbl { color: var(--muted); text-align: right; }

.mp { display: inline-block; padding: 1px 6px; border-radius: 50%; font-weight: 700; color: #111; font-size: 11px; min-width: 14px; text-align: center; }

table { width: 100%; border-collapse: collapse; font-size: 13px; margin-top: 8px; }
th, td { text-align: left; padding: 4px 8px; border-bottom: 1px solid var(--border); }
th { color: var(--muted); font-weight: 500; font-size: 11px; text-transform: uppercase; }
td.qty { color: var(--muted); width: 30px; }
td.cmc { color: var(--muted); text-align: right; width: 40px; }

.combo { background: var(--panel); border-left: 3px solid var(--good); padding: 10px 14px; margin-bottom: 10px; border-radius: 4px; }
.combo.near { border-left-color: var(--warn); }
.combo-title { font-weight: 600; margin-bottom: 4px; font-size: 14px; }
.combo-meta { color: var(--muted); font-size: 12px; margin-bottom: 4px; }
.combo-prod { color: var(--good); font-size: 12px; margin-bottom: 4px; }
.combo-desc { font-size: 12px; color: var(--muted); line-height: 1.4; }
.card-in { color: var(--text); }
.card-out { color: var(--warn); text-decoration: underline dashed; }

.prompt-block { background: var(--panel); border: 1px dashed var(--border); border-radius: 4px; padding: 12px; margin-top: 16px; }
.prompt-block .ph { color: var(--muted); font-size: 11px; text-transform: uppercase; letter-spacing: 0.5px; margin-bottom: 6px; }
.prompt-block code { display: block; background: var(--bg); padding: 8px; border-radius: 3px; font-size: 12px; color: var(--accent); margin-bottom: 8px; word-break: break-word; }
.prompt-block button { background: var(--accent); color: #000; border: 0; padding: 6px 12px; border-radius: 3px; font-weight: 600; cursor: pointer; font-size: 12px; }
.prompt-block button:hover { opacity: 0.85; }
.prompt-block .hint { color: var(--muted); font-size: 11px; margin-top: 6px; }
.empty { color: var(--muted); font-style: italic; }
.combos-split { display: grid; gap: 18px; }
.combos-section { background: var(--panel); border: 1px solid var(--border); border-radius: 6px; padding: 14px; }
.sec-head { margin: 0 0 10px; font-size: 13px; text-transform: uppercase; letter-spacing: 0.5px; padding-bottom: 6px; border-bottom: 1px solid var(--border); }
.sec-head.sec-in { color: var(--good); border-bottom-color: var(--good); }
.sec-head.sec-out { color: var(--warn); border-bottom-color: var(--warn); }
.hint-text { font-size: 12px; color: var(--muted); margin: 4px 0 12px; }
.footer { text-align: center; color: var(--muted); font-size: 11px; margin-top: 20px; }
.footer a { color: var(--accent); }
</style>
</head>
<body>
<div class='container'>
<h1>$(Html-Escape $d.name)</h1>
<div class='meta'>
  <strong>$(Html-Escape $commanderNames)</strong>
  · $($r.identity) identity
  · $total cards
  · $($includedSorted.Count) combos · $($almostSorted.Count) near-combos
  · imported from <a href='https://archidekt.com/decks/6845199/' style='color:var(--accent)'>Archidekt</a>
  · generated $(Get-Date -Format 'yyyy-MM-dd HH:mm')
</div>

<div class='tabs'>
  <div class='tab active' data-tab='overview'>Overview</div>
  <div class='tab' data-tab='manabase'>Manabase</div>
  <div class='tab' data-tab='ramp'>Ramp</div>
  <div class='tab' data-tab='draw'>Draw</div>
  <div class='tab' data-tab='removal'>Removal</div>
  <div class='tab' data-tab='synergies'>Synergies</div>
  <div class='tab' data-tab='combos'>Combos</div>
  <div class='tab' data-tab='sideboard'>Side/Maybe</div>
  <div class='tab' data-tab='strategy'>Strategy</div>
</div>

<div class='panel'>

<section id='overview' class='active'>
<h2>Overview</h2>
<div class='stat-row'>
  <div class='stat'><div class='stat-label'>Total</div><div class='stat-value'>$total</div></div>
  <div class='stat'><div class='stat-label'>Lands</div><div class='stat-value'>$(($lands | Measure-Object Qty -Sum).Sum)</div></div>
  <div class='stat'><div class='stat-label'>Ramp</div><div class='stat-value'>$((($rocks + $dorks + $rituals + $fastmana) | Sort-Object Name -Unique | Measure-Object Qty -Sum).Sum)</div></div>
  <div class='stat'><div class='stat-label'>Draw</div><div class='stat-value'>$(($draws | Measure-Object Qty -Sum).Sum)</div></div>
  <div class='stat'><div class='stat-label'>Interaction</div><div class='stat-value'>$((($counters + $removals + $wipes) | Sort-Object Name -Unique | Measure-Object Qty -Sum).Sum)</div></div>
  <div class='stat'><div class='stat-label'>Tutors</div><div class='stat-value'>$(($tutors | Measure-Object Qty -Sum).Sum)</div></div>
  <div class='stat'><div class='stat-label'>Combos in deck</div><div class='stat-value' style='color:var(--good)'>$($includedSorted.Count)</div></div>
  <div class='stat'><div class='stat-label'>Missing 1 card</div><div class='stat-value' style='color:var(--warn)'>$($almostSorted.Count)</div></div>
</div>

<div class='grid-3'>
  <div class='card-panel'><h3>Mana Curve (non-land)</h3>$cmcRows</div>
  <div class='card-panel'><h3>Type Distribution</h3>$typeRows</div>
  <div class='card-panel'><h3>Color Pips</h3>$pipRows</div>
</div>

<div class='prompt-block'>
  <div class='ph'>To run the orchestrator</div>
  <code>@MTG EDH Orchestrator — analyze this deck, weaknesses and bracket recommendation</code>
  <button onclick="copyDeckPrompt()">Copy deck context to clipboard</button>
  <div class='hint'>Then paste into Copilot Chat with the MTG EDH Orchestrator chat mode selected.</div>
</div>
</section>

<section id='manabase'>
<h2>Manabase ($(($lands | Measure-Object Qty -Sum).Sum) lands)</h2>
$(CardTable $lands)
$(PromptBlock 'manabase' 'evaluate land count vs CMC, color sources per color, fixing density, fast lands, tap-land tax')
</section>

<section id='ramp'>
<h2>Ramp</h2>
<h3>Mana rocks ($(($rocks | Measure-Object Qty -Sum).Sum))</h3>
$(CardTable $rocks)
<h3>Mana dorks ($(($dorks | Measure-Object Qty -Sum).Sum))</h3>
$(CardTable $dorks)
<h3>Rituals ($(($rituals | Measure-Object Qty -Sum).Sum))</h3>
$(CardTable $rituals)
<h3>Fast mana ($(($fastmana | Measure-Object Qty -Sum).Sum))</h3>
$(CardTable $fastmana)
$(PromptBlock 'ramp' 'evaluate ramp density, turn-1 plays, curve consistency, creature vs artifact tradeoffs')
</section>

<section id='draw'>
<h2>Draw Engines ($(($draws | Measure-Object Qty -Sum).Sum))</h2>
$(CardTable $draws)
$(PromptBlock 'draw' 'distinguish repeatable engines from one-shot draw, count engines and evaluate redundancy')
</section>

<section id='removal'>
<h2>Removal & Interaction</h2>
<h3>Counterspells ($(($counters | Measure-Object Qty -Sum).Sum))</h3>
$(CardTable $counters)
<h3>Targeted removal ($(($removals | Measure-Object Qty -Sum).Sum))</h3>
$(CardTable $removals)
<h3>Board wipes / mass effects ($(($wipes | Measure-Object Qty -Sum).Sum))</h3>
$(CardTable $wipes)
$(PromptBlock 'removal' 'evaluate interaction density, coverage gaps, exile vs destroy, free interaction count')
</section>

<section id='synergies'>
<h2>Synergies — full mainboard for review</h2>
<p class='empty'>This lens is best handled by the LLM. Use the copy-prompt button to send the full deck context to the synergies agent.</p>
$(CardTable ($mainboard | Where-Object { -not (Is-Land $_) }))
$(PromptBlock 'synergies' 'identify theme cohesion, payoff vs enabler ratio, commander-specific abuse, off-theme cards to cut')
</section>

<section id='combos'>
<h2>Combos & Win Conditions</h2>

<div class='combos-split'>
  <div class='combos-section'>
    <h3 class='sec-head sec-in'>✓ Combos in deck ($($includedSorted.Count)) — all cards present</h3>
    $includedHtml
  </div>
  <div class='combos-section'>
    <h3 class='sec-head sec-out'>✗ Combos NOT in deck (top $($almostSorted.Count)) — 1 card missing each</h3>
    <p class='hint-text'>These combos are <strong>not assembled</strong> in the current deck. The missing card name is highlighted in yellow on each line. Pick up the missing piece to enable the combo.</p>
    $nearHtml
  </div>
</div>

$(PromptBlock 'combos' 'evaluate tutor density to assemble combos, protection layers, redundancy, realistic turn of assembly')
</section>

<section id='sideboard'>
<h2>Sideboard / Maybeboard</h2>
<p class='hint-text'>These cards are <strong>NOT</strong> part of the 100-card deck and are <strong>excluded</strong> from all stats and the Spellbook combo query above. Use them as upgrade/swap candidates.</p>
<h3>Sideboard ($(($sideboard | Measure-Object Qty -Sum).Sum))</h3>
$(CardTable $sideboard)
<h3>Maybeboard ($(($maybeboard | Measure-Object Qty -Sum).Sum))</h3>
$(CardTable $maybeboard)
</section>

<section id='strategy'>
<h2>Strategy & Archetype</h2>
<p>Quantitative inputs available to the strategy agent:</p>
<ul>
  <li><strong>$total cards</strong>, identity <strong>$($r.identity)</strong></li>
  <li><strong>$(($lands | Measure-Object Qty -Sum).Sum) lands</strong>, average CMC computed by the agent</li>
  <li>Ramp: $(($rocks | Measure-Object Qty -Sum).Sum) rocks + $(($dorks | Measure-Object Qty -Sum).Sum) dorks + $(($rituals | Measure-Object Qty -Sum).Sum) rituals + $(($fastmana | Measure-Object Qty -Sum).Sum) fast-mana</li>
  <li>Interaction: $(($counters | Measure-Object Qty -Sum).Sum) counters + $(($removals | Measure-Object Qty -Sum).Sum) targeted + $(($wipes | Measure-Object Qty -Sum).Sum) wipes</li>
  <li>Card advantage: $(($draws | Measure-Object Qty -Sum).Sum) draw effects</li>
  <li>Tutors: $(($tutors | Measure-Object Qty -Sum).Sum)</li>
  <li>Combos: $($includedSorted.Count) confirmed, $($almostSorted.Count) near</li>
</ul>
$(PromptBlock 'strategy' 'classify archetype, articulate the win plan in 2-3 sentences, recommend a Commander bracket (1-5) with justification')
</section>

</div>

<div class='footer'>
  Self-contained dossier — combo data from <a href='https://commanderspellbook.com'>Commander Spellbook</a>,
  deck from <a href='https://archidekt.com/decks/6845199/'>Archidekt</a>.
  Use the buttons above to copy prompts and paste into Copilot Chat with the matching <code>/mtg-*</code> command.
</div>
</div>

<script>
const deckContext = $deckListJson;
const combosContext = $combosJsonEnc;
const agentHints = {
  manabase: 'evaluate land count vs CMC, color sources per color, fixing density',
  ramp: 'evaluate ramp density, turn-1 plays, curve consistency',
  draw: 'distinguish repeatable engines from one-shot draw',
  removal: 'evaluate interaction density and coverage gaps',
  synergies: 'identify theme cohesion and off-theme cards',
  combos: 'evaluate tutor density, protection, redundancy',
  strategy: 'classify archetype, articulate the win plan, recommend bracket'
};
document.querySelectorAll('.tab').forEach(t => {
  t.addEventListener('click', () => {
    document.querySelectorAll('.tab').forEach(x => x.classList.remove('active'));
    document.querySelectorAll('.panel section').forEach(x => x.classList.remove('active'));
    t.classList.add('active');
    document.getElementById(t.dataset.tab).classList.add('active');
  });
});
function copyPrompt(agent) {
  const hint = agentHints[agent] || '';
  const text = '/mtg-' + agent + ' ' + hint + '\\n\\n' + deckContext + '\\n\\nCOMBOS:\\n' + combosContext;
  navigator.clipboard.writeText(text).then(() => {
    alert('Prompt for /mtg-' + agent + ' copied. Paste into Copilot Chat.');
  });
}
function copyDeckPrompt() {
  navigator.clipboard.writeText(deckContext + '\\n\\nCOMBOS:\\n' + combosContext).then(() => {
    alert('Deck context copied. Switch to MTG EDH Orchestrator mode and paste.');
  });
}
</script>
</body>
</html>
"@

# PromptBlock helper as a function (must be inline-string after \$html built? Actually it was referenced earlier — define before)
$html | Set-Content -Encoding UTF8 $Out
"Written: $Out ($([math]::Round((Get-Item $Out).Length / 1KB, 1)) KB)"
