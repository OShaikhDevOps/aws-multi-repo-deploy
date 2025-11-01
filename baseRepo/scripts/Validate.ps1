param(
  [string]$url = "http://localhost/health"
)

Write-Host "Validating health endpoint: $url"

try {
    $resp = Invoke-WebRequest -Uri $url -UseBasicParsing -TimeoutSec 10
    if ($resp.StatusCode -eq 200) {
        Write-Host "Health check OK"
        exit 0
    } else {
        Write-Host "Health check failed with status $($resp.StatusCode)"
        exit 1
    }
} catch {
    Write-Host "Health check failed: $_"
    exit 2
}
