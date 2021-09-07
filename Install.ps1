#!/usr/bin/env pwsh

[CmdletBinding(SupportsShouldProcess=$true)]param(
  [Parameter(Mandatory=$false)][Switch]$Force
)

  function ResolveSymlink([System.IO.FileInfo]$file) {
    $contents = [Array](Get-Content $file)
    if ($contents.Length -eq 1) {
      $target = Join-Path $file.Directory $contents[0]
      if (Test-Path -Type Leaf $target) {
        return Get-Item $target
      }
    }
  }

function InstallToWinFolder([System.IO.DirectoryInfo]$srcFolder) {
  # "MyDocuments", "LocalApplicationData", etc.
  $baseTargetFolder = [Environment]::GetFolderPath($srcFolder.BaseName)
  Get-ChildItem -Recurse -File $srcFolder | ForEach-Object {
    $srcFile = $_
    $relPath = [System.IO.Path]::GetRelativePath($srcFolder, $srcFile)
    $targetPath = Join-Path $baseTargetFolder $relPath
    if (!$Force -and (Test-Path -Type Leaf -Path $targetPath)) {
      Write-Host "File exists. Skipping: $targetPath"
      return
    }
    # Symlinks
    $linkedFile = ResolveSymlink $srcFile
    if ($linkedFile) {
      Write-Host "Source file $srcFile is symlink."
        $srcFile = $linkedFile
    }
    Write-Host "Copying file: $srcFile -> $targetPath"
    if ($PSCmdlet.ShouldProcess($targetPath, "Copy file $srcFile")) {
      Copy-Item $srcFile $targetPath -Force -Recurse
    }
  }
}

if (!$IsWindows) {
  if ($Force) {
    Write-Warning "Running on non-windows OS"
  } else {
    Write-Error "This file is meant to run on Windows only. Use -Force to override"
    exit 1
  }
}

$rootFolder = Get-Item "$PSScriptRoot/windows"
Get-ChildItem -Directory $rootFolder | ForEach-Object { InstallToWinFolder $_ }