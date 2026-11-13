#requires -Version 5.1
<#
.SYNOPSIS
    Formats a removable drive (SD card, USB stick) as FAT32, quick format.

.DESCRIPTION
    Targets removable volumes only (unless -AllowFixed), asks for confirmation,
    runs format.com /FS:FAT32, verifies the result and reports back.
    Self-elevates (UAC) when needed. Logs to %ProgramData%\FormatFAT32\logs
    (administrator) or %LOCALAPPDATA%\FormatFAT32\logs (standard user).

    Uses only Microsoft's format.com. No third-party binary.

    Requires Windows 11 24H2 build 26100.8313 / 25H2 build 26200.8313 (or later)
    to create FAT32 volumes larger than 32 GB. Up to 32 GB any Windows with
    PowerShell 5.1 works.

    User interface strings live in .\lang\<code>.psd1 (en, fr, de, es, it, pt, nl).

.PARAMETER Drive
    Drive letter ("E", "E:", "E:\"). If omitted, a picker window is shown.

.PARAMETER Label
    New volume label (11 characters max). Defaults to the current label.

.PARAMETER ClusterSizeKb
    Cluster size in KB. Windows default when omitted.

.PARAMETER Language
    UI language code (en, fr, de, es, it, pt, nl). Defaults to language.txt,
    then to the Windows display language, then to English.

.PARAMETER AllowFixed
    Also allow drives reported as "Fixed" (some card readers). The system drive
    is always refused.

.PARAMETER Yes
    Skip the confirmation dialog (automation).

.PARAMETER DryRun
    Print the action plan without formatting (console output).

.PARAMETER SelfTest
    Check script + WinForms + report the Windows build, then exit.

.PARAMETER SkipVersionCheck
    Ignore the Windows build check for FAT32 volumes above 32 GB.

.EXAMPLE
    .\Format-RemovableFat32.ps1 -Drive E:

.EXAMPLE
    .\Format-RemovableFat32.ps1 -Drive E: -DryRun

.EXAMPLE
    .\Format-RemovableFat32.ps1 -Language de
#>
[CmdletBinding()]
param(
    [Parameter(Position = 0)]
    [string]$Drive,

    [string]$Label,

    [int]$ClusterSizeKb = 0,

    [string]$Language,

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
$script:Strings = @{}
$script:FallbackStrings = @{}
$script:LanguageCode = 'en'
$script:visualStylesEnabled = $false
$script:dialogResult = 'OK'

# --------------------------------------------------------------------------
# Localisation
# --------------------------------------------------------------------------

function Initialize-Localization {
    param([string]$Requested)

    $langDir = Join-Path $PSScriptRoot 'lang'
    $enPath = Join-Path $langDir 'en.psd1'
    if (Test-Path -LiteralPath $enPath) {
        $script:FallbackStrings = Import-PowerShellDataFile -LiteralPath $enPath
    }

    $code = $null
    if ($Requested) { $code = $Requested }
    if (-not $code) {
        $languageFile = Join-Path $PSScriptRoot 'language.txt'
        if (Test-Path -LiteralPath $languageFile) {
            $code = (Get-Content -LiteralPath $languageFile -TotalCount 1).Trim()
        }
    }
    if (-not $code) {
        $code = [System.Globalization.CultureInfo]::CurrentUICulture.TwoLetterISOLanguageName
    }
    $code = $code.ToLowerInvariant()
    if ($code.Length -gt 2) { $code = $code.Substring(0, 2) }

    $path = Join-Path $langDir ("{0}.psd1" -f $code)
    if (-not (Test-Path -LiteralPath $path)) {
        $code = 'en'
        $path = $enPath
    }

    if (Test-Path -LiteralPath $path) {
        $script:Strings = Import-PowerShellDataFile -LiteralPath $path
    }
    else {
        $script:Strings = $script:FallbackStrings
    }
    $script:LanguageCode = $code
}

function Enable-VisualStyles {
    if ($script:visualStylesEnabled) { return }
    try {
        [System.Windows.Forms.Application]::EnableVisualStyles()
    }
    catch {
        # Theme is cosmetic only.
    }
    $script:visualStylesEnabled = $true
}

function Get-UiText {
    param(
        [Parameter(Mandatory)][string]$Key,
        [object[]]$Arguments
    )

    $value = $null
    if ($script:Strings.ContainsKey($Key)) { $value = $script:Strings[$Key] }
    elseif ($script:FallbackStrings.ContainsKey($Key)) { $value = $script:FallbackStrings[$Key] }
    else { return "[$Key]" }

    if ($Arguments -and $Arguments.Count -gt 0) {
        try { return ([string]$value -f $Arguments) }
        catch { return [string]$value }
    }
    return [string]$value
}

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

# Logs are deliberately English-only: they are support artefacts, not UI.
function Add-LogEntry {
    param([string]$Message)
    if (-not $script:LogFile) { return }
    try {
        $line = "[{0}] {1}" -f (Get-Date -Format 'yyyy-MM-dd HH:mm:ss'), $Message
        Add-Content -LiteralPath $script:LogFile -Value $line -Encoding UTF8
    }
    catch {
        # Logging must never break the formatting flow.
    }
}

function Show-Dialog {
    param(
        [Parameter(Mandatory)][string]$Text,
        [string]$Title,
        [ValidateSet('Information', 'Warning', 'Error', 'Question')][string]$Icon = 'Information',
        [ValidateSet('OK', 'OKCancel', 'YesNo', 'YesNoCancel')][string]$Buttons = 'OK'
    )
    if (-not $Title) { $Title = Get-UiText 'DialogTitle' }

    try {
        Add-Type -AssemblyName System.Windows.Forms -ErrorAction Stop
        Add-Type -AssemblyName System.Drawing -ErrorAction Stop
        Enable-VisualStyles

        $form = New-Object System.Windows.Forms.Form
        $form.Text = $Title
        $form.FormBorderStyle = [System.Windows.Forms.FormBorderStyle]::FixedDialog
        $form.StartPosition = [System.Windows.Forms.FormStartPosition]::CenterScreen
        $form.MaximizeBox = $false
        $form.MinimizeBox = $false
        $form.ShowInTaskbar = $false
        $form.TopMost = $true
        $form.AutoScaleMode = [System.Windows.Forms.AutoScaleMode]::Font
        $form.Font = New-Object System.Drawing.Font 'Segoe UI', 9

        $margin = 18
        $iconSize = 32
        $maxTextWidth = 540

        $picture = New-Object System.Windows.Forms.PictureBox
        $picture.Size = New-Object System.Drawing.Size $iconSize, $iconSize
        $picture.Location = New-Object System.Drawing.Point $margin, $margin
        $picture.SizeMode = [System.Windows.Forms.PictureBoxSizeMode]::CenterImage
        switch ($Icon) {
            'Warning' { $picture.Image = [System.Drawing.SystemIcons]::Warning.ToBitmap() }
            'Error' { $picture.Image = [System.Drawing.SystemIcons]::Error.ToBitmap() }
            'Question' { $picture.Image = [System.Drawing.SystemIcons]::Question.ToBitmap() }
            default { $picture.Image = [System.Drawing.SystemIcons]::Information.ToBitmap() }
        }
        $form.Controls.Add($picture)

        # Two-pass measurement: choose a width, then measure the height at that width
        # so long texts (and long unbreakable paths) are never clipped.
        $textLeft = $margin + $iconSize + 14
        $measureFlags = [System.Windows.Forms.TextFormatFlags]::WordBreak
        $naturalWidth = [System.Windows.Forms.TextRenderer]::MeasureText($Text, $form.Font).Width
        if (($naturalWidth + 12) -le $maxTextWidth) {
            $textWidth = [Math]::Max($naturalWidth + 12, 240)
        }
        else {
            $textWidth = $maxTextWidth
        }
        $measured = [System.Windows.Forms.TextRenderer]::MeasureText(
            $Text, $form.Font, (New-Object System.Drawing.Size $textWidth, 2400), $measureFlags)
        if ($measured.Width -gt $textWidth) {
            $textWidth = [Math]::Min($measured.Width + 12, 760)
            $measured = [System.Windows.Forms.TextRenderer]::MeasureText(
                $Text, $form.Font, (New-Object System.Drawing.Size $textWidth, 2400), $measureFlags)
        }
        $textHeight = $measured.Height + 8

        $label = New-Object System.Windows.Forms.Label
        $label.Text = $Text
        $label.AutoSize = $false
        $label.Location = New-Object System.Drawing.Point $textLeft, ($margin + 4)
        $label.Size = New-Object System.Drawing.Size $textWidth, $textHeight
        $form.Controls.Add($label)

        $specs = @()
        switch ($Buttons) {
            'OK' {
                $specs = @([pscustomobject]@{ Result = 'OK'; Text = (Get-UiText 'ButtonOk'); Default = $true; Cancel = $false })
            }
            'OKCancel' {
                $specs = @(
                    [pscustomobject]@{ Result = 'OK'; Text = (Get-UiText 'ButtonOk'); Default = $true; Cancel = $false },
                    [pscustomobject]@{ Result = 'Cancel'; Text = (Get-UiText 'ButtonCancel'); Default = $false; Cancel = $true })
            }
            'YesNo' {
                $specs = @(
                    [pscustomobject]@{ Result = 'Yes'; Text = (Get-UiText 'ButtonYes'); Default = $false; Cancel = $false },
                    [pscustomobject]@{ Result = 'No'; Text = (Get-UiText 'ButtonNo'); Default = $true; Cancel = $true })
            }
            'YesNoCancel' {
                $specs = @(
                    [pscustomobject]@{ Result = 'Yes'; Text = (Get-UiText 'ButtonYes'); Default = $false; Cancel = $false },
                    [pscustomobject]@{ Result = 'No'; Text = (Get-UiText 'ButtonNo'); Default = $true; Cancel = $false },
                    [pscustomobject]@{ Result = 'Cancel'; Text = (Get-UiText 'ButtonCancel'); Default = $false; Cancel = $true })
            }
        }

        $buttonHeight = 30
        $gap = 8
        $widths = @()
        foreach ($spec in $specs) {
            $size = [System.Windows.Forms.TextRenderer]::MeasureText($spec.Text, $form.Font)
            $widths += [Math]::Max($size.Width + 34, 92)
        }
        $totalWidth = ($widths | Measure-Object -Sum).Sum + ($gap * ($specs.Count - 1))

        $clientWidth = [Math]::Max($textLeft + $textWidth + $margin, $totalWidth + (2 * $margin))
        $buttonsTop = $margin + 4 + $textHeight + 20
        $form.ClientSize = New-Object System.Drawing.Size $clientWidth, ($buttonsTop + $buttonHeight + $margin)

        $script:dialogResult = $specs[0].Result
        if ($Buttons -eq 'YesNo' -or $Buttons -eq 'YesNoCancel') { $script:dialogResult = 'No' }
        if ($Buttons -eq 'OKCancel') { $script:dialogResult = 'Cancel' }

        $x = $clientWidth - $margin
        $acceptButton = $null
        $cancelButton = $null
        for ($i = $specs.Count - 1; $i -ge 0; $i--) {
            $spec = $specs[$i]
            $x -= $widths[$i]
            $button = New-Object System.Windows.Forms.Button
            $button.Text = $spec.Text
            $button.Size = New-Object System.Drawing.Size $widths[$i], $buttonHeight
            $button.Location = New-Object System.Drawing.Point $x, $buttonsTop
            $button.Tag = $spec.Result
            $button.Add_Click({
                    param($control)
                    $script:dialogResult = [string]$control.Tag
                    $control.FindForm().Close()
                })
            $form.Controls.Add($button)
            if ($spec.Default) { $acceptButton = $button }
            if ($spec.Cancel) { $cancelButton = $button }
            $x -= $gap
        }
        if ($acceptButton) { $form.AcceptButton = $acceptButton }
        if ($cancelButton) { $form.CancelButton = $cancelButton }

        [void]$form.ShowDialog()
        $result = $script:dialogResult
        $form.Dispose()
        return $result
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
    return 'n/a'
}

# --------------------------------------------------------------------------
# Drives
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
            DriveType  = [int]$disk.DriveType
        }
    }
    return $list
}

function Format-Size {
    param([uint64]$Bytes)
    if ($Bytes -ge 1GB) { return ('{0:N1} {1}' -f ($Bytes / 1GB), (Get-UiText 'SizeGB')) }
    if ($Bytes -ge 1MB) { return ('{0:N0} {1}' -f ($Bytes / 1MB), (Get-UiText 'SizeMB')) }
    if ($Bytes -ge 1KB) { return ('{0:N0} {1}' -f ($Bytes / 1KB), (Get-UiText 'SizeKB')) }
    return ('{0} {1}' -f $Bytes, (Get-UiText 'SizeBytes'))
}

function Get-DriveTypeName {
    param([int]$Type)
    switch ($Type) {
        0 { Get-UiText 'DriveTypeUnknown' }
        1 { Get-UiText 'DriveTypeNoRoot' }
        2 { Get-UiText 'DriveTypeRemovable' }
        3 { Get-UiText 'DriveTypeFixed' }
        4 { Get-UiText 'DriveTypeNetwork' }
        5 { Get-UiText 'DriveTypeCdRom' }
        6 { Get-UiText 'DriveTypeRam' }
        default { Get-UiText 'DriveTypeOther' @($Type) }
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

    # FAT32 above 32 GB via command line: 24H2 (26100.8313) and 25H2 (26200.8313)+.
    $supportsLargeFat32 = (($build -eq 26100) -and ($ubr -ge 8313)) -or ($build -ge 26200)

    return [pscustomobject]@{
        Build              = $build
        UBR                = $ubr
        DisplayVersion     = $display
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

# --------------------------------------------------------------------------
# Picker
# --------------------------------------------------------------------------

function New-VolumePicker {
    param([object[]]$Volumes)

    Add-Type -AssemblyName System.Windows.Forms -ErrorAction Stop
    Add-Type -AssemblyName System.Drawing -ErrorAction Stop
    Enable-VisualStyles

    $form = New-Object System.Windows.Forms.Form
    $form.Text = Get-UiText 'PickerTitle'
    $form.ClientSize = New-Object System.Drawing.Size(640, 350)
    $form.StartPosition = 'CenterScreen'
    $form.FormBorderStyle = 'FixedDialog'
    $form.MaximizeBox = $false
    $form.MinimizeBox = $false
    $form.TopMost = $true
    $form.Font = New-Object System.Drawing.Font 'Segoe UI', 9

    $intro = New-Object System.Windows.Forms.Label
    $intro.Text = Get-UiText 'PickerIntro'
    $intro.Location = New-Object System.Drawing.Point(14, 12)
    $intro.AutoSize = $true
    $form.Controls.Add($intro)

    $list = New-Object System.Windows.Forms.ListBox
    $list.Location = New-Object System.Drawing.Point(14, 38)
    $list.Size = New-Object System.Drawing.Size(612, 230)
    $list.Font = New-Object System.Drawing.Font 'Consolas', 9.5
    $list.IntegralHeight = $false
    $noLabel = Get-UiText 'VolumeNoLabel'
    foreach ($volume in $Volumes) {
        $name = if ($volume.Label) { $volume.Label } else { $noLabel }
        $fs = if ($volume.FileSystem) { $volume.FileSystem } else { Get-UiText 'VolumeRaw' }
        $null = $list.Items.Add((Get-UiText 'VolumeListItem' @($volume.Letter, $name, (Format-Size $volume.SizeBytes), $fs)))
    }
    $list.SelectedIndex = 0
    $form.Controls.Add($list)

    $warning = New-Object System.Windows.Forms.Label
    $warning.Text = Get-UiText 'PickerWarning'
    $warning.ForeColor = [System.Drawing.Color]::Firebrick
    $warning.Location = New-Object System.Drawing.Point(14, 274)
    $warning.AutoSize = $true
    $form.Controls.Add($warning)

    $ok = New-Object System.Windows.Forms.Button
    $ok.Text = Get-UiText 'PickerOk'
    $ok.Size = New-Object System.Drawing.Size(180, 30)
    $ok.Location = New-Object System.Drawing.Point(268, 300)
    $ok.DialogResult = [System.Windows.Forms.DialogResult]::OK
    $form.Controls.Add($ok)

    $cancel = New-Object System.Windows.Forms.Button
    $cancel.Text = Get-UiText 'PickerCancel'
    $cancel.Size = New-Object System.Drawing.Size(160, 30)
    $cancel.Location = New-Object System.Drawing.Point(466, 300)
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
        Show-Dialog -Text (Get-UiText 'PickerEmpty') -Icon Warning | Out-Null
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
# Formatting
# --------------------------------------------------------------------------

function Invoke-NativeFormat {
    param(
        [string]$Letter,
        [string]$NewLabel,
        [string]$ClusterBytes
    )

    $exe = Join-Path $env:SystemRoot 'System32\format.com'
    if (-not (Test-Path -LiteralPath $exe)) {
        throw (Get-UiText 'ErrorFormatMissing' @($env:SystemRoot))
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

    try {
        $process.StandardInput.Write("Y`r`n")
        $process.StandardInput.Close()
    }
    catch {
        # Standard input may already be closed; harmless with /Y.
    }

    $finished = $process.WaitForExit(900000)
    if (-not $finished) {
        try { $process.Kill() } catch { }
        throw (Get-UiText 'ErrorFormatTimeout')
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
# Main
# --------------------------------------------------------------------------

Initialize-Localization -Requested $Language
Initialize-Log

try {
    if ($SelfTest) {
        $fake = @([pscustomobject]@{
            Letter     = 'E'
            Label      = 'TEST'
            FileSystem = 'exFAT'
            SizeBytes  = [uint64]64GB
            DriveType  = 2
        })
        $picker = New-VolumePicker -Volumes $fake
        $itemCount = $picker.List.Items.Count
        $picker.Form.Dispose()
        $volumes = @(Get-RemovableVolumes)
        $buildInfo = Get-WindowsBuildInfo
        Write-Host ("SelfTest OK | PowerShell {0} | Admin={1} | Removable={2} | Picker={3} item(s)" -f $PSVersionTable.PSVersion, (Test-IsAdmin), $volumes.Count, $itemCount)
        Write-Host ("Language: {0} | {1} | FAT32 > 32 GB: {2}" -f $script:LanguageCode, $buildInfo.VersionText, $(if ($buildInfo.SupportsLargeFat32) { 'supported' } else { 'NOT supported' }))
        exit 0
    }

    $isAdmin = Test-IsAdmin

    if (-not $isAdmin -and -not $DryRun -and -not $Elevated) {
        Add-LogEntry "Elevation requested (initial request: Drive=$Drive, Language=$($script:LanguageCode))."
        $shell = Join-Path $env:SystemRoot 'System32\WindowsPowerShell\v1.0\powershell.exe'
        $arguments = @('-NoProfile', '-ExecutionPolicy', 'Bypass', '-WindowStyle', 'Hidden', '-STA',
            '-File', (ConvertTo-QuotedArgument $PSCommandPath),
            '-Language', $script:LanguageCode)
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
            Add-LogEntry ("Elevation denied: " + $_.Exception.Message)
            Show-Dialog -Text (Get-UiText 'ErrorElevationDenied' @($_.Exception.Message)) -Icon Warning | Out-Null
            exit 4
        }
        exit 0
    }

    $letter = Resolve-DriveLetter $Drive
    if (-not $letter) {
        if ($Drive) { throw (Get-UiText 'ErrorInvalidLetter' @($Drive)) }
        $picked = Select-RemovableVolume
        if (-not $picked) {
            Add-LogEntry 'No drive selected: aborted.'
            exit 2
        }
        $letter = $picked.Letter
    }

    $disk = Get-DiskInfo $letter
    if (-not $disk) {
        throw (Get-UiText 'ErrorDriveMissing' @($letter))
    }

    $systemLetter = $env:SystemDrive.Substring(0, 1)
    if ($letter -eq $systemLetter) {
        throw (Get-UiText 'ErrorSystemDrive' @($letter))
    }

    $driveType = [int]$disk.DriveType
    if ($driveType -eq 4 -or $driveType -eq 5) {
        throw (Get-UiText 'ErrorUnsupportedType' @($letter, (Get-DriveTypeName $driveType)))
    }
    if ($driveType -ne 2 -and -not $AllowFixed) {
        throw (Get-UiText 'ErrorNotRemovable' @($letter, (Get-DriveTypeName $driveType)))
    }
    if (-not $disk.Size) {
        throw (Get-UiText 'ErrorNoMedia' @($letter))
    }

    $sizeBytes = [uint64]$disk.Size
    if ($sizeBytes -gt 2TB) {
        throw (Get-UiText 'ErrorTooBig' @((Format-Size $sizeBytes)))
    }

    $buildInfo = Get-WindowsBuildInfo
    if ($sizeBytes -gt 32GB -and -not $buildInfo.SupportsLargeFat32) {
        if (-not $SkipVersionCheck) {
            throw (Get-UiText 'ErrorBuildTooOld' @($buildInfo.VersionText))
        }
        Add-LogEntry ("Build check bypassed (build {0}.{1})." -f $buildInfo.Build, $buildInfo.UBR)
    }

    $currentLabel = [string]$disk.VolumeName
    $newLabel = $currentLabel
    if ($Label) { $newLabel = $Label }
    if ($newLabel.Length -gt 11) { $newLabel = $newLabel.Substring(0, 11) }
    $currentFs = if ($disk.FileSystem) { [string]$disk.FileSystem } else { Get-UiText 'VolumeRaw' }

    $clusterBytes = 0
    if ($ClusterSizeKb -gt 0) { $clusterBytes = $ClusterSizeKb * 1KB }

    $labelBefore = if ($currentLabel) { $currentLabel } else { Get-UiText 'VolumeNoLabel' }
    $labelAfter = if ($newLabel) { $newLabel } else { Get-UiText 'VolumeNoLabel' }
    $sizeText = Format-Size $sizeBytes
    $supportText = if ($buildInfo.SupportsLargeFat32) { Get-UiText 'SupportYes' } else { Get-UiText 'SupportNo' }

    $previewArgs = @(('{0}:' -f $letter), '/FS:FAT32', '/Q', '/Y')
    if ($newLabel) { $previewArgs += ('/V:{0}' -f $newLabel) }
    if ($clusterBytes) { $previewArgs += ('/A:{0}' -f $clusterBytes) }

    if ($DryRun) {
        try { [Console]::OutputEncoding = New-Object System.Text.UTF8Encoding($false) } catch { }
        Write-Host (Get-UiText 'DryRunTitle')
        Write-Host ('-' * 62)
        Write-Host (Get-UiText 'DryRunDrive' @($letter))
        Write-Host (Get-UiText 'DryRunLabel' @($labelBefore, $labelAfter))
        Write-Host (Get-UiText 'DryRunFs' @($currentFs))
        Write-Host (Get-UiText 'DryRunCapacity' @($sizeText))
        Write-Host (Get-UiText 'DryRunType' @((Get-DriveTypeName $driveType)))
        Write-Host (Get-UiText 'DryRunQuick')
        Write-Host (Get-UiText 'DryRunWindows' @($buildInfo.VersionText, $supportText))
        Write-Host (Get-UiText 'DryRunCommand' @($previewArgs -join ' '))
        exit 0
    }

    $removableText = if ($driveType -eq 2) { Get-UiText 'RemovableYes' } else { Get-UiText 'RemovableNo' }
    $confirm = Get-UiText 'ConfirmBody' @($letter, $labelBefore, $sizeText, $currentFs, $removableText, $buildInfo.VersionText)

    Add-LogEntry ("Format request: drive={0} type={1} fs={2} size={3} label='{4}' lang={5}" -f $letter, $driveType, $currentFs, $sizeBytes, $currentLabel, $script:LanguageCode)

    if (-not $Yes) {
        $answer = Show-Dialog -Text $confirm -Title (Get-UiText 'ConfirmTitle') -Icon Warning -Buttons YesNo
        if ($answer -ne 'Yes') {
            Add-LogEntry 'Cancelled by user.'
            exit 2
        }
    }

    $watch = [System.Diagnostics.Stopwatch]::StartNew()
    $result = Invoke-NativeFormat -Letter $letter -NewLabel $newLabel -ClusterBytes $clusterBytes
    $watch.Stop()

    Add-LogEntry ("{0} -> exit code {1}" -f $result.Command, $result.ExitCode)
    if ($result.Output) { Add-LogEntry $result.Output }

    $after = Wait-ForFat32 -Letter $letter
    $success = [bool]($after -and ([string]$after.FileSystem).ToUpperInvariant() -eq 'FAT32' -and [uint64]$after.Size -gt 0)

    if (-not $success) {
        $details = [string]$result.Output
        if ($details.Length -gt 1200) { $details = $details.Substring($details.Length - 1200) }
        Add-LogEntry ("Format FAILED (exit code {0})." -f $result.ExitCode)
        $failureText = Get-UiText 'FailureBody' @($letter, $result.Tool, $result.ExitCode, $details, (Get-LogPath))
        Show-Dialog -Icon Error -Title (Get-UiText 'FailureTitle') -Text $failureText | Out-Null
        exit 3
    }

    $volume = Get-VolumeDetails $letter
    $clusterText = Get-UiText 'ClusterUnknown'
    if ($volume -and $volume.BlockSize) { $clusterText = ('{0:N0} {1}' -f ($volume.BlockSize / 1KB), (Get-UiText 'SizeKB')) }
    $finalLabel = [string]$after.VolumeName
    if (-not $finalLabel) { $finalLabel = Get-UiText 'VolumeNoLabel' }

    Add-LogEntry ("SUCCESS: {0}: formatted as FAT32, label='{1}', duration={2:N1}s" -f $letter, $finalLabel, $watch.Elapsed.TotalSeconds)

    $successText = Get-UiText 'SuccessBody' @($letter, $finalLabel, (Format-Size ([uint64]$after.Size)), $clusterText, [int]$watch.Elapsed.TotalSeconds, (Get-LogPath))
    Show-Dialog -Icon Information -Title (Get-UiText 'SuccessTitle') -Text $successText | Out-Null

    exit 0
}
catch {
    $message = $_.Exception.Message
    Add-LogEntry ("ERROR: {0}" -f $message)
    if ($DryRun) {
        Write-Host ("ERROR: {0}" -f $message) -ForegroundColor Red
        exit 1
    }
    Show-Dialog -Icon Error -Title (Get-UiText 'ErrorTitle') -Text (Get-UiText 'ErrorBody' @($message, (Get-LogPath))) | Out-Null
    exit 1
}
