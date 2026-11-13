@{
    LanguageName    = 'Dutch'
    LanguageNative  = 'Nederlands'

    DialogTitle     = 'Formatteren als FAT32'
    ErrorTitle      = 'Formatteren als FAT32'
    ConfirmTitle    = 'FAT32-formattering bevestigen'
    SuccessTitle    = 'Formatteren voltooid'
    FailureTitle    = 'Formatteren mislukt'
    PickerTitle     = 'Formatteren als FAT32'

    PickerIntro     = 'Selecteer het verwisselbare station dat als FAT32 geformatteerd moet worden:'
    PickerWarning   = 'De inhoud van het geselecteerde station wordt definitief gewist.'
    PickerOk        = 'Formatteren als FAT32'
    PickerCancel    = 'Annuleren'
    PickerEmpty     = "Geen gereed verwisselbaar station gevonden.`r`n`r`nPlaats een SD-kaart of USB-stick en probeer het opnieuw."
    VolumeListItem  = '{0}:  {1,-18} {2,10}  {3}'
    VolumeNoLabel   = '(geen naam)'
    VolumeRaw       = 'RAW'

    SizeGB          = 'GB'
    SizeMB          = 'MB'
    SizeKB          = 'KB'
    SizeBytes       = 'bytes'

    DriveTypeUnknown   = 'Onbekend'
    DriveTypeNoRoot    = 'Zonder hoofdmap'
    DriveTypeRemovable = 'Verwisselbaar'
    DriveTypeFixed     = 'Vast'
    DriveTypeNetwork   = 'Netwerk'
    DriveTypeCdRom     = 'CD-ROM'
    DriveTypeRam       = 'RAM-schijf'
    DriveTypeOther     = 'Type {0}'

    SupportYes      = 'ondersteund'
    SupportNo       = 'NIET ondersteund'
    RemovableYes    = 'ja'
    RemovableNo     = 'NEE (optie -AllowFixed)'

    ButtonOk        = 'OK'
    ButtonCancel    = 'Annuleren'
    ButtonYes       = 'Ja'
    ButtonNo        = 'Nee'

    ConfirmBody     = "Station {0}: als FAT32 formatteren?`r`n`r`nLabel            : {1}`r`nCapaciteit       : {2}`r`nHuidig systeem   : {3}`r`nVerwisselbaar    : {4}`r`nWindows          : {5}`r`n`r`nAlle gegevens op dit station worden definitief gewist.`r`nDoorgaan?"

    DryRunTitle     = 'Formatteringsplan (simulatie)'
    DryRunDrive     = 'Station             : {0}:'
    DryRunLabel     = 'Label               : {0} -> {1}'
    DryRunFs        = 'Bestandssysteem     : {0} -> FAT32'
    DryRunCapacity  = 'Capaciteit          : {0}'
    DryRunType      = 'Type                : {0}'
    DryRunQuick     = 'Modus               : snelle formattering'
    DryRunWindows   = 'Windows             : {0} (FAT32 > 32 GB: {1})'
    DryRunCommand   = 'Opdracht            : format {0}'

    SuccessBody     = "Station {0}: is nu FAT32.`r`n`r`nLabel            : {1}`r`nCapaciteit       : {2}`r`nClustergrootte   : {3}`r`nDuur             : {4} s`r`n`r`nHerinnering: onder FAT32 mag één bestand maximaal 4 GB zijn.`r`n`r`nLogboek: {5}"
    FailureBody     = "Het formatteren van {0}: als FAT32 is mislukt.`r`n`r`nMogelijke oorzaken:`r`n- deze Windows-versie maakt geen FAT32 boven 32 GB`r`n  (controleer met winver: ondersteuning vanaf builds`r`n  26100.8313 / 26200.8313; werk anders Windows bij);`r`n- de kaart is schrijfbeveiligd of wordt door een ander programma gebruikt;`r`n- de kaart is defect.`r`n`r`nUitvoer van {1} (code {2}):`r`n{3}`r`n`r`nLogboek: {4}"
    ErrorBody       = "{0}`r`n`r`nLogboek: {1}"

    ErrorInvalidLetter   = 'Ongeldige stationsletter: «{0}».'
    ErrorDriveMissing    = "Station {0}: bestaat niet of is niet bereikbaar.`r`nControleer de kaart en probeer het opnieuw."
    ErrorSystemDrive     = "Het systeemstation ({0}:) kan niet met dit hulpprogramma worden geformatteerd."
    ErrorUnsupportedType = "Station {0}: is van het type «{1}»: formatteren is niet mogelijk."
    ErrorNotRemovable    = "Station {0}: is van het type «{1}» en niet «Verwisselbaar».`r`n`r`nDit hulpprogramma is bedoeld voor SD-kaarten en USB-sticks.`r`nMeldt een kaartlezer «Vast», gebruik dan de optie -AllowFixed."
    ErrorNoMedia         = "Geen medium gevonden in station {0}:`r`nPlaats een kaart en probeer het opnieuw."
    ErrorTooBig          = 'Het volume is {0}, boven de FAT32-limiet (2 TB).'
    ErrorBuildTooOld     = "Deze pc kan geen FAT32-volume groter dan 32 GB maken.`r`n`r`nGedetecteerd : {0}`r`nVereist      : Windows 11 24H2 build 26100.8313 of 25H2 build 26200.8313 (of nieuwer).`r`n`r`nWerk Windows bij (Instellingen > Windows Update) en probeer het opnieuw.`r`nDeze controle omzeilen: optie -SkipVersionCheck."
    ErrorElevationDenied = "Beheerdersrechten zijn nodig om een station te formatteren.`r`n`r`nDe verhoging is geweigerd of geannuleerd.`r`n`r`n{0}"
    ErrorFormatMissing   = 'format.com is niet gevonden in {0}\System32.'
    ErrorFormatTimeout   = 'Time-out: format.com was na 15 minuten niet klaar.'
    ClusterUnknown       = 'onbekend'
}
