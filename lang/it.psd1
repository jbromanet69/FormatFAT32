@{
    LanguageName    = 'Italian'
    LanguageNative  = 'Italiano'

    DialogTitle     = 'Formatta in FAT32'
    ErrorTitle      = 'Formatta in FAT32'
    ConfirmTitle    = 'Conferma la formattazione FAT32'
    SuccessTitle    = 'Formattazione completata'
    FailureTitle    = 'Formattazione non riuscita'
    PickerTitle     = 'Formatta in FAT32'

    PickerIntro     = "Selezionare l'unità rimovibile da formattare in FAT32:"
    PickerWarning   = "Il contenuto dell'unità selezionata verrà eliminato definitivamente."
    PickerOk        = 'Formatta in FAT32'
    PickerCancel    = 'Annulla'
    PickerEmpty     = "Nessuna unità rimovibile pronta trovata.`r`n`r`nInserire una scheda SD o una chiavetta USB e riprovare."
    VolumeListItem  = '{0}:  {1,-18} {2,10}  {3}'
    VolumeNoLabel   = '(senza nome)'
    VolumeRaw       = 'RAW'

    SizeGB          = 'GB'
    SizeMB          = 'MB'
    SizeKB          = 'KB'
    SizeBytes       = 'byte'

    DriveTypeUnknown   = 'Sconosciuto'
    DriveTypeNoRoot    = 'Senza directory radice'
    DriveTypeRemovable = 'Rimovibile'
    DriveTypeFixed     = 'Fisso'
    DriveTypeNetwork   = 'Rete'
    DriveTypeCdRom     = 'CD-ROM'
    DriveTypeRam       = 'Unità RAM'
    DriveTypeOther     = 'Tipo {0}'

    SupportYes      = 'supportato'
    SupportNo       = 'NON supportato'
    RemovableYes    = 'sì'
    RemovableNo     = 'NO (opzione -AllowFixed)'

    ButtonOk        = 'OK'
    ButtonCancel    = 'Annulla'
    ButtonYes       = 'Sì'
    ButtonNo        = 'No'

    ConfirmBody     = "Formattare l'unità {0}: in FAT32?`r`n`r`nEtichetta        : {1}`r`nCapacità         : {2}`r`nFile system      : {3}`r`nRimovibile       : {4}`r`nWindows          : {5}`r`n`r`nTutti i dati di questa unità saranno eliminati definitivamente.`r`nContinuare?"

    DryRunTitle     = 'Piano di formattazione (simulazione)'
    DryRunDrive     = 'Unità               : {0}:'
    DryRunLabel     = 'Etichetta           : {0} -> {1}'
    DryRunFs        = 'File system         : {0} -> FAT32'
    DryRunCapacity  = 'Capacità            : {0}'
    DryRunType      = 'Tipo                : {0}'
    DryRunQuick     = 'Modalità            : formattazione rapida'
    DryRunWindows   = 'Windows             : {0} (FAT32 > 32 GB: {1})'
    DryRunCommand   = 'Comando             : format {0}'

    SuccessBody     = "L'unità {0}: è ora in FAT32.`r`n`r`nEtichetta        : {1}`r`nCapacità         : {2}`r`nDimensione cluster: {3}`r`nDurata           : {4} s`r`n`r`nPromemoria: in FAT32 un file non può superare 4 GB.`r`n`r`nRegistro: {5}"
    FailureBody     = "La formattazione di {0}: in FAT32 non è riuscita.`r`n`r`nCause possibili:`r`n- questa versione di Windows non crea FAT32 oltre 32 GB`r`n  (verificare con winver: supporto dalle build`r`n  26100.8313 / 26200.8313; altrimenti aggiornare Windows);`r`n- la scheda è protetta da scrittura o usata da un altro programma;`r`n- la scheda è difettosa.`r`n`r`nOutput di {1} (codice {2}):`r`n{3}`r`n`r`nRegistro: {4}"
    ErrorBody       = "{0}`r`n`r`nRegistro: {1}"

    ErrorInvalidLetter   = 'Lettera di unità non valida: «{0}».'
    ErrorDriveMissing    = "L'unità {0}: non esiste o non è accessibile.`r`nControllare la scheda e riprovare."
    ErrorSystemDrive     = "L'unità di sistema ({0}:) non può essere formattata da questo strumento."
    ErrorUnsupportedType = "L'unità {0}: è di tipo «{1}»: formattazione impossibile."
    ErrorNotRemovable    = "L'unità {0}: è di tipo «{1}» e non «Rimovibile».`r`n`r`nQuesto strumento è pensato per schede SD e chiavette USB.`r`nSe un lettore di schede si dichiara «Fisso», usare l'opzione -AllowFixed."
    ErrorNoMedia         = "Nessun supporto rilevato nell'unità {0}:`r`nInserire una scheda e riprovare."
    ErrorTooBig          = 'Il volume è di {0}, oltre il limite FAT32 (2 TB).'
    ErrorBuildTooOld     = "Questo PC non può creare un volume FAT32 più grande di 32 GB.`r`n`r`nRilevato  : {0}`r`nRichiesto : Windows 11 24H2 build 26100.8313 o 25H2 build 26200.8313 (o successive).`r`n`r`nAggiornare Windows (Impostazioni > Windows Update) e riprovare.`r`nPer ignorare questo controllo: opzione -SkipVersionCheck."
    ErrorElevationDenied = "Sono necessari diritti di amministratore per formattare un'unità.`r`n`r`nL'elevazione è stata rifiutata o annullata.`r`n`r`n{0}"
    ErrorFormatMissing   = 'format.com non trovato in {0}\System32.'
    ErrorFormatTimeout   = 'Timeout: format.com non è terminato entro 15 minuti.'
    ClusterUnknown       = 'sconosciuta'
}
