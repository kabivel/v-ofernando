# Conecte-se ao Microsoft Graph com os escopos necessários
# Connect-MgGraph -Scopes User.Read.All,Directory.Read.All,AuditLog.Read.All,"RoleManagement.Read.Directory", "User.Read.All", "Directory.Read.All"


#-- Folder Creation --#
$domain = Get-MgDomain | Where-Object { $_.Id -like "*.onmicrosoft.com" }
$folder = $domain.Id.Split('.')[0]
md $folder -Force

###################################
# RELATÓRIO DE LICENÇAS SUSPENSAS #
###################################

# Recupera os SKUs de assinatura
$skus = Get-MgSubscribedSku

# Mapeamento de nomes amigáveis
$nomeComercial = @{
    "ENTERPRISEPACK"       = "Microsoft 365 E3"
    "ENTERPRISEPREMIUM"    = "Microsoft 365 E5"
    "EXCHANGESTANDARD"     = "Exchange Online (Plano 1)"
    "MCOEV"                = "Microsoft Teams Exploratory"
    "MCOSTANDARD"          = "Microsoft Teams (sem PSTN)"
    "EMS"                  = "EMS E3"
    "EMSPREMIUM"           = "EMS E5"
    "PROJECTESSENTIALS"    = "Project Plan 1"
    "VISIOONLINEPLAN2"     = "Visio Plan 2"
    "POWER_BI_PRO"         = "Power BI Pro"
    "SPB"                  = "Microsoft 365 Business Premium"
}

# Cria uma lista para armazenar os dados de licenças
$dadosLicencas = @()

foreach ($sku in $skus) {
    $licenca = $sku.SkuPartNumber
    $nome = if ($nomeComercial.ContainsKey($licenca)) { $nomeComercial[$licenca] } else { $licenca }
    $total = $sku.PrepaidUnits.Enabled
    $atribuido = $sku.ConsumedUnits
    $disponivel = $total - $atribuido
    $estado = $sku.CapabilityStatus

    $dadosLicencas += [PSCustomObject]@{
        Licenca        = $licenca
        NomeComercial  = $nome
        Total          = $total
        Atribuido      = $atribuido
        Disponivel     = $disponivel
        Estado         = $estado
    }
}


# Exporta relatório de licenças
$outFileLic = $folder + "\Lics_suspensas.csv"
$dadosLicencas | Export-Csv -Path $outFileLic -NoTypeInformation -Encoding UTF8
Write-Host "✅ Relatório de licenças gerado: $outFileLic"

################################
# RELATÓRIO DE ADMINS COM ROLE #
################################

# Carrega todas as definições de função (roles)
$roleDefs = Get-MgRoleManagementDirectoryRoleDefinition -All

# Carrega todas as atribuições de função (roleAssignments)
$assignments = Get-MgRoleManagementDirectoryRoleAssignment -All

# Lista para armazenar os resultados de admins
$resultAdmins = @()

foreach ($a in $assignments) {
    # Busca o usuário associado à atribuição
    $u = Get-MgUser -UserId $a.PrincipalId -ErrorAction SilentlyContinue
    if (-not $u) { continue }

    # Nome da função
    $roleName = ($roleDefs | Where-Object Id -eq $a.RoleDefinitionId).DisplayName

    # Adiciona ao resultado
    $resultAdmins += [PSCustomObject]@{
        DisplayName = $u.DisplayName
        UserPrincipalName = $u.UserPrincipalName
        Role = $roleName
    }
}

$outFileAdmins = $folder + "\Usuarios_com_Role.csv"
$resultAdmins | Export-Csv -Path $outFileAdmins -NoTypeInformation -Encoding UTF8
Write-Host "✅ Relatório de admins com role gerado: $outFileAdmins"


####################
# get_MFA_per_User #
####################
# 1. Busca todos os usuários com ID, nome e UPN do tenant via Microsoft Graph
$users = Get-MgUser -All -Select "Id","DisplayName","UserPrincipalName"

# 2. Define as colunas desejadas para o relatório detalhado de métodos de autenticação
$columns = @(
    "UserPrincipalName",
    "MethodType",
    "DisplayName",
    "MfaRegistrationDate", # Data de registro do método MFA
    "PhoneType",
    "PhoneNumber",
    "EmailAddress",
    "KeyStrength",
    "DeviceTag",
    "IsDefault",
    "AppName",
    "AppVersion",
    "LastUsedDateTime",
    "IsUsableForSignIn",
    "IsPasswordlessCapable",
    "IsMfaRegistered",
    "IsMfaCapable",
    "IsSsprCapable",
    "IsSsprEnabled",
    "IsSsprRegistered",
    "State",
    "Status",
    "MFAError"
)

# 3. Consulta os métodos de autenticação de cada usuário e monta o relatório detalhado
$results = @()

foreach ($u in $users) {
    try {
        $methods = Invoke-MgGraphRequest `
            -Method GET `
            -Uri "https://graph.microsoft.com/beta/users/$($u.Id)/authentication/methods"

        foreach ($m in $methods.value) {
            $obj = [ordered]@{}
            $obj["UserPrincipalName"] = $u.UserPrincipalName
            $obj["MethodType"]        = $m["@odata.type"] -replace "#microsoft.graph.", ""
            $obj["DisplayName"]       = $u.DisplayName
            # Usa registrationDateTime se existir, senão createdDateTime
            $obj["MfaRegistrationDate"] = $m.registrationDateTime
            if (-not $obj["MfaRegistrationDate"] -and $m.createdDateTime) {
                $obj["MfaRegistrationDate"] = $m.createdDateTime
            }
            $obj["PhoneType"]         = $m.phoneType
            $obj["PhoneNumber"]       = $m.phoneNumber
            $obj["EmailAddress"]      = $m.emailAddress
            $obj["KeyStrength"]       = $m.keyStrength
            $obj["DeviceTag"]         = $m.deviceTag
            $obj["IsDefault"]         = $m.isDefault
            $obj["AppName"]           = $m.appName
            $obj["AppVersion"]        = $m.appVersion
            $obj["LastUsedDateTime"]     = $m.lastUsedDateTime
            $obj["IsUsableForSignIn"]    = $m.isUsableForSignIn
            $obj["IsPasswordlessCapable"]= $m.isPasswordlessCapable
            $obj["IsMfaRegistered"]      = $m.isMfaRegistered
            $obj["IsMfaCapable"]         = $m.isMfaCapable
            $obj["IsSsprCapable"]        = $m.isSsprCapable
            $obj["IsSsprEnabled"]        = $m.isSsprEnabled
            $obj["IsSsprRegistered"]     = $m.isSsprRegistered
            $obj["State"]                = $m.state
            $obj["Status"]               = $m.status
            $obj["MFAError"]             = ""
            $results += [PSCustomObject]$obj
        }
    } catch {
        $obj = [ordered]@{}
        foreach ($col in $columns) { $obj[$col] = "" }
        $obj["UserPrincipalName"] = $u.UserPrincipalName
        $obj["DisplayName"] = $u.DisplayName
        $obj["MFAError"] = "Erro ao recuperar métodos"
        $results += [PSCustomObject]$obj
    }
}

# 8. Exporta para CSV o relatório detalhado de métodos de autenticação
$outFile = $folder + "\get_MFA_per_User.csv"
$results | Select-Object $columns | Export-Csv -Path $outFile -NoTypeInformation -Encoding UTF8

Write-Host "✅ Relatório CSV de métodos de autenticação gerado: $outFile"

# Lista ampliada de relatórios de uso
$reports = @(

  # Apps
  @{ Name = "getM365AppUserDetail"; Uri = "https://graph.microsoft.com/v1.0/reports/getM365AppUserDetail(period='D180')" },
  @{ Name = "getOffice365ActivationCounts"; Uri = "https://graph.microsoft.com/v1.0/reports/getOffice365ActivationCounts" },
  @{ Name = "getOffice365ActivationsUserCounts"; Uri = "https://graph.microsoft.com/v1.0/reports/getOffice365ActivationsUserCounts" },

  # Exchange
  @{ Name = "getEmailActivityCounts"; Uri = "https://graph.microsoft.com/v1.0/reports/getEmailActivityCounts(period='D180')" },
  @{ Name = "getEmailActivityUserDetail"; Uri = "https://graph.microsoft.com/v1.0/reports/getEmailActivityUserDetail(period='D180')" },
  @{ Name = "getEmailAppUsageAppsUserCounts"; Uri = "https://graph.microsoft.com/v1.0/reports/getEmailAppUsageAppsUserCounts(period='D180')" },
  @{ Name = "getEmailAppUsageUserDetail"; Uri = "https://graph.microsoft.com/v1.0/reports/getEmailAppUsageUserDetail(period='D180')" },
  @{ Name = "getEmailAppUsageUserCounts"; Uri = "https://graph.microsoft.com/v1.0/reports/getEmailAppUsageUserCounts(period='D180')" },
  @{ Name = "getMailboxUsageDetail"; Uri = "https://graph.microsoft.com/v1.0/reports/getMailboxUsageDetail(period='D180')" },
  @{ Name = "getMailboxUsageMailboxCounts"; Uri = "https://graph.microsoft.com/v1.0/reports/getMailboxUsageMailboxCounts(period='D180')" },
  @{ Name = "getMailboxUsageQuotaStatusMailboxCounts"; Uri = "https://graph.microsoft.com/v1.0/reports/getMailboxUsageQuotaStatusMailboxCounts(period='D180')" },
  @{ Name = "getMailboxUsageStorage"; Uri = "https://graph.microsoft.com/v1.0/reports/getMailboxUsageStorage(period='D180')" },
  @{ Name = "getOffice365ActiveUserCounts"; Uri = "https://graph.microsoft.com/v1.0/reports/getOffice365ActiveUserCounts(period='D180')" },
  @{ Name = "getOffice365ActiveUserDetail"; Uri = "https://graph.microsoft.com/v1.0/reports/getOffice365ActiveUserDetail(period='D180')" },

  # Onedrive
  @{ Name = "getOneDriveUsageAccountDetail"; Uri = "https://graph.microsoft.com/v1.0/reports/getOneDriveUsageAccountDetail(period='D180')" },
  @{ Name = "getOneDriveUsageAccountCounts"; Uri = "https://graph.microsoft.com/v1.0/reports/getOneDriveUsageAccountCounts(period='D180')" },
  @{ Name = "getOneDriveUsageFileCounts";    Uri = "https://graph.microsoft.com/v1.0/reports/getOneDriveUsageFileCounts(period='D180')" },
  @{ Name = "getOneDriveUsageStorage";  Uri = "https://graph.microsoft.com/v1.0/reports/getOneDriveUsageStorage(period='D180')" },

  @{ Name = "getOneDriveActivityUserDetail"; Uri = "https://graph.microsoft.com/v1.0/reports/getOneDriveActivityUserDetail(period='D180')" },
  @{ Name = "getOneDriveActivityUserCounts"; Uri = "https://graph.microsoft.com/v1.0/reports/getOneDriveActivityUserCounts(period='D180')" },
  @{ Name = "getOneDriveActivityFileCounts";    Uri = "https://graph.microsoft.com/v1.0/reports/getOneDriveActivityFileCounts(period='D180')" },

  # Sharepoint
  @{ Name = "getSharePointActivityUserDetail"; Uri = "https://graph.microsoft.com/v1.0/reports/getSharePointActivityUserDetail(period='D180')" },
  @{ Name = "getSharePointActivityFileCounts"; Uri = "https://graph.microsoft.com/v1.0/reports/getSharePointActivityFileCounts(period='D180')" },
  @{ Name = "getSharePointActivityUserCounts";    Uri = "https://graph.microsoft.com/v1.0/reports/getSharePointActivityUserCounts(period='D180')" },
  @{ Name = "getSharePointActivityPages";  Uri = "https://graph.microsoft.com/v1.0/reports/getSharePointActivityPages(period='D180')" },

  @{ Name = "getSharePointSiteUsageDetail"; Uri = "https://graph.microsoft.com/v1.0/reports/getSharePointSiteUsageDetail(period='D180')" },
  @{ Name = "getSharePointSiteUsageFileCounts"; Uri = "https://graph.microsoft.com/v1.0/reports/getSharePointSiteUsageFileCounts(period='D180')" },
  @{ Name = "getSharePointSiteUsageSiteCounts";    Uri = "https://graph.microsoft.com/v1.0/reports/getSharePointSiteUsageSiteCounts(period='D180')" },
  @{ Name = "getSharePointSiteUsageStorage";  Uri = "https://graph.microsoft.com/v1.0/reports/getSharePointSiteUsageStorage(period='D180')" },
  @{ Name = "getSharePointSiteUsagePages";  Uri = "https://graph.microsoft.com/v1.0/reports/getSharePointSiteUsagePages(period='D180')" },

  # Teams
  @{ Name = "getTeamsDeviceUsageDistributionUserCounts";   Uri = "https://graph.microsoft.com/v1.0/reports/getTeamsDeviceUsageDistributionUserCounts(period='D180')" },
  @{ Name = "getTeamsDeviceUsageUserCounts";               Uri = "https://graph.microsoft.com/v1.0/reports/getTeamsDeviceUsageUserCounts(period='D180')" },
  @{ Name = "getTeamsDeviceUsageUserDetail";               Uri = "https://graph.microsoft.com/v1.0/reports/getTeamsDeviceUsageUserDetail(period='D180')" },
  @{ Name = "getTeamsTeamActivityCounts";                  Uri = "https://graph.microsoft.com/v1.0/reports/getTeamsTeamActivityCounts(period='D180')" },
  @{ Name = "getTeamsTeamActivityDetail";                  Uri = "https://graph.microsoft.com/v1.0/reports/getTeamsTeamActivityDetail(period='D180')" },
  @{ Name = "getTeamsUserActivityCounts";                  Uri = "https://graph.microsoft.com/v1.0/reports/getTeamsUserActivityCounts(period='D180')" },
  @{ Name = "getTeamsUserActivityUserCounts";              Uri = "https://graph.microsoft.com/v1.0/reports/getTeamsUserActivityUserCounts(period='D180')" },
  @{ Name = "getTeamsUserActivityUserDetail";              Uri = "https://graph.microsoft.com/v1.0/reports/getTeamsUserActivityUserDetail(period='D180')" }
)

foreach ($report in $reports) {
    $outCsv = $folder + "\$($report.Name).csv"
    Invoke-MgGraphRequest `
      -Method GET `
      -Uri $report.Uri `
      -OutputFilePath $outCsv

    Write-Host "✅ $($report.Name) salvo em: $outCsv"
}