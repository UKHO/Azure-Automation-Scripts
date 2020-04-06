$resourceURI = Get-AutomationVariable -Name 'PostgresResourceURI'
$tenantId = Get-AutomationVariable -Name 'TennantID'
$clientId =  Get-AutomationVariable -Name 'ClientId'
$clientSecret =  Get-AutomationVariable -Name 'ClientSecret'


$param = @{
    "grant_type" = "client_credentials"
    "client_id" = $clientId
    "resource" = "https://management.core.windows.net"
    "client_secret" = ($clientSecret)
}

$accessToken = (Invoke-RestMethod `
    -Method POST `
    -Uri "https://login.microsoftonline.com/$tenantId/oauth2/token" `
    -Body $param `
    -ContentType "application/x-www-form-urlencoded").access_token


$headers = @{
    "Authorization" = "Bearer " + $accessToken
}

$url = "https://management.azure.com/" + $resourceURI + "?api-version=2017-12-01"

$currentServerConfig = Invoke-RestMethod $url `
    -Method GET `
    -Headers $headers


$newServerSku = $currentServerConfig.sku
$newServerSku.capacity /= 2

# Check that we do not scale to above 64 cores
if($newServerSku.capacity -gt 64) {
    $newServerSku.capacity = 64
}

#check that we at least run on 2 cores at a minimum
if($newServerSku.capacity -lt 2) {
    $newServerSku.capacity = 2
}

$newServerSku.name = "GP_Gen5_" + $newServerSku.capacity

$jsonbody = @{
        "sku" = $newServerSku
    } | ConvertTo-Json



Invoke-RestMethod $url `
    -Method PATCH `
    -Headers $headers `
    -Body $jsonbody `
    -ContentType "application/json"

