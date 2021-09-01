#!/usr/bin/env pwsh

function Set-DotEnv() {
    [CmdletBinding(SupportsShouldProcess=$true)]
    param(
        [Parameter(Mandatory=$false)][string]$Path = "./.env",
        [Parameter(Mandatory=$false)][switch]$PassThru = $false,
        [Parameter(Mandatory=$false)][ValidateSet("Process", "User", "Machine")]$Scope = "Process"
    )

    $content = Get-Content $Path -ErrorAction SilentlyContinue
    if (-not $content) {
      Write-Debug "No .env file found at $Path"
      return
    }
    Write-Debug "Parsed $Path"

    $content | ForEach-Object {
        [string]$line = $_.Trim()
        if ([string]::IsNullOrWhiteSpace($line)) {
            Write-Debug "Skipping empty line"
            return
        }
        if ($line.StartsWith("#")){
            Write-Debug "Skipping comment: $line"
            return
        }

        $key, $value = $line -split "=", 2 | ForEach { $_.Trim() }
        if ($value -match '^"[^"]*"$') {
            Write-Debug "Found double-quoted value: $value"
            $value = $value.Trim('"')
        } elseif ($value -match "^'[^']*'$") {
            Write-Debug "Found single-quoted value: $value"
            $value = $value.Trim("'")
        }

        if ($PSCmdlet.ShouldProcess("Environment variable $key", "Set value = $value")) {
            [Environment]::SetEnvironmentVariable($key, $value, $Scope) | Out-Null
        }

        if ($PassThru) {
            Write-Output @{ $key = $value }
        }
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

function Resolve-Error($ErrorRecord=$Error[0])
{
   $ErrorRecord | Format-List * -Force
   $ErrorRecord.InvocationInfo |Format-List *
   $Exception = $ErrorRecord.Exception
   for ($i = 0; $Exception; $i++, ($Exception = $Exception.InnerException))
   {   “$i” * 80
       $Exception |Format-List * -Force
   }
}

# Modules
$installedModules = Get-InstalledModule | Select -ExpandProperty Name
@(
  "PSFzf"
) | ForEach {
  Write-Verbose "Checking if module $_ is installed."
  if ($_ -notIn $installedModules) {
    Write-Verbose "Installing module $_."
    Install-Module -Name $_ -Scope CurrentUser -Force
  }
}
Remove-Variable installedModules

# Input settings
Set-PSReadLineOption -EditMode vi -BellStyle None -ViModeIndicator Cursor
Set-PSReadLineKeyHandler -Key Tab -Function Complete
Set-PsFzfOption -PSReadlineChordProvider 'Ctrl+t' -PSReadlineChordReverseHistory 'Ctrl+r'

# Aliases
Set-Alias rver Resolve-Error
