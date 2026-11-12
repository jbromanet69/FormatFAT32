@{
    # Règles volontairement désactivées : ce projet est un outil graphique
    # piloté par un utilisateur, pas un module destiné à être chaîné.
    ExcludeRules = @(
        'PSAvoidUsingWriteHost'                   # sortie console volontaire (mode -DryRun, installation)
        'PSUseShouldProcessForStateChangingFunctions'
        'PSAvoidUsingEmptyCatchBlock'             # catch volontairement silencieux (journalisation, nettoyage)
        'PSUseSingularNouns'
        'PSUseOutputTypeCorrectly'
        'PSAvoidUsingInvokeExpression'
        'PSReviewUnusedParameter'                 # faux positifs sur les paramètres lus dans les heredocs
    )

    Rules = @{
        PSAvoidUsingCmdletAliases = @{
            AllowList = @()
        }
        PSUseCompatibleSyntax = @{
            Enable         = $true
            TargetVersions = @('5.1', '7.0')
        }
    }
}
