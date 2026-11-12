# FormatFAT32 — « Formater en FAT32 » dans le menu contextuel

Ajoute une action **Formater en FAT32** au clic droit des disques dans l'Explorateur.
Elle effectue un **formatage rapide en FAT32** des cartes SD et clés USB — y compris
celles de plus de 32 Go — après une boîte de confirmation et une élévation UAC.

Aucun binaire tiers : l'outil n'appelle que `format.com` de Microsoft.

> ⚠️ **Action destructive.** Le formatage efface tout le contenu du volume ciblé.
> Vérifiez toujours la lettre et la capacité affichées dans la confirmation.

## Ce que fait l'outil

- Enregistre le verbe Shell `HKLM\SOFTWARE\Classes\Drive\shell\FormatFAT32` (tous les utilisateurs).
- Ajoute un raccourci **menu Démarrer** qui ouvre une fenêtre listant les disques amovibles.
- Déclare une entrée dans **Applications et fonctionnalités** pour une désinstallation propre.
- Journalise chaque tentative dans `%ProgramData%\FormatFAT32\logs` (compte standard : `%LOCALAPPDATA%\FormatFAT32\logs`).

Le script de formatage :

1. refuse tout disque qui n'est pas de type **Amovible** (et toujours le disque système) ;
2. affiche une confirmation avec lettre, libellé, capacité et système de fichiers actuel ;
3. demande l'élévation UAC (l'instance élevée s'exécute masquée, sans fenêtre console) ;
4. lance `format.com X: /FS:FAT32 /Q /Y` ;
5. **vérifie** ensuite que le volume est réellement en FAT32 (sans se fier au code retour)
   et attend le remontage du média ;
6. affiche un compte rendu (détails en cas de succès, sortie de `format.com` en cas d'échec).

## Configuration requise

| Cas d'usage | Version minimale |
|---|---|
| FAT32 jusqu'à **32 Go** | Tout Windows disposant de **PowerShell 5.1** (Windows 10 / 11) |
| FAT32 **au-delà de 32 Go** | **Windows 11 24H2 build 26100.8313** ou **25H2 build 26200.8313** (ou ultérieure) |
| Dans tous les cas | Droits administrateur (demandés automatiquement), Windows PowerShell 5.1 ou PowerShell 7 |

**Pourquoi cette contrainte.** Le plafond de 32 Go est une politique du formateur Windows,
pas une limite du système FAT32. Microsoft l'a levé **en ligne de commande uniquement**, à
partir des builds ci-dessus. Sur une build plus ancienne, `format.com` répond « The volume
is too big for FAT32 » pour tout volume de plus de 32 Go. L'outil contrôle donc la build
**avant** de formater et s'arrête avec un message explicite, plutôt que de laisser un échec
difficile à interpréter.

Vérifiez votre build avec `winver`, ou laissez l'outil vous le dire : `-SelfTest` l'affiche.

Sur un Windows plus ancien, deux options : mettre Windows à jour, ou formater la carte avec
un outil externe (Rufus avec l'option *Large FAT32*, ou `fat32format` de Ridgecrop, GPL-2.0 —
**non fourni ici**, car c'est un binaire tiers). Windows lira ensuite ce volume FAT32 sans
difficulté : seule sa *création* exige une build récente.

L'option `-SkipVersionCheck` contourne ce contrôle (si la détection est erronée).

## Installation

```powershell
powershell -ExecutionPolicy Bypass -File .\Install-FormatFAT32.ps1
```

L'installateur s'auto-élève, copie les scripts dans `C:\Program Files\FormatFAT32`,
enregistre l'entrée de menu et se termine par une liste de contrôles (`[OK]`) ainsi
qu'une ligne indiquant si la build de Windows prend en charge le FAT32 au-delà de 32 Go.

Options :

```powershell
# Installation par utilisateur, sans UAC, sans raccourci
powershell -ExecutionPolicy Bypass -File .\Install-FormatFAT32.ps1 -Hive HKCU -NoShortcut

# Dossier personnalisé et éditeur affiché dans Applications et fonctionnalités
powershell -ExecutionPolicy Bypass -File .\Install-FormatFAT32.ps1 -InstallDir D:\Outils\FormatFAT32 -Publisher "Ma société"
```

| Paramètre | Défaut | Rôle |
|---|---|---|
| `-Hive` | `HKLM` | `HKLM` (tous les utilisateurs) ou `HKCU` (utilisateur courant) |
| `-InstallDir` | `%ProgramFiles%\FormatFAT32` | Dossier d'installation |
| `-Publisher` | *(aucun)* | Éditeur affiché dans Applications et fonctionnalités |
| `-NoShortcut` | désactivé | Pas de raccourci dans le menu Démarrer |
| `-Quiet` | désactivé | Sortie minimale |

## Utilisation

- **Clic droit sur un disque** → *Formater en FAT32*.
  Sur Windows 11, les verbes de registre se trouvent dans **Afficher plus d'options** (`Maj+F10`).
- Ou **menu Démarrer** → *Formater en FAT32* : une fenêtre liste les disques amovibles.

## Ligne de commande

```powershell
.\Format-RemovableFat32.ps1 -Drive E:                     # formate E: après confirmation
.\Format-RemovableFat32.ps1 -Drive E: -DryRun             # affiche le plan, ne change rien
.\Format-RemovableFat32.ps1                               # sélection dans une fenêtre
.\Format-RemovableFat32.ps1 -Drive E: -Label PHOTOS -ClusterSizeKb 32
.\Format-RemovableFat32.ps1 -Drive E: -Yes                # sans confirmation (automatisation)
.\Format-RemovableFat32.ps1 -Drive E: -AllowFixed         # lecteurs de cartes déclarés « Fixe »
```

| Paramètre | Rôle |
|---|---|
| `-Drive` | Lettre du lecteur (`E`, `E:`, `E:\`). Omis → fenêtre de sélection |
| `-Label` | Nouveau libellé du volume (11 caractères max) |
| `-ClusterSizeKb` | Taille de cluster en Ko (défaut : Windows) |
| `-AllowFixed` | Autorise les disques déclarés *Fixe* (certains lecteurs de cartes) |
| `-Yes` | Supprime la boîte de confirmation |
| `-DryRun` | Affiche le plan d'action sans rien modifier |
| `-SelfTest` | Contrôle script + WinForms + affiche la build Windows, puis quitte |
| `-SkipVersionCheck` | Ignore le contrôle de build pour le FAT32 > 32 Go |

Codes de retour : `0` succès · `1` erreur · `2` annulé par l'utilisateur ·
`3` échec du formatage · `4` élévation refusée.

## Limites à connaître

- **4 Go maximum par fichier** — limite du système FAT32, pas de l'outil.
- **2 To maximum par volume**.
- Les cartes de plus de 32 Go sont officiellement des **SDXC**, dont le système de
  référence est **exFAT**. Le FAT32 fonctionne, mais certains appareils (appareils photo,
  dashcams, imprimantes, autoradios) peuvent refuser la carte ou la reformater. Utilisez
  FAT32 quand l'appareil l'exige.
- Certains lecteurs de cartes déclarent les cartes SD comme **Fixe** et non Amovible.
  Utilisez `-AllowFixed` pour ces cas ; l'entrée du menu contextuel ne transmet aucun
  paramètre, passez donc par la ligne de commande (ou le raccourci du menu Démarrer suivi
  du sélecteur).
- Seuls les lecteurs ayant une lettre et un volume monté sont traités.

## Désinstallation

**Paramètres → Applications → Applications installées → « Formater en FAT32 (menu contextuel) » → Désinstaller**

ou :

```powershell
powershell -ExecutionPolicy Bypass -File "$env:ProgramFiles\FormatFAT32\Uninstall-FormatFAT32.ps1"
```

`-KeepFiles` conserve le dossier d'installation.

## Dépannage

| Symptôme | À vérifier |
|---|---|
| Rien ne se passe au clic | Consultez `%ProgramData%\FormatFAT32\logs` (ou `%LOCALAPPDATA%`). |
| « Ce PC ne peut pas créer un volume FAT32 de plus de 32 Go » | Build Windows trop ancienne — voir [Configuration requise](#configuration-requise). |
| « Échec du formatage » | Carte protégée en écriture, occupée ou défectueuse — le dialogue affiche la sortie de `format.com`. |
| Entrée absente sous Windows 11 | Elle est dans *Afficher plus d'options* (`Maj+F10`). Vérifiez `HKLM\SOFTWARE\Classes\Drive\shell\FormatFAT32`. |
| « est de type « Fixe » et non « Amovible » » | Lecteur de cartes déclaré Fixe → utilisez `-AllowFixed`. |

## Arborescence du dépôt

```
FormatFAT32/
├─ Format-RemovableFat32.ps1    # moteur : validation, dialogues, formatage, vérification, journal
├─ Install-FormatFAT32.ps1      # installateur : copie, verbe Shell, raccourci, entrée ARP
├─ Uninstall-FormatFAT32.ps1    # désinstalleur
├─ README.md / README.fr.md     # documentation (anglais / français)
├─ LICENSE                      # MIT
└─ .github/workflows/lint.yml   # CI PSScriptAnalyzer
```

## Licence

MIT — voir [LICENSE](./LICENSE).

Projet non affilié à Microsoft. « Windows » et « Microsoft » sont des marques de Microsoft
Corporation. `format.com` fait partie de Windows et est utilisé tel quel : rien n'est
redistribué ni re-licencié ici.

---

🇬🇧 [English version](./README.md)
