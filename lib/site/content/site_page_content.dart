import '../../legal/legal_document_registry.dart';
import '../site_routes.dart';

/// İçerik bloğu tipleri. Sayfalar bu bloklardan kurulur; render tarafı
/// [SiteContentPage] içindedir.
sealed class SiteBlock {
  const SiteBlock();
}

class SiteHeadingBlock extends SiteBlock {
  final String eyebrow;
  final String title;
  final String? description;

  /// Sayfa içi çapa (anchor) kimliği. Doluysa bu bölüm `/route#id` ile
  /// hedeflenebilir ve [SiteAnchorNavBlock] buraya kaydırabilir.
  final String? anchorId;

  const SiteHeadingBlock({
    required this.eyebrow,
    required this.title,
    this.description,
    this.anchorId,
  });
}

/// Görsel + metin bloğu (dönüşümlü hizalı). MD §7 ve §8 şablonlarının
/// omurgası: bir görsel, başlık, gövde ve isteğe bağlı madde listesi.
class SiteImageTextBlock extends SiteBlock {
  final String? eyebrow;
  final String title;
  final String? body;
  final List<String> bullets;
  final String image;
  final String? imageAlt;
  final String? caption;

  /// Görseli sağa yerleştirir (varsayılan sol).
  final bool imageRight;

  /// Ürün / cihaz / sonuç görselleri için `BoxFit.contain`; lifestyle için
  /// `false` → `BoxFit.cover`.
  final bool contain;

  /// Görselin altında gösterilecek "temsilî / bilgilendirme amaçlı" notu.
  final String? disclaimer;

  const SiteImageTextBlock({
    required this.title,
    required this.image,
    this.eyebrow,
    this.body,
    this.bullets = const [],
    this.imageAlt,
    this.caption,
    this.imageRight = false,
    this.contain = true,
    this.disclaimer,
  });
}

/// Numaralı süreç adımları (MD §7.4 / §8 "nasıl çalışır").
class SiteStepsBlock extends SiteBlock {
  final String? title;
  final List<({String number, String title, String body})> steps;

  const SiteStepsBlock({this.title, required this.steps});
}

/// Kısa değer/ölçü şeridi (MD §7.2). Değerler merkezî içerik sabitinden gelir.
class SiteStatsBlock extends SiteBlock {
  final List<({String value, String label})> stats;

  const SiteStatsBlock({required this.stats});
}

/// Tek görsel + açıklama + "temsilî" notu (gerçek tarama/sonuç ekranları).
class SiteFigureBlock extends SiteBlock {
  final String image;
  final String? imageAlt;
  final String? caption;
  final String? disclaimer;
  final bool contain;

  const SiteFigureBlock({
    required this.image,
    this.imageAlt,
    this.caption,
    this.disclaimer,
    this.contain = true,
  });
}

/// Erişilebilir aç/kapa SSS listesi (MD §8 /sss ve çözüm SSS'leri).
class SiteFaqBlock extends SiteBlock {
  final String? title;
  final List<({String question, String answer})> items;

  const SiteFaqBlock({this.title, required this.items});
}

/// İki hiyerarşik CTA kartı (MD §7.11 final CTA).
class SiteSplitCtaBlock extends SiteBlock {
  final String primaryTitle;
  final String primaryLabel;
  final String primaryRoute;
  final String secondaryTitle;
  final String secondaryLabel;
  final String secondaryRoute;

  const SiteSplitCtaBlock({
    required this.primaryTitle,
    required this.primaryLabel,
    required this.primaryRoute,
    required this.secondaryTitle,
    required this.secondaryLabel,
    required this.secondaryRoute,
  });
}

/// Sayfa içi çapa navigasyonu (MD §7.8 /teknolojilerimiz).
class SiteAnchorNavBlock extends SiteBlock {
  final List<({String id, String label})> items;

  const SiteAnchorNavBlock({required this.items});
}

class SiteFeaturesBlock extends SiteBlock {
  final List<({String title, String body})> items;
  final int columns;

  const SiteFeaturesBlock({required this.items, this.columns = 2});
}

class SiteBulletsBlock extends SiteBlock {
  final String? title;
  final List<String> bullets;
  final String? note;

  const SiteBulletsBlock({this.title, required this.bullets, this.note});
}

class SiteCategoryCodeBlock extends SiteBlock {
  final String code;
  final List<({String part, String meaning})> legend;

  const SiteCategoryCodeBlock({required this.code, required this.legend});
}

class SiteProjectsBlock extends SiteBlock {
  final List<({String code, String title, String description, String route})>
  projects;

  const SiteProjectsBlock({required this.projects});
}

class SiteProductsBlock extends SiteBlock {
  final List<({String image, String title, String description, String route})>
  products;

  const SiteProductsBlock({required this.products});
}

class SitePlaceholderBlock extends SiteBlock {
  final String label;
  final String? note;

  const SitePlaceholderBlock({required this.label, this.note});
}

/// Mevcut hukuki belge kayıtlarından tam metin basar.
class SiteLegalBlock extends SiteBlock {
  final String documentCode;

  const SiteLegalBlock({required this.documentCode});
}

class SiteCtaBlock extends SiteBlock {
  final String title;
  final String description;
  final String primaryLabel;
  final String primaryRoute;
  final String? secondaryLabel;
  final String? secondaryRoute;

  const SiteCtaBlock({
    required this.title,
    required this.description,
    required this.primaryLabel,
    required this.primaryRoute,
    this.secondaryLabel,
    this.secondaryRoute,
  });
}

/// Bir public sayfanın tüm içeriği.
class SitePageContent {
  final String eyebrow;
  final String title;
  final String description;
  final List<SiteBlock> blocks;

  const SitePageContent({
    required this.eyebrow,
    required this.title,
    required this.description,
    this.blocks = const [],
  });
}

const SiteCtaBlock _scanCta = SiteCtaBlock(
  title: 'Ayak profilini çıkarmaya hazır mısın?',
  description:
      'Randevu oluştur, en yakın ölçüm merkezinde tarama iki dakika sürsün.',
  primaryLabel: 'Tarama Yap',
  primaryRoute: SiteRoutes.taramaRandevusu,
  secondaryLabel: 'Ölçüm Merkezleri',
  secondaryRoute: SiteRoutes.olcumMerkezleri,
);

const SiteCtaBlock _contactCta = SiteCtaBlock(
  title: 'Kurumsal iş birliği için görüşelim',
  description:
      'Klinik, eczane, mağaza ve iş yerleri için kurulum ve süreç modelini '
      'birlikte planlayalım.',
  primaryLabel: 'İletişime Geç',
  primaryRoute: SiteRoutes.iletisim,
  secondaryLabel: 'Tarama Standı İçin Başvur',
  secondaryRoute: SiteRoutes.taramaStandiBasvuru,
);

/// Route → içerik eşlemesi.
///
/// Ana sayfa [SiteHomePage] içinde; buradaki kayıtlar giriş yapmamış bir
/// ziyaretçinin gezdiği tüm menü sayfalarını besler. İçerik veri olarak
/// tutulur, [SiteContentPage] bloklara göre çizer.
///
/// Dil: `CLAUDE_CODE_IMPLEMENTATION.md` §9 guardrail'leri — "veri güdümlü",
/// "anatomik iç taban", "uyum skoru", "kullanım senaryosu"; tıbbi tanı /
/// doğrulanmamış fayda / sertifika iddiası yok.
const String _genDir = 'assets/site/generated';
const String _srcDir = 'assets/site/source';

const SiteSplitCtaBlock _finalScanCta = SiteSplitCtaBlock(
  primaryTitle: 'Tarama için randevu alın.',
  primaryLabel: 'Tarama Yap',
  primaryRoute: SiteRoutes.taramaRandevusu,
  secondaryTitle: 'Tarama standı için başvurun.',
  secondaryLabel: 'Başvuru Yap',
  secondaryRoute: SiteRoutes.taramaStandiBasvuru,
);

const Map<String, SitePageContent> sitePageContent = {
  // ── Nasıl Çalışır? ─────────────────────────────────────────────────────────
  SiteRoutes.nasilCalisir: SitePageContent(
    eyebrow: 'Süreç',
    title: 'Ölçümden teslimata, tek veri akışı',
    description:
        '3D ayak tarama ve plantar basınç ölçümü aynı dijital süreçte '
        'birleşir. Yapay zekâ destekli değerlendirme ve uzman kontrolüyle '
        'uygun anatomik iç taban yapısı belirlenir; üretim ve teslimat '
        'çevrim içi takip edilir.',
    blocks: [
      SiteImageTextBlock(
        eyebrow: '01 · 3D ayak tarama',
        title: 'Ayağınızın dijital profili çıkarılır',
        body:
            'Uzunluk, genişlik, kemer yapısı ve iki ayak arasındaki geometrik '
            'farklar yük altında taranır. Değerlendirme yalnızca ayakkabı '
            'numarasına değil, ayağın gerçek anatomik özelliklerine dayanır.',
        image: '$_srcDir/real-scan-session.png',
        imageAlt:
            'Bir kişinin tarama platformunda 3D ayak taramasından geçmesi',
      ),
      SiteImageTextBlock(
        eyebrow: '02 · Plantar basınç ölçümü',
        title: 'Basış dinamikleri görünür hâle gelir',
        body:
            'Topuk, orta ayak ve ön ayak bölgelerine aktarılan yük ve basınç '
            'dağılımı ölçülür. 3D tarama ile birlikte okunan bu veri, destek '
            've yastıklama ihtiyacının bütüncül incelenmesini sağlar.',
        image: '$_srcDir/real-plantar-pressure.png',
        imageAlt: 'Renkli plantar basınç haritası',
        imageRight: true,
      ),
      SiteStepsBlock(
        title: 'Ölçümden teslimata beş adım',
        steps: [
          (
            number: '01',
            title: '3D biyomekanik tarama',
            body:
                'Ayak geometrisi yük altında, iki ayak birlikte '
                'dijitalleştirilir.',
          ),
          (
            number: '02',
            title: 'Verinin eşleştirilmesi',
            body:
                'Geometri ve plantar basınç verisi tek kayıtta bir araya '
                'getirilir.',
          ),
          (
            number: '03',
            title: 'Yapay zekâ destekli anatomik kategorileme',
            body:
                'Veriler anatomik kategoriye ve uyum skoruna dönüştürülür, '
                'uzman kontrolünden geçer.',
          ),
          (
            number: '04',
            title: 'Veri güdümlü dijital üretim',
            body:
                'Belirlenen yapıya uygun anatomik iç taban dijital süreçle '
                'üretilir ve kontrol edilir.',
          ),
          (
            number: '05',
            title: 'Teslimat ve dijital takip',
            body:
                'Ürün kargoya verilir; sonraki ölçümlerle değişim '
                'karşılaştırılabilir.',
          ),
        ],
      ),
      SiteCategoryCodeBlock(
        code: '42-R-M-N-B',
        legend: [
          (part: '42', meaning: 'Numara — temel uzunluk aralığı.'),
          (part: 'R', meaning: 'Ön ayak formu.'),
          (part: 'M', meaning: 'Orta kemer profili.'),
          (part: 'N', meaning: 'Nötr adım yönelimi.'),
          (part: 'B', meaning: 'Balance — dengeli kullanım odağı.'),
        ],
      ),
      SiteHeadingBlock(
        eyebrow: 'Uyum skoru',
        title: 'Temsilî bir okuma; klinik tanı değildir',
        description:
            'Uyum skoru; geometri ve basınç verilerinin ürün yapısına ne kadar '
            'oturduğunu özetleyen temsilî bir göstergedir. Kapalı algoritma '
            'ayrıntıları paylaşılmaz. Bilgilendirme amaçlıdır; klinik tanı '
            'yerine geçmez.',
      ),
      SiteFigureBlock(
        image: '$_srcDir/real-result-detail-1.png',
        imageAlt: 'Örnek sonuç ekranı: kemer, basınç ve topuk yönelimi',
        caption: 'Örnek sonuç ekranı.',
        disclaimer: 'Temsilî arayüz — demo veri. Klinik tanı yerine geçmez.',
      ),
      SiteFeaturesBlock(
        columns: 2,
        items: [
          (
            title: 'Seri kategori üretimi',
            body:
                'Anatomik kategoriye uygun hazır yapı; hızlı teslimat için '
                'kullanım senaryosuna göre seçilir.',
          ),
          (
            title: 'Detaylı dijital üretim',
            body:
                'Ölçüm verisine göre hazırlanan üretim dosyasıyla anatomik iç '
                'taban dijital süreçte üretilir.',
          ),
        ],
      ),
      _finalScanCta,
    ],
  ),

  // ── Ürünler ────────────────────────────────────────────────────────────────
  SiteRoutes.tabanliklar: SitePageContent(
    eyebrow: 'Ürünler',
    title: 'Her kullanım senaryosuna farklı bir katman mimarisi',
    description:
        'Günlük kullanım, spor, toparlanma ve ayakta çalışma senaryoları için '
        'geliştirilen veri güdümlü ürün aileleri.',
    blocks: [
      SiteProductsBlock(
        products: [
          (
            image: '$_genDir/product-daily-assembled.png',
            title: 'OY Orthopedic — Günlük',
            description:
                'Gün boyu konfor, denge ve destek için veri güdümlü anatomik '
                'iç taban.',
            route: SiteRoutes.tabanliklarGunluk,
          ),
          (
            image: '$_srcDir/oy-sports-product.png',
            title: 'OY Sports',
            description:
                'Yüksek tempolu kullanım için enerji yönetimi ve stabilite '
                'odaklı yapı.',
            route: SiteRoutes.tabanliklarSpor,
          ),
          (
            image: '$_srcDir/oy-recovery-product.png',
            title: 'OY Recovery',
            description:
                'Yoğun gün sonrası için yastıklama ve toparlayıcı temas '
                'yüzeyi.',
            route: SiteRoutes.tabanliklarRecovery,
          ),
          (
            image: 'assets/images/products/personal_shoe.png',
            title: 'Veri Güdümlü Ortopedik İş Ayakkabısı',
            description:
                'Uzun süre ayakta çalışma senaryosu için geliştirilen model.',
            route: SiteRoutes.isAyakkabisi,
          ),
        ],
      ),
      _scanCta,
    ],
  ),

  SiteRoutes.tabanliklarGunluk: SitePageContent(
    eyebrow: 'Günlük Tabanlıklar',
    title: 'OY Orthopedic',
    description:
        'Gün boyu kullanım için veri güdümlü anatomik iç taban. Ayak profiline '
        'göre seçilen destek ve basınç dağıtımıyla konforu hedefler.',
    blocks: [
      SiteImageTextBlock(
        eyebrow: 'Katman mimarisi',
        title: 'Dört katman, tek yapı',
        body:
            'Kartın üzerine gelindiğinde katmanlar ayrışır. Her katman farklı '
            'bir işlevi üstlenir; birlikte gün boyu taşınabilir bir yapı '
            'oluşturur.',
        bullets: [
          'Antibakteriyel üst yüzey — nemi yönetir, hijyeni destekler.',
          'Konfor katmanı — temas basıncını yumuşatır.',
          'Anatomik destek çekirdeği — kavisi tarama verisine göre destekler.',
          'Stabil taban — adımda yanal salınımı sınırlar.',
        ],
        image: '$_genDir/product-daily-exploded.png',
        imageAlt: 'OY Orthopedic iç tabanının dört katmana ayrılmış görünümü',
        imageRight: true,
      ),
      SiteFeaturesBlock(
        columns: 2,
        items: [
          (
            title: 'Kullanım senaryosu',
            body: 'Günlük ayakkabı, ofis ve şehir içi yürüyüş.',
          ),
          (
            title: 'Ölçümden ürüne',
            body:
                'Uygun yapı, 3D tarama ve plantar basınç ölçümü sonucuna göre '
                'belirlenir.',
          ),
          (
            title: 'Bakım',
            body: 'Nemli bezle silinir, doğrudan ısı kaynağından uzak tutulur.',
          ),
          (
            title: 'Takip',
            body: 'Periyodik ölçümle konfor geri bildirimi izlenir.',
          ),
        ],
      ),
      _scanCta,
    ],
  ),

  SiteRoutes.tabanliklarSpor: SitePageContent(
    eyebrow: 'Spor Tabanlıkları',
    title: 'OY Sports',
    description:
        'Yüksek tempolu kullanım için enerji yönetimi ve stabilite odaklı '
        'veri güdümlü tabanlık.',
    blocks: [
      SiteImageTextBlock(
        eyebrow: 'Katman mimarisi',
        title: 'Tepki ve stabilite bir arada',
        bullets: [
          'Teknik üst yüzey — teri ve sürtünmeyi yönetir.',
          'Tepkisel yastıklama — iniş kuvvetini emer, adıma geri verir.',
          'Enerji yönetim katmanı — yükü tabana yayar.',
          'Stabilizasyon plakası — hızlı yön değişiminde ayağı hizada tutar.',
        ],
        image: '$_genDir/product-sports-exploded.png',
        imageAlt: 'OY Sports tabanlığının dört katmana ayrılmış görünümü',
      ),
      SiteFeaturesBlock(
        columns: 2,
        items: [
          (
            title: 'Kullanım senaryosu',
            body: 'Koşu, saha sporları ve yüksek tempolu antrenman.',
          ),
          (
            title: 'Ölçüm',
            body:
                'Basış dağılımı ve adım yönelimi verisi ürün seçimini '
                'belirler.',
          ),
          (
            title: 'Teknik özellikler',
            body:
                'Malzeme ve yoğunluk değerleri, ilgili ürün belgesiyle '
                'doğrulandığında burada yayımlanır.',
          ),
          (title: 'Takip', body: 'Periyodik ölçümle değişim izlenebilir.'),
        ],
      ),
      _scanCta,
    ],
  ),

  SiteRoutes.tabanliklarRecovery: SitePageContent(
    eyebrow: 'Recovery',
    title: 'OY Recovery',
    description:
        'Yoğun gün sonrası için yastıklama, basınç dağıtımı ve esnek zemin '
        'desteği sağlayan toparlayıcı sandalet.',
    blocks: [
      SiteImageTextBlock(
        eyebrow: 'Katman mimarisi',
        title: 'Hafif gövde, toparlayıcı temas',
        bullets: [
          'Nefes alan örgü bant — ayağı sarar, temas basıncını dağıtır.',
          'Konturlu ayak yatağı — tabanı geniş alana yayar.',
          'Yumuşak ara taban — adım yükünü yumuşatır.',
          'Dayanıklı dış taban — kaymaz, esnek zemin teması.',
        ],
        image: '$_genDir/product-recovery-exploded.png',
        imageAlt: 'OY Recovery sandaletinin katmanlara ayrılmış görünümü',
        imageRight: true,
      ),
      SiteFeaturesBlock(
        columns: 2,
        items: [
          (
            title: 'Kullanım senaryosu',
            body: 'Antrenman sonrası, uzun mesai sonrası ve ev içi kullanım.',
          ),
          (title: 'Üretim', body: 'SLA 3B baskı ile kafes yapılı gövde.'),
          (
            title: 'Hafiflik',
            body: 'Kafes yapısı ağırlığı düşürürken desteği korur.',
          ),
          (title: 'Konfor', body: 'Ayak tabanına yayılan geniş temas yüzeyi.'),
        ],
      ),
      _scanCta,
    ],
  ),

  SiteRoutes.isAyakkabisi: SitePageContent(
    eyebrow: 'İş Ayakkabısı',
    title: 'Veri Güdümlü Ortopedik İş Ayakkabısı',
    description:
        'Uzun süre ayakta çalışma senaryosu için geliştirilen, ölçüm verisine '
        'göre seçilen veri güdümlü iş ayakkabısı ve iç taban çözümü.',
    blocks: [
      SiteFeaturesBlock(
        columns: 2,
        items: [
          (
            title: 'Kimler için uygun?',
            body:
                'Sağlık, üretim, perakende ve hizmet sektöründe gün boyu ayakta '
                'çalışanlar.',
          ),
          (
            title: 'Yaklaşım',
            body:
                'Ürün seçimi, ayak profili ve basış dağılımı verisiyle birlikte '
                'yapılır.',
          ),
          (
            title: 'Kurumsal program',
            body:
                'İş yerlerinde toplu ölçüm ve takip programıyla birlikte '
                'kurgulanabilir.',
          ),
          (
            title: 'Standartlar',
            body:
                'ESD, antistatik ve EN ISO iş güvenliği sınıfı bilgileri, '
                'ilgili ürün belgesi sağlandığında yayımlanır.',
          ),
        ],
      ),
      _contactCta,
    ],
  ),

  // ── Anatomik Kategorilerimiz ──────────────────────────────────────────────
  SiteRoutes.anatomikKategoriler: SitePageContent(
    eyebrow: 'Anatomik Kategoriler',
    title: 'Numara Yalnızca Başlangıçtır',
    description:
        'Aynı ayakkabı numarası, farklı ayaklarda aynı uyumu garanti etmez. '
        'Doğru seçim çok parametreli bir değerlendirmeye dayanır.',
    blocks: [
      SiteImageTextBlock(
        eyebrow: 'Kemer profili',
        title: 'Düşük, nötr ve yüksek kemer — başlangıç ayrımı',
        body:
            'Kemer profili, destek ihtiyacını okumaya başlamak için ilk '
            'bakılan özelliktir. Tek başına bir sınıf değil; geometri ve '
            'basınç verileriyle birlikte değerlendirilir.',
        image: '$_genDir/anatomical-arch-categories.webp',
        imageAlt: 'Düşük, nötr ve yüksek kemer görselleştirmesi',
        contain: false,
      ),
      SiteBulletsBlock(
        title: 'Neden numara tek başına yeterli değil?',
        bullets: [
          'Aynı ayakkabı numarası, farklı ayaklarda aynı uyumu garanti etmez.',
          'Uzunluk ve genişlik, ayağın tüm yapısını açıklamaya yetmez.',
          'Ayak yapısı yük altında değişir.',
          'Gün içi değişim, zemin etkisi ve sağ-sol farkı dikkate alınmalıdır.',
        ],
        note:
            'Bu maddeler ilgili uyum çalışmalarının kısa özetidir; tam alıntı '
            'içermez.',
      ),
      SiteFeaturesBlock(
        columns: 3,
        items: [
          (title: 'Numara', body: 'Temel uzunluk aralığı.'),
          (title: 'Uzunluk', body: 'Topuktan en uzun parmağa mesafe.'),
          (title: 'Tarak', body: 'Ön ayak genişliği ve hacmi.'),
          (title: 'Arka ayak', body: 'Topuk yönelimi ve temas ekseni.'),
          (
            title: 'Kemer profili',
            body: 'Kemer yüksekliği ve destek ihtiyacı.',
          ),
          (title: 'Adım yönelimi', body: 'Basış sırasında ağırlığın yönü.'),
        ],
      ),
      SiteCategoryCodeBlock(
        code: '42 · 27 · 15 · 2',
        legend: [
          (part: '42', meaning: 'Numara.'),
          (part: '27', meaning: 'Uzunluk (cm).'),
          (part: '15', meaning: 'Tarak genişliği (cm).'),
          (part: '2', meaning: 'Arka ayak yönelim adımı.'),
        ],
      ),
      SiteHeadingBlock(
        eyebrow: 'Kategori Sistemi',
        title: 'Teşhis değil, uyum sınıfı',
        description:
            'Kategoriler ürün seçimini kolaylaştırmak için tanımlanır. Uzman '
            'etiketli veri → yapay zekâ destekli sınıf → temsilî uyum skoru '
            'akışında ilerler. Tıbbi bir sınıflandırma değildir.',
      ),
      SiteFigureBlock(
        image: '$_srcDir/real-arch-result.png',
        imageAlt: 'Örnek kemer sonucu görünümü',
        caption: 'Örnek kemer sonucu.',
        disclaimer:
            'Temsilî görünüm — demo veri. Klinik tanı veya başarı oranı '
            'değildir.',
      ),
      SiteFaqBlock(
        items: [
          (
            question: 'Kategori kodu bir teşhis mi?',
            answer:
                'Hayır. Kod, ürün seçimini kolaylaştıran bir uyum sınıfıdır; '
                'tıbbi tanı içermez.',
          ),
          (
            question: 'Uyum skoru neyi gösterir?',
            answer:
                'Ölçüm verisinin ürün yapısına ne kadar oturduğunu özetleyen '
                'temsilî bir göstergedir.',
          ),
        ],
      ),
      _scanCta,
    ],
  ),

  // ── Teknolojilerimiz (anchor'lı tek sayfa) ───────────────────────────────
  SiteRoutes.teknolojiler: SitePageContent(
    eyebrow: 'Teknolojilerimiz',
    title: 'Ölçümü, değerlendirmeyi ve üretimi bir arada tutan altyapı',
    description:
        'Tarama donanımından dijital üretime kadar tüm adımlar aynı veri '
        'zinciri üzerinde çalışır.',
    blocks: [
      SiteAnchorNavBlock(
        items: [
          (id: '3d-ayak-tarama', label: '3D ayak tarama'),
          (id: 'basinc-olcumu', label: 'Basınç ölçümü'),
          (id: 'yz-degerlendirme', label: 'YZ destekli değerlendirme'),
          (id: 'uretim-tarama', label: 'Üretim ve tarama'),
          (id: 'kalite-dogruluk', label: 'Kalite ve doğruluk'),
          (id: 'veri-guvenligi', label: 'Veri güvenliği'),
        ],
      ),
      SiteHeadingBlock(
        anchorId: '3d-ayak-tarama',
        eyebrow: 'Teknoloji',
        title: '3D ayak tarama',
        description:
            'Ayak geometrisi üç boyutlu olarak, yük altında ve iki ayak '
            'birlikte kaydedilir. Çıktı; uzunluk, genişlik, kavis ve sağ-sol '
            'farkını içeren bir nokta bulutudur.',
      ),
      SiteFigureBlock(
        image: '$_srcDir/real-3d-foot-scan.png',
        imageAlt: 'Gerçek 3D ayak tarama görünümü',
        caption: 'Gerçek 3D tarama çıktısı.',
      ),
      SiteHeadingBlock(
        anchorId: 'basinc-olcumu',
        eyebrow: 'Teknoloji',
        title: 'Basınç ölçümü',
        description:
            'Plantar basınç platformu; topuk, orta ayak ve ön ayak '
            'bölgelerindeki yük dağılımını görünür hâle getirir.',
      ),
      SiteFigureBlock(
        image: '$_srcDir/real-pressure-map.png',
        imageAlt: 'Plantar basınç haritası',
        caption: 'Örnek basınç haritası.',
        disclaimer: 'Temsilî görünüm — demo veri.',
      ),
      SiteHeadingBlock(
        anchorId: 'yz-degerlendirme',
        eyebrow: 'Teknoloji',
        title: 'Yapay zekâ destekli değerlendirme',
        description:
            '3D geometri ve plantar basınç verileri birlikte değerlendirilir; '
            'anatomik kategori ve temsilî uyum skoru üretilir ve uzman '
            'kontrolünden geçer. Kapalı algoritma ayrıntıları paylaşılmaz.',
      ),
      SiteHeadingBlock(
        anchorId: 'uretim-tarama',
        eyebrow: 'Teknoloji',
        title: 'Üretim ve tarama teknolojilerimiz',
        description:
            'Tarama donanımı ve dijital üretim hattı aynı veri zincirine '
            'bağlıdır; ölçümden üretim dosyasına elle veri aktarımı yapılmaz.',
      ),
      SiteImageTextBlock(
        title: 'Dijital üretim hattı',
        body:
            'Üretim dosyaları kontrollü dijital süreçle hazırlanır; çıktı '
            'tekrarlanabilir ve izlenebilirdir.',
        image: '$_srcDir/real-cnc-production.png',
        imageAlt: 'Dijital üretim alanından görünüm',
        imageRight: true,
      ),
      SiteHeadingBlock(
        anchorId: 'kalite-dogruluk',
        eyebrow: 'Teknoloji',
        title: 'Kalite ve doğruluk',
        description:
            'Ölçüm doğruluğu ve tekrarlanabilirlik düzenli olarak kontrol '
            'edilir. Sayısal doğruluk değerleri, doğrulama raporu '
            'yayımlandığında bu bölüme eklenir.',
      ),
      SiteHeadingBlock(
        anchorId: 'veri-guvenligi',
        eyebrow: 'Teknoloji',
        title: 'Veri güvenliği',
        description:
            'Ölçüm verisi erişim yetkileriyle saklanır ve korunur. Ayrıntılar '
            'Aydınlatma Metni ve Gizlilik Politikası’nda yer alır.',
      ),
      SiteCtaBlock(
        title: 'DML — Dijital Üretim Laboratuvarı',
        description:
            'Geliştirme, test, prototipleme ve dijital üretim yetkinliğimizin '
            'merkezi.',
        primaryLabel: 'DML’yi İncele',
        primaryRoute: SiteRoutes.teknolojilerDml,
      ),
    ],
  ),

  SiteRoutes.teknolojilerDml: SitePageContent(
    eyebrow: 'DML',
    title: 'Dijital Üretim Laboratuvarı',
    description:
        'DML, OPTIYOU’nun üretim ve geliştirme omurgasıdır. Yeni ürün yapıları '
        'burada geliştirilir, test edilir ve doğrulanır.',
    blocks: [
      SiteImageTextBlock(
        eyebrow: 'DML',
        title: 'Geliştirme, prototipleme, üretim doğrulama',
        body:
            'DML; yeni bir ürün yapısını tasarımdan saha doğrulamasına taşıyan '
            'kapalı döngüdür. CNC işleme, eklemeli üretim ve dijital tasarım '
            'yetkinlikleri aynı çatı altındadır.',
        image: '$_genDir/dml-cnc-lab.webp',
        imageAlt: 'CNC üretim laboratuvarından görünüm',
        contain: false,
      ),
      SiteFeaturesBlock(
        items: [
          (title: 'Geliştirme', body: 'Yeni ürün yapılarının tasarlanması.'),
          (title: 'Test', body: 'Dayanım, uyum ve konfor testleri.'),
          (title: 'Prototipleme', body: 'Hızlı prototip üretimi ve revizyon.'),
          (
            title: 'Dijital üretim yetkinliği',
            body: 'Sayısal üretim hattıyla tekrarlanabilir çıktı.',
          ),
          (
            title: 'Malzeme ve numune',
            body:
                'Doğrulanmış malzeme ve numuneler; makine modelleri belge '
                'sağlandığında yayımlanır.',
          ),
          (
            title: 'Kalite akışı',
            body: 'Saha geri bildirimiyle doğrulama döngüsü.',
          ),
        ],
      ),
      _contactCta,
    ],
  ),

  // ── Çözümler (ortak şablon) ──────────────────────────────────────────────
  SiteRoutes.cozumlerKlinikler: SitePageContent(
    eyebrow: 'Çözümler',
    title: 'Klinikler',
    description:
        'Ölçüm, değerlendirme, ürün süreci ve hasta takibini tek akışta '
        'yönetin.',
    blocks: [
      SiteImageTextBlock(
        eyebrow: 'İş akışı',
        title: 'Ölçümden rapora, tek panel',
        body:
            'Kliniğinize kurulan 3D tarama ve plantar basınç istasyonuyla '
            'ölçüm verileri dijital ortamda kayda alınır. Uzman etiketli veri '
            've yapay zekâ destekli değerlendirmeyle ürün ihtiyacı belirlenir.',
        image: '$_srcDir/real-scan-session.png',
        imageAlt: 'Klinik içinde 3D tarama oturumu',
      ),
      SiteFeaturesBlock(
        items: [
          (
            title: 'Ölçüm istasyonu',
            body: 'Klinik içinde 3D tarama ve plantar basınç ölçümü.',
          ),
          (
            title: 'Yetkilendirme',
            body: 'Kullanıcı profili ve rol bazlı erişim.',
          ),
          (
            title: 'Ürün süreci',
            body: 'Yapı belirlemeden üretime uçtan uca izlenebilirlik.',
          ),
          (
            title: 'Rapor paylaşımı',
            body: 'Ölçüm sonuçlarının anlaşılır biçimde iletilmesi.',
          ),
        ],
      ),
      SiteFaqBlock(
        title: 'Sık sorulanlar',
        items: [
          (
            question: 'Kurulum ne içerir?',
            answer:
                'Tarama ve basınç ölçüm donanımı, panel erişimi ve ekip '
                'eğitimi birlikte planlanır.',
          ),
          (
            question: 'Veriler nasıl korunuyor?',
            answer:
                'Ölçüm verisi erişim yetkileriyle saklanır; ayrıntılar '
                'Aydınlatma Metni’nde yer alır.',
          ),
        ],
      ),
      _contactCta,
    ],
  ),

  SiteRoutes.cozumlerEczaneler: SitePageContent(
    eyebrow: 'Çözümler',
    title: 'Eczaneler ve Ayakkabı Mağazaları',
    description:
        'Mağaza içinde hızlı tarama ile müşteriyi doğru ürün ailesine '
        'yönlendirin.',
    blocks: [
      SiteImageTextBlock(
        eyebrow: 'Mağaza içi',
        title: 'Küçük alana kurulan tarama noktası',
        body:
            'İki dakikalık ölçümle müşteri, kullanım senaryosuna uygun ürün '
            'ailesine yönlendirilir. Ürün seçimi ölçüm sonucuyla eşleşir.',
        image: '$_genDir/solution-retail-scan.webp',
        imageAlt: 'Perakende alanında tarama noktası',
        contain: false,
        imageRight: true,
      ),
      SiteFeaturesBlock(
        items: [
          (
            title: 'Stand alanı',
            body: 'Küçük alana kurulabilen ölçüm noktası.',
          ),
          (
            title: 'Personel akışı',
            body: 'Kısa eğitimle mağaza ekibi ölçümü yönetir.',
          ),
          (
            title: 'Ürün yönlendirme',
            body: 'Ölçüm sonucuna göre uygun ürün ailesi önerilir.',
          ),
          (
            title: 'Satış sonrası',
            body: 'Kullanıcı geri bildirimi ve tekrar ölçüm.',
          ),
        ],
      ),
      SiteCtaBlock(
        title: 'İşletmeniz için tarama standı',
        description: 'Kurulum, eğitim ve süreç desteğini birlikte planlayalım.',
        primaryLabel: 'Tarama Standı İçin Başvur',
        primaryRoute: SiteRoutes.taramaStandiBasvuru,
        secondaryLabel: 'İletişime Geç',
        secondaryRoute: SiteRoutes.iletisim,
      ),
    ],
  ),

  SiteRoutes.cozumlerIsYerleri: SitePageContent(
    eyebrow: 'Çözümler',
    title: 'İş Yerleri',
    description:
        'Gün boyu ayakta çalışan ekipler için toplu ölçüm ve takip programı.',
    blocks: [
      SiteImageTextBlock(
        eyebrow: 'Saha programı',
        title: 'Çalışma alanında toplu ölçüm günü',
        body:
            'Taşınabilir tarama istasyonuyla ekibin ayak verileri toplu olarak '
            'ölçülür. Departman ve vardiya bazında özetlenen bulgulara göre '
            'uygun ürün ailesi belirlenir.',
        image: '$_genDir/solution-workplace-scan.webp',
        imageAlt: 'İş yerinde toplu ölçüm istasyonu',
        contain: false,
      ),
      SiteFeaturesBlock(
        items: [
          (
            title: 'Planlama',
            body: 'Vardiya takvimine göre ölçüm günü kurgusu.',
          ),
          (
            title: 'Çalışan grubu',
            body: 'Görev bazında ürün ihtiyacının belirlenmesi.',
          ),
          (
            title: 'Toplu dashboard',
            body: 'Departman kırılımıyla özet raporlama.',
          ),
          (
            title: 'Periyodik takip',
            body: 'Dönemsel ölçümle değişimin izlenmesi.',
          ),
        ],
      ),
      _contactCta,
    ],
  ),

  SiteRoutes.cozumlerBireysel: SitePageContent(
    eyebrow: 'Çözümler',
    title: 'Bireysel Kullanıcılar',
    description:
        'Kendi ayak profilini çıkar, kullanım senaryona uygun ürünü seç, '
        'süreci takip et.',
    blocks: [
      SiteImageTextBlock(
        eyebrow: 'Deneyim',
        title: 'Ayak profilini görün',
        body:
            'En yakın ölçüm merkezinde iki dakikalık tarama; ardından ölçüm '
            'sonucunuz anlaşılır bir profile dönüşür ve uygun ürün aileleri '
            'öne çıkar.',
        image: '$_genDir/hero-biomechanical-scan.webp',
        imageAlt: 'Bireysel kullanıcı için 3D ayak tarama',
        contain: false,
      ),
      SiteStepsBlock(
        steps: [
          (
            number: '01',
            title: 'Hazırlık',
            body: 'Rahat çorap ve günlük ayakkabıyla gelin; ölçüm çıplak ayak.',
          ),
          (
            number: '02',
            title: 'Ölçüm günü',
            body: '3D tarama ve plantar basınç ölçümü toplam iki dakika.',
          ),
          (
            number: '03',
            title: 'Teslimat',
            body: 'Uygun yapı üretilir, kargoya verilir ve takip edilir.',
          ),
        ],
      ),
      _scanCta,
    ],
  ),

  // ── TÜBİTAK ─────────────────────────────────────────────────────────────
  SiteRoutes.tubitak: SitePageContent(
    eyebrow: 'Ar-Ge',
    title: 'TÜBİTAK Projelerimiz',
    description:
        'Ürün ve üretim teknolojilerimizi geliştiren destekli Ar-Ge '
        'çalışmalarımız.',
    blocks: [
      SiteProjectsBlock(
        projects: [
          (
            code: '1812',
            title: 'Yenilikçi Ürünler ve Üretim Teknolojileri',
            description:
                'Yeni ürün yapıları ve bunları üretebilen dijital üretim '
                'yetkinliklerinin geliştirilmesi.',
            route: SiteRoutes.tubitak1812,
          ),
          (
            code: '1707',
            title: 'Siparişe Dayalı Ar-Ge Projesi',
            description:
                'Siparişe dayalı üretim modelinin ve ölçüm-üretim '
                'entegrasyonunun geliştirilmesi.',
            route: SiteRoutes.tubitak1707,
          ),
        ],
      ),
      SiteFeaturesBlock(
        columns: 2,
        items: [
          (
            title: 'Ortak omurga',
            body:
                'İki proje de ölçüm verisini dijital üretime bağlayan aynı '
                'zincir üzerinde ilerler.',
          ),
          (
            title: 'Doğrulama',
            body:
                'Çıktılar saha geri bildirimiyle doğrulanır; pazar veya klinik '
                'fayda rakamı paylaşılmaz.',
          ),
        ],
      ),
    ],
  ),

  SiteRoutes.tubitak1812: SitePageContent(
    eyebrow: 'TÜBİTAK 1812',
    title: 'Yenilikçi Ürünler ve Üretim Teknolojileri',
    description:
        'Yeni ürün yapılarının ve bunları üretebilen dijital üretim '
        'yetkinliklerinin geliştirilmesini kapsar.',
    blocks: [
      SiteFeaturesBlock(
        columns: 2,
        items: [
          (
            title: 'Problem',
            body:
                'Standart numaralandırmanın kullanım senaryolarına yetmemesi '
                've üretim esnekliği ihtiyacı.',
          ),
          (
            title: 'Yaklaşım',
            body:
                'Katman mimarisi ve dijital üretim akışının birlikte '
                'geliştirilmesi.',
          ),
          (
            title: 'Teknik çıktılar',
            body:
                'Doğrulanmış ürün yapıları ve tekrarlanabilir üretim süreçleri.',
          ),
          (
            title: 'Ticarileşme yönü',
            body:
                'Çıktıların OPTIYOU ürün ailelerine ve iş ortağı ağına '
                'aktarılması.',
          ),
        ],
      ),
      SiteFigureBlock(
        image: '$_srcDir/real-cnc-production.png',
        imageAlt: 'Proje kapsamında dijital üretim',
        caption: 'Dijital üretim doğrulaması.',
      ),
    ],
  ),

  SiteRoutes.tubitak1707: SitePageContent(
    eyebrow: 'TÜBİTAK 1707',
    title: 'Siparişe Dayalı Ar-Ge Projesi',
    description:
        'Müşteri kuruluş iş birliğiyle yürütülen, siparişe dayalı üretim '
        'modelinin geliştirilmesine yönelik Ar-Ge çalışması.',
    blocks: [
      SiteFeaturesBlock(
        columns: 2,
        items: [
          (
            title: 'Müşteri kuruluş',
            body: 'Mekap iş birliğiyle ölçüm-üretim entegrasyonu senaryosu.',
          ),
          (
            title: 'Ölçüm sistemi',
            body:
                '3D tarama ve plantar basınç verisinin tek akışta toplanması.',
          ),
          (
            title: 'Anatomik kategorileme',
            body:
                'Uzman etiketli veriyle yapay zekâ destekli sınıf ve temsilî '
                'uyum skoru.',
          ),
          (
            title: 'Üç tip seri kalıp',
            body:
                'Sık görülen yapılar için hazır kalıp; dışına düşen durumlarda '
                'dijital üretim fallback.',
          ),
        ],
      ),
      SiteFeaturesBlock(
        columns: 2,
        items: [
          (
            title: 'Doğrulama',
            body:
                'Uzman etiketli veriyle sınıf tutarlılığı ölçülür; sayısal '
                'metrikler doğrulama raporuyla yayımlanır.',
          ),
          (
            title: 'Çıktı',
            body: 'Üretim planlama ve izlenebilirlik yetkinlikleri.',
          ),
        ],
      ),
    ],
  ),

  // ── Ölçüm merkezleri & başvuru ──────────────────────────────────────────
  SiteRoutes.olcumMerkezleri: SitePageContent(
    eyebrow: 'Ölçüm Merkezleri',
    title: 'Sana en yakın ölçüm noktası',
    description:
        'Tarama ve plantar basınç ölçümü anlaşmalı klinik, eczane ve '
        'mağazalarda yapılır. Ölçüm yaklaşık iki dakika sürer.',
  ),

  SiteRoutes.taramaStandiBasvuru: SitePageContent(
    eyebrow: 'Başvuru',
    title: 'Tarama Standı İçin Başvur',
    description:
        'İşletmenize tarama standı kurulumu için başvurun. Kurulum, eğitim ve '
        'süreç desteğini birlikte planlayalım.',
  ),

  // ── Kurumsal ────────────────────────────────────────────────────────────
  SiteRoutes.hakkimizda: SitePageContent(
    eyebrow: 'Kurumsal',
    title: 'Ürün seçimini tahmine değil, veriye dayandırıyoruz',
    description:
        'OPTIYOU; dijital ayak ölçümü, veri güdümlü değerlendirme, uygun ürün '
        'seçimi, dijital üretim ve takip altyapısını bir araya getiren bir '
        'ayak giyim teknolojileri platformudur.',
    blocks: [
      SiteImageTextBlock(
        eyebrow: 'Yaklaşım',
        title: 'Ölçüm, değerlendirme ve üretim tek zincirde',
        body:
            'Tarama donanımından dijital üretim laboratuvarına kadar tüm '
            'adımlar aynı veri zinciri üzerinde çalışır. Ölçümden üretim '
            'dosyasına elle veri aktarımı yapılmaz.',
        image: '$_srcDir/real-dashboard-composite.png',
        imageAlt: 'Dijital takip özeti görünümü',
      ),
      SiteFeaturesBlock(
        items: [
          (
            title: 'Yaklaşımımız',
            body: 'Ürün seçimini ölçüme ve veriye dayandırıyoruz.',
          ),
          (
            title: 'Üretim',
            body:
                'Dijital üretim laboratuvarımızda (DML) geliştirme ve üretim '
                'yapıyoruz.',
          ),
          (
            title: 'İş birlikleri',
            body:
                'Klinik, eczane, mağaza ve iş yerleriyle ortak ölçüm ağı '
                'kuruyoruz.',
          ),
          (
            title: 'Ar-Ge',
            body:
                'Destekli Ar-Ge projeleriyle ürün ve süreçleri geliştiriyoruz.',
          ),
        ],
      ),
      _contactCta,
    ],
  ),

  SiteRoutes.ekibimiz: SitePageContent(
    eyebrow: 'Kurumsal',
    title: 'Ekibimiz',
    description:
        'Mühendislik, üretim, sağlık ve yazılım alanlarından gelen bir ekip.',
    blocks: [
      SitePlaceholderBlock(
        label: 'Ekip kartları',
        note:
            'Kişi kartları, ekip verisi ve paylaşılabilir fotoğraflar '
            'sağlandığında eklenecektir. Gerçek olmayan kişi/fotoğraf '
            'üretilmez.',
      ),
      _contactCta,
    ],
  ),

  SiteRoutes.kariyer: SitePageContent(
    eyebrow: 'Kurumsal',
    title: 'Kariyer',
    description:
        'Ölçüm, üretim ve yazılım alanlarında birlikte çalışacak takım '
        'arkadaşları arıyoruz.',
    blocks: [
      SiteFeaturesBlock(
        items: [
          (
            title: 'Kültür',
            body: 'Küçük ekip, kısa geri bildirim döngüleri, ölçülebilir iş.',
          ),
          (title: 'Alanlar', body: 'Donanım, üretim, veri, mobil ve web.'),
          (
            title: 'Genel başvuru',
            body: 'Açık pozisyon olmasa da başvurunuzu iletebilirsiniz.',
          ),
        ],
      ),
      SitePlaceholderBlock(
        label: 'Açık pozisyonlar',
        note: 'Pozisyon listesi güncellendiğinde bu alan doldurulacaktır.',
      ),
      _contactCta,
    ],
  ),

  SiteRoutes.haberler: SitePageContent(
    eyebrow: 'Kurumsal',
    title: 'Haberler / Basın',
    description: 'Duyurular, basın bültenleri ve etkinlik notları.',
  ),

  SiteRoutes.blog: SitePageContent(
    eyebrow: 'Keşfet',
    title: 'Blog',
    description: 'Ayak profili, ölçüm ve ürün seçimi üzerine yazılar.',
    blocks: [SitePlaceholderBlock(label: 'Blog yazıları')],
  ),

  SiteRoutes.sss: SitePageContent(
    eyebrow: 'Destek',
    title: 'Sıkça Sorulan Sorular',
    description:
        'Ölçüm, ürün ve teslimat süreciyle ilgili sık sorulan sorular.',
    blocks: [
      SiteFaqBlock(
        items: [
          (
            question: 'Tarama ne kadar sürer?',
            answer: '3D tarama ve plantar basınç ölçümü toplam iki dakika.',
          ),
          (
            question: 'Ölçüm nerede yapılır?',
            answer:
                'Anlaşmalı klinik, eczane ve mağazalardaki ölçüm '
                'noktalarında.',
          ),
          (
            question: 'Randevuya nasıl hazırlanmalıyım?',
            answer:
                'Rahat bir çorap ve günlük ayakkabınızla gelin; ölçüm çıplak '
                'ayak yapılır.',
          ),
          (
            question: 'Ürün ne zaman teslim edilir?',
            answer:
                'Üretim tamamlandıktan sonra kargoya verilir; süreç '
                'hesabınızdan takip edilebilir.',
          ),
          (
            question: 'Uyum skoru bir teşhis mi?',
            answer:
                'Hayır. Temsilî bir göstergedir; bilgilendirme amaçlıdır ve '
                'klinik tanı yerine geçmez.',
          ),
          (
            question: 'Ölçüm verim nasıl korunuyor?',
            answer:
                'Veriler erişim yetkileriyle korunur; ayrıntılar Aydınlatma '
                'Metni’nde yer alır.',
          ),
        ],
      ),
      _scanCta,
    ],
  ),

  SiteRoutes.iletisim: SitePageContent(
    eyebrow: 'İletişim',
    title: 'Bize ulaşın',
    description:
        'Kurumsal iş birliği, tarama standı başvurusu ve ürün soruları için '
        'iletişime geçebilirsiniz.',
  ),

  // ── Yasal metinler (mevcut belge kayıtlarından) ────────────────────────
  SiteRoutes.kvkk: SitePageContent(
    eyebrow: 'Yasal',
    title: 'KVKK Aydınlatma Metni',
    description: 'Kişisel verilerin işlenmesine ilişkin aydınlatma metni.',
    blocks: [SiteLegalBlock(documentCode: LegalDocumentCodes.aydinlatmaMetni)],
  ),

  SiteRoutes.gizlilik: SitePageContent(
    eyebrow: 'Yasal',
    title: 'Gizlilik Politikası',
    description: 'Gizlilik ve güvenlik uygulamalarımız.',
    blocks: [SiteLegalBlock(documentCode: LegalDocumentCodes.gizlilikGuvenlik)],
  ),

  SiteRoutes.kullanimKosullari: SitePageContent(
    eyebrow: 'Yasal',
    title: 'Kullanım Koşulları',
    description: 'Siteyi ve hizmetleri kullanım koşulları.',
    blocks: [
      SiteLegalBlock(documentCode: LegalDocumentCodes.kullanimKosullari),
    ],
  ),
};
