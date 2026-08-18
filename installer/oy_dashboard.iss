; OY Dashboard - Inno Setup kurulum betigi
; Windows masaustu uygulamasi (Flutter) icin tek dosyalik kurulum .exe'si uretir.
; Uygulama optiyou.fit ile ayni Supabase backend'ine baglidir.

#define MyAppName "OY Dashboard"
#define MyAppVersion "1.0.0"
#define MyAppPublisher "Optiyou Shoes Ortopedi"
#define MyAppURL "https://optiyou.fit"
#define MyAppExeName "oy_site.exe"
#define SourceDir "..\build\windows\x64\install"

; Imzalama, ISCC'ye /DSIGN gecildiginde devreye girer; "oysign" araci da
; komut satirindan /Soysign=... ile tanimlanir (bkz. build_release.ps1).
; Sertifika yoksa betik /DSIGN gecmez ve kurulum imzasiz uretilir.
#ifdef SIGN
  #define SignedBuild
#endif

[Setup]
AppId={{8F3C2A61-7B4D-4E9A-9C1F-A1B2C3D4E5F6}
#ifdef SignedBuild
SignTool=oysign
; Kaldirma programi da imzalanir; aksi halde program kaldirilirken
; SmartScreen/UAC "bilinmeyen yayinci" uyarisi cikar.
SignedUninstaller=yes
#endif
AppName={#MyAppName}
AppVersion={#MyAppVersion}
AppPublisher={#MyAppPublisher}
AppPublisherURL={#MyAppURL}
AppSupportURL={#MyAppURL}
DefaultDirName={autopf}\OY Dashboard
DefaultGroupName=OY Dashboard
DisableProgramGroupPage=yes
OutputDir=..\dist
OutputBaseFilename=OY_Dashboard_Setup
SetupIconFile=..\windows\runner\resources\app_icon.ico
UninstallDisplayIcon={app}\{#MyAppExeName}
Compression=lzma2/max
SolidCompression=yes
WizardStyle=modern
ArchitecturesAllowed=x64compatible
ArchitecturesInstallIn64BitMode=x64compatible
PrivilegesRequiredOverridesAllowed=commandline dialog

[Languages]
Name: "turkish"; MessagesFile: "compiler:Languages\Turkish.isl"
Name: "english"; MessagesFile: "compiler:Default.isl"

[Tasks]
Name: "desktopicon"; Description: "{cm:CreateDesktopIcon}"; GroupDescription: "{cm:AdditionalIcons}"; Flags: checkedonce

[Files]
Source: "{#SourceDir}\{#MyAppExeName}"; DestDir: "{app}"; Flags: ignoreversion
Source: "{#SourceDir}\*"; DestDir: "{app}"; Flags: ignoreversion recursesubdirs createallsubdirs

[Icons]
Name: "{group}\{#MyAppName}"; Filename: "{app}\{#MyAppExeName}"
Name: "{group}\{cm:UninstallProgram,{#MyAppName}}"; Filename: "{uninstallexe}"
Name: "{autodesktop}\{#MyAppName}"; Filename: "{app}\{#MyAppExeName}"; Tasks: desktopicon

[Run]
Filename: "{app}\{#MyAppExeName}"; Description: "{cm:LaunchProgram,{#MyAppName}}"; Flags: nowait postinstall skipifsilent
