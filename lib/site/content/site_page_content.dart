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

  const SiteHeadingBlock({
    required this.eyebrow,
    required this.title,
    this.description,
  });
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
  final List<
      ({String image, String title, String description, String route})> products;

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
  primaryLabel: 'Randevu Al',
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
/// Kapsam notu: bu sürümde ana sayfa tam içerikli, menü sayfaları ise
/// spesifikasyondaki başlık ve mesaj iskeletiyle üretilmiştir. Uzun metinler
/// ve görseller ilerleyen aşamada doldurulacaktır.
const Map<String, SitePageContent> sitePageContent = {
  // ── Nasıl Çalışır? ─────────────────────────────────────────────────────────
  SiteRoutes.nasilCalisir: SitePageContent(
    eyebrow: 'Süreç',
    title: 'Ölçümden teslimata kadar nasıl çalışır?',
    description:
        'Tarama, basınç ölçümü, değerlendirme, ürün seçimi, üretim ve takip; '
        'hepsi tek veri akışı üzerinde ilerler.',
    blocks: [
      SiteFeaturesBlock(
        columns: 2,
        items: [
          (
            title: '01 · Ölçüm',
            body:
                'Ayak geometrisi 3D tarama ile kaydedilir, basış dağılımı '
                'basınç ölçümüyle görünür hâle gelir.',
          ),
          (
            title: '02 · Değerlendirme',
            body:
                'Ölçüm verisi sınıflandırılır; uzunluk, genişlik, kemer profili '
                've adım yönelimi birlikte okunur.',
          ),
          (
            title: '03 · Ürün Seçimi',
            body:
                'Ayak profiline uygun ürün ailesi ve yapı önerilir. Seçim tek '
                'bir ölçüye değil, çok parametreli değerlendirmeye dayanır.',
          ),
          (
            title: '04 · Üretim',
            body:
                'Ürün, dijital üretim laboratuvarımızda hazırlanır ve kalite '
                'kontrolünden geçer.',
          ),
          (
            title: '05 · Teslimat',
            body:
                'Sipariş kargoya verilir; süreç adım adım takip edilebilir.',
          ),
          (
            title: '06 · Dijital Takip',
            body:
                'Sonraki ölçümlerle değişim izlenir; geri bildirim ürün '
                'seçimini güncellemeye yardımcı olur.',
          ),
        ],
      ),
      _scanCta,
    ],
  ),

  // ── Ürünler ────────────────────────────────────────────────────────────────
  SiteRoutes.tabanliklar: SitePageContent(
    eyebrow: 'Ürünler',
    title: 'Tabanlık ve ürün ailelerimiz',
    description:
        'Günlük kullanım, spor, toparlanma ve ayakta çalışma senaryoları için '
        'geliştirilen ürün aileleri.',
    blocks: [
      SiteProductsBlock(
        products: [
          (
            image: 'assets/images/products/custom_insole.png',
            title: 'Veri Güdümlü Anatomik Tabanlık',
            description:
                'Günlük kullanım için tasarlandı. Ayak yapına uyum sağlar, gün '
                'boyu konfor sunar.',
            route: SiteRoutes.tabanliklarGunluk,
          ),
          (
            image: 'assets/images/products/sport_insole.png',
            title: 'Sporcular İçin Karbon Fiber Tabanlık',
            description:
                'Hafif karbon fiber tabanla performansını artırır, darbe '
                'emilimini destekler.',
            route: SiteRoutes.tabanliklarSpor,
          ),
          (
            image: 'assets/images/products/recovery_sandal.png',
            title: 'OY Recovery Anatomik Toparlayıcı Sandalet',
            description:
                'SLA 3B teknolojisiyle kafes yapılı tasarım, hafiflik ve '
                'toparlayıcı destek sağlar.',
            route: SiteRoutes.tabanliklarRecovery,
          ),
          (
            image: 'assets/images/products/personal_shoe.png',
            title: 'Veri Güdümlü Ortopedik İş Ayakkabısı',
            description:
                'Uzun süre ayakta çalışan kullanıcılar için geliştirilen model.',
            route: SiteRoutes.isAyakkabisi,
          ),
        ],
      ),
      _scanCta,
    ],
  ),

  SiteRoutes.tabanliklarGunluk: SitePageContent(
    eyebrow: 'Günlük Tabanlıklar',
    title: 'Veri Güdümlü Anatomik Tabanlık',
    description:
        'Gün boyu kullanım için tasarlandı. Ayak yapına uyum sağlar, basış '
        'dağılımını dengelemeye yardımcı olur.',
    blocks: [
      SiteFeaturesBlock(
        items: [
          (
            title: 'Kullanım',
            body: 'Günlük ayakkabı, iş ayakkabısı ve şehir içi yürüyüş.',
          ),
          (
            title: 'Yapı',
            body:
                'Ayak profiline göre seçilen kemer desteği ve darbe emici taban.',
          ),
          (
            title: 'Uyum',
            body:
                'Uygun yapı, tarama ve basınç ölçümü sonucuna göre belirlenir.',
          ),
          (
            title: 'Bakım',
            body: 'Nemli bezle temizlenir, doğrudan ısı kaynağından uzak tutulur.',
          ),
        ],
      ),
      SitePlaceholderBlock(
        label: 'Ürün detay görselleri',
        note:
            'Marka onaylı ürün render seti sağlandığında bu alan görsellerle '
            'değiştirilecektir.',
      ),
      _scanCta,
    ],
  ),

  SiteRoutes.tabanliklarSpor: SitePageContent(
    eyebrow: 'Spor Tabanlıkları',
    title: 'Sporcular İçin Karbon Fiber Tabanlık',
    description:
        'Hafif karbon fiber taban yapısı ile destek ve darbe emilimini bir '
        'arada sunar.',
    blocks: [
      SiteFeaturesBlock(
        items: [
          (
            title: 'Kullanım',
            body: 'Koşu, saha sporları ve yüksek tempolu antrenman.',
          ),
          (
            title: 'Yapı',
            body: 'Karbon fiber taban, hedefli destek bölgeleri.',
          ),
          (
            title: 'Ölçüm',
            body:
                'Basış dağılımı ve adım yönelimi verisi ürün seçimini belirler.',
          ),
          (
            title: 'Takip',
            body: 'Periyodik ölçümle değişim izlenebilir.',
          ),
        ],
      ),
      SitePlaceholderBlock(label: 'Spor tabanlığı detay görselleri'),
      _scanCta,
    ],
  ),

  SiteRoutes.tabanliklarRecovery: SitePageContent(
    eyebrow: 'Recovery',
    title: 'OY Recovery Anatomik Toparlayıcı Sandalet',
    description:
        'SLA 3B teknolojisiyle üretilen kafes yapılı tasarım; hafiflik ve '
        'toparlayıcı destek sağlar.',
    blocks: [
      SiteFeaturesBlock(
        items: [
          (
            title: 'Kullanım',
            body: 'Antrenman sonrası, uzun mesai sonrası ve ev içi kullanım.',
          ),
          (
            title: 'Üretim',
            body: 'SLA 3B baskı ile kafes yapılı gövde.',
          ),
          (
            title: 'Hafiflik',
            body: 'Kafes yapısı, ağırlığı düşürürken desteği korur.',
          ),
          (
            title: 'Konfor',
            body: 'Ayak tabanına yayılan temas yüzeyi.',
          ),
        ],
      ),
      SitePlaceholderBlock(label: 'Recovery sandalet detay görselleri'),
      _scanCta,
    ],
  ),

  SiteRoutes.isAyakkabisi: SitePageContent(
    eyebrow: 'İş Ayakkabısı',
    title: 'Veri Güdümlü Ortopedik İş Ayakkabısı',
    description:
        'Uzun süre ayakta çalışan kullanıcılar için geliştirilen, ölçüm '
        'verisine göre seçilen model.',
    blocks: [
      SiteFeaturesBlock(
        items: [
          (
            title: 'Kimler için?',
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
                'İş yerlerinde toplu ölçüm ve takip programı ile birlikte '
                'kurgulanabilir.',
          ),
          (
            title: 'Takip',
            body: 'Periyodik ölçümle konfor geri bildirimi izlenir.',
          ),
        ],
      ),
      SitePlaceholderBlock(label: 'İş ayakkabısı ürün görselleri'),
      _contactCta,
    ],
  ),

  // ── Anatomik Kategorilerimiz (Superspec §9 — zorunlu içerik) ───────────────
  SiteRoutes.anatomikKategoriler: SitePageContent(
    eyebrow: 'Anatomik Kategoriler',
    title: 'Numara Yalnızca Başlangıçtır',
    description:
        'Aynı ayakkabı numarası, farklı ayaklarda aynı uyumu garanti etmez. '
        'Doğru seçim çok parametreli bir değerlendirmeye dayanır.',
    blocks: [
      SiteBulletsBlock(
        title: 'Neden numara tek başına yeterli değil?',
        bullets: [
          'Aynı ayakkabı numarası, farklı ayaklarda aynı uyumu garanti etmez.',
          'Uzunluk ve genişlik, ayağın tüm yapısını açıklamak için yeterli '
              'değildir.',
          'Ayak yapısı yük altında değişir.',
          'Gün içi değişim, zemin etkisi ve sağ-sol farkı dikkate alınmalıdır.',
          'Ayak seçimi tek bir ölçüye değil, çok parametreli değerlendirmeye '
              'dayanmalıdır.',
        ],
      ),
      SiteBulletsBlock(
        title: 'Uyum çalışmalarından öne çıkan noktalar',
        bullets: [
          'Aynı numara ayakkabılar arasında belirgin iç uzunluk farkları '
              'olabilir.',
          'İç genişlik ve hacim farkları da kullanıcı deneyimini etkiler.',
          'Standart numaralandırma her kullanıcı için yeterli değildir.',
          'Doğru seçim için yalnızca numara değil, ayak profili de önemlidir.',
        ],
        note:
            'Bu maddeler ilgili uyum çalışmalarının kısa özetidir; tam alıntı '
            'içermez.',
      ),
      SiteHeadingBlock(
        eyebrow: 'Kategori Sistemi',
        title: 'Teşhis değil, uyum sınıfı',
        description:
            'Kategoriler ürün seçimini kolaylaştırmak için tanımlanır. Tıbbi '
            'bir sınıflandırma değildir.',
      ),
      SiteFeaturesBlock(
        columns: 3,
        items: [
          (title: 'Temel uzunluk', body: 'Ayağın temel ölçü aralığı.'),
          (title: 'Ön ayak formu', body: 'Ön ayak genişliği ve parmak dizilimi.'),
          (title: 'Kemer profili', body: 'Kemer yüksekliği ve destek ihtiyacı.'),
          (title: 'Adım yönelimi', body: 'Basış sırasında ağırlığın yönü.'),
          (title: 'Konfor odağı', body: 'Kullanım senaryosuna göre öncelik.'),
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
      _scanCta,
    ],
  ),

  // ── Teknolojilerimiz (Superspec §10) ──────────────────────────────────────
  SiteRoutes.teknolojiler: SitePageContent(
    eyebrow: 'Teknolojilerimiz',
    title: 'Ölçümü, değerlendirmeyi ve üretimi bir arada tutan altyapı',
    description:
        'Tarama donanımından üretim laboratuvarına kadar tüm adımlar aynı veri '
        'zinciri üzerinde çalışır.',
    blocks: [
      SiteFeaturesBlock(
        items: [
          (
            title: '3D Ayak Tarama',
            body: 'Ayak geometrisinin üç boyutlu olarak kaydedilmesi.',
          ),
          (
            title: 'Basınç Ölçümü',
            body:
                'Basış dağılımının ölçülmesi ve görünür hâle getirilmesi.',
          ),
          (
            title: 'Yapay Zekâ Destekli Değerlendirme',
            body:
                'Ölçüm verisinin sınıflandırılması ve uygun ürün yapısının '
                'belirlenmesi.',
          ),
          (
            title: 'Üretim ve Tarama Teknolojilerimiz',
            body: 'Tarama donanımı ve dijital üretim hattı.',
          ),
          (
            title: 'Kalite ve Doğruluk',
            body: 'Ölçüm doğruluğu ve tekrarlanabilirlik kontrolleri.',
          ),
          (
            title: 'Veri Güvenliği',
            body:
                'Ölçüm verisinin saklanması, erişim yetkileri ve korunması.',
          ),
        ],
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
        'DML, OPTIYOU’nun üretim ve geliştirme omurgasıdır. Yeni ürünler '
        'burada geliştirilir, test edilir ve doğrulanır.',
    blocks: [
      SiteFeaturesBlock(
        items: [
          (title: 'Geliştirme', body: 'Yeni ürün yapılarının tasarlanması.'),
          (title: 'Test', body: 'Dayanım, uyum ve konfor testleri.'),
          (title: 'Prototipleme', body: 'Hızlı prototip üretimi ve revizyon.'),
          (
            title: 'Dijital üretim yetkinliği',
            body: 'Sayısal üretim hattı ile tekrarlanabilir çıktı.',
          ),
          (
            title: 'Yeni ürün doğrulama',
            body: 'Saha geri bildirimiyle doğrulama döngüsü.',
          ),
        ],
      ),
      SitePlaceholderBlock(
        label: 'DML tesis ve makine fotoğrafları',
        note:
            'Gerçek tesis fotoğrafları için marka onaylı görsel seti '
            'gerekmektedir.',
      ),
      _contactCta,
    ],
  ),

  // ── Çözümler ───────────────────────────────────────────────────────────────
  SiteRoutes.cozumlerKlinikler: SitePageContent(
    eyebrow: 'Çözümler',
    title: 'Klinikler',
    description:
        'Ölçüm, değerlendirme, ürün süreci ve hasta takibini tek akışta '
        'yönetin.',
    blocks: [
      SiteFeaturesBlock(
        items: [
          (
            title: 'Ölçüm istasyonu',
            body: 'Klinik içinde 3D tarama ve basınç ölçümü.',
          ),
          (
            title: 'Kayıt ve takip',
            body: 'Ölçüm geçmişi ve süreç durumu tek panelde.',
          ),
          (
            title: 'Ürün süreci',
            body: 'Uygun ürünün belirlenmesinden üretime kadar izlenebilirlik.',
          ),
          (
            title: 'Raporlama',
            body: 'Ölçüm sonuçlarının anlaşılır biçimde paylaşılması.',
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
        'Mağaza içinde hızlı tarama ile müşteriyi doğru ürüne yönlendirin.',
    blocks: [
      SiteFeaturesBlock(
        items: [
          (
            title: 'Tarama standı',
            body: 'Küçük alana kurulabilen ölçüm noktası.',
          ),
          (
            title: 'Hızlı yönlendirme',
            body: 'İki dakikalık ölçümle uygun ürün ailesine yönlendirme.',
          ),
          (
            title: 'Stok uyumu',
            body: 'Ürün seçiminin ölçüm sonucuyla eşleştirilmesi.',
          ),
          (
            title: 'Satış sonrası',
            body: 'Kullanıcı geri bildirimi ve tekrar ölçüm.',
          ),
        ],
      ),
      _contactCta,
    ],
  ),

  SiteRoutes.cozumlerIsYerleri: SitePageContent(
    eyebrow: 'Çözümler',
    title: 'İş Yerleri',
    description:
        'Gün boyu ayakta çalışan ekipler için toplu ölçüm ve takip programı.',
    blocks: [
      SiteFeaturesBlock(
        items: [
          (
            title: 'Toplu ölçüm günü',
            body: 'Çalışma alanında kurulan geçici ölçüm noktası.',
          ),
          (
            title: 'Departman kırılımı',
            body: 'Görev ve vardiya bazında eğilimlerin özetlenmesi.',
          ),
          (
            title: 'Ürün programı',
            body: 'Çalışan grubuna uygun ürün ailelerinin belirlenmesi.',
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
        'Kendi ayak profilini çıkar, yürüyüşüne uygun ürünü seç, süreci takip '
        'et.',
    blocks: [
      SiteFeaturesBlock(
        items: [
          (
            title: 'Tarama',
            body: 'En yakın ölçüm merkezinde iki dakikalık tarama.',
          ),
          (
            title: 'Ayak profili',
            body: 'Ölçüm sonucunun anlaşılır bir profile dönüşmesi.',
          ),
          (
            title: 'Ürün seçimi',
            body: 'Profiline uygun ürün ailelerinin öne çıkarılması.',
          ),
          (
            title: 'Takip',
            body: 'Sipariş durumunun ve sonraki ölçümlerin izlenmesi.',
          ),
        ],
      ),
      _scanCta,
    ],
  ),

  // ── TÜBİTAK ────────────────────────────────────────────────────────────────
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
            title: 'Yenilikçi Ürünler ve Üretim Teknolojileri Projesi',
            description:
                'Yeni ürün yapıları ve üretim teknolojilerinin geliştirilmesine '
                'odaklanır.',
            route: SiteRoutes.tubitak1812,
          ),
          (
            code: '1707',
            title: 'Siparişe Dayalı Ar-Ge Projesi',
            description:
                'Siparişe dayalı üretim modelinin geliştirilmesini kapsar.',
            route: SiteRoutes.tubitak1707,
          ),
        ],
      ),
    ],
  ),

  SiteRoutes.tubitak1812: SitePageContent(
    eyebrow: 'TÜBİTAK 1812',
    title: 'Yenilikçi Ürünler ve Üretim Teknolojileri Projesi',
    description:
        'Yeni ürün yapılarının ve bunları üretebilen dijital üretim '
        'yetkinliklerinin geliştirilmesini kapsar.',
    blocks: [
      SiteFeaturesBlock(
        items: [
          (
            title: 'Kapsam',
            body: 'Ürün geliştirme ve üretim teknolojisi çalışmaları.',
          ),
          (
            title: 'Çıktı',
            body: 'Doğrulanmış ürün yapıları ve üretim süreçleri.',
          ),
        ],
      ),
      SitePlaceholderBlock(
        label: 'Proje görselleri',
        note: 'Proje kapsamına ait paylaşılabilir görseller eklenecektir.',
      ),
    ],
  ),

  SiteRoutes.tubitak1707: SitePageContent(
    eyebrow: 'TÜBİTAK 1707',
    title: 'Siparişe Dayalı Ar-Ge Projesi',
    description:
        'Siparişe dayalı üretim modelinin geliştirilmesine yönelik Ar-Ge '
        'çalışması.',
    blocks: [
      SiteFeaturesBlock(
        items: [
          (
            title: 'Kapsam',
            body: 'Siparişe dayalı üretim akışının geliştirilmesi.',
          ),
          (
            title: 'Çıktı',
            body: 'Üretim planlama ve izlenebilirlik yetkinlikleri.',
          ),
        ],
      ),
      SitePlaceholderBlock(label: 'Proje görselleri'),
    ],
  ),

  // ── Ölçüm merkezleri & başvuru ────────────────────────────────────────────
  SiteRoutes.olcumMerkezleri: SitePageContent(
    eyebrow: 'Ölçüm Merkezleri',
    title: 'Sana en yakın ölçüm noktası',
    description:
        'Tarama ve basınç ölçümü, anlaşmalı klinik, eczane ve mağazalarda '
        'yapılır. Ölçüm iki dakika sürer.',
    blocks: [
      SitePlaceholderBlock(
        label: 'Ölçüm merkezleri listesi / harita',
        note:
            'Merkez listesi veri kaynağı bağlandığında bu alan doldurulacaktır.',
      ),
      _contactCta,
    ],
  ),

  SiteRoutes.taramaRandevusu: SitePageContent(
    eyebrow: 'Randevu',
    title: 'Tarama için randevu alın',
    description:
        '3D ayak tarama ve basınç ölçümü, anlaşmalı ölçüm noktalarında '
        'yapılır. Randevu oluşturun, ölçüm yaklaşık iki dakika sürsün.',
    blocks: [
      SiteFeaturesBlock(
        items: [
          (
            title: 'Randevu öncesi',
            body:
                'Rahat bir çorap ve günlük ayakkabınızla gelin; ölçüm çıplak '
                'ayak yapılır.',
          ),
          (
            title: 'Ölçüm',
            body: '3D tarama ve basınç ölçümü toplam iki dakika sürer.',
          ),
          (
            title: 'Değerlendirme',
            body:
                'Ölçüm sonucunuz ayak profiline dönüştürülür ve uygun ürün '
                'yapısı belirlenir.',
          ),
          (
            title: 'Sonrası',
            body:
                'Sipariş ve üretim süreci randevu kaydınız üzerinden takip '
                'edilir.',
          ),
        ],
      ),
      SitePlaceholderBlock(
        label: 'Randevu formu ve takvim',
        note:
            'Randevu takvimi ve form gönderimi için servis bağlantısı '
            'kurulduğunda bu alan aktif edilecektir. Şimdilik iletişim '
            'sayfasından ulaşabilirsiniz.',
      ),
      SiteCtaBlock(
        title: 'En yakın ölçüm noktasını görün',
        description:
            'Randevu oluşturmadan önce size en yakın merkezi inceleyebilir '
            'veya işletmeniz için tarama standı başvurusu yapabilirsiniz.',
        primaryLabel: 'Ölçüm Merkezleri',
        primaryRoute: SiteRoutes.olcumMerkezleri,
        secondaryLabel: 'Tarama Standı İçin Başvur',
        secondaryRoute: SiteRoutes.taramaStandiBasvuru,
      ),
    ],
  ),

  SiteRoutes.taramaStandiBasvuru: SitePageContent(
    eyebrow: 'Başvuru',
    title: 'Tarama Standı İçin Başvur',
    description:
        'İşletmenize tarama standı kurulumu için başvurun. Kurulum, eğitim ve '
        'süreç desteğini birlikte planlayalım.',
    blocks: [
      SiteFeaturesBlock(
        items: [
          (
            title: 'Kimler başvurabilir?',
            body: 'Klinikler, eczaneler, ayakkabı mağazaları ve iş yerleri.',
          ),
          (
            title: 'Kurulum',
            body: 'Küçük alana kurulabilen ölçüm noktası ve eğitim.',
          ),
          (
            title: 'Süreç',
            body: 'Ölçümden ürün teslimine kadar tanımlı akış.',
          ),
          (
            title: 'Destek',
            body: 'Kurulum sonrası operasyon desteği.',
          ),
        ],
      ),
      SitePlaceholderBlock(
        label: 'Başvuru formu',
        note:
            'Form gönderimi için servis bağlantısı kurulduğunda bu alan aktif '
            'edilecektir. Şimdilik iletişim sayfasından ulaşabilirsiniz.',
      ),
      _contactCta,
    ],
  ),

  // ── Kurumsal ───────────────────────────────────────────────────────────────
  SiteRoutes.hakkimizda: SitePageContent(
    eyebrow: 'Kurumsal',
    title: 'Hakkımızda',
    description:
        'OPTIYOU; dijital ayak ölçümü, veri güdümlü değerlendirme, uygun ürün '
        'seçimi, üretim ve takip altyapısını bir araya getiren yeni nesil ayak '
        'deneyimi platformudur.',
    blocks: [
      SiteFeaturesBlock(
        items: [
          (
            title: 'Yaklaşımımız',
            body:
                'Ürün seçimini tahmine değil, ölçüme ve veriye dayandırıyoruz.',
          ),
          (
            title: 'Üretim',
            body:
                'Dijital üretim laboratuvarımızda geliştirme ve üretim yapıyoruz.',
          ),
          (
            title: 'İş birlikleri',
            body:
                'Klinik, eczane, mağaza ve iş yerleriyle ortak ölçüm ağı '
                'kuruyoruz.',
          ),
          (
            title: 'Ar-Ge',
            body: 'Destekli Ar-Ge projeleriyle ürün ve süreçleri geliştiriyoruz.',
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
        label: 'Ekip fotoğrafları ve tanıtım metinleri',
        note: 'Kurumsal ekip görselleri sağlandığında eklenecektir.',
      ),
    ],
  ),

  SiteRoutes.kariyer: SitePageContent(
    eyebrow: 'Kurumsal',
    title: 'Kariyer',
    description:
        'Ölçüm, üretim ve yazılım alanlarında birlikte çalışacak takım '
        'arkadaşları arıyoruz.',
    blocks: [
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
    blocks: [
      SitePlaceholderBlock(label: 'Haber ve basın içerikleri'),
    ],
  ),

  SiteRoutes.blog: SitePageContent(
    eyebrow: 'Keşfet',
    title: 'Blog',
    description:
        'Ayak profili, ölçüm ve ürün seçimi üzerine yazılar.',
    blocks: [
      SitePlaceholderBlock(label: 'Blog yazıları'),
    ],
  ),

  SiteRoutes.sss: SitePageContent(
    eyebrow: 'Destek',
    title: 'Sıkça Sorulan Sorular',
    description: 'Ölçüm, ürün ve teslimat süreciyle ilgili sık sorulan sorular.',
    blocks: [
      SiteFeaturesBlock(
        items: [
          (
            title: 'Tarama ne kadar sürer?',
            body: 'Ölçüm yaklaşık iki dakika sürer.',
          ),
          (
            title: 'Ölçüm nerede yapılır?',
            body: 'Anlaşmalı klinik, eczane ve mağazalardaki ölçüm noktalarında.',
          ),
          (
            title: 'Ürün ne zaman teslim edilir?',
            body:
                'Üretim tamamlandıktan sonra kargoya verilir; süreç takip '
                'edilebilir.',
          ),
          (
            title: 'Ölçüm verim nasıl korunuyor?',
            body:
                'Veriler erişim yetkileriyle korunur; detaylar Aydınlatma '
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
    blocks: [
      SitePlaceholderBlock(
        label: 'İletişim bilgileri ve form',
        note:
            'Adres, telefon ve form gönderim ucu tanımlandığında bu alan '
            'güncellenecektir.',
      ),
    ],
  ),

  // ── Yasal metinler (mevcut belge kayıtlarından) ───────────────────────────
  SiteRoutes.kvkk: SitePageContent(
    eyebrow: 'Yasal',
    title: 'KVKK Aydınlatma Metni',
    description:
        'Kişisel verilerin işlenmesine ilişkin aydınlatma metni.',
    blocks: [
      SiteLegalBlock(documentCode: LegalDocumentCodes.aydinlatmaMetni),
    ],
  ),

  SiteRoutes.gizlilik: SitePageContent(
    eyebrow: 'Yasal',
    title: 'Gizlilik Politikası',
    description: 'Gizlilik ve güvenlik uygulamalarımız.',
    blocks: [
      SiteLegalBlock(documentCode: LegalDocumentCodes.gizlilikGuvenlik),
    ],
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
