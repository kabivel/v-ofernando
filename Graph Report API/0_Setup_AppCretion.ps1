# ============================================================================
# SETUP - Criação de App Registration para Reports Graph API
# Versão moderna com módulos atualizados
# ============================================================================

Write-Host ""
Write-Host "╔════════════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
Write-Host "║  SETUP - Graph Reports API (Plug & Play)                       ║" -ForegroundColor Cyan
Write-Host "║  Este script criará tudo que você precisa automaticamente      ║" -ForegroundColor Cyan
Write-Host "╚════════════════════════════════════════════════════════════════╝" -ForegroundColor Cyan
Write-Host ""

# Instalar módulos modernos (não deprecated)
Write-Host "📦 Verificando módulos necessários..." -ForegroundColor Yellow

if (-not (Get-Module -ListAvailable -Name Microsoft.Graph.Authentication)) {
    Write-Host "   ↳ Instalando Microsoft.Graph.Authentication..." -ForegroundColor Blue
    Install-Module -Name Microsoft.Graph.Authentication -Scope CurrentUser -Force -AllowClobber
}

if (-not (Get-Module -ListAvailable -Name Microsoft.Graph.Applications)) {
    Write-Host "   ↳ Instalando Microsoft.Graph.Applications..." -ForegroundColor Blue
    Install-Module -Name Microsoft.Graph.Applications -Scope CurrentUser -Force -AllowClobber
}

if (-not (Get-Module -ListAvailable -Name Microsoft.Graph.DirectoryObjects)) {
    Write-Host "   ↳ Instalando Microsoft.Graph.DirectoryObjects..." -ForegroundColor Blue
    Install-Module -Name Microsoft.Graph.DirectoryObjects -Scope CurrentUser -Force -AllowClobber
}

Write-Host "✅ Módulos verificados!" -ForegroundColor Green
Write-Host ""

try {
    # Conectar ao Microsoft Graph com permissão de Admin
    Write-Host "🔐 Conectando ao Microsoft Graph..." -ForegroundColor Blue
    Write-Host "   (Uma janela de navegador pode abrir para você fazer login)" -ForegroundColor Gray
    
    Connect-MgGraph -Scopes "Application.ReadWrite.All", "Directory.ReadWrite.All" -NoWelcome | Out-Null
    
    Write-Host "✅ Conectado com sucesso!" -ForegroundColor Green
    Write-Host ""
    
    # Obter contexto do usuário logado
    $context = Get-MgContext
    $tenantId = $context.TenantId
    $userEmail = $context.Account
    
    Write-Host "👤 Usuário: $userEmail" -ForegroundColor Gray
    Write-Host "🏢 Tenant ID: $tenantId" -ForegroundColor Yellow
    Write-Host ""
    
    # Criar App Registration com nome único
    $appName = "GraphReports_$(Get-Date -Format 'yyyyMMdd_HHmm')"
    Write-Host "🚀 Criando App Registration: $appName" -ForegroundColor Blue
    
    $appParams = @{
        DisplayName = $appName
        Description = "App para extração de relatórios do Microsoft 365 via Graph API"
        SignInAudience = "AzureADMyOrg"
    }
    $app = New-MgApplication @appParams
    $clientId = $app.AppId
    
    Write-Host "✅ App criado!" -ForegroundColor Green
    Write-Host "   Client ID: $clientId" -ForegroundColor Yellow
    Write-Host ""
    
    # Criar Service Principal
    Write-Host "👤 Criando Service Principal..." -ForegroundColor Blue
    $sp = New-MgServicePrincipal -AppId $clientId -DisplayName $appName
    Write-Host "✅ Service Principal criado!" -ForegroundColor Green
    Write-Host ""
    
    # Aguardar sincronização
    Write-Host "⏳ Aguardando sincronização..." -ForegroundColor Yellow
    Start-Sleep -Seconds 5
    
    # Adicionar permissão: Reports.Read.All
    Write-Host "🔑 Configurando permissão Reports.Read.All..." -ForegroundColor Blue
    
    # Obter o Microsoft Graph Service Principal
    $graphSP = Get-MgServicePrincipal -Filter "appId eq '00000003-0000-0000-c000-000000000000'"
    
    # Obter a permissão Reports.Read.All
    $reportPermission = $graphSP.AppRoles | Where-Object { $_.Value -eq "Reports.Read.All" }
    
    if ($reportPermission) {
        # Adicionar a permissão ao app
        $appRoleAssignment = @{
            PrincipalId = $sp.Id
            ResourceId = $graphSP.Id
            AppRoleId = $reportPermission.Id
        }
        
        New-MgServicePrincipalAppRoleAssignment -ServicePrincipalId $sp.Id @appRoleAssignment | Out-Null
        Write-Host "✅ Permissão Reports.Read.All adicionada!" -ForegroundColor Green
    } else {
        Write-Host "⚠️ Aviso: Permissão Reports.Read.All não encontrada (pode precisar consentimento manual)" -ForegroundColor Yellow
    }
    
    Write-Host ""
    
    # Criar Client Secret
    Write-Host "🔐 Criando Client Secret (válido por 1 ano)..." -ForegroundColor Blue
    
    $passwordCredential = @{
        DisplayName = "AutoCreated-$(Get-Date -Format 'yyyyMMdd_HHmm')"
        EndDateTime = (Get-Date).AddYears(1)
    }
    
    $secret = Add-MgApplicationPassword -ApplicationId $app.Id @passwordCredential
    $clientSecret = $secret.SecretText
    
    Write-Host "✅ Client Secret criado!" -ForegroundColor Green
    Write-Host ""
    
    # Definir variáveis globais
    $global:ClientId = $clientId
    $global:ClientSecret = $clientSecret
    $global:TenantId = $tenantId
    
    # Salvar configuração em arquivo JSON
    $configData = @{
        ClientId = $global:ClientId
        ClientSecret = $global:ClientSecret
        TenantId = $global:TenantId
        AppName = $appName
        CreatedDate = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
        SecretExpires = (Get-Date).AddYears(1).ToString("yyyy-MM-dd")
        Status = "Completo - Pronto para usar"
    }
    
    $configFileName = "graph_config.json"
    $configData | ConvertTo-Json -Depth 2 | Set-Content -Path $configFileName -Encoding UTF8
    
    Write-Host ""
    Write-Host "╔════════════════════════════════════════════════════════════════╗" -ForegroundColor Green
    Write-Host "║  ✅ SETUP CONCLUÍDO COM SUCESSO!                              ║" -ForegroundColor Green
    Write-Host "╚════════════════════════════════════════════════════════════════╝" -ForegroundColor Green
    Write-Host ""
    
    Write-Host "📋 CREDENCIAIS GERADAS:" -ForegroundColor Cyan
    Write-Host "─────────────────────────────────────────────────────────" -ForegroundColor Gray
    Write-Host "Client ID:     $global:ClientId" -ForegroundColor White
    Write-Host "Client Secret: $global:ClientSecret" -ForegroundColor Yellow
    Write-Host "Tenant ID:     $global:TenantId" -ForegroundColor White
    Write-Host "─────────────────────────────────────────────────────────" -ForegroundColor Gray
    Write-Host ""
    
    Write-Host "💾 ARQUIVO DE CONFIGURAÇÃO:" -ForegroundColor Cyan
    Write-Host "   ↳ $configFileName" -ForegroundColor Green
    Write-Host "   (Você pode usar este arquivo para backup ou transferir para outro computador)" -ForegroundColor Gray
    Write-Host ""
    
    Write-Host "▶️  PRÓXIMO PASSO - USE OS DADOS ACIMA:" -ForegroundColor Cyan
    Write-Host "─────────────────────────────────────────────────────────" -ForegroundColor Gray
    Write-Host "1. Abra o arquivo: 2_Graph_Only.ps1" -ForegroundColor White
    Write-Host "2. No início do script, substitua as linhas:" -ForegroundColor White
    Write-Host "" -ForegroundColor White
    Write-Host "   `$ClientId    = '$global:ClientId'" -ForegroundColor Yellow
    Write-Host "   `$ClientSecret = '$global:ClientSecret'" -ForegroundColor Yellow
    Write-Host "   `$TenantId    = '$global:TenantId'" -ForegroundColor Yellow
    Write-Host "" -ForegroundColor White
    Write-Host "3. Salve o arquivo e execute: .\2_Graph_Only.ps1" -ForegroundColor White
    Write-Host "─────────────────────────────────────────────────────────" -ForegroundColor Gray
    Write-Host ""
    
    Write-Host "✅ PRONTO! Todas as credenciais estão configuradas e prontas para uso." -ForegroundColor Green
    Write-Host ""
    
} catch {
    Write-Host ""
    Write-Host "❌ ERRO: $_" -ForegroundColor Red
    Write-Host ""
    Write-Host "💡 SOLUÇÕES:" -ForegroundColor Yellow
    Write-Host "   • Execute como Administrador (clique direito > Executar como administrador)" -ForegroundColor Gray
    Write-Host "   • Verifique sua conexão com a internet" -ForegroundColor Gray
    Write-Host "   • Feche e reabra o PowerShell" -ForegroundColor Gray
    Write-Host "   • Se o erro persistir, entre em contato com o suporte" -ForegroundColor Gray
    Write-Host ""
}