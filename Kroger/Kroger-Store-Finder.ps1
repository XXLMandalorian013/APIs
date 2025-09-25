# Cred prompt
#region
$clientId = Read-Host "Enter your Kroger API Client ID"
$clientSecret = Read-Host "Enter your Kroger API Client Secret" -AsSecureString
$clientSecretText = [Runtime.InteropServices.Marshal]::PtrToStringAuto([Runtime.InteropServices.Marshal]::SecureStringToBSTR($clientSecret))
$credentials = "${clientId}:${clientSecretText}"
$encodedCredentials = [Convert]::ToBase64String([System.Text.Encoding]::UTF8.GetBytes($credentials))
#endregion
# Token creation.
#region
$headers = @{
    'Content-Type' = 'application/x-www-form-urlencoded'
    'Authorization' = "Basic $encodedCredentials"
}
$body = @{
    'grant_type' = 'client_credentials'
    'scope' = 'product.compact'
}
$response = Invoke-RestMethod -Uri 'https://api-ce.kroger.com/v1/connect/oauth2/token' -Method Post -Headers $headers -Body $body
$response | ConvertTo-Json
#endregion
# Store Lookup Function
function Find-KrogerStores {
    $zipCode = Read-Host "Enter ZIP code to find nearby stores"
    $MileLimit = Read-Host "Enter the mile radius for store search"
    $headers = @{
        'Accept' = 'application/json'
        'Authorization' = "Bearer $($response.access_token)"
    }
    try {
        $storeResponse = Invoke-RestMethod -Uri "https://api-ce.kroger.com/v1/locations?filter.zipCode.near=$zipCode&filter.radiusInMiles=$MileLimit&filter.limit=50" -Method Get -Headers $headers
        if ($storeResponse.data.Count -gt 0) {
            Write-Host "`nStores found within $MileLimit miles of ZIP code: $zipCode" -ForegroundColor Cyan
            Write-Host "=============================" -ForegroundColor Cyan
            $storeResponse.data | ForEach-Object {
                Write-Host "`nStore ID: $($_.locationId)" -ForegroundColor Yellow
                Write-Host "Name: $($_.name)"
                Write-Host "Address: $($_.address.addressLine1)"
                Write-Host "         $($_.address.city), $($_.address.state) $($_.address.zipCode)"
                if ($_.geolocation.distanceFromStoreInMiles) {
                    Write-Host "Distance: $($_.geolocation.distanceFromStoreInMiles) miles"
                }
                Write-Host "Hours: $($_.hours.regular.open) - $($_.hours.regular.close)"
                Write-Host "-----------------------------"
            }
        } else {
            Write-Host "No stores found within $MileLimit miles of ZIP code: $zipCode" -ForegroundColor Red
        }
    } catch {
        Write-Host "Error looking up stores: $_" -ForegroundColor Red
        if ($_.Exception.Response) {
            Write-Host $_.Exception.Response.Content -ForegroundColor Red
        }
    }
}
# Run the store lookup
Find-KrogerStores
