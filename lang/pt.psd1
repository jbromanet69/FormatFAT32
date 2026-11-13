@{
    LanguageName    = 'Portuguese'
    LanguageNative  = 'Português'

    DialogTitle     = 'Formatar em FAT32'
    ErrorTitle      = 'Formatar em FAT32'
    ConfirmTitle    = 'Confirmar formatação FAT32'
    SuccessTitle    = 'Formatação concluída'
    FailureTitle    = 'Falha na formatação'
    PickerTitle     = 'Formatar em FAT32'

    PickerIntro     = 'Selecione a unidade removível a formatar em FAT32:'
    PickerWarning   = 'O conteúdo da unidade selecionada será apagado definitivamente.'
    PickerOk        = 'Formatar em FAT32'
    PickerCancel    = 'Cancelar'
    PickerEmpty     = "Nenhuma unidade removível pronta foi encontrada.`r`n`r`nInsira um cartão SD ou uma pen USB e tente novamente."
    VolumeListItem  = '{0}:  {1,-18} {2,10}  {3}'
    VolumeNoLabel   = '(sem nome)'
    VolumeRaw       = 'RAW'

    SizeGB          = 'GB'
    SizeMB          = 'MB'
    SizeKB          = 'KB'
    SizeBytes       = 'bytes'

    DriveTypeUnknown   = 'Desconhecido'
    DriveTypeNoRoot    = 'Sem diretório raiz'
    DriveTypeRemovable = 'Removível'
    DriveTypeFixed     = 'Fixo'
    DriveTypeNetwork   = 'Rede'
    DriveTypeCdRom     = 'CD-ROM'
    DriveTypeRam       = 'Unidade RAM'
    DriveTypeOther     = 'Tipo {0}'

    SupportYes      = 'suportado'
    SupportNo       = 'NÃO suportado'
    RemovableYes    = 'sim'
    RemovableNo     = 'NÃO (opção -AllowFixed)'

    ButtonOk        = 'OK'
    ButtonCancel    = 'Cancelar'
    ButtonYes       = 'Sim'
    ButtonNo        = 'Não'

    ConfirmBody     = "Formatar a unidade {0}: em FAT32?`r`n`r`nEtiqueta         : {1}`r`nCapacidade       : {2}`r`nSistema atual    : {3}`r`nRemovível        : {4}`r`nWindows          : {5}`r`n`r`nTodos os dados desta unidade serão apagados definitivamente.`r`nContinuar?"

    DryRunTitle     = 'Plano de formatação (simulação)'
    DryRunDrive     = 'Unidade             : {0}:'
    DryRunLabel     = 'Etiqueta            : {0} -> {1}'
    DryRunFs        = 'Sistema de ficheiros: {0} -> FAT32'
    DryRunCapacity  = 'Capacidade          : {0}'
    DryRunType      = 'Tipo                : {0}'
    DryRunQuick     = 'Modo                : formatação rápida'
    DryRunWindows   = 'Windows             : {0} (FAT32 > 32 GB: {1})'
    DryRunCommand   = 'Comando             : format {0}'

    SuccessBody     = "A unidade {0}: está agora em FAT32.`r`n`r`nEtiqueta         : {1}`r`nCapacidade       : {2}`r`nTamanho do cluster: {3}`r`nDuração          : {4} s`r`n`r`nLembrete: em FAT32 um ficheiro não pode exceder 4 GB.`r`n`r`nRegisto: {5}"
    FailureBody     = "A formatação de {0}: em FAT32 falhou.`r`n`r`nCausas possíveis:`r`n- esta versão do Windows não cria FAT32 acima de 32 GB`r`n  (verifique com winver: suporte a partir das builds`r`n  26100.8313 / 26200.8313; caso contrário atualize o Windows);`r`n- o cartão está protegido contra escrita ou a ser usado por outro programa;`r`n- o cartão está defeituoso.`r`n`r`nSaída de {1} (código {2}):`r`n{3}`r`n`r`nRegisto: {4}"
    ErrorBody       = "{0}`r`n`r`nRegisto: {1}"

    ErrorInvalidLetter   = 'Letra de unidade inválida: «{0}».'
    ErrorDriveMissing    = "A unidade {0}: não existe ou não está acessível.`r`nVerifique o cartão e tente novamente."
    ErrorSystemDrive     = "A unidade de sistema ({0}:) não pode ser formatada por esta ferramenta."
    ErrorUnsupportedType = "A unidade {0}: é do tipo «{1}»: formatação impossível."
    ErrorNotRemovable    = "A unidade {0}: é do tipo «{1}» e não «Removível».`r`n`r`nEsta ferramenta destina-se a cartões SD e pens USB.`r`nSe um leitor de cartões se declarar «Fixo», utilize a opção -AllowFixed."
    ErrorNoMedia         = "Nenhum suporte detetado na unidade {0}:`r`nInsira um cartão e tente novamente."
    ErrorTooBig          = 'O volume tem {0}, acima do limite FAT32 (2 TB).'
    ErrorBuildTooOld     = "Este PC não pode criar um volume FAT32 com mais de 32 GB.`r`n`r`nDetetado   : {0}`r`nNecessário : Windows 11 24H2 build 26100.8313 ou 25H2 build 26200.8313 (ou posterior).`r`n`r`nAtualize o Windows (Definições > Windows Update) e tente novamente.`r`nPara ignorar esta verificação: opção -SkipVersionCheck."
    ErrorElevationDenied = "São necessários direitos de administrador para formatar uma unidade.`r`n`r`nA elevação foi recusada ou cancelada.`r`n`r`n{0}"
    ErrorFormatMissing   = 'format.com não foi encontrado em {0}\System32.'
    ErrorFormatTimeout   = 'Tempo excedido: format.com não terminou em 15 minutos.'
    ClusterUnknown       = 'desconhecido'
}
