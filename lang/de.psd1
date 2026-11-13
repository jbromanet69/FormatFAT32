@{
    LanguageName    = 'German'
    LanguageNative  = 'Deutsch'

    DialogTitle     = 'FAT32 formatieren'
    ErrorTitle      = 'FAT32 formatieren'
    ConfirmTitle    = 'FAT32-Formatierung bestätigen'
    SuccessTitle    = 'Formatierung abgeschlossen'
    FailureTitle    = 'Formatierung fehlgeschlagen'
    PickerTitle     = 'Als FAT32 formatieren'

    PickerIntro     = 'Wählen Sie das Laufwerk, das als FAT32 formatiert werden soll:'
    PickerWarning   = 'Der Inhalt des ausgewählten Laufwerks wird endgültig gelöscht.'
    PickerOk        = 'Als FAT32 formatieren'
    PickerCancel    = 'Abbrechen'
    PickerEmpty     = "Kein bereites Wechseldatenträger-Laufwerk gefunden.`r`n`r`nLegen Sie eine SD-Karte oder einen USB-Stick ein und versuchen Sie es erneut."
    VolumeListItem  = '{0}:  {1,-18} {2,10}  {3}'
    VolumeNoLabel   = '(ohne Name)'
    VolumeRaw       = 'RAW'

    SizeGB          = 'GB'
    SizeMB          = 'MB'
    SizeKB          = 'KB'
    SizeBytes       = 'Bytes'

    DriveTypeUnknown   = 'Unbekannt'
    DriveTypeNoRoot    = 'Ohne Stammverzeichnis'
    DriveTypeRemovable = 'Wechseldatenträger'
    DriveTypeFixed     = 'Festplatte'
    DriveTypeNetwork   = 'Netzwerk'
    DriveTypeCdRom     = 'CD-ROM'
    DriveTypeRam       = 'RAM-Laufwerk'
    DriveTypeOther     = 'Typ {0}'

    SupportYes      = 'unterstützt'
    SupportNo       = 'NICHT unterstützt'
    RemovableYes    = 'ja'
    RemovableNo     = 'NEIN (Option -AllowFixed)'

    ButtonOk        = 'OK'
    ButtonCancel    = 'Abbrechen'
    ButtonYes       = 'Ja'
    ButtonNo        = 'Nein'

    ConfirmBody     = "Laufwerk {0}: als FAT32 formatieren?`r`n`r`nBezeichnung      : {1}`r`nKapazität        : {2}`r`nAktuelles FS     : {3}`r`nWechselmedienträger: {4}`r`nWindows          : {5}`r`n`r`nAlle Daten auf diesem Laufwerk werden endgültig gelöscht.`r`nFortfahren?"

    DryRunTitle     = 'Formatierungsplan (Simulation)'
    DryRunDrive     = 'Laufwerk            : {0}:'
    DryRunLabel     = 'Bezeichnung         : {0} -> {1}'
    DryRunFs        = 'Dateisystem         : {0} -> FAT32'
    DryRunCapacity  = 'Kapazität           : {0}'
    DryRunType      = 'Typ                 : {0}'
    DryRunQuick     = 'Modus               : Schnellformatierung'
    DryRunWindows   = 'Windows             : {0} (FAT32 > 32 GB: {1})'
    DryRunCommand   = 'Befehl              : format {0}'

    SuccessBody     = "Laufwerk {0}: ist jetzt FAT32.`r`n`r`nBezeichnung      : {1}`r`nKapazität        : {2}`r`nClustergröße     : {3}`r`nDauer            : {4} s`r`n`r`nHinweis: unter FAT32 darf eine Datei höchstens 4 GB groß sein.`r`n`r`nProtokoll: {5}"
    FailureBody     = "Das Formatieren von {0}: als FAT32 ist fehlgeschlagen.`r`n`r`nMögliche Ursachen:`r`n- diese Windows-Version erstellt kein FAT32 über 32 GB`r`n  (winver prüfen: Unterstützung ab Build 26100.8313 / 26200.8313;`r`n  sonst Windows aktualisieren);`r`n- die Karte ist schreibgeschützt oder wird von einem anderen Programm verwendet;`r`n- die Karte ist defekt.`r`n`r`nAusgabe von {1} (Code {2}):`r`n{3}`r`n`r`nProtokoll: {4}"
    ErrorBody       = "{0}`r`n`r`nProtokoll: {1}"

    ErrorInvalidLetter   = "Ungültiger Laufwerksbuchstabe: «{0}»."
    ErrorDriveMissing    = "Laufwerk {0}: existiert nicht oder ist nicht erreichbar.`r`nPrüfen Sie die Karte und versuchen Sie es erneut."
    ErrorSystemDrive     = "Das Systemlaufwerk ({0}:) kann mit diesem Tool nicht formatiert werden."
    ErrorUnsupportedType = "Laufwerk {0}: ist vom Typ «{1}»: Formatieren ist nicht möglich."
    ErrorNotRemovable    = "Laufwerk {0}: ist vom Typ «{1}» und nicht «Wechseldatenträger».`r`n`r`nDieses Tool ist für SD-Karten und USB-Sticks gedacht.`r`nMeldet ein Kartenleser «Festplatte», verwenden Sie die Option -AllowFixed."
    ErrorNoMedia         = "Kein Medium in Laufwerk {0}: gefunden.`r`nLegen Sie eine Karte ein und versuchen Sie es erneut."
    ErrorTooBig          = 'Das Volume ist {0} groß und überschreitet damit das FAT32-Limit (2 TB).'
    ErrorBuildTooOld     = "Dieser PC kann kein FAT32-Volume über 32 GB erstellen.`r`n`r`nErkannt  : {0}`r`nErforderlich: Windows 11 24H2 Build 26100.8313 oder 25H2 Build 26200.8313 (oder neuer).`r`n`r`nAktualisieren Sie Windows (Einstellungen > Windows Update) und versuchen Sie es erneut.`r`nZum Umgehen dieser Prüfung: Option -SkipVersionCheck."
    ErrorElevationDenied = "Zum Formatieren eines Laufwerks sind Administratorrechte erforderlich.`r`n`r`nDie Erhöhung wurde abgelehnt oder abgebrochen.`r`n`r`n{0}"
    ErrorFormatMissing   = 'format.com wurde in {0}\System32 nicht gefunden.'
    ErrorFormatTimeout   = 'Zeitüberschreitung: format.com war nach 15 Minuten nicht fertig.'
    ClusterUnknown       = 'unbekannt'
}
