# ============================================================================
# RELATÓRIOS - Copilot + Entra ID  |  Login Interativo
# Requer: conta com Reports.Read.All + AuditLog.Read.All (Admin ou delegado)
# ============================================================================

Write-Host ""
Write-Host "╔══════════════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
Write-Host "║  EXTRAÇÃO DE RELATÓRIOS  -  Copilot  +  Entra ID                ║" -ForegroundColor Cyan
Write-Host "║  Login interativo: um navegador será aberto para autenticação    ║" -ForegroundColor Cyan
Write-Host "╚══════════════════════════════════════════════════════════════════╝" -ForegroundColor Cyan
Write-Host ""

# ============================================================================
# 1. AUTENTICAÇÃO
# ============================================================================
Write-Host "🔐 Iniciando autenticação..." -ForegroundColor Blue
Write-Host "   (O navegador será aberto — faça login com uma conta admin do M365)" -ForegroundColor Gray
Write-Host ""

try {
    Connect-MgGraph `
        -Scopes "Reports.Read.All", "AuditLog.Read.All", "UserAuthenticationMethod.Read.All" `
        -NoWelcome | Out-Null

    $ctx = Get-MgContext
    Write-Host "✅ Autenticado como: $($ctx.Account)" -ForegroundColor Green
    Write-Host "   Tenant: $($ctx.TenantId)" -ForegroundColor Gray
    Write-Host ""
} catch {
    Write-Host "❌ Falha na autenticação: $_" -ForegroundColor Red
    exit 1
}

# ============================================================================
# 2. PASTA DE SAÍDA
# ============================================================================
$exportFolder = Join-Path $PSScriptRoot "Export"
if (-not (Test-Path $exportFolder)) {
    New-Item -ItemType Directory -Path $exportFolder | Out-Null
    Write-Host "📁 Pasta criada: $exportFolder" -ForegroundColor Gray
    Write-Host ""
}

# ============================================================================
# 3. DEFINIÇÃO DOS RELATÓRIOS
#    Tipo "csv"  → endpoint retorna CSV diretamente   (OutputFilePath)
#    Tipo "json" → endpoint retorna JSON/paginado     (convertido para CSV)
# ============================================================================
$reports = @(

    # ── COPILOT ─────────────────────────────────────────────────────────────
    # NOTA: Requer licenças Microsoft 365 Copilot no tenant.
    # Endpoints testados: https://learn.microsoft.com/graph/api/resources/copilot-usage-reports
    @{
        Name = "Copilot_UsageUserDetail"
        Uri  = "https://graph.microsoft.com/beta/reports/getMicrosoft365CopilotUsageUserDetail(period='D30')"
        Type = "csv"
    },
    @{
        Name = "Copilot_UserCountSummary"
        Uri  = "https://graph.microsoft.com/beta/reports/getMicrosoft365CopilotUserCountSummary(period='D30')"
        Type = "json"
    },
    @{
        Name = "Copilot_UserCountTrend"
        Uri  = "https://graph.microsoft.com/beta/reports/getMicrosoft365CopilotUserCountTrend(period='D30')"
        Type = "csv"
    },

    # ── ENTRA ID – AUTENTICAÇÃO / MFA / SSPR ────────────────────────────────
    @{
        # Detalhes de registro MFA/SSPR por usuário
        Name = "EntraID_UserRegistrationDetails"
        Uri  = "https://graph.microsoft.com/v1.0/reports/authenticationMethods/userRegistrationDetails"
        Type = "json"
    },
    @{
        # Contagem de usuários registrados por funcionalidade (MFA, SSPR, etc.)
        Name = "EntraID_UsersRegisteredByFeature"
        Uri  = "https://graph.microsoft.com/v1.0/reports/authenticationMethods/usersRegisteredByFeature"
        Type = "json"
    },
    @{
        # Contagem de usuários registrados por método (Authenticator, TOTP, etc.)
        Name = "EntraID_UsersRegisteredByMethod"
        Uri  = "https://graph.microsoft.com/v1.0/reports/authenticationMethods/usersRegisteredByMethod"
        Type = "json"
    }
)

# ============================================================================
# 4. FUNÇÕES AUXILIARES
# ============================================================================

# Baixar endpoint paginado e retornar todos os registros
function Get-GraphPagedData {
    param ([string]$Uri)
    $all   = @()
    $next  = $Uri
    while ($next) {
        $resp = Invoke-MgGraphRequest -Method GET -Uri $next -ErrorAction Stop
        if ($resp.ContainsKey("value")) { $all += $resp.value }
        else                            { $all += $resp }
        $next = $resp.'@odata.nextLink'
    }
    return $all
}

# Converter array de objetos para CSV sem travar em tipos complexos
function Export-ToCsv {
    param ($Data, [string]$Path)

    if ($Data.Count -eq 0) {
        "Sem dados" | Set-Content -Path $Path -Encoding UTF8
        return
    }

    $flat = $Data | ForEach-Object {
        $row = [ordered]@{}
        foreach ($prop in $_.PSObject.Properties) {
            $val = $prop.Value
            if ($val -is [System.Collections.IEnumerable] -and $val -isnot [string]) {
                $row[$prop.Name] = ($val | ForEach-Object { $_.ToString() }) -join "; "
            } elseif ($val -is [hashtable] -or $val -is [PSCustomObject]) {
                $row[$prop.Name] = ($val | ConvertTo-Json -Compress)
            } else {
                $row[$prop.Name] = $val
            }
        }
        [PSCustomObject]$row
    }

    $flat | Export-Csv -Path $Path -NoTypeInformation -Encoding UTF8BOM -Delimiter ','
}

# ============================================================================
# 5. EXTRAÇÃO
# ============================================================================
Write-Host "┌──────────────────────────────────────────────────────────────────┐" -ForegroundColor Cyan
Write-Host "│  Iniciando exportação  (período D30 = últimos 30 dias)           │" -ForegroundColor Cyan
Write-Host "└──────────────────────────────────────────────────────────────────┘" -ForegroundColor Cyan
Write-Host ""

$successCount = 0
$failureCount = 0
$failureList  = @()

foreach ($report in $reports) {
    $outPath = Join-Path $exportFolder "$($report.Name).csv"
    Write-Host "⏳ $($report.Name)..." -ForegroundColor Blue -NoNewline

    try {
        if ($report.Type -eq "csv") {
            Invoke-MgGraphRequest `
                -Method GET `
                -Uri $report.Uri `
                -OutputFilePath $outPath `
                -ErrorAction Stop | Out-Null
        } else {
            $data = Get-GraphPagedData -Uri $report.Uri
            Export-ToCsv -Data $data -Path $outPath
        }

        $size = (Get-Item $outPath -ErrorAction SilentlyContinue).Length
        if ($size -gt 0) {
            Write-Host " ✅  ($size bytes)" -ForegroundColor Green
        } else {
            Write-Host " ⚠️  (arquivo vazio — sem dados no período)" -ForegroundColor Yellow
        }
        $successCount++

    } catch {
        $errMsg = $_.Exception.Message
        Write-Host " ❌" -ForegroundColor Red

        # Diagnóstico específico por tipo de erro
        if ($errMsg -like "*BadRequest*" -and $report.Name -like "Copilot*") {
            Write-Host "   ⚠️  Copilot for M365 não está habilitado/licenciado neste tenant." -ForegroundColor Yellow
        } elseif ($errMsg -like "*Forbidden*" -or $errMsg -like "*403*") {
            Write-Host "   ⚠️  Sem permissão. Consulte RESOLVE_403_ERROR.md." -ForegroundColor Yellow
        } elseif ($errMsg -like "*BadRequest*") {
            Write-Host "   ⚠️  Endpoint não disponível neste tenant: $errMsg" -ForegroundColor Yellow
        } else {
            Write-Host "   Erro: $errMsg" -ForegroundColor DarkRed
        }

        $failureCount++
        $failureList += "$($report.Name) → $errMsg"
    }
}

# ============================================================================
# 6. RESUMO
# ============================================================================
Write-Host ""
Write-Host "┌──────────────────────────────────────────────────────────────────┐" -ForegroundColor Cyan
Write-Host "│  RESUMO                                                          │" -ForegroundColor Cyan
Write-Host "└──────────────────────────────────────────────────────────────────┘" -ForegroundColor Cyan
Write-Host "✅ Sucesso : $successCount relatório(s)" -ForegroundColor Green
Write-Host "❌ Falha   : $failureCount relatório(s)" -ForegroundColor $(if ($failureCount -gt 0) { "Red" } else { "Green" })

if ($failureList.Count -gt 0) {
    Write-Host ""
    Write-Host "Detalhes das falhas:" -ForegroundColor Yellow
    $failureList | ForEach-Object { Write-Host "  • $_" -ForegroundColor DarkYellow }
    Write-Host ""
    Write-Host "💡 Dica: Erro 403 = conta sem permissão admin para Reports.Read.All" -ForegroundColor Gray
    Write-Host "         Consulte RESOLVE_403_ERROR.md para instruções."           -ForegroundColor Gray
}

Write-Host ""
Write-Host "📂 Arquivos: $exportFolder" -ForegroundColor Cyan
Write-Host ""
Write-Host "✨ Concluído!" -ForegroundColor Green
Write-Host ""
