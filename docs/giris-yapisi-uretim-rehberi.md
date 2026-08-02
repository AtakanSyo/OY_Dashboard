# Giriş (Auth) Yapısı — Üretim Rehberi

Bu doküman, OY Dashboard (`oy_site`) projesindeki giriş yapısının **sıfırdan aynı şekilde nasıl üretileceğini** anlatır. Flutter (web + masaüstü) istemci + Supabase Auth/Postgres arka uç mimarisini, ekran ekran widget yapısını, veritabanı şemasını ve akışları içerir.

Referans kaynak dosyalar:

| Katman | Dosya |
| --- | --- |
| Uygulama girişi / routing | [lib/main.dart](../lib/main.dart) |
| Supabase bağlantı ayarı | [lib/core/supabase_config.dart](../lib/core/supabase_config.dart) |
| Auth servisi | [lib/services/auth_service.dart](../lib/services/auth_service.dart) |
| Kullanıcı modeli | [lib/models/app_user.dart](../lib/models/app_user.dart) |
| Giriş ekranı | [lib/screens/auth/login_screen.dart](../lib/screens/auth/login_screen.dart) |
| Kayıt ekranı | [lib/screens/auth/register_screen.dart](../lib/screens/auth/register_screen.dart) |
| Şifremi unuttum | [lib/screens/auth/forgot_password_screen.dart](../lib/screens/auth/forgot_password_screen.dart) |
| Yeni şifre belirle | [lib/screens/auth/reset_password_screen.dart](../lib/screens/auth/reset_password_screen.dart) |
| Veritabanı şeması | [supabase/schema.sql](../supabase/schema.sql) |

---

## 1. Mimari Özeti

Üç katmanlı, ince bir yapıdır. Ekranlar doğrudan `AuthService`'i çağırır; state yönetimi için ek bir kütüphane (bloc/riverpod) **kullanılmaz**, saf `StatefulWidget` + `setState` vardır.

```
┌──────────────────────────────────────────────────────────┐
│  UI Katmanı  (screens/auth/*.dart)                       │
│  LoginScreen · RegisterScreen · ForgotPasswordScreen     │
│  ResetPasswordScreen · LegalConsentScreen                │
│  → StatefulWidget + setState, controller'lar, hata metni │
└───────────────────────┬──────────────────────────────────┘
                        │ signIn / signUp / reset / update
┌───────────────────────▼──────────────────────────────────┐
│  Servis Katmanı  (services/auth_service.dart)            │
│  · Supabase Auth çağrıları                               │
│  · user_profiles_full view'undan profil çekme            │
│  · Rol bazlı onay (approval) kontrolü                    │
│  · AppUser'a dönüştürme                                  │
└───────────────────────┬──────────────────────────────────┘
                        │ supabase_flutter (REST + GoTrue)
┌───────────────────────▼──────────────────────────────────┐
│  Supabase                                                │
│  auth.users  →  trigger  →  public.user_profiles         │
│  roles · clinics · user_profiles_full (VIEW) · RLS       │
└──────────────────────────────────────────────────────────┘
```

Temel tasarım kararları:

1. **Kimlik doğrulama Supabase Auth'ta, profil bilgisi kendi tablomuzda.** `auth.users` sadece e-posta/şifre/metadata tutar; ad, soyad, rol, klinik `public.user_profiles` tablosundadır.
2. **Okuma tek bir view üzerinden yapılır.** `user_profiles_full` view'u, `AppUser.fromMap()` alan adlarıyla birebir eşleşir. İstemci join yapmaz.
3. **Rol bazlı manuel onay.** `EXPERT` ve `OPTIYOU_TEAM` rolleri, giriş yapabilmek için ekip onayı bekler; `CUSTOMER` ve `CORPORATE` doğrudan girer.
4. **Şifre sıfırlama, URL fragment üzerinden.** Flutter Web'de Supabase maili `#/reset-password` adresine döner ve `onAuthStateChange` üzerinden ekran açılır.

---

## 2. Ön Koşullar

- Flutter SDK `^3.9.2`
- Bir Supabase projesi (ücretsiz plan yeterli)
- `pubspec.yaml` içinde tek zorunlu bağımlılık:

```yaml
dependencies:
  supabase_flutter: ^2.9.0
```

---

## 3. Adım 1 — Supabase Bağlantısı

### 3.1 Config sınıfı

`lib/core/supabase_config.dart`:

```dart
class SupabaseConfig {
  static const String url = 'https://<proje-ref>.supabase.co';

  // Public anon key — istemciye gömülmesi güvenlidir.
  // service_role anahtarı ASLA buraya yazılmaz.
  static const String anonKey = 'eyJhbGciOi...';
}
```

> **Not:** `anon` anahtarı istemcide açık durur; güvenlik RLS politikalarıyla sağlanır. Bu yüzden 5. adımdaki RLS kuralları opsiyonel değildir.

### 3.2 Uygulama başlatma

`main()` içinde, `runApp`'ten önce Supabase başlatılır:

```dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: SupabaseConfig.url,
    anonKey: SupabaseConfig.anonKey,
  );

  runApp(const OYDashboardApp());
}
```

---

## 4. Adım 2 — Veritabanı Şeması

Aşağıdaki SQL, Supabase SQL Editor'de sırayla çalıştırılır (tamamı [supabase/schema.sql](../supabase/schema.sql) içindedir).

### 4.1 Roller

```sql
CREATE TABLE public.roles (
  id         BIGSERIAL PRIMARY KEY,
  role_code  TEXT UNIQUE NOT NULL,
  role_name  TEXT        NOT NULL,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

INSERT INTO public.roles (role_code, role_name) VALUES
  ('EXPERT',       'Uzman'),
  ('CUSTOMER',     'Müşteri'),
  ('CORPORATE',    'Kurumsal'),
  ('OPTIYOU_TEAM', 'OptiYou Ekibi');
```

`role_code` değerleri, Dart tarafındaki `RoleCodes` sabitleriyle **büyük harf duyarlı** olarak birebir aynı olmalıdır. Eşleşmezse `handle_new_user` trigger'ı `role_id`'yi NULL bırakır ve kullanıcı rolsüz kalır.

### 4.2 Klinikler ve kullanıcı profilleri

```sql
CREATE TABLE public.clinics (
  id          BIGSERIAL PRIMARY KEY,
  clinic_code TEXT UNIQUE NOT NULL,
  clinic_name TEXT        NOT NULL,
  clinic_type TEXT,
  created_at  TIMESTAMPTZ DEFAULT NOW(),
  updated_at  TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE public.user_profiles (
  id                      BIGSERIAL PRIMARY KEY,
  auth_id                 UUID UNIQUE NOT NULL
                            REFERENCES auth.users(id) ON DELETE CASCADE,
  role_id                 BIGINT REFERENCES public.roles(id),
  clinic_id               BIGINT REFERENCES public.clinics(id),
  first_name              TEXT NOT NULL,
  last_name               TEXT NOT NULL,
  username                TEXT UNIQUE,
  phone                   TEXT,
  title                   TEXT,
  commission_profile_name TEXT,
  is_active               BOOLEAN     DEFAULT TRUE,
  approval_status         TEXT        DEFAULT 'approved',  -- pending | approved | rejected | suspended
  is_approved             BOOLEAN     DEFAULT TRUE,
  last_login_at           TIMESTAMPTZ,
  created_at              TIMESTAMPTZ DEFAULT NOW(),
  updated_at              TIMESTAMPTZ DEFAULT NOW()
);
```

> **Dikkat:** Depodaki `schema.sql` dosyasında `approval_status` ve `is_approved` kolonları **yoktur**; onay özelliği sonradan Supabase panelinden eklenmiştir. Aynı yapıyı sıfırdan kurarken bu iki kolonu yukarıdaki gibi baştan ekleyin, yoksa `AuthService.signIn` view'dan bu alanları okuyamaz. Mevcut bir kuruluma eklemek için:
>
> ```sql
> ALTER TABLE public.user_profiles
>   ADD COLUMN IF NOT EXISTS approval_status TEXT DEFAULT 'approved',
>   ADD COLUMN IF NOT EXISTS is_approved     BOOLEAN DEFAULT TRUE;
> ```

### 4.3 `user_profiles_full` view'u

İstemcinin okuduğu tek kaynak. Kolon adları `AppUser.fromMap()` ile birebir eşleşir:

```sql
CREATE OR REPLACE VIEW public.user_profiles_full AS
SELECT
  up.id AS user_id,
  up.role_id,
  up.clinic_id,
  up.first_name,
  up.last_name,
  au.email,
  up.username,
  up.phone,
  up.title,
  up.commission_profile_name,
  r.role_code,
  r.role_name,
  c.clinic_code,
  c.clinic_name,
  c.clinic_type,
  up.is_active,
  up.approval_status,
  up.is_approved,
  up.last_login_at,
  up.created_at,
  up.updated_at,
  up.auth_id            -- AuthService bu alanla filtreler
FROM public.user_profiles up
JOIN      auth.users     au ON au.id = up.auth_id
LEFT JOIN public.roles   r  ON r.id  = up.role_id
LEFT JOIN public.clinics c  ON c.id  = up.clinic_id;
```

View'a yeni alan eklerken kural: **önce SQL kolonu, sonra `AppUser` alanı + `fromMap`/`toMap` satırı.** İkisi ayrışırsa alan sessizce `null` döner.

### 4.4 RLS politikaları

```sql
ALTER TABLE public.user_profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.roles         ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.clinics       ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can read own profile"
  ON public.user_profiles FOR SELECT
  USING (auth.uid() = auth_id);

CREATE POLICY "Users can update own profile"
  ON public.user_profiles FOR UPDATE
  USING (auth.uid() = auth_id);

CREATE POLICY "Authenticated users can read roles"
  ON public.roles FOR SELECT TO authenticated USING (true);

CREATE POLICY "Authenticated users can read clinics"
  ON public.clinics FOR SELECT TO authenticated USING (true);
```

View'lar varsayılan olarak sahibinin yetkisiyle çalışır; kullanıcının yalnızca kendi satırını görmesi için view'u `security_invoker` ile tanımlamak gerekir:

```sql
ALTER VIEW public.user_profiles_full SET (security_invoker = on);
```

### 4.5 Kayıt trigger'ı

`auth.users`'a satır eklendiğinde profil otomatik oluşur. Rol, kayıt sırasında gönderilen metadata'dan okunur:

```sql
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  INSERT INTO public.user_profiles (
    auth_id, first_name, last_name, role_id, approval_status, is_approved
  ) VALUES (
    NEW.id,
    COALESCE(NEW.raw_user_meta_data->>'first_name', 'Yeni'),
    COALESCE(NEW.raw_user_meta_data->>'last_name',  'Kullanıcı'),
    (
      SELECT id FROM public.roles
      WHERE role_code = COALESCE(
        NULLIF(TRIM(NEW.raw_user_meta_data->>'role_code'), ''), 'CUSTOMER'
      )
      LIMIT 1
    ),
    COALESCE(NEW.raw_user_meta_data->>'approval_status', 'approved'),
    COALESCE((NEW.raw_user_meta_data->>'is_approved')::BOOLEAN, TRUE)
  );
  RETURN NEW;
END;
$$;

CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();
```

`updated_at` için ayrıca bir `set_updated_at()` fonksiyonu ve `BEFORE UPDATE` trigger'ları tanımlanır (bkz. schema.sql bölüm 7).

---

## 5. Adım 3 — Kullanıcı Modeli

`lib/models/app_user.dart` iki parçadan oluşur:

```dart
class RoleCodes {
  static const String expert      = 'EXPERT';
  static const String customer    = 'CUSTOMER';
  static const String corporate   = 'CORPORATE';
  static const String optiYouTeam = 'OPTIYOU_TEAM';

  static const List<String> values = [expert, customer, corporate, optiYouTeam];
}

class AppUser {
  final int? userId;
  final String firstName, lastName, email, roleCode, roleName;
  final String? username, phone, title, clinicCode, clinicName, clinicType;
  final bool isActive;
  // ...

  String get fullName => "$firstName $lastName";
  String get displayName => (title ?? '').trim().isNotEmpty
      ? "${title!.trim()} $firstName $lastName"
      : fullName;

  bool get isExpert      => roleCode == RoleCodes.expert;
  bool get isCustomer    => roleCode == RoleCodes.customer;
  bool get isCorporate   => roleCode == RoleCodes.corporate;
  bool get isOptiYouTeam => roleCode == RoleCodes.optiYouTeam;

  factory AppUser.fromMap(Map<String, dynamic> map) { /* snake_case → alan */ }
  Map<String, dynamic> toMap() { /* alan → snake_case */ }
  AppUser copyWith({...});
}
```

Rol kontrolü uygulamanın her yerinde `user.isExpert` gibi getter'larla yapılır; string karşılaştırması ekranlara dağıtılmaz.

---

## 6. Adım 4 — AuthService

Tüm auth işlemleri tek sınıfta toplanır. `Supabase.instance.client` her çağrıda getter üzerinden alınır, cache'lenmez.

### 6.1 Giriş + onay kontrolü

```dart
class AccountApprovalException implements Exception {
  final String status;
  final String message;
  const AccountApprovalException({required this.status, required this.message});
}

class AuthService {
  SupabaseClient get _client => Supabase.instance.client;

  bool _requiresManualApproval(String roleCode) =>
      roleCode == RoleCodes.expert || roleCode == RoleCodes.optiYouTeam;

  Future<AppUser> signIn({required String email, required String password}) async {
    final response = await _client.auth.signInWithPassword(
      email: email, password: password,
    );

    final authUser = response.user;
    if (authUser == null) throw const AuthException('Giriş başarısız.');

    // 2. adım: profil view'undan zenginleştirme
    final raw = await _client
        .from('user_profiles_full')
        .select()
        .eq('auth_id', authUser.id)
        .single();

    final profileData = Map<String, dynamic>.from(raw as Map);

    final roleCode       = (profileData['role_code'] ?? '').toString();
    final approvalStatus = (profileData['approval_status'] ?? 'approved').toString();
    final isApproved     = profileData['is_approved'] as bool? ?? true;

    // 3. adım: onay gerektiren roller için kapı
    if (_requiresManualApproval(roleCode)) {
      if (approvalStatus != 'approved' || isApproved != true) {
        await _client.auth.signOut();          // oturumu bırakma!
        throw AccountApprovalException(
          status: approvalStatus,
          message: _approvalMessage(approvalStatus),
        );
      }
    }

    return AppUser.fromMap(profileData);
  }
}
```

Kritik davranış: onay yoksa **önce `signOut()` çağrılır**, sonra exception atılır. Aksi hâlde kullanıcı geçerli bir oturumla ortada kalır ve RLS'nin izin verdiği verilere erişebilir.

Onay durumu → mesaj eşlemesi:

| `approval_status` | Kullanıcıya gösterilen mesaj |
| --- | --- |
| `pending` | Hesabınız onay bekliyor. Optiyou ekibi hesabınızı onayladıktan sonra giriş yapabilirsiniz. |
| `rejected` | Kayıt başvurunuz onaylanmadı. Lütfen Optiyou ekibiyle iletişime geçin. |
| `suspended` | Hesabınız askıya alınmıştır. Lütfen Optiyou ekibiyle iletişime geçin. |
| diğer | Hesabınız henüz giriş için onaylanmamış. |

### 6.2 Kayıt

Profil alanları `data` (user metadata) ile gönderilir; trigger bunları okuyup `user_profiles` satırını üretir:

```dart
Future<String> signUp({
  required String email,
  required String password,
  required String firstName,
  required String lastName,
  required String roleCode,
}) async {
  final requiresApproval = _requiresManualApproval(roleCode);

  final response = await _client.auth.signUp(
    email: email,
    password: password,
    data: {
      'first_name': firstName,
      'last_name': lastName,
      'role_code': roleCode,
      'approval_status': requiresApproval ? 'pending' : 'approved',
      'is_approved': !requiresApproval,
    },
  );

  final authUser = response.user;
  if (authUser == null) throw const AuthException('Kayıt başarısız.');

  return authUser.id;   // davet akışında hastaya bağlamak için gerekir
}
```

### 6.3 Şifre işlemleri ve oturum

```dart
Future<void> signOut() => _client.auth.signOut();

User? get currentAuthUser => _client.auth.currentUser;
Stream<AuthState> get onAuthStateChange => _client.auth.onAuthStateChange;

Future<void> sendPasswordResetEmail({required String email, String? redirectTo}) =>
    _client.auth.resetPasswordForEmail(email, redirectTo: redirectTo);

Future<void> updatePassword({required String newPassword}) =>
    _client.auth.updateUser(UserAttributes(password: newPassword));
```

---

## 7. Adım 5 — Giriş Ekranı (LoginScreen)

### 7.1 State yapısı

```dart
class LoginScreen extends StatefulWidget {
  final dynamic pressureRepository;    // dashboard'a taşınan bağımlılık
  const LoginScreen({super.key, required this.pressureRepository});
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _emailController    = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final AuthService _authService = AuthService();

  String? _errorMessage;         // tek hata alanı — şifre kutusunda gösterilir
  bool _isLoading      = false;  // tüm etkileşimleri kilitler
  bool _obscurePassword = true;
}
```

Üç state alanı bütün ekranı yönetir. `dispose()` içinde her iki controller da temizlenir.

### 7.2 Widget ağacı

```
Scaffold
└── Center
    └── Container(width: 380, padding: 24)
        └── Column(mainAxisSize: min)
            ├── Text('Giriş Yap')            fontSize 26, bold
            ├── SizedBox(24)
            ├── TextField  e-posta           OutlineInputBorder r=12
            ├── SizedBox(16)
            ├── TextField  şifre             obscure + göz ikonu + errorText
            ├── SizedBox(8)
            ├── Align(right) TextButton      'Şifremi unuttum'
            ├── SizedBox(16)
            ├── ElevatedButton (full width)  'Giriş Yap' / spinner
            ├── SizedBox(16)
            ├── TextButton                   'Hesabın yok mu? Kayıt Ol'
            └── TextButton.icon              'Ana Sayfa' (geri oku)
```

Görsel sabitler: sabit `380 px` kart genişliği, `24 px` iç boşluk, `12 px` köşe yarıçapı, birincil renk `Colors.teal`, buton dikey padding `14`.

### 7.3 Davranış kuralları

1. **Hata gösterimi tek noktada.** `_errorMessage`, şifre alanının `errorText`'ine bağlıdır; ayrı bir hata satırı yoktur. E-posta veya şifre değiştiğinde `onChanged` içinde hata temizlenir.
2. **Enter ile giriş.** Şifre alanının `onSubmitted`'ı `_login()`'i tetikler (yükleme sırasında değil).
3. **Yükleme kilidi.** `_isLoading` iken tüm `TextField`'lar `enabled: false`, tüm butonların `onPressed`'i `null`; giriş butonu 20×20 beyaz `CircularProgressIndicator`'a döner.
4. **Şifre görünürlüğü.** `suffixIcon` olarak `IconButton` ile `visibility` / `visibility_off` arasında geçiş.
5. **`mounted` kontrolü.** Her `await` sonrası `if (!mounted) return;` — ekran kapanmışsa `setState` çağrılmaz.

### 7.4 Giriş akışı

```dart
Future<void> _login() async {
  final email = _emailController.text.trim();
  final password = _passwordController.text;

  if (email.isEmpty)    { setState(() => _errorMessage = 'Lütfen e-posta girin.'); return; }
  if (password.isEmpty) { setState(() => _errorMessage = 'Lütfen şifrenizi girin.'); return; }

  setState(() { _isLoading = true; _errorMessage = null; });

  try {
    final appUser = await _authService.signIn(email: email, password: password);
    if (!mounted) return;

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => DashboardScreen(
          currentUser: appUser,
          pressureRepository: widget.pressureRepository,
        ),
      ),
    );
  } on AccountApprovalException catch (e) {          // onay bekliyor / reddedildi
    if (!mounted) return;
    setState(() => _errorMessage = e.message);
  } on AuthException catch (e) {                     // Supabase auth hatası
    if (!mounted) return;
    setState(() => _errorMessage = _localizeAuthError(e.message));
  } catch (_) {                                      // ağ / beklenmeyen
    if (!mounted) return;
    setState(() => _errorMessage = 'Bir hata oluştu. Lütfen tekrar deneyin.');
  } finally {
    if (mounted) setState(() => _isLoading = false);
  }
}
```

Sıralama önemlidir: `AccountApprovalException` **önce** yakalanır; sonra `AuthException`; en sonda genel `catch`.

Başarılı girişte `pushReplacement` kullanılır — kullanıcı geri tuşuyla giriş ekranına dönemez.

### 7.5 Hata metinlerinin Türkçeleştirilmesi

Supabase İngilizce mesaj döndürür; her ekranda küçük bir `_localizeAuthError` yardımcısı vardır:

```dart
String _localizeAuthError(String message) {
  final lower = message.toLowerCase();
  if (lower.contains('invalid login') || lower.contains('invalid credentials')) {
    return 'E-posta veya şifre hatalı.';
  }
  if (lower.contains('email not confirmed')) return 'E-posta adresiniz doğrulanmamış.';
  if (lower.contains('too many requests')) {
    return 'Çok fazla deneme yaptınız. Lütfen bekleyin.';
  }
  return message;   // tanınmayan hata olduğu gibi gösterilir
}
```

| Ekran | Ele alınan hatalar |
| --- | --- |
| Login | invalid login/credentials, email not confirmed, too many requests |
| Register | already registered, invalid email, password should be |
| Forgot password | rate limit / too many requests, invalid email |
| Reset password | session / jwt (süresi dolmuş bağlantı), password (zayıf şifre) |

---

## 8. Adım 6 — Yönlendirme (Routing)

Uygulama `MaterialApp` + `onGenerateRoute` kullanır; named route tablosu yoktur. Giriş ekranı `MaterialPageRoute` ile açılır.

### 8.1 Tema

```dart
MaterialApp(
  navigatorKey: _navigatorKey,
  title: 'OY Dashboard',
  debugShowCheckedModeBanner: false,
  theme: ThemeData(
    colorScheme: ColorScheme.fromSeed(seedColor: Colors.teal),
    useMaterial3: true,
  ),
  home: ...,
  onGenerateRoute: ...,
)
```

### 8.2 URL tabanlı ilk ekran seçimi (Flutter Web)

`build()` içinde `Uri.base` hem path hem de fragment (`#/...`) olarak ayrıştırılır ve `home` buna göre seçilir:

| URL | Açılan ekran |
| --- | --- |
| `/payment-result?status=...` | `PaymentResultScreen` |
| `/reset-password` veya `#/reset-password` | `ResetPasswordScreen` |
| `/register?invite=<token>` | `RegisterScreen(inviteToken: ...)` |
| `/legal-consent?token=<token>` | `LegalConsentScreen` |
| diğer | `HomeScreen` |

Her token çıkarıcı aynı deseni izler: önce doğrudan path denenir, sonra fragment `/` ile normalize edilip `Uri.tryParse` ile ikinci kez denenir. Bu, hem path-based hem hash-based web yönlendirmesinde çalışmayı sağlar.

```dart
String? _extractInviteTokenFromUrl() {
  final directUri = Uri.base;
  if (directUri.path == '/register') {
    final token = directUri.queryParameters['invite'];
    if (token != null && token.trim().isNotEmpty) return token.trim();
  }

  final fragment = Uri.base.fragment;
  if (fragment.isEmpty) return null;

  final normalized = fragment.startsWith('/') ? fragment : '/$fragment';
  final fragmentUri = Uri.tryParse(normalized);
  if (fragmentUri == null || fragmentUri.path != '/register') return null;

  final token = fragmentUri.queryParameters['invite'];
  return (token == null || token.trim().isEmpty) ? null : token.trim();
}
```

`onGenerateRoute` aynı yolları çalışma zamanı navigasyonu için tekrar tanır; eşleşmeyen her route **LoginScreen**'e düşer (varsayılan davranış).

### 8.3 Şifre kurtarma dinleyicisi

Kök widget, `initState` içinde auth olaylarını dinler ve `passwordRecovery` olayında yeni şifre ekranını açar:

```dart
_authSubscription = Supabase.instance.client.auth.onAuthStateChange.listen((data) {
  if (data.event == AuthChangeEvent.passwordRecovery) {
    _openResetPasswordScreen();
  }
});
```

Ekranın iki kez açılmasını `_isResetPasswordScreenOpen` bayrağı engeller; push işlemi `addPostFrameCallback` içinde yapılır (navigator henüz hazır olmayabilir) ve `whenComplete` ile bayrak sıfırlanır. `dispose()` içinde abonelik iptal edilir.

---

## 9. Adım 7 — Şifremi Unuttum / Yeni Şifre Akışı

Uçtan uca akış:

```
LoginScreen ── 'Şifremi unuttum' ──▶ ForgotPasswordScreen
                                          │ resetPasswordForEmail(email, redirectTo)
                                          ▼
                                   Supabase e-posta gönderir
                                          │ kullanıcı linke tıklar
                                          ▼
                          <origin>/#/reset-password  (recovery token ile)
                                          │ onAuthStateChange → passwordRecovery
                                          ▼
                                   ResetPasswordScreen
                                          │ updateUser(password)
                                          │ signOut()
                                          ▼
                                   'Giriş ekranına dön'
```

### 9.1 Redirect adresi

```dart
String? _resolvePasswordResetRedirectTo() {
  if (kIsWeb) {
    final origin = Uri.base.origin;
    return '$origin/#/reset-password';
  }
  // Masaüstü/mobilde deep link yoksa null → Supabase Site URL kullanılır.
  return null;
}
```

Bu adres, **Supabase Dashboard → Authentication → URL Configuration → Redirect URLs** listesinde tanımlı olmalıdır; aksi hâlde bağlantı reddedilir.

### 9.2 ForgotPasswordScreen yapısı

- `AppBar` (beyaz zemin, `elevation: 0.6`) + ortalanmış `SingleChildScrollView`
- `430 px` genişliğinde beyaz kart: `borderRadius 18`, gri kenarlık, `blurRadius 10` gölge
- `CircleAvatar` (r=34, teal %10 zemin) + `Icons.lock_reset_outlined`
- Başlık, açıklama metni, e-posta `TextField` (`prefixIcon`, `errorText`)
- İstemci tarafı e-posta doğrulaması: `^[^\s@]+@[^\s@]+\.[^\s@]+$`
- Başarıda yeşil bilgi kutusu (`_isSent`) — ekran değişmez, kutu eklenir
- `ElevatedButton.icon`: yüklenirken "Gönderiliyor..." + spinner
- Alt kısımda "Giriş ekranına dön" (`Navigator.pop`)

E-posta alanı değiştiğinde hem `_errorMessage` hem `_isSent` sıfırlanır.

### 9.3 ResetPasswordScreen yapısı

Aynı kart iskeleti; içerik `_isCompleted` bayrağına göre iki farklı `Column` arasında değişir (form ↔ başarı ekranı).

Doğrulama kuralları:

| Kural | Mesaj |
| --- | --- |
| Boş alan | Lütfen yeni şifrenizi iki kez girin. |
| < 8 karakter | Şifre en az 8 karakter olmalı. |
| Eşleşmiyor | Şifreler eşleşmiyor. |

Şifre güncellendikten sonra **bilinçli olarak `signOut()` çağrılır**: kullanıcı yeni şifresiyle yeniden giriş yapmak zorundadır. Ardından `_isCompleted = true` ve yeşil onay ekranı + `SnackBar` gösterilir.

> **Tutarsızlık notu:** Kayıt ekranı minimum 6 karakter, şifre sıfırlama ekranı minimum 8 karakter ister. Aynı yapıyı yeniden üretirken tek bir kural belirleyip iki ekrana da uygulayın (ve Supabase Auth ayarlarındaki minimum uzunlukla eşitleyin).

---

## 10. Adım 8 — Kayıt Ekranı ve Davet Akışı

`RegisterScreen` iki modda çalışır:

**A. Serbest kayıt** (`inviteToken == null`)
- Kullanıcı tipi `_roles` listesinden seçilir: Uzman / Müşteri / Kurumsal / OptiYou Ekibi
- `EXPERT` veya `OPTIYOU_TEAM` seçilirse formda "onay bekleyecek" uyarısı gösterilir

**B. Davetli kayıt** (`/register?invite=<token>`)
- `initState` → `_loadInvite()` daveti Supabase'den çeker
- Rol zorla `CUSTOMER` yapılır, e-posta davetten doldurulur
- Davet doğrulama sırası: bulunamadı → kullanılmış → iptal edilmiş → süresi dolmuş
- Kayıt başarılı olursa `linkAuthUserToPatient()` ile hasta kaydına bağlanır ve `markInviteAsUsed()` çağrılır

Kayıt öncesi zorunlu onaylar (hepsi ayrı bayrak): Üyelik Sözleşmesi, Aydınlatma Metni, Kullanım Koşulları. Ticari ileti onayı isteğe bağlıdır.

Doğrulama sırası — ilk başarısız kuralda durup mesaj gösterilir:

1. Davet modundaysa geçerli davet var mı
2. Ad + soyad dolu mu
3. Kullanıcı tipi seçilmiş mi
4. E-posta dolu mu
5. Şifre ≥ 6 karakter mi
6. Şifreler eşleşiyor mu
7. Üç zorunlu yasal onay işaretli mi

Başarıda ekran `_success = true` ile bilgilendirme durumuna geçer (onay gerektiren rollerde "onay bekleniyor" mesajı).

---

## 11. Rol / Onay Matrisi

| Rol kodu | Etiket | Kayıtta `approval_status` | Girişte onay kontrolü |
| --- | --- | --- | --- |
| `CUSTOMER` | Müşteri | `approved` | Yok, doğrudan girer |
| `CORPORATE` | Kurumsal | `approved` | Yok, doğrudan girer |
| `EXPERT` | Uzman | `pending` | **Var** — onaylanana kadar giriş engellenir |
| `OPTIYOU_TEAM` | OptiYou Ekibi | `pending` | **Var** — onaylanana kadar giriş engellenir |

Onay verme işlemi (Supabase panelinden veya yönetim ekranından):

```sql
UPDATE public.user_profiles
   SET approval_status = 'approved', is_approved = TRUE
 WHERE auth_id = '<kullanıcı-uuid>';
```

`_requiresManualApproval()` mantığı **iki yerde** tekrarlanır: `AuthService` ve `RegisterScreen`. Rol politikası değişirse ikisinin de güncellenmesi gerekir (ideali tek bir yardımcıya taşımaktır).

---

## 12. Sıfırdan Üretim Sırası (Kontrol Listesi)

1. [ ] Supabase projesi oluştur; URL ve `anon` anahtarını al
2. [ ] `supabase_flutter` bağımlılığını ekle
3. [ ] `SupabaseConfig` sınıfını yaz
4. [ ] `main()` içinde `Supabase.initialize` çağır
5. [ ] SQL: `roles` (4 rol) → `clinics` → `user_profiles` (onay kolonlarıyla)
6. [ ] SQL: `user_profiles_full` view + `security_invoker`
7. [ ] SQL: RLS'i aç ve politikaları oluştur
8. [ ] SQL: `handle_new_user` + `on_auth_user_created` trigger'ı
9. [ ] SQL: `set_updated_at` trigger'ları
10. [ ] Dart: `RoleCodes` + `AppUser` (`fromMap`/`toMap` view kolonlarıyla birebir)
11. [ ] Dart: `AccountApprovalException` + `AuthService`
12. [ ] Dart: `LoginScreen` (state, widget ağacı, `_login`, `_localizeAuthError`)
13. [ ] Dart: `RegisterScreen` (rol seçimi, yasal onaylar, davet modu)
14. [ ] Dart: `ForgotPasswordScreen` + `ResetPasswordScreen`
15. [ ] Dart: `MaterialApp` teması, `onGenerateRoute`, URL ayrıştırıcılar, `passwordRecovery` dinleyicisi
16. [ ] Supabase: Authentication → URL Configuration'a `<origin>/#/reset-password` ekle
17. [ ] Supabase: e-posta doğrulama (confirm email) ayarını projeye göre aç/kapat

### Test senaryoları

- [ ] Boş e-posta / boş şifre → alan bazlı uyarı
- [ ] Hatalı şifre → "E-posta veya şifre hatalı."
- [ ] `CUSTOMER` girişi → doğrudan dashboard
- [ ] `EXPERT` kaydı → giriş denemesi "onay bekliyor" mesajı **ve oturum açık kalmamalı**
- [ ] Onay verildikten sonra aynı kullanıcı giriş yapabilmeli
- [ ] Şifremi unuttum → mail gelir, link `#/reset-password` açar
- [ ] Yeni şifre kaydedilir, oturum kapanır, yeni şifreyle giriş çalışır
- [ ] Süresi dolmuş sıfırlama linki → oturum hatası mesajı
- [ ] `/register?invite=<gecersiz>` → davet hatası, kayıt engellenir
- [ ] Giriş sonrası tarayıcı geri tuşu → giriş ekranına dönmemeli

---

## 13. Bilinen Farklar ve Dikkat Edilecekler

Aynı yapıyı yeniden üretirken bu noktalar mevcut kodda düzeltilmeye açıktır:

1. **`schema.sql` onay kolonlarını içermiyor.** `approval_status` / `is_approved` sonradan panelden eklenmiş; migration dosyası yok. Yeni kurulumda 4.2'deki tanımı kullanın.
2. **`CORPORATE` rolü `roles` tablosuna eklenmemiş.** Dart tarafında tanımlı olduğu hâlde SQL `INSERT`'inde yok; bu rolle kaydolan kullanıcı `role_id = NULL` ile oluşur ve `role_code` boş döner. 4.1'deki `INSERT` bu eksiği kapatır.
3. **Şifre uzunluğu kuralı tutarsız** (kayıt 6, sıfırlama 8) — tek kurala indirin.
4. **`_requiresManualApproval` iki yerde kopyalanmış** — `AuthService` ve `RegisterScreen`.
5. **`LoginScreen` içinden `RegisterScreen` açılırken `pressureRepository` geçilmiyor**; kayıt ekranındaki bu parametre `null` kalır.
6. **`anon` anahtarı kaynak koda gömülü.** Güvenlik açısından sorun değildir (public anahtar), ancak ortam ayrımı için `--dart-define` ile dışarıdan verilmesi tercih edilebilir.
7. **Giriş ekranında `Form`/`TextFormField` yok**; doğrulama elle yapılır. Aynı yapıyı kurarken `Form` + `validator` kullanmak isterseniz hata gösterimini `errorText`'ten `validator`'a taşımanız gerekir.
