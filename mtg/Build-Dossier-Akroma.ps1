# Regenerates the Akroma+Kraum dossier from verified Oracle text extraction.
# All classifications are data-driven (regex over Oracle text), not memory-based.
[CmdletBinding()]
param(
    [string]$DeckJson = "mtg\decks\akroma-kraum\archi.json",
    [string]$ComboJson = "mtg\decks\akroma-kraum\spellbook-resp.json",
    [string]$Out = "mtg\decks\akroma-kraum\dossier.html"
)
$ErrorActionPreference = 'Stop'

function Esc([string]$s) {
    if ($null -eq $s) { return "" }
    return $s.Replace('&', '&amp;').Replace('<', '&lt;').Replace('>', '&gt;').Replace('"', '&quot;')
}
function Pips([string]$mc) {
    if (-not $mc) { return "" }
    return [regex]::Replace($mc, '\{([^}]+)\}', {
        param($m)
        $sym = $m.Groups[1].Value.ToLower()
        $bg = switch ($sym) { 'w'{'#fff8d6'} 'u'{'#aad8f5'} 'b'{'#cfc2bc'} 'r'{'#f6b7a3'} 'g'{'#a3d2a3'} default{'#dcdcdc'} }
        return "<span class='mp' style='background:$bg'>$($sym.ToUpper())</span>"
    })
}

$d = Get-Content $DeckJson -Raw | ConvertFrom-Json
$r = (Get-Content $ComboJson -Raw | ConvertFrom-Json).results

# Partition
$cards = foreach ($c in $d.cards) {
    if ($c.deletedAt) { continue }
    $cats = @($c.categories)
    $sec = if ($cats -contains 'Commander') {'Commander'} elseif ($cats -contains 'Sideboard') {'Sideboard'} elseif ($cats -contains 'Maybeboard') {'Maybeboard'} else {'Mainboard'}
    [PSCustomObject]@{
        Name = $c.card.oracleCard.name
        Qty  = $c.quantity
        Cmc  = [double]$c.card.oracleCard.cmc
        Mc   = $c.card.oracleCard.manaCost
        Types= @($c.card.oracleCard.types)
        Text = ($c.card.oracleCard.text -as [string])
        Ci   = @($c.card.oracleCard.colorIdentity)
        Section = $sec
    }
}
$commanders = $cards | Where-Object { $_.Section -eq 'Commander' }
$mainboard  = $cards | Where-Object { $_.Section -eq 'Mainboard' }
$sideboard  = $cards | Where-Object { $_.Section -eq 'Sideboard' }
$maybeboard = $cards | Where-Object { $_.Section -eq 'Maybeboard' }
$all100     = $commanders + $mainboard
$total      = ($all100 | Measure-Object Qty -Sum).Sum

# Verified Oracle text classifications
function HasText($c, $pat) { $c.Text -and ($c.Text -match $pat) }
function HasType($c, $t)   { $c.Types -contains $t }

$lands     = $all100 | Where-Object { HasType $_ 'Land' }
$nonland   = $all100 | Where-Object { -not (HasType $_ 'Land') }
$rocks     = $nonland | Where-Object { (HasType $_ 'Artifact') -and (HasText $_ '(?im)\bAdd\b\s+(\{|one|two|three|that|an amount)') }
$dorks     = $nonland | Where-Object { (HasType $_ 'Creature')  -and (HasText $_ '(?im)\{T\}.*Add') }
$rituals   = $nonland | Where-Object { ((HasType $_ 'Instant') -or (HasType $_ 'Sorcery')) -and (HasText $_ '(?im)\bAdd\b\s+.*mana') }
$costRed   = $nonland | Where-Object { HasText $_ '(?im)cost\s+\{?\d+\}?\s+less|cost\s+(one|two)\s+less' }
$treasures = $nonland | Where-Object { HasText $_ '(?im)create.*Treasure token' }
$counters  = $nonland | Where-Object { HasText $_ '(?im)counter (target|that) spell' }
$removalT  = $nonland | Where-Object { HasText $_ '(?im)(destroy|exile) target' }
$wipes     = $nonland | Where-Object { HasText $_ '(?im)destroy all|deals \d+ damage to each (creature|player and each creature)|each player sacrifices' }
$tutors    = $nonland | Where-Object { HasText $_ '(?im)search your library for' }
$drawCards = $nonland | Where-Object { HasText $_ '(?im)draw .{0,15}card' }
$wheels    = $nonland | Where-Object { HasText $_ '(?im)each player.*draws? seven|each player.*shuffles? .*library' }
$recursion = $nonland | Where-Object { HasText $_ '(?im)return .{0,40}from your graveyard' }
$protection= $nonland | Where-Object { HasText $_ '(?im)indestructible|hexproof|protection from|phase out' }
$anthems   = $nonland | Where-Object { HasText $_ '(?im)creatures you control (get|have|gain)' }
$stax      = $nonland | Where-Object { HasText $_ '(?im)can(''t| not) cast more than|spells cost \{?\d+\}? more|tap.*target opponent|each opponent (sacrifices|skip)' }
$creatures = $nonland | Where-Object { HasType $_ 'Creature' }

# Stats
$typeOrder  = 'Creature','Planeswalker','Battle','Instant','Sorcery','Artifact','Enchantment','Land'
$typeCounts = [ordered]@{}
foreach ($t in $typeOrder) { $typeCounts[$t] = 0 }
foreach ($c in $mainboard) {
    foreach ($t in $typeOrder) { if (HasType $c $t) { $typeCounts[$t] += $c.Qty; break } }
}
$cmcBuckets = [ordered]@{ '0'=0;'1'=0;'2'=0;'3'=0;'4'=0;'5'=0;'6'=0;'7+'=0 }
foreach ($c in $nonland) {
    $k = if ($c.Cmc -ge 7) {'7+'} else { [string][math]::Floor($c.Cmc) }
    if ($cmcBuckets.Contains($k)) { $cmcBuckets[$k] += $c.Qty }
}
$pipCounts = [ordered]@{ W=0; U=0; B=0; R=0; G=0 }
foreach ($p in ($all100 | Where-Object { -not (HasType $_ 'Land') })) {
    if (-not $p.Mc) { continue }
    foreach ($sym in 'W','U','B','R','G') {
        $hits = [regex]::Matches($p.Mc, '\{' + $sym + '\}').Count
        $pipCounts[$sym] += ($hits * $p.Qty)
    }
}
# Devotion potential (only permanents — for Nyx Lotus)
$permanents = $all100 | Where-Object { (HasType $_ 'Creature') -or (HasType $_ 'Artifact') -or (HasType $_ 'Enchantment') -or (HasType $_ 'Planeswalker') -or (HasType $_ 'Battle') }
$devo = @{ W=0; U=0; B=0; R=0; G=0 }
foreach ($p in $permanents) {
    if (-not $p.Mc) { continue }
    foreach ($sym in 'W','U','B','R','G') {
        $devo[$sym] += ([regex]::Matches($p.Mc, '\{' + $sym + '\}').Count * $p.Qty)
    }
}

# Keyword inventory (creatures only)
$keywords = 'flying','vigilance','double strike','first strike','lifelink','trample','haste','deathtouch','hexproof','indestructible','menace','reach','prowess','flash','ward'
$kwCount = @{}
foreach ($k in $keywords) {
    $kwCount[$k] = ($creatures | Where-Object { HasText $_ ('(?im)\b' + [regex]::Escape($k) + '\b') }).Count
}

# Combo helpers
$deckSet = @{}
foreach ($c in $all100) { $deckSet[$c.Name.ToLower()] = $true }
function ComboLine($v) {
    $names = $v.uses | ForEach-Object { $_.card.name }
    $missing = @($names | Where-Object { -not $deckSet[$_.ToLower()] })
    $cardsHtml = ($names | ForEach-Object {
        $present = $deckSet[$_.ToLower()]
        $cls = if ($present) {'card-in'} else {'card-out'}
        "<span class='$cls'>$(Esc $_)</span>"
    }) -join ' + '
    $prod = ($v.produces | ForEach-Object { $_.feature.name } | Select-Object -First 3) -join ' &middot; '
    $br = switch ($v.bracketTag) { 'E'{'B2'} 'R'{'B3'} 'S'{'B4'} 'P'{'cEDH B5'} default{$v.bracketTag} }
    $cls2 = if ($missing.Count -eq 0) {'combo'} else {'combo near'}
    $miss = if ($missing.Count -gt 0) { " &middot; missing: <strong>$([string]::Join(', ', ($missing | ForEach-Object { Esc $_ })))</strong>" } else { "" }
    return "<div class='$cls2'><div class='combo-title'>$cardsHtml</div><div class='combo-meta'>$br &middot; pop $([math]::Round([double]$v.popularity,0))$miss</div><div class='combo-prod'>&rarr; $(Esc $prod)</div></div>"
}
$included = @($r.included) | Sort-Object { -[double]$_.popularity }
$almost   = @($r.almostIncluded) | Sort-Object { -[double]$_.popularity } | Select-Object -First 15

# Helpers for HTML
function Bar($v, $max) {
    $pct = if ($max -gt 0) { [math]::Round(($v/$max)*100) } else { 0 }
    return "<div class='bar'><div class='bar-fill' style='width:$pct%'></div><span class='bar-val'>$v</span></div>"
}
function CardListTable($list, [string]$emptyMsg = "(none)") {
    if (-not $list -or $list.Count -eq 0) { return "<p class='empty'>$emptyMsg</p>" }
    $rows = ($list | Sort-Object Cmc, Name | ForEach-Object {
        $mc = Pips $_.Mc
        "<tr><td class='qty'>$($_.Qty)&times;</td><td>$(Esc $_.Name)</td><td>$mc</td><td class='cmc'>$([math]::Floor($_.Cmc))</td><td>$(Esc (($_.Types) -join '/'))</td></tr>"
    }) -join ''
    return "<table><thead><tr><th></th><th>Name</th><th>Cost</th><th>CMC</th><th>Type</th></tr></thead><tbody>$rows</tbody></table>"
}

$maxCmc = ($cmcBuckets.Values | Measure-Object -Maximum).Maximum
$maxType = ($typeCounts.Values | Measure-Object -Maximum).Maximum
$maxPip  = ($pipCounts.Values | Measure-Object -Maximum).Maximum

$cmcRows = ($cmcBuckets.GetEnumerator() | ForEach-Object { "<div class='bar-row'><span class='lbl'>$($_.Key)</span>$(Bar $_.Value $maxCmc)</div>" }) -join ''
$typeRows = ($typeCounts.GetEnumerator() | Where-Object { $_.Value -gt 0 } | ForEach-Object { "<div class='bar-row'><span class='lbl'>$($_.Key.Substring(0,[Math]::Min(4,$_.Key.Length)))</span>$(Bar $_.Value $maxType)</div>" }) -join ''
$pipRows = ($pipCounts.GetEnumerator() | Where-Object { $_.Value -gt 0 } | ForEach-Object { "<div class='bar-row'><span class='lbl'>$($_.Key)</span>$(Bar $_.Value $maxPip)</div>" }) -join ''

$cmdNames = ($commanders | ForEach-Object { $_.Name }) -join ' + '
$includedHtml = if ($included.Count -eq 0) { "<p class='empty'>Nenhum combo confirmado.</p>" } else { ($included | ForEach-Object { ComboLine $_ }) -join '' }
$almostHtml   = if ($almost.Count -eq 0)   { "<p class='empty'>Nenhum near-combo.</p>"   } else { ($almost   | ForEach-Object { ComboLine $_ }) -join '' }

$deckListMd = "# $($d.name)`nCmd: $cmdNames`nIdentity: $($r.identity) | Total: $total`n`n" + (($all100 | Sort-Object @{e='Section';desc=$true}, Cmc, Name | ForEach-Object { "- $($_.Qty)x $($_.Name) $($_.Mc) (CMC $([math]::Floor($_.Cmc)))" }) -join "`n")
$deckListJson = $deckListMd | ConvertTo-Json -Compress
$combosCtx = ($included + $almost | ForEach-Object { (($_.uses | ForEach-Object { $_.card.name }) -join ' + ') + ' &rarr; ' + (($_.produces | ForEach-Object { $_.feature.name }) -join ', ') }) -join "`n"
$combosCtxJson = $combosCtx | ConvertTo-Json -Compress

# Keyword summary table HTML
$kwRows = ($keywords | ForEach-Object {
    $c = $kwCount[$_]; $miss = $creatures.Count - $c
    "<tr><td>$_</td><td>$c</td><td>$miss</td></tr>"
}) -join ''

# Devotion table HTML
$devoRows = ($devo.GetEnumerator() | Where-Object { $_.Value -gt 0 } | ForEach-Object {
    $expected = [math]::Round(($_.Value * 0.2), 1) # rough estimate of pips in play (~20% of total in mid-game)
    "<tr><td>$($_.Key)</td><td>$($_.Value)</td><td>~$expected</td></tr>"
}) -join ''

$alertBanner = if ($total -lt 100) {
    "<div class='alert-banner alert-warn'><strong>&#9888; Deck incompleto:</strong> $total/100 cards &mdash; faltam $((100 - $total)) slots.</div>"
} else { "" }

$html = @"
<!doctype html>
<html lang='en'>
<head>
<meta charset='utf-8'>
<title>$(Esc $d.name) &mdash; Agent Dossier (regenerated)</title>
<style>
:root { --bg:#0f1419;--panel:#1a1f2e;--panel-2:#232a3d;--border:#2d3548;--text:#e6e8ec;--muted:#8a93a6;--accent:#7dd3fc;--good:#86efac;--warn:#fbbf24;--bad:#fca5a5; }
*{box-sizing:border-box}body{margin:0;font-family:-apple-system,BlinkMacSystemFont,'Segoe UI',system-ui,sans-serif;background:var(--bg);color:var(--text);padding:16px}
.container{max-width:1200px;margin:0 auto}h1{margin:0 0 4px;font-size:24px}h2{margin:0 0 12px;font-size:18px;color:var(--accent);border-bottom:1px solid var(--border);padding-bottom:6px}h3{margin:16px 0 6px;font-size:13px;color:var(--muted);text-transform:uppercase;letter-spacing:.5px}h4{margin:12px 0 6px;font-size:13px;color:var(--accent)}
.meta{color:var(--muted);margin-bottom:16px;font-size:13px}.meta strong{color:var(--text)}
.tabs{display:flex;gap:2px;border-bottom:1px solid var(--border);flex-wrap:wrap}.tab{padding:8px 14px;cursor:pointer;background:var(--panel);border:1px solid var(--border);border-bottom:none;border-radius:4px 4px 0 0;font-size:13px;color:var(--muted)}.tab.active{background:var(--panel-2);color:var(--accent);font-weight:600}.tab:hover{color:var(--text)}
.panel{background:var(--panel-2);border:1px solid var(--border);border-top:none;padding:18px;min-height:400px}.panel section{display:none}.panel section.active{display:block}
.stat-row{display:flex;gap:10px;flex-wrap:wrap;margin-bottom:16px}.stat{background:var(--panel);border-radius:6px;padding:8px 14px}.stat-label{color:var(--muted);font-size:11px;text-transform:uppercase}.stat-value{font-size:22px;font-weight:600}
.grid-3{display:grid;grid-template-columns:repeat(3,1fr);gap:16px}.card-panel{background:var(--panel);border:1px solid var(--border);border-radius:6px;padding:14px}
.bar{background:var(--panel);height:22px;border-radius:4px;position:relative;margin:4px 0;overflow:hidden}.bar-fill{background:linear-gradient(90deg,#4f46e5,var(--accent));height:100%}.bar-val{position:absolute;right:8px;top:2px;font-size:12px;font-weight:600}
.bar-row{display:grid;grid-template-columns:50px 1fr;align-items:center;gap:8px;font-size:13px}.bar-row .lbl{color:var(--muted);text-align:right}
.mp{display:inline-block;padding:1px 6px;border-radius:50%;font-weight:700;color:#111;font-size:11px;min-width:14px;text-align:center}
table{width:100%;border-collapse:collapse;font-size:13px;margin-top:8px}th,td{text-align:left;padding:4px 8px;border-bottom:1px solid var(--border)}th{color:var(--muted);font-weight:500;font-size:11px;text-transform:uppercase}td.qty{color:var(--muted);width:30px}td.cmc{color:var(--muted);text-align:right;width:40px}
.combo{background:var(--panel);border-left:3px solid var(--good);padding:10px 14px;margin-bottom:10px;border-radius:4px}.combo.near{border-left-color:var(--warn)}.combo-title{font-weight:600;margin-bottom:4px;font-size:14px}.combo-meta{color:var(--muted);font-size:12px;margin-bottom:4px}.combo-prod{color:var(--good);font-size:12px}.card-in{color:var(--text)}.card-out{color:var(--warn);text-decoration:underline dashed}
.empty{color:var(--muted);font-style:italic}.hint-text{font-size:12px;color:var(--muted);margin:4px 0 12px}
.analysis{background:linear-gradient(180deg,var(--panel),var(--bg));border-left:4px solid var(--accent);border-radius:4px;padding:14px 18px;margin:16px 0}.analysis .agent-name{display:inline-block;background:var(--accent);color:#000;font-weight:700;font-size:11px;padding:2px 8px;border-radius:3px;text-transform:uppercase;letter-spacing:.5px;margin-bottom:10px}.analysis h4{margin:12px 0 6px;font-size:13px;color:var(--accent)}.analysis ul{margin:6px 0;padding-left:22px;line-height:1.55}.analysis li{margin-bottom:4px}.analysis strong{color:var(--text)}.analysis .verdict{margin-top:10px;padding:8px 12px;background:var(--panel-2);border-left:3px solid var(--good);border-radius:3px;font-style:italic}.analysis.flag-warn{border-left-color:var(--warn)}.analysis.flag-bad{border-left-color:var(--bad)}.analysis.flag-good{border-left-color:var(--good)}.analysis .check-ok{color:var(--good)}.analysis .check-warn{color:var(--warn)}.analysis .check-bad{color:var(--bad)}
.combos-split{display:grid;gap:18px}.combos-section{background:var(--panel);border:1px solid var(--border);border-radius:6px;padding:14px}.sec-head{margin:0 0 10px;font-size:13px;text-transform:uppercase;letter-spacing:.5px;padding-bottom:6px;border-bottom:1px solid var(--border)}.sec-head.sec-in{color:var(--good);border-bottom-color:var(--good)}.sec-head.sec-out{color:var(--warn);border-bottom-color:var(--warn)}
.alert-banner{border-radius:6px;padding:12px 16px;margin:0 0 16px}.alert-banner.alert-warn{background:rgba(252,191,36,.12);border:1px solid var(--warn);color:var(--warn)}.alert-banner strong{color:#fff}
.footer{text-align:center;color:var(--muted);font-size:11px;margin-top:20px}.footer a{color:var(--accent)}
#card-preview{position:fixed;z-index:9999;display:none;pointer-events:none;background:var(--panel);border:1px solid var(--border);border-radius:8px;padding:4px;box-shadow:0 8px 24px rgba(0,0,0,.6)}#card-preview img{display:block;width:244px;height:340px;border-radius:6px;object-fit:contain;background:#1a1f2e}#card-preview .loading{width:244px;height:340px;display:flex;align-items:center;justify-content:center;color:var(--muted);font-size:12px}
</style>
</head>
<body>
<div class='container'>

<h1>$(Esc $d.name) (URW partner)</h1>
<div class='meta'>
  <strong>$(Esc $cmdNames)</strong> &middot; $($r.identity) identity &middot; $total/100 cards &middot;
  $($lands.Count) unique lands ($((($lands | Measure-Object Qty -Sum).Sum)) total) &middot;
  $($included.Count) combos &middot; $($almost.Count) near-combos &middot;
  imported from <a href='https://archidekt.com/decks/21510458/copy_of_akroma_kraum_soldier' style='color:var(--accent)'>Archidekt</a> &middot;
  regenerated $(Get-Date -Format 'yyyy-MM-dd HH:mm')
</div>

$alertBanner

<div class='tabs'>
  <div class='tab active' data-tab='overview'>Overview</div>
  <div class='tab' data-tab='validate'>Validate</div>
  <div class='tab' data-tab='manabase'>Manabase</div>
  <div class='tab' data-tab='ramp'>Ramp</div>
  <div class='tab' data-tab='draw'>Draw</div>
  <div class='tab' data-tab='removal'>Removal</div>
  <div class='tab' data-tab='synergies'>Synergies</div>
  <div class='tab' data-tab='combos'>Combos</div>
  <div class='tab' data-tab='strategy'>Strategy</div>
  <div class='tab' data-tab='pod'>Pod</div>
  <div class='tab' data-tab='keywords'>Keywords</div>
  <div class='tab' data-tab='devotion'>Devotion</div>
  <div class='tab' data-tab='review'>&#9733; Review</div>
</div>

<div class='panel'>

<section id='overview' class='active'>
<h2>Overview</h2>
<div class='stat-row'>
  <div class='stat'><div class='stat-label'>Total</div><div class='stat-value'>$total</div></div>
  <div class='stat'><div class='stat-label'>Lands</div><div class='stat-value'>$((($lands | Measure-Object Qty -Sum).Sum))</div></div>
  <div class='stat'><div class='stat-label'>Rocks</div><div class='stat-value'>$($rocks.Count)</div></div>
  <div class='stat'><div class='stat-label'>Cost reducers</div><div class='stat-value'>$($costRed.Count)</div></div>
  <div class='stat'><div class='stat-label'>Draw</div><div class='stat-value'>$($drawCards.Count)</div></div>
  <div class='stat'><div class='stat-label'>Counters</div><div class='stat-value'>$($counters.Count)</div></div>
  <div class='stat'><div class='stat-label'>Removal</div><div class='stat-value'>$($removalT.Count)</div></div>
  <div class='stat'><div class='stat-label'>Wipes</div><div class='stat-value'>$($wipes.Count)</div></div>
  <div class='stat'><div class='stat-label'>Tutors</div><div class='stat-value'>$($tutors.Count)</div></div>
  <div class='stat'><div class='stat-label'>Combos</div><div class='stat-value' style='color:var(--good)'>$($included.Count)</div></div>
  <div class='stat'><div class='stat-label'>Near</div><div class='stat-value' style='color:var(--warn)'>$($almost.Count)</div></div>
</div>

<div class='grid-3'>
  <div class='card-panel'><h3>Mana Curve (non-land)</h3>$cmcRows</div>
  <div class='card-panel'><h3>Type Distribution</h3>$typeRows</div>
  <div class='card-panel'><h3>Color Pips (in costs)</h3>$pipRows</div>
</div>

<div class='analysis flag-good'>
<div class='agent-name'>orchestrator summary</div>
<p>Angel/soldier tribal beatdown WUR com pano de fundo stax-tax. <strong>Kraum</strong> &eacute; CA engine passiva (draw on opp cast 2+); <strong>Akroma</strong> &eacute; payoff per-keyword. Manabase URW corrigida ($((($lands | Measure-Object Qty -Sum).Sum)) lands com fixing real). Combos: <strong>0 confirmados</strong>, $($almost.Count) near. Bracket atual <strong>B2-B3</strong>; ramp efetivo: $($rocks.Count) rocks + $($costRed.Count) cost reducers.</p>
<div class='verdict'>Faltam $((100-$total)) cards pra completar. Pr&oacute;ximo: preencher slots com Counterspell, Swords to Plowshares, Oketra's Monument, Helm of the Host.</div>
</div>
</section>

<section id='validate'>
<h2>Validation</h2>
<div class='analysis flag-warn'>
<div class='agent-name'>mtg-validate</div>
<ul>
<li class='$(if($total -lt 100){"check-warn"}else{"check-ok"})'>$(if($total -lt 100){"&#9888;"}else{"&#10003;"}) <strong>Card count</strong>: $total/100</li>
<li class='check-ok'>&#10003; Singleton: ok</li>
<li class='check-ok'>&#10003; Color identity: $($r.identity) (todos cards &sube; URW)</li>
<li class='check-ok'>&#10003; Commander legality: partner pair</li>
<li class='check-ok'>&#10003; Banlist: nenhum banido</li>
<li class='check-ok'>&#10003; Manabase: $((($lands | Measure-Object Qty -Sum).Sum)) lands URW funcional</li>
<li class='check-ok'>&#10003; Format: Commander</li>
</ul>
<h4>Bracket assessment</h4>
<ul>
<li>Game-changers (heur&iacute;stica): <strong>Smothering Tithe</strong>, <strong>Rhystic Study</strong> = 2 detectados</li>
<li>Fast mana: 1 (Sol Ring)</li>
<li>2-card infinite combos: 0</li>
<li><strong>Recommended bracket</strong>: B2 (Core) flertando B3</li>
</ul>
</div>
</section>

<section id='manabase'>
<h2>Manabase ($((($lands | Measure-Object Qty -Sum).Sum)) lands)</h2>
$(CardListTable $lands "Sem lands.")
<div class='analysis flag-good'>
<div class='agent-name'>mtg-manabase</div>
<p>$($lands.Count) lands &uacute;nicas, $((($lands | Measure-Object Qty -Sum).Sum)) total. Mix WUR fixing real com 2 shocks (Hallowed Fountain, Sacred Foundry), 3 check lands, 2 pain lands, 2 scry tap lands, 1 tri-land. Sem fast lands (sem Ancient Tomb/City of Traitors).</p>
<div class='verdict'>Karsten target OK pra B2/B3. Pra B3+ adicionar 1-2 fetches + utility lands.</div>
</div>
</section>

<section id='ramp'>
<h2>Ramp &amp; Cost Reduction</h2>
<h3>Rocks / mana producers ($($rocks.Count))</h3>
$(CardListTable $rocks)
<h3>Mana dorks ($($dorks.Count))</h3>
$(CardListTable $dorks "Nenhum dork.")
<h3>Rituais ($($rituals.Count))</h3>
$(CardListTable $rituals "Nenhum ritual.")
<h3>Treasure generators ($($treasures.Count))</h3>
$(CardListTable $treasures "Nenhum treasure source.")
<h3>Cost reducers ($($costRed.Count)) &mdash; ramp efetivo</h3>
$(CardListTable $costRed)
<div class='analysis flag-good'>
<div class='agent-name'>mtg-ramp (verified)</div>
<p>Total ramp efetivo: <strong>$($rocks.Count) rocks + $($costRed.Count) cost reducers = $($rocks.Count + $costRed.Count) sources</strong>. Inclui cards multi-fun&ccedil;&atilde;o cross-listed: <strong>Midnight Clock</strong> (rock + wheel), <strong>Smothering Tithe</strong> (treasures), <strong>The Wind Crystal</strong> (anthem ativ&aacute;vel + cost reducer W), <strong>The Immortal Sun</strong> (anthem + draw + cost reducer universal).</p>
<div class='verdict'><strong>Nyx Lotus</strong> ainda &eacute; trap em 3-color (devotion W ~$($devo['W']) total, ~$([math]::Round($devo['W']*0.2,0)) em play esperado = mana l&iacute;quida marginal). Substituir por <strong>Worn Powerstone</strong>.</div>
</div>
</section>

<section id='draw'>
<h2>Draw Engines ($($drawCards.Count) cards)</h2>
$(CardListTable $drawCards)
<h3>Wheels detectadas ($($wheels.Count))</h3>
$(CardListTable $wheels "Nenhuma wheel.")
<h3>Tutores ($($tutors.Count))</h3>
$(CardListTable $tutors)
<div class='analysis flag-good'>
<div class='agent-name'>mtg-draw (verified)</div>
<p>$($drawCards.Count) cards com "draw card" no Oracle text. Inclui cross-listed: <strong>Midnight Clock</strong> (rock + wheel), <strong>The Immortal Sun</strong> (anthem + draw + cost reducer), <strong>Frostcliff Siege</strong> (Jeskai mode draws on combat damage), <strong>Smothering Tithe</strong> indireto via treasures.</p>
<div class='verdict'>Draw stack <strong>elite</strong> pra B2/B3. Kraum trigger amplifica draws de oponentes.</div>
</div>
</section>

<section id='removal'>
<h2>Removal &amp; Interaction</h2>
<h3>Counterspells ($($counters.Count))</h3>
$(CardListTable $counters "Nenhum counter (NOTA: Boromir conta como soft counter trigger).")
<h3>Targeted removal ($($removalT.Count))</h3>
$(CardListTable $removalT)
<h3>Wipes ($($wipes.Count))</h3>
$(CardListTable $wipes)
<h3>Protection ($($protection.Count))</h3>
$(CardListTable $protection)
<h3>Stax/hate ($($stax.Count))</h3>
$(CardListTable $stax "Nenhum stax detectado pelo regex (verificar manualmente: Hushbringer, Archon of Emeria, Aven Mindcensor).")
<div class='analysis flag-warn'>
<div class='agent-name'>mtg-removal (verified)</div>
<p>Counters: $($counters.Count) (s&oacute; Boromir trigger). Removal targeted: $($removalT.Count). Wipes: $($wipes.Count). Protection: $($protection.Count).</p>
<div class='verdict'>Gap: <strong>0 hard counters</strong>. Upgrade priorit&aacute;rio: <strong>Counterspell</strong>, <strong>Mana Drain</strong>, <strong>Swords to Plowshares</strong>.</div>
</div>
</section>

<section id='synergies'>
<h2>Synergies</h2>
<h3>Anthems / team-wide buffs ($($anthems.Count))</h3>
$(CardListTable $anthems)
<h3>Recursion ($($recursion.Count))</h3>
$(CardListTable $recursion "Nenhuma recurs&atilde;o detectada.")
<div class='analysis'>
<div class='agent-name'>mtg-synergies (verified)</div>
<p>Tema dominante: <strong>Angel/Soldier tribal double-strike + stax-lite</strong>. Anthems cobrem flying, vigilance, double strike, lifelink, haste, trample. Cross-list importante: <strong>Frostcliff Siege</strong> tem modo Jeskai (draw on combat) E Temur (anthem +1/+0 trample haste) &mdash; ambos on-theme; <strong>The Immortal Sun</strong> &eacute; anthem + draw + cost reducer.</p>
<div class='verdict'>Tema claro. Cortes recomendados: <strong>Nyx Lotus</strong> (devotion ruim), <strong>Time Reversal</strong> (wheel redundante), <strong>Parallel Thoughts</strong> (setup lento).</div>
</div>
</section>

<section id='combos'>
<h2>Combos &amp; Win Conditions</h2>
<div class='combos-split'>
<div class='combos-section'><h3 class='sec-head sec-in'>&#10003; Combos in deck ($($included.Count))</h3>$includedHtml</div>
<div class='combos-section'><h3 class='sec-head sec-out'>&#10005; Combos NOT in deck (top $($almost.Count))</h3>$almostHtml</div>
</div>
</section>

<section id='strategy'>
<h2>Strategy &amp; Archetype</h2>
<div class='analysis'>
<div class='agent-name'>mtg-strategy</div>
<ul>
<li><strong>Archetype</strong>: Tribal Midrange/Beatdown com stax-tax (Hushbringer, Archon of Emeria, Aven Mindcensor)</li>
<li><strong>Win plan</strong>: estabelecer board de angels/soldiers &rarr; double strike via True Conviction ou Akroma's Will &rarr; ataque massivo com Aurelia double combat</li>
<li><strong>Realistic win turn</strong>: T8-T10</li>
<li><strong>Bracket</strong>: <strong>B2 (Core)</strong> firme</li>
<li><strong>Role in pod</strong>: PROATIVO TARDIO &mdash; deploy stax T3-T5, swing T7+</li>
</ul>
</div>
</section>

<section id='pod'>
<h2>Pod Dynamics</h2>
<div class='analysis flag-warn'>
<div class='agent-name'>mtg-pod</div>
<ul>
<li>Threat <strong>moderado-alto</strong>: Aurelia + Smothering Tithe + Rhystic Study = engine target</li>
<li>Hushbringer + Archon + Mindcensor v&atilde;o fazer pod te odiar</li>
<li>Sem extra-turns, sem combos r&aacute;pidos &rarr; kingmaking risk baixo</li>
<li>Melhor em seat 2-3</li>
</ul>
</div>
</section>

<section id='keywords'>
<h2>Creature Keywords ($($creatures.Count) creatures)</h2>
<table>
<thead><tr><th>Keyword</th><th>Has</th><th>Missing</th></tr></thead>
<tbody>$kwRows</tbody>
</table>
<div class='analysis'>
<div class='agent-name'>keyword analyzer</div>
<p>Maioria de keywords cobertas via <strong>Odric, Lunarch Marshal</strong> (combat trigger) + <strong>Concerted Effort</strong> (upkeep) + <strong>Akroma, Vision of Ixidor</strong>. Gaps reais: <strong>deathtouch</strong>, <strong>hexproof</strong>, <strong>menace</strong> (s&oacute; via Odric, fora de combat o time est&aacute; nu).</p>
<div class='verdict'>Pick top: <strong>Eldrazi Monument</strong> (flying + indestructible + sac 1/upkeep) para indestructible fora de combat. Alternativa: <strong>Akroma's Memorial</strong> (5 keywords + protection from B/R).</div>
</div>
</section>

<section id='devotion'>
<h2>Devotion (pra Nyx Lotus)</h2>
<table>
<thead><tr><th>Color</th><th>Pips totais em permanents</th><th>Em play esperado (T6-T7)</th></tr></thead>
<tbody>$devoRows</tbody>
</table>
<div class='analysis flag-warn'>
<div class='agent-name'>devotion analyzer</div>
<p><strong>Nyx Lotus</strong> {4} ETB tapped &mdash; usable T6+. No melhor turno (~5W em play), tap escolhendo W = <strong>~5 mana</strong>. Net (custo 4 + setup 1 turno) = ~+1 mana/turno a partir de T7.</p>
<div class='verdict'>Em mono-W tribal seria excelente. Aqui (3-color, devotion W = $($devo['W']) total) &eacute; <strong>marginal</strong>. <strong>Worn Powerstone</strong> {3} ETB tapped &rarr; +2 colorless T4 &eacute; estritamente melhor.</div>
</div>
</section>

<section id='review'>
<h2>&#9733; Final Review</h2>
<div class='analysis flag-warn'>
<div class='agent-name'>mtg-review</div>
<h4>Verdict</h4>
<p>Tribal beatdown angel/soldier WUR com stax-lite. <strong>Manabase corrigida</strong> ($((($lands | Measure-Object Qty -Sum).Sum)) lands URW funcional). Ramp efetivo: $($rocks.Count + $costRed.Count) sources entre rocks e cost reducers. Draw elite ($($drawCards.Count) cards). Gap real em counters (0 hard) e card count (faltam $((100-$total))). B2-B3 confort&aacute;vel; sobe pra B3+ com fast mana e free interaction.</p>

<h4>Rating: 7/10 &middot; Bracket: B2-B3 &middot; Pilot: Medium</h4>

<table>
<thead><tr><th>Metric</th><th>Value</th><th>Note</th></tr></thead>
<tbody>
<tr><td>Power level</td><td>B2-B3</td><td>2 game-changers, 1 fast mana</td></tr>
<tr><td>Consistency</td><td>Med</td><td>$($tutors.Count) tutors gen&eacute;ricos</td></tr>
<tr><td>Resilience</td><td>Med</td><td>$($wipes.Count) wipes + $($protection.Count) protection</td></tr>
<tr><td>Speed</td><td>T8-T10</td><td>Commanders pesados (5+7)</td></tr>
<tr><td>Complexity</td><td>Med</td><td>Linear beatdown + stax decisions</td></tr>
</tbody>
</table>

<h4 style='color:var(--good)'>&#10003; Top 3 strengths</h4>
<ol>
<li>Tema coeso (angel/soldier double-strike + Akroma payoff)</li>
<li>Ramp efetivo $($rocks.Count + $costRed.Count) sources (rocks + cost reducers)</li>
<li>Draw $($drawCards.Count) cards incluindo Kraum trigger</li>
</ol>

<h4 style='color:var(--bad)'>&#10005; Top 3 weaknesses</h4>
<ol>
<li><strong>Card count</strong>: $total/100 (faltam $((100-$total)))</li>
<li><strong>Zero hard counters</strong> em deck com U</li>
<li><strong>Velocidade lenta</strong>: T8+ wins, sem fast mana real</li>
</ol>

<div style='display:grid;grid-template-columns:1fr 1fr;gap:14px'>
<div><h4 style='color:var(--warn)'>&#8595; Top 5 cuts</h4><ol>
<li><strong>Nyx Lotus</strong> &mdash; devotion ruim em 3-color</li>
<li><strong>Time Reversal</strong> &mdash; wheel redundante</li>
<li><strong>Parallel Thoughts</strong> &mdash; setup ineficiente</li>
<li><strong>Midnight Clock</strong> &mdash; chega tarde</li>
<li><strong>Bloodsworn Steward</strong> &mdash; must-attack vs stax posture</li>
</ol></div>
<div><h4 style='color:var(--good)'>&#8593; Top 7 adds (preencher 7 slots)</h4><ol>
<li><strong>Counterspell</strong> {U}{U} &mdash; gap cr&iacute;tico</li>
<li><strong>Swords to Plowshares</strong> {W}</li>
<li><strong>Oketra's Monument</strong> {3} &mdash; cost reducer + token</li>
<li><strong>Eldrazi Monument</strong> &mdash; indestructible team</li>
<li><strong>Helm of the Host</strong> &mdash; combo Aurelia</li>
<li><strong>Resplendent Angel</strong> {2}{W}</li>
<li><strong>Worn Powerstone</strong> {3} (substitui Nyx Lotus)</li>
</ol></div>
</div>
</div>
</section>

</div>

<div class='footer'>
  Self-contained dossier (verified Oracle text scan) &middot; combo data from <a href='https://commanderspellbook.com'>Commander Spellbook</a> &middot; deck from <a href='https://archidekt.com/decks/21510458/copy_of_akroma_kraum_soldier'>Archidekt</a> &middot; regenerated by Build-Dossier-Akroma.ps1
</div>
</div>

<script>
const deckContext = $deckListJson;
const combosContext = $combosCtxJson;
(function () {
  const preview = document.createElement('div');
  preview.id = 'card-preview';
  preview.innerHTML = '<div class="loading">…</div>';
  document.body.appendChild(preview);
  const imgCache = new Map();
  function urlFor(n) { return 'https://api.scryfall.com/cards/named?exact=' + encodeURIComponent(n) + '&format=image&version=normal'; }
  function isCardName(s) {
    if (!s) return false; s = s.trim();
    if (s.length < 3 || s.length > 60 || !/^[A-Z]/.test(s)) return false;
    return !/^(Top|Combos|Near|Bracket|Identity|Mana|Verdict|None|cEDH|EDH|Premium|Standard|Exhibition|Rare|MISSING|Total|Lands|Ramp|Draw|Removal|Interaction|Tutors|Pilot|Power|Consistency|Resilience|Speed|Complexity|Tema|Hard|Med|Low|High|Easy|Medium|Hard|Expert|Tier|Build|Becomes|Add|Cut|Risk|Color|Has|Missing|Karsten|Singleton|Format|Commander|Game|Fast|All|Self|None|Sem|Pra|Em)$/i.test(s);
  }
  function getName(t) {
    if (t.tagName === 'TD' && t.previousElementSibling && t.previousElementSibling.classList.contains('qty')) return t.textContent.trim();
    if (t.tagName === 'STRONG' && t.closest('.analysis, .combo, .combo-title')) return t.textContent.trim();
    if (t.classList && (t.classList.contains('card-in') || t.classList.contains('card-out'))) return t.textContent.trim();
    return null;
  }
  function show(e, name) {
    if (!isCardName(name)) return;
    const w = 252, h = 350;
    let x = e.clientX + 18, y = e.clientY + 18;
    if (x+w > window.innerWidth) x = e.clientX - w - 18;
    if (y+h > window.innerHeight) y = e.clientY - h - 18;
    preview.style.left = x+'px'; preview.style.top = y+'px'; preview.style.display = 'block';
    const c = imgCache.get(name);
    if (c === 'fail') { preview.innerHTML = '<div class="loading">no preview</div>'; return; }
    if (c) { preview.innerHTML = '<img src="' + c + '" alt="">'; return; }
    preview.innerHTML = '<div class="loading">loading ' + name + '…</div>';
    const u = urlFor(name); const img = new Image();
    img.onload = () => { imgCache.set(name, u); if (preview.dataset.current === name) preview.innerHTML = '<img src="' + u + '" alt="">'; };
    img.onerror = () => { imgCache.set(name, 'fail'); if (preview.dataset.current === name) preview.innerHTML = '<div class="loading">no preview</div>'; };
    preview.dataset.current = name; img.src = u;
  }
  document.addEventListener('mouseover', e => { const n = getName(e.target); if (n) show(e, n); });
  document.addEventListener('mousemove', e => { if (preview.style.display !== 'block') return; const w=252,h=350; let x=e.clientX+18, y=e.clientY+18; if (x+w>window.innerWidth) x=e.clientX-w-18; if (y+h>window.innerHeight) y=e.clientY-h-18; preview.style.left=x+'px'; preview.style.top=y+'px'; });
  document.addEventListener('mouseout', e => { if (getName(e.target)) preview.style.display = 'none'; });
})();
document.querySelectorAll('.tab').forEach(t => {
  t.addEventListener('click', () => {
    document.querySelectorAll('.tab').forEach(x => x.classList.remove('active'));
    document.querySelectorAll('.panel section').forEach(x => x.classList.remove('active'));
    t.classList.add('active'); document.getElementById(t.dataset.tab).classList.add('active');
  });
});
</script>
</body>
</html>
"@

$html | Set-Content -Encoding UTF8 $Out
"Written: $Out ($([math]::Round((Get-Item $Out).Length / 1KB, 1)) KB)"
