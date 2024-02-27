#!/usr/bin/env pwsh

[CmdletBinding()]
param(
  [Parameter(Mandatory=$false)][Switch]$Rebuild,
  [Parameter(Mandatory=$false)][Switch]$OnlyMetadata,
  [Parameter(Mandatory=$false)][ValidateSet("Main", "Uber", "Both")]$Jars = "Both",
  [Parameter(Mandatory=$false)][String[]]$Profiles = @(),
  [Parameter(Mandatory=$false)][String[]]$Projects = @()
)

$ErrorActionPreference = "Stop"

function Get-TempFilePath {
  $tmpPath = [IO.Path]::GetTempFileName()
  Remove-Item -Path $tmpPath -Force
  $tmpPath
}

function Get-BuildDirectory($project) {
  if ($project.build) {
    $build = $project.build
    $directory = $build.directory
    if ($build.plugins) {
      $mavenJarPlugin = $build.plugins.plugin | Where-Object { $_.artifactId -eq "maven-jar-plugin" }
      if ($mavenJarPlugin && $mavenJarPlugin.configuration) {
        $configuration = $mavenJarPlugin.configuration
        if ($configuration.outputDirectory) {
          $directory = $configuration.outputDirectory
        }
      }
    }
    $directory
  }
}

function Assert-ProjectHasUberJar($project) {
  if ($project.build) {
    $build = $project.build
    if ($build.plugins) {
      $mavenAssemblyPlugin = $build.plugins.plugin | Where-Object { $_.artifactId -eq "maven-assembly-plugin" }
      if ($mavenAssemblyPlugin && $mavenAssemblyPlugin.configuration) {
        $configuration = $mavenAssemblyPlugin.configuration
        if ($configuration.descriptorRefs) {
          $descriptorRefs = $configuration.descriptorRefs
          if ($descriptorRefs.descriptorRef && $descriptorRefs.descriptorRef | Where-Object { $_ -eq "jar-with-dependencies" }) {
            return $true
          }
        }
      }
    }
  }
  return $false
}

function Expand-Jar($jarPath, $targetDirectory) {
  if (Test-Path -Path $jarPath) {
    if (-not (Test-Path -Path $targetDirectory)) {
      New-Item -ItemType Directory -Path $targetDirectory | Out-Null
    }
    "Extracting $jarPath to $targetDirectory" | Write-Verbose
    Set-Location -Path $targetDirectory
    if ($OnlyMetadata) {
      jar -xf $jarPath "META-INF"
    } else {
      jar -xf $jarPath
    }
    Get-Item $targetDirectory
  } else {
    "Jar not found at $jarPath" | Write-Warning
  }
}

function New-JarDump($project) {
  $projectName = "{0}-{1}" -f $project.artifactId, $project.version
  if ($project.packaging -and $project.packaging -ne "jar") {
    "Skipping non-jar project $projectName" | Write-Host
    return
  }
  "Processing $projectName" | Write-Host
  if (!$project.build) {
    "Project has no build section" | Write-Warning
    return
  }

  $buildDirectory = Get-BuildDirectory $project
  $finalName = $project.build.finalName
  $dumpFolder = Join-Path $buildDirectory "jar-dump"

  if (-not (Test-Path -Path $dumpFolder)) {
    New-Item -ItemType Directory -Path $dumpFolder | Out-Null
  }

  if ($Jars -in "Main", "Both") {
    $jarPath = Join-Path $buildDirectory "$finalName.jar"
    if (Test-Path -Path $jarPath) {
      $dumpTarget = Join-Path $dumpFolder $finalName
      Expand-Jar $jarPath $dumpTarget
    } else {
      "Jar not found at {0}" -f $jarPath | Write-Warning
    }
  }

  if (($Jars -in "Uber", "Both") -and (Assert-ProjectHasUberJar $project)) {
    "Project has an uber jar" | Write-Verbose
    $uberJarPath = Join-Path $buildDirectory "$finalName-jar-with-dependencies.jar"
    if (Test-Path -Path $uberJarPath) {
      $dumpTarget = Join-Path $dumpFolder "$finalName-jar-with-dependencies"
      Expand-Jar $uberJarPath $dumpTarget
    } else {
      "Uber jar not found at {0}" -f $uberJarPath | Write-Warning
    }
  }
}

$mvnOpts = @("-e")
if ($Profiles.Count -gt 0) {
  $mvnOpts += @("-P", ($Profiles -join ","))
}
if ($Projects.Count -gt 0) {
  $mvnOpts += @("-pl", ($Projects -join ","))
}

if ($Rebuild) {
  "Rebuilding project" | Write-Host
  mvn @mvnOpts clean package -DskipTests | Write-Host
}

$startingDirectory = Get-Location
try {
  $tmpFilePath = Get-TempFilePath
  mvn @mvnOpts help:effective-pom -Doutput="$tmpFilePath" | Write-Host
  "Effective POM written to $tmpFilePath" | Write-Verbose
  $dom = [xml](Get-Content -Raw -Path $tmpFilePath)

  if ($dom.project) {
    New-JarDump $dom.project
  } elseif ($dom.projects) {
    $dom.projects.project | ForEach-Object { New-JarDump $_ }
  } else {
    "No project(s) found in effective POM" | Write-Error
  }
} finally {
  Set-Location -Path $startingDirectory
  if (Test-Path -Path $tmpFilePath) {
    Remove-Item -Path $tmpFilePath -Force
  }
}

