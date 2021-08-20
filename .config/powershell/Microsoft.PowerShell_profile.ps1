#!/usr/bin/env pwsh

function Set-DotEnv() {
    [CmdletBinding(SupportsShouldProcess=$true)]
    param(
        [Parameter(Mandatory=$false)][string]$Path = "./.env",
        [Parameter(Mandatory=$false)][switch]$PassThru = $false,
        [Parameter(Mandatory=$false)][ValidateSet("Process", "User", "Machine")]$Scope = "Process"
    )

    $content = Get-Content $Path -ErrorAction SilentlyContinue
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

function Get-CmdletAlias ($cmdletname) {
  Get-Alias | Where-Object -FilterScript { $_.Definition -like "$cmdletname" } | Format-Table -Property Definition, Name -AutoSize
}

function Test-Elevated {
  $identity = [System.Security.Principal.WindowsIdentity]::GetCurrent()
  $principal = New-Object System.Security.Principal.WindowsPrincipal($identity)
  $adminRole = [System.Security.Principal.WindowsBuiltInRole]::Administrator
  return $principal.IsInRole($adminRole)
}

function Resolve-Error ($ErrorRecord=$Error[0])
{
   $ErrorRecord | Format-List * -Force
   $ErrorRecord.InvocationInfo |Format-List *
   $Exception = $ErrorRecord.Exception
   for ($i = 0; $Exception; $i++, ($Exception = $Exception.InnerException))
   {   “$i” * 80
       $Exception |Format-List * -Force
   }
}
Set-Alias rver Resolve-Error

$psReadlineArgs = @{
    "EditMode" = "vi"
    "BellStyle" = "None"
    "ViModeIndicator" = "Cursor"
    # "ViModeIndicator" = "Script"
    # "ViModeChangeHandler" = {
    #     if ($args[0] -eq 'Command') {
    #         # Set the cursor to a blinking block.
    #         Write-Host -NoNewLine "`e[1 q"
    #     } else {
    #         # Set the cursor to a blinking line.
    #         Write-Host -NoNewLine "`e[5 q"
    #     }
    # }
}
Set-PSReadLineOption @psReadlineArgs
Set-PSReadLineKeyHandler -Key Tab -Function Complete

if (Get-Command "Set-PsFzfOption") {
    Set-PsFzfOption -PSReadlineChordProvider 'Ctrl+t' -PSReadlineChordReverseHistory 'Ctrl+r'
}
