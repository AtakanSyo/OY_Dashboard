import 'package:flutter/material.dart';

import '../theme/site_responsive.dart';
import '../theme/site_tokens.dart';
import '../theme/site_typography.dart';

/// Sayfa bölümü kabuğu: dikey ritim, azami içerik genişliği ve yatay gutter.
class SiteSection extends StatelessWidget {
  final Widget child;

  /// Koyu bant varyantı (Deep Teal zemin).
  final bool inverse;

  /// Bölümün kendi zemin rengini ezmek için.
  final Color? background;

  final EdgeInsets? padding;

  const SiteSection({
    super.key,
    required this.child,
    this.inverse = false,
    this.background,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    final device = context.device;

    return Container(
      width: double.infinity,
      color: background ??
          (inverse ? SiteColors.surfaceInverse : SiteColors.surface),
      padding: padding ??
          EdgeInsets.symmetric(
            vertical: device.sectionSpacing,
            horizontal: device.gutter,
          ),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            maxWidth: SiteBreakpoints.contentMaxWidth,
          ),
          // Genişliği zorlamazsak, metin ağırlıklı bölümler kendi doğal
          // genişliğine küçülüp ortalanır ve sol hizalama ızgarası bozulur.
          child: SizedBox(width: double.infinity, child: child),
        ),
      ),
    );
  }
}

/// Sitenin imza motifi: kumpas / ölçü çizelgesi çizgisi.
///
/// Bölüm eyebrow'larının yanında ve ölçüm kartlarında tekrar eder.
/// Süsleme değil; "her şey ölçülür" mesajının yapısal karşılığıdır.
class CaliperRule extends StatelessWidget {
  final Color color;
  final double width;

  const CaliperRule({
    super.key,
    this.color = SiteColors.primary,
    this.width = 44,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      height: 12,
      child: CustomPaint(painter: _CaliperRulePainter(color)),
    );
  }
}

class _CaliperRulePainter extends CustomPainter {
  final Color color;

  const _CaliperRulePainter(this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.4
      ..strokeCap = StrokeCap.square;

    final baseline = size.height - 1;
    canvas.drawLine(Offset(0, baseline), Offset(size.width, baseline), paint);

    const tickCount = 4;
    for (var i = 0; i < tickCount; i++) {
      final x = size.width * (i / (tickCount - 1));
      final isMajor = i == 0 || i == tickCount - 1;
      final height = isMajor ? size.height : size.height * 0.45;
      canvas.drawLine(
        Offset(x.clamp(0.7, size.width - 0.7), baseline),
        Offset(x.clamp(0.7, size.width - 0.7), baseline - height),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(_CaliperRulePainter oldDelegate) =>
      oldDelegate.color != color;
}

/// Bölüm başlığı: eyebrow (kumpas çizgisi + etiket), başlık ve açıklama.
class SectionHeading extends StatelessWidget {
  final String eyebrow;
  final String title;
  final String? description;
  final bool inverse;
  final bool centered;

  const SectionHeading({
    super.key,
    required this.eyebrow,
    required this.title,
    this.description,
    this.inverse = false,
    this.centered = false,
  });

  @override
  Widget build(BuildContext context) {
    final accent = inverse ? SiteColors.textInverse : SiteColors.primary;

    return Column(
      crossAxisAlignment:
          centered ? CrossAxisAlignment.center : CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            CaliperRule(color: accent),
            const SizedBox(width: SiteSpacing.md),
            Flexible(
              child: Text(
                eyebrow.toUpperCase(),
                overflow: TextOverflow.ellipsis,
                style: SiteType.dataLabel(context, color: accent),
              ),
            ),
          ],
        ),
        const SizedBox(height: SiteSpacing.lg),
        Text(
          title,
          textAlign: centered ? TextAlign.center : TextAlign.start,
          style: SiteType.h2(context).copyWith(
            color: inverse ? SiteColors.textInverse : SiteColors.textPrimary,
          ),
        ),
        if (description != null) ...[
          const SizedBox(height: SiteSpacing.lg),
          ConstrainedBox(
            constraints: const BoxConstraints(
              maxWidth: SiteBreakpoints.proseMaxWidth,
            ),
            child: Text(
              description!,
              textAlign: centered ? TextAlign.center : TextAlign.start,
              style: SiteType.bodyLarge(context).copyWith(
                color: inverse
                    ? SiteColors.textInverseSecondary
                    : SiteColors.textSecondary,
              ),
            ),
          ),
        ],
      ],
    );
  }
}

/// Hover'da hafifçe yükselen kart yüzeyi. Tüm kart bileşenlerinin tabanı.
class SiteCard extends StatefulWidget {
  final Widget child;
  final EdgeInsets padding;
  final VoidCallback? onTap;
  final bool inverse;
  final bool interactive;

  const SiteCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(SiteSpacing.x2),
    this.onTap,
    this.inverse = false,
    this.interactive = true,
  });

  @override
  State<SiteCard> createState() => _SiteCardState();
}

class _SiteCardState extends State<SiteCard> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final lifted = _hovered && widget.interactive;

    final card = AnimatedContainer(
      duration: SiteMotion.duration(context, SiteMotion.base),
      curve: SiteMotion.curve,
      transform: Matrix4.translationValues(0, lifted ? -4 : 0, 0),
      padding: widget.padding,
      decoration: BoxDecoration(
        color: widget.inverse
            ? SiteColors.surfaceInverseRaised
            : SiteColors.surfaceRaised,
        borderRadius: SiteRadius.cardRadius,
        border: Border.all(
          color: lifted
              ? SiteColors.primarySoftBorder
              : (widget.inverse ? SiteColors.borderInverse : SiteColors.border),
        ),
        boxShadow: lifted ? SiteShadows.cardHover : SiteShadows.card,
      ),
      child: widget.child,
    );

    if (widget.onTap == null && !widget.interactive) return card;

    return MouseRegion(
      cursor: widget.onTap != null
          ? SystemMouseCursors.click
          : SystemMouseCursors.basic,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(onTap: widget.onTap, child: card),
    );
  }
}

/// Eksik görsel yerine kullanılan işaretli yüzey.
///
/// Superspec §12.1: kritik olmayan görseller placeholder ile geçilir ve
/// gerçek veriymiş gibi sunulmaz. Bu bileşen her zaman "görsel bekleniyor"
/// olduğunu açıkça belirtir.
class AssetPlaceholder extends StatelessWidget {
  final String label;
  final double? height;
  final double aspectRatio;
  final IconData icon;

  const AssetPlaceholder({
    super.key,
    required this.label,
    this.height,
    this.aspectRatio = 4 / 3,
    this.icon = Icons.image_outlined,
  });

  @override
  Widget build(BuildContext context) {
    final content = DecoratedBox(
      decoration: BoxDecoration(
        color: SiteColors.primarySoft,
        borderRadius: SiteRadius.cardRadius,
        border: Border.all(color: SiteColors.primarySoftBorder),
      ),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(SiteSpacing.lg),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: SiteColors.primary, size: 26),
              const SizedBox(height: SiteSpacing.sm),
              Text(
                label,
                textAlign: TextAlign.center,
                style: SiteType.dataLabel(context),
              ),
              const SizedBox(height: SiteSpacing.xs),
              Text(
                'Görsel bekleniyor',
                textAlign: TextAlign.center,
                style: SiteType.small(context).copyWith(fontSize: 12),
              ),
            ],
          ),
        ),
      ),
    );

    if (height != null) {
      return SizedBox(height: height, width: double.infinity, child: content);
    }

    return AspectRatio(aspectRatio: aspectRatio, child: content);
  }
}

/// Basit yatay/dikey akış: ekran daraldığında kartları alt alta indirir.
class SiteResponsiveGrid extends StatelessWidget {
  final List<Widget> children;

  /// Desktop'ta kolon sayısı. Tablet'te [tabletColumns], mobilde 1 olur.
  final int columns;
  final int tabletColumns;
  final double? gap;

  const SiteResponsiveGrid({
    super.key,
    required this.children,
    this.columns = 3,
    this.tabletColumns = 2,
    this.gap,
  });

  @override
  Widget build(BuildContext context) {
    final device = context.device;
    final spacing = gap ?? device.gridGap;

    final count = device.responsiveColumns(
      desktop: columns,
      tablet: tabletColumns,
    );

    if (count <= 1) {
      return Column(
        children: [
          for (var i = 0; i < children.length; i++) ...[
            if (i > 0) SizedBox(height: spacing),
            children[i],
          ],
        ],
      );
    }

    // Kartlar doğal yüksekliklerinde kalır.
    //
    // Satır içi eşit yükseklik için `IntrinsicHeight` denendi ve iki kez
    // üretimde taşmaya yol açtı: iç yükseklik hesabı, sarmalanan metnin gerçek
    // satır sayısını her genişlikte doğru tahmin etmiyor ve kart tıkır tıkır
    // 26 px taşıyor. Kozmetik bir kazanç için taşma riski alınmıyor.
    return LayoutBuilder(
      builder: (context, constraints) {
        final itemWidth =
            (constraints.maxWidth - spacing * (count - 1)) / count;

        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: [
            for (final child in children)
              SizedBox(width: itemWidth, child: child),
          ],
        );
      },
    );
  }
}

extension on SiteDevice {
  int responsiveColumns({required int desktop, required int tablet}) {
    switch (this) {
      case SiteDevice.mobile:
        return 1;
      case SiteDevice.tablet:
        return tablet;
      case SiteDevice.desktop:
        return desktop;
    }
  }
}
