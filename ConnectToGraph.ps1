$Appid = "<AppID>"
$secret = "<Secret>"
$tenant ="<tenant>.onmicrosoft.com" 

Connect-PnPOnline -AppId:$Appid -AppSecret:$secret -AADDomain:$tenant

$accessToken = Get-PnPAccessToken

$apiUrl = "https://graph.microsoft.com/beta/users"
$myUsers = Invoke-WebRequest -Headers @{Authorization = "Bearer $accessToken"} -Uri $apiUrl -Method Get

$valueJson = $myUsers | ConvertFrom-Json

$valueJson.Value
