# Eksik Asset Talebi

Aşağıdaki varlıklar projede bulunamadı. Yerlerine "Görsel bekleniyor" işaretli placeholder
kullanıldı; marka doğruluğu için gerçekleriyle değiştirilmeleri gerekiyor.

> Not: Superspec §12.3'te listelenen `/mnt/data/...` yolları bu çalışma ortamında **erişilebilir
> değil** (bunlar sohbet ortamına yüklenmiş dosyalardı). Aşağıdaki liste, projedeki `assets/`
> klasörü taranarak çıkarılmıştır.

## Kritik (uydurulmadı, kullanıcıdan bekleniyor)

1. **DML / dijital üretim laboratuvarı fotoğrafları**
   Kullanılacağı yer: `/teknolojilerimiz/dml`
   Gerekli: tesis, makine ve üretim hattı fotoğrafları (yatay, en az 1600 px genişlik).

2. **Ekip ve kurumsal fotoğraflar**
   Kullanılacağı yer: `/ekibimiz`
   Gerekli: ekip portreleri veya ortak çalışma fotoğrafı + kısa tanıtım metinleri.

3. **Ürün detay render setleri**
   Kullanılacağı yer: `/tabanliklar/gunluk`, `/tabanliklar/spor`, `/tabanliklar/recovery`,
   `/is-ayakkabisi`
   Mevcut: her ürün için tek bir vitrin render'ı var ve kullanılıyor.
   Gerekli: farklı açı, detay ve malzeme yakın çekimleri (şeffaf arka planlı PNG tercih edilir).

4. **TÜBİTAK 1812 ve 1707 için paylaşılabilir proje görselleri**
   Kullanılacağı yer: `/tubitak-projeleri/1812`, `/tubitak-projeleri/1707`

## Hero videosu — optimizasyon gerekiyor

`assets/video/hero.mp4` mevcut ve ana sayfada kullanılıyor, ancak **web için fazla ağır**:

| Ölçüm | Değer |
| --- | --- |
| Boyut | 22,8 MB |
| Süre | 10 sn |
| Bit hızı | ~18,3 Mbit/s |

Bu, ana sayfayı açan her ziyaretçinin indireceği veri demek. 10 saniyelik sessiz bir döngü için
1,5–2,5 Mbit/s fazlasıyla yeterli (yaklaşık 2–3 MB). Web'e uygun bir kopya şu komutla üretilebilir:

```bash
ffmpeg -i assets/video/hero.mp4 -an -vf "scale=1600:-2" \
  -c:v libx264 -profile:v high -crf 26 -preset slow -movflags +faststart \
  assets/video/hero_web.mp4
```

Poster dosyası WebP'ye çevrildi ve kod artık onu kullanıyor:
`hero_poster.png` (1 MB) → `hero_poster.webp` (51 KB). PNG dosyası silinmedi.

Video dönüşümü için onay bekleniyor; onay verilirse üretilip koda bağlanabilir.

## Görsel dışı eksikler

5. **Ölçüm merkezleri listesi** (`/olcum-merkezleri`)
   Gerekli: merkez adı, adres, şehir, çalışma saatleri — veri dosyası veya servis ucu.

6. **İletişim bilgileri** (`/iletisim`)
   Gerekli: adres, telefon, e-posta, varsa harita koordinatı.

7. **Başvuru formu gönderim ucu** (`/tarama-standi-basvuru`)
   Gerekli: formun gönderileceği servis (e-posta ucu, Supabase tablosu veya CRM).

8. **Bülten kaydı servisi** (footer)
   Gerekli: liste sağlayıcısı ve API bilgisi.

9. **Açık pozisyonlar** (`/kariyer`), **haber/basın içerikleri** (`/haberler`),
   **blog yazıları** (`/blog`).

## Mevcut ve kullanılan varlıklar (talep edilmesine gerek yok)

- OPTIYOU logo: `assets/images/branding/logo.png` ve `logo_footer.png`
- Ürün vitrin render'ları: `custom_insole.png`, `sport_insole.png`, `recovery_sandal.png`,
  `personal_insole.png`, `personal_shoe.png`
- Ayak konturu: `assets/images/analysis/left_foot_top.png`
- Plantar basınç ısı haritası: `assets/heatmaps/left_arch.png`
- Sistem görselleri: `assets/images/systems/` (oy_scan, oy_scan_pro, basınç pedleri) —
  teknoloji sayfaları detaylandırılırken kullanılabilir.
