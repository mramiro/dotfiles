#!/usr/bin/env pwsh

<#
.Synopsis
    Convert JSON file(s) to YAML or viceversa.
.Parameter InputPath
    Path to a JSON file.
    If Recurse is used: path to a folder containing JSON files.
.Parameter From
    Format from which to convert from.
    If JSON, will convert to YAML. InputFile(s) must be JSON.
    If YAML, will convert to JSON. InputFile(s) must be YAML.
    Defaults to JSON.
.Parameter OutputPath
    Path where to write to resulting string(s).
    If Recurse is not used: must be a YAML or JSON file.
    If Recurse is used: must be a folder. See Recurse for details.
    Defaults to $null, in which case the resulting string gets returned directly as output.
.Parameter Force
    Overwrite existing file(s). Only used when OutputPath is used.
.Parameter Recurse
    All JSON/YAML files under InputPath and its children are converted to YAML/JSON and written to OutputPath.
    Extensions are removed from original files and replaced with ".yml" or ".json", depending on the value of From.
    Filesystem hierarchy is preserved.
    If passed, OutputPath becomes mandatory.
.Parameter RecurseFilter
    Filtering string to use when searching for JSON/YAML files inside InputPath.
    Defaults to "*.json" if From = "JSON".
    Defaults to "*.yaml<newline>*.yml" if From = "YAML".
.Example
    # Convert a single JSON file to YAML and output the result to STDOUT:
    > ./JsonToYaml.ps1 -InputPath ./settings.json
    
    # Convert a single YAML file to JSON and save the result to disk:
    > ./JsonToYaml.ps1 -From YAML -InputPath ./settings.yml -OutputPath ./settings.json
    
    # Find all JSON files inside a folder and save them to another folder in as YAML files:
    > ./JsonToYaml.ps1 -From JSON -InputPath ./mySettings -OutputPath ./myNewSettings -Recurse
#>

using module powershell-yaml

[CmdletBinding(SupportsShouldProcess=$true)]
param(
    [Parameter(Mandatory=$true)]$InputPath,
    [Parameter(Mandatory=$false)]$OutputPath = $null,
    [Parameter(Mandatory=$false)][ValidateSet("JSON", "YAML")]$From = "JSON",
    [Parameter(Mandatory=$false)][Switch]$Force = $false,
    [Parameter(Mandatory=$false)][Switch]$Recurse = $false,
    [Parameter(Mandatory=$false)][String]$RecurseFilter = ""
)

$ErrorActionPreference = "Stop"

function IsDirectory($path) {
    if ($path -is [System.IO.DirectoryInfo]) {
        return $true
    }
    if ($path -is [System.IO.FileInfo]) {
        return $false
    }
    if ($path -is [String]) {
        return (Test-Path -Path $path -Type "Container")
    }
}

function YamlifyJsonFile($jsonFile) {
    Write-Verbose "Reading JSON file at $jsonFile"
    Get-Content -Raw -Path $jsonFile | ConvertFrom-Json -Depth 20 | ConvertTo-Yaml
}

function JsonifyYamlFile($yamlFile) {
    Write-Verbose "Reading YAML file at $yamlFile"
    Get-Content -Raw -Path $yamlFile | ConvertFrom-Yaml -Ordered | ConvertTo-Json -Depth 20
}

function ConvertFile($file) {
    if ($From -eq "JSON") {
        YamlifyJsonFile $file
    } else {
        JsonifyYamlFile $file
    }
}

function WriteToFile($path, $str) {
    if ((Test-Path -Path $path) -and (-not $Force)) {
        Write-Warning "Not writing to $path because it already exists. Use Force to override."
    } else {
        Write-Verbose "Saving string to $path..."
        $str | Set-Content -Path $path
    }
}

$sourceItem = Get-Item $InputPath
if ($Recurse) {
    $sourceFolder = $sourceItem
    if (-not (IsDirectory $sourceFolder)) {
        Write-Error "Invalid argument. InputPath must be a directory when using Recurse option. Value provided: $InputPath"
    }
    if ($OutputPath -eq $null) {
        Write-Error "Invalid argument. Recurse option requires a valid OutputPath. Value provided: $OutputPath"
    }
    $outputFolder = Get-Item $OutputPath
    if (-not (isDirectory $outputFolder)) {
        Write-Error "Invalid argument. OutputPath must be a directory when using Recurse option. Value provided: $OutputPath"
    }
    Write-Verbose "Reading folder $sourceFolder..."
    $filter = if ($RecurseFilter -eq "") {
        if ($From -eq "JSON") { "*.json" } else { ("*.yaml", "*.yml") }
    } else {
        $RecurseFilter
    }
    $foundItems = $sourceFolder | Get-ChildItem -Recurse -Include $filter
    if ($foundItems.Length -eq 0) {
        Write-Warning "No suitable files found under $sourceFolder"
    }
    $foundItems | ForEach-Object {
        $curFile = $_
        # Convert file string
        $convertedString = ConvertFile $curFile

        $newExtension = if ($From -eq "JSON") { ".yml" } else { ".json" }
        $mockFile = Join-Path $curFile.Directory ($curFile.BaseName + $newExtension)
        $relativePath = [System.IO.Path]::GetRelativePath($sourceFolder, $mockFile)
        $targetPath = [System.IO.FileInfo](Join-Path $outputFolder $relativePath)
        $targetPathFolder = $targetPath.Directory

        # Create folder hierarchy if it doesn't exist already
        if (-not (Test-Path -Path $targetPathFolder)) {
            Write-Verbose "Directory $targetPathFolder. Creating recursively..."
            New-Item -ItemType Directory -Path $targetPathFolder.Parent -Name $targetPathFolder.BaseName -Force | Out-Null
        }
        WriteToFile $targetPath $convertedString
    }
} else {
    $sourceFile = $sourceItem
    if (IsDirectory $sourceFile) {
        Write-Error "Invalid argument. InputPath must be a file unless Recurse option is used. Value provided $InputPath"
    }
    $convertedString = ConvertFile $sourceFile

    if ($OutputPath -ne $null) {
        WriteToFile $OutputPath $convertedString
    } else {
        $convertedString
    }
}
