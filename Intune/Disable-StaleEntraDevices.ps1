<#
.SYNOPSIS
    Identifica e desabilita dispositivos obsoletos no Entra ID (Azure AD)
    com base na data do último sign-in.

.DESCRIPTION
    Usa Microsoft Graph PowerShell SDK para:
      1. Listar dispositivos sem sign-in há mais de N dias.
      2. Exportar relatório CSV.
      3. Desabilitar (AccountEnabled = $false) — opcional.
      4. Remover dispositivos já desabilitados há mais de N dias — opcional.

.REQUIREMENTS
    Install-Module Microsoft.Graph -Scope CurrentUser
    Permissões: Device.ReadWrite.All, Directory.Read.All

.EXAMPLE
    .\Disable-StaleEntraDevices.ps1 -InactiveDays 90 -WhatIfMode
    .\Disable-StaleEntraDevices.ps1 -InactiveDays 90 -Disable
    .\Disable-StaleEntraDevices.ps1 -InactiveDays 180 -Disable -Delete
#>

[CmdletBinding()]
param(
    [int]$InactiveDays = 90,
    [switch]$Disable,
    [switch]$Delete,
    [switch]$WhatIfMode,
    [string]$ExportPath = "$PSScriptRoot\StaleDevices_$(Get-Date -Format 'yyyyMMdd_HHmm').csv"
)

# --- Conectar ao Graph ---
Write-Host "Conectando ao Microsoft Graph..." -ForegroundColor Cyan
Connect-MgGraph -Scopes "Device.ReadWrite.All","Directory.Read.All" -NoWelcome

$cutoff = (Get-Date).ToUniversalTime().AddDays(-$InactiveDays)
Write-Host "Buscando dispositivos sem sign-in desde: $cutoff" -ForegroundColor Yellow

# --- Coletar dispositivos ---
$allDevices = Get-MgDevice -All -Property `
    Id,DisplayName,DeviceId,OperatingSystem,OperatingSystemVersion,`
    TrustType,AccountEnabled,ApproximateLastSignInDateTime,RegistrationDateTime

$stale = $allDevices | Where-Object {
    $_.ApproximateLastSignInDateTime -ne $null -and
    $_.ApproximateLastSignInDateTime -lt $cutoff
}

Write-Host "Total de dispositivos: $($allDevices.Count)"
Write-Host "Dispositivos obsoletos (>$InactiveDays dias): $($stale.Count)" -ForegroundColor Magenta

# --- Exportar CSV ---
$stale | Select-Object DisplayName,DeviceId,OperatingSystem,OperatingSystemVersion,
    TrustType,AccountEnabled,ApproximateLastSignInDateTime,RegistrationDateTime |
    Export-Csv -Path $ExportPath -NoTypeInformation -Encoding UTF8
Write-Host "Relatório salvo em: $ExportPath" -ForegroundColor Green

# --- Desabilitar ---
if ($Disable) {
    foreach ($d in $stale | Where-Object AccountEnabled -eq $true) {
        if ($WhatIfMode) {
            Write-Host "[WhatIf] Desabilitaria: $($d.DisplayName) ($($d.DeviceId))" -ForegroundColor Yellow
        } else {
            try {
                Update-MgDevice -DeviceId $d.Id -AccountEnabled:$false
                Write-Host "Desabilitado: $($d.DisplayName)" -ForegroundColor DarkYellow
            } catch {
                Write-Warning "Falha ao desabilitar $($d.DisplayName): $_"
            }
        }
    }
}

# --- Remover (somente já desabilitados) ---
if ($Delete) {
    foreach ($d in $stale | Where-Object AccountEnabled -eq $false) {
        if ($WhatIfMode) {
            Write-Host "[WhatIf] Removeria: $($d.DisplayName) ($($d.DeviceId))" -ForegroundColor Red
        } else {
            try {
                Remove-MgDevice -DeviceId $d.Id
                Write-Host "Removido: $($d.DisplayName)" -ForegroundColor Red
            } catch {
                Write-Warning "Falha ao remover $($d.DisplayName): $_"
            }
        }
    }
}

Disconnect-MgGraph | Out-Null
Write-Host "Concluído." -ForegroundColor Cyan
