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

    $key, $value = $line -split "=", 2 | ForEach { $_.Trim() }
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
  $installedModules = Get-InstalledModule | Select -ExpandProperty Name
  @(
    "PSFzf"
  ) | ForEach {
    Write-Verbose "Checking if module $_ is installed."
    if ($_ -notIn $installedModules) {
      Write-Verbose "Installing module $_."
      if ($PSCmdlet.ShouldProcess("Install module $_")) {
        $extraFlags = $PassThru ? @{"PassThru" = $true} : @{}
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

# Input settings
Set-PSReadLineOption -EditMode vi -BellStyle None -ViModeIndicator Cursor
Set-PSReadLineKeyHandler -Key Tab -Function Complete
Set-PSFzfOption -PSReadlineChordProvider 'Ctrl+t' -PSReadlineChordReverseHistory 'Ctrl+r' -ErrorAction "Continue"

# Aliases
# Set-Alias rver Resolve-Error
Set-Alias sazc Set-AzContext
Set-Alias gazc Get-AzContext
Set-Alias pazc Select-AzContext
