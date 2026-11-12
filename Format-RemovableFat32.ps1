#requires -Version 5.1
<#
.SYNOPSIS
    Formate en FAT32 un disque amovible (carte SD, clé USB), en formatage rapide.

.DESCRIPTION
    Cible uniquement les volumes amovibles (sauf -AllowFixed), demande une confirmation,
    lance format.com /FS:FAT32, vérifie le résultat et affiche un compte rendu.
    S'élève automatiquement en administrateur (UAC) si nécessaire.
    Un journal est écrit dans %ProgramData%\FormatFAT32\logs (compte administrateur)
    ou %LOCALAPPDATA%\FormatFAT32\logs (compte standard).

    L'outil n'utilise que les composants de Windows (format.com). Aucun binaire tiers.

    Prérequis pour le FAT32 au-delà de 32 Go : Windows 11 24H2 build 26100.8313
    ou 25H2 build 26200.8313 (ou version ultérieure). Jusqu'à 32 Go, toute version
    de Windows disposant de PowerShell 5.1 convient.

.PARAMETER Drive
    Lettre du lecteur ("E", "E:", "E:\"). Si omis, une fenêtre de sélection s'ouvre.

.PARAMETER Label
    Nouveau libellé du volume (11 caractères max). Par défaut, le libellé actuel est conservé.

.PARAMETER ClusterSizeKb
    Taille de cluster en Ko. Par défaut, Windows choisit.

.PARAMETER AllowFixed
    Autorise aussi les disques fixes (certains lecteurs de cartes se déclarent « Fixe »).
    Le disque système est toujours refusé.

.PARAMETER Yes
    Ne pas afficher la confirmation (automatisation).

.PARAMETER DryRun
    Affiche le plan d'action sans rien formater (sortie console).

.PARAMETER SelfTest
    Vérifie que le script et WinForms sont opérationnels, puis quitte.

.PARAMETER SkipVersionCheck
    Passe outre le contrôle de version de Windows (utile si la détection est erronée).

.EXAMPLE
    .\Format-RemovableFat32.ps1 -Drive E:

.EXAMPLE
    .\Format-RemovableFat32.ps1 -Drive E: -DryRun

.EXAMPLE
    .\Format-RemovableFat32.ps1
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
    [switch]$SkipVersionCheck,
    [switch]$Elevated
)

$ErrorActionPreference = 'Stop'

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

function Add-LogEntry {
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

function ConvertTo-QuotedArgument {
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

function Format-Size {
    param([uint64]$Bytes)
    if ($Bytes -ge 1GB) { return ('{0:N1} Go' -f ($Bytes / 1GB)) }
    if ($Bytes -ge 1MB) { return ('{0:N0} Mo' -f ($Bytes / 1MB)) }
    if ($Bytes -ge 1KB) { return ('{0:N0} Ko' -f ($Bytes / 1KB)) }
    return ('{0} o' -f $Bytes)
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

function Get-WindowsBuildInfo {
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
    $product = if ($props -and $props.ProductName) { [string]$props.ProductName } else { '' }

    # FAT32 > 32 Go en ligne de commande : disponible depuis 24H2 (26100.8313)
    # et 25H2 (26200.8313), donc pour tout build 26200 ou ultérieur.
    $supportsLargeFat32 = (($build -eq 26100) -and ($ubr -ge 8313)) -or ($build -ge 26200)

    return [pscustomobject]@{
        Build              = $build
        UBR                = $ubr
        DisplayVersion     = $display
        ProductName        = $product
        SupportsLargeFat32 = $supportsLargeFat32
        VersionText        = ("Windows {0} build {1}.{2}" -f $display, $build, $ubr).Trim()
    }
}

function Wait-ForFat32 {
    param([string]$Letter, [int]$TimeoutSeconds = 15)
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
        $null = $list.Items.Add(('{0}:  {1,-18} {2,10}  {3}' -f $volume.Letter, $name, (Format-Size $volume.SizeBytes), $fs))
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
        [string]$ClusterBytes
    )

    $exe = Join-Path $env:SystemRoot 'System32\format.com'
    if (-not (Test-Path -LiteralPath $exe)) {
        throw "format.com est introuvable dans $env:SystemRoot\System32."
    }

    $arguments = @(('{0}:' -f $Letter), '/FS:FAT32', '/Q', '/Y')
    if ($NewLabel) { $arguments += ('/V:{0}' -f $NewLabel) }
    if ($ClusterBytes) { $arguments += ('/A:{0}' -f $ClusterBytes) }

    $startInfo = New-Object System.Diagnostics.ProcessStartInfo
    $startInfo.FileName = $exe
    $startInfo.Arguments = $arguments -join ' '
    $startInfo.UseShellExecute = $false
    $startInfo.CreateNoWindow = $true
    $startInfo.RedirectStandardInput = $true
    $startInfo.RedirectStandardOutput = $true
    $startInfo.RedirectStandardError = $true

    $process = New-Object System.Diagnostics.Process
    $process.StartInfo = $startInfo
    [void]$process.Start()

    $stdoutTask = $process.StandardOutput.ReadToEndAsync()
    $stderrTask = $process.StandardError.ReadToEndAsync()

    # Répond aux invites éventuelles (confirmation, libellé courant).
    try {
        $process.StandardInput.Write("Y`r`n")
        $process.StandardInput.Close()
    }
    catch {
        # L'entrée standard peut déjà être fermée : sans conséquence avec /Y.
    }

    $finished = $process.WaitForExit(900000)
    if (-not $finished) {
        try { $process.Kill() } catch { }
        throw "Délai dépassé : format.com n'a pas terminé en 15 minutes."
    }

    $process.WaitForExit()
    $stdout = $stdoutTask.Result
    $stderr = $stderrTask.Result
    $code = $process.ExitCode
    $process.Dispose()

    return [pscustomobject]@{
        ExitCode = $code
        Output   = (@($stdout, $stderr) -join "`r`n").Trim()
        Command  = ('format {0}' -f ($arguments -join ' '))
        Tool     = 'format.com'
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
        $buildInfo = Get-WindowsBuildInfo
        Write-Host ("SelfTest OK | PowerShell {0} | Admin={1} | Disques amovibles={2} | Fenêtre={3} élément(s)" -f $PSVersionTable.PSVersion, (Test-IsAdmin), $volumes.Count, $itemCount)
        Write-Host ("Windows : {0} | FAT32 > 32 Go : {1}" -f $buildInfo.VersionText, $(if ($buildInfo.SupportsLargeFat32) { 'pris en charge' } else { 'non pris en charge' }))
        exit 0
    }

    $isAdmin = Test-IsAdmin

    if (-not $isAdmin -and -not $DryRun -and -not $Elevated) {
        Add-LogEntry "Relance en administrateur (demande initiale : Drive=$Drive)."
        $shell = Join-Path $env:SystemRoot 'System32\WindowsPowerShell\v1.0\powershell.exe'
        $arguments = @('-NoProfile', '-ExecutionPolicy', 'Bypass', '-WindowStyle', 'Hidden', '-STA',
            '-File', (ConvertTo-QuotedArgument $PSCommandPath))
        if ($Drive) { $arguments += @('-Drive', (ConvertTo-QuotedArgument $Drive)) }
        if ($Label) { $arguments += @('-Label', (ConvertTo-QuotedArgument $Label)) }
        if ($ClusterSizeKb -gt 0) { $arguments += @('-ClusterSizeKb', "$ClusterSizeKb") }
        if ($AllowFixed) { $arguments += '-AllowFixed' }
        if ($Yes) { $arguments += '-Yes' }
        if ($SkipVersionCheck) { $arguments += '-SkipVersionCheck' }
        $arguments += '-Elevated'

        try {
            Start-Process -FilePath $shell -ArgumentList ($arguments -join ' ') -Verb RunAs -Wait -ErrorAction Stop
        }
        catch {
            Add-LogEntry "Élévation refusée : $($_.Exception.Message)"
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
            Add-LogEntry 'Aucun disque sélectionné : abandon.'
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
    if ($driveType -eq 4 -or $driveType -eq 5) {
        throw ("Le lecteur {0}: est de type « {1} » : formatage impossible." -f $letter, (Get-DriveTypeName $driveType))
    }
    if ($driveType -ne 2 -and -not $AllowFixed) {
        $message = "Le lecteur {0}: est de type « {1} » et non « Amovible »." -f $letter, (Get-DriveTypeName $driveType)
        $message += "`r`n`r`nCet outil est réservé aux cartes SD et clés USB."
        $message += "`r`nSi un lecteur de cartes se déclare « Fixe », utilisez l'option -AllowFixed."
        throw $message
    }
    if (-not $disk.Size) {
        throw "Aucun média détecté dans le lecteur ${letter}:`r`nInsérez une carte, puis relancez."
    }

    $sizeBytes = [uint64]$disk.Size
    if ($sizeBytes -gt 2TB) {
        throw ("Le volume fait {0} : au-delà de la limite FAT32 (2 To)." -f (Format-Size $sizeBytes))
    }

    $buildInfo = Get-WindowsBuildInfo
    if ($sizeBytes -gt 32GB -and -not $buildInfo.SupportsLargeFat32 -and -not $SkipVersionCheck) {
        $message = "Ce PC ne peut pas créer un volume FAT32 de plus de 32 Go.`r`n`r`n" +
            "Version détectée : $($buildInfo.VersionText)`r`n" +
            "Version requise  : Windows 11 24H2 build 26100.8313 ou 25H2 build 26200.8313 (ou ultérieure).`r`n`r`n" +
            "Mettez Windows à jour (Paramètres > Windows Update), puis relancez.`r`n" +
            "Pour passer outre ce contrôle : option -SkipVersionCheck."
        throw $message
    }
    if ($sizeBytes -gt 32GB -and -not $buildInfo.SupportsLargeFat32) {
        Add-LogEntry ("Contrôle de version ignoré (build {0}.{1})." -f $buildInfo.Build, $buildInfo.UBR)
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
    $sizeText = Format-Size $sizeBytes

    $previewArgs = @(('{0}:' -f $letter), '/FS:FAT32', '/Q', '/Y')
    if ($newLabel) { $previewArgs += ('/V:{0}' -f $newLabel) }
    if ($clusterBytes) { $previewArgs += ('/A:{0}' -f $clusterBytes) }

    if ($DryRun) {
        Write-Host 'Plan de formatage (simulation)'
        Write-Host '------------------------------'
        Write-Host ('Lecteur             : {0}:' -f $letter)
        Write-Host ('Libellé             : {0} -> {1}' -f $labelBefore, $labelAfter)
        Write-Host ('Système de fichiers : {0} -> FAT32' -f $currentFs)
        Write-Host ('Capacité            : {0}' -f $sizeText)
        Write-Host ('Type                : {0}' -f (Get-DriveTypeName $driveType))
        Write-Host 'Formatage           : rapide'
        Write-Host ('Windows             : {0} (FAT32 > 32 Go : {1})' -f $buildInfo.VersionText, $(if ($buildInfo.SupportsLargeFat32) { 'pris en charge' } else { 'NON pris en charge' }))
        Write-Host ('Commande            : format {0}' -f ($previewArgs -join ' '))
        exit 0
    }

    $isRemovableText = if ($driveType -eq 2) { 'oui' } else { 'NON (option -AllowFixed)' }
    $confirm = "Formater le disque ${letter}: en FAT32 ?`r`n`r`n" +
        "Libellé            : $labelBefore`r`n" +
        "Capacité           : $sizeText`r`n" +
        "Système actuel     : $currentFs`r`n" +
        "Disque amovible    : $isRemovableText`r`n" +
        "Windows            : $($buildInfo.VersionText)`r`n`r`n" +
        "Toutes les données de ce disque seront définitivement effacées.`r`n" +
        "Continuer ?"
    Add-LogEntry ("Demande de formatage : lecteur={0} type={1} fs={2} taille={3} libellé='{4}'" -f $letter, $driveType, $currentFs, $sizeBytes, $currentLabel)

    if (-not $Yes) {
        $answer = Show-Dialog -Text $confirm -Title 'Confirmer le formatage FAT32' -Icon Warning -Buttons YesNo
        if ($answer -ne 'Yes') {
            Add-LogEntry "Formatage annulé par l'utilisateur."
            exit 2
        }
    }

    $watch = [System.Diagnostics.Stopwatch]::StartNew()
    $result = Invoke-NativeFormat -Letter $letter -NewLabel $newLabel -ClusterBytes $clusterBytes
    $watch.Stop()

    Add-LogEntry ("{0} -> code {1}" -f $result.Command, $result.ExitCode)
    if ($result.Output) { Add-LogEntry $result.Output }

    $after = Wait-ForFat32 -Letter $letter
    $success = [bool]($after -and ([string]$after.FileSystem).ToUpperInvariant() -eq 'FAT32' -and [uint64]$after.Size -gt 0)

    if (-not $success) {
        $details = [string]$result.Output
        if ($details.Length -gt 1200) { $details = $details.Substring($details.Length - 1200) }
        Add-LogEntry ("ÉCHEC du formatage (code {0})" -f $result.ExitCode)
        $failureText = "Le formatage de ${letter}: en FAT32 a échoué.`r`n`r`n" +
            "Causes possibles :`r`n" +
            "- version de Windows trop ancienne pour créer du FAT32 au-delà de 32 Go`r`n" +
            "  (vérifiez avec winver : la limite en ligne de commande a été levée à partir`r`n" +
            "  des builds 26100.8313 et 26200.8313 ; sinon mettez Windows à jour) ;`r`n" +
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

    Add-LogEntry ("SUCCÈS : {0}: formaté en FAT32, libellé='{1}', durée={2:N1}s" -f $letter, $finalLabel, $watch.Elapsed.TotalSeconds)

    $successText = "Le disque ${letter}: est maintenant en FAT32.`r`n`r`n" +
        "Libellé             : $finalLabel`r`n" +
        "Capacité            : $(Format-Size ([uint64]$after.Size))`r`n" +
        "Taille des clusters : $clusterText`r`n" +
        "Durée               : $([int]$watch.Elapsed.TotalSeconds) s`r`n`r`n" +
        "Rappel : en FAT32, un fichier ne peut pas dépasser 4 Go.`r`n`r`n" +
        "Journal : $(Get-LogPath)"
    Show-Dialog -Icon Information -Title 'Formatage terminé' -Text $successText | Out-Null

    exit 0
}
catch {
    $message = $_.Exception.Message
    Add-LogEntry ("ERREUR : {0}" -f $message)
    if ($DryRun) {
        Write-Host ("ERREUR : {0}" -f $message) -ForegroundColor Red
        exit 1
    }
    Show-Dialog -Icon Error -Title 'Format FAT32' -Text ("$message`r`n`r`nJournal : $(Get-LogPath)") | Out-Null
    exit 1
}
