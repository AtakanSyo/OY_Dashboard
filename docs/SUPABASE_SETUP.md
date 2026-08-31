# Supabase — Tarama Talebi Kurulum ve Yayın Rehberi

Bu belge, public sitedeki bireysel randevu ve kurumsal tarama formlarının
güvenli kurulumunu anlatır. Kaynak kodu ve migration geçmişi bu rehberin
önündedir; Dashboard'da elle yapılan değişiklikler repoya migration olarak
geri alınmalıdır.

## 1. Akış

İki form da `send-scan-appointment` Edge Function'ını çağırır:

1. Function, Supabase `apikey` başlığını ve ardından alanları/istek kimliğini
   doğrular.
2. Ham IP saklamadan, gizli bir tuzla üretilmiş kaynak özeti üzerinden hız
   sınırı uygular.
3. Kaydı servis yetkisiyle ilgili tabloya ekler.
4. `info@optiyou.com.tr` ve form sahibine Resend üzerinden e-posta gönderir.
5. Kaydı `pending`, `sent` veya `failed` e-posta durumuyla günceller.

Public istemci tablolara doğrudan `INSERT`, `SELECT`, `UPDATE` veya `DELETE`
yapmaz. Aynı `client_request_id` ile yinelenen çağrılar yeni kayıt/e-posta
oluşturmaz.

| Form | Route | Tablo |
|---|---|---|
| Bireysel | `/tarama-randevusu` | `scan_appointment_requests` |
| Kurumsal | `/tarama-randevusu`, `/tarama-standi-basvuru` | `corporate_scan_requests` |

## 2. Repo bileşenleri

| Bileşen | Yol |
|---|---|
| İstemci servisi | `lib/site/data/scan_appointment_service.dart` |
| Form sayfası | `lib/site/pages/scan_appointment_page.dart` |
| İlk tablo migration'ı | `supabase/migrations/026_create_scan_appointment_requests.sql` |
| Güvenlik migration'ı | `supabase/migrations/027_harden_scan_appointment_requests.sql` |
| Edge Function | `supabase/functions/send-scan-appointment/index.ts` |
| RLS/grant testleri | `supabase/tests/027_scan_appointment_rls.test.sql` |
| Function ayarı | `supabase/config.toml` |

`027` migration'ı anonim tablo erişimini kapatır, tekil istek kimliği ve
e-posta durum alanlarını ekler. Yeni veya mevcut bir ortamda `026` ve `027`
birlikte uygulanmalıdır.

Function ayarında platformun eski `verify_jwt` kontrolü kapalıdır; çünkü bu
kontrol yeni `sb_publishable_...` anahtarlarını kabul etmez. Function bunun
yerine `apikey` başlığını ortamın `SUPABASE_PUBLISHABLE_KEYS` listesiyle veya
eski `SUPABASE_ANON_KEY` değeriyle doğrular. Böylece hem yeni hem eski public
anahtarlar desteklenir.

## 3. Ortamlar

Üretim proje ref'i: `iytzfqfhlqcboohtpugh`.

Önce ayrı bir staging Supabase projesi kullanılmalıdır. Repo artık
`supabase/.temp` klasörünü takip etmez; her geliştirici doğru projeye kendi
makinesinde açıkça link vermelidir.

Uygulama varsayılan olarak üretim URL ve public anon anahtarını kullanır.
Staging/yerel derleme için kaynak kodu değiştirmeden:

```powershell
flutter run -d chrome `
  --dart-define=SUPABASE_URL=https://STAGING_REF.supabase.co `
  --dart-define=SUPABASE_ANON_KEY=STAGING_PUBLIC_KEY
```

Secret/service anahtarları hiçbir zaman `--dart-define`, istemci kodu veya
Git içine konmaz.

## 4. Zorunlu Function secret'ları

| Secret | Amaç |
|---|---|
| `RESEND_API_KEY` | E-posta gönderimi |
| `SCAN_RATE_LIMIT_SALT` | Kaynak adresi geri döndürülemeyen özetle saklamak; en az 32 rastgele karakter |

Opsiyonel:

| Secret | Varsayılan |
|---|---|
| `OPTIYOU_INBOX` | `info@optiyou.com.tr` |
| `SCAN_FROM_ADDRESS` | `Optiyou <no-reply@optiyou.fit>` |

Hosted Edge Functions, Supabase sunucu anahtarlarını ortam değişkeni olarak
sağlar. Function yeni `SUPABASE_SECRET_KEYS` biçimini, yoksa eski
`SUPABASE_SERVICE_ROLE_KEY` değerini kullanır. Bu anahtarlar tarayıcıya
gönderilmez.

Resend tarafında `no-reply@optiyou.fit` gönderen domaininin SPF/DKIM ile
doğrulanmış olması gerekir.

## 5. Staging kurulumu

Supabase CLI bu makinede kurulu değilse önce resmî yöntemlerden biriyle kurun.
Ardından repo kökünde:

```powershell
supabase login
supabase link --project-ref STAGING_PROJECT_REF

# Yerel migration'larla uzak geçmişi karşılaştır.
supabase migration list --linked

# Uygulanacak migration'ları değiştirmeden göster.
supabase db push --dry-run --linked

# Çıktı yalnızca beklenen migration'ları içeriyorsa uygula.
supabase db push --linked

supabase secrets set `
  RESEND_API_KEY=REDACTED `
  SCAN_RATE_LIMIT_SALT=EN_AZ_32_RASTGELE_KARAKTER

supabase functions deploy send-scan-appointment
```

Remote migration geçmişi repo ile uyuşmuyorsa `db push` yapmayın. Önce
`supabase db pull` ile drift'i inceleyin veya doğru migration geçmişini ekipçe
netleştirin. Üretimde `db reset --linked` kullanılmaz.

## 6. Yerel DB ve RLS testleri

Docker uyumlu çalışma zamanı ve Supabase CLI ile:

```powershell
supabase start
supabase db reset
supabase test db
```

Testlerde en az şu matris doğrulanmalıdır:

| Rol | INSERT | SELECT | UPDATE | DELETE |
|---|---:|---:|---:|---:|
| `anon` | Engelli | Engelli | Engelli | Engelli |
| OPTIYOU ekip üyesi | İzinli | İzinli | İzinli | İzinli |
| `service_role` / secret key | İzinli | İzinli | İzinli | İzinli |

## 7. Staging uçtan uca doğrulama

- [ ] `026` ve `027` migration geçmişinde uygulanmış.
- [ ] İki tablo mevcut ve RLS açık.
- [ ] `send-scan-appointment` deployed.
- [ ] `RESEND_API_KEY` ve `SCAN_RATE_LIMIT_SALT` tanımlı.
- [ ] Resend gönderen domaini doğrulanmış.
- [ ] Bireysel form bir kayıt oluşturuyor.
- [ ] Kurumsal form bir kayıt oluşturuyor.
- [ ] Her form için ekip ve başvuru sahibi e-postası ulaşıyor.
- [ ] Başarılı kayıtta `email_status = 'sent'` ve
      `email_dispatched = true`.
- [ ] Resend hatasında kayıt korunuyor ve `email_status = 'failed'`.
- [ ] Aynı istek kimliğiyle tekrar gönderim ikinci satır/e-posta oluşturmuyor.
- [ ] Aynı kaynaktan art arda aşırı gönderim HTTP 429 ile engelleniyor.
- [ ] Anon REST istemcisi tablolara doğrudan erişemiyor.
- [ ] Eksik veya geçersiz `apikey` ile Function çağrısı HTTP 401 dönüyor.
- [ ] Function cevabı iç hata/secrets/kişisel veri sızdırmıyor.

## 8. Üretim yayın sırası

1. Üretim DB yedeğinin güncel olduğunu doğrulayın.
2. Doğru proje ref'ine link verildiğini iki kişiyle kontrol edin.
3. `migration list --linked` ve `db push --dry-run --linked` çıktısını saklayın.
4. Migration'ları uygulayın.
5. Secret'ları kontrol edin ve Function'ı deploy edin.
6. Test adresleriyle iki formun smoke testini yapın.
7. Function/Resend loglarını ve tablo durumlarını kontrol edin.
8. Backend doğrulandıktan sonra web uygulamasını yayınlayın.

## 9. Geri dönüş

- Web: bir önceki doğrulanmış `build/web` çıktısını yeniden yayınlayın.
- Function: bir önceki Git commit'indeki Function sürümünü yeniden deploy edin.
- DB: hata halinde tabloları veya talepleri silmeyin. Önce public Function'ı
  devre dışı bırakın; gerekiyorsa yeni bir ileri-düzeltme migration'ı yazın.
- Secret sızıntısı şüphesinde ilgili secret/anahtarı döndürün ve logları
  inceleyin.

## 10. CAPTCHA notu

Sunucu tarafında kaynak ve hedef e-posta bazlı hız sınırı aktiftir. Cloudflare
Turnstile eklenmesi ikinci bir savunma katmanı sağlar; ancak yalnızca istemci
widget'ı yeterli değildir. Site key istemcide, secret yalnızca Function
ortamında tutulmalı ve token her istekte Function tarafından Siteverify API ile
doğrulanmalıdır. Turnstile anahtarları oluşturulmadan yarım entegrasyon deploy
edilmemelidir.
