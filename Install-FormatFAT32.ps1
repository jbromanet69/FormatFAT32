#requires -Version 5.1
<#
.SYNOPSIS
    Installe l'action de menu contextuel « Formater en FAT32 » pour les disques amovibles.

.DESCRIPTION
    Copie les scripts dans Program Files, enregistre le verbe Shell sous Drive\shell
    (visible pour tous les utilisateurs), crée un raccourci dans le menu Démarrer et
    une entrée « Applications et fonctionnalités ». S'auto-élève en administrateur.

.PARAMETER InstallDir
    Dossier d'installation. Par défaut : %ProgramFiles%\FormatFAT32 (HKLM)
    ou %LOCALAPPDATA%\FormatFAT32 (HKCU).

.PARAMETER Hive
    HKLM (par défaut, tous les utilisateurs) ou HKCU (installation par utilisateur).

.PARAMETER Publisher
    Éditeur affiché dans « Applications et fonctionnalités ». Omis par défaut.

.PARAMETER NoShortcut
    Ne pas créer le raccourci du menu Démarrer.

.PARAMETER Quiet
    Sortie minimale.

.EXAMPLE
    powershell -ExecutionPolicy Bypass -File .\Install-FormatFAT32.ps1

.EXAMPLE
    powershell -ExecutionPolicy Bypass -File .\Install-FormatFAT32.ps1 -Hive HKCU -NoShortcut
#>
[CmdletBinding()]
param(
    [string]$InstallDir,
    [ValidateSet('HKLM', 'HKCU')][string]$Hive = 'HKLM',
    [ValidateSet('en', 'fr', 'de', 'es', 'it', 'pt', 'nl')][string]$Language,
    [string]$Publisher,
    [switch]$NoShortcut,
    [switch]$Quiet,
    [switch]$Elevated
)

$ErrorActionPreference = 'Stop'

$script:AppName = 'FormatFAT32'
$script:Version = '1.2.1'
$script:MenuText = 'Formater en FAT32'

function Test-IsAdmin {
    $identity = [Security.Principal.WindowsIdentity]::GetCurrent()
    $principal = New-Object Security.Principal.WindowsPrincipal $identity
    return $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

function ConvertTo-QuotedArgument {
    param([string]$Value)
    if ($Value -match '\s') { return '"' + $Value + '"' }
    return $Value
}

function Show-Error {
    param([string]$Text)
    try {
        Add-Type -AssemblyName System.Windows.Forms -ErrorAction Stop
        [System.Windows.Forms.MessageBox]::Show($Text, 'Installation Format FAT32',
            [System.Windows.Forms.MessageBoxButtons]::OK,
            [System.Windows.Forms.MessageBoxIcon]::Error) | Out-Null
    }
    catch {
        Write-Host $Text -ForegroundColor Red
    }
}

function Write-Step {
    param([string]$Text)
    if ($Quiet) { return }
    foreach ($line in ($Text -split "`r?`n")) {
        Write-Host ("  {0}" -f $line) -ForegroundColor DarkGray
    }
}

function Get-WindowsFat32Support {
    $props = Get-ItemProperty -Path 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion' -ErrorAction SilentlyContinue
    $build = 0
    $ubr = 0
    if ($props -and $props.CurrentBuildNumber) {
        $build = [int]$props.CurrentBuildNumber
        if ($null -ne $props.UBR) { $ubr = [int]$props.UBR }
    }
    else {
        $build = [Environment]::OSVersion.Version.Build
    }
    $display = if ($props -and $props.DisplayVersion) { [string]$props.DisplayVersion } else { '' }
    return [pscustomobject]@{
        Build              = $build
        UBR                = $ubr
        VersionText        = ("Windows {0} build {1}.{2}" -f $display, $build, $ubr).Trim()
        SupportsLargeFat32 = (($build -eq 26100) -and ($ubr -ge 8313)) -or ($build -ge 26200)
    }
}

try {
    if ($Hive -eq 'HKLM' -and -not (Test-IsAdmin) -and -not $Elevated) {
        $shell = Join-Path $env:SystemRoot 'System32\WindowsPowerShell\v1.0\powershell.exe'
        $arguments = @('-NoProfile', '-ExecutionPolicy', 'Bypass', '-STA',
            '-File', (ConvertTo-QuotedArgument $PSCommandPath), '-Hive', $Hive)
        if ($InstallDir) { $arguments += @('-InstallDir', (ConvertTo-QuotedArgument $InstallDir)) }
        if ($Publisher) { $arguments += @('-Publisher', (ConvertTo-QuotedArgument $Publisher)) }
        if ($Language) { $arguments += @('-Language', $Language) }
        if ($NoShortcut) { $arguments += '-NoShortcut' }
        if ($Quiet) { $arguments += '-Quiet' }
        $arguments += '-Elevated'
        try {
            Start-Process -FilePath $shell -ArgumentList ($arguments -join ' ') -Verb RunAs -Wait -ErrorAction Stop
        }
        catch {
            Show-Error ("Droits administrateur requis pour installer l'action de menu.`r`n`r`n" + $_.Exception.Message)
            exit 4
        }
        exit 0
    }

    if ($Hive -eq 'HKLM' -and -not (Test-IsAdmin)) {
        throw "L'installation dans HKLM exige des droits administrateur."
    }

    # --- Sources -----------------------------------------------------------
    $sourceScript = Join-Path $PSScriptRoot 'Format-RemovableFat32.ps1'
    $sourceUninstall = Join-Path $PSScriptRoot 'Uninstall-FormatFAT32.ps1'
    foreach ($required in @($sourceScript, $sourceUninstall)) {
        if (-not (Test-Path -LiteralPath $required)) {
            throw "Fichier introuvable : $required`r`nPlacez l'installateur dans le dossier complet de l'outil."
        }
    }

    # Contrôle de syntaxe avant toute copie.
    foreach ($source in @($sourceScript, $sourceUninstall)) {
        $tokens = $null
        $errors = $null
        $null = [System.Management.Automation.Language.Parser]::ParseFile($source, [ref]$tokens, [ref]$errors)
        if ($errors -and $errors.Count -gt 0) {
            throw ("Erreurs de syntaxe dans {0} :`r`n{1}" -f (Split-Path -Leaf $source), (($errors | ForEach-Object { $_.Message }) -join "`r`n"))
        }
    }

    # --- Dossier cible -----------------------------------------------------
    if (-not $InstallDir) {
        if ($Hive -eq 'HKLM') {
            $InstallDir = Join-Path $env:ProgramFiles $script:AppName
        }
        else {
            $InstallDir = Join-Path $env:LOCALAPPDATA $script:AppName
        }
    }
    if (-not (Test-Path -LiteralPath $InstallDir)) {
        New-Item -ItemType Directory -Path $InstallDir -Force | Out-Null
    }
    $InstallDir = (Resolve-Path -LiteralPath $InstallDir).Path

    if (-not $Quiet) {
        Write-Host ''
        Write-Host ("Installation de « {0} » {1}" -f $script:MenuText, $script:Version) -ForegroundColor Cyan
        Write-Host ("  Destination : {0}" -f $InstallDir)
        Write-Host ("  Portée      : {0}" -f $(if ($Hive -eq 'HKLM') { 'tous les utilisateurs (HKLM)' } else { 'utilisateur courant (HKCU)' }))
    }

    # --- Copie des fichiers ------------------------------------------------
    $targetScript = Join-Path $InstallDir 'Format-RemovableFat32.ps1'
    $targetUninstall = Join-Path $InstallDir 'Uninstall-FormatFAT32.ps1'
    Copy-Item -LiteralPath $sourceScript -Destination $targetScript -Force
    Copy-Item -LiteralPath $sourceUninstall -Destination $targetUninstall -Force

    $sourceVbs = Join-Path $PSScriptRoot 'Launch-FormatFAT32.vbs'
    if (-not (Test-Path -LiteralPath $sourceVbs)) { throw "Fichier introuvable : $sourceVbs" }
    $targetVbs = Join-Path $InstallDir 'Launch-FormatFAT32.vbs'
    Copy-Item -LiteralPath $sourceVbs -Destination $targetVbs -Force

    $sourceLang = Join-Path $PSScriptRoot 'lang'
    if (-not (Test-Path -LiteralPath $sourceLang)) { throw "Dossier introuvable : $sourceLang" }
    $targetLang = Join-Path $InstallDir 'lang'
    if (-not (Test-Path -LiteralPath $targetLang)) { New-Item -ItemType Directory -Path $targetLang -Force | Out-Null }
    Copy-Item -Path (Join-Path $sourceLang '*.psd1') -Destination $targetLang -Force

    $uiLanguage = if ($Language) { $Language } else { [System.Globalization.CultureInfo]::CurrentUICulture.TwoLetterISOLanguageName.ToLowerInvariant() }
    if ($uiLanguage.Length -gt 2) { $uiLanguage = $uiLanguage.Substring(0, 2) }
    if (-not (Test-Path -LiteralPath (Join-Path $targetLang ("{0}.psd1" -f $uiLanguage)))) { $uiLanguage = 'en' }
    Set-Content -LiteralPath (Join-Path $InstallDir 'language.txt') -Value $uiLanguage -Encoding ASCII
    Write-Step ("Langue de l'interface : {0}" -f $uiLanguage)
    Write-Step 'Scripts copiés.'

    foreach ($doc in @('README.md', 'README.fr.md', 'LICENSE')) {
        $sourceDoc = Join-Path $PSScriptRoot $doc
        if (Test-Path -LiteralPath $sourceDoc) {
            Copy-Item -LiteralPath $sourceDoc -Destination (Join-Path $InstallDir $doc) -Force
        }
    }

    # --- Entrée de menu contextuel ----------------------------------------
    if ($Hive -eq 'HKLM') {
        $classesRoot = 'Registry::HKEY_LOCAL_MACHINE\SOFTWARE\Classes'
        $arpRoot = 'Registry::HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall'
        $startMenu = Join-Path $env:ProgramData 'Microsoft\Windows\Start Menu\Programs'
    }
    else {
        $classesRoot = 'Registry::HKEY_CURRENT_USER\Software\Classes'
        $arpRoot = 'Registry::HKEY_CURRENT_USER\Software\Microsoft\Windows\CurrentVersion\Uninstall'
        $startMenu = Join-Path $env:APPDATA 'Microsoft\Windows\Start Menu\Programs'
    }

    $verbPath = Join-Path $classesRoot 'Drive\shell\FormatFAT32'
    $commandPath = Join-Path $verbPath 'command'
    New-Item -Path $commandPath -Force | Out-Null

    $shellExe = Join-Path $env:SystemRoot 'System32\WindowsPowerShell\v1.0\powershell.exe'
    $iconPath = Join-Path $env:SystemRoot 'System32\shell32.dll'
    $commandLine = '"{0}" "{1}" "%1"' -f (Join-Path $env:SystemRoot 'System32\wscript.exe'), $targetVbs

    New-ItemProperty -Path $verbPath -Name 'MUIVerb' -Value $script:MenuText -PropertyType String -Force | Out-Null
    New-ItemProperty -Path $verbPath -Name 'Icon' -Value ('{0},-7' -f $iconPath) -PropertyType String -Force | Out-Null
    Set-Item -Path $commandPath -Value $commandLine
    Write-Step 'Entrée de menu contextuel enregistrée (Drive\shell\FormatFAT32).'

    # --- Raccourci du menu Démarrer ---------------------------------------
    $shortcutPath = $null
    if (-not $NoShortcut) {
        if (-not (Test-Path -LiteralPath $startMenu)) {
            New-Item -ItemType Directory -Path $startMenu -Force | Out-Null
        }
        $shortcutPath = Join-Path $startMenu ("{0}.lnk" -f $script:MenuText)
        $wsh = New-Object -ComObject WScript.Shell
        $shortcut = $wsh.CreateShortcut($shortcutPath)
        $shortcut.TargetPath = (Join-Path $env:SystemRoot 'System32\wscript.exe')
        $shortcut.Arguments = '"{0}"' -f $targetVbs
        $shortcut.WorkingDirectory = $InstallDir
        $shortcut.IconLocation = '{0},7' -f $iconPath
        $shortcut.Description = 'Formater une carte SD ou une clé USB en FAT32'
        $shortcut.Save()
        Write-Step ("Raccourci créé : {0}" -f $shortcutPath)
    }

    # --- Désinstallation (Applications et fonctionnalités) ----------------
    $arpPath = Join-Path $arpRoot $script:AppName
    New-Item -Path $arpPath -Force | Out-Null
    $uninstallCommand = '"{0}" -NoProfile -ExecutionPolicy Bypass -WindowStyle Hidden -STA -File "{1}" -Hive {2}' -f $shellExe, $targetUninstall, $Hive

    New-ItemProperty -Path $arpPath -Name 'DisplayName' -Value 'Formater en FAT32 (menu contextuel)' -PropertyType String -Force | Out-Null
    New-ItemProperty -Path $arpPath -Name 'DisplayVersion' -Value $script:Version -PropertyType String -Force | Out-Null
    New-ItemProperty -Path $arpPath -Name 'InstallLocation' -Value $InstallDir -PropertyType String -Force | Out-Null
    New-ItemProperty -Path $arpPath -Name 'DisplayIcon' -Value ('{0},7' -f $iconPath) -PropertyType String -Force | Out-Null
    New-ItemProperty -Path $arpPath -Name 'UninstallString' -Value $uninstallCommand -PropertyType String -Force | Out-Null
    New-ItemProperty -Path $arpPath -Name 'NoModify' -Value 1 -PropertyType DWord -Force | Out-Null
    New-ItemProperty -Path $arpPath -Name 'NoRepair' -Value 1 -PropertyType DWord -Force | Out-Null
    if ($Publisher) {
        New-ItemProperty -Path $arpPath -Name 'Publisher' -Value $Publisher -PropertyType String -Force | Out-Null
    }
    Write-Step 'Entrée de désinstallation enregistrée.'

    # --- Vérifications -----------------------------------------------------
    $checks = @()
    $checks += [pscustomobject]@{ Test = 'Script installé'; Ok = (Test-Path -LiteralPath $targetScript) }
    $checks += [pscustomobject]@{ Test = 'Désinstalleur installé'; Ok = (Test-Path -LiteralPath $targetUninstall) }
    $checks += [pscustomobject]@{ Test = 'Lanceur sans console installé'; Ok = (Test-Path -LiteralPath (Join-Path $InstallDir 'Launch-FormatFAT32.vbs')) }
    $checks += [pscustomobject]@{ Test = 'Fichiers de langue installés'; Ok = ((Get-ChildItem -LiteralPath (Join-Path $InstallDir 'lang') -Filter '*.psd1' -ErrorAction SilentlyContinue).Count -ge 7) }
    $checks += [pscustomobject]@{ Test = 'Verbe enregistré'; Ok = ((Get-ItemProperty -Path $verbPath -ErrorAction SilentlyContinue).MUIVerb -eq $script:MenuText) }
    $checks += [pscustomobject]@{ Test = 'Commande enregistrée'; Ok = ((Get-Item -Path $commandPath).GetValue('') -like '*Launch-FormatFAT32.vbs*') }
    if ($shortcutPath) {
        $checks += [pscustomobject]@{ Test = 'Raccourci créé'; Ok = (Test-Path -LiteralPath $shortcutPath) }
    }

    $selfTestOutput = & $shellExe -NoProfile -ExecutionPolicy Bypass -File $targetScript -SelfTest 2>&1 | Out-String
    $selfTestOk = ($LASTEXITCODE -eq 0)
    $checks += [pscustomobject]@{ Test = 'Auto-test du script'; Ok = $selfTestOk }

    $failed = @($checks | Where-Object { -not $_.Ok })
    if (-not $Quiet) {
        Write-Host ''
        $checks | ForEach-Object {
            $color = if ($_.Ok) { 'Green' } else { 'Red' }
            $mark = if ($_.Ok) { '[OK]   ' } else { '[ÉCHEC]' }
            Write-Host ("  {0} {1}" -f $mark, $_.Test) -ForegroundColor $color
        }
        if ($selfTestOutput.Trim()) { Write-Step $selfTestOutput.Trim() }
    }

    $windows = Get-WindowsFat32Support
    if (-not $Quiet) {
        Write-Host ''
        if ($windows.SupportsLargeFat32) {
            Write-Host ("  Système : {0} — FAT32 au-delà de 32 Go pris en charge." -f $windows.VersionText) -ForegroundColor Green
        }
        else {
            Write-Host ("  Système : {0}" -f $windows.VersionText) -ForegroundColor Yellow
            Write-Host '  ATTENTION : sur cette version, Windows ne crée pas de FAT32 au-delà de 32 Go.' -ForegroundColor Yellow
            Write-Host '  Il faut Windows 11 24H2 build 26100.8313 ou 25H2 build 26200.8313 (ou ultérieure).' -ForegroundColor Yellow
            Write-Host '  L''outil restera utilisable pour les volumes de 32 Go ou moins.' -ForegroundColor Yellow
        }
    }

    if ($failed.Count -gt 0) {
        throw ("Installation incomplète : " + (($failed | ForEach-Object { $_.Test }) -join ', '))
    }

    if (-not $Quiet) {
        Write-Host ''
        Write-Host 'Installation terminée.' -ForegroundColor Green
        Write-Host ''
        Write-Host "Utilisation : clic droit sur un disque dans l'Explorateur." -ForegroundColor Gray
        Write-Host 'Sur Windows 11, l''entrée se trouve dans « Afficher plus d''options »' -ForegroundColor Gray
        Write-Host '(ou Maj+F10). Un raccourci est aussi disponible dans le menu Démarrer.' -ForegroundColor Gray
        Write-Host ''
    }

    exit 0
}
catch {
    $message = $_.Exception.Message
    if (-not $Quiet) { Write-Host ("ERREUR : {0}" -f $message) -ForegroundColor Red }
    Show-Error ("Échec de l'installation.`r`n`r`n" + $message)
    exit 1
}
