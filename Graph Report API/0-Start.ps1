##cd d:\5_HSBS
# 1 - Desconecta de qualquer sessÃ£o existente do Microsoft Graph (sem exibir mensagens de erro)
# Disconnect-MgGraph -ErrorAction SilentlyContinue
# Import-Module Microsoft.Graph

# Manual
# Connect-MgGraph -Scopes User.Read.All,Directory.Read.All,AuditLog.Read.All,"RoleManagement.Read.Directory", "User.Read.All", "Directory.Read.All"

# 1.1 - Configurar variáveis de ambiente
$tenantId = "61e3e996-4ed3-420f-8065-ab360c2c3d90"
$appId = "94e769c4-dbe2-475b-b370-58fccf8ee506"
$certThumbprint = "7F1815A057B7BDE41FCA3B9A6747058A43C518BF"

# 1.2 - Carregar certificado do repositório local
$cert = Get-ChildItem -Path Cert:\CurrentUser\My\$certThumbprint

# 1.3 - autenticar
try {
    Write-Host "🔐 Authenticating to tenant $TenantId..." -ForegroundColor Cyan

    # Autenticar silenciosamente usando o certificado
    Connect-MgGraph -ClientId $appId -TenantId $tenantId -Certificate $cert -ErrorAction Stop 
    

    Write-Host "✅ Authentication successful." -ForegroundColor Green
  }
  catch {
    Write-Error "❌ Authentication failed:`n$($_.Exception.Message)"
    Exit 1
  }


# 1.4 - Limpa a tela do terminal
#Invoke-Command -ScriptBlock { & ".\1-MainMenu.ps1" }

#-----UNIFICADO-----#
# 2 - relatorio de licenças suspensas
# Verifica se o script de licenÃ§as suspensas existe e executa    
# Invoke-Command -ScriptBlock { & ".\2-Lics suspensas.ps1" }

#-----UNIFICADO-----#
# 3 - relatorio de admins com licenÃ§as
# Verifica se o script de admins com licenÃ§as existe e executa
#Invoke-Command -ScriptBlock { & ".\3-Admins com lic.ps1" }

#-----UNIFICADO-----#
# 4 - relatorio de ativaÃ§Ã£o do pacote office
# Verifica se o script de ativaÃ§Ã£o do pacote office existe e executa
#Invoke-Command -ScriptBlock { & ".\4-ActivationApps.ps1" }

#-----UNIFICADO-----#
# 5 - relatorio de MFA por usuario
# Verifica se o script de MFA por usuÃ¡rio existe e executa
# Invoke-Command -ScriptBlock { & ".\5-MFA por usuario.ps1" }

# 6 - relatorio de usuarios inativos por onedrive
# Verifica se o script de usuarios inativos por onedrive existe e executa
# Invoke-Command -ScriptBlock { & ".\6-Usuarios Inativos por Onedrive.ps1" }

# 7 - relatorio de usuarios ativos por email
# Verifica se o script de usuarios ativos por email existe e executa
# Invoke-Command -ScriptBlock { & ".\7-UserReport.ps1" }

# 8 - relatorio de usuarios inativos por Teams
# Invoke-Command -ScriptBlock { & ".\8-TeamsReports.ps1" }

# 9 - relatorio de usuarios inativos por Exchange
# Invoke-Command -ScriptBlock { & ".\1_unificado.ps1" }

# 10 - relatorio de usuarios inativos por Exchange
 #Invoke-Command -ScriptBlock { & ".\1_Blob.ps1" }

 