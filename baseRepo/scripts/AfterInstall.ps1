Write-Host "Running AfterInstall: extracting artifact and setting permissions"

$dest = "C:\inetpub\mywebapi"
$zip = Join-Path $deploy_root "artifact.zip"

if (-Not (Test-Path $zip)) {
    # CodeDeploy expands artifact so the zip may already be extracted; try artifact path
    Write-Host "artifact.zip not found at $zip. Attempting to find artifact in current dir."
    $found = Get-ChildItem -Filter artifact.zip -Recurse -ErrorAction SilentlyContinue | Select-Object -First 1
    if ($found) { $zip = $found.FullName }
}

if (Test-Path $zip) {
    Write-Host "Extracting $zip to $dest"
    Add-Type -AssemblyName System.IO.Compression.FileSystem
    [IO.Compression.ZipFile]::ExtractToDirectory($zip, $dest)
} else {
    Write-Host "No zip found — assuming files already deployed"
}

# Set permissions for IIS user
Write-Host "Setting permissions for IIS_IUSRS on $dest"
$acl = Get-Acl $dest
$perm = "IIS_IUSRS","Modify","ContainerInherit,ObjectInherit","None","Allow"
$accessRule = New-Object System.Security.AccessControl.FileSystemAccessRule $perm
$acl.SetAccessRule($accessRule)
Set-Acl $dest $acl

Write-Host "AfterInstall completed"
