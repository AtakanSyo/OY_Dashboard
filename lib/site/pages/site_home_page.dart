import 'package:flutter/material.dart';

import '../components/hero_video_section.dart';
import '../components/selection_wizard.dart';
import '../components/site_buttons.dart';
import '../components/site_cards.dart';
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
        _TrustStripSection(),
        _ProcessSection(),
        _InsoleTechnologiesSection(),
        _ModelFinderSection(),
        _ProductionTimelineSection(),
        _TestimonialsSection(),
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
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const CaliperRule(color: SiteColors.primaryOnDark),
                const SizedBox(width: SiteSpacing.md),
                Flexible(
                  child: Text(
                    'DİJİTAL AYAK DENEYİMİ',
                    overflow: TextOverflow.ellipsis,
                    style: SiteType.dataLabel(
                      context,
                      color: SiteColors.primaryOnDark,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: SiteSpacing.x2),
            Text(
              'Ayağınız tek bir kategoriye sığmayacak kadar eşsiz.',
              style: SiteType.hero(context).copyWith(
                color: SiteColors.textInverse,
              ),
            ),
            const SizedBox(height: SiteSpacing.lg),
            Text(
              'Anatomik kategorilemeyle doğru tabanlıkla konforu hissedin.',
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
                style: SiteType.bodyLarge(context).copyWith(
                  color: SiteColors.textOnMedia,
                ),
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
                  label: 'Randevu Al',
                  icon: Icons.event_available_outlined,
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

/// Hero'nun hemen altındaki ince güven şeridi.
///
/// Bu üç madde daha önce hero'nun içindeydi; hero videonun üzerinde sade
/// kalsın diye aşağı alındı.
class _TrustStripSection extends StatelessWidget {
  const _TrustStripSection();

  @override
  Widget build(BuildContext context) {
    final device = context.device;

    return SiteSection(
      background: SiteColors.surfaceRaised,
      padding: EdgeInsets.symmetric(
        horizontal: device.gutter,
        vertical: device.isMobile ? SiteSpacing.x3 : SiteSpacing.x4,
      ),
      child: const _HeroBenefits(),
    );
  }
}

class _HeroBenefits extends StatelessWidget {
  const _HeroBenefits();

  static const List<({IconData icon, String label})> _items = [
    (icon: Icons.timer_outlined, label: '2 Dakikada Tarama'),
    (icon: Icons.straighten_outlined, label: 'Bilimsel Ölçüm'),
    (icon: Icons.local_shipping_outlined, label: 'Hızlı Gönderim'),
  ];

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: SiteSpacing.x2,
      runSpacing: SiteSpacing.md,
      children: [
        for (final item in _items)
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 34,
                height: 34,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: SiteColors.primarySoft,
                  borderRadius: BorderRadius.circular(SiteRadius.sm),
                ),
                child: Icon(item.icon, size: 17, color: SiteColors.primary),
              ),
              const SizedBox(width: SiteSpacing.sm),
              // Dar ekranda etiket satırı taşırmasın.
              Flexible(
                child: Text(
                  item.label,
                  overflow: TextOverflow.ellipsis,
                  style: SiteType.action(context, strong: true),
                ),
              ),
            ],
          ),
      ],
    );
  }
}

// ── 4 adımlı süreç ───────────────────────────────────────────────────────────

class _ProcessSection extends StatelessWidget {
  const _ProcessSection();

  static const List<({String title, String description, IconData icon})> _steps =
      [
    (
      title: '3D Ayak Tarama',
      description:
          'Telefon kamerası ile ayağını 3 boyutlu olarak tararız.',
      icon: Icons.center_focus_strong_outlined,
    ),
    (
      title: 'Basınç Ölçümü',
      description:
          'Basınç dağılımını ölçer, yürüme verilerini toplarız.',
      icon: Icons.grain_outlined,
    ),
    (
      title: 'Akıllı Değerlendirme',
      description:
          'Verileri değerlendirerek senin için en uygun tabanlık yapısını belirleriz.',
      icon: Icons.insights_outlined,
    ),
    (
      title: 'Uygun Tabanlık ve Kargo',
      description:
          'Senin için üretilen tabanlığın kargoya verilir, kapına ulaştırılır.',
      icon: Icons.inventory_2_outlined,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return SiteSection(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionHeading(
            eyebrow: 'Süreç',
            title: 'Dört adımda ayak profilinden ürüne',
            description:
                'Ölçümden teslimata kadar her adım aynı veri üzerinde ilerler. '
                'Süreç boyunca hangi aşamada olduğunu görürsün.',
          ),
          const SizedBox(height: SiteSpacing.x5),
          SiteResponsiveGrid(
            columns: 4,
            tabletColumns: 2,
            children: [
              for (var i = 0; i < _steps.length; i++)
                ProcessStepCard(
                  index: i + 1,
                  title: _steps[i].title,
                  description: _steps[i].description,
                  icon: _steps[i].icon,
                ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Tabanlık teknolojileri ───────────────────────────────────────────────────

class _InsoleTechnologiesSection extends StatelessWidget {
  const _InsoleTechnologiesSection();

  @override
  Widget build(BuildContext context) {
    return SiteSection(
      background: SiteColors.surfaceRaised,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionHeading(
            eyebrow: 'Ürün Aileleri',
            title: 'Tabanlık Teknolojilerimiz',
            description:
                'Farklı kullanım senaryoları için geliştirilen üç ana yapı. '
                'Hangisinin size uygun olduğu ölçüm sonucuna göre belirlenir.',
          ),
          const SizedBox(height: SiteSpacing.x5),
          SiteResponsiveGrid(
            columns: 3,
            tabletColumns: 2,
            children: [
              TechnologyCard(
                imageAsset: 'assets/images/products/custom_insole.png',
                title: 'Veri Güdümlü Anatomik Tabanlık',
                description:
                    'Günlük kullanım için tasarlandı. Ayak yapına uyum sağlar, '
                    'gün boyu konfor sunar.',
                onPressed: () =>
                    SiteNav.go(context, SiteRoutes.tabanliklarGunluk),
              ),
              TechnologyCard(
                imageAsset: 'assets/images/products/sport_insole.png',
                title: 'Sporcular İçin Karbon Fiber Tabanlık',
                description:
                    'Hafif karbon fiber tabanla performansını artırır, darbe '
                    'emilimini destekler.',
                onPressed: () => SiteNav.go(context, SiteRoutes.tabanliklarSpor),
              ),
              TechnologyCard(
                imageAsset: 'assets/images/products/recovery_sandal.png',
                title: 'OY Recovery Anatomik Toparlayıcı Sandalet',
                description:
                    'SLA 3B teknolojisiyle kafes yapılı tasarım, hafiflik ve '
                    'toparlayıcı destek sağlar.',
                onPressed: () =>
                    SiteNav.go(context, SiteRoutes.tabanliklarRecovery),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Model bulucu ─────────────────────────────────────────────────────────────

class _ModelFinderSection extends StatefulWidget {
  const _ModelFinderSection();

  @override
  State<_ModelFinderSection> createState() => _ModelFinderSectionState();
}

class _ModelFinderSectionState extends State<_ModelFinderSection> {
  int _size = 42;
  String _arch = 'Orta';
  String _balance = 'Nötr';

  void _showCartNotice() {
    // TODO(entegrasyon): sepet akışı bağlanacak.
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Sepet akışı yakında bu sayfaya bağlanacak.'),
        backgroundColor: SiteColors.surfaceInverse,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final device = context.device;

    final wizard = SelectionWizard(
      size: _size,
      arch: _arch,
      balance: _balance,
      onSizeChanged: (value) => setState(() => _size = value),
      onArchChanged: (value) => setState(() => _arch = value),
      onBalanceChanged: (value) => setState(() => _balance = value),
    );

    final card = RecommendedProductCard(
      badge: 'Sana Önerilen Model',
      name: 'Balance Pro',
      description:
          'Dengeli yürüyüş için tasarlandı. Gün boyu konfor ve destek sağlar.',
      features: const [
        'Orta kemer desteği',
        'Darbe emici yapı',
        'Nefes alabilir üst yüzey',
      ],
      price: '1.499 TL',
      priceNote: 'KDV dahil',
      imageAsset: 'assets/images/products/personal_insole.png',
      onDetails: () => SiteNav.go(context, SiteRoutes.tabanliklarGunluk),
      onAddToCart: _showCartNotice,
    );

    return SiteSection(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionHeading(
            eyebrow: 'Model Bulucu',
            title: 'Sana En Uygun Modeli Bulalım',
            description:
                'Numara, kemer tipi ve yürüme dengeni seç; hangi yapının öne '
                'çıktığını gör. Kesin uyum taramadan sonra netleşir.',
          ),
          const SizedBox(height: SiteSpacing.x5),
          if (device.isMobile)
            Column(
              children: [
                wizard,
                const SizedBox(height: SiteSpacing.x2),
                card,
              ],
            )
          else
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(flex: 5, child: wizard),
                const SizedBox(width: SiteSpacing.x3),
                Expanded(flex: 6, child: card),
              ],
            ),
        ],
      ),
    );
  }
}

// ── Üretim ve teslimat ───────────────────────────────────────────────────────

class _ProductionTimelineSection extends StatelessWidget {
  const _ProductionTimelineSection();

  static const List<({String label, IconData icon})> _steps = [
    (label: 'Siparişin Alınır', icon: Icons.receipt_long_outlined),
    (label: 'Üretime Hazırlanır', icon: Icons.tune_outlined),
    (label: 'Üretim Tamamlanır', icon: Icons.precision_manufacturing_outlined),
    (label: 'Kargoya Verilir', icon: Icons.local_shipping_outlined),
    (label: 'Kapında', icon: Icons.home_outlined),
  ];

  @override
  Widget build(BuildContext context) {
    final device = context.device;
    final horizontal = device.isDesktop;

    return SiteSection(
      inverse: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionHeading(
            eyebrow: 'Üretim',
            title: 'Üretim ve Teslimat Süreci',
            description:
                'Siparişin hangi aşamada olduğunu takip edebilirsin. Üretim '
                'kendi laboratuvarımızda yapılır.',
            inverse: true,
          ),
          const SizedBox(height: SiteSpacing.x5),
          if (horizontal)
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (var i = 0; i < _steps.length; i++) ...[
                  if (i > 0)
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.only(top: 26),
                        child: Container(
                          height: 1,
                          color: SiteColors.borderInverse,
                        ),
                      ),
                    ),
                  SizedBox(
                    width: 150,
                    child: TimelineStep(
                      index: i + 1,
                      total: _steps.length,
                      label: _steps[i].label,
                      icon: _steps[i].icon,
                      horizontal: true,
                    ),
                  ),
                ],
              ],
            )
          else
            Column(
              children: [
                for (var i = 0; i < _steps.length; i++) ...[
                  if (i > 0) const SizedBox(height: SiteSpacing.xl),
                  TimelineStep(
                    index: i + 1,
                    total: _steps.length,
                    label: _steps[i].label,
                    icon: _steps[i].icon,
                    horizontal: false,
                  ),
                ],
              ],
            ),
        ],
      ),
    );
  }
}

// ── Yorumlar ─────────────────────────────────────────────────────────────────

class _TestimonialsSection extends StatelessWidget {
  const _TestimonialsSection();

  static const List<({String name, int rating, String comment, String role})>
      _testimonials = [
    (
      name: 'Mert K.',
      rating: 5,
      comment:
          'Gün boyu ayaktayım. Ölçümden sonra önerilen tabanlıkla akşam '
          'yorgunluğunun belirgin şekilde azaldığını fark ettim.',
      role: 'Günlük tabanlık kullanıcısı',
    ),
    (
      name: 'Seda A.',
      rating: 5,
      comment:
          'Tarama iki dakika sürdü. Basış dağılımımı ekranda görmek, doğru '
          'ürünü seçerken çok işime yaradı.',
      role: 'Ölçüm merkezi ziyaretçisi',
    ),
    (
      name: 'Emre T.',
      rating: 4,
      comment:
          'Koşu sonrası toparlanmam hızlandı. Karbon fiber taban hafif ve '
          'destek hissi net.',
      role: 'Spor tabanlığı kullanıcısı',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return SiteSection(
      background: SiteColors.surfaceRaised,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionHeading(
            eyebrow: 'Kullanıcılar',
            title: 'Deneyimi yaşayanlar ne diyor?',
          ),
          const SizedBox(height: SiteSpacing.x5),
          SiteResponsiveGrid(
            columns: 3,
            tabletColumns: 2,
            children: [
              for (final item in _testimonials)
                TestimonialCard(
                  name: item.name,
                  rating: item.rating,
                  comment: item.comment,
                  context_: item.role,
                ),
            ],
          ),
        ],
      ),
    );
  }
}
