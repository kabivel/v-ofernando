# ============================================================================
# RELATÓRIOS DO MICROSOFT 365 - Graph API
# Setup: Execute 0_Setup_AppCretion.ps1 primeiro
# ============================================================================

# 🔐 SUBSTITUA COM OS VALORES DO SETUP (gerados em 0_Setup_AppCretion.ps1)
$ClientId    = "SUBSTITUA_COM_CLIENT_ID_DO_SETUP"
$ClientSecret = "SUBSTITUA_COM_CLIENT_SECRET_DO_SETUP"
$TenantId    = "SUBSTITUA_COM_TENANT_ID_DO_SETUP"

# ============================================================================
# Autenticação (não precisa alterar)
Write-Host "🔐 Autenticando no Microsoft Graph..." -ForegroundColor Blue

try {
    $secureClientSecret = $ClientSecret | ConvertTo-SecureString -AsPlainText -Force
    $credential = New-Object System.Management.Automation.PSCredential($ClientId, $secureClientSecret)
    
    Connect-MgGraph -ClientId $ClientId -TenantId $TenantId -ClientSecret $secureClientSecret -NoWelcome | Out-Null
    Write-Host "✅ Autenticado com sucesso!" -ForegroundColor Green
} catch {
    Write-Host "❌ Erro na autenticação: $_" -ForegroundColor Red
    Write-Host "Verifique suas credenciais e tente novamente." -ForegroundColor Yellow
    exit
}

# ============================================================================
# Lista ampliada de relatórios de uso
$reports = @(

  # Apps
  @{ Name = "getM365AppUserDetail"; Uri = "https://graph.microsoft.com/v1.0/reports/getM365AppUserDetail(period='D90')" },
  @{ Name = "getOffice365ActivationCounts"; Uri = "https://graph.microsoft.com/v1.0/reports/getOffice365ActivationCounts" },
  @{ Name = "getOffice365ActivationsUserCounts"; Uri = "https://graph.microsoft.com/v1.0/reports/getOffice365ActivationsUserCounts" },

  # Exchange
  @{ Name = "getEmailActivityCounts"; Uri = "https://graph.microsoft.com/v1.0/reports/getEmailActivityCounts(period='D90')" },
  @{ Name = "getEmailActivityUserDetail"; Uri = "https://graph.microsoft.com/v1.0/reports/getEmailActivityUserDetail(period='D90')" },
  @{ Name = "getEmailAppUsageAppsUserCounts"; Uri = "https://graph.microsoft.com/v1.0/reports/getEmailAppUsageAppsUserCounts(period='D90')" },
  @{ Name = "getEmailAppUsageUserDetail"; Uri = "https://graph.microsoft.com/v1.0/reports/getEmailAppUsageUserDetail(period='D90')" },
  @{ Name = "getEmailAppUsageUserCounts"; Uri = "https://graph.microsoft.com/v1.0/reports/getEmailAppUsageUserCounts(period='D90')" },
  @{ Name = "getMailboxUsageDetail"; Uri = "https://graph.microsoft.com/v1.0/reports/getMailboxUsageDetail(period='D90')" },
  @{ Name = "getMailboxUsageMailboxCounts"; Uri = "https://graph.microsoft.com/v1.0/reports/getMailboxUsageMailboxCounts(period='D90')" },
  @{ Name = "getMailboxUsageQuotaStatusMailboxCounts"; Uri = "https://graph.microsoft.com/v1.0/reports/getMailboxUsageQuotaStatusMailboxCounts(period='D90')" },
  @{ Name = "getMailboxUsageStorage"; Uri = "https://graph.microsoft.com/v1.0/reports/getMailboxUsageStorage(period='D90')" },
  @{ Name = "getOffice365ActiveUserCounts"; Uri = "https://graph.microsoft.com/v1.0/reports/getOffice365ActiveUserCounts(period='D90')" },
  @{ Name = "getOffice365ActiveUserDetail"; Uri = "https://graph.microsoft.com/v1.0/reports/getOffice365ActiveUserDetail(period='D90')" },

  # Onedrive
  @{ Name = "getOneDriveUsageAccountDetail"; Uri = "https://graph.microsoft.com/v1.0/reports/getOneDriveUsageAccountDetail(period='D90')" },
  @{ Name = "getOneDriveUsageAccountCounts"; Uri = "https://graph.microsoft.com/v1.0/reports/getOneDriveUsageAccountCounts(period='D90')" },
  @{ Name = "getOneDriveUsageFileCounts";    Uri = "https://graph.microsoft.com/v1.0/reports/getOneDriveUsageFileCounts(period='D90')" },
  @{ Name = "getOneDriveUsageStorage";  Uri = "https://graph.microsoft.com/v1.0/reports/getOneDriveUsageStorage(period='D90')" },

  @{ Name = "getOneDriveActivityUserDetail"; Uri = "https://graph.microsoft.com/v1.0/reports/getOneDriveActivityUserDetail(period='D90')" },
  @{ Name = "getOneDriveActivityUserCounts"; Uri = "https://graph.microsoft.com/v1.0/reports/getOneDriveActivityUserCounts(period='D90')" },
  @{ Name = "getOneDriveActivityFileCounts";    Uri = "https://graph.microsoft.com/v1.0/reports/getOneDriveActivityFileCounts(period='D90')" },

  # Sharepoint
  @{ Name = "getSharePointActivityUserDetail"; Uri = "https://graph.microsoft.com/v1.0/reports/getSharePointActivityUserDetail(period='D90')" },
  @{ Name = "getSharePointActivityFileCounts"; Uri = "https://graph.microsoft.com/v1.0/reports/getSharePointActivityFileCounts(period='D90')" },
  @{ Name = "getSharePointActivityUserCounts";    Uri = "https://graph.microsoft.com/v1.0/reports/getSharePointActivityUserCounts(period='D90')" },
  @{ Name = "getSharePointActivityPages";  Uri = "https://graph.microsoft.com/v1.0/reports/getSharePointActivityPages(period='D90')" },

  @{ Name = "getSharePointSiteUsageDetail"; Uri = "https://graph.microsoft.com/v1.0/reports/getSharePointSiteUsageDetail(period='D90')" },
  @{ Name = "getSharePointSiteUsageFileCounts"; Uri = "https://graph.microsoft.com/v1.0/reports/getSharePointSiteUsageFileCounts(period='D90')" },
  @{ Name = "getSharePointSiteUsageSiteCounts";    Uri = "https://graph.microsoft.com/v1.0/reports/getSharePointSiteUsageSiteCounts(period='D90')" },
  @{ Name = "getSharePointSiteUsageStorage";  Uri = "https://graph.microsoft.com/v1.0/reports/getSharePointSiteUsageStorage(period='D90')" },
  @{ Name = "getSharePointSiteUsagePages";  Uri = "https://graph.microsoft.com/v1.0/reports/getSharePointSiteUsagePages(period='D90')" },

  # Teams
  @{ Name = "getTeamsDeviceUsageDistributionUserCounts";   Uri = "https://graph.microsoft.com/v1.0/reports/getTeamsDeviceUsageDistributionUserCounts(period='D90')" },
  @{ Name = "getTeamsDeviceUsageUserCounts";               Uri = "https://graph.microsoft.com/v1.0/reports/getTeamsDeviceUsageUserCounts(period='D90')" },
  @{ Name = "getTeamsDeviceUsageUserDetail";               Uri = "https://graph.microsoft.com/v1.0/reports/getTeamsDeviceUsageUserDetail(period='D90')" },
  @{ Name = "getTeamsTeamActivityCounts";                  Uri = "https://graph.microsoft.com/v1.0/reports/getTeamsTeamActivityCounts(period='D90')" },
  @{ Name = "getTeamsTeamActivityDetail";                  Uri = "https://graph.microsoft.com/v1.0/reports/getTeamsTeamActivityDetail(period='D90')" },
  @{ Name = "getTeamsUserActivityCounts";                  Uri = "https://graph.microsoft.com/v1.0/reports/getTeamsUserActivityCounts(period='D90')" },
  @{ Name = "getTeamsUserActivityUserCounts";              Uri = "https://graph.microsoft.com/v1.0/reports/getTeamsUserActivityUserCounts(period='D90')" },
  @{ Name = "getTeamsUserActivityUserDetail";              Uri = "https://graph.microsoft.com/v1.0/reports/getTeamsUserActivityUserDetail(period='D90')" },

  # Copilot
  @{ Name = "getCopilotInteractionUserCounts";             Uri = "https://graph.microsoft.com/v1.0/reports/getCopilotInteractionUserCounts(period='D90')" },
  @{ Name = "getCopilotInteractionUserDetail";             Uri = "https://graph.microsoft.com/v1.0/reports/getCopilotInteractionUserDetail(period='D90')" },
  @{ Name = "getCopilotSummaryUserCounts";                 Uri = "https://graph.microsoft.com/v1.0/reports/getCopilotSummaryUserCounts(period='D90')" },
  @{ Name = "getCopilotSummaryUserDetail";                 Uri = "https://graph.microsoft.com/v1.0/reports/getCopilotSummaryUserDetail(period='D90')" }
)

# ============================================================================
# Extrair Relatórios
Write-Host ""
Write-Host "┌────────────────────────────────────────────────────────┐" -ForegroundColor Cyan
Write-Host "│  Iniciando exportação de relatórios (D90 = 90 dias)    │" -ForegroundColor Cyan
Write-Host "└────────────────────────────────────────────────────────┘" -ForegroundColor Cyan
Write-Host ""

# Criar pasta Export se não existir
$exportFolder = "Export"
if (-not (Test-Path $exportFolder)) {
    New-Item -ItemType Directory -Path $exportFolder | Out-Null
    Write-Host "📁 Pasta criada: $exportFolder" -ForegroundColor Gray
}

$successCount = 0
$failureCount = 0
$failureList = @()

foreach ($report in $reports) {
    $outCsv = "$exportFolder\$($report.Name).csv"
    
    try {
        Write-Host "⏳ Processando: $($report.Name)..." -ForegroundColor Blue -NoNewline
        
        Invoke-MgGraphRequest `
          -Method GET `
          -Uri $report.Uri `
          -OutputFilePath $outCsv `
          -ErrorAction Stop | Out-Null
        
        Write-Host " ✅" -ForegroundColor Green
        $successCount++
        
    } catch {
        Write-Host " ❌" -ForegroundColor Red
        $failureCount++
        $failureList += $report.Name
    }
}

Write-Host ""
Write-Host "┌────────────────────────────────────────────────────────┐" -ForegroundColor Cyan
Write-Host "│  RESUMO DA EXPORTAÇÃO                                  │" -ForegroundColor Cyan
Write-Host "└────────────────────────────────────────────────────────┘" -ForegroundColor Cyan
Write-Host "✅ Sucesso: $successCount relatório(s)" -ForegroundColor Green
Write-Host "❌ Falha:   $failureCount relatório(s)" -ForegroundColor Red

if ($failureList.Count -gt 0) {
    Write-Host ""
    Write-Host "Relatórios com erro:" -ForegroundColor Yellow
    foreach ($item in $failureList) {
        Write-Host "  • $item" -ForegroundColor Gray
    }
}

Write-Host ""
Write-Host "📂 Arquivos salvos em: $(Join-Path (Get-Location) $exportFolder)" -ForegroundColor Cyan
Write-Host ""
Write-Host "✨ Exportação concluída!" -ForegroundColor Green
Write-Host ""