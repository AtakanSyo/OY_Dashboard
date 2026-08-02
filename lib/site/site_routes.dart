import 'package:flutter/material.dart';

import 'content/site_page_content.dart';
import 'pages/site_content_page.dart';
import 'pages/site_home_page.dart';

/// Public site route adları — Superspec §8.1.
///
/// Kullanıcı işlemlerine ait route'lar (`/login`, `/register`, `/dashboard`,
/// `/reset-password`, `/payment-result`, `/legal-consent`) bu dosyanın
/// kapsamı dışındadır; onlar [main.dart] içinde tanımlı kalır.
class SiteRoutes {
  const SiteRoutes._();

  static const String home = '/';

  static const String nasilCalisir = '/nasil-calisir';
  static const String tabanliklar = '/tabanliklar';
  static const String tabanliklarGunluk = '/tabanliklar/gunluk';
  static const String tabanliklarSpor = '/tabanliklar/spor';
  static const String tabanliklarRecovery = '/tabanliklar/recovery';
  static const String isAyakkabisi = '/is-ayakkabisi';

  static const String anatomikKategoriler = '/anatomik-kategorilerimiz';

  static const String teknolojiler = '/teknolojilerimiz';
  static const String teknolojilerDml = '/teknolojilerimiz/dml';

  static const String cozumlerKlinikler = '/cozumler/klinikler';
  static const String cozumlerEczaneler =
      '/cozumler/eczaneler-ayakkabi-magazalari';
  static const String cozumlerIsYerleri = '/cozumler/is-yerleri';
  static const String cozumlerBireysel = '/cozumler/bireysel';

  static const String tubitak = '/tubitak-projeleri';
  static const String tubitak1812 = '/tubitak-projeleri/1812';
  static const String tubitak1707 = '/tubitak-projeleri/1707';

  static const String olcumMerkezleri = '/olcum-merkezleri';
  static const String taramaStandiBasvuru = '/tarama-standi-basvuru';

  /// Bireysel kullanıcı randevusu (hero ve üst bar birincil aksiyonu).
  static const String taramaRandevusu = '/tarama-randevusu';

  static const String hakkimizda = '/hakkimizda';
  static const String ekibimiz = '/ekibimiz';
  static const String kariyer = '/kariyer';
  static const String haberler = '/haberler';
  static const String blog = '/blog';
  static const String iletisim = '/iletisim';
  static const String sss = '/sss';

  static const String kvkk = '/kvkk';
  static const String gizlilik = '/gizlilik-politikasi';
  static const String kullanimKosullari = '/kullanim-kosullari';

  /// Giriş ekranı. Bu adres [main.dart] içinde mevcut `LoginScreen`'e
  /// bağlanır (`/login` de çalışmaya devam eder); site tarafı yalnızca
  /// yönlendirir, giriş akışına müdahale etmez.
  static const String login = '/giris';
}

/// Mega-menü içindeki tek bir bağlantı.
class SiteNavLink {
  final String label;
  final String route;
  final String? description;

  const SiteNavLink(this.label, this.route, {this.description});
}

/// Ana navigasyon öğesi. [route] doluysa doğrudan gider,
/// [children] doluysa mega-menü açar.
class SiteNavItem {
  final String label;

  /// Üst barda kullanılan kısa etiket. Mega-menü ve mobil menüde her zaman
  /// tam [label] gösterilir.
  final String? barLabel;

  final String? route;
  final List<SiteNavLink> children;

  const SiteNavItem(
    this.label, {
    this.barLabel,
    this.route,
    this.children = const [],
  });

  String get shortLabel => barLabel ?? label;

  bool get hasMenu => children.isNotEmpty;
}

/// Ana navigasyon — Superspec §6.1–6.5.
/// Logo ana sayfaya götürdüğü için ayrıca "Anasayfa" öğesi yoktur.
const List<SiteNavItem> siteNavigation = [
  SiteNavItem('Nasıl Çalışır?', route: SiteRoutes.nasilCalisir),
  SiteNavItem(
    'Çözümler',
    children: [
      SiteNavLink(
        'Klinikler',
        SiteRoutes.cozumlerKlinikler,
        description: 'Ölçüm, takip ve ürün süreçlerini tek akışta yönetin.',
      ),
      SiteNavLink(
        'Eczaneler ve Ayakkabı Mağazaları',
        SiteRoutes.cozumlerEczaneler,
        description: 'Mağaza içinde tarama ile doğru ürüne yönlendirin.',
      ),
      SiteNavLink(
        'İş Yerleri',
        SiteRoutes.cozumlerIsYerleri,
        description: 'Ayakta çalışan ekipler için toplu ölçüm programı.',
      ),
      SiteNavLink(
        'Bireysel Kullanıcılar',
        SiteRoutes.cozumlerBireysel,
        description: 'Kendi ayak profilini çıkar, uygun ürünü seç.',
      ),
      SiteNavLink(
        'Tarama Standı İçin Başvur',
        SiteRoutes.taramaStandiBasvuru,
        description: 'İşletmenize tarama standı kurulumu için başvurun.',
      ),
    ],
  ),
  SiteNavItem(
    'Ürünler',
    children: [
      SiteNavLink(
        'Tüm Tabanlıklar',
        SiteRoutes.tabanliklar,
        description: 'Ürün ailelerinin tamamı.',
      ),
      SiteNavLink(
        'Günlük Tabanlıklar',
        SiteRoutes.tabanliklarGunluk,
        description: 'Gün boyu konfor için veri güdümlü anatomik yapı.',
      ),
      SiteNavLink(
        'Spor Tabanlıkları',
        SiteRoutes.tabanliklarSpor,
        description: 'Karbon fiber taban, darbe emilimi desteği.',
      ),
      SiteNavLink(
        'Recovery Ürünleri',
        SiteRoutes.tabanliklarRecovery,
        description: 'OY Recovery toparlayıcı sandalet ailesi.',
      ),
      SiteNavLink(
        'Veri Güdümlü Ortopedik İş Ayakkabısı',
        SiteRoutes.isAyakkabisi,
        description: 'Ayakta çalışma senaryosu için geliştirilen model.',
      ),
    ],
  ),
  SiteNavItem(
    'Anatomik Kategorilerimiz',
    barLabel: 'Kategoriler',
    route: SiteRoutes.anatomikKategoriler,
  ),
  SiteNavItem(
    'Teknolojilerimiz',
    barLabel: 'Teknoloji',
    children: [
      SiteNavLink(
        '3D Ayak Tarama',
        SiteRoutes.teknolojiler,
        description: 'Ayak geometrisinin üç boyutlu kaydı.',
      ),
      SiteNavLink(
        'Basınç Ölçümü',
        SiteRoutes.teknolojiler,
        description: 'Basış dağılımının görünür hâle getirilmesi.',
      ),
      SiteNavLink(
        'Yapay Zekâ Destekli Değerlendirme',
        SiteRoutes.teknolojiler,
        description: 'Ölçüm verisinden uyum sınıfına giden yol.',
      ),
      SiteNavLink(
        'Üretim ve Tarama Teknolojilerimiz',
        SiteRoutes.teknolojiler,
        description: 'Tarama donanımı ve üretim hattı.',
      ),
      SiteNavLink(
        'DML — Dijital Üretim Laboratuvarı',
        SiteRoutes.teknolojilerDml,
        description: 'Geliştirme, test, prototipleme omurgası.',
      ),
      SiteNavLink(
        'Kalite ve Doğruluk',
        SiteRoutes.teknolojiler,
        description: 'Ölçüm doğruluğu ve tekrarlanabilirlik.',
      ),
      SiteNavLink(
        'Veri Güvenliği',
        SiteRoutes.teknolojiler,
        description: 'Ölçüm verisinin saklanması ve korunması.',
      ),
    ],
  ),
  SiteNavItem(
    'TÜBİTAK Projelerimiz',
    barLabel: 'TÜBİTAK',
    children: [
      SiteNavLink(
        '1812 — Yenilikçi Ürünler ve Üretim Teknolojileri',
        SiteRoutes.tubitak1812,
      ),
      SiteNavLink(
        '1707 — Siparişe Dayalı Ar-Ge Projesi',
        SiteRoutes.tubitak1707,
      ),
      SiteNavLink('Tüm Projeler', SiteRoutes.tubitak),
    ],
  ),
  SiteNavItem(
    'Kurumsal',
    children: [
      SiteNavLink('Hakkımızda', SiteRoutes.hakkimizda),
      SiteNavLink('Ekibimiz', SiteRoutes.ekibimiz),
      SiteNavLink('Kariyer', SiteRoutes.kariyer),
      SiteNavLink('Haberler / Basın', SiteRoutes.haberler),
      SiteNavLink('Ölçüm Merkezleri', SiteRoutes.olcumMerkezleri),
      SiteNavLink('İletişim', SiteRoutes.iletisim),
    ],
  ),
];

/// Site içi gezinme yardımcıları.
class SiteNav {
  const SiteNav._();

  /// Aynı sayfaya tekrar gitmeyi engelleyerek route'a geçer.
  /// Ana sayfaya dönerken yığın temizlenir.
  static void go(BuildContext context, String route) {
    final current = ModalRoute.of(context)?.settings.name;
    if (current == route) return;

    if (route == SiteRoutes.home) {
      Navigator.pushNamedAndRemoveUntil(context, route, (_) => false);
      return;
    }

    Navigator.pushNamed(context, route);
  }
}

/// Public site route'larını üretir. Site route'u değilse `null` döner ve
/// çağıran taraf (main.dart) kendi route'larıyla devam eder.
Route<dynamic>? generateSiteRoute(RouteSettings settings) {
  final rawName = settings.name ?? '';
  if (rawName.isEmpty) return null;

  final path = Uri.tryParse(rawName)?.path ?? rawName;

  if (path == SiteRoutes.home) {
    return _siteRoute(const SiteHomePage(), settings);
  }

  final content = sitePageContent[path];
  if (content == null) return null;

  return _siteRoute(SiteContentPage(content: content), settings);
}

MaterialPageRoute<dynamic> _siteRoute(Widget page, RouteSettings settings) {
  return MaterialPageRoute<dynamic>(
    builder: (_) => page,
    settings: settings,
  );
}
