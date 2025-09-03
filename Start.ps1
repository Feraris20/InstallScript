Enable-WindowsOptionalFeature -Online -FeatureName NetFx3 -All
# msg * /time:15 "✅ .NET Framework 3.5 installed successfully."
Write-Output "*****************************************"
Write-Output "Winget version: $(winget --version)"
winget install --id=Microsoft.AppInstaller --accept-source-agreements --accept-package-agreements --silent
Write-Output "*****************************************"
Write-Output "Winget version: $(winget --version)"


$apps = @("Microsoft.VisualStudioCode", "abbodi1406.vcredist", "M2Team.NanaZip", "Nilesoft.Shell")
foreach ($app in $apps) { winget install --id=$app --accept-source-agreements --accept-package-agreements --silent }
Write-Output "Winget version: $(winget --version)"
