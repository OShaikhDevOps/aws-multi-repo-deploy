param(
    [string]$Profile = "",
    [string]$Region = "",
    [string]$ParametersFile = "cloudformation-parameters.json",
    [string]$TemplateFile = "codepipeline-cloudformation.yml"
)

<#
Simple wrapper to deploy the CloudFormation template using the example parameters JSON.

Usage:
  .\deploy-stack.ps1 -Profile your-aws-profile -Region us-east-1
  .\deploy-stack.ps1 -ParametersFile .\cloudformation-parameters.json

This script reads the JSON file, converts the Parameters object into
--parameter-overrides for `aws cloudformation deploy` and invokes the AWS CLI.
Ensure AWS CLI v2 is installed and available in PATH, or provide a valid profile.
#>

if (-not (Get-Command aws -ErrorAction SilentlyContinue)) {
    Write-Error "AWS CLI not found in PATH. Install and configure AWS CLI v2 or ensure 'aws' is available."
    exit 2
}

$paramsPath = Join-Path -Path (Split-Path -Path $MyInvocation.MyCommand.Path -Parent) -ChildPath $ParametersFile
if (-not (Test-Path $paramsPath)) {
    Write-Error "Parameters file not found: $paramsPath"
    exit 3
}

$json = Get-Content -Raw -Path $paramsPath | ConvertFrom-Json
$stackName = $json.StackName
if (-not $stackName) {
    Write-Error "StackName is not defined in the parameters JSON."
    exit 4
}

$paramOverrides = @()
foreach ($prop in $json.Parameters.PSObject.Properties) {
    $k = $prop.Name
    $v = $prop.Value
    if ($null -ne $v -and ($v -ne "")) {
        # Escape spaces
        $escaped = $v -replace '"', '"' 
        $paramOverrides += ("$k=$escaped")
    }
}

$templatePath = Join-Path -Path (Split-Path -Path $MyInvocation.MyCommand.Path -Parent) -ChildPath $TemplateFile
if (-not (Test-Path $templatePath)) {
    Write-Error "CloudFormation template not found: $templatePath"
    exit 5
}

$awsArgs = @('cloudformation','deploy', '--template-file', $templatePath, '--stack-name', $stackName, '--capabilities', 'CAPABILITY_NAMED_IAM')
if ($paramOverrides.Count -gt 0) { $awsArgs += @('--parameter-overrides') ; $awsArgs += $paramOverrides }
if ($Profile -ne "") { $awsArgs += @('--profile', $Profile) }
if ($Region -ne "") { $awsArgs += @('--region', $Region) }

Write-Host "Running: aws $($awsArgs -join ' ')"
$proc = Start-Process -FilePath aws -ArgumentList $awsArgs -NoNewWindow -Wait -PassThru
if ($proc.ExitCode -ne 0) {
    Write-Error "aws cli exited with code $($proc.ExitCode)"
    exit $proc.ExitCode
}

Write-Host "CloudFormation deploy finished (stack: $stackName). Check the AWS Console or run 'aws cloudformation describe-stacks --stack-name $stackName' for status."
