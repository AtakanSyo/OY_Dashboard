# OPTIYOU Claude Code Master MD — En Kapsamlı Web Sitesi ve Landing Page Spesifikasyonu

> **Bu dosya, Claude Code'a tek başına verilebilecek ana master dokümandır.**  
> Amaç; OPTIYOU’nun marka kimliğine uygun, public web sitesini ve landing page yapısını sıfırdan planlamak, tasarlamak, kodlamak, test etmek ve çalışır hâlde teslim etmektir.  
> Bu dosya; önceki üç markdown kaynağının, landing page mockup’ının, menü mimarisinin, marka dilinin, skill protokolünün ve görsel ihtiyaçlarının **konsolide edilmiş ana sürümüdür**.

---

# 0. Bu dosyanın kapsamı

Bu master dosya aşağıdaki kapsamı birlikte tanımlar:

1. **OPTIYOU genel public web sitesi**  
2. **Landing page / ana giriş sayfası**  
3. **Ürün, çözüm, teknoloji, proje ve kurumsal sayfalar**  
4. **Claude Code çalışma protokolü**  
5. **Skill aktivasyon kuralları**  
6. **Marka kimliği ve public dil kısıtları**  
7. **Gerekli asset / görsel envanteri**  
8. **Eksik görseller için kullanıcıdan istenecekler**  
9. **Flutter Web uygulama mimarisi**  
10. **Teslim kriterleri, QA, test ve raporlama**

---

# 1. Mutlak stratejik çerçeve

## 1.1 OPTIYOU nasıl konumlanacak?

OPTIYOU, yalnızca “tabanlık satan bir ürün markası” gibi konumlanmayacaktır.  
Ana anlatı:

**Dijital ayak ölçümü, veri güdümlü değerlendirme, uygun ürün seçimi, üretim ve takip altyapısını bir araya getiren yeni nesil ayak deneyimi platformu.**

Public web sitesinde anlatı omurgası şu sırayla ilerlemelidir:

1. 3D ayak tarama  
2. Basınç ölçümü  
3. Yapay zekâ destekli değerlendirme  
4. En uygun tabanlığın / ürünün belirlenmesi  
5. Üretim  
6. Kargo / teslimat  
7. Geri bildirim ve dijital takip

## 1.2 Ana hedef kitleler

### Birincil hedef kitle
- Klinikler
- Eczaneler
- Ayakkabı mağazaları
- İş yerleri / kurumsal sağlık yapıları

### İkincil hedef kitle
- Bireysel kullanıcılar
- Sporcular
- Performans odaklı kullanıcılar
- Gün boyu ayakta çalışan profesyoneller

---

# 2. Public dil ve mevzuat sınırları — zorunlu

## 2.1 Public alanda kesinlikle kullanılmaması gereken kelimeler

Aşağıdaki kelimeler **public ürün sayfalarında, landing page’lerde ve pazarlama dilinde kullanılmayacaktır**:

- **kişiselleştirilmiş**
- **ortez**
- **analiz**

## 2.2 Yerine kullanılacak güvenli public karşılıklar

| Kullanılmayacak | Public karşılık |
|---|---|
| kişiselleştirilmiş | kullanıcıya uygun, veriye göre seçilen, ayak profiline uygun, veri güdümlü |
| ortez | iç taban, tabanlık, destek ürünü |
| analiz | değerlendirme, veri incelemesi, ölçüm sonucu, sınıflandırma |

## 2.3 Public dilde kaçınılacak ifadeler

Aşağıdaki türde ifadeler public sitede kullanılmaz:

- tedavi eder
- teşhis koyar
- düzeltir
- hastalığı iyileştirir
- medikal sonuç garantisi sunar
- klinik tanı verir
- reçete yerine geçer

## 2.4 Public sitede kullanılabilecek güvenli anlatım

Örnek güvenli ifadeler:

- Ayak yapısını daha iyi anlamaya yardımcı olur.
- Kullanıcıya uygun ürün seçim sürecini destekler.
- Yürüyüş konforunu artırmaya yardımcı olur.
- Basış dağılımını görünür hâle getirir.
- Ayak profiline göre uygun seçenekleri öne çıkarır.
- Günlük kullanımda destek ve konfor sunar.

---

# 3. Claude Code skill protokolü — zorunlu

Bu projede aşağıdaki skill’ler **isimleriyle çağrılmalı ve aktif kullanılmalıdır**.

## 3.1 Zorunlu skill seti

| Skill | Görevi | Ne zaman kullanılacak |
|---|---|---|
| `frontend-design` | Estetik yön, tipografi, section kompozisyonu, premium teknoloji dili | Kodlamadan önce |
| `ui-ux-pro-max` | Bilgi mimarisi, form akışı, mega-menu, responsive davranış | IA ve sayfa kurgusunda |
| `design-system` | Token sistemi, bileşen sözleşmeleri, buton/kart/form standardı | Tema ve component kurulurken |
| `banner-design` | Hero ve büyük tanıtım görselleri için görsel yön / brief | Büyük görsel veya banner gerektiğinde |
| `impeccable` | UI/UX denetimi, görsel cilalama, erişilebilirlik, spacing | Her ana sayfa sonrasında ve finalde |

## 3.2 Çalışma sırası

1. Bu dosyanın tamamını oku.  
2. Asset envanterini çıkar.  
3. `frontend-design` ile estetik yönü tanımla.  
4. `ui-ux-pro-max` ile bilgi mimarisini ve user flow’u doğrula.  
5. `design-system` ile token ve ortak component sistemini kur.  
6. Gerekirse `banner-design` ile eksik görseller için brief üret.  
7. Uygulamayı route bazlı geliştir.  
8. Her büyük ekran sonrasında `impeccable` ile gözden geçir.  
9. Desktop, tablet, mobil kalite turu yap.  
10. `flutter analyze`, testler ve release build çalıştır.  
11. `IMPLEMENTATION_REPORT.md` oluştur.

## 3.3 Skill’ler bu dokümanı geçersiz kılamaz

Öncelik sırası:

1. Bu dosyadaki marka kimliği ve public dil kuralları  
2. Bu dosyadaki menü, içerik ve sayfa mimarisi  
3. Bu dosyadaki asset kuralları  
4. Skill önerileri  
5. Framework varsayılanları

---

# 4. Teknoloji ve framework hedefi

## 4.1 Ana hedef

- **Flutter Web public site**
- Responsive
- Erişilebilir
- Yüksek görsel kalite
- Asset eksikken bile derlenebilir

## 4.2 Başlangıç kuralı

Bu dosya, Claude Code’un sıfırdan proje açabileceği varsayımıyla hazırlanmıştır.

Önerilen başlangıç:

```bash
flutter create optiyou_web --platforms=web
cd optiyou_web
flutter pub add google_fonts
flutter pub add url_launcher
flutter pub add video_player
```

## 4.3 Uydurulmaması gerekenler

Aşağıdaki alanlar ayrıca veri / API spesifikasyonu olmadan uydurulmayacaktır:

- gerçek kullanıcı doğrulama backend’i
- gerçek ödeme sistemi
- gerçek dashboard veritabanı
- sahte klinik veri tabloları
- gerçek rapor motoru

Bunların yerine:

- arayüz iskeleti
- placeholder state
- future integration hooks
- TODO notları

eklenmelidir.

---

# 5. Marka kimliği

## 5.1 Renk paleti

| Token | Hex | Kullanım |
|---|---:|---|
| Deep Teal | `#0E1F22` | Ana metin, footer, koyu hero yüzeyi |
| Pine Green | `#2E8C7A` | Primary CTA, aktif durum, ikon |
| Ice White | `#F5FBFD` | Açık arka plan |
| Pure White | `#FFFFFF` | Kart, navbar, form alanı |
| Charcoal | `#38474B` | İkincil metin |
| Deep Pine | `#1F3F3D` | Hover, koyu vurgu |
| Soft Border | `#DCE6EA` | Border, divider |

**Yasak:** generic Material blue, indigo, neon cyber renk paleti, marka dışı baskın turuncu.

## 5.2 Tipografi

- Başlık: **Montserrat**
- Body / UI: **Public Sans**

Boyut sistemi:

- Hero desktop: 52 px
- Hero mobile: 32 px
- H1: 38 px
- H2: 30 px
- H3: 20 px
- Body Large: 18 px
- Body: 16 px
- Small: 14 px
- Button/Nav: 15 px, 600–700 weight

## 5.3 Görsel karakter

Site şu hisleri vermelidir:

- temiz
- premium
- veri görünür
- modern
- mühendislik hassasiyeti taşıyan
- sade ve güven verici
- sağlık + teknoloji + e-ticaret hibriti

---

# 6. Site bilgi mimarisi — ana iskelet

## 6.1 Nihai ana navigasyon

Logo solda yer alır. `Anasayfa` ayrı metin olarak eklenmez; logo ana sayfaya götürür.

### Desktop menü

1. **Nasıl Çalışır?**
2. **Çözümler**
3. **Ürünler**
4. **Anatomik Kategorilerimiz**
5. **Teknolojilerimiz**
6. **TÜBİTAK Projelerimiz**
7. **Kurumsal**

### Sağ aksiyon alanı

- **Giriş Yap** veya oturum varsa **Ayak Profilim**
- **Tarama Standı İçin Başvur** (primary CTA)

> Not: Landing page varyasyonunda yukarıdaki karmaşık menü yerine daha sade versiyon kullanılabilir:  
> `Tabanlıklar / Nasıl Çalışır? / Ayak Profili / Hakkımızda / SSS / İletişim / Giriş Yap / Taramanı Başlat`

## 6.2 Çözümler mega-menu

- Klinikler
- Eczaneler ve Ayakkabı Mağazaları
- İş Yerleri
- Bireysel Kullanıcılar
- Tarama Standı İçin Başvur

## 6.3 Teknolojilerimiz mega-menu

- 3D Ayak Tarama
- Basınç Ölçümü
- Yapay Zekâ Destekli Değerlendirme
- Üretim ve Tarama Teknolojilerimiz
- DML — Dijital Üretim Laboratuvarı
- Kalite ve Doğruluk
- Veri Güvenliği

## 6.4 TÜBİTAK Projeleri menüsü

- 1812 — Yenilikçi Ürünler ve Üretim Teknolojileri Projesi
- 1707 — Siparişe Dayalı Ar-Ge Projesi

## 6.5 Kurumsal menüsü

- Hakkımızda
- Ekibimiz
- Kariyer
- Haberler / Basın
- İletişim

---

# 7. Ana sayfa / landing page — zorunlu yapı

Bu bölüm, yüklenen landing page görseline dayalı ana giriş ekranını tanımlar.

## 7.1 Header

Sol:
- OPTIYOU wordmark / logo

Orta:
- Tabanlıklar
- Nasıl Çalışır?
- Ayak Profili
- Hakkımızda
- SSS
- İletişim

Sağ:
- **Giriş Yap** (outline button, ikonlu)
- **Taramanı Başlat** (primary CTA)

## 7.2 Hero bölümü

### Sol metin alanı
Ana başlık:

**Ayağını Tara, Doğru Tabanlıkla Konforu Hisset.**

Alt açıklama:

> 3D ayak tarama, basınç ölçümü ve akıllı değerlendirme ile yürüyüşüne en uygun tabanlık yapısını keşfet. Teknolojiyle desteklenen konforu deneyimle.

CTA’lar:
- Taramanı Başlat
- Nasıl Çalışır?

Mini faydalar:
- 2 Dakikada Tarama
- Bilimsel Ölçüm
- Hızlı Gönderim

### Sağ görsel kompozisyon
Aynı sahnede şu öğeler görünmelidir:

- 3D tarama ekranı
- ayak 3D mesh / iskeletimsi tel kafes görseli
- plantar basınç ısı haritası
- zemine basan ayak görseli
- 2 adet tabanlık ürün render’ı

## 7.3 4 adımlı süreç kartları

1. **3D Ayak Tarama**  
   Telefon kamerası ile ayağını 3 boyutlu olarak tararız.

2. **Basınç Ölçümü**  
   Basınç dağılımını ölçer, yürüme verilerini toplarız.

3. **Akıllı Değerlendirme**  
   Verileri değerlendirerek senin için en uygun tabanlık yapısını belirleriz.

4. **Uygun Tabanlık ve Kargo**  
   Senin için üretilen tabanlığın kargoya verilir, kapına ulaştırılır.

## 7.4 Tabanlık Teknolojilerimiz

Bölüm başlığı:

**Tabanlık Teknolojilerimiz**

### Kart 1
**Veri Güdümlü Anatomik Tabanlık**  
Günlük kullanım için tasarlandı. Ayak yapına uyum sağlar, gün boyu konfor sunar.

### Kart 2
**Sporcular İçin Karbon Fiber Tabanlık**  
Hafif karbon fiber tabanla performansını artırır, darbe emilimini destekler.

### Kart 3
**OY Recovery Anatomik Toparlayıcı Sandalet**  
SLA 3B teknolojisiyle kafes yapılı tasarım, hafiflik ve toparlayıcı destek sağlar.

Her kartta:
- ürün görseli
- kısa açıklama
- `İncele` butonu

## 7.5 Sana En Uygun Modeli Bulalım

Sol blokta kullanıcı şu verileri seçer:

- Ayakkabı numarası
- Kemer tipi
- Yürüme dengesi

Örnek değerler:
- Numara: 42
- Kemer: Orta
- Denge: Nötr

## 7.6 Önerilen model kartı

Etiket:
- Sana Önerilen Model

Ürün adı:
- **Balance Pro**

Açıklama:
- Dengeli yürüyüş için tasarlandı. Gün boyu konfor ve destek sağlar.

Özellikler:
- Orta kemer desteği
- Darbe emici yapı
- Nefes alabilir üst yüzey

CTA:
- Detayları Gör
- Sepete Ekle

Fiyat:
- **1.499 TL**
- KDV dahil

## 7.7 Üretim ve Teslimat Süreci

Yatay ikonlu akış:

1. Siparişin Alınır
2. Üretime Hazırlanır
3. Üretim Tamamlanır
4. Kargoya Verilir
5. Kapında

## 7.8 Sosyal kanıt / yorumlar

3 yorum kartı:
- Mert K.
- Seda A.
- Emre T.

Her kart:
- avatar
- yıldız puanı
- kısa yorum
- isim

## 7.9 Footer

Sütunlar:
- Ürünler
- Keşfet
- Kurumsal
- Bülten

Alt linkler:
- Gizlilik Politikası
- Kullanım Koşulları
- KVKK Aydınlatma Metni

---

# 8. Sayfa listesi — tam kapsam

## 8.1 Zorunlu route’lar

- `/`
- `/giris`
- `/ayak-profili`
- `/nasil-calisir`
- `/tabanliklar`
- `/tabanliklar/gunluk`
- `/tabanliklar/spor`
- `/tabanliklar/recovery`
- `/teknolojilerimiz`
- `/teknolojilerimiz/dml`
- `/anatomik-kategorilerimiz`
- `/cozumler/klinikler`
- `/cozumler/eczaneler-ayakkabi-magazalari`
- `/cozumler/is-yerleri`
- `/cozumler/bireysel`
- `/tubitak-projeleri`
- `/tubitak-projeleri/1812`
- `/tubitak-projeleri/1707`
- `/olcum-merkezleri`
- `/hakkimizda`
- `/blog`
- `/iletisim`
- `/kvkk`
- `/gizlilik-politikasi`
- `/kullanim-kosullari`
- `/tarama-standi-basvuru`
- `/sepet`

## 8.2 Sayfa amaçları

### Nasıl Çalışır?
- süreci adım adım açıklar
- ölçüm, değerlendirme, ürün seçimi, üretim ve takip akışını gösterir

### Anatomik Kategorilerimiz
- ayak sınıflandırmasının mantığını açıklar
- sadece numara ve genişliğin neden yeterli olmadığını gösterir
- `un fit.pdf` bulgularını özetler

### Teknolojilerimiz
- 3D tarama
- basınç ölçümü
- yapay zekâ destekli değerlendirme
- üretim teknolojileri
- DML

### TÜBİTAK Projelerimiz
- 1812 ve 1707’yi anlaşılır ve kurumsal bir dille anlatır
- statüler hardcode edilmez

---

# 9. Anatomik Kategorilerimiz sayfası — zorunlu içerik

Bu sayfada ilk bölüm mutlaka şu ana fikirle açılmalıdır:

## 9.1 Ana başlık

**Numara Yalnızca Başlangıçtır**

## 9.2 Anlatılması gereken ana mesajlar

- Aynı ayakkabı numarası, farklı ayaklarda aynı uyumu garanti etmez.
- Uzunluk ve genişlik, ayağın tüm yapısını açıklamak için yeterli değildir.
- Ayak yapısı yük altında değişir.
- Gün içi değişim, zemin etkisi ve sağ-sol farkı dikkate alınmalıdır.
- Ayak seçimi tek bir ölçüye değil, çok parametreli değerlendirmeye dayanmalıdır.

## 9.3 UN FIT çalışmasından türetilmiş özet noktalar

Sayfada kısa maddeler hâlinde aşağıdaki mesajlar kullanılmalıdır:

- Aynı numara ayakkabılar arasında belirgin iç uzunluk farkları olabilir.
- İç genişlik ve hacim farkları da kullanıcı deneyimini etkiler.
- Standart numaralandırma her kullanıcı için yeterli değildir.
- Doğru seçim için yalnızca numara değil, ayak profili de önemlidir.

> Bu bölümde telif nedeniyle tam alıntı değil, kısa özet/parafraz kullanılacaktır.

## 9.4 Kategori sistemi

Public kategoriler, teşhis değil **ürün seçimini kolaylaştıran uyum sınıfları** olarak sunulacaktır.

Önerilen yapı:

- Temel uzunluk
- Ön ayak formu
- Kemer profili
- Adım yönelimi
- Konfor odağı

Örnek kod mantığı:

`42-R-M-N-B`

Açılım örneği:
- 42 = numara
- R = ön ayak formu
- M = orta kemer
- N = nötr yönelim
- B = balance / dengeli kullanım odağı

---

# 10. Teknolojilerimiz sayfası — zorunlu yapı

Bu sayfa aşağıdaki bölümleri içermelidir:

1. 3D Ayak Tarama
2. Basınç Ölçümü
3. Yapay Zekâ Destekli Değerlendirme
4. Üretim ve Tarama Teknolojilerimiz
5. DML — Dijital Üretim Laboratuvarı
6. Kalite ve Doğruluk
7. Veri Güvenliği

## 10.1 DML bölümü

DML, OPTIYOU’nun üretim ve geliştirme omurgası olarak anlatılmalıdır.

Mesaj çerçevesi:
- geliştirme
- test
- prototipleme
- dijital üretim yetkinliği
- yeni ürün doğrulama

---

# 11. Ürün mimarisi

## 11.1 Ürün aileleri

Public ürün aileleri:

- Günlük Tabanlıklar
- Spor Tabanlıkları
- Recovery Ürünleri
- Veri Güdümlü Ortopedik İş Ayakkabısı *(menüde bu başlık ayrıca görünmelidir)*

> Not: Başlıkta kullanıcı talebi doğrultusunda “Veri Güdümlü Ortopedik İş Ayakkabısı” ifadesi kullanılacaktır. Ancak sayfa metinlerinde gereksiz medikal ton büyütülmeyecektir.

## 11.2 Landing page’de öne çıkan ürünler

- Veri Güdümlü Anatomik Tabanlık
- Sporcular İçin Karbon Fiber Tabanlık
- OY Recovery Anatomik Toparlayıcı Sandalet
- Balance Pro (öneri kartında)

---

# 12. Görsel / asset yönetimi — zorunlu envanter sistemi

Bu bölüm Claude Code için çok kritiktir.

## 12.1 Genel kural

Claude Code, önce mevcut dosyaları kontrol edecektir.  
Bir görsel gerekliyse:

1. Önce bu master dosyada belirtilen **kaynak yolunu** kontrol eder.  
2. Varsa projedeki `assets/` klasörüne kopyalar / organize eder.  
3. Yoksa, bunun **resmî / marka açısından kritik** mi yoksa **üretilebilir placeholder** mı olduğuna karar verir.  
4. Kritik ve resmî ise **kullanıcıdan talep eder**.  
5. Kritik değilse, geçici placeholder / brief ile ilerler ve TODO notu bırakır.

## 12.2 Önerilen proje asset klasörleri

```text
assets/
  images/
    brand/
    hero/
    products/
    technology/
    testimonials/
    placeholders/
  icons/
  docs/
```

## 12.3 Mevcut doğrulanmış kaynak dosyalar

Aşağıdaki dosyalar çalışma ortamında bulunduğu için Claude Code bunları aramalı ve uygun olanları kullanmalıdır.

### A. Mevcut markdown ve strateji dosyaları

- `/mnt/data/WEB_SAYFASI_YAPISI_CLAUDE_CODE_MASTER(2).md`
- `/mnt/data/OPTIYOU_WEB_CLAUDE_CODE_MASTER_V2(1).md`
- `/mnt/data/OPTIYOU_landing_page_tabanlik_teknolojileri.md`
- `/mnt/data/giris-yapisi-uretim-rehberi.md`
- `/mnt/data/OPTIYOU_1707_MEKAP_Kaynak_Haritasi_Guncel_17-07-2026__Rev4.md`

### B. Kullanılabilir mockup / referans görseller

- `/mnt/data/optiyou_teknolojiyle_konforlu_adımlar.png`  
  → landing page referans mockup’ı

- `/mnt/data/optiyou_tabanlık_deneyimi_landing_sayfası.png`  
  → alternatif landing page referansı

- `/mnt/data/optiyou_tabanlıkları_konforlu_adımlara_yolculuk.png`  
  → alternatif görsel / banner referansı

- `/mnt/data/wide_high_resolution_mockup_image_of_a_website_mo.png`  
  → dokümantasyon / UX board referansı

- `/mnt/data/we_need_title_in_turkish_sentence_case_7_words.png`  
  → düşük öncelikli, sadece referans

### C. Kullanıcı tarafından yüklenen ekran görselleri

- `/mnt/data/ghostwriter_images/context/29bee21a-ae95-5e90-80db-90e627ec8eb9.png`  
  → son yüklenen landing page örneği

- `/mnt/data/ghostwriter_images/context/2f72d766-e4ea-5333-9b4a-95c2f85a0ae2.png`  
  → giriş yapısı / üretim rehberi ile ilişkili referans

- `/mnt/data/ghostwriter_images/context/244f2f44-6e52-5b79-b1d3-baf0ae59c01b.png`
- `/mnt/data/ghostwriter_images/context/4b9b2a20-248b-569e-a5ef-f35338943f14.png`

> Bu son iki görselin içeriği belirsizse önce kontrol et; uygunsa kullan, değilse es geç.

### D. Doküman / içerik kaynakları

- `/mnt/data/İç Taban Kategorizasyon Çalışması.pdf`
- `/mnt/data/İç Taban Kategorizasyon Çalışması(1).pdf`
- `/mnt/data/İç Taban Kategorizasyon Çalışması(2).pdf`
- `/mnt/data/un fit.pdf`
- `/mnt/data/Precision_Footwear_Ecosystem.pdf`
- `/mnt/data/Veri Güdümlü Hibrit Ayakkabı ve Tabanlık Üretim Platformu_ Yeni Nesil Üretim Stratejisi.pdf`
- `/mnt/data/Klinikler ve Eczaneler için Ayak Sağlığı için Dijital Takip ve Üretim Sistemi.pdf`

## 12.4 Görsel ihtiyaç matrisi

Aşağıdaki tablo, hangi görselin zorunlu olduğunu ve bulunamazsa ne yapılacağını tanımlar.

| Görsel ihtiyacı | Öncelik | Önerilen kaynak yolu | Bulunamazsa ne yapılacak? |
|---|---|---|---|
| Resmî OPTIYOU logo | Kritik | Kullanıcıdan ayrı logo asset beklenir | **Uydurma logo üretme.** Geçici tipografik `OPTIYOU` wordmark kullan ve kullanıcıdan iste |
| Landing page hero referansı | Yüksek | `/mnt/data/optiyou_teknolojiyle_konforlu_adımlar.png` | Bu yoksa `/mnt/data/ghostwriter_images/context/29bee21a-ae95-5e90-80db-90e627ec8eb9.png` kullan |
| 3D tarama / basınç arayüz görseli | Yüksek | Yukarıdaki hero referans görsellerinden crop / yeniden üretim referansı | Gerekirse placeholder üret, ama gerçek veri gibi sunma |
| Veri güdümlü anatomik tabanlık görseli | Yüksek | Hero referansındaki tabanlık / ürün görseli | Kullanıcıdan ürün render’ı iste veya sade placeholder kullan |
| Karbon fiber tabanlık görseli | Orta-Yüksek | Mockup içindeki ilgili ürün kartı | Yoksa kullanıcıdan render iste |
| OY Recovery sandal görseli | Yüksek | Landing page referansında görünen sandal görseli | Yoksa kullanıcıdan üretmesini / sağlamasını iste |
| Kullanıcı avatarları / testimonial görselleri | Orta | Placeholder kullanılabilir | Stok hissi vermeyen genel avatar placeholder kullan |
| Kargo / teslimat kutusu görseli | Düşük-Orta | Gerekirse placeholder | Yoksa ikon tabanlı anlatım yeterli |
| DML / üretim laboratuvarı görselleri | Orta-Yüksek | Kullanıcı sağladıysa kullan | Yoksa kullanıcıdan istenmeli; placeholder ile anlatım yapılabilir |
| TÜBİTAK proje kart görselleri | Düşük-Orta | Tipografi + ikon + sade grafik | Özel görsel yoksa metin tabanlı kart yeterli |

## 12.5 Kullanıcıdan mutlaka istenecek varlıklar

Claude Code aşağıdaki durumlarda kullanıcıdan görsel talep etmelidir:

1. **Resmî OPTIYOU logo dosyası yoksa**  
2. **Marka tarafından onaylı ürün render’ları yoksa**  
3. **OY Recovery sandal için net ürün görseli yoksa**  
4. **DML / üretim teknolojileri sayfasında kullanılacak gerçek tesis / makine fotoğrafları gerekiyorsa**  
5. **Gerçek ekip / kurumsal fotoğraflar isteniyorsa**

## 12.6 Eksik asset prosedürü

Eksik kritik varlık varsa Claude Code şu dosyayı oluşturmalıdır:

`MISSING_ASSETS_REQUEST.md`

Bu dosyada şu format kullanılmalıdır:

```md
# Eksik Asset Talebi

Aşağıdaki varlıklar projede bulunamadı ve marka doğruluğu için kullanıcıdan istenmelidir:

1. OPTIYOU resmi logo (SVG/PNG)
2. Veri güdümlü anatomik tabanlık ürün render’ı
3. Sporcular için karbon fiber tabanlık ürün render’ı
4. OY Recovery sandalet görseli
5. DML / üretim laboratuvarı fotoğrafları
```

---

# 13. Component sistemi

Zorunlu componentler:

- `AppHeader`
- `MegaMenu`
- `PrimaryButton`
- `SecondaryButton`
- `HeroSection`
- `ProcessStepCard`
- `TechnologyCard`
- `SelectionWizard`
- `RecommendedProductCard`
- `TimelineStep`
- `TestimonialCard`
- `NewsletterForm`
- `AppFooter`

Ek componentler:

- `PageHero`
- `FeatureGrid`
- `StatsStrip`
- `ProjectCard`
- `CategoryCodeBlock`
- `AssetPlaceholder`

---

# 14. Responsive kurallar

## Desktop
- 12 kolon grid
- hero iki sütunlu
- teknoloji kartları 3 sütunlu
- süreç kartları tek satır

## Tablet
- 8 kolon
- hero 2 sütunlu kalabilir
- süreç kartları 2x2 olabilir
- selection modülü alt alta kırılabilir

## Mobil
- 4 kolon
- hamburger menü
- hero tek kolon
- Giriş Yap ve Taramanı Başlat görünürlüğünü koru
- süreç kartları dikey
- teknoloji kartları slider veya dikey stack
- footer accordion yapılabilir

---

# 15. SEO ve erişilebilirlik

## 15.1 SEO

Her sayfada:
- anlamlı page title
- meta description
- Open Graph başlık/açıklama
- semantic heading hiyerarşisi

## 15.2 Erişilebilirlik

- bütün buton ve input’larda görünür focus
- yeterli kontrast
- görseller için alt text
- klavye ile menü navigasyonu
- mobil dokunma alanı yeterli genişlikte

---

# 16. Test ve Definition of Done

Aşağıdaki kontroller tamamlanmadan proje bitmiş sayılmaz:

- `flutter analyze` hatasız veya kritik hatasız
- widget / smoke testler çalışıyor
- `flutter build web --release` başarılı
- 1440 px, 1024 px ve 390 px’te manuel kontrol yapıldı
- overflow yok
- hero fallback çalışıyor
- eksik asset akışları çalışıyor
- `IMPLEMENTATION_REPORT.md` yazıldı
- kritik eksikler varsa `MISSING_ASSETS_REQUEST.md` yazıldı

---

# 17. Claude Code’un teslim etmesi gereken dosyalar

Claude Code finalde aşağıdaki dosyaları üretmelidir:

1. Çalışan Flutter Web projesi  
2. `IMPLEMENTATION_REPORT.md`  
3. (gerekirse) `MISSING_ASSETS_REQUEST.md`  
4. Asset klasör yapısı  
5. Responsive ve düzenli component mimarisi

`IMPLEMENTATION_REPORT.md` içinde şunlar yazılmalıdır:

- kullanılan skill’ler
- route listesi
- kullanılan asset’ler ve kaynak yolları
- placeholder kullanılan alanlar
- kullanıcıdan istenecek eksik varlıklar
- analiz, test ve build sonuçları

---

# 18. Claude Code için master prompt

Aşağıdaki prompt, bu master dosya ile birlikte Claude Code’a verilebilir:

```text
Bu markdown dosyası, OPTIYOU’nun tek ana kaynak-of-truth web spesifikasyonudur. Bu dosyaya tam uy.

Görevin:
- OPTIYOU için Flutter Web tabanlı public siteyi sıfırdan planlamak, tasarlamak, kodlamak ve teslim etmek.
- Bu dosyada tanımlanan marka dili, menü mimarisi, landing page yapısı, ürün bölümleri, çözüm sayfaları, teknolojiler, TÜBİTAK proje sayfaları, anatomik kategoriler sayfası ve asset kurallarına eksiksiz uymak.
- Zorunlu skill’leri sırasıyla aktive et: frontend-design, ui-ux-pro-max, design-system, banner-design, impeccable.
- Önce asset envanteri çıkar. Bu dosyada belirtilen /mnt/data yollarını kontrol et.
- Bir asset mevcutsa uygun klasöre taşı ve kullan.
- Resmî logo veya kritik ürün görseli yoksa uydurma görsel üretme; MISSING_ASSETS_REQUEST.md dosyasına ekleyerek kullanıcıdan iste.
- Landing page, yüklenen örnek görsel mantığında olmalı. Üst menüde Giriş Yap ve Taramanı Başlat aksiyonları görünür olmalı.
- “Tabanlık Teknolojilerimiz” bölümünde şu üç kart mutlaka yer almalı:
  1) Veri Güdümlü Anatomik Tabanlık
  2) Sporcular İçin Karbon Fiber Tabanlık
  3) OY Recovery Anatomik Toparlayıcı Sandalet
- OY Recovery kartında “SLA 3B teknolojisiyle kafes yapılı tasarım” ifadesi bulunmalı.
- Public sitede kişiselleştirilmiş, ortez ve analiz kelimelerini kullanma. Bunların yerine bu dosyada verilen güvenli public karşılıkları kullan.
- Anatomik Kategorilerimiz sayfasında, numaranın tek başına yeterli olmadığını anlat. UN FIT ve kategori çalışmalarından türetilmiş kısa özetleri kullan, uzun telifli alıntı yapma.
- TÜBİTAK Projeleri sayfasında 1812 ve 1707 projelerini kartlar ve detail sayfalar ile sun.
- DML için ayrı açıklama bölümü oluştur.
- Site responsive, erişilebilir, premium ve üretilebilir olmalı.
- Geliştirme sonunda flutter analyze, testler ve flutter build web --release çalıştır.
- IMPLEMENTATION_REPORT.md oluştur.
- Eksik kritik görseller varsa MISSING_ASSETS_REQUEST.md oluştur.
```

---

# 19. Son not

Bu dosya, önceki üç markdown kaynağının ve son landing page yönünün birleşmiş ana sürümüdür.  
Bundan sonra Claude Code’a ayrı ayrı eski dosyaları vermek zorunlu değildir; ancak istenirse referans olarak workspace’te tutulabilir.

**Bu dosya önceliklidir.**
