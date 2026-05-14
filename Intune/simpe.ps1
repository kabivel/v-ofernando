Connect-MgGraph -Scopes "Device.ReadWrite.All"

# Listar dispositivos sem login há mais de 90 dias
$cutoff = (Get-Date).AddDays(-90)
$stale = Get-MgDevice -All | Where-Object {
    $_.ApproximateLastSignInDateTime -lt $cutoff
}

# Desabilitar
$stale | ForEach-Object {
    Update-MgDevice -DeviceId $_.Id -AccountEnabled:$false
}

# Após período de carência, remover
# $stale | ForEach-Object { Remove-MgDevice -DeviceId $_.Id }