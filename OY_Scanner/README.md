# OY Scanner Probe

OY Scanner Probe, eSole yazilimi ve ayak tarayici sistemi arasindaki davranisi pasif olarak gozlemlemek icin hazirlanmis bir Windows loglama aracidir.

Arac herhangi bir cihaza komut gondermez. Surecleri, ag baglantilarini, USB/COM cihazlarini, named pipe listesini ve secilen klasorlerdeki dosya degisikliklerini zaman damgali olarak kaydeder.

## Ne Kaydeder?

- Calisan surecler ve yeni/kapanan surecler
- `eSole` gibi hedef surecler icin exe yolu, baslangic zamani, modul listesi ve pencere basligi
- `netstat -ano` ciktisi ile TCP/UDP baglantilari
- USB, COM ve PnP cihaz anlik gorunumleri
- Windows servis anlik gorunumu
- Named pipe anlik gorunumu
- Secilen klasorlerde olusan, degisen, silinen veya yeniden adlandirilan dosyalar
- eSole tarafindan uretilen rapor, STL, gorsel ve analiz klasorleri gibi dosya aktiviteleri

## Derleme

Gelistirme bilgisayarinda:

```powershell
cd C:\dev_projects\oy_dashboard_dev_project\OY_Dashboard\OY_Scanner
.\build.ps1
```

Derleme sonunda exe burada olusur:

```text
dist\OYScannerProbe.exe
```

## Tarama Bilgisayarinda Calistirma

`dist` klasorunu tarama bilgisayarina kopyalayin. Sonra PowerShell veya Komut Istemi ile:

```powershell
.\OYScannerProbe.exe --config .\probe.config.json --duration-minutes 30
```

eSole ciktisinin yazildigi klasoru biliyorsaniz ek olarak izletebilirsiniz:

```powershell
.\OYScannerProbe.exe --config .\probe.config.json --watch "C:\eSole\Output" --duration-minutes 30
```

Tarama akisi icin onerilen kullanim:

1. eSole kapaliyken probe'u baslatin.
2. eSole'u acin.
3. Yeni hasta/kullanici kaydi olusturun.
4. Taramayi baslatin ve rapor olusana kadar bekleyin.
5. Probe'u `Ctrl+C` ile kapatin veya sure bitmesini bekleyin.
6. `logs` klasorunu analiz icin gelistirme bilgisayarina alin.

## Cikti Klasoru

Her calistirmada `logs\run-YYYYMMDD-HHMMSS` formatinda yeni bir klasor acilir.

Onemli dosyalar:

- `events.ndjson`: ana olay akisi
- `process-snapshots.ndjson`: surec anlik gorunumleri
- `target-process.ndjson`: hedef surec detaylari
- `netstat.txt`: ag anlik gorunumleri
- `devices.ndjson`: USB/COM/PnP anlik gorunumleri
- `services.txt`: servis anlik gorunumleri
- `pipes.ndjson`: named pipe anlik gorunumleri
- `file-events.ndjson`: izlenen klasorlerdeki dosya olaylari

## Ayarlar

`probe.config.json` icindeki `targetProcessNames` alanina eSole surec adi eklenebilir. Ornek:

```json
{
  "targetProcessNames": ["eSole", "ESole", "FootScan"],
  "watchPaths": ["C:\\ProgramData", "C:\\Users\\Public\\Documents"],
  "outputDirectory": "logs",
  "snapshotIntervalSeconds": 5
}
```

Ilk calistirmada cok fazla dosya olayi gelirse `watchPaths` listesini eSole'un rapor cikti klasoru ve kurulum klasoruyle sinirlandirin.

## LSF350 Arsiv Analizi

Tarama cikti klasor yapisini incelemek icin:

```powershell
.\OYScanArchiveAnalyzer.exe --root "D:\LSF350\2026" --max-scans 10
```

Arac `analysis` klasoru altina JSON, CSV ve Markdown raporu uretir. Bu rapor OY Dashboard icin importer tasarlarken hangi dosyalarin nerede oldugunu gormek icindir.

Daha hafif rapor almak icin:

```powershell
.\OYScanArchiveAnalyzer.exe --root "D:\LSF350\2026" --max-scans 10 --key-files-only
```
## Window Inspector / Automation Probe

eFoot penceresinin Windows UI Automation ile okunup okunamadigini incelemek icin:

```powershell
.\OYAutomationProbe.exe --target eFoot --max-depth 10 --max-nodes 1500
```

Cikti `automation-analysis` klasorune JSON ve Markdown olarak yazilir. Arac pasiftir; tiklama yapmaz, form doldurmaz, sadece pencere ve kontrol agacini raporlar.

Tum gorunur pencereleri taramak gerekirse:

```powershell
.\OYAutomationProbe.exe --all-windows --max-windows 20 --max-depth 6
```