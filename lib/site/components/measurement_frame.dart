import 'package:flutter/material.dart';

import '../theme/site_responsive.dart';
import '../theme/site_tokens.dart';
import '../theme/site_typography.dart';

/// Sitenin imza görsel bloğu: ölçüm çizelgesi olarak sunulan ayak profili.
///
/// Superspec §7.2'nin sağ görsel kompozisyonunu projedeki gerçek asset'lerle
/// kurar: ayak konturu, plantar basınç ısı haritası ve iki tabanlık render'ı.
/// Üzerine çizilen kumpas çizgileri ve etiketler örnek ölçülerdir; gerçek
/// kullanıcı verisi olarak sunulmaz (§12.4).
class MeasurementFrame extends StatefulWidget {
  const MeasurementFrame({super.key});

  @override
  State<MeasurementFrame> createState() => _MeasurementFrameState();
}

class _MeasurementFrameState extends State<MeasurementFrame>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: SiteMotion.reveal,
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    if (MediaQuery.maybeOf(context)?.disableAnimations ?? false) {
      _controller.value = 1;
    } else if (!_controller.isAnimating && _controller.value == 0) {
      _controller.forward();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final device = context.device;
    final height = device.responsiveHeight;

    return Semantics(
      label: 'Ayak profili ölçüm görseli: ayak konturu, örnek ölçü çizgileri, '
          'basınç dağılımı ısı haritası ve iki tabanlık görseli.',
      image: true,
      child: SizedBox(
        height: height,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Positioned.fill(
              top: device.isMobile ? 0 : 22,
              bottom: device.isMobile ? 0 : 26,
              right: device.isMobile ? 0 : 34,
              child: _ScanCard(progress: _controller),
            ),
            if (!device.isMobile)
              Positioned(
                top: 0,
                right: 0,
                child: _FloatingCard(
                  progress: _controller,
                  delay: 0.45,
                  child: const _PressurePreview(),
                ),
              ),
            Positioned(
              bottom: device.isMobile ? 6 : 0,
              left: device.isMobile ? 6 : 0,
              child: _FloatingCard(
                progress: _controller,
                delay: 0.65,
                child: _InsolePreview(compact: device.isMobile),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

extension on SiteDevice {
  double get responsiveHeight {
    switch (this) {
      case SiteDevice.mobile:
        return 360;
      case SiteDevice.tablet:
        return 440;
      case SiteDevice.desktop:
        return 520;
    }
  }
}

/// Ana ölçüm kartı: milimetrik zemin, ayak konturu ve kumpas çizgileri.
class _ScanCard extends StatelessWidget {
  final Animation<double> progress;

  const _ScanCard({required this.progress});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: SiteColors.surfaceRaised,
        borderRadius: BorderRadius.circular(SiteRadius.xl),
        border: Border.all(color: SiteColors.border),
        boxShadow: SiteShadows.floating,
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          Positioned.fill(
            child: CustomPaint(painter: _GraphPaperPainter()),
          ),
          Positioned(
            left: SiteSpacing.lg,
            top: SiteSpacing.lg,
            child: _ScanChip(progress: progress),
          ),
          Positioned.fill(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                SiteSpacing.x5,
                SiteSpacing.x6,
                SiteSpacing.x5,
                SiteSpacing.x5,
              ),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  return Stack(
                    alignment: Alignment.center,
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: SiteSpacing.x3,
                        ),
                        child: Image.asset(
                          'assets/images/analysis/left_foot_top.png',
                          fit: BoxFit.contain,
                          filterQuality: FilterQuality.medium,
                        ),
                      ),
                      Positioned.fill(
                        child: AnimatedBuilder(
                          animation: progress,
                          builder: (context, _) => CustomPaint(
                            painter: _CaliperPainter(progress.value),
                          ),
                        ),
                      ),
                      // Etiketler kumpas çizgilerinin uçlarına oturur:
                      // uzunluk sol dikey çizginin ortasında, genişlik yatay
                      // çizginin sağ ucunun üstünde, kemer ise kılavuz
                      // çizgisinin bittiği noktada.
                      _MeasurementTag(
                        progress: progress,
                        delay: 0.55,
                        alignment: const Alignment(-0.86, 0),
                        label: 'UZUNLUK',
                        value: '268 mm',
                      ),
                      _MeasurementTag(
                        progress: progress,
                        delay: 0.7,
                        alignment: const Alignment(0.62, -0.52),
                        label: 'GENİŞLİK',
                        value: '101 mm',
                      ),
                      _MeasurementTag(
                        progress: progress,
                        delay: 0.85,
                        alignment: const Alignment(0.82, 0.06),
                        label: 'KEMER',
                        value: '24 mm',
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ScanChip extends StatelessWidget {
  final Animation<double> progress;

  const _ScanChip({required this.progress});

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: CurvedAnimation(
        parent: progress,
        curve: const Interval(0.1, 0.5, curve: Curves.easeOut),
      ),
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: SiteSpacing.md,
          vertical: SiteSpacing.sm,
        ),
        decoration: BoxDecoration(
          color: SiteColors.primarySoft,
          borderRadius: SiteRadius.chipRadius,
          border: Border.all(color: SiteColors.primarySoftBorder),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.center_focus_strong_outlined,
              size: 15,
              color: SiteColors.primary,
            ),
            const SizedBox(width: SiteSpacing.sm),
            Text('3D TARAMA', style: SiteType.dataLabel(context)),
          ],
        ),
      ),
    );
  }
}

/// Kumpas etiketi: küçük ölçü rozeti.
class _MeasurementTag extends StatelessWidget {
  final Animation<double> progress;
  final double delay;
  final Alignment alignment;
  final String label;
  final String value;

  const _MeasurementTag({
    required this.progress,
    required this.delay,
    required this.alignment,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: alignment,
      child: FadeTransition(
        opacity: CurvedAnimation(
          parent: progress,
          curve: Interval(delay, 1, curve: Curves.easeOut),
        ),
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: SiteSpacing.sm,
            vertical: 6,
          ),
          decoration: BoxDecoration(
            color: SiteColors.surfaceRaised,
            borderRadius: BorderRadius.circular(SiteRadius.sm),
            border: Border.all(color: SiteColors.border),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: SiteType.dataLabel(context).copyWith(fontSize: 9),
              ),
              const SizedBox(height: 1),
              Text(
                value,
                style: SiteType.numeric(context, size: 14),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Milimetrik kağıt zemini.
class _GraphPaperPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final minor = Paint()
      ..color = SiteColors.primary.withValues(alpha: 0.05)
      ..strokeWidth = 1;
    final major = Paint()
      ..color = SiteColors.primary.withValues(alpha: 0.10)
      ..strokeWidth = 1;

    const step = 16.0;
    var index = 0;

    for (var x = 0.0; x < size.width; x += step, index++) {
      canvas.drawLine(
        Offset(x, 0),
        Offset(x, size.height),
        index % 4 == 0 ? major : minor,
      );
    }

    index = 0;
    for (var y = 0.0; y < size.height; y += step, index++) {
      canvas.drawLine(
        Offset(0, y),
        Offset(size.width, y),
        index % 4 == 0 ? major : minor,
      );
    }
  }

  @override
  bool shouldRepaint(_GraphPaperPainter oldDelegate) => false;
}

/// Ayak konturunun etrafına çizilen kumpas çizgileri.
class _CaliperPainter extends CustomPainter {
  final double progress;

  const _CaliperPainter(this.progress);

  @override
  void paint(Canvas canvas, Size size) {
    if (progress <= 0) return;

    final paint = Paint()
      ..color = SiteColors.primary.withValues(alpha: 0.85)
      ..strokeWidth = 1.3
      ..strokeCap = StrokeCap.square;

    final tick = Paint()
      ..color = SiteColors.primary
      ..strokeWidth = 1.6
      ..strokeCap = StrokeCap.square;

    // Dikey uzunluk kumpası (sol kenar).
    final left = size.width * 0.06;
    final top = size.height * 0.04;
    final bottom = size.height * 0.96;
    final verticalEnd = top + (bottom - top) * progress.clamp(0.0, 1.0);

    canvas.drawLine(Offset(left, top), Offset(left, verticalEnd), paint);
    canvas.drawLine(Offset(left - 6, top), Offset(left + 6, top), tick);
    if (progress > 0.98) {
      canvas.drawLine(
        Offset(left - 6, bottom),
        Offset(left + 6, bottom),
        tick,
      );
    }

    // Yatay genişlik kumpası (ön ayak hizası).
    final widthProgress = ((progress - 0.35) / 0.5).clamp(0.0, 1.0);
    if (widthProgress > 0) {
      final y = size.height * 0.30;
      final startX = size.width * 0.20;
      final endX = size.width * 0.80;
      final currentX = startX + (endX - startX) * widthProgress;

      canvas.drawLine(Offset(startX, y), Offset(currentX, y), paint);
      canvas.drawLine(Offset(startX, y - 6), Offset(startX, y + 6), tick);
      if (widthProgress > 0.98) {
        canvas.drawLine(Offset(endX, y - 6), Offset(endX, y + 6), tick);
      }
    }

    // Kemer noktası göstergesi.
    final archProgress = ((progress - 0.6) / 0.4).clamp(0.0, 1.0);
    if (archProgress > 0) {
      final center = Offset(size.width * 0.72, size.height * 0.60);
      canvas.drawCircle(
        center,
        4,
        Paint()..color = SiteColors.primary.withValues(alpha: archProgress),
      );
      canvas.drawLine(
        center,
        Offset(center.dx + 34 * archProgress, center.dy - 22 * archProgress),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(_CaliperPainter oldDelegate) =>
      oldDelegate.progress != progress;
}

/// Ana kartın üstüne binen küçük kartlar için ortak kabuk.
class _FloatingCard extends StatelessWidget {
  final Animation<double> progress;
  final double delay;
  final Widget child;

  const _FloatingCard({
    required this.progress,
    required this.delay,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final animation = CurvedAnimation(
      parent: progress,
      curve: Interval(delay, 1, curve: Curves.easeOutCubic),
    );

    return FadeTransition(
      opacity: animation,
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0, 0.16),
          end: Offset.zero,
        ).animate(animation),
        child: Container(
          padding: const EdgeInsets.all(SiteSpacing.md),
          decoration: BoxDecoration(
            color: SiteColors.surfaceRaised,
            borderRadius: BorderRadius.circular(SiteRadius.lg),
            border: Border.all(color: SiteColors.border),
            boxShadow: SiteShadows.floating,
          ),
          child: child,
        ),
      ),
    );
  }
}

/// Basınç dağılımı önizlemesi — gerçek ısı haritası asset'i.
class _PressurePreview extends StatelessWidget {
  const _PressurePreview();

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Image.asset(
          'assets/heatmaps/left_arch.png',
          height: 86,
          filterQuality: FilterQuality.medium,
        ),
        const SizedBox(width: SiteSpacing.md),
        Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('BASINÇ DAĞILIMI', style: SiteType.dataLabel(context)),
            const SizedBox(height: SiteSpacing.sm),
            Container(
              width: 96,
              height: 6,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(3),
                gradient: const LinearGradient(
                  colors: [
                    Color(0xFF2E8C7A),
                    Color(0xFFB8D64B),
                    Color(0xFFE0402A),
                  ],
                ),
              ),
            ),
            const SizedBox(height: SiteSpacing.xs),
            SizedBox(
              width: 96,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Flexible(
                    child: Text(
                      'düşük',
                      overflow: TextOverflow.ellipsis,
                      style: SiteType.small(context).copyWith(fontSize: 11),
                    ),
                  ),
                  const SizedBox(width: SiteSpacing.xs),
                  Flexible(
                    child: Text(
                      'yüksek',
                      textAlign: TextAlign.end,
                      overflow: TextOverflow.ellipsis,
                      style: SiteType.small(context).copyWith(fontSize: 11),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }
}

/// Uygun tabanlık önizlemesi — iki ürün render'ı.
class _InsolePreview extends StatelessWidget {
  final bool compact;

  const _InsolePreview({required this.compact});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('UYGUN TABANLIK', style: SiteType.dataLabel(context)),
        const SizedBox(height: SiteSpacing.sm),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset(
              'assets/images/products/custom_insole.png',
              height: compact ? 46 : 62,
              filterQuality: FilterQuality.medium,
            ),
            const SizedBox(width: SiteSpacing.sm),
            Image.asset(
              'assets/images/products/sport_insole.png',
              height: compact ? 46 : 62,
              filterQuality: FilterQuality.medium,
            ),
          ],
        ),
      ],
    );
  }
}
