# Certificate authentication parameters - PREENCHA ESTES VALORES
$tenantId = "61e3e996-4ed3-420f-8065-ab360c2c3d90"  # Preencha com seu Tenant ID
$appId = "94e769c4-dbe2-475b-b370-58fccf8ee506"     # Preencha com seu Application (Client) ID
$certThumbprint = "7F1815A057B7BDE41FCA3B9A6747058A43C518BF"  # Preencha com o Thumbprint do seu certificado

param(
    [Parameter(Mandatory=$false)]
    [string]$OutputPath = "EntraUsers.csv",
    
    [Parameter(Mandatory=$false)]
    [switch]$ForceInteractive
)

# Determine authentication method
$UseCertificateAuth = $false
$UseInteractiveAuth = $false

if ($ForceInteractive) {
    Write-Host "Forçando autenticação interativa..." -ForegroundColor Yellow
    $UseInteractiveAuth = $true
}
elseif (-not [string]::IsNullOrEmpty($tenantId) -and -not [string]::IsNullOrEmpty($appId) -and -not [string]::IsNullOrEmpty($certThumbprint)) {
    Write-Host "Parâmetros de certificado preenchidos. Usando autenticação por certificado..." -ForegroundColor Green
    $UseCertificateAuth = $true
}
else {
    Write-Host "Parâmetros de certificado não preenchidos. Usando autenticação interativa..." -ForegroundColor Yellow
    $UseInteractiveAuth = $true
}

# Install Microsoft.Graph module if not already installed
if (-not (Get-Module -ListAvailable -Name Microsoft.Graph)) {
    Write-Host "Installing Microsoft.Graph module..." -ForegroundColor Yellow
    Install-Module -Name Microsoft.Graph -Scope CurrentUser -Force
}

# Import required modules
Import-Module Microsoft.Graph.Authentication
Import-Module Microsoft.Graph.Users

try {
    if ($UseCertificateAuth) {
        # Verify certificate exists in certificate store
        Write-Host "Verificando certificado..." -ForegroundColor Green
        $Certificate = Get-ChildItem -Path "Cert:\CurrentUser\My" | Where-Object { $_.Thumbprint -eq $certThumbprint }
        
        if (-not $Certificate) {
            # Also check LocalMachine store
            $Certificate = Get-ChildItem -Path "Cert:\LocalMachine\My" | Where-Object { $_.Thumbprint -eq $certThumbprint }
        }
        
        if (-not $Certificate) {
            Write-Warning "Certificado com thumbprint '$certThumbprint' não encontrado. Tentando autenticação interativa..."
            $UseInteractiveAuth = $true
            $UseCertificateAuth = $false
        }
        else {
            Write-Host "Certificado encontrado: $($Certificate.Subject)" -ForegroundColor Green
            
            # Connect to Microsoft Graph using certificate authentication
            Write-Host "Conectando ao Microsoft Graph usando autenticação por certificado..." -ForegroundColor Green
            Connect-MgGraph -TenantId $tenantId -ClientId $appId -CertificateThumbprint $certThumbprint
        }
    }
    
    if ($UseInteractiveAuth) {
        # Connect to Microsoft Graph using interactive authentication
        Write-Host "Conectando ao Microsoft Graph usando autenticação interativa..." -ForegroundColor Green
        Write-Host "Uma janela do navegador será aberta para login..." -ForegroundColor Yellow
        
        # Define required scopes for interactive login
        $Scopes = @(
            "User.Read.All",
            "Directory.Read.All"
        )
        
        Connect-MgGraph -Scopes $Scopes
    }
    
    # Verify connection
    $Context = Get-MgContext
    if (-not $Context) {
        throw "Falha na conexão com Microsoft Graph"
    }
    
    Write-Host "Successfully connected to tenant: $($Context.TenantId)" -ForegroundColor Green
    Write-Host "App ID: $($Context.ClientId)" -ForegroundColor Green
    Write-Host "Auth Type: $($Context.AuthType)" -ForegroundColor Green
    Write-Host "Scopes: $($Context.Scopes -join ', ')" -ForegroundColor Green
    
    # Get all users with detailed properties
    Write-Host "Retrieving user information..." -ForegroundColor Green
    $Users = Get-MgUser -All -Property @(
        'Id',
        'DisplayName', 
        'UserPrincipalName',
        'Mail',
        'GivenName',
        'Surname',
        'JobTitle',
        'Department',
        'CompanyName',
        'OfficeLocation',
        'BusinessPhones',
        'MobilePhone',
        'StreetAddress',
        'City',
        'State',
        'PostalCode',
        'Country',
        'AccountEnabled',
        'CreatedDateTime',
        'LastPasswordChangeDateTime',
        'UserType',
        'AssignedLicenses'
    )
    
    Write-Host "Found $($Users.Count) users. Processing data..." -ForegroundColor Green
    
    # Create array to store processed user data
    $UserData = @()
    $ProcessedCount = 0
    
    foreach ($User in $Users) {
        $ProcessedCount++
        
        # Show progress every 50 users
        if ($ProcessedCount % 50 -eq 0) {
            Write-Host "Processed $ProcessedCount of $($Users.Count) users..." -ForegroundColor Yellow
        }
        
        # Get manager information if available
        $ManagerName = ""
        try {
            $Manager = Get-MgUserManager -UserId $User.Id -ErrorAction SilentlyContinue
            if ($Manager) {
                $ManagerDetails = Get-MgUser -UserId $Manager.Id -Property DisplayName -ErrorAction SilentlyContinue
                $ManagerName = $ManagerDetails.DisplayName
            }
        }
        catch {
            $ManagerName = ""
        }
        
        # Process assigned licenses
        $LicenseNames = @()
        if ($User.AssignedLicenses) {
            foreach ($License in $User.AssignedLicenses) {
                $LicenseNames += $License.SkuId
            }
        }
        $LicensesString = $LicenseNames -join "; "
        
        # Create custom object with user data
        $UserObject = [PSCustomObject]@{
            'User ID' = $User.Id
            'Display Name' = $User.DisplayName
            'User Principal Name' = $User.UserPrincipalName
            'Email' = $User.Mail
            'First Name' = $User.GivenName
            'Last Name' = $User.Surname
            'Job Title' = $User.JobTitle
            'Department' = $User.Department
            'Company' = $User.CompanyName
            'Office Location' = $User.OfficeLocation
            'Business Phone' = ($User.BusinessPhones -join "; ")
            'Mobile Phone' = $User.MobilePhone
            'Street Address' = $User.StreetAddress
            'City' = $User.City
            'State' = $User.State
            'Postal Code' = $User.PostalCode
            'Country' = $User.Country
            'Account Enabled' = $User.AccountEnabled
            'Created Date' = $User.CreatedDateTime
            'Last Password Change' = $User.LastPasswordChangeDateTime
            'User Type' = $User.UserType
            'Manager' = $ManagerName
            'Assigned Licenses' = $LicensesString
        }
        
        $UserData += $UserObject
    }
    
    # Export to CSV
    Write-Host "Exporting to CSV: $OutputPath" -ForegroundColor Green
    $UserData | Export-Csv -Path $OutputPath -NoTypeInformation -Encoding UTF8
    
    Write-Host "Export completed successfully!" -ForegroundColor Green
    Write-Host "File location: $((Get-Item $OutputPath).FullName)" -ForegroundColor Cyan
    Write-Host "Total users exported: $($UserData.Count)" -ForegroundColor Cyan
    
    # Display summary statistics
    $EnabledUsers = ($UserData | Where-Object { $_.'Account Enabled' -eq $true }).Count
    $DisabledUsers = ($UserData | Where-Object { $_.'Account Enabled' -eq $false }).Count
    $UsersWithLicenses = ($UserData | Where-Object { $_.'Assigned Licenses' -ne "" }).Count
    
    Write-Host "`nSummary:" -ForegroundColor Cyan
    Write-Host "  - Enabled users: $EnabledUsers" -ForegroundColor White
    Write-Host "  - Disabled users: $DisabledUsers" -ForegroundColor White
    Write-Host "  - Users with licenses: $UsersWithLicenses" -ForegroundColor White
    
}
catch {
    Write-Error "An error occurred: $($_.Exception.Message)"
    Write-Host "Stack trace: $($_.Exception.StackTrace)" -ForegroundColor Red
}
finally {
    # Disconnect from Microsoft Graph
    if (Get-MgContext) {
        Disconnect-MgGraph
        Write-Host "Disconnected from Microsoft Graph" -ForegroundColor Yellow
    }
}

<#
INSTRUÇÕES DE USO:

MÉTODO 1 - AUTENTICAÇÃO POR CERTIFICADO (Automática):
1. PREENCHA OS VALORES NO INÍCIO DO SCRIPT:
   - $tenantId: Seu Tenant ID do Azure AD
   - $appId: Application ID (Client ID) do seu app registration
   - $certThumbprint: Thumbprint do certificado instalado

2. CERTIFICADO DEVE ESTAR INSTALADO:
   - No repositório "Current User\Personal" ou "Local Machine\Personal"
   - Com chave privada disponível
   - Associado ao App Registration no Azure AD

3. APP REGISTRATION DEVE TER PERMISSÕES:
   - User.Read.All (Application)
   - Directory.Read.All (Application)

MÉTODO 2 - AUTENTICAÇÃO INTERATIVA (Login manual):
1. DEIXE OS PARÂMETROS DE CERTIFICADO VAZIOS (ou use -ForceInteractive)
2. O script abrirá uma janela do navegador para login
3. Faça login com uma conta que tenha permissões adequadas

EXEMPLOS DE EXECUÇÃO:

# Usando certificado (se parâmetros preenchidos)
.\ExportEntraUsersCert.ps1

# Forçando login interativo
.\ExportEntraUsersCert.ps1 -ForceInteractive

# Login interativo com caminho customizado
.\ExportEntraUsersCert.ps1 -OutputPath "C:\Reports\MyUsers.csv" -ForceInteractive

# Automático (certificado se disponível, senão interativo)
.\ExportEntraUsersCert.ps1 -OutputPath "C:\Reports\MyUsers.csv"

PERMISSÕES NECESSÁRIAS PARA LOGIN INTERATIVO:
- A conta deve ter permissão para ler usuários no Azure AD
- Roles como "User Administrator", "Global Reader" ou "Global Administrator"
#>