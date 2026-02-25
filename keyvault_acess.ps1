# Azure Key Vault Demo Script with Menu Interface

param(
    [string]$VaultName = ""
)

# ===== COLOR AND FORMATTING =====
function Write-ColorOutput {
    param(
        [string]$Message,
        [string]$Color = "White"
    )
    Write-Host $Message -ForegroundColor $Color
}

function Write-Header {
    param([string]$Title)
    Write-Host "`n" + ("=" * 60) -ForegroundColor Cyan
    Write-Host "  $Title" -ForegroundColor Cyan
    Write-Host ("=" * 60) -ForegroundColor Cyan
}

function Write-Separator {
    Write-Host ("-" * 60) -ForegroundColor DarkGray
}

# ===== LOGIN METHODS =====
function Show-LoginMenu {
    Write-Header "Métodos de Autenticação do Azure"
    Write-Host ""
    Write-ColorOutput "1. Login Interativo (Browser)" -Color "Yellow"
    Write-ColorOutput "2. Service Principal (Client Secret)" -Color "Yellow"
    Write-ColorOutput "3. Service Principal (Certificate)" -Color "Yellow"
    Write-ColorOutput "4. Managed Identity" -Color "Yellow"
    Write-ColorOutput "5. Device Code Flow" -Color "Yellow"
    Write-ColorOutput "0. Sair" -Color "Red"
    Write-Host ""
}

function Connect-AzureInteractive {
    Write-ColorOutput "`n[*] Abrindo browser para login..." -Color "Green"
    Write-ColorOutput "[!] Complete o login na janela do browser que irá abrir." -Color "Yellow"
    Write-Host ""
    
    try {
        $result = Connect-AzAccount -ErrorAction Stop
        
        Write-Host ""
        Write-Separator
        Write-ColorOutput "[✓] Autenticação bem-sucedida!" -Color "Green"
        Write-Host "Conta: $($result.Context.Account.Id)"
        Write-Host "Subscription: $($result.Context.Subscription.Name)"
        Write-Host "Tenant: $($result.Context.Tenant.Id)"
        Write-Separator
        
        return $true
    }
    catch {
        Write-ColorOutput "[✗] Erro na autenticação: $_" -Color "Red"
        return $false
    }
}

function Connect-AzureServicePrincipal {
    Write-Header "Login via Service Principal (Client Secret)"
    Write-Host ""
    
    $tenantId = Read-Host "Informe o Tenant ID"
    $appId = Read-Host "Informe o Application ID (Client ID)"
    $secret = Read-Host "Informe o Client Secret" -AsSecureString
    
    Write-ColorOutput "`n[*] Conectando ao Azure..." -Color "Green"
    try {
        $credential = New-Object System.Management.Automation.PSCredential($appId, $secret)
        $result = Connect-AzAccount -ServicePrincipal -Credential $credential -Tenant $tenantId -ErrorAction Stop
        
        Write-Host ""
        Write-Separator
        Write-ColorOutput "[✓] Autenticação bem-sucedida!" -Color "Green"
        Write-Host "Service Principal: $($result.Context.Account.Id)"
        Write-Host "Subscription: $($result.Context.Subscription.Name)"
        Write-Host "Tenant: $($result.Context.Tenant.Id)"
        Write-Separator
        
        return $true
    }
    catch {
        Write-ColorOutput "[✗] Erro na autenticação: $_" -Color "Red"
        return $false
    }
}

function Connect-AzureCertificate {
    Write-Header "Login via Service Principal (Certificate)"
    Write-Host ""
    
    $tenantId = Read-Host "Informe o Tenant ID"
    $appId = Read-Host "Informe o Application ID"
    $certificatePath = Read-Host "Caminho para o arquivo .pfx"
    $certificatePassword = Read-Host "Senha do certificado" -AsSecureString
    
    Write-ColorOutput "`n[*] Conectando ao Azure..." -Color "Green"
    try {
        $result = Connect-AzAccount -ServicePrincipal -ApplicationId $appId `
            -CertificatePath $certificatePath `
            -CertificatePassword $certificatePassword `
            -Tenant $tenantId -ErrorAction Stop
        
        Write-Host ""
        Write-Separator
        Write-ColorOutput "[✓] Autenticação bem-sucedida!" -Color "Green"
        Write-Host "Service Principal: $($result.Context.Account.Id)"
        Write-Host "Subscription: $($result.Context.Subscription.Name)"
        Write-Host "Tenant: $($result.Context.Tenant.Id)"
        Write-Separator
        
        return $true
    }
    catch {
        Write-ColorOutput "[✗] Erro na autenticação: $_" -Color "Red"
        return $false
    }
}

function Connect-AzureDeviceCode {
    Write-ColorOutput "`n[*] Iniciando Device Code Flow..." -Color "Green"
    Write-ColorOutput "[!] Um código será exibido. Use-o em https://microsoft.com/devicelogin" -Color "Yellow"
    Write-Host ""
    
    try {
        $result = Connect-AzAccount -UseDeviceAuthentication -ErrorAction Stop
        
        Write-Host ""
        Write-Separator
        Write-ColorOutput "[✓] Autenticação bem-sucedida!" -Color "Green"
        Write-Host "Conta: $($result.Context.Account.Id)"
        Write-Host "Subscription: $($result.Context.Subscription.Name)"
        Write-Host "Tenant: $($result.Context.Tenant.Id)"
        Write-Separator
        
        return $true
    }
    catch {
        Write-ColorOutput "[✗] Erro na autenticação: $_" -Color "Red"
        return $false
    }
}

# ===== KEYVAULT OPERATIONS =====
function Get-VaultName {
    if ($VaultName) {
        return $VaultName
    }
    Write-Host ""
    $vault = Read-Host "Informe o nome do Key Vault"
    return $vault
}

function Show-OperationsMenu {
    Write-Header "Operações do Key Vault"
    Write-Host ""
    Write-ColorOutput "--- SECRETS ---" -Color "Magenta"
    Write-ColorOutput "1. Criar um Secret" -Color "Yellow"
    Write-ColorOutput "2. Listar Secrets" -Color "Yellow"
    Write-ColorOutput "3. Ler um Secret" -Color "Yellow"
    Write-ColorOutput "4. Deletar um Secret" -Color "Yellow"
    Write-Host ""
    Write-ColorOutput "--- KEYS ---" -Color "Magenta"
    Write-ColorOutput "5. Criar uma Key" -Color "Yellow"
    Write-ColorOutput "6. Listar Keys" -Color "Yellow"
    Write-ColorOutput "7. Ler uma Key" -Color "Yellow"
    Write-ColorOutput "8. Deletar uma Key" -Color "Yellow"
    Write-Host ""
    Write-ColorOutput "--- CERTIFICATES ---" -Color "Magenta"
    Write-ColorOutput "9. Listar Certificados" -Color "Yellow"
    Write-ColorOutput "10. Ler Certificado" -Color "Yellow"
    Write-Host ""
    Write-ColorOutput "0. Sair" -Color "Red"
    Write-Host ""
}

function New-KeyVaultSecret {
    param([string]$VaultName)
    
    Write-Header "Criar um novo Secret"
    Write-Host ""
    
    $secretName = Read-Host "Nome do Secret"
    $secretValue = Read-Host "Valor do Secret" -AsSecureString
    
    Write-ColorOutput "`n[*] Criando Secret '$secretName'..." -Color "Green"
    try {
        $result = Set-AzKeyVaultSecret -VaultName $VaultName `
            -Name $secretName `
            -SecretValue $secretValue `
            -ErrorAction Stop
        
        Write-Separator
        Write-ColorOutput "[✓] Secret criado com sucesso!" -Color "Green"
        Write-Host "Nome: $($result.Name)"
        Write-Host "ID: $($result.Id)"
        Write-Host "Versão: $($result.Version)"
        Write-Host "Criado em: $($result.Created)"
        Write-Separator
    }
    catch {
        Write-ColorOutput "[✗] Erro ao criar Secret: $_" -Color "Red"
    }
    
    Pause
}

function Get-KeyVaultSecrets {
    param([string]$VaultName)
    
    Write-Header "Listar Secrets"
    Write-Host ""
    
    Write-ColorOutput "[*] Recuperando Secrets..." -Color "Green"
    try {
        $secrets = Get-AzKeyVaultSecret -VaultName $VaultName -ErrorAction Stop
        
        if ($secrets.Count -eq 0) {
            Write-ColorOutput "[!] Nenhum Secret encontrado." -Color "Yellow"
        }
        else {
            Write-Separator
            $secrets | Format-Table -Property Name, Created, Updated -AutoSize
            Write-Separator
        }
    }
    catch {
        Write-ColorOutput "[✗] Erro ao listar Secrets: $_" -Color "Red"
    }
    
    Pause
}

function Get-KeyVaultSecret {
    param([string]$VaultName)
    
    Write-Header "Ler um Secret"
    Write-Host ""
    
    $secretName = Read-Host "Nome do Secret"
    
    Write-ColorOutput "`n[*] Recuperando Secret '$secretName'..." -Color "Green"
    try {
        $secret = Get-AzKeyVaultSecret -VaultName $VaultName -Name $secretName -ErrorAction Stop
        
        Write-Separator
        Write-ColorOutput "[✓] Secret encontrado!" -Color "Green"
        Write-Host "Nome: $($secret.Name)"
        Write-Host "ID: $($secret.Id)"
        Write-Host "Versão: $($secret.Version)"
        Write-Host "Criado em: $($secret.Created)"
        Write-Host "Atualizado em: $($secret.Updated)"
        
        $showValue = Read-Host "`nExibir valor do Secret? (s/n)"
        if ($showValue -eq "s") {
            $secretValue = Get-AzKeyVaultSecret -VaultName $VaultName -Name $secretName -AsPlainText -ErrorAction Stop
            Write-ColorOutput "`nValor: $secretValue" -Color "Cyan"
        }
        Write-Separator
    }
    catch {
        Write-ColorOutput "[✗] Erro ao recuperar Secret: $_" -Color "Red"
    }
    
    Pause
}

function Remove-KeyVaultSecret {
    param([string]$VaultName)
    
    Write-Header "Deletar um Secret"
    Write-Host ""
    
    $secretName = Read-Host "Nome do Secret a deletar"
    
    Write-ColorOutput "`n[!] Você está prestes a deletar o Secret '$secretName'" -Color "Yellow"
    $confirm = Read-Host "Tem certeza? (s/n)"
    
    if ($confirm -eq "s") {
        Write-ColorOutput "`n[*] Deletando Secret..." -Color "Green"
        try {
            Remove-AzKeyVaultSecret -VaultName $VaultName -Name $secretName -Force -ErrorAction Stop
            Write-ColorOutput "[✓] Secret deletado com sucesso!" -Color "Green"
        }
        catch {
            Write-ColorOutput "[✗] Erro ao deletar Secret: $_" -Color "Red"
        }
    }
    else {
        Write-ColorOutput "[!] Operação cancelada." -Color "Yellow"
    }
    
    Pause
}

function New-KeyVaultKey {
    param([string]$VaultName)
    
    Write-Header "Criar uma nova Key"
    Write-Host ""
    
    $keyName = Read-Host "Nome da Key"
    
    Write-ColorOutput "`n[*] Criando Key '$keyName'..." -Color "Green"
    try {
        $result = Add-AzKeyVaultKey -VaultName $VaultName `
            -Name $keyName `
            -Destination Software `
            -ErrorAction Stop
        
        Write-Separator
        Write-ColorOutput "[✓] Key criada com sucesso!" -Color "Green"
        Write-Host "Nome: $($result.Name)"
        Write-Host "ID: $($result.Id)"
        Write-Host "Tipo: $($result.KeyType)"
        Write-Host "Criada em: $($result.Created)"
        Write-Separator
    }
    catch {
        Write-ColorOutput "[✗] Erro ao criar Key: $_" -Color "Red"
    }
    
    Pause
}

function Get-KeyVaultKeys {
    param([string]$VaultName)
    
    Write-Header "Listar Keys"
    Write-Host ""
    
    Write-ColorOutput "[*] Recuperando Keys..." -Color "Green"
    try {
        $keys = Get-AzKeyVaultKey -VaultName $VaultName -ErrorAction Stop
        
        if ($keys.Count -eq 0) {
            Write-ColorOutput "[!] Nenhuma Key encontrada." -Color "Yellow"
        }
        else {
            Write-Separator
            $keys | Format-Table -Property Name, KeyType, Created, Updated -AutoSize
            Write-Separator
        }
    }
    catch {
        Write-ColorOutput "[✗] Erro ao listar Keys: $_" -Color "Red"
    }
    
    Pause
}

function Get-KeyVaultKey {
    param([string]$VaultName)
    
    Write-Header "Ler uma Key"
    Write-Host ""
    
    $keyName = Read-Host "Nome da Key"
    
    Write-ColorOutput "`n[*] Recuperando Key '$keyName'..." -Color "Green"
    try {
        $key = Get-AzKeyVaultKey -VaultName $VaultName -Name $keyName -ErrorAction Stop
        
        Write-Separator
        Write-ColorOutput "[✓] Key encontrada!" -Color "Green"
        Write-Host "Nome: $($key.Name)"
        Write-Host "ID: $($key.Id)"
        Write-Host "Tipo: $($key.KeyType)"
        Write-Host "Tamanho: $($key.Key.KeySize) bits"
        Write-Host "Criada em: $($key.Created)"
        Write-Host "Atualizada em: $($key.Updated)"
        Write-Separator
    }
    catch {
        Write-ColorOutput "[✗] Erro ao recuperar Key: $_" -Color "Red"
    }
    
    Pause
}

function Remove-KeyVaultKey {
    param([string]$VaultName)
    
    Write-Header "Deletar uma Key"
    Write-Host ""
    
    $keyName = Read-Host "Nome da Key a deletar"
    
    Write-ColorOutput "`n[!] Você está prestes a deletar a Key '$keyName'" -Color "Yellow"
    $confirm = Read-Host "Tem certeza? (s/n)"
    
    if ($confirm -eq "s") {
        Write-ColorOutput "`n[*] Deletando Key..." -Color "Green"
        try {
            Remove-AzKeyVaultKey -VaultName $VaultName -Name $keyName -Force -ErrorAction Stop
            Write-ColorOutput "[✓] Key deletada com sucesso!" -Color "Green"
        }
        catch {
            Write-ColorOutput "[✗] Erro ao deletar Key: $_" -Color "Red"
        }
    }
    else {
        Write-ColorOutput "[!] Operação cancelada." -Color "Yellow"
    }
    
    Pause
}

function Get-KeyVaultCertificates {
    param([string]$VaultName)
    
    Write-Header "Listar Certificados"
    Write-Host ""
    
    Write-ColorOutput "[*] Recuperando Certificados..." -Color "Green"
    try {
        $certs = Get-AzKeyVaultCertificate -VaultName $VaultName -ErrorAction Stop
        
        if ($certs.Count -eq 0) {
            Write-ColorOutput "[!] Nenhum Certificado encontrado." -Color "Yellow"
        }
        else {
            Write-Separator
            $certs | Format-Table -Property Name, Enabled, Created, Updated -AutoSize
            Write-Separator
        }
    }
    catch {
        Write-ColorOutput "[✗] Erro ao listar Certificados: $_" -Color "Red"
    }
    
    Pause
}

function Get-KeyVaultCertificate {
    param([string]$VaultName)
    
    Write-Header "Ler um Certificado"
    Write-Host ""
    
    $certName = Read-Host "Nome do Certificado"
    
    Write-ColorOutput "`n[*] Recuperando Certificado '$certName'..." -Color "Green"
    try {
        $cert = Get-AzKeyVaultCertificate -VaultName $VaultName -Name $certName -ErrorAction Stop
        
        Write-Separator
        Write-ColorOutput "[✓] Certificado encontrado!" -Color "Green"
        Write-Host "Nome: $($cert.Name)"
        Write-Host "ID: $($cert.Id)"
        Write-Host "Ativado: $($cert.Enabled)"
        Write-Host "Criado em: $($cert.Created)"
        Write-Host "Atualizado em: $($cert.Updated)"
        Write-Host "Subject: $($cert.Certificate.Subject)"
        Write-Host "Thumbprint: $($cert.Certificate.Thumbprint)"
        Write-Host "Válido de: $($cert.Certificate.NotBefore)"
        Write-Host "Válido até: $($cert.Certificate.NotAfter)"
        Write-Separator
    }
    catch {
        Write-ColorOutput "[✗] Erro ao recuperar Certificado: $_" -Color "Red"
    }
    
    Pause
}

# ===== MAIN LOOP =====
function Show-MainMenu {
    Write-ColorOutput "`n███████╗ █████╗ ███████╗██╗   ██╗██████╗ ███████╗" -Color "Cyan"
    Write-ColorOutput "██╔════╝██╔══██╗██╔════╝██║   ██║██╔══██╗██╔════╝" -Color "Cyan"
    Write-ColorOutput "█████╗  ███████║███████╗██║   ██║██████╔╝█████╗  " -Color "Cyan"
    Write-ColorOutput "██╔══╝  ██╔══██║╚════██║██║   ██║██╔══██╗██╔══╝  " -Color "Cyan"
    Write-ColorOutput "███████╗██║  ██║███████║╚██████╔╝██║  ██║███████╗" -Color "Cyan"
    Write-ColorOutput "╚══════╝╚═╝  ╚═╝╚══════╝ ╚═════╝ ╚═╝  ╚═╝╚══════╝" -Color "Cyan"
    Write-ColorOutput "" -Color "Cyan"
    Write-ColorOutput "        Azure Key Vault Demo - Cliente Showcase" -Color "Green"
}

function Main {
    Show-MainMenu
    
    # Login
    $authenticated = $false
    while (-not $authenticated) {
        Show-LoginMenu
        $choice = Read-Host "Selecione uma opção"
        
        switch ($choice) {
            "1" { $authenticated = Connect-AzureInteractive }
            "2" { $authenticated = Connect-AzureServicePrincipal }
            "3" { $authenticated = Connect-AzureCertificate }
            "4" { 
                Write-ColorOutput "`n[*] Usando Managed Identity..." -Color "Green"
                $authenticated = $true
            }
            "5" { $authenticated = Connect-AzureDeviceCode }
            "0" { 
                Write-ColorOutput "`n[!] Encerrando..." -Color "Yellow"
                exit
            }
            default { Write-ColorOutput "`n[✗] Opção inválida!" -Color "Red" }
        }
    }
    
    # Get Vault Name
    $vaultName = Get-VaultName
    
    # Operations Loop
    while ($true) {
        Show-OperationsMenu
        $choice = Read-Host "Selecione uma operação"
        
        switch ($choice) {
            "1" { New-KeyVaultSecret -VaultName $vaultName }
            "2" { Get-KeyVaultSecrets -VaultName $vaultName }
            "3" { Get-KeyVaultSecret -VaultName $vaultName }
            "4" { Remove-KeyVaultSecret -VaultName $vaultName }
            "5" { New-KeyVaultKey -VaultName $vaultName }
            "6" { Get-KeyVaultKeys -VaultName $vaultName }
            "7" { Get-KeyVaultKey -VaultName $vaultName }
            "8" { Remove-KeyVaultKey -VaultName $vaultName }
            "9" { Get-KeyVaultCertificates -VaultName $vaultName }
            "10" { Get-KeyVaultCertificate -VaultName $vaultName }
            "0" { 
                Write-ColorOutput "`n[!] Encerrando..." -Color "Yellow"
                break
            }
            default { 
                Write-ColorOutput "`n[✗] Opção inválida!" -Color "Red"
                Pause
            }
        }
        
        if ($choice -eq "0") { break }
    }
}

# ===== EXECUTION =====
Main