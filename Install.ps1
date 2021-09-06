#!/usr/bin/env pwsh

[CmdletBinding(SupportsShouldProcess=$true)]param(
  [Parameter(Mandatory=$false)][Switch]$Force
)

function InstallToWinFolder([System.IO.DirectoryInfo]$srcFolder) {
  # "MyDocuments", "LocalApplicationData", etc.
  $baseTargetFolder = [Environment]::GetFolderPath($srcFolder.BaseName)
  Get-ChildItem -Recurse -File $srcFolder | ForEach {
    $srcFile = $_
    $relPath = [System.IO.Path]::GetRelativePath($srcFolder, $srcFile)
    $targetPath = Join-Path $baseTargetFolder $relPath
    if (!$Force -and (Test-Path -Type Leaf -Path $targetPath)) {
      Write-Host "File exists. Skipping: $targetPath"
    }
    Write-Host "Copying file: $srcFile -> $targetPath"
    if ($PSCmdlet.ShouldProcess($targetPath, "Copy file $srcFile")) {
      Copy-Item $srcFile $targetPath
    }
  }
}

$rootFolder = Get-Item "$PSScriptRoot/windows"
Get-ChildItem -Directory $rootFolder | ForEach-Object { InstallToWinFolder $_ }
