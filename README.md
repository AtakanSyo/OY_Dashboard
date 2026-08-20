# OPTIYOU — Public Site (`public-site-only`)

Bu dal, OPTIYOU Flutter uygulamasının **yalnızca herkese açık site** kısmını içerir:
karşılama (ana) sayfası, üst bar / mega-menü, menü altındaki içerik sayfaları,
footer ve site tasarım sistemi.

**Kapsam dışı (bu dalda yok):** giriş (`/giris`, `/login`), kayıt, şifre sıfırlama,
yasal onay, ödeme akışı ve giriş sonrası tüm dashboard ekranları (hasta, ölçüm,
analiz, sipariş, operasyon, kurumsal paneller), bunlara ait servisler, modeller,
repository'ler, Supabase yapılandırması/migration'ları ve dashboard'a özel asset'ler.
Bu kısımlar `main` dalında durmaktadır.

Üst bardaki "Giriş" bağlantısı bu dalda tanımlı olmadığı için ana sayfaya döner.

## Yapı

| Klasör | İçerik |
| --- | --- |
| `lib/site/` | Site route'ları, sayfalar, bileşenler, tema (Superspec §6–§8) |
| `lib/legal/` | Footer'dan açılan yasal belge metinleri |
| `lib/l10n/` | Dil seçimi altyapısı (site içeriği Türkçe) |
| `lib/main.dart` | Site-only uygulama girişi ve route üretimi |
| `test/` | Site yerleşim ve genişlik testleri |

## Çalıştırma

```bash
flutter pub get
flutter run -d chrome        # web
flutter run -d windows       # masaüstü
flutter test                 # site testleri
```

Referans spesifikasyon: [docs/OPTIYOU_CLAUDE_CODE_MASTER_SUPERSPEC.md](docs/OPTIYOU_CLAUDE_CODE_MASTER_SUPERSPEC.md)
