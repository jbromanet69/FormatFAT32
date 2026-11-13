#requires -Version 5.1
<#
.SYNOPSIS
    Construit l'archive portable FormatFAT32 (dossier + ZIP).

.DESCRIPTION
    Rassemble les scripts, les fichiers de langue, le lanceur et la documentation
    dans dist\FormatFAT32-<version>-portable.zip, prêt à être envoyé aux collègues.
    L'archive contient un dossier racine FormatFAT32, à décompresser puis à
    installer avec Install-FormatFAT32.ps1.

    Pour un installateur classique (menu Démarrer, Applications et fonctionnalités),
    utiliser plutôt installer\FormatFAT32.iss avec Inno Setup 6.

.PARAMETER OutputPath
    Chemin de l'archive. Par défaut : dist\FormatFAT32-<version>-portable.zip.

.PARAMETER Version
    Version reportée dans le nom de l'archive. Par défaut : lue depuis
    Install-FormatFAT32.ps1.

.EXAMPLE
    powershell -ExecutionPolicy Bypass -File .\Build-Package.ps1
#>
[CmdletBinding()]
param(
    [string]$OutputPath,
    [string]$Version
)

$ErrorActionPreference = 'Stop'

if (-not $Version) {
    $installer = Join-Path $PSScriptRoot 'Install-FormatFAT32.ps1'
    $match = Select-String -LiteralPath $installer -Pattern "\`$script:Version\s*=\s*'([0-9.]+)'" | Select-Object -First 1
    $Version = if ($match) { $match.Matches[0].Groups[1].Value } else { '0.0.0' }
}

if (-not $OutputPath) {
    $OutputPath = Join-Path (Join-Path $PSScriptRoot 'dist') ("FormatFAT32-{0}-portable.zip" -f $Version)
}

$required = @(
    'Format-RemovableFat32.ps1'
    'Launch-FormatFAT32.vbs'
    'Install-FormatFAT32.ps1'
    'Uninstall-FormatFAT32.ps1'
    'FormatFAT32.ico'
    'LICENSE'
    'README.md'
    'README.fr.md'
)

$missing = @($required | Where-Object { -not (Test-Path -LiteralPath (Join-Path $PSScriptRoot $_)) })
if ($missing.Count -gt 0) {
    throw ("Fichiers manquants : " + ($missing -join ', '))
}

$languageFiles = @(Get-ChildItem -LiteralPath (Join-Path $PSScriptRoot 'lang') -Filter '*.psd1' -ErrorAction SilentlyContinue)
if ($languageFiles.Count -eq 0) {
    throw 'Aucun fichier de langue trouvé dans .\lang'
}

$outDir = Split-Path -Parent $OutputPath
if (-not (Test-Path -LiteralPath $outDir)) {
    New-Item -ItemType Directory -Path $outDir -Force | Out-Null
}
if (Test-Path -LiteralPath $OutputPath) {
    Remove-Item -LiteralPath $OutputPath -Force
}

$staging = Join-Path ([System.IO.Path]::GetTempPath()) ('FormatFAT32-build-' + [guid]::NewGuid().ToString('N'))
$root = Join-Path $staging 'FormatFAT32'
New-Item -ItemType Directory -Path $root -Force | Out-Null
try {
    foreach ($name in $required) {
        Copy-Item -LiteralPath (Join-Path $PSScriptRoot $name) -Destination (Join-Path $root $name) -Force
    }

    $langDir = Join-Path $root 'lang'
    New-Item -ItemType Directory -Path $langDir -Force | Out-Null
    foreach ($file in $languageFiles) {
        Copy-Item -LiteralPath $file.FullName -Destination (Join-Path $langDir $file.Name) -Force
    }

    Compress-Archive -Path $root -DestinationPath $OutputPath -CompressionLevel Optimal -Force
}
finally {
    Remove-Item -LiteralPath $staging -Recurse -Force -ErrorAction SilentlyContinue
}

Write-Host ("Archive créée : {0} ({1:N0} octets, version {2})" -f $OutputPath, (Get-Item -LiteralPath $OutputPath).Length, $Version) -ForegroundColor Green
