@{
    LanguageName    = 'English'
    LanguageNative  = 'English'

    DialogTitle     = 'Format FAT32'
    ErrorTitle      = 'Format FAT32'
    ConfirmTitle    = 'Confirm FAT32 formatting'
    SuccessTitle    = 'Format completed'
    FailureTitle    = 'Formatting failed'
    PickerTitle     = 'Format as FAT32'

    PickerIntro     = 'Select the removable drive to format as FAT32:'
    PickerWarning   = 'The contents of the selected drive will be permanently erased.'
    PickerOk        = 'Format as FAT32'
    PickerCancel    = 'Cancel'
    PickerEmpty     = "No ready removable drive was found.`r`n`r`nInsert an SD card or a USB drive, then try again."
    VolumeListItem  = '{0}:  {1,-18} {2,10}  {3}'
    VolumeNoLabel   = '(no label)'
    VolumeRaw       = 'RAW'

    SizeGB          = 'GB'
    SizeMB          = 'MB'
    SizeKB          = 'KB'
    SizeBytes       = 'bytes'

    DriveTypeUnknown   = 'Unknown'
    DriveTypeNoRoot    = 'No root directory'
    DriveTypeRemovable = 'Removable'
    DriveTypeFixed     = 'Fixed'
    DriveTypeNetwork   = 'Network'
    DriveTypeCdRom     = 'CD-ROM'
    DriveTypeRam       = 'RAM disk'
    DriveTypeOther     = 'Type {0}'

    SupportYes      = 'supported'
    SupportNo       = 'NOT supported'
    RemovableYes    = 'yes'
    RemovableNo     = 'NO (option -AllowFixed)'

    ButtonOk        = 'OK'
    ButtonCancel    = 'Cancel'
    ButtonYes       = 'Yes'
    ButtonNo        = 'No'

    ConfirmBody     = "Format drive {0}: as FAT32?`r`n`r`nLabel           : {1}`r`nCapacity        : {2}`r`nCurrent FS      : {3}`r`nRemovable       : {4}`r`nWindows         : {5}`r`n`r`nAll data on this drive will be permanently erased.`r`nContinue?"

    DryRunTitle     = 'Formatting plan (simulation)'
    DryRunDrive     = 'Drive               : {0}:'
    DryRunLabel     = 'Label               : {0} -> {1}'
    DryRunFs        = 'File system         : {0} -> FAT32'
    DryRunCapacity  = 'Capacity            : {0}'
    DryRunType      = 'Type                : {0}'
    DryRunQuick     = 'Mode                : quick format'
    DryRunWindows   = 'Windows             : {0} (FAT32 > 32 GB: {1})'
    DryRunCommand   = 'Command             : format {0}'

    SuccessBody     = "Drive {0}: is now FAT32.`r`n`r`nLabel           : {1}`r`nCapacity        : {2}`r`nCluster size    : {3}`r`nDuration        : {4} s`r`n`r`nReminder: on FAT32 a single file cannot exceed 4 GB.`r`n`r`nLog: {5}"
    FailureBody     = "Formatting drive {0}: as FAT32 failed.`r`n`r`nPossible causes:`r`n- this Windows build cannot create FAT32 volumes above 32 GB`r`n  (run winver: support starts with builds 26100.8313 / 26200.8313;`r`n  otherwise update Windows);`r`n- the card is write-protected or used by another program;`r`n- the card is faulty.`r`n`r`n{1} output (exit code {2}):`r`n{3}`r`n`r`nLog: {4}"
    ErrorBody       = "{0}`r`n`r`nLog: {1}"

    ErrorInvalidLetter   = "Invalid drive letter: '{0}'."
    ErrorDriveMissing    = "Drive {0}: does not exist or is not accessible.`r`nCheck the card, then try again."
    ErrorSystemDrive     = "The system drive ({0}:) cannot be formatted by this tool."
    ErrorUnsupportedType = "Drive {0}: is of type « {1} »: formatting is not possible."
    ErrorNotRemovable    = "Drive {0}: is of type « {1} », not « Removable ».`r`n`r`nThis tool is meant for SD cards and USB drives.`r`nIf a card reader reports « Fixed », use the -AllowFixed option."
    ErrorNoMedia         = "No media detected in drive {0}:`r`nInsert a card, then try again."
    ErrorTooBig          = 'The volume is {0}, beyond the FAT32 limit (2 TB).'
    ErrorBuildTooOld     = "This PC cannot create a FAT32 volume larger than 32 GB.`r`n`r`nDetected : {0}`r`nRequired : Windows 11 24H2 build 26100.8313 or 25H2 build 26200.8313 (or later).`r`n`r`nUpdate Windows (Settings > Windows Update), then try again.`r`nTo bypass this check: -SkipVersionCheck option."
    ErrorElevationDenied = "Administrator rights are required to format a drive.`r`n`r`nElevation was refused or cancelled.`r`n`r`n{0}"
    ErrorFormatMissing   = 'format.com was not found in {0}\System32.'
    ErrorFormatTimeout   = 'Timeout: format.com did not finish within 15 minutes.'
    ClusterUnknown       = 'unknown'
}
