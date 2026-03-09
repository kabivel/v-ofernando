# Credenciais do Azure Storage
$storageAccountName = "bicenter"
$storageAccountKey  = "sv=2024-11-04&ss=bfqt&srt=sco&sp=rwdlacupiytfx&se=2026-10-10T03:39:17Z&st=2025-10-10T19:24:17Z&spr=https&sig=4N%2BzEEGGFBw8UD7vjZLWIkUZzJanzGhEuyu7cVebeFg%3D"
$containerName      = "bicenter"
$localFolder        = "D:\5_HSBS\Export"  # <-- define the local folder
$destinationFolder  = "BI Cloud Ops\QCA"             # optional subfolder in container

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
