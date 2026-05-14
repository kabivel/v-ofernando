# Credenciais do Azure Storage
$storageAccountName = ""
$storageAccountKey  = ""
$containerName      = ""
$localFolder        = ""  # <-- define the local folder
$destinationFolder  = ""             # optional subfolder in container

# Garantir que o módulo Az.Storage esteja instalado e importado
if (-not (Get-Module -ListAvailable -Name Az.Storage)) {
    Write-Host "Módulo Az.Storage não encontrado. Instalando..."
    Install-Module -Name Az.Storage -Scope CurrentUser -Force
}
Import-Module Az.Storage -Force

# Cria o contexto do Storage
$ctx = New-AzStorageContext -StorageAccountName $storageAccountName -SasToken $storageAccountKey
    #-StorageAccountKey  $storageAccountKey

# Busca todos os arquivos na pasta local (recursivo)
$files = Get-ChildItem -Path $localFolder -File -Recurse

foreach ($file in $files) {

    # Calcula caminho relativo dentro da pasta base
    $relativePath = $file.FullName.Substring($localFolder.Length).TrimStart('\')

    # Constrói o nome do blob (usa / para pastas virtuais)
    if ([string]::IsNullOrEmpty($destinationFolder)) {
        $blobName = $relativePath -replace '\\','/'
    }
    else {
        $blobName = "$destinationFolder/$($relativePath -replace '\\','/')"
    }

    # Exibe log e faz upload
    Write-Host "Uploading $($file.FullName) → $blobName"
    Set-AzStorageBlobContent `
        -File      $file.FullName `
        -Container $containerName `
        -Blob      $blobName `
        -Context   $ctx `
        -Force
}
