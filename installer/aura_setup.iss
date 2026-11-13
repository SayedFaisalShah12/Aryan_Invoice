; Inno Setup script for the Aura Invoice Windows installer.
; Build the app first:  flutter build windows --release
; Then compile:         "C:\Program Files (x86)\Inno Setup 6\ISCC.exe" installer\aura_setup.iss

#define AppName "Aura Invoice"
#define AppVersion "1.1.1"
#define AppExe "aura.exe"
#define BuildDir "..\build\windows\x64\runner\Release"

[Setup]
AppId={{6B1C2A4E-8F3D-4E7A-9C51-0A0A00000001}
AppName={#AppName}
AppVersion={#AppVersion}
AppPublisher=Aura
DefaultDirName={autopf}\Aura Invoice
DefaultGroupName=Aura Invoice
OutputDir=..\build\installer
OutputBaseFilename=AuraSetup-{#AppVersion}
SetupIconFile=..\windows\runner\resources\app_icon.ico
UninstallDisplayIcon={app}\{#AppExe}
Compression=lzma2
SolidCompression=yes
ArchitecturesAllowed=x64compatible
ArchitecturesInstallIn64BitMode=x64compatible
WizardStyle=modern

[Tasks]
Name: "desktopicon"; Description: "Create a desktop shortcut"; GroupDescription: "Shortcuts:"

[Files]
Source: "{#BuildDir}\*"; DestDir: "{app}"; Flags: ignoreversion recursesubdirs createallsubdirs
; Separate icon file so shortcuts always show the current Aura logo.
Source: "..\windows\runner\resources\app_icon.ico"; DestDir: "{app}"; DestName: "aura_logo.ico"; Flags: ignoreversion

[Icons]
Name: "{group}\Aura Invoice"; Filename: "{app}\{#AppExe}"; IconFilename: "{app}\aura_logo.ico"
Name: "{autodesktop}\Aura Invoice"; Filename: "{app}\{#AppExe}"; IconFilename: "{app}\aura_logo.ico"; Tasks: desktopicon

[Run]
; Refresh the Windows icon cache so the new icon shows immediately.
Filename: "{sys}\ie4uinit.exe"; Parameters: "-show"; Flags: runhidden skipifdoesntexist
Filename: "{app}\{#AppExe}"; Description: "Start Aura Invoice"; Flags: nowait postinstall skipifsilent
