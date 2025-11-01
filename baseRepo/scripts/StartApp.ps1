Write-Host "Starting IIS site and app pool"

Import-Module WebAdministration -ErrorAction SilentlyContinue

$siteName = "MyWebApiSite"
$appPool = "MyWebApiAppPool"
$physicalPath = "C:\inetpub\mywebapi"

# Ensure app pool exists
if (-Not (Get-ChildItem IIS:\AppPools | Where-Object { $_.Name -eq $appPool })) {
    Write-Host "Creating app pool $appPool"
    New-WebAppPool -Name $appPool
}

# Ensure site exists
if (-Not (Get-Website -Name $siteName -ErrorAction SilentlyContinue)) {
    Write-Host "Creating website $siteName pointing to $physicalPath"
    New-Website -Name $siteName -Port 80 -PhysicalPath $physicalPath -ApplicationPool $appPool
}

# Start app pool & site
Start-WebAppPool -Name $appPool
Start-Website -Name $siteName

Write-Host "StartApp completed"
