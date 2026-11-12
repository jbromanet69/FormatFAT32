# Formater en FAT32 — action de menu contextuel

Ajoute une action **Formater en FAT32** au clic droit des disques de l'Explorateur.
Elle formate en FAT32 (formatage rapide) les cartes SD et clés USB, y compris
celles de plus de 32 Go, après confirmation et élévation UAC.

## Contenu

| Fichier | Rôle |
|---|---|
| `Format-RemovableFat32.ps1` | Script de formatage (dialogue de confirmation, contrôle, journal). |
| `Install-FormatFAT32.ps1` | Installateur : copie les fichiers, enregistre le menu, crée le raccourci et l'entrée de désinstallation. |
| `Uninstall-FormatFAT32.ps1` | Désinstalleur. |
| `Build-Package.ps1` | Reconstruit l'archive `dist\FormatFAT32.zip` à distribuer aux collègues. |
| `fat32format.exe` | *Optionnel.* Outil de secours pour les Windows antérieurs au build 26100.8313. |

## Distribution

```powershell
powershell -ExecutionPolicy Bypass -File .\Build-Package.ps1
```

L'archive `dist\FormatFAT32.zip` (non versionnée) contient un dossier
`FormatFAT32` avec les trois scripts et ce README. Le destinataire la décompresse
et lance `Install-FormatFAT32.ps1`.

## Installation

Clic droit sur `Install-FormatFAT32.ps1` → **Exécuter avec PowerShell**, puis accepter l'UAC.

En ligne de commande :

```powershell
powershell -ExecutionPolicy Bypass -File .\Install-FormatFAT32.ps1
```

Options utiles :

```powershell
# Installation pour l'utilisateur courant uniquement (pas d'UAC)
powershell -ExecutionPolicy Bypass -File .\Install-FormatFAT32.ps1 -Hive HKCU

# Dossier personnalisé, sans raccourci du menu Démarrer
powershell -ExecutionPolicy Bypass -File .\Install-FormatFAT32.ps1 -InstallDir D:\Outils\FormatFAT32 -NoShortcut
```

L'installateur vérifie à la fin que le verbe, la commande et le script sont opérationnels.

## Utilisation

- **Clic droit sur un disque** → *Formater en FAT32*.
  Sur Windows 11, les entrées de ce type sont regroupées dans
  **Afficher plus d'options** (ou `Maj+F10`).
- Ou **menu Démarrer** → *Formater en FAT32* : une fenêtre liste les disques amovibles.

Le script :

1. refuse tout disque qui n'est pas de type « Amovible » (et toujours le disque système) ;
   l'entrée de menu est donc visible sur tous les disques, mais seuls les supports
   amovibles peuvent être formatés (le filtre AQS du Shell ne sait pas cibler les
   volumes amovibles) ;
2. affiche une confirmation avec le libellé, la capacité et le système actuel ;
3. demande l'élévation UAC si nécessaire ;
4. lance `format.com X: /FS:FAT32 /Q /Y` ;
5. vérifie que le volume est bien en FAT32 et affiche le compte rendu ;
6. journalise dans `%ProgramData%\FormatFAT32\logs` (compte administrateur) ou
   `%LOCALAPPDATA%\FormatFAT32\logs` (compte standard).

## Limites à connaître

- **FAT32 : 4 Go maximum par fichier** (limite du système de fichiers).
- **2 To maximum** par volume.
- Pour formater **plus de 32 Go en FAT32**, Windows doit être à jour :
  la limite en ligne de commande est levée à partir des builds
  **26100.8313** (24H2) et **26200.8313** (25H2). Vérifier avec `winver`.
  Sur une build antérieure, placer `fat32format.exe` (Ridgecrop) à côté du script :
  il sera utilisé automatiquement en secours.
- Les cartes de plus de 32 Go sont officiellement des **SDXC** (exFAT selon la
  SD Association). Le FAT32 fonctionne, mais certains appareils peuvent refuser
  la carte ou la reformater.

## Désinstallation

Menu Démarrer → Paramètres → Applications → *Formater en FAT32 (menu contextuel)* → Désinstaller.

Ou :

```powershell
powershell -ExecutionPolicy Bypass -File "$env:ProgramFiles\FormatFAT32\Uninstall-FormatFAT32.ps1"
```

L'option `-KeepFiles` conserve le dossier d'installation.

## Dépannage

| Symptôme | Piste |
|---|---|
| Rien ne se passe au clic | Consulter `%ProgramData%\FormatFAT32\logs` (admin) ou `%LOCALAPPDATA%\FormatFAT32\logs`. |
| « Échec du formatage » | Mettre Windows à jour, ou utiliser `fat32format.exe` / Rufus. |
| L'entrée n'apparaît pas | Windows 11 : *Afficher plus d'options* (`Maj+F10`). Vérifier `HKLM\SOFTWARE\Classes\Drive\shell\FormatFAT32`. |
| « Le volume est trop grand » | Build Windows trop ancienne (voir ci-dessus). |
