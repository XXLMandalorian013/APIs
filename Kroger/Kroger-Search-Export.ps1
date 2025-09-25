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
# Token creation.
#region
$headers = @{
    'Accept' = 'application/json'
    'Authorization' = "Bearer $($response.access_token)"
}
# Now do the product search with this store ID
$storeID = Read-Host "Enter a store ID number."
$searchTerm = Read-Host "What would you like to search for?"
$productResponse = Invoke-RestMethod -Uri "https://api-ce.kroger.com/v1/products?filter.term=$searchTerm&filter.locationId=$storeId&filter.fulfillment=inStore" -Method Get -Headers $headers
# Display results
$productResponse.data | Select-Object -Property description, brand, items | ForEach-Object {
    Write-Host "`nProduct: $($_.description)" -ForegroundColor Cyan
    Write-Host "Brand: $($_.brand)"
    Write-Host "Price Info:"
    $_.items | ForEach-Object {
        Write-Host "  - Size: $($_.size)"
        Write-Host "    Regular Price: `$$($_.price.regular)"
        if ($_.price.promo -gt 0 -and $_.price.promo -lt $_.price.regular) {
            $savings = $_.price.regular - $_.price.promo
            Write-Host "    SALE PRICE: `$$($_.price.promo)" -ForegroundColor Green
            Write-Host "    You Save: `$$($savings.ToString('0.00'))" -ForegroundColor Yellow
        }
        if ($_.price.promotions) {
            Write-Host "    Promotions:" -ForegroundColor Magenta
            $_.price.promotions | ForEach-Object {
                Write-Host "      - $($_.description)" -ForegroundColor Magenta
            }
        }
    }
    Write-Host "------------------------"
}
#endregion
# Convert to CSV.
#region
$csvData = $productResponse.data | ForEach-Object {
    $product = $_
    $product.items | ForEach-Object {
        [PSCustomObject]@{
            ProductName = $product.description
            Brand = $product.brand
            Size = $_.size
            RegularPrice = $_.price.regular
            UPC = $_.upc
            FulfillmentMethod = $_.fulfillment.curbside ? "Curbside Available" : "In Store Only"
        }
    }
}
$exportPath = "$env:USERPROFILE\Desktop\KrogerProducts.csv"
$csvData | Export-Csv -Path $exportPath -NoTypeInformation
Write-Host "CSV file has been created at: $exportPath"
#endregion




