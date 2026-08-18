<#
.SYNOPSIS
    OPTIYOU Windows dosyalarini Authenticode ile imzalar.

.DESCRIPTION
    Sertifika iki yoldan verilebilir:

      -Thumbprint  Windows sertifika deposundaki sertifikanin parmak izi.
                   Donanim token'lari (Yubikey, SafeNet) ve bulut imzalama
                   bu yolu kullanir; ozel anahtar disari cikmaz.

      -PfxPath     .pfx dosyasi (+ -PfxPassword). Yalnizca eski sertifikalar
                   ve test icin; 2023 sonrasi CA sertifikalari .pfx gelmez.

    Zaman damgasi her zaman eklenir. Bu sart: zaman damgasiz imza,
    sertifika suresi dolunca gecersiz olur ve uygulama "imzasiz" gorunur.
    Zaman damgali imza, sertifika sonradan expire olsa bile gecerli kalir.

.EXAMPLE
    .\sign.ps1 -Thumbprint A1B2C3... -Files "..\build\windows\x64\install\oy_site.exe"
#>
[CmdletBinding(DefaultParameterSetName = 'Store')]
param(
    [Parameter(Mandatory, ParameterSetName = 'Store')]
    [string]$Thumbprint,

    [Parameter(Mandatory, ParameterSetName = 'Pfx')]
    [string]$PfxPath,

    [Parameter(ParameterSetName = 'Pfx')]
    [string]$PfxPassword,

    [Parameter(Mandatory)]
    [string[]]$Files,

    # RFC3161 zaman damgasi sunucusu. Biri cevap vermezse digerleri denenir.
    [string[]]$TimestampUrls = @(
        'http://timestamp.digicert.com',
        'http://timestamp.sectigo.com',
        'http://timestamp.globalsign.com/tsa/r6advanced1'
    )
)

$ErrorActionPreference = 'Stop'

function Get-SignTool {
    $roots = @(
        "${env:ProgramFiles(x86)}\Windows Kits\10\bin",
        "$env:ProgramFiles\Windows Kits\10\bin"
    ) | Where-Object { Test-Path $_ }

    $tool = $roots |
        ForEach-Object { Get-ChildItem $_ -Filter signtool.exe -Recurse -ErrorAction SilentlyContinue } |
        Where-Object { $_.FullName -match '\\x64\\' } |
        Sort-Object FullName -Descending |
        Select-Object -First 1

    if (-not $tool) {
        throw "signtool.exe bulunamadi. Windows SDK kurulu olmali."
    }
    return $tool.FullName
}

$signtool = Get-SignTool
Write-Host "signtool : $signtool"

# Imzalanacak dosyalari cozumle.
# @(...) sart: tek dosyada duz string olusur ve splat karakter karakter dagitir.
$targets = @(
    foreach ($f in $Files) {
        $resolved = Resolve-Path $f -ErrorAction SilentlyContinue
        if (-not $resolved) { throw "Dosya bulunamadi: $f" }
        $resolved.Path
    }
)

# Sertifika secimi
$certArgs = if ($PSCmdlet.ParameterSetName -eq 'Store') {
    $cert = Get-ChildItem Cert:\CurrentUser\My, Cert:\LocalMachine\My -ErrorAction SilentlyContinue |
        Where-Object { $_.Thumbprint -eq $Thumbprint }
    if (-not $cert) {
        throw "Sertifika depoda bulunamadi: $Thumbprint"
    }
    Write-Host "sertifika: $($cert.Subject)  (gecerlilik sonu: $($cert.NotAfter))"
    @('/sha1', $Thumbprint)
} else {
    if (-not (Test-Path $PfxPath)) { throw ".pfx bulunamadi: $PfxPath" }
    Write-Host "sertifika: $PfxPath"
    if ($PfxPassword) { @('/f', $PfxPath, '/p', $PfxPassword) } else { @('/f', $PfxPath) }
}

# Imzala; zaman damgasi sunuculari sirayla denenir.
#
# Zaman damgasi sunuculari zaman zaman gecici hata verir, bu yuzden her biri
# iki kez denenir ve sonra digerine gecilir. Native komut stderr'e yazinca
# ErrorActionPreference='Stop' bunu sonlandirici hataya cevirdigi icin cagri
# gecici olarak 'Continue' altinda yapilir; basari $LASTEXITCODE ile olculur.
$signed = $false
:outer foreach ($ts in $TimestampUrls) {
    foreach ($attempt in 1..2) {
        $signArgs = @('sign', '/fd', 'SHA256', '/td', 'SHA256', '/tr', $ts) + $certArgs + $targets

        $prev = $ErrorActionPreference
        $ErrorActionPreference = 'Continue'
        try {
            & $signtool @signArgs 2>&1 | Out-String | Write-Verbose
            $code = $LASTEXITCODE
        } finally {
            $ErrorActionPreference = $prev
        }

        if ($code -eq 0) {
            Write-Host "zaman damgasi: $ts"
            $signed = $true
            break outer
        }
        Write-Warning "Zaman damgasi basarisiz ($ts, deneme $attempt/2)."
        Start-Sleep -Seconds 2
    }
}
if (-not $signed) {
    throw @"
Hicbir zaman damgasi sunucusuna ulasilamadi; imzalama yapilmadi.

Zaman damgasiz imzalamak istemiyoruz: sertifika suresi dolunca imza
gecersiz olur ve daha once dagitilmis kurulumlar "imzasiz" gorunmeye baslar.
Ag baglantisini/proxy ayarini kontrol edip tekrar deneyin.
"@
}

# Dogrula. Guven zinciri hatasi imzalamayi bosa cikarmaz (test sertifikasinda
# beklenen durum), o yuzden bu adim derlemeyi durdurmaz.
Write-Host "`n--- dogrulama ---"
$prev = $ErrorActionPreference
$ErrorActionPreference = 'Continue'
try {
    & $signtool verify /pa /v $targets 2>&1 | Out-String | Write-Verbose
    $verifyCode = $LASTEXITCODE
} finally {
    $ErrorActionPreference = $prev
}

foreach ($t in $targets) {
    $sig = Get-AuthenticodeSignature $t
    "{0,-36} {1}" -f (Split-Path $t -Leaf), $sig.Status
}

if ($verifyCode -ne 0) {
    Write-Warning @"
Imza dosyaya yazildi ama guven zinciri dogrulanamadi.
Kendi urettiginiz test sertifikasi kullaniyorsaniz bu beklenen durumdur;
gercek bir CA sertifikasinda bu adim temiz gecmelidir.
"@
}
