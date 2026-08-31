import 'package:flutter/material.dart';

import '../theme/site_tokens.dart';
import '../theme/site_typography.dart';

/// Site genelinde tutarlı görsel: sabit oran (layout shift yok), erişilebilir
/// alt metin, yüklenemezse sakin bir yüzey ve makul decode boyutu.
///
/// MD §12: hero için `precacheImage`, alt bölümler için `cacheWidth`; ürün /
/// sonuç görsellerinde `BoxFit.contain`, lifestyle sahnelerinde `cover`.
class SiteImage extends StatelessWidget {
  final String asset;
  final String semanticLabel;
  final BoxFit fit;

  /// Görselin oturduğu kutu oranı. Yükseklik önceden bilindiği için görsel
  /// gelmeden yer ayrılır.
  final double aspectRatio;

  final BorderRadius radius;

  /// `contain` görsellerde şeffaf alanların arkasına konan yüzey rengi.
  final Color? background;

  /// Dekoratif görsellerde `true` → ekran okuyucudan gizlenir.
  final bool decorative;

  const SiteImage({
    super.key,
    required this.asset,
    required this.semanticLabel,
    this.fit = BoxFit.cover,
    this.aspectRatio = 3 / 2,
    this.radius = const BorderRadius.all(Radius.circular(SiteRadius.lg)),
    this.background,
    this.decorative = false,
  });

  @override
  Widget build(BuildContext context) {
    final dpr = MediaQuery.maybeOf(context)?.devicePixelRatio ?? 1.0;

    Widget image = LayoutBuilder(
      builder: (context, constraints) {
        final logicalWidth = constraints.maxWidth.isFinite
            ? constraints.maxWidth
            : 1200.0;
        final cacheWidth = (logicalWidth * dpr).clamp(64.0, 2400.0).round();

        return Image.asset(
          asset,
          fit: fit,
          cacheWidth: cacheWidth,
          filterQuality: FilterQuality.medium,
          errorBuilder: (context, error, stack) => const _ImageFallback(),
        );
      },
    );

    if (background != null) {
      image = ColoredBox(color: background!, child: image);
    }

    final framed = ClipRRect(
      borderRadius: radius,
      child: AspectRatio(aspectRatio: aspectRatio, child: image),
    );

    if (decorative) {
      return ExcludeSemantics(child: framed);
    }
    return Semantics(image: true, label: semanticLabel, child: framed);
  }
}

class _ImageFallback extends StatelessWidget {
  const _ImageFallback();

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: SiteColors.primarySoft,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.image_outlined,
              color: SiteColors.primary,
              size: 26,
            ),
            const SizedBox(height: SiteSpacing.xs),
            Text(
              'Görsel yüklenemedi',
              style: SiteType.small(context).copyWith(fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }
}
