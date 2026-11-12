#requires -Version 5.1
<#
.SYNOPSIS
    Désinstalle l'action de menu contextuel « Formater en FAT32 ».

.DESCRIPTION
    Supprime le verbe Shell, le raccourci du menu Démarrer, l'entrée
    « Applications et fonctionnalités » et, sauf -KeepFiles, le dossier d'installation.
    S'auto-élève en administrateur si nécessaire.

.PARAMETER InstallDir
    Dossier d'installation. Par défaut, celui enregistré lors de l'installation.

.PARAMETER Hive
    HKLM (par défaut) ou HKCU.

.PARAMETER KeepFiles
    Conserve les fichiers du dossier d'installation.

.EXAMPLE
    powershell -ExecutionPolicy Bypass -File .\Uninstall-FormatFAT32.ps1
#>
[CmdletBinding()]
param(
    [string]$InstallDir,
    [ValidateSet('HKLM', 'HKCU')][string]$Hive = 'HKLM',
    [switch]$KeepFiles,
    [switch]$Quiet,
    [switch]$Elevated
)

$ErrorActionPreference = 'Stop'

$script:AppName = 'FormatFAT32'
$script:MenuText = 'Formater en FAT32'

function Test-IsAdmin {
    $identity = [Security.Principal.WindowsIdentity]::GetCurrent()
    $principal = New-Object Security.Principal.WindowsPrincipal $identity
    return $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

function Quote-Argument {
    param([string]$Value)
    if ($Value -match '\s') { return '"' + $Value + '"' }
    return $Value
}

function Show-Error {
    param([string]$Text)
    try {
        Add-Type -AssemblyName System.Windows.Forms -ErrorAction Stop
        [System.Windows.Forms.MessageBox]::Show($Text, 'Désinstallation Format FAT32',
            [System.Windows.Forms.MessageBoxButtons]::OK,
            [System.Windows.Forms.MessageBoxIcon]::Error) | Out-Null
    }
    catch {
        Write-Host $Text -ForegroundColor Red
    }
}

try {
    if ($Hive -eq 'HKLM' -and -not (Test-IsAdmin) -and -not $Elevated) {
        $shell = Join-Path $env:SystemRoot 'System32\WindowsPowerShell\v1.0\powershell.exe'
        $arguments = @('-NoProfile', '-ExecutionPolicy', 'Bypass', '-STA',
            '-File', (Quote-Argument $PSCommandPath), '-Hive', $Hive)
        if ($InstallDir) { $arguments += @('-InstallDir', (Quote-Argument $InstallDir)) }
        if ($KeepFiles) { $arguments += '-KeepFiles' }
        if ($Quiet) { $arguments += '-Quiet' }
        $arguments += '-Elevated'
        try {
            Start-Process -FilePath $shell -ArgumentList ($arguments -join ' ') -Verb RunAs -Wait -ErrorAction Stop
        }
        catch {
            Show-Error ("Droits administrateur requis pour désinstaller.`r`n`r`n" + $_.Exception.Message)
            exit 4
        }
        exit 0
    }

    if (-not $Quiet) {
        Write-Host ''
        Write-Host 'Désinstallation de « Formater en FAT32 »' -ForegroundColor Cyan
    }

    $hives = @(
        @{ Hive = 'HKLM'; Root = 'Registry::HKEY_LOCAL_MACHINE\SOFTWARE\Classes'; Arp = 'Registry::HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall'; Menu = (Join-Path $env:ProgramData 'Microsoft\Windows\Start Menu\Programs') },
        @{ Hive = 'HKCU'; Root = 'Registry::HKEY_CURRENT_USER\Software\Classes'; Arp = 'Registry::HKEY_CURRENT_USER\Software\Microsoft\Windows\CurrentVersion\Uninstall'; Menu = (Join-Path $env:APPDATA 'Microsoft\Windows\Start Menu\Programs') }
    )

    # Dossier d'installation : paramètre, sinon valeur enregistrée dans le registre.
    if (-not $InstallDir) {
        foreach ($item in $hives) {
            $candidate = Join-Path $item.Arp $script:AppName
            $recorded = (Get-ItemProperty -Path $candidate -ErrorAction SilentlyContinue).InstallLocation
            if ($recorded -and (Test-Path -LiteralPath $recorded)) {
                $InstallDir = $recorded
                break
            }
        }
    }
    if (-not $InstallDir) {
        if ($Hive -eq 'HKLM') { $InstallDir = Join-Path $env:ProgramFiles $script:AppName }
        else { $InstallDir = Join-Path $env:LOCALAPPDATA $script:AppName }
    }

    $target = $hives | Where-Object { $_.Hive -eq $Hive } | Select-Object -First 1

    $verbPath = Join-Path $target.Root 'Drive\shell\FormatFAT32'
    if (Test-Path -Path $verbPath) {
        Remove-Item -Path $verbPath -Recurse -Force
        if (-not $Quiet) { Write-Host '  Verbe de menu supprimé.' -ForegroundColor DarkGray }
    }
    $arpPath = Join-Path $target.Arp $script:AppName
    if (Test-Path -Path $arpPath) {
        Remove-Item -Path $arpPath -Recurse -Force
        if (-not $Quiet) { Write-Host '  Entrée de désinstallation supprimée.' -ForegroundColor DarkGray }
    }
    $shortcut = Join-Path $target.Menu ("{0}.lnk" -f $script:MenuText)
    if (Test-Path -LiteralPath $shortcut) {
        Remove-Item -LiteralPath $shortcut -Force
        if (-not $Quiet) { Write-Host '  Raccourci supprimé.' -ForegroundColor DarkGray }
    }

    if ($KeepFiles) {
        if (-not $Quiet) { Write-Host ("  Fichiers conservés : {0}" -f $InstallDir) -ForegroundColor DarkGray }
    }
    elseif (Test-Path -LiteralPath $InstallDir) {
        try {
            Remove-Item -LiteralPath $InstallDir -Recurse -Force -ErrorAction Stop
            if (-not $Quiet) { Write-Host ("  Dossier supprimé : {0}" -f $InstallDir) -ForegroundColor DarkGray }
        }
        catch {
            # Le script en cours d'exécution peut verrouiller son propre dossier :
            # suppression différée.
            $command = 'ping -n 3 127.0.0.1 >nul & rmdir /s /q "{0}"' -f $InstallDir
            Start-Process -FilePath (Join-Path $env:SystemRoot 'System32\cmd.exe') -ArgumentList @('/c', $command) -WindowStyle Hidden
            if (-not $Quiet) { Write-Host '  Suppression du dossier planifiée.' -ForegroundColor DarkGray }
        }
    }

    if (-not $Quiet) {
        Write-Host ''
        Write-Host 'Désinstallation terminée.' -ForegroundColor Green
        Write-Host ''
    }
    exit 0
}
catch {
    $message = $_.Exception.Message
    if (-not $Quiet) { Write-Host ("ERREUR : {0}" -f $message) -ForegroundColor Red }
    Show-Error ("Échec de la désinstallation.`r`n`r`n" + $message)
    exit 1
}
