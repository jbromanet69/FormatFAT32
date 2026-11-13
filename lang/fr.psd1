@{
    LanguageName    = 'French'
    LanguageNative  = 'Français'

    DialogTitle     = 'Format FAT32'
    ErrorTitle      = 'Format FAT32'
    ConfirmTitle    = 'Confirmer le formatage FAT32'
    SuccessTitle    = 'Formatage terminé'
    FailureTitle    = 'Échec du formatage'
    PickerTitle     = 'Formater en FAT32'

    PickerIntro     = 'Sélectionnez le disque amovible à formater en FAT32 :'
    PickerWarning   = 'Le contenu du disque sélectionné sera définitivement effacé.'
    PickerOk        = 'Formater en FAT32'
    PickerCancel    = 'Annuler'
    PickerEmpty     = "Aucun disque amovible prêt n'a été détecté.`r`n`r`nInsérez une carte SD ou une clé USB, puis réessayez."
    VolumeListItem  = '{0}:  {1,-18} {2,10}  {3}'
    VolumeNoLabel   = '(sans nom)'
    VolumeRaw       = 'RAW'

    SizeGB          = 'Go'
    SizeMB          = 'Mo'
    SizeKB          = 'Ko'
    SizeBytes       = 'octets'

    DriveTypeUnknown   = 'Inconnu'
    DriveTypeNoRoot    = 'Sans racine'
    DriveTypeRemovable = 'Amovible'
    DriveTypeFixed     = 'Fixe'
    DriveTypeNetwork   = 'Réseau'
    DriveTypeCdRom     = 'CD-ROM'
    DriveTypeRam       = 'Disque RAM'
    DriveTypeOther     = 'Type {0}'

    SupportYes      = 'pris en charge'
    SupportNo       = 'NON pris en charge'
    RemovableYes    = 'oui'
    RemovableNo     = 'NON (option -AllowFixed)'

    ButtonOk        = 'OK'
    ButtonCancel    = 'Annuler'
    ButtonYes       = 'Oui'
    ButtonNo        = 'Non'

    ConfirmBody     = "Formater le disque {0}: en FAT32 ?`r`n`r`nLibellé          : {1}`r`nCapacité         : {2}`r`nSystème actuel   : {3}`r`nAmovible         : {4}`r`nWindows          : {5}`r`n`r`nToutes les données de ce disque seront définitivement effacées.`r`nContinuer ?"

    DryRunTitle     = 'Plan de formatage (simulation)'
    DryRunDrive     = 'Lecteur             : {0}:'
    DryRunLabel     = 'Libellé             : {0} -> {1}'
    DryRunFs        = 'Système de fichiers : {0} -> FAT32'
    DryRunCapacity  = 'Capacité            : {0}'
    DryRunType      = 'Type                : {0}'
    DryRunQuick     = 'Mode                : formatage rapide'
    DryRunWindows   = 'Windows             : {0} (FAT32 > 32 Go : {1})'
    DryRunCommand   = 'Commande            : format {0}'

    SuccessBody     = "Le disque {0}: est maintenant en FAT32.`r`n`r`nLibellé          : {1}`r`nCapacité         : {2}`r`nTaille cluster   : {3}`r`nDurée            : {4} s`r`n`r`nRappel : en FAT32, un fichier ne peut pas dépasser 4 Go.`r`n`r`nJournal : {5}"
    FailureBody     = "Le formatage de {0}: en FAT32 a échoué.`r`n`r`nCauses possibles :`r`n- cette version de Windows ne crée pas de FAT32 au-delà de 32 Go`r`n  (vérifiez avec winver : prise en charge à partir des builds`r`n  26100.8313 / 26200.8313 ; sinon mettez Windows à jour) ;`r`n- carte protégée en écriture ou utilisée par un autre programme ;`r`n- carte défectueuse.`r`n`r`nSortie de {1} (code {2}) :`r`n{3}`r`n`r`nJournal : {4}"
    ErrorBody       = "{0}`r`n`r`nJournal : {1}"

    ErrorInvalidLetter   = "Lettre de lecteur invalide : « {0} »."
    ErrorDriveMissing    = "Le lecteur {0}: n'existe pas ou n'est pas accessible.`r`nVérifiez la carte, puis relancez."
    ErrorSystemDrive     = "Le disque système ({0}:) ne peut pas être formaté par cet outil."
    ErrorUnsupportedType = "Le lecteur {0}: est de type « {1} » : formatage impossible."
    ErrorNotRemovable    = "Le lecteur {0}: est de type « {1} » et non « Amovible ».`r`n`r`nCet outil est réservé aux cartes SD et clés USB.`r`nSi un lecteur de cartes se déclare « Fixe », utilisez l'option -AllowFixed."
    ErrorNoMedia         = "Aucun média détecté dans le lecteur {0}:`r`nInsérez une carte, puis relancez."
    ErrorTooBig          = 'Le volume fait {0} : au-delà de la limite FAT32 (2 To).'
    ErrorBuildTooOld     = "Ce PC ne peut pas créer un volume FAT32 de plus de 32 Go.`r`n`r`nDétecté  : {0}`r`nRequis   : Windows 11 24H2 build 26100.8313 ou 25H2 build 26200.8313 (ou ultérieure).`r`n`r`nMettez Windows à jour (Paramètres > Windows Update), puis relancez.`r`nPour passer outre ce contrôle : option -SkipVersionCheck."
    ErrorElevationDenied = "Droits administrateur requis pour formater un disque.`r`n`r`nL'élévation a été refusée ou annulée.`r`n`r`n{0}"
    ErrorFormatMissing   = 'format.com est introuvable dans {0}\System32.'
    ErrorFormatTimeout   = "Délai dépassé : format.com n'a pas terminé en 15 minutes."
    ClusterUnknown       = 'inconnue'
}
