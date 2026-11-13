; ---------------------------------------------------------------------------
; FormatFAT32 - Inno Setup script
;
; Build:  "C:\Program Files (x86)\Inno Setup 6\ISCC.exe" FormatFAT32.iss
; Output: ..\dist\FormatFAT32-<version>-setup.exe
;
; Installs the "Format as FAT32" shell verb for drives, a Start menu shortcut
; and the localized scripts. The verb is registered under HKA: machine-wide
; (HKCR) when run as administrator, per-user (HKCU\Software\Classes) otherwise.
; ---------------------------------------------------------------------------

#define AppName        "FormatFAT32"
#define AppVersion     "1.1.0"
#define AppPublisher   "Jean-Baptiste Romanet"
#define AppURL         "https://github.com/jbromanet69/FormatFAT32"
#define RepoRoot       ".."

[Setup]
AppId={{8E1B6A2C-5C64-4E9B-9F1E-3D0C7A5B2F41}
AppName={#AppName}
AppVersion={#AppVersion}
AppVerName={#AppName} {#AppVersion}
AppPublisher={#AppPublisher}
AppPublisherURL={#AppURL}
AppSupportURL={#AppURL}/issues
AppUpdatesURL={#AppURL}/releases
VersionInfoVersion={#AppVersion}
VersionInfoDescription=Format as FAT32 - right-click action for removable drives
VersionInfoCompany={#AppPublisher}
VersionInfoCopyright=MIT License - {#AppPublisher}

DefaultDirName={autopf}\{#AppName}
DefaultGroupName={#AppName}
DisableProgramGroupPage=yes
AllowNoIcons=yes

; Per-user install is allowed (no UAC) but the default is machine-wide.
PrivilegesRequired=admin
PrivilegesRequiredOverridesAllowed=dialog commandline

ArchitecturesAllowed=x64compatible
ArchitecturesInstallIn64BitMode=x64compatible
MinVersion=10.0

OutputDir={#RepoRoot}\dist
OutputBaseFilename={#AppName}-{#AppVersion}-setup
SetupIconFile={#RepoRoot}\FormatFAT32.ico
UninstallDisplayIcon={app}\FormatFAT32.ico
UninstallDisplayName=Format as FAT32 (context menu)
LicenseFile={#RepoRoot}\LICENSE

Compression=lzma2/max
SolidCompression=yes
WizardStyle=modern
DisableWelcomePage=no
SetupLogging=yes

[Languages]
Name: "en"; MessagesFile: "compiler:Default.isl"
Name: "fr"; MessagesFile: "compiler:Languages\French.isl"
Name: "de"; MessagesFile: "compiler:Languages\German.isl"
Name: "es"; MessagesFile: "compiler:Languages\Spanish.isl"
Name: "it"; MessagesFile: "compiler:Languages\Italian.isl"
Name: "pt"; MessagesFile: "compiler:Languages\Portuguese.isl"
Name: "nl"; MessagesFile: "compiler:Languages\Dutch.isl"

[CustomMessages]
en.ShellVerb=Format as FAT32
fr.ShellVerb=Formater en FAT32
de.ShellVerb=Als FAT32 formatieren
es.ShellVerb=Formatear en FAT32
it.ShellVerb=Formatta in FAT32
pt.ShellVerb=Formatar em FAT32
nl.ShellVerb=Formatteren als FAT32

en.DrivePicker=Open the drive picker
fr.DrivePicker=Ouvrir le sélecteur de disques
de.DrivePicker=Laufwerksauswahl öffnen
es.DrivePicker=Abrir el selector de unidades
it.DrivePicker=Apri il selettore di unità
pt.DrivePicker=Abrir o seletor de unidades
nl.DrivePicker=Stationskiezer openen

[Tasks]
Name: "desktopicon"; Description: "{cm:CreateDesktopIcon}"; GroupDescription: "{cm:AdditionalIcons}"; Flags: unchecked

[Files]
Source: "{#RepoRoot}\Format-RemovableFat32.ps1"; DestDir: "{app}"; Flags: ignoreversion
Source: "{#RepoRoot}\Launch-FormatFAT32.vbs";   DestDir: "{app}"; Flags: ignoreversion
Source: "{#RepoRoot}\FormatFAT32.ico";          DestDir: "{app}"; Flags: ignoreversion
Source: "{#RepoRoot}\LICENSE";                  DestDir: "{app}"; Flags: ignoreversion
Source: "{#RepoRoot}\README.md";                DestDir: "{app}"; Flags: ignoreversion
Source: "{#RepoRoot}\README.fr.md";             DestDir: "{app}"; Flags: ignoreversion
Source: "{#RepoRoot}\lang\*.psd1";              DestDir: "{app}\lang"; Flags: ignoreversion

[Registry]
; Machine-wide when elevated (HKLM\Software\Classes == HKCR), per-user otherwise.
; HKA cannot be used here: in non-admin mode it maps to HKCU directly, not to
; HKCU\Software\Classes, which is where the shell looks for verbs.
Root: HKLM; Subkey: "Software\Classes\Drive\shell\FormatFAT32"; ValueType: string; ValueName: "MUIVerb"; ValueData: "{cm:ShellVerb}"; Flags: uninsdeletekey; Check: IsAdminInstallMode
Root: HKLM; Subkey: "Software\Classes\Drive\shell\FormatFAT32"; ValueType: string; ValueName: "Icon"; ValueData: "{app}\FormatFAT32.ico"; Check: IsAdminInstallMode
Root: HKLM; Subkey: "Software\Classes\Drive\shell\FormatFAT32"; ValueType: string; ValueName: "MultiSelectModel"; ValueData: "Single"; Check: IsAdminInstallMode
Root: HKLM; Subkey: "Software\Classes\Drive\shell\FormatFAT32\command"; ValueType: string; ValueName: ""; ValueData: """{sys}\wscript.exe"" ""{app}\Launch-FormatFAT32.vbs"" ""%1"""; Check: IsAdminInstallMode

Root: HKCU; Subkey: "Software\Classes\Drive\shell\FormatFAT32"; ValueType: string; ValueName: "MUIVerb"; ValueData: "{cm:ShellVerb}"; Flags: uninsdeletekey; Check: not IsAdminInstallMode
Root: HKCU; Subkey: "Software\Classes\Drive\shell\FormatFAT32"; ValueType: string; ValueName: "Icon"; ValueData: "{app}\FormatFAT32.ico"; Check: not IsAdminInstallMode
Root: HKCU; Subkey: "Software\Classes\Drive\shell\FormatFAT32"; ValueType: string; ValueName: "MultiSelectModel"; ValueData: "Single"; Check: not IsAdminInstallMode
Root: HKCU; Subkey: "Software\Classes\Drive\shell\FormatFAT32\command"; ValueType: string; ValueName: ""; ValueData: """{sys}\wscript.exe"" ""{app}\Launch-FormatFAT32.vbs"" ""%1"""; Check: not IsAdminInstallMode

; Migration: remove the entries created by the legacy PowerShell installer
; (Install-FormatFAT32.ps1) so only one "Format as FAT32" entry remains.
Root: HKLM; Subkey: "Software\Microsoft\Windows\CurrentVersion\Uninstall\FormatFAT32"; Flags: dontcreatekey deletekey
Root: HKCU; Subkey: "Software\Microsoft\Windows\CurrentVersion\Uninstall\FormatFAT32"; Flags: dontcreatekey deletekey

[InstallDelete]
; Legacy shortcut names used by Install-FormatFAT32.ps1
Type: files; Name: "{commonprograms}\Formater en FAT32.lnk"
Type: files; Name: "{commonprograms}\Format as FAT32.lnk"
Type: files; Name: "{userprograms}\Formater en FAT32.lnk"
Type: files; Name: "{userprograms}\Format as FAT32.lnk"
; Legacy PowerShell uninstaller, superseded by the Inno uninstaller
Type: files; Name: "{app}\Uninstall-FormatFAT32.ps1"

[Icons]
Name: "{group}\{cm:ShellVerb}"; Filename: "{sys}\wscript.exe"; Parameters: """{app}\Launch-FormatFAT32.vbs"""; WorkingDir: "{app}"; IconFilename: "{app}\FormatFAT32.ico"; Comment: "{cm:DrivePicker}"
Name: "{group}\{cm:UninstallProgram,{#AppName}}"; Filename: "{uninstallexe}"
Name: "{autodesktop}\{cm:ShellVerb}"; Filename: "{sys}\wscript.exe"; Parameters: """{app}\Launch-FormatFAT32.vbs"""; WorkingDir: "{app}"; IconFilename: "{app}\FormatFAT32.ico"; Tasks: desktopicon

[Run]
; Silent post-install check: verifies PowerShell, WinForms and the language files.
Filename: "{sys}\WindowsPowerShell\v1.0\powershell.exe"; Parameters: "-NoProfile -ExecutionPolicy Bypass -WindowStyle Hidden -STA -File ""{app}\Format-RemovableFat32.ps1"" -SelfTest"; Flags: runhidden waituntilterminated

[UninstallDelete]
Type: files; Name: "{app}\language.txt"

[Code]
{ Writes the language chosen in the wizard so the dialogs match the setup language. }
procedure CurStepChanged(CurStep: TSetupStep);
var
  LanguageFile: String;
begin
  if CurStep = ssPostInstall then
  begin
    LanguageFile := ExpandConstant('{app}\language.txt');
    SaveStringToFile(LanguageFile, ActiveLanguage + #13#10, False);
  end;
end;

{ Removes the per-user verb if a per-user install left one behind. }
procedure CurUninstallStepChanged(CurUninstallStep: TUninstallStep);
var
  ResultCode: Integer;
begin
  if CurUninstallStep = usPostUninstall then
  begin
    Exec(ExpandConstant('{sys}\reg.exe'),
         'delete "HKCU\Software\Classes\Drive\shell\FormatFAT32" /f',
         '', SW_HIDE, ewWaitUntilTerminated, ResultCode);
  end;
end;
