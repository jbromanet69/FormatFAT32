#requires -Version 5.1
<#
.SYNOPSIS
    Formate en FAT32 un disque amovible (carte SD, clé USB), en formatage rapide.

.DESCRIPTION
    Cible uniquement les volumes amovibles (sauf -AllowFixed), demande une confirmation,
    lance format.com /FS:FAT32, vérifie le résultat et affiche un compte rendu.
    S'élève automatiquement en administrateur (UAC) si nécessaire.
    Un journal est écrit dans %ProgramData%\FormatFAT32\logs.

.PARAMETER Drive
    Lettre du lecteur ("E", "E:", "E:\"). Si omis, une fenêtre de sélection s'ouvre.

.PARAMETER Label
    Nouveau libellé du volume (11 caractères max). Par défaut, le libellé actuel est conservé.

.PARAMETER ClusterSizeKb
    Taille de cluster en Ko. Par défaut, Windows choisit.

.PARAMETER AllowFixed
    Autorise aussi les disques fixes (déconseillé). Le disque système est toujours refusé.

.PARAMETER Yes
    Ne pas afficher la confirmation (automatisation).

.PARAMETER DryRun
    Affiche le plan d'action sans rien formater (sortie console).

.PARAMETER SelfTest
    Vérifie que le script et WinForms sont opérationnels, puis quitte.

.EXAMPLE
    .\Format-RemovableFat32.ps1 -Drive E:

.EXAMPLE
    .\Format-RemovableFat32.ps1 -Drive E: -DryRun
#>
[CmdletBinding()]
param(
    [Parameter(Position = 0)]
    [string]$Drive,

    [string]$Label,

    [int]$ClusterSizeKb = 0,

    [switch]$AllowFixed,
    [switch]$Yes,
    [switch]$DryRun,
    [switch]$SelfTest,
    [switch]$Elevated
)

$ErrorActionPreference = 'Stop'
$LASTEXITCODE = 0

$script:AppName = 'FormatFAT32'
$script:LogFile = $null

# --------------------------------------------------------------------------
# Infrastructure
# --------------------------------------------------------------------------

function Test-IsAdmin {
    $identity = [Security.Principal.WindowsIdentity]::GetCurrent()
    $principal = New-Object Security.Principal.WindowsPrincipal $identity
    return $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

function Initialize-Log {
    $stamp = Get-Date -Format 'yyyyMMdd-HHmmss'
    $candidates = @()
    if (Test-IsAdmin) {
        $candidates += (Join-Path $env:ProgramData "$($script:AppName)\logs")
    }
    $candidates += (Join-Path $env:LOCALAPPDATA "$($script:AppName)\logs")
    $candidates += (Join-Path $env:TEMP "$($script:AppName)-logs")
    foreach ($dir in $candidates) {
        try {
            if (-not (Test-Path -LiteralPath $dir)) {
                New-Item -ItemType Directory -Path $dir -Force | Out-Null
            }
            $probe = Join-Path $dir '.write-test'
            Set-Content -LiteralPath $probe -Value 'ok' -Encoding ASCII -ErrorAction Stop
            Remove-Item -LiteralPath $probe -Force -ErrorAction SilentlyContinue
            $script:LogFile = Join-Path $dir ("format-{0}.log" -f $stamp)
            return
        }
        catch {
            continue
        }
    }
}

function Write-Log {
    param([string]$Message)
    if (-not $script:LogFile) { return }
    try {
        $line = "[{0}] {1}" -f (Get-Date -Format 'yyyy-MM-dd HH:mm:ss'), $Message
        Add-Content -LiteralPath $script:LogFile -Value $line -Encoding UTF8
    }
    catch {
        # Le journal ne doit jamais faire échouer le formatage.
    }
}

function Show-Dialog {
    param(
        [Parameter(Mandatory)][string]$Text,
        [string]$Title = 'Format FAT32',
        [ValidateSet('Information', 'Warning', 'Error', 'Question')][string]$Icon = 'Information',
        [ValidateSet('OK', 'OKCancel', 'YesNo', 'YesNoCancel')][string]$Buttons = 'OK'
    )
    try {
        Add-Type -AssemblyName System.Windows.Forms -ErrorAction Stop
        $default = 'Button1'
        if ($Buttons -eq 'YesNo' -or $Buttons -eq 'YesNoCancel') { $default = 'Button2' }
        $result = [System.Windows.Forms.MessageBox]::Show(
            $Text,
            $Title,
            [System.Windows.Forms.MessageBoxButtons]::$Buttons,
            [System.Windows.Forms.MessageBoxIcon]::$Icon,
            [System.Windows.Forms.MessageBoxDefaultButton]::$default)
        return [string]$result
    }
    catch {
        Write-Host ''
        Write-Host "=== $Title ===" -ForegroundColor Yellow
        Write-Host $Text
        Write-Host ''
        return 'OK'
    }
}

function Quote-Argument {
    param([string]$Value)
    if ($Value -match '\s') { return '"' + $Value + '"' }
    return $Value
}

function Get-LogPath {
    if ($script:LogFile) { return $script:LogFile }
    return 'indisponible'
}

# --------------------------------------------------------------------------
# Disques
# --------------------------------------------------------------------------

function Resolve-DriveLetter {
    param([string]$Value)
    if ([string]::IsNullOrWhiteSpace($Value)) { return $null }
    $match = [regex]::Match($Value, '([A-Za-z])\s*:')
    if ($match.Success) { return $match.Groups[1].Value.ToUpperInvariant() }
    if ($Value -match '^\s*"?([A-Za-z])"?\s*$') { return $Matches[1].ToUpperInvariant() }
    return $null
}

function Get-DiskInfo {
    param([string]$Letter)
    return Get-CimInstance -ClassName Win32_LogicalDisk -Filter ("DeviceID='{0}:'" -f $Letter) -ErrorAction SilentlyContinue
}

function Get-RemovableVolumes {
    $disks = Get-CimInstance -ClassName Win32_LogicalDisk -Filter 'DriveType=2' -ErrorAction SilentlyContinue
    $list = @()
    foreach ($disk in $disks) {
        if (-not $disk.Size) { continue }
        $list += [pscustomobject]@{
            Letter     = $disk.DeviceID.TrimEnd(':')
            Label      = [string]$disk.VolumeName
            FileSystem = [string]$disk.FileSystem
            SizeBytes  = [uint64]$disk.Size
            SizeGB     = [math]::Round($disk.Size / 1GB, 1)
            DriveType  = [int]$disk.DriveType
        }
    }
    return $list
}

function Get-DriveTypeName {
    param([int]$Type)
    switch ($Type) {
        0 { 'Inconnu' }
        1 { 'Sans racine' }
        2 { 'Amovible' }
        3 { 'Fixe' }
        4 { 'Réseau' }
        5 { 'CD-ROM' }
        6 { 'RAM' }
        default { "Type $Type" }
    }
}

function Wait-ForFat32 {
    param([string]$Letter, [int]$TimeoutSeconds = 10)
    $deadline = (Get-Date).AddSeconds($TimeoutSeconds)
    $state = $null
    do {
        $state = Get-DiskInfo $Letter
        if ($state -and ([string]$state.FileSystem).ToUpperInvariant() -eq 'FAT32') { return $state }
        Start-Sleep -Milliseconds 500
    } while ((Get-Date) -lt $deadline)
    return $state
}

function New-VolumePicker {
    param([object[]]$Volumes)

    Add-Type -AssemblyName System.Windows.Forms -ErrorAction Stop
    Add-Type -AssemblyName System.Drawing -ErrorAction Stop

    $form = New-Object System.Windows.Forms.Form
    $form.Text = 'Formater en FAT32'
    $form.ClientSize = New-Object System.Drawing.Size(620, 350)
    $form.StartPosition = 'CenterScreen'
    $form.FormBorderStyle = 'FixedDialog'
    $form.MaximizeBox = $false
    $form.MinimizeBox = $false
    $form.TopMost = $true

    $intro = New-Object System.Windows.Forms.Label
    $intro.Text = 'Sélectionnez le disque amovible à formater en FAT32 :'
    $intro.Location = New-Object System.Drawing.Point(12, 12)
    $intro.AutoSize = $true
    $form.Controls.Add($intro)

    $list = New-Object System.Windows.Forms.ListBox
    $list.Location = New-Object System.Drawing.Point(12, 38)
    $list.Size = New-Object System.Drawing.Size(596, 230)
    $list.Font = New-Object System.Drawing.Font 'Consolas', 9.5
    $list.IntegralHeight = $false
    foreach ($volume in $Volumes) {
        $name = if ($volume.Label) { $volume.Label } else { '(sans nom)' }
        $fs = if ($volume.FileSystem) { $volume.FileSystem } else { 'RAW' }
        $null = $list.Items.Add(('{0}:  {1,-16} {2,8} Go   {3}' -f $volume.Letter, $name, $volume.SizeGB, $fs))
    }
    $list.SelectedIndex = 0
    $form.Controls.Add($list)

    $warning = New-Object System.Windows.Forms.Label
    $warning.Text = 'Le contenu du disque sélectionné sera définitivement effacé.'
    $warning.ForeColor = [System.Drawing.Color]::Firebrick
    $warning.Location = New-Object System.Drawing.Point(12, 274)
    $warning.AutoSize = $true
    $form.Controls.Add($warning)

    $ok = New-Object System.Windows.Forms.Button
    $ok.Text = 'Formater en FAT32'
    $ok.Size = New-Object System.Drawing.Size(170, 30)
    $ok.Location = New-Object System.Drawing.Point(258, 300)
    $ok.DialogResult = [System.Windows.Forms.DialogResult]::OK
    $form.Controls.Add($ok)

    $cancel = New-Object System.Windows.Forms.Button
    $cancel.Text = 'Annuler'
    $cancel.Size = New-Object System.Drawing.Size(150, 30)
    $cancel.Location = New-Object System.Drawing.Point(458, 300)
    $cancel.DialogResult = [System.Windows.Forms.DialogResult]::Cancel
    $form.Controls.Add($cancel)

    $form.AcceptButton = $ok
    $form.CancelButton = $cancel

    return [pscustomobject]@{
        Form    = $form
        List    = $list
        Volumes = $Volumes
    }
}

function Select-RemovableVolume {
    $volumes = @(Get-RemovableVolumes)
    if ($volumes.Count -eq 0) {
        Show-Dialog -Text "Aucun disque amovible prêt n'a été détecté.`r`n`r`nInsérez une carte SD ou une clé USB, puis réessayez." -Icon Warning | Out-Null
        return $null
    }

    $picker = New-VolumePicker -Volumes $volumes
    $index = -1
    try {
        $result = $picker.Form.ShowDialog()
        if ($result -eq [System.Windows.Forms.DialogResult]::OK) { $index = $picker.List.SelectedIndex }
    }
    finally {
        $picker.Form.Dispose()
    }

    if ($index -lt 0) { return $null }
    return $picker.Volumes[$index]
}

# --------------------------------------------------------------------------
# Formatage
# --------------------------------------------------------------------------

function Invoke-NativeFormat {
    param(
        [string]$Letter,
        [string]$NewLabel,
        [string]$CurrentLabel,
        [int]$ClusterBytes
    )

    $exe = Join-Path $env:SystemRoot 'System32\format.com'
    if (-not (Test-Path -LiteralPath $exe)) { throw "format.com est introuvable dans $env:SystemRoot\System32." }

    $formatArgs = @(('{0}:' -f $Letter), '/FS:FAT32', '/Q', '/Y')
    if ($NewLabel) { $formatArgs += ('/V:{0}' -f $NewLabel) }
    if ($ClusterBytes -gt 0) { $formatArgs += ('/A:{0}' -f $ClusterBytes) }

    # Répond aux invites éventuelles (libellé courant, puis confirmation).
    $stdin = if ($CurrentLabel) { "$CurrentLabel`r`nY`r`n" } else { "`r`nY`r`n" }
    $output = $stdin | & $exe @formatArgs 2>&1 | Out-String
    $code = $LASTEXITCODE

    return [pscustomobject]@{
        ExitCode = $code
        Output   = $output.Trim()
        Command  = ('format {0}' -f ($formatArgs -join ' '))
        Tool     = 'format.com'
    }
}

function Invoke-FallbackFormat {
    param(
        [string]$Letter,
        [string]$NewLabel,
        [int]$ClusterSectors
    )

    $exe = Join-Path $PSScriptRoot 'fat32format.exe'
    if (-not (Test-Path -LiteralPath $exe)) { return $null }

    $toolArgs = @('-y')
    if ($NewLabel) { $toolArgs += @('-l', $NewLabel) }
    if ($ClusterSectors -gt 0) { $toolArgs += @('-c', "$ClusterSectors") }
    $toolArgs += ('{0}:' -f $Letter)

    $output = & $exe @toolArgs 2>&1 | Out-String
    return [pscustomobject]@{
        ExitCode = $LASTEXITCODE
        Output   = $output.Trim()
        Command  = ('fat32format {0}' -f ($toolArgs -join ' '))
        Tool     = 'fat32format.exe'
    }
}

function Get-VolumeDetails {
    param([string]$Letter)
    try {
        return Get-CimInstance -ClassName Win32_Volume -Filter ("DriveLetter='{0}:'" -f $Letter) -ErrorAction Stop
    }
    catch {
        return $null
    }
}

# --------------------------------------------------------------------------
# Exécution
# --------------------------------------------------------------------------

Initialize-Log

try {
    if ($SelfTest) {
        $fake = @([pscustomobject]@{
            Letter     = 'E'
            Label      = 'TEST'
            FileSystem = 'exFAT'
            SizeBytes  = [uint64]64GB
            SizeGB     = 64.0
            DriveType  = 2
        })
        $picker = New-VolumePicker -Volumes $fake
        $itemCount = $picker.List.Items.Count
        $picker.Form.Dispose()
        $volumes = @(Get-RemovableVolumes)
        Write-Host ("SelfTest OK | PowerShell {0} | Admin={1} | Disques amovibles={2} | Fenêtre={3} élément(s)" -f $PSVersionTable.PSVersion, (Test-IsAdmin), $volumes.Count, $itemCount)
        exit 0
    }

    $isAdmin = Test-IsAdmin

    if (-not $isAdmin -and -not $DryRun -and -not $Elevated) {
        Write-Log "Relance en administrateur (demande initiale : Drive=$Drive)."
        $shell = Join-Path $env:SystemRoot 'System32\WindowsPowerShell\v1.0\powershell.exe'
        $arguments = @('-NoProfile', '-ExecutionPolicy', 'Bypass', '-WindowStyle', 'Hidden', '-STA',
            '-File', (Quote-Argument $PSCommandPath))
        if ($Drive) { $arguments += @('-Drive', (Quote-Argument $Drive)) }
        if ($Label) { $arguments += @('-Label', (Quote-Argument $Label)) }
        if ($ClusterSizeKb -gt 0) { $arguments += @('-ClusterSizeKb', "$ClusterSizeKb") }
        if ($AllowFixed) { $arguments += '-AllowFixed' }
        if ($Yes) { $arguments += '-Yes' }
        $arguments += '-Elevated'

        try {
            Start-Process -FilePath $shell -ArgumentList ($arguments -join ' ') -Verb RunAs -Wait -ErrorAction Stop
        }
        catch {
            Write-Log "Élévation refusée : $($_.Exception.Message)"
            Show-Dialog -Text ("Droits administrateur requis pour formater un disque.`r`n`r`n" +
                "L'élévation a été refusée ou annulée.`r`n`r`n" + $_.Exception.Message) -Icon Warning | Out-Null
            exit 4
        }
        exit 0
    }

    $letter = Resolve-DriveLetter $Drive
    if (-not $letter) {
        if ($Drive) { throw "Lettre de lecteur invalide : '$Drive'." }
        $picked = Select-RemovableVolume
        if (-not $picked) {
            Write-Log 'Aucun disque sélectionné : abandon.'
            exit 2
        }
        $letter = $picked.Letter
    }

    $disk = Get-DiskInfo $letter
    if (-not $disk) {
        throw "Le lecteur ${letter}: n'existe pas ou n'est pas accessible.`r`nVérifiez la carte, puis relancez."
    }

    $systemLetter = $env:SystemDrive.Substring(0, 1)
    if ($letter -eq $systemLetter) {
        throw "Le disque système (${letter}:) ne peut pas être formaté par cet outil."
    }

    $driveType = [int]$disk.DriveType
    if ($driveType -ne 2 -and -not $AllowFixed) {
        $message = "Le lecteur {0}: est de type « {1} » et non « Amovible »." -f $letter, (Get-DriveTypeName $driveType)
        $message += "`r`n`r`nCet outil est réservé aux cartes SD et clés USB."
        throw $message
    }
    if ($driveType -eq 4 -or $driveType -eq 5) {
        $message = "Le lecteur {0}: est de type « {1} » : formatage impossible." -f $letter, (Get-DriveTypeName $driveType)
        throw $message
    }
    if (-not $disk.Size) {
        throw "Aucun média détecté dans le lecteur ${letter}:`r`nInsérez une carte, puis relancez."
    }

    $sizeBytes = [uint64]$disk.Size
    if ($sizeBytes -gt 2TB) {
        $message = "Le volume fait {0:N1} Go : au-delà de la limite FAT32 (2 To)." -f ($sizeBytes / 1GB)
        throw $message
    }

    $currentLabel = [string]$disk.VolumeName
    $newLabel = $currentLabel
    if ($Label) { $newLabel = $Label }
    if ($newLabel.Length -gt 11) { $newLabel = $newLabel.Substring(0, 11) }
    $currentFs = if ($disk.FileSystem) { [string]$disk.FileSystem } else { 'RAW' }
    $clusterBytes = 0
    if ($ClusterSizeKb -gt 0) { $clusterBytes = $ClusterSizeKb * 1KB }

    $labelBefore = if ($currentLabel) { $currentLabel } else { '(sans nom)' }
    $labelAfter = if ($newLabel) { $newLabel } else { '(sans nom)' }
    $sizeText = '{0:N1}' -f ($sizeBytes / 1GB)

    $formatArgsPreview = @(('{0}:' -f $letter), '/FS:FAT32', '/Q', '/Y')
    if ($newLabel) { $formatArgsPreview += ('/V:{0}' -f $newLabel) }
    if ($clusterBytes -gt 0) { $formatArgsPreview += ('/A:{0}' -f $clusterBytes) }

    if ($DryRun) {
        Write-Host 'Plan de formatage (simulation)'
        Write-Host '------------------------------'
        Write-Host ("Lecteur             : {0}:" -f $letter)
        Write-Host ("Libellé             : {0} -> {1}" -f $labelBefore, $labelAfter)
        Write-Host ("Système de fichiers : {0} -> FAT32" -f $currentFs)
        Write-Host ("Capacité            : {0} Go" -f $sizeText)
        Write-Host ("Type                : {0}" -f (Get-DriveTypeName $driveType))
        Write-Host ("Formatage           : rapide")
        Write-Host ("Commande            : format {0}" -f ($formatArgsPreview -join ' '))
        exit 0
    }

    $isRemovableText = if ($driveType -eq 2) { 'oui' } else { 'NON (option -AllowFixed)' }
    $confirm = "Formater le disque ${letter}: en FAT32 ?`r`n`r`n" +
        "Libellé            : $labelBefore`r`n" +
        "Capacité           : $sizeText Go`r`n" +
        "Système actuel     : $currentFs`r`n" +
        "Disque amovible    : $isRemovableText`r`n`r`n" +
        "Toutes les données de ce disque seront définitivement effacées.`r`n" +
        "Continuer ?"

    Write-Log ("Demande de formatage : lecteur={0} type={1} fs={2} taille={3} libellé='{4}'" -f $letter, $driveType, $currentFs, $sizeBytes, $currentLabel)

    if (-not $Yes) {
        $answer = Show-Dialog -Text $confirm -Title 'Confirmer le formatage FAT32' -Icon Warning -Buttons YesNo
        if ($answer -ne 'Yes') {
            Write-Log "Formatage annulé par l'utilisateur."
            exit 2
        }
    }

    $watch = [System.Diagnostics.Stopwatch]::StartNew()
    $result = Invoke-NativeFormat -Letter $letter -NewLabel $newLabel -CurrentLabel $currentLabel -ClusterBytes $clusterBytes
    $watch.Stop()
    Write-Log ("{0} -> code {1}" -f $result.Command, $result.ExitCode)
    if ($result.Output) { Write-Log $result.Output }

    $after = Wait-ForFat32 -Letter $letter
    $success = [bool]($after -and ([string]$after.FileSystem).ToUpperInvariant() -eq 'FAT32' -and [uint64]$after.Size -gt 0)

    if (-not $success -and $result.ExitCode -ne 0) {
        $clusterSectors = 0
        if ($clusterBytes -gt 0) { $clusterSectors = [int]($clusterBytes / 512) }
        $fallback = Invoke-FallbackFormat -Letter $letter -NewLabel $newLabel -ClusterSectors $clusterSectors
        if ($fallback) {
            Write-Log ("{0} -> code {1}" -f $fallback.Command, $fallback.ExitCode)
            if ($fallback.Output) { Write-Log $fallback.Output }
            $result = $fallback
            $after = Wait-ForFat32 -Letter $letter
            $success = [bool]($after -and ([string]$after.FileSystem).ToUpperInvariant() -eq 'FAT32' -and [uint64]$after.Size -gt 0)
        }
    }

    if (-not $success) {
        $details = [string]$result.Output
        if ($details.Length -gt 1200) { $details = $details.Substring($details.Length - 1200) }
        Write-Log ("ÉCHEC du formatage (code {0})" -f $result.ExitCode)
        $failureText = "Le formatage de ${letter}: en FAT32 a échoué.`r`n`r`n" +
            "Causes possibles :`r`n" +
            "- version de Windows trop ancienne pour FAT32 au-delà de 32 Go`r`n" +
            "  (vérifiez avec winver : la limite a été levée à partir des builds`r`n" +
            "  26100.8313 / 26200.8313 ; sinon utilisez Rufus ou fat32format.exe) ;`r`n" +
            "- carte en protection en écriture ou occupée par un autre programme ;`r`n" +
            "- carte défectueuse.`r`n`r`n" +
            "Sortie de $($result.Tool) (code $($result.ExitCode)) :`r`n$details`r`n`r`n" +
            "Journal : $(Get-LogPath)"
        Show-Dialog -Icon Error -Title 'Échec du formatage' -Text $failureText | Out-Null
        exit 3
    }

    $volume = Get-VolumeDetails $letter
    $clusterText = 'inconnue'
    if ($volume -and $volume.BlockSize) { $clusterText = '{0:N0} Ko' -f ($volume.BlockSize / 1KB) }
    $finalLabel = [string]$after.VolumeName
    if (-not $finalLabel) { $finalLabel = '(sans nom)' }

    Write-Log ("SUCCÈS : {0}: formaté en FAT32, libellé='{1}', durée={2:N1}s" -f $letter, $finalLabel, $watch.Elapsed.TotalSeconds)

    $successText = "Le disque ${letter}: est maintenant en FAT32.`r`n`r`n" +
        "Libellé             : $finalLabel`r`n" +
        "Capacité            : $('{0:N1}' -f ([uint64]$after.Size / 1GB)) Go`r`n" +
        "Taille des clusters : $clusterText`r`n" +
        "Durée               : $([int]$watch.Elapsed.TotalSeconds) s`r`n`r`n" +
        "Rappel : en FAT32, un fichier ne peut pas dépasser 4 Go.`r`n`r`n" +
        "Journal : $(Get-LogPath)"
    Show-Dialog -Icon Information -Title 'Formatage terminé' -Text $successText | Out-Null

    exit 0
}
catch {
    $message = $_.Exception.Message
    Write-Log ("ERREUR : {0}" -f $message)
    if ($DryRun) {
        Write-Host ("ERREUR : {0}" -f $message) -ForegroundColor Red
        exit 1
    }
    Show-Dialog -Icon Error -Title 'Format FAT32' -Text ("$message`r`n`r`nJournal : $(Get-LogPath)") | Out-Null
    exit 1
}
