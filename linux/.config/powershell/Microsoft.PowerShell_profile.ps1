#!/usr/bin/env pwsh

function Get-DotEnv() {
  param(
    [Parameter(Mandatory=$false)][string]$Path = "./.env"
  )
  $content = Get-Content $Path -ErrorAction SilentlyContinue
  if (-not $content) {
    Write-Verbose "No .env file found at $Path"
    return
  }
  Write-Verbose "Parsed $Path"

  $variables = @{}
  $content | ForEach-Object {
    [string]$line = $_.Trim()
    if ([string]::IsNullOrWhiteSpace($line)) {
      Write-Verbose "Skipping empty line"
      return
    }
    if ($line.StartsWith("#")){
      Write-Verbose "Skipping comment: $line"
      return
    }

    $key, $value = $line -split "=", 2 | ForEach-Object { $_.Trim() }
    if ($value -match '^"[^"]*"$') {
      Write-Verbose "Found double-quoted value: $value"
      $value = $value.Trim('"')
    } elseif ($value -match "^'[^']*'$") {
      Write-Verbose "Found single-quoted value: $value"
      $value = $value.Trim("'")
    }
    $variables[$key] = $value
  }
  return $variables
}

function Set-DotEnv() {
  [CmdletBinding(SupportsShouldProcess=$true)]
  param(
    [Parameter(Mandatory=$false)][string]$Path = "./.env",
    [Parameter(Mandatory=$false)][switch]$PassThru = $false,
    [Parameter(Mandatory=$false)][ValidateSet("Process", "User", "Machine")]$Scope = "Process"
  )

  $variables = Get-DotEnv $Path
  foreach ($key in $variables.Keys) {
    $value = $variables[$key]
    if ($PSCmdlet.ShouldProcess("Environment variable $key", "Set value = $value")) {
      [Environment]::SetEnvironmentVariable($key, $value, $Scope) | Out-Null
    }
  }
  if ($PassThru) {
    return $variables
  }
}

function Assert-Guid([string]$string) {
    return $string -match "(?i)^[0-9A-F]{8}[-]?(?:[0-9A-F]{4}[-]?){3}[0-9A-F]{12}$"
}

function Get-CmdletAlias($cmdletname) {
  Get-Alias | Where-Object -FilterScript { $_.Definition -like "$cmdletname" } | Format-Table -Property Definition, Name -AutoSize
}

function Test-Elevated {
  if ($IsWindows) {
    $identity = [System.Security.Principal.WindowsIdentity]::GetCurrent()
    $principal = New-Object System.Security.Principal.WindowsPrincipal($identity)
    $adminRole = [System.Security.Principal.WindowsBuiltInRole]::Administrator
    return $principal.IsInRole($adminRole)
  }
  return (whoami) -eq "root"
}

function Trace-Exception() {
  param(
    [Parameter(Mandatory=$false)]$Exception = $Error[0].Exception
  )
  while ($Exception) {
    $Exception
    $Exception = $Exception.InnerException
  }
}

function Trace-Error() {
  param(
    [Parameter(Mandatory=$false)]$ErrorRecord = $Error[0]
  )
  $ErrorRecord | Format-List * -Force
  $ErrorRecord.InvocationInfo | Format-List * -Force
  Trace-Exception $ErrorRecord.Exception | Format-List * -Force
}

# Modules
function Install-UserModules() {
  [CmdletBinding(SupportsShouldProcess=$true)]
  param(
    [Parameter(Mandatory=$false)][switch]$PassThru = $false
  )
  $installedModules = Get-InstalledModule | Select-Object -ExpandProperty Name
  @(
    "PSFzf"
  ) | ForEach-Object {
    Write-Verbose "Checking if module $_ is installed."
    if ($_ -notIn $installedModules) {
      Write-Verbose "Installing module $_."
      if ($PSCmdlet.ShouldProcess("Install module $_")) {
        $extraFlags = if ($PassThru) { @{"PassThru" = $true} } else { @{} }
        Install-Module -Name $_ -Scope CurrentUser -Force @extraFlags
      }
    }
  }
}

function Get-AzContextFile() {
  $settings = Get-AzContextAutosaveSetting
  if ($settings.ContextDirectory -and $settings.ContextFile) {
    return Join-Path $settings.ContextDirectory $settings.ContextFile
  }
  Write-Error "AzContext configuration file not defined"
}

function Get-DevModule {
  param(
    [Parameter(Mandatory=$false)]$Name = $null
  )
  $modules = if ($null -ne $Name) {
    Get-Module -Name $Name
  } else {
    # TODO: Recursive search here
    Get-Module -All
  }
  $modules | Where-Object {
    $_.ModuleType -eq [System.Management.Automation.ModuleType]::Script `
    -and $_.Guid.Guid -eq "00000000-0000-0000-0000-000000000000"
  }
}

function Remove-DevModule {
  Get-DevModule | ForEach-Object {
    "Removing module {0}" -f $_ | Write-Verbose
    Remove-Module $_
  }
}

function Sync-DevModule {
  param(
    [Parameter(Mandatory=$false)]$Module = $null
  )
  [Array]$modules = if ($null -eq $Module) {
    Get-DevModule
  } elseif ($Module -is [System.Management.Automation.PSModuleInfo]) {
    $Module
  } else {
    Get-DevModule -Name $Module
  }

  $modules | ForEach-Object {
    $modulePath = $_.Path
    $_ | Remove-Module
    Import-Module $modulePath
  }
}

function Copy-Object {
  param(
    [Parameter(Mandatory,ValueFromPipeline)]$Object
  )
  # Shallow copy
  $Object | Select-Object -Property *;
  # [System.Management.Automation.PSSerializer]::Deserialize(
  #   [System.Management.Automation.PSSerializer]::Serialize($Object)
  # )
}

function Expand-Property {
  [CmdletBinding()]
  param(
    [Parameter(Mandatory)][String]$PropertyName,
    [Parameter(Mandatory, ValueFromPipeline)]$Object,
    [Parameter(Mandatory=$false)][Alias("epl")][String]$ExpandedPropertyListVariable
  )
  # TODO: Make this work for all primitives
  if ($property -Is [String]) {
    return $Object
  }
  $clone = Copy-Object $Object
  $property = $clone.$PropertyName
  $innerPropNames = if ($property -Is [System.Collections.IDictionary]) {
    $property.get_Keys()
  } else {
    $property | Get-Member -Type Property | ForEach-Object { $_.Name }
  }
  $newNames = @()
  foreach ($name in $innerPropNames) {
    $newName = $PropertyName + "_" + $name
    $clone | Add-Member -NotePropertyName $newName -NotePropertyValue $property.$name
    $newNames = $newNames += $newName
  }
  if ($ExpandedPropertyListVariable) {
    Set-Variable -Name $ExpandedPropertyListVariable -Value $newNames -Scope 1
  }
  $clone
}

# PATH
if (Test-Path -Type Container -Path "~/.local/bin") {
  $Env:Path = "{0};{1}" -f $Env:Path, (Resolve-Path -Path "~/.local/bin")
}

# Input settings
Set-PSReadLineOption -EditMode vi -BellStyle None -ViModeIndicator Cursor
Set-PSReadLineKeyHandler -Key Tab -Function Complete
if ((Get-Command -Name "Set-PsFzfOption" -ErrorAction SilentlyContinue) -and (Get-Command -Name "fzf" -ErrorAction SilentlyContinue)) {
  Set-PSFzfOption -PSReadlineChordProvider 'Ctrl+t' -PSReadlineChordReverseHistory 'Ctrl+r' -ErrorAction "Continue"
}

# Aliases
Set-Alias setazc Set-AzContext
Set-Alias getazc Get-AzContext
Set-Alias selazc Select-AzContext

Register-ArgumentCompleter -Native -CommandName az -ScriptBlock {
    param($commandName, $wordToComplete, $cursorPosition)
    $completion_file = New-TemporaryFile
    $env:ARGCOMPLETE_USE_TEMPFILES = 1
    $env:_ARGCOMPLETE_STDOUT_FILENAME = $completion_file
    $env:COMP_LINE = $wordToComplete
    $env:COMP_POINT = $cursorPosition
    $env:_ARGCOMPLETE = 1
    $env:_ARGCOMPLETE_SUPPRESS_SPACE = 0
    $env:_ARGCOMPLETE_IFS = "`n"
    az 2>&1 | Out-Null
    Get-Content $completion_file | Sort-Object | ForEach-Object {
        [System.Management.Automation.CompletionResult]::new($_, $_, "ParameterValue", $_)
    }
    Remove-Item $completion_file, Env:\_ARGCOMPLETE_STDOUT_FILENAME, Env:\ARGCOMPLETE_USE_TEMPFILES, Env:\COMP_LINE, Env:\COMP_POINT, Env:\_ARGCOMPLETE, Env:\_ARGCOMPLETE_SUPPRESS_SPACE, Env:\_ARGCOMPLETE_IFS
}
