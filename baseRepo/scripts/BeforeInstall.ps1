Write-Host "Running BeforeInstall: stopping IIS site and app pool if exists"

Import-Module WebAdministration -ErrorAction SilentlyContinue

$siteName = "MyWebApiSite"
$appPool = "MyWebApiAppPool"

# Stop site & app pool if present
if (Get-WebAppPoolState -Name $appPool -ErrorAction SilentlyContinue) {
    Write-Host "Stopping app pool $appPool"
    Stop-WebAppPool $appPool
}

if (Get-Website -Name $siteName -ErrorAction SilentlyContinue) {
    Write-Host "Stopping site $siteName"
    Stop-Website -Name $siteName
}

# Ensure destination directory exists
$dest = "C:\inetpub\mywebapi"
if (-Not (Test-Path $dest)) {
    New-Item -Path $dest -ItemType Directory -Force | Out-Null
}

# Clean destination
Write-Host "Cleaning destination $dest"
Remove-Item "$dest\*" -Recurse -Force -ErrorAction SilentlyContinue

Write-Host "BeforeInstall completed"
