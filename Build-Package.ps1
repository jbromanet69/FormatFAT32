#requires -Version 5.1
<#
.SYNOPSIS
    Construit l'archive de distribution FormatFAT32.zip.

.DESCRIPTION
    Rassemble les scripts et le README dans dist\FormatFAT32.zip, prêt à être
    envoyé aux collègues. L'archive contient un dossier racine FormatFAT32,
    à décompresser puis à installer avec Install-FormatFAT32.ps1.

.PARAMETER OutputPath
    Chemin de l'archive. Par défaut : dist\FormatFAT32.zip.

.EXAMPLE
    powershell -ExecutionPolicy Bypass -File .\Build-Package.ps1
#>
[CmdletBinding()]
param(
    [string]$OutputPath
)

$ErrorActionPreference = 'Stop'

if (-not $OutputPath) {
    $OutputPath = Join-Path (Join-Path $PSScriptRoot 'dist') 'FormatFAT32.zip'
}

$required = @(
    'Format-RemovableFat32.ps1'
    'Install-FormatFAT32.ps1'
    'Uninstall-FormatFAT32.ps1'
    'README.md'
)
$optional = @('fat32format.exe')

$missing = @($required | Where-Object { -not (Test-Path -LiteralPath (Join-Path $PSScriptRoot $_)) })
if ($missing.Count -gt 0) {
    throw ("Fichiers manquants : " + ($missing -join ', '))
}

$files = @($required) + @($optional | Where-Object { Test-Path -LiteralPath (Join-Path $PSScriptRoot $_) })

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
    foreach ($name in $files) {
        Copy-Item -LiteralPath (Join-Path $PSScriptRoot $name) -Destination (Join-Path $root $name) -Force
    }
    Compress-Archive -Path $root -DestinationPath $OutputPath -CompressionLevel Optimal -Force
}
finally {
    Remove-Item -LiteralPath $staging -Recurse -Force -ErrorAction SilentlyContinue
}

Write-Host ("Archive créée : {0} ({1:N0} octets)" -f $OutputPath, (Get-Item -LiteralPath $OutputPath).Length) -ForegroundColor Green
