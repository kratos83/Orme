; Installer Windows per "Orme", generato con Inno Setup (preinstallato sui
; runner windows-latest di GitHub Actions). Presuppone che dist\Orme\ sia
; gia' stato preparato (build + windeployqt) da .github/workflows/windows.yml
; prima di lanciare ISCC su questo script.
;
; La versione di default sotto viene sovrascritta in CI con
; /DMyAppVersion=<versione>.
#define MyAppName "Orme"
#define MyAppVersion "0.4"
#define MyAppPublisher "Angelo Scarna"
#define MyAppExeName "Orme.exe"
; GUID fisso: identifica l'app tra le versioni per aggiornamenti/disinstallazione pulita.
; Graffe raddoppiate: dopo la sostituzione di {#MyAppId}, il compilatore
; rilegge il risultato e tratterebbe "{...}" come riferimento a una propria
; costante anziche' come testo letterale del GUID.
#define MyAppId "{{C3A2E7F0-6B1D-4E3A-9C2F-7D8E5A1B4F6C}}"

[Setup]
AppId={#MyAppId}
AppName={#MyAppName}
AppVersion={#MyAppVersion}
AppPublisher={#MyAppPublisher}
DefaultDirName={autopf}\{#MyAppName}
DefaultGroupName={#MyAppName}
DisableProgramGroupPage=yes
OutputDir=..\..\dist
OutputBaseFilename=Orme-windows-setup-x64
SetupIconFile=orme.ico
Compression=lzma
SolidCompression=yes
WizardStyle=modern
ArchitecturesInstallIn64BitMode=x64compatible
LicenseFile=..\..\LICENSE

[Languages]
Name: "italian"; MessagesFile: "compiler:Languages\Italian.isl"
Name: "english"; MessagesFile: "compiler:Default.isl"

[Tasks]
Name: "desktopicon"; Description: "{cm:CreateDesktopIcon}"; GroupDescription: "{cm:AdditionalIcons}"

[Files]
Source: "..\..\dist\Orme\*"; DestDir: "{app}"; Flags: ignoreversion recursesubdirs createallsubdirs

[Icons]
Name: "{group}\{#MyAppName}"; Filename: "{app}\{#MyAppExeName}"
Name: "{group}\Disinstalla {#MyAppName}"; Filename: "{uninstallexe}"
Name: "{autodesktop}\{#MyAppName}"; Filename: "{app}\{#MyAppExeName}"; Tasks: desktopicon

[Run]
Filename: "{app}\{#MyAppExeName}"; Description: "{cm:LaunchProgram,{#MyAppName}}"; Flags: nowait postinstall skipifsilent
