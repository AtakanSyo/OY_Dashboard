import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../components/hero_video_section.dart';
import '../components/process_showcase.dart';
import '../components/product_technology_card.dart';
import '../components/site_buttons.dart';
import '../components/site_scaffold.dart';
import '../components/site_section.dart';
import '../site_routes.dart';
import '../theme/site_responsive.dart';
import '../theme/site_tokens.dart';
import '../theme/site_typography.dart';

/// OPTIYOU ana sayfası / landing page — Superspec §7.
class SiteHomePage extends StatelessWidget {
  const SiteHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return const SiteScaffold(
      children: [
        _HeroSection(),
        _ProcessSection(),
        _InsoleTechnologiesSection(),
        _B2bServicesSection(),
      ],
    );
  }
}

// ── Hero ─────────────────────────────────────────────────────────────────────

class _HeroSection extends StatelessWidget {
  const _HeroSection();

  @override
  Widget build(BuildContext context) {
    final device = context.device;

    // Metin bloğu: masaüstünde rahat okunacak kadar geniş, ama satır uzunluğu
    // okunabilirlik sınırını aşmayacak kadar dar.
    final copyWidth = context.responsive<double>(
      mobile: double.infinity,
      tablet: 560,
      desktop: 700,
    );

    return HeroVideoSection(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: copyWidth),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Ayağınız tek bir kategoriye sığmayacak kadar eşsiz.',
              style: SiteType.hero(
                context,
              ).copyWith(color: SiteColors.textInverse),
            ),
            const SizedBox(height: SiteSpacing.lg),
            Text(
              'Yapay Zeka Destekli Anatomik Kategorilemeyle doğru '
              'tabanlıkla konforu hissedin.',
              style: SiteType.h2(context).copyWith(
                color: SiteColors.primaryOnDark,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: SiteSpacing.x2),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 560),
              child: Text(
                '3D ayak tarama, basınç ölçümü ve akıllı değerlendirme ile '
                'yürüyüşüne en uygun tabanlık yapısını keşfet. Teknolojiyle '
                'desteklenen konforu deneyimle.',
                style: SiteType.bodyLarge(
                  context,
                ).copyWith(color: SiteColors.textOnMedia),
              ),
            ),
            SizedBox(height: device.isMobile ? SiteSpacing.x3 : SiteSpacing.x4),
            Wrap(
              spacing: SiteSpacing.md,
              runSpacing: SiteSpacing.md,
              children: [
                SecondaryButton(
                  label: 'Sürecimiz',
                  size: SiteButtonSize.large,
                  onDark: true,
                  onPressed: () => SiteNav.go(context, SiteRoutes.nasilCalisir),
                ),
                PrimaryButton(
                  label: '3D Tarama İçin Randevu Al',
                  size: SiteButtonSize.large,
                  onPressed: () =>
                      SiteNav.go(context, SiteRoutes.taramaRandevusu),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ── 4 adımlı süreç ───────────────────────────────────────────────────────────

class _ProcessSection extends StatelessWidget {
  const _ProcessSection();

  /// Patent bandı anahtarı.
  ///
  /// Başvuru 29.08.2026'da yapıldı; başvuru numarası henüz yok. Başvuru geri
  /// çekilirse ya da tescil tamamlanıp metin değişirse burası tek satırda
  /// kapatılır. Tescil öncesi "patentli teknoloji" ifadesi kullanılmaz.
  static const bool _showPatentNotice = true;

  /// Dört sahne. V3: her adım kartın tamamını dolduran bir görsel.
  static const List<ProcessStep> _steps = [
    ProcessStep(
      number: '01',
      category: '01 · Tarama',
      title: '3D Biyomekanik Tarama',
      body:
          'Ayak geometrisi ve yük altındaki plantar basınç dağılımı aynı '
          'ölçüm oturumunda dijitalleştirilir.',
      image: 'assets/site/v3/source/process-real-scan-session.webp',
      imageAlt: 'Gerçek bir 3D ayak tarama oturumu',
    ),
    ProcessStep(
      number: '02',
      category: '02 · Değerlendirme',
      title: 'Yapay Zekâ Destekli Anatomik Kategorileme',
      body:
          'Ölçüm verileri uzman etiketleriyle birlikte değerlendirilir; '
          'anatomik kategori ve uyum skoru oluşturulur.',
      image: 'assets/site/v3/generated/process-ai-categorization.webp',
      imageAlt: '3D ayak ve basınç verisinin anatomik kategorilere ayrılması',
    ),
    ProcessStep(
      number: '03',
      category: '03 · Üretim',
      title: 'Veri Güdümlü Dijital Üretim',
      body:
          'Seçilen kategori ve ürün ailesine göre üretim geometrisi '
          'hazırlanır; dijital üretim süreci başlatılır.',
      image: 'assets/site/v3/generated/process-digital-production.webp',
      imageAlt: 'Veri güdümlü dijital tabanlık üretimi',
    ),
    ProcessStep(
      number: '04',
      category: '04 · Takip',
      title: 'Teslimat ve Dijital Takip',
      body:
          'Ürün kullanıcıya ulaştırılır; sonraki ölçümler aynı profil '
          'üzerinden karşılaştırmalı olarak takip edilir.',
      image: 'assets/site/v3/generated/process-delivery-tracking.webp',
      imageAlt: 'Ürün teslimatı ve dijital takip ekranı',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final device = context.device;

    return SiteSection(
      dense: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _ProcessIntro(),
          const SizedBox(height: SiteSpacing.x4),
          const ProcessShowcase(
            steps: _steps,
            showPatentNotice: _showPatentNotice,
            patentTitle:
                'Anatomik kategorileme sistemimiz için patent başvurusu '
                'yapıldı',
            patentText:
                '3D ayak geometrisi ve plantar basınç verilerinden anatomik '
                'kategori ve uyum skoru oluşturan sistem için 29.08.2026 '
                'tarihinde patent başvurusu gerçekleştirilmiştir.',
          ),
          SizedBox(height: device.isCompact ? SiteSpacing.x2 : SiteSpacing.x3),
          const _ProcessCta(),
        ],
      ),
    );
  }
}

/// Sürecimiz bölümü giriş bloğu (V3 metinleri).
class _ProcessIntro extends StatelessWidget {
  const _ProcessIntro();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CaliperRule(),
            const SizedBox(width: SiteSpacing.md),
            Text('SÜRECİMİZ', style: SiteType.dataLabel(context)),
          ],
        ),
        const SizedBox(height: SiteSpacing.lg),
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1000),
          child: Text(
            'Eşsiz ayak yapınıza en uygun ortopedik tabanlığı bulun.',
            style: SiteType.h2(context),
          ),
        ),
        const SizedBox(height: SiteSpacing.lg),
        RichText(
          text: TextSpan(
            style: SiteType.bodyLarge(context),
            children: [
              TextSpan(
                text: 'Sole Doctor',
                style: TextStyle(
                  color: SiteColors.primary,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const TextSpan(
                text: ' - Ayak Sağlığı için Dijital Takip Üretim Hizmeti',
              ),
            ],
          ),
        ),
        const SizedBox(height: SiteSpacing.md),
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 840),
          child: Text(
            '3D ayak geometrisi ve plantar basınç verileri tek bir dijital '
            'profilde bir araya getirilir. Yapay zekâ destekli anatomik '
            'kategorileme ve uzman değerlendirmesiyle ayak yapınıza en uygun '
            'iç taban belirlenir; üretim, teslimat ve sonraki ölçümler aynı '
            'sistem üzerinden takip edilir.',
            style: SiteType.body(
              context,
            ).copyWith(color: SiteColors.textSecondary, height: 1.65),
          ),
        ),
      ],
    );
  }
}

/// Bölüm sonu eylem alanı.
class _ProcessCta extends StatelessWidget {
  const _ProcessCta();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: SiteSpacing.md,
          runSpacing: SiteSpacing.md,
          children: [
            PrimaryButton(
              label: 'Ölçüm Noktalarını Gör',
              icon: Icons.place_outlined,
              size: SiteButtonSize.large,
              onPressed: () => SiteNav.go(context, SiteRoutes.olcumMerkezleri),
            ),
            SecondaryButton(
              label: 'Süreci İncele',
              size: SiteButtonSize.large,
              onPressed: () => SiteNav.go(context, SiteRoutes.nasilCalisir),
            ),
          ],
        ),
        const SizedBox(height: SiteSpacing.md),
        Text(
          'Ölçüm, değerlendirme ve ürün seçenekleri hakkında bilgi alın.',
          style: SiteType.small(context),
        ),
      ],
    );
  }
}

// ── Tabanlık teknolojileri ───────────────────────────────────────────────────

class _InsoleTechnologiesSection extends StatefulWidget {
  const _InsoleTechnologiesSection();

  @override
  State<_InsoleTechnologiesSection> createState() =>
      _InsoleTechnologiesSectionState();
}

class _InsoleTechnologiesSectionState
    extends State<_InsoleTechnologiesSection> {
  static const String _v3 = 'assets/site/v3';

  int? _flipped;

  static const List<ProductTechnology> _products = [
    ProductTechnology(
      category: 'VERİ GÜDÜMLÜ ANATOMİK TABANLIK',
      name: 'OY Orthopedic',
      slogan: 'Gün boyu dengeli destek.',
      description: 'Günlük kullanımda konfor, denge ve anatomik uyum.',
      frontImage: '$_v3/generated/product-daily-assembled.webp',
      frontImageAlt: 'OY Orthopedic günlük anatomik tabanlık',
      backImage: '$_v3/generated/product-daily-exploded.webp',
      layers: [
        ProductLayer(
          'Antibakteriyel üst yüzey',
          'Nemi yönetir, hijyeni destekleyen temas yüzeyi.',
        ),
        ProductLayer('Konfor katmanı', 'Temas basıncını yumuşatan yastıklama.'),
        ProductLayer(
          'Anatomik destek',
          'Kavisi tarama verisine göre destekleyen çekirdek.',
        ),
        ProductLayer(
          'Stabil taban',
          'Adımda yanal salınımı sınırlayan alt yüzey.',
        ),
      ],
    ),
    ProductTechnology(
      category: 'VERİ GÜDÜMLÜ SPORCU TABANLIĞI',
      name: 'OY Sports',
      slogan: 'Hareket için tasarlanan tepki.',
      description: 'Darbe yönetimi ve stabilite odaklı performans yapısı.',
      frontImage: '$_v3/source/product-sports-assembled.webp',
      frontImageAlt: 'OY Sports performans tabanlığı',
      backImage: '$_v3/generated/product-sports-exploded.webp',
      layers: [
        ProductLayer('Teknik üst yüzey', 'Teri ve sürtünmeyi yöneten kaplama.'),
        ProductLayer(
          'Tepkisel yastıklama',
          'İniş kuvvetini emip adıma geri veren katman.',
        ),
        ProductLayer('Enerji yönetimi', 'Yükü tabana yayan ara katman.'),
        ProductLayer(
          'Stabilizasyon plakası',
          'Hızlı yön değişiminde ayağı hizada tutan yapı.',
        ),
      ],
    ),
    ProductTechnology(
      category: 'TOPARLAYICI SANDALET',
      name: 'OY Recovery',
      slogan: 'Günün sonunda daha yumuşak bir zemin.',
      description: 'Konfor ve basınç dağılımı odaklı toparlanma yapısı.',
      frontImage: '$_v3/source/product-recovery-assembled.webp',
      frontImageAlt: 'OY Recovery toparlayıcı sandalet',
      backImage: '$_v3/generated/product-recovery-exploded.webp',
      layers: [
        ProductLayer(
          'Nefes alan üst bant',
          'Ayağı saran, temas basıncını dağıtan bant.',
        ),
        ProductLayer(
          'Konturlu ayak yatağı',
          'Tabanı geniş alana yayan temas yüzeyi.',
        ),
        ProductLayer('Yumuşak ara taban', 'Adım yükünü yumuşatan katman.'),
        ProductLayer('Dayanıklı dış taban', 'Kaymaz, esnek zemin teması.'),
      ],
    ),
    ProductTechnology(
      category: 'KARBON DESTEK MİMARİSİ',
      name: 'OY Sports Carbon',
      slogan: 'Karbon stabilite. Kontrollü enerji.',
      description:
          'Yüksek tempolu kullanım için hafif ve rijit destek mimarisi.',
      frontImage: '$_v3/generated/product-carbon-assembled.webp',
      frontImageAlt: 'Karbon fiberli sporcu tabanlığı',
      backImage: '$_v3/generated/product-carbon-exploded.webp',
      carbon: true,
      layers: [
        ProductLayer(
          'Nefes alan üst yüzey',
          'Nemi uzaklaştıran ince temas katmanı.',
        ),
        ProductLayer(
          'Tepkisel yastıklama',
          'Darbeyi emip enerjiyi geri veren katman.',
        ),
        ProductLayer(
          'Karbon fiber plaka',
          'Burulmaya direnç veren rijit orta katman.',
        ),
        ProductLayer('Grafit taban gövdesi', 'Hafif, dayanıklı alt gövde.'),
      ],
    ),
  ];

  void _toggle(int index) {
    setState(() => _flipped = _flipped == index ? null : index);
  }

  @override
  Widget build(BuildContext context) {
    final compact = context.device.isCompact;

    final textBlock = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CaliperRule(),
            const SizedBox(width: SiteSpacing.md),
            Flexible(
              child: Text(
                'OPTIYOU TEKNOLOJİ GİYİM ÜRÜNLERİ',
                overflow: TextOverflow.ellipsis,
                style: SiteType.dataLabel(context),
              ),
            ),
          ],
        ),
        const SizedBox(height: SiteSpacing.lg),
        Text(
          'Veri Güdümlü Ayak Giyim Teknolojileri',
          style: SiteType.h2(context),
        ),
        const SizedBox(height: SiteSpacing.lg),
        ConstrainedBox(
          constraints: const BoxConstraints(
            maxWidth: SiteBreakpoints.proseMaxWidth,
          ),
          child: Text(
            'Her kullanım senaryosuna farklı bir katman mimarisi. Karta '
            'dokunarak katmanlı görünüme geçin.',
            style: SiteType.bodyLarge(context),
          ),
        ),
      ],
    );

    final cta = SecondaryButton(
      label: 'Tüm ürünleri incele',
      size: SiteButtonSize.large,
      onPressed: () => SiteNav.go(context, SiteRoutes.tabanliklar),
    );

    final cardHeight = compact ? 620.0 : 600.0;

    return SiteSection(
      dense: true,
      background: SiteColors.surfaceRaised,
      child: FocusableActionDetector(
        shortcuts: const <ShortcutActivator, Intent>{
          SingleActivator(LogicalKeyboardKey.escape): DismissIntent(),
        },
        actions: <Type, Action<Intent>>{
          DismissIntent: CallbackAction<DismissIntent>(
            onInvoke: (_) {
              if (_flipped != null) setState(() => _flipped = null);
              return null;
            },
          ),
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (compact)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  textBlock,
                  const SizedBox(height: SiteSpacing.lg),
                  cta,
                ],
              )
            else
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(child: textBlock),
                  const SizedBox(width: SiteSpacing.x2),
                  cta,
                ],
              ),
            const SizedBox(height: SiteSpacing.x3),
            SiteResponsiveGrid(
              columns: 4,
              tabletColumns: 2,
              children: [
                for (var i = 0; i < _products.length; i++)
                  SizedBox(
                    height: cardHeight,
                    child: ProductTechnologyCard(
                      data: _products[i],
                      flipped: _flipped == i,
                      onToggle: () => _toggle(i),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ── B2B: Kurumlara özel çözümler ─────────────────────────────────────────────

class _B2bSegment {
  const _B2bSegment({
    required this.eyebrow,
    required this.title,
    required this.detail,
    required this.ctaLabel,
    required this.route,
    required this.image,
    required this.imageAlt,
  });

  final String eyebrow;
  final String title;
  final String detail;
  final String ctaLabel;
  final String route;
  final String image;
  final String imageAlt;
}

class _B2bServicesSection extends StatelessWidget {
  const _B2bServicesSection();

  static const String _v3 = 'assets/site/v3/generated';

  static const List<_B2bSegment> _segments = [
    _B2bSegment(
      eyebrow: 'KLİNİKLER',
      title: 'Ölçümden ürün teslimine kadar tek dijital iş akışı.',
      detail:
          'Uzman görüşünü 3D ayak ve plantar basınç verileriyle aynı kullanıcı '
          'profilinde yönetin.',
      ctaLabel: 'Klinik çözümünü incele',
      route: SiteRoutes.cozumlerKlinikler,
      image: '$_v3/b2b-clinics.webp',
      imageAlt: 'Klinikte düşük tarama platformunda ayak taraması',
    ),
    _B2bSegment(
      eyebrow: 'SPOR KULÜPLERİ',
      title: 'Her sporcuyu aynı ölçüm standardıyla takip edin.',
      detail:
          'Sporcu bazlı ölçüm, ürün yönlendirmesi ve dönemsel karşılaştırma '
          'akışı.',
      ctaLabel: 'Spor kulübü çözümünü incele',
      route: SiteRoutes.iletisim,
      image: '$_v3/b2b-sports-clubs.webp',
      imageAlt: 'Spor bilimleri ortamında ayak tarama platformu',
    ),
    _B2bSegment(
      eyebrow: 'İŞ YERLERİ',
      title: 'Ayakta çalışan ekipler için planlı toplu tarama.',
      detail:
          'İş yerinde mobil ölçüm, kullanıcı gruplama ve ürün teslimini tek '
          'programda yönetin.',
      ctaLabel: 'Kurumsal programı incele',
      route: SiteRoutes.cozumlerIsYerleri,
      image: '$_v3/b2b-workplaces.webp',
      imageAlt: 'İş yerinde planlı toplu ayak tarama',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return SiteSection(
      inverse: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionHeading(
            eyebrow: 'KURUMLARA ÖZEL ÇÖZÜMLER',
            title:
                'Ayak sağlığı verisini kurumunuz için ölçülebilir bir '
                'hizmete dönüştürün.',
            description:
                'Klinikler, spor kulüpleri ve iş yerleri için tarama, ürün '
                'yönlendirme ve dijital takip süreçlerini tek hizmet modelinde '
                'birleştiriyoruz. Kuruma özel ölçüm planı ve düzenli takip '
                'akışıyla süreci ölçeklenebilir hâle getiriyoruz.',
            inverse: true,
          ),
          const SizedBox(height: SiteSpacing.x4),
          SiteResponsiveGrid(
            columns: 3,
            tabletColumns: 1,
            children: [
              for (final segment in _segments) _B2bImageCard(segment: segment),
            ],
          ),
        ],
      ),
    );
  }
}

class _B2bImageCard extends StatefulWidget {
  const _B2bImageCard({required this.segment});

  final _B2bSegment segment;

  @override
  State<_B2bImageCard> createState() => _B2bImageCardState();
}

class _B2bImageCardState extends State<_B2bImageCard> {
  bool _hovered = false;
  bool _focused = false;

  @override
  Widget build(BuildContext context) {
    final s = widget.segment;
    final lifted = _hovered || _focused;
    final motion = SiteMotion.duration(
      context,
      const Duration(milliseconds: 420),
    );

    return Semantics(
      button: true,
      label: '${s.eyebrow}: ${s.title}',
      child: FocusableActionDetector(
        mouseCursor: SystemMouseCursors.click,
        onShowHoverHighlight: (v) => setState(() => _hovered = v),
        onShowFocusHighlight: (v) => setState(() => _focused = v),
        actions: {
          ActivateIntent: CallbackAction<ActivateIntent>(
            onInvoke: (_) {
              SiteNav.go(context, s.route);
              return null;
            },
          ),
        },
        child: GestureDetector(
          onTap: () => SiteNav.go(context, s.route),
          child: Container(
            height: 560,
            decoration: BoxDecoration(
              borderRadius: const BorderRadius.all(Radius.circular(28)),
              border: Border.all(
                color: _focused ? SiteColors.focus : SiteColors.borderInverse,
                width: _focused ? 2 : 1,
              ),
              boxShadow: lifted ? SiteShadows.cardHover : SiteShadows.card,
            ),
            child: ClipRRect(
              borderRadius: const BorderRadius.all(Radius.circular(28)),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Semantics(
                    image: true,
                    label: s.imageAlt,
                    child: AnimatedScale(
                      duration: motion,
                      scale: lifted ? 1.035 : 1,
                      child: Image.asset(
                        s.image,
                        fit: BoxFit.cover,
                        filterQuality: FilterQuality.medium,
                        errorBuilder: (context, error, stack) =>
                            const ColoredBox(
                              color: SiteColors.surfaceInverseRaised,
                            ),
                      ),
                    ),
                  ),
                  const DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        stops: [0.25, 0.77, 1.0],
                        colors: [
                          Color(0x0D0E1F22),
                          Color(0xED0E1F22),
                          Color(0xFC0E1F22),
                        ],
                      ),
                    ),
                  ),
                  Positioned(
                    left: SiteSpacing.xl,
                    right: SiteSpacing.xl,
                    bottom: SiteSpacing.xl,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          s.eyebrow,
                          style: SiteType.dataLabel(
                            context,
                            color: SiteColors.primaryOnDark,
                          ),
                        ),
                        const SizedBox(height: SiteSpacing.sm),
                        Text(
                          s.title,
                          style: SiteType.h3(context).copyWith(
                            color: SiteColors.textInverse,
                            fontSize: 22,
                          ),
                        ),
                        const SizedBox(height: SiteSpacing.sm),
                        Text(
                          s.detail,
                          style: SiteType.body(context).copyWith(
                            color: SiteColors.textOnMedia,
                            fontSize: 14,
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.only(top: SiteSpacing.lg),
                          child: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  s.ctaLabel,
                                  style: SiteType.action(context, strong: true)
                                      .copyWith(
                                        color: lifted
                                            ? SiteColors.primaryOnDark
                                            : SiteColors.textInverse,
                                      ),
                                ),
                              ),
                              Icon(
                                Icons.arrow_forward,
                                size: 18,
                                color: lifted
                                    ? SiteColors.primaryOnDark
                                    : SiteColors.textInverse,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
