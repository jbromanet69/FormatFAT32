# FormatFAT32 — right-click “Format as FAT32” for removable drives

Adds a **Format as FAT32** action to the right-click menu of drives in File Explorer.
It performs a **quick format to FAT32** on SD cards and USB drives — including cards
larger than 32 GB — after a confirmation dialog and an UAC elevation prompt.

No third-party binary: the tool only calls Microsoft's `format.com`.

> ⚠️ **Destructive action.** Formatting erases everything on the target volume.
> Always check the drive letter and the capacity shown in the confirmation dialog.

## What it does

- Adds the shell verb `HKLM\SOFTWARE\Classes\Drive\shell\FormatFAT32` (all users).
- Adds a **Start menu** shortcut that opens a picker listing the removable drives.
- Registers an entry in **Apps & features** for clean uninstallation.
- Logs every attempt to `%ProgramData%\FormatFAT32\logs` (standard account: `%LOCALAPPDATA%\FormatFAT32\logs`).

The formatting script:

1. refuses any drive that is not **Removable** (and always refuses the system drive);
2. shows a confirmation dialog with drive letter, label, capacity and current file system;
3. requests UAC elevation (the elevated instance runs hidden, without a console window);
4. runs `format.com X: /FS:FAT32 /Q /Y`;
5. **verifies** the volume really is FAT32 afterwards (does not trust the exit code) and
   waits for the media to be remounted;
6. shows a result dialog (success details, or the `format.com` output on failure).

## Requirements

| Scenario | Minimum version |
|---|---|
| FAT32 up to **32 GB** | Any Windows with **PowerShell 5.1** (Windows 10 / 11) |
| FAT32 **above 32 GB** | **Windows 11 24H2 build 26100.8313** or **25H2 build 26200.8313** (or later) |
| Everything | Administrator rights (requested automatically), Windows PowerShell 5.1 or PowerShell 7 |

**Why the version matters.** The 32 GB cap is a Windows formatter policy, not a FAT32
limit. Microsoft lifted it for the command line only, starting with the builds above.
On an older build, `format.com` answers “The volume is too big for FAT32” for any volume
above 32 GB — the tool therefore checks the build *before* formatting and stops with an
explicit message instead of leaving you with a cryptic failure.

Check your build with `winver`, or let the tool tell you: `-SelfTest` prints it.

On an older Windows, either update Windows, or format the card with an external tool
(Rufus with *Large FAT32*, or Ridgecrop's `fat32format`, GPL-2.0 — **not** bundled here,
because it is a third-party binary). Windows will then read and write that FAT32 volume
without any problem; only *creating* it needs a recent build.

Use `-SkipVersionCheck` to bypass the build check (e.g. if detection is wrong).

## Install

```powershell
powershell -ExecutionPolicy Bypass -File .\Install-FormatFAT32.ps1
```

The installer self-elevates, copies the scripts to `C:\Program Files\FormatFAT32`,
registers the menu entry, and finishes with a checklist (`[OK]` lines) plus a line
stating whether this Windows build supports FAT32 above 32 GB.

Options:

```powershell
# Per-user install, no UAC, no Start menu shortcut
powershell -ExecutionPolicy Bypass -File .\Install-FormatFAT32.ps1 -Hive HKCU -NoShortcut

# Custom folder and publisher shown in Apps & features
powershell -ExecutionPolicy Bypass -File .\Install-FormatFAT32.ps1 -InstallDir D:\Tools\FormatFAT32 -Publisher "My Company"
```

| Parameter | Default | Purpose |
|---|---|---|
| `-Hive` | `HKLM` | `HKLM` (all users) or `HKCU` (current user) |
| `-InstallDir` | `%ProgramFiles%\FormatFAT32` | Target folder |
| `-Publisher` | *(none)* | Publisher shown in Apps & features |
| `-NoShortcut` | off | Skip the Start menu shortcut |
| `-Quiet` | off | Minimal output |

## Usage

- **Right-click a drive** → *Format as FAT32*.
  On Windows 11, registry verbs live under **Show more options** (`Shift+F10`).
- Or **Start menu** → *Format as FAT32*: a window lists the removable drives.

Note: the user interface is in **French** (built for a French-speaking team).

## Command line

```powershell
.\Format-RemovableFat32.ps1 -Drive E:                     # format E: after confirmation
.\Format-RemovableFat32.ps1 -Drive E: -DryRun             # show the plan, change nothing
.\Format-RemovableFat32.ps1                               # pick a removable drive in a window
.\Format-RemovableFat32.ps1 -Drive E: -Label PHOTOS -ClusterSizeKb 32
.\Format-RemovableFat32.ps1 -Drive E: -Yes                # no confirmation (automation)
.\Format-RemovableFat32.ps1 -Drive E: -AllowFixed         # card readers that report "Fixed"
```

| Parameter | Purpose |
|---|---|
| `-Drive` | Drive letter (`E`, `E:`, `E:\`). Omitted → picker window |
| `-Label` | New volume label (11 characters max) |
| `-ClusterSizeKb` | Cluster size in KB (Windows default if omitted) |
| `-AllowFixed` | Also allow drives reported as *Fixed* (some card readers) |
| `-Yes` | Skip the confirmation dialog |
| `-DryRun` | Print the action plan, change nothing |
| `-SelfTest` | Check script + WinForms + report the Windows build, then exit |
| `-SkipVersionCheck` | Ignore the Windows build check for FAT32 > 32 GB |

Exit codes: `0` success · `1` error · `2` cancelled by user · `3` formatting failed ·
`4` elevation denied.

## Limits to know

- **4 GB maximum per file** — a FAT32 file system limit, not a tool limit.
- **2 TB maximum per volume**.
- SD cards above 32 GB are officially **SDXC**, whose reference file system is **exFAT**.
  FAT32 works, but some devices (cameras, dashcams, printers, car stereos) may refuse
  the card or reformat it. Use FAT32 when the device requires it.
- Some card readers report SD cards as **Fixed** rather than Removable. Use
  `-AllowFixed` for those; the context-menu entry passes no switches, so prefer the
  command line (or the Start menu shortcut followed by the picker) in that case.
- Only drives with a drive letter and a mounted volume are handled.

## Uninstall

**Settings → Apps → Installed apps → “Formater en FAT32 (context menu)” → Uninstall**

or:

```powershell
powershell -ExecutionPolicy Bypass -File "$env:ProgramFiles\FormatFAT32\Uninstall-FormatFAT32.ps1"
```

`-KeepFiles` keeps the installation folder.

## Troubleshooting

| Symptom | What to check |
|---|---|
| Nothing happens on click | See `%ProgramData%\FormatFAT32\logs` (or `%LOCALAPPDATA%`). |
| “Ce PC ne peut pas créer un volume FAT32 de plus de 32 Go” | Windows build too old — see [Requirements](#requirements). |
| “Échec du formatage” | Card write-protected, busy, defective — the dialog shows `format.com` output. |
| Entry missing on Windows 11 | It is under *Show more options* (`Shift+F10`). Verify `HKLM\SOFTWARE\Classes\Drive\shell\FormatFAT32`. |
| “est de type « Fixe » et non « Amovible »” | Card reader reports Fixed → use `-AllowFixed`. |

## Repository layout

```
FormatFAT32/
├─ Format-RemovableFat32.ps1    # formatting engine (validation, dialogs, format, verify, log)
├─ Install-FormatFAT32.ps1      # installer: copy, shell verb, shortcut, Apps & features entry
├─ Uninstall-FormatFAT32.ps1    # uninstaller
├─ README.md / README.fr.md     # documentation (English / French)
├─ LICENSE                      # MIT
└─ .github/workflows/lint.yml   # PSScriptAnalyzer CI
```

## License

MIT — see [LICENSE](./LICENSE).

Not affiliated with Microsoft. “Windows” and “Microsoft” are trademarks of Microsoft
Corporation. `format.com` is part of Windows and is used as-is; nothing is
redistributed or re-licensed here.

---

🇫🇷 [Version française](./README.fr.md)
