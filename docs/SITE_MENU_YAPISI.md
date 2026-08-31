# OPTIYOU Public Site — Menü Yapısı

Kaynak: [`lib/site/site_routes.dart`](../lib/site/site_routes.dart) (`siteNavigation`),
[`lib/site/components/app_header.dart`](../lib/site/components/app_header.dart),
[`lib/site/components/app_footer.dart`](../lib/site/components/app_footer.dart).

Bu belge kod değişmedikçe geçerlidir; menü güncellendiğinde yeniden üretilmelidir.

---

## 1. Üst bar — ana navigasyon (mega-menü)

Üst bar dar ekranlarda kısa etiket (`barLabel`) kullanır; mega-menü ve mobil menüde her zaman tam
etiket gösterilir. Bir öğenin `children` listesi varsa üst barda tıklanınca doğrudan gitmez,
mega-menü açar.

### Nasıl Çalışır?

- Doğrudan bağlantı, alt menüsü yok.
- Route: `/nasil-calisir`

### Çözümler

| Bağlantı | Route | Açıklama |
|---|---|---|
| Klinikler | `/cozumler/klinikler` | Ölçüm, takip ve ürün süreçlerini tek akışta yönetin. |
| Eczaneler ve Ayakkabı Mağazaları | `/cozumler/eczaneler-ayakkabi-magazalari` | Mağaza içinde tarama ile doğru ürüne yönlendirin. |
| İş Yerleri | `/cozumler/is-yerleri` | Ayakta çalışan ekipler için toplu ölçüm programı. |
| Bireysel Kullanıcılar | `/cozumler/bireysel` | Kendi ayak profilini çıkar, uygun ürünü seç. |
| Tarama Standı İçin Başvur | `/tarama-standi-basvuru` | İşletmenize tarama standı kurulumu için başvurun. |

### Ürünler

| Bağlantı | Route | Açıklama |
|---|---|---|
| Tüm Tabanlıklar | `/tabanliklar` | Ürün ailelerinin tamamı. |
| Günlük Tabanlıklar | `/tabanliklar/gunluk` | Gün boyu konfor için veri güdümlü anatomik yapı. |
| Spor Tabanlıkları | `/tabanliklar/spor` | Karbon fiber taban, darbe emilimi desteği. |
| Recovery Ürünleri | `/tabanliklar/recovery` | OY Recovery toparlayıcı sandalet ailesi. |
| Veri Güdümlü Ortopedik İş Ayakkabısı | `/is-ayakkabisi` | Ayakta çalışma senaryosu için geliştirilen model. |

### Anatomik Kategorilerimiz

- Üst barda kısa etiket: **Kategoriler**
- Doğrudan bağlantı, alt menüsü yok.
- Route: `/anatomik-kategorilerimiz`

### Teknolojilerimiz

- Üst barda kısa etiket: **Teknoloji**

| Bağlantı | Route | Açıklama |
|---|---|---|
| 3D Ayak Tarama | `/teknolojilerimiz` | Ayak geometrisinin üç boyutlu kaydı. |
| Basınç Ölçümü | `/teknolojilerimiz` | Basış dağılımının görünür hâle getirilmesi. |
| Yapay Zekâ Destekli Değerlendirme | `/teknolojilerimiz` | Ölçüm verisinden uyum sınıfına giden yol. |
| Üretim ve Tarama Teknolojilerimiz | `/teknolojilerimiz` | Tarama donanımı ve üretim hattı. |
| DML — Dijital Üretim Laboratuvarı | `/teknolojilerimiz/dml` | Geliştirme, test, prototipleme omurgası. |
| Kalite ve Doğruluk | `/teknolojilerimiz` | Ölçüm doğruluğu ve tekrarlanabilirlik. |
| Veri Güvenliği | `/teknolojilerimiz` | Ölçüm verisinin saklanması ve korunması. |

> Not: DML dışındaki altı bağlantı şu an aynı sayfaya (`/teknolojilerimiz`) gidiyor; sayfa
> içinde ilgili bölüme çapa (anchor) eklenmedi.

### TÜBİTAK Projelerimiz

- Üst barda kısa etiket: **TÜBİTAK**

| Bağlantı | Route |
|---|---|
| 1812 — Yenilikçi Ürünler ve Üretim Teknolojileri | `/tubitak-projeleri/1812` |
| 1707 — Siparişe Dayalı Ar-Ge Projesi | `/tubitak-projeleri/1707` |
| Tüm Projeler | `/tubitak-projeleri` |

### Kurumsal

| Bağlantı | Route |
|---|---|
| Hakkımızda | `/hakkimizda` |
| Ekibimiz | `/ekibimiz` |
| Kariyer | `/kariyer` |
| Haberler / Basın | `/haberler` |
| Ölçüm Merkezleri | `/olcum-merkezleri` |
| İletişim | `/iletisim` |

---

## 2. Üst bar — sağ aksiyon alanı

Mega-menü öğesi değildir; her sayfada sabit görünen iki buton.

| Etiket (geniş / dar bar) | Route |
|---|---|
| Giriş Yap | `/giris` (→ `main.dart` içindeki `LoginScreen`, `/login` de çalışır) |
| Tarama İçin Randevu Al / Randevu Al | `/tarama-randevusu` |

---

## 3. Alt bilgi (footer) menüsü

Üst bar menüsünden bağımsız, kendi gruplamasıyla tekrarlanan kısa yollar.

### Ürünler

- Günlük Tabanlıklar — `/tabanliklar/gunluk`
- Spor Tabanlıkları — `/tabanliklar/spor`
- Recovery Ürünleri — `/tabanliklar/recovery`
- Veri Güdümlü Ortopedik İş Ayakkabısı — `/is-ayakkabisi`

### Keşfet

- Nasıl Çalışır? — `/nasil-calisir`
- Anatomik Kategorilerimiz — `/anatomik-kategorilerimiz`
- Teknolojilerimiz — `/teknolojilerimiz`
- Ölçüm Merkezleri — `/olcum-merkezleri`
- SSS — `/sss`

### Kurumsal

- Hakkımızda — `/hakkimizda`
- Ekibimiz — `/ekibimiz`
- Kariyer — `/kariyer`
- TÜBİTAK Projelerimiz — `/tubitak-projeleri`
- İletişim — `/iletisim`

### Bülten

- E-posta bültenine kayıt formu (`NewsletterForm`) — route yok, form gönderimi.

### Yasal (footer alt satırı)

- Gizlilik Politikası — `/gizlilik-politikasi`
- Kullanım Koşulları — `/kullanim-kosullari`
- KVKK — `/kvkk`

---

## 4. Menüde yer almayan diğer route'lar

Bu adresler herhangi bir menüde bağlantı olarak durmaz, yalnızca doğrudan erişim veya
CTA (ör. bölüm içi buton) ile ulaşılır.

- `/` — Ana sayfa
- `/sss` — footer'da var, üst bar mega-menüsünde yok

---

## 5. Route sabitleri kaynağı

Tüm yollar `SiteRoutes` sınıfında (`lib/site/site_routes.dart`) tanımlıdır. Yeni bir menü
öğesi eklenirken hem `SiteRoutes` sabiti hem `siteNavigation` (ve gerekiyorsa `AppFooter`)
güncellenmeli, `sitePageContent` (`lib/site/content/site_page_content.dart`) içinde karşılık
gelen içerik girilmelidir; aksi hâlde `generateSiteRoute` o adres için `null` döner ve
kullanıcı ana sayfaya düşer.
