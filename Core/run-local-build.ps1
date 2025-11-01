Write-Host "Running local build: restore, build, test"

dotnet restore
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }

dotnet build --configuration Release
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }

dotnet test --no-build
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }

Write-Host "Build and tests completed"
