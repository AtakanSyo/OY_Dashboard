# Supabase Bağlantısı — Gereklilikler ve Kurulum

Bu belge, OPTIYOU public sitesindeki **"Tarama Yap"** akışının (bireysel randevu +
kurumsal talep) çalışması için gereken Supabase parçalarını ve yapılması
gerekenleri anlatır.

> Site tarafındaki diğer her şey (statik sayfalar, `/iletisim` mailto formu,
> `/olcum-merkezleri` liste/harita alanı) Supabase **gerektirmez**. Yalnızca
> aşağıdaki iki form backend'e bağlıdır.

---

## 1. Özet — hangi özellikler Supabase'e bağlı

| Site özelliği | Route | Backend ihtiyacı |
|---|---|---|
| Bireysel tarama randevusu | `/tarama-randevusu` (Bireysel sekmesi) | `scan_appointment_requests` tablosu + `send-scan-appointment` function |
| Kurumsal tarama talebi | `/tarama-randevusu` (Kurumsal sekmesi) ve `/tarama-standi-basvuru` | `corporate_scan_requests` tablosu + `send-scan-appointment` function |

Akış: form gönderilince kayıt önce ilgili tabloya `INSERT` edilir, ardından
edge function iki e-posta gönderir:

1. **`info@optiyou.com.tr`** → talep detayı
2. **Talep sahibi** (form'daki e-posta) → KVKK aydınlatma özeti + randevu özeti

E-posta gönderimi kaydın kendisinden ayrıdır: kayıt başarılıysa form başarılı
sayılır, e-posta ayrıca denenip `email_dispatched` sütunu işaretlenir.

İlgili kod:
- İstemci servisi: [`lib/site/data/scan_appointment_service.dart`](../lib/site/data/scan_appointment_service.dart)
- Form sayfası: [`lib/site/pages/scan_appointment_page.dart`](../lib/site/pages/scan_appointment_page.dart)
- Migration: [`supabase/migrations/026_create_scan_appointment_requests.sql`](../supabase/migrations/026_create_scan_appointment_requests.sql)
- Edge function: [`supabase/functions/send-scan-appointment/index.ts`](../supabase/functions/send-scan-appointment/index.ts)

---

## 2. Proje bilgileri

| | |
|---|---|
| Proje ref | `iytzfqfhlqcboohtpugh` |
| API URL | `https://iytzfqfhlqcboohtpugh.supabase.co` |
| Dashboard | `https://supabase.com/dashboard/project/iytzfqfhlqcboohtpugh` |
| Anon key | [`lib/core/supabase_config.dart`](../lib/core/supabase_config.dart) içinde gömülü (public, güvenli) |

`supabase/.temp/linked-project.json` bu ref ile bağlı görünüyor ama `supabase`
CLI şu an bu makinede PATH'te **değil**.

---

## 3. Gerekli bileşenler ve durum

| # | Bileşen | Dosya / Yer | Amaç | Yapılacak | Durum |
|---|---|---|---|---|---|
| 1 | **Migration** | `supabase/migrations/026_create_scan_appointment_requests.sql` | `scan_appointment_requests` + `corporate_scan_requests` tabloları + RLS | `supabase db push` **ya da** Dashboard → SQL Editor'a dosya içeriğini yapıştır → Run | ⚠️ Deploy edilmedi |
| 2 | **Edge Function** | `supabase/functions/send-scan-appointment/index.ts` | Talep + KVKK e-postalarını Resend ile gönderir | `supabase functions deploy send-scan-appointment` **ya da** Dashboard → Edge Functions'tan oluştur | ⚠️ Deploy edilmedi |
| 3 | **Paylaşılan CORS** | `supabase/functions/_shared/cors.ts` | Function'ın CORS başlıkları | Yok — function deploy'u ile birlikte gider (Dashboard'dan yapıyorsan `_shared/cors.ts`'i de oluştur) | ✅ Repo'da var |
| 4 | **Secret `RESEND_API_KEY`** | Supabase proje secrets | Function'ın okuduğu Resend anahtarı | `supabase secrets list` ile kontrol et; yoksa `supabase secrets set RESEND_API_KEY=re_xxx` | 🔎 Muhtemelen tanımlı (mevcut `send-patient-consent-email` de kullanıyor) |
| 5 | **Resend gönderen domaini** | Resend paneli → Domains | `no-reply@optiyou.fit` doğrulanmış gönderen olmalı | Resend'de teyit et; değilse domain doğrula | 🔎 Muhtemelen doğrulanmış (mevcut KVKK e-postaları bu adresi kullanıyor) |
| 6 | **`is_optityou_team_member()` DB fonksiyonu** | `supabase/migrations/024_create_store_catalog.sql` | 026 RLS politikalarının bağımlılığı | Yok — 024 migration'ı zaten uygulanmışsa mevcut | ✅ 024 ile geliyor |
| 7 | **Supabase client init** | [`lib/main.dart`](../lib/main.dart) `Supabase.initialize(...)` | Formların kullandığı anon client | Yok | ✅ Hazır |
| 8 | **Alıcı adres** | `OPTIYOU_INBOX` sabiti — `send-scan-appointment/index.ts` | Taleplerin düştüğü kutu (`info@optiyou.com.tr`) | Değiştirmek istersen sabiti düzenle + yeniden deploy et | ✅ Kodda sabit |

---

## 4. Zaten hazır olanlar (aksiyon gerektirmez)

- `Supabase.initialize` `main.dart` içinde çağrılıyor; anon client her yerde
  `Supabase.instance.client` üzerinden erişilebilir.
- Migration ve function dosyaları repo'da yazılı ve derleniyor.
- `_shared/cors.ts` ve `is_optityou_team_member()` mevcut.
- Uygulama, backend eksikken **çökmez** (bkz. Bölüm 8).

---

## 5. Adım adım kurulum

### Yol A — Supabase CLI (önerilen)

```bash
# 1) CLI kur (bir kez):
#    Windows:  winget install Supabase.CLI
#    veya:     npm i -g supabase   ·   scoop install supabase

# 2) Giriş + projeye bağlan (bir kez)
supabase login
supabase link --project-ref iytzfqfhlqcboohtpugh

# 3) Tabloları oluştur
supabase db push
#    (026_create_scan_appointment_requests.sql uygulanır)

# 4) E-posta fonksiyonunu deploy et
supabase functions deploy send-scan-appointment

# 5) Secret kontrolü
supabase secrets list
#    RESEND_API_KEY listede görünmeli. Yoksa:
supabase secrets set RESEND_API_KEY=re_xxxxxxxx
```

### Yol B — Supabase Dashboard (CLI olmadan)

1. **Tablolar:** Dashboard → **SQL Editor** → New query →
   `supabase/migrations/026_create_scan_appointment_requests.sql` dosyasının
   **tüm içeriğini** yapıştır → **Run**.
   (Not: `is_optityou_team_member()` fonksiyonu yoksa önce `024_create_store_catalog.sql`
   içindeki `CREATE OR REPLACE FUNCTION public.is_optityou_team_member` bloğunu çalıştır.)
2. **Edge Function:** Dashboard → **Edge Functions** → **Deploy a new function** →
   ad: `send-scan-appointment` → `index.ts` içeriğini yapıştır.
   Dashboard editörü `../_shared/cors.ts` import'unu çözemezse:
   - ya `_shared/cors.ts`'i ayrı dosya olarak ekle,
   - ya da `import { corsHeaders } ...` satırını kaldırıp `corsHeaders`
     nesnesini `index.ts` başına satır içi yaz:
     ```ts
     const corsHeaders = {
       "Access-Control-Allow-Origin": "*",
       "Access-Control-Allow-Headers":
         "authorization, x-client-info, apikey, content-type",
     };
     ```
3. **Secret:** Dashboard → **Project Settings → Edge Functions → Secrets** →
   `RESEND_API_KEY` var mı bak; yoksa ekle.
4. **Resend:** [resend.com](https://resend.com) → **Domains** → `optiyou.fit`
   doğrulanmış mı bak (SPF/DKIM). Değilse domaini ekleyip DNS kayıtlarını gir.

---

## 6. Tablo şeması (referans)

### `public.scan_appointment_requests` — bireysel randevu

| Sütun | Tip | Not |
|---|---|---|
| `id` | `uuid` | PK, `gen_random_uuid()` |
| `full_name` | `text` | zorunlu |
| `phone` | `text` | zorunlu |
| `email` | `text` | zorunlu |
| `location` | `text` | `CHECK IN ('LLT','OPTIYOU','IZTU_DML')` |
| `appointment_date` | `date` | zorunlu |
| `appointment_time` | `text` | `"HH:mm"` (ör. `14:15`) |
| `note` | `text` | opsiyonel |
| `kvkk_consent` | `boolean` | INSERT için `TRUE` şart (RLS) |
| `email_dispatched` | `boolean` | function e-postayı yollayınca `TRUE` |
| `created_at` | `timestamptz` | `NOW()` |

### `public.corporate_scan_requests` — kurumsal talep

| Sütun | Tip | Not |
|---|---|---|
| `id` | `uuid` | PK |
| `company_name` | `text` | zorunlu |
| `contact_name` | `text` | zorunlu |
| `email` | `text` | zorunlu |
| `phone` | `text` | zorunlu |
| `person_count` | `integer` | `CHECK > 0` |
| `request_type` | `text` | `CHECK IN ('scanner_purchase','b2b_service')` |
| `note` | `text` | opsiyonel |
| `kvkk_consent` | `boolean` | INSERT için `TRUE` şart |
| `email_dispatched` | `boolean` | |
| `created_at` | `timestamptz` | |

> **Önemli:** `location` kısıtı `'LLT' / 'OPTIYOU' / 'IZTU_DML'` kodlarına
> bağlıdır. Ekranda görünen adlar ("LiveLifeTaller — Kartal" vb.) yalnızca
> etiket; kodları değiştirmek migration'ı ve edge function'ı da kırar.

---

## 7. RLS / güvenlik

Her iki tabloda da RLS **açık**:

- **INSERT** → `anon` + `authenticated`, yalnızca `kvkk_consent = TRUE` ile.
  (Giriş yapmamış ziyaretçi kayıt açabilir ama KVKK onayı olmadan olmaz.)
- **SELECT / UPDATE / DELETE** → yalnızca `authenticated` + `public.is_optityou_team_member()`.
  (Talepleri yalnızca OPTIYOU ekibi görür/yönetir; anon okuyamaz.)
- `service_role` (edge function'ın `email_dispatched` güncellemesi) RLS'i baypas eder.

Edge function **anon key** ile çağrılır (`Supabase.instance.client.functions.invoke`);
`RESEND_API_KEY` yalnızca function ortamında bulunur, istemciye sızmaz.

---

## 8. Deploy edilmeden önceki davranış (çökme yok)

| Durum | Kullanıcı ne görür |
|---|---|
| Tablo yok | Kırmızı "Talebiniz gönderilemedi. Lütfen bağlantınızı kontrol edip tekrar deneyin." uyarısı. Kayıt olmaz. |
| Tablo var, function yok / hata | Kayıt tutulur; yeşil başarı ekranı + "Bilgilendirme e-postası şu an gönderilemedi, ancak talebiniz kaydedildi." notu. |
| Her şey hazır | Yeşil başarı ekranı; `info@optiyou.com.tr` ve talep sahibi e-posta alır; `email_dispatched = true`. |

---

## 9. Doğrulama listesi (deploy sonrası)

- [ ] Dashboard → Table Editor'da `scan_appointment_requests` ve
      `corporate_scan_requests` görünüyor, RLS "Enabled".
- [ ] Dashboard → Edge Functions'ta `send-scan-appointment` "Deployed".
- [ ] `RESEND_API_KEY` secret tanımlı.
- [ ] Uygulamadan `/tarama-randevusu` → Bireysel form gönder → başarı ekranı.
- [ ] `info@optiyou.com.tr` gelen kutusunda "Yeni tarama randevusu" e-postası.
- [ ] Form'da girdiğin e-postada "Tarama randevunuz alındı" + KVKK özeti e-postası.
- [ ] Tabloda yeni satır, `email_dispatched = true`.
- [ ] `/tarama-randevusu` → Kurumsal form için aynısını tekrarla (`corporate_scan_requests`).
- [ ] Anon bir istemciden `SELECT * FROM scan_appointment_requests` **boş / yetkisiz** dönüyor.

---

## 10. Sık değiştirilen değerler

| Ne | Nerede | Deploy gereği |
|---|---|---|
| Alıcı gelen kutusu (`info@optiyou.com.tr`) | `OPTIYOU_INBOX` — `send-scan-appointment/index.ts` | function redeploy |
| Gönderen adresi (`no-reply@optiyou.fit`) | `FROM_ADDRESS` — aynı dosya | function redeploy + Resend'de domain doğrulama |
| Lokasyon etiketleri | `LOCATION_LABELS` — `send-scan-appointment/index.ts` **ve** `ScanLocation` enum — [`scan_appointment_service.dart`](../lib/site/data/scan_appointment_service.dart) | function redeploy + uygulama rebuild |
| Randevu saat aralığı (11:00–16:45, 15 dk) | `buildDailyScanSlots()` — `scan_appointment_service.dart` | uygulama rebuild |
| İletişim numaraları / adres | [`lib/site/content/site_contact.dart`](../lib/site/content/site_contact.dart) | uygulama rebuild |
| KVKK metni bağlantısı | `KVKK_URL` — `send-scan-appointment/index.ts` | function redeploy |

---

## 11. Sorun giderme

| Belirti | Olası neden | Çözüm |
|---|---|---|
| Form "gönderilemedi" (kırmızı) | Tablo yok ya da RLS INSERT politikası eksik | Migration'ı uygula; `kvkk_consent` kolonunun politikasını kontrol et |
| Kayıt oluyor, e-posta gelmiyor | Function deploy edilmemiş / `RESEND_API_KEY` yok / Resend domaini doğrulanmamış | Function loglarına bak (Dashboard → Edge Functions → Logs); secret ve domaini teyit et |
| Function log: `RESEND_API_KEY tanımlı değil` | Secret eksik | `supabase secrets set RESEND_API_KEY=...` |
| Resend 403 / "domain not verified" | `optiyou.fit` Resend'de doğrulanmamış | Resend → Domains → DNS kayıtlarını ekle |
| `location` INSERT hatası (`check constraint`) | Enum kodu ile DB kısıtı uyuşmuyor | Kod her iki tarafta da `LLT / OPTIYOU / IZTU_DML` olmalı |
| Web'de CORS hatası | Function `_shared/cors.ts` olmadan deploy edildi | CORS başlıklarını function'a ekleyip redeploy et |

---

## 12. Yerel geliştirme (opsiyonel)

```bash
supabase start                         # yerel Postgres + Studio
supabase functions serve send-scan-appointment --env-file supabase/functions/.env
# .env içine: RESEND_API_KEY=re_xxx
```

Yerelde `SupabaseConfig.url` / `anonKey` değerlerini `supabase start` çıktısındaki
yerel değerlerle geçici olarak değiştirmen gerekir (commit etme).
