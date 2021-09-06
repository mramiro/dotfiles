#!/usr/bin/env pwsh

[CmdletBinding(SupportsShouldProcess=$true)]param(
  [Parameter(Mandatory=$false)][Switch]$Force
)

$srcFolder = Get-Item "$PSScriptRoot/windows"
$localAppData = [Environment]::GetFolderPath("LocalApplicationData")
Get-ChildItem -Recurse -File $srcFolder | ForEach {
  $srcFile = $_
  $relPath = [System.IO.Path]::GetRelativePath($srcFolder, $srcFile)
  $targetPath = Join-Path $localAppData $relPath
  if (!$Force -and (Test-Path -Type Leaf -Path $targetPath)) {
    Write-Host "File exists. Skipping: $targetPath"
  }
  Write-Host "Copying file: $srcFile -> $targetPath"
  if ($PSCmdlet.ShouldProcess($targetPath, "Copy file $srcFile")) {
    Copy-Item $srcFile $targetPath
  }
}
