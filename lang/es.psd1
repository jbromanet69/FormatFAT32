@{
    LanguageName    = 'Spanish'
    LanguageNative  = 'Español'

    DialogTitle     = 'Formatear en FAT32'
    ErrorTitle      = 'Formatear en FAT32'
    ConfirmTitle    = 'Confirmar el formateo FAT32'
    SuccessTitle    = 'Formateo completado'
    FailureTitle    = 'Error de formateo'
    PickerTitle     = 'Formatear en FAT32'

    PickerIntro     = 'Seleccione la unidad extraíble que desea formatear en FAT32:'
    PickerWarning   = 'El contenido de la unidad seleccionada se borrará de forma definitiva.'
    PickerOk        = 'Formatear en FAT32'
    PickerCancel    = 'Cancelar'
    PickerEmpty     = "No se ha encontrado ninguna unidad extraíble lista.`r`n`r`nInserte una tarjeta SD o una unidad USB e inténtelo de nuevo."
    VolumeListItem  = '{0}:  {1,-18} {2,10}  {3}'
    VolumeNoLabel   = '(sin nombre)'
    VolumeRaw       = 'RAW'

    SizeGB          = 'GB'
    SizeMB          = 'MB'
    SizeKB          = 'KB'
    SizeBytes       = 'bytes'

    DriveTypeUnknown   = 'Desconocido'
    DriveTypeNoRoot    = 'Sin directorio raíz'
    DriveTypeRemovable = 'Extraíble'
    DriveTypeFixed     = 'Fijo'
    DriveTypeNetwork   = 'Red'
    DriveTypeCdRom     = 'CD-ROM'
    DriveTypeRam       = 'Unidad RAM'
    DriveTypeOther     = 'Tipo {0}'

    SupportYes      = 'compatible'
    SupportNo       = 'NO compatible'
    RemovableYes    = 'sí'
    RemovableNo     = 'NO (opción -AllowFixed)'

    ButtonOk        = 'Aceptar'
    ButtonCancel    = 'Cancelar'
    ButtonYes       = 'Sí'
    ButtonNo        = 'No'

    ConfirmBody     = "¿Formatear la unidad {0}: en FAT32?`r`n`r`nEtiqueta         : {1}`r`nCapacidad        : {2}`r`nSistema actual   : {3}`r`nExtraíble        : {4}`r`nWindows          : {5}`r`n`r`nTodos los datos de esta unidad se borrarán de forma definitiva.`r`n¿Continuar?"

    DryRunTitle     = 'Plan de formateo (simulación)'
    DryRunDrive     = 'Unidad              : {0}:'
    DryRunLabel     = 'Etiqueta            : {0} -> {1}'
    DryRunFs        = 'Sistema de archivos : {0} -> FAT32'
    DryRunCapacity  = 'Capacidad           : {0}'
    DryRunType      = 'Tipo                : {0}'
    DryRunQuick     = 'Modo                : formateo rápido'
    DryRunWindows   = 'Windows             : {0} (FAT32 > 32 GB: {1})'
    DryRunCommand   = 'Comando             : format {0}'

    SuccessBody     = "La unidad {0}: ya está en FAT32.`r`n`r`nEtiqueta         : {1}`r`nCapacidad        : {2}`r`nTamaño de clúster: {3}`r`nDuración         : {4} s`r`n`r`nRecordatorio: en FAT32 un archivo no puede superar 4 GB.`r`n`r`nRegistro: {5}"
    FailureBody     = "El formateo de {0}: en FAT32 ha fallado.`r`n`r`nCausas posibles:`r`n- esta versión de Windows no crea FAT32 por encima de 32 GB`r`n  (compruebe con winver: compatible desde las compilaciones`r`n  26100.8313 / 26200.8313; si no, actualice Windows);`r`n- la tarjeta está protegida contra escritura o la usa otro programa;`r`n- la tarjeta está defectuosa.`r`n`r`nSalida de {1} (código {2}):`r`n{3}`r`n`r`nRegistro: {4}"
    ErrorBody       = "{0}`r`n`r`nRegistro: {1}"

    ErrorInvalidLetter   = "Letra de unidad no válida: «{0}»."
    ErrorDriveMissing    = "La unidad {0}: no existe o no es accesible.`r`nCompruebe la tarjeta e inténtelo de nuevo."
    ErrorSystemDrive     = "La unidad del sistema ({0}:) no se puede formatear con esta herramienta."
    ErrorUnsupportedType = "La unidad {0}: es de tipo «{1}»: no se puede formatear."
    ErrorNotRemovable    = "La unidad {0}: es de tipo «{1}» y no «Extraíble».`r`n`r`nEsta herramienta está pensada para tarjetas SD y unidades USB.`r`nSi un lector de tarjetas se declara «Fijo», utilice la opción -AllowFixed."
    ErrorNoMedia         = "No se detecta ningún medio en la unidad {0}:`r`nInserte una tarjeta e inténtelo de nuevo."
    ErrorTooBig          = 'El volumen es de {0}, por encima del límite de FAT32 (2 TB).'
    ErrorBuildTooOld     = "Este PC no puede crear un volumen FAT32 de más de 32 GB.`r`n`r`nDetectado : {0}`r`nRequerido : Windows 11 24H2 compilación 26100.8313 o 25H2 compilación 26200.8313 (o posterior).`r`n`r`nActualice Windows (Configuración > Windows Update) e inténtelo de nuevo.`r`nPara omitir esta comprobación: opción -SkipVersionCheck."
    ErrorElevationDenied = "Se requieren derechos de administrador para formatear una unidad.`r`n`r`nLa elevación se ha rechazado o cancelado.`r`n`r`n{0}"
    ErrorFormatMissing   = 'No se encuentra format.com en {0}\System32.'
    ErrorFormatTimeout   = 'Tiempo de espera agotado: format.com no terminó en 15 minutos.'
    ClusterUnknown       = 'desconocido'
}
