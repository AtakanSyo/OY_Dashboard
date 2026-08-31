<#
.SYNOPSIS
    OPTIYOU Windows dagitim paketini uretir: obfuscated derleme + (varsa)
    kod imzalama + Inno Setup kurulum dosyasi.

.DESCRIPTION
    Sertifika verilmezse her sey aynen calisir, yalnizca imzalama atlanir ve
    SmartScreen "bilinmeyen yayinci" uyarisi cikar. Sertifika aldiginizda
    tek yapmaniz gereken -Thumbprint (veya -PfxPath) eklemek.

    Imzalama sirasi onemli: once uygulama exe'si imzalanir, sonra kurulum
    paketlenir. Tersi olursa kurulan uygulama imzasiz kalir.

.EXAMPLE
    # Sertifikasiz (bugunku durum)
    .\build_release.ps1

.EXAMPLE
    # Sertifika alindiktan sonra
    .\build_release.ps1 -Thumbprint A1B2C3D4E5...
#>
[CmdletBinding()]
param(
    [string]$Thumbprint,
    [string]$PfxPath,
    [string]$PfxPassword,
    [string]$TimestampUrl = 'http://timestamp.digicert.com'
)

$ErrorActionPreference = 'Stop'

$repo      = Split-Path $PSScriptRoot -Parent
$installDir = Join-Path $repo 'build\windows\x64\install'
$appExe     = Join-Path $installDir 'oy_site.exe'
$iss        = Join-Path $PSScriptRoot 'oy_dashboard.iss'
$symbols    = Join-Path $repo 'build\symbols'

$sign = [bool]($Thumbprint -or $PfxPath)

function Find-Tool([string]$name, [string[]]$roots) {
    foreach ($r in $roots) { if (Test-Path $r) { return $r } }
    $cmd = Get-Command $name -ErrorAction SilentlyContinue
    if ($cmd) { return $cmd.Source }
    throw "$name bulunamadi."
}

$iscc = Find-Tool 'ISCC.exe' @(
    "$env:LOCALAPPDATA\Programs\Inno Setup 6\ISCC.exe",
    "${env:ProgramFiles(x86)}\Inno Setup 6\ISCC.exe",
    "$env:ProgramFiles\Inno Setup 6\ISCC.exe"
)

# --- 1. Derleme -----------------------------------------------------------
Write-Host "`n=== 1/3  Obfuscated release derlemesi ===" -ForegroundColor Cyan
Push-Location $repo
try {
    # --obfuscate: Dart sinif/dosya adlari ikili dosyadan silinir.
    # --split-debug-info: cozme haritasi ayri tutulur, pakete girmez.
    #   Bu klasoru saklayin; kullanici cokme kayitlarini okumanin tek yolu.
    & flutter build windows --release --obfuscate --split-debug-info=$symbols
    if ($LASTEXITCODE -ne 0) { throw "flutter build basarisiz." }
} finally {
    Pop-Location
}

# --- 2. Uygulama exe'sini imzala -----------------------------------------
Write-Host "`n=== 2/3  Uygulama imzalama ===" -ForegroundColor Cyan
if ($sign) {
    $signArgs = @{ Files = @($appExe) }
    if ($Thumbprint) { $signArgs.Thumbprint = $Thumbprint }
    else { $signArgs.PfxPath = $PfxPath; if ($PfxPassword) { $signArgs.PfxPassword = $PfxPassword } }
    & (Join-Path $PSScriptRoot 'sign.ps1') @signArgs
} else {
    Write-Host "Sertifika verilmedi -> imzalama atlandi (SmartScreen uyarisi cikacak)." -ForegroundColor Yellow
}

# --- 3. Kurulum dosyasi ---------------------------------------------------
Write-Host "`n=== 3/3  Kurulum dosyasi ===" -ForegroundColor Cyan
$isccArgs = @($iss)
if ($sign) {
    $signtool = (Get-ChildItem "${env:ProgramFiles(x86)}\Windows Kits\10\bin" -Filter signtool.exe -Recurse |
        Where-Object { $_.FullName -match '\\x64\\' } | Sort-Object FullName -Descending | Select-Object -First 1).FullName

    # Inno Setup'in kendi kacislari kullanilir:
    #   $q -> cift tirnak   (ic ice tirnak sorunu boylece hic olusmaz)
    #   $f -> imzalanacak dosyanin adi (Inno doldurur)
    # Tek tirnakli string sart: PowerShell $q ve $f'i degisken sanmasin.
    $certPart = if ($Thumbprint) {
        '/sha1 ' + $Thumbprint
    } elseif ($PfxPassword) {
        '/f $q' + $PfxPath + '$q /p ' + $PfxPassword
    } else {
        '/f $q' + $PfxPath + '$q'
    }

    $signCmd = '$q' + $signtool + '$q sign /fd SHA256 /td SHA256 /tr ' +
               $TimestampUrl + ' ' + $certPart + ' $f'

    $isccArgs = @('/DSIGN', "/Soysign=$signCmd") + $isccArgs
}

& $iscc @isccArgs
if ($LASTEXITCODE -ne 0) { throw "ISCC basarisiz." }

# --- Ozet -----------------------------------------------------------------
$setup = Join-Path $repo 'dist\OY_Dashboard_Setup.exe'
Write-Host "`n=== Sonuc ===" -ForegroundColor Cyan
$item = Get-Item $setup
"{0}  ({1:N1} MB)" -f $item.FullName, ($item.Length / 1MB)
"SHA-256 : $((Get-FileHash $setup -Algorithm SHA256).Hash)"
"Imza    : $((Get-AuthenticodeSignature $setup).Status)"
if (-not $sign) {
    Write-Host "`nSertifika aldiginizda: .\build_release.ps1 -Thumbprint <parmak izi>" -ForegroundColor Yellow
}
