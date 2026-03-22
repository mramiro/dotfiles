param(
    [ValidatePattern('^[a-z_][a-z0-9_-]*$')]
    [string]$UserName = 'mramiro',
    [string]$Gecos = 'Miguel Ramiro',
    [string]$RepoUrl = 'https://github.com/mramiro/dotfiles.git',
    [string]$Branch = 'master',
    [string]$TemplatePath = "$PSScriptRoot/cloud-init.yaml",
    [string]$OutputPath = "$env:USERPROFILE/.cloud-init/Ubuntu-24.04.user-data"
)

if (-not (Test-Path -LiteralPath $TemplatePath)) {
    throw "Template not found: $TemplatePath"
}

$template = Get-Content -LiteralPath $TemplatePath -Raw

$rendered = $template
$rendered = $rendered.Replace('__WSL_USERNAME__', $UserName)
$rendered = $rendered.Replace('__WSL_GECOS__', $Gecos)
$rendered = $rendered.Replace('__DOTFILES_REPO_URL__', $RepoUrl)
$rendered = $rendered.Replace('__DOTFILES_REPO_BRANCH__', $Branch)

$outDir = Split-Path -Parent $OutputPath
if (-not (Test-Path -LiteralPath $outDir)) {
    New-Item -ItemType Directory -Path $outDir -Force | Out-Null
}

Set-Content -LiteralPath $OutputPath -Value $rendered -NoNewline

Write-Host "Generated WSL cloud-init user-data: $OutputPath"
Write-Host "UserName=$UserName"
Write-Host "RepoUrl=$RepoUrl"
Write-Host "Branch=$Branch"
