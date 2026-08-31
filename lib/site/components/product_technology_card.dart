import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/site_tokens.dart';
import '../theme/site_typography.dart';

/// Patlatılmış görünümdeki tek bir katman: ad + kısa açıklama.
class ProductLayer {
  final String title;
  final String description;

  const ProductLayer(this.title, this.description);
}

/// "Veri Güdümlü Ayak Giyim Teknolojileri" bölümündeki bir ürün.
///
/// V3: kart iki yüzlüdür — ön yüz montajlı ürün, arka yüz patlatılmış
/// katmanlar. Katman etiketleri raster görsele gömülü değil, widget'tır.
class ProductTechnology {
  /// Küçük kategori etiketi ("VERİ GÜDÜMLÜ ANATOMİK TABANLIK").
  final String category;

  /// Ürün adı ("OY Orthopedic").
  final String name;

  /// Kısa slogan.
  final String slogan;

  /// Ürün adının altındaki kısa açıklama.
  final String description;

  /// Montajlı (ön yüz) görsel — şeffaf WebP.
  final String frontImage;

  /// Ekran okuyucu için ön görsel açıklaması.
  final String frontImageAlt;

  /// Patlatılmış (arka yüz) görsel — şeffaf WebP.
  final String backImage;

  /// Katmanlar, görseldeki yukarıdan aşağı sırayla.
  final List<ProductLayer> layers;

  /// Karbon ürünü — arka planda radial gradient kullanılır.
  final bool carbon;

  const ProductTechnology({
    required this.category,
    required this.name,
    required this.slogan,
    required this.description,
    required this.frontImage,
    required this.frontImageAlt,
    required this.backImage,
    required this.layers,
    this.carbon = false,
  });
}

/// İki yüzlü ürün kartı. Tıklama / Enter / Space kartı kalıcı çevirir; grup
/// koordinasyonu ve `Escape` sıfırlaması üst bölümdedir (bkz. ana sayfa).
class ProductTechnologyCard extends StatefulWidget {
  final ProductTechnology data;
  final bool flipped;
  final VoidCallback onToggle;

  const ProductTechnologyCard({
    super.key,
    required this.data,
    required this.flipped,
    required this.onToggle,
  });

  @override
  State<ProductTechnologyCard> createState() => _ProductTechnologyCardState();
}

class _ProductTechnologyCardState extends State<ProductTechnologyCard> {
  final FocusNode _node = FocusNode(debugLabel: 'product-card');
  bool _focused = false;

  @override
  void dispose() {
    _node.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final data = widget.data;
    final reduceMotion =
        MediaQuery.maybeOf(context)?.disableAnimations ?? false;

    final front = _ProductFront(data: data);
    final back = _ProductBack(data: data);

    final Widget faces;
    if (reduceMotion) {
      faces = AnimatedCrossFade(
        firstChild: front,
        secondChild: back,
        crossFadeState: widget.flipped
            ? CrossFadeState.showSecond
            : CrossFadeState.showFirst,
        duration: const Duration(milliseconds: 1),
        layoutBuilder: (top, topKey, bottom, bottomKey) => Stack(
          fit: StackFit.expand,
          children: [
            Positioned.fill(key: bottomKey, child: bottom),
            Positioned.fill(key: topKey, child: top),
          ],
        ),
      );
    } else {
      faces = TweenAnimationBuilder<double>(
        tween: Tween(end: widget.flipped ? math.pi : 0),
        duration: const Duration(milliseconds: 640),
        curve: Curves.easeInOutCubic,
        builder: (context, angle, _) {
          final showBack = angle > math.pi / 2;
          return Transform(
            alignment: Alignment.center,
            transform: Matrix4.identity()
              ..setEntry(3, 2, 0.001)
              ..rotateY(angle),
            child: showBack
                ? Transform(
                    alignment: Alignment.center,
                    transform: Matrix4.identity()..rotateY(math.pi),
                    child: back,
                  )
                : front,
          );
        },
      );
    }

    return Semantics(
      button: true,
      toggled: widget.flipped,
      label: widget.flipped
          ? '${data.name} — katmanlı görünüm'
          : '${data.name} — ürün görünümü',
      child: Focus(
        focusNode: _node,
        onFocusChange: (v) => setState(() => _focused = v),
        onKeyEvent: (node, event) {
          if (event is KeyDownEvent &&
              (event.logicalKey == LogicalKeyboardKey.enter ||
                  event.logicalKey == LogicalKeyboardKey.space)) {
            widget.onToggle();
            return KeyEventResult.handled;
          }
          return KeyEventResult.ignored;
        },
        child: MouseRegion(
          cursor: SystemMouseCursors.click,
          child: GestureDetector(
            onTap: () {
              _node.requestFocus();
              widget.onToggle();
            },
            child: DecoratedBox(
              decoration: BoxDecoration(
                borderRadius: SiteRadius.cardRadius,
                border: Border.all(
                  color: _focused ? SiteColors.focus : Colors.transparent,
                  width: 2,
                ),
              ),
              child: faces,
            ),
          ),
        ),
      ),
    );
  }
}

// ── Ön yüz ───────────────────────────────────────────────────────────────────

class _ProductFront extends StatelessWidget {
  final ProductTechnology data;

  const _ProductFront({required this.data});

  @override
  Widget build(BuildContext context) {
    return _FaceShell(
      carbon: data.carbon,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: Text(
                  data.category,
                  overflow: TextOverflow.ellipsis,
                  style: SiteType.dataLabel(
                    context,
                    color: SiteColors.primaryOnDark,
                  ),
                ),
              ),
              Text(
                'ÖN',
                style: SiteType.small(context).copyWith(
                  color: SiteColors.textInverseSecondary,
                  fontSize: 10,
                  letterSpacing: 1,
                ),
              ),
            ],
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: SiteSpacing.md),
              child: Semantics(
                image: true,
                label: data.frontImageAlt,
                child: Image.asset(
                  data.frontImage,
                  fit: BoxFit.contain,
                  filterQuality: FilterQuality.medium,
                  errorBuilder: (context, error, stack) =>
                      const _ImageFallback(),
                ),
              ),
            ),
          ),
          Text(
            data.name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: SiteType.h3(
              context,
            ).copyWith(color: SiteColors.textInverse, fontSize: 21),
          ),
          const SizedBox(height: SiteSpacing.xs),
          Text(
            data.slogan,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: SiteType.action(
              context,
            ).copyWith(color: SiteColors.primaryOnDark),
          ),
          const SizedBox(height: SiteSpacing.sm),
          Text(
            data.description,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
            style: SiteType.small(
              context,
            ).copyWith(color: SiteColors.textOnMedia, height: 1.45),
          ),
          const SizedBox(height: SiteSpacing.md),
          Row(
            children: [
              Flexible(
                child: Text(
                  'Katmanları gör',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: SiteType.action(
                    context,
                  ).copyWith(color: SiteColors.primaryOnDark),
                ),
              ),
              const SizedBox(width: SiteSpacing.xs),
              const Icon(
                Icons.flip_camera_android_outlined,
                size: 15,
                color: SiteColors.primaryOnDark,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Arka yüz ─────────────────────────────────────────────────────────────────

class _ProductBack extends StatelessWidget {
  final ProductTechnology data;

  const _ProductBack({required this.data});

  @override
  Widget build(BuildContext context) {
    return _FaceShell(
      carbon: data.carbon,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: Text(
                  data.name,
                  overflow: TextOverflow.ellipsis,
                  style: SiteType.h3(
                    context,
                  ).copyWith(color: SiteColors.textInverse, fontSize: 18),
                ),
              ),
              Text(
                'KATMANLAR',
                style: SiteType.small(context).copyWith(
                  color: SiteColors.textInverseSecondary,
                  fontSize: 10,
                  letterSpacing: 1,
                ),
              ),
            ],
          ),
          const SizedBox(height: SiteSpacing.sm),
          Expanded(
            flex: 3,
            child: ExcludeSemantics(
              child: Image.asset(
                data.backImage,
                fit: BoxFit.contain,
                filterQuality: FilterQuality.medium,
                errorBuilder: (context, error, stack) => const _ImageFallback(),
              ),
            ),
          ),
          const SizedBox(height: SiteSpacing.sm),
          for (var i = 0; i < data.layers.length; i++) ...[
            if (i > 0) const SizedBox(height: SiteSpacing.sm),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  margin: const EdgeInsets.only(top: 7),
                  width: 16,
                  height: 1.5,
                  color: SiteColors.primaryOnDark,
                ),
                const SizedBox(width: SiteSpacing.sm),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        data.layers[i].title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: SiteType.small(context).copyWith(
                          color: SiteColors.textInverse,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        data.layers[i].description,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: SiteType.small(context).copyWith(
                          color: SiteColors.textInverseSecondary,
                          fontSize: 11,
                          height: 1.3,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _FaceShell extends StatelessWidget {
  final Widget child;
  final bool carbon;

  const _FaceShell({required this.child, required this.carbon});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(SiteSpacing.x2),
      decoration: BoxDecoration(
        gradient: carbon
            ? const RadialGradient(
                center: Alignment(0.1, -0.2),
                radius: 1.1,
                colors: [Color(0xFF174957), Color(0xFF081B23)],
              )
            : const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF0A2029), Color(0xFF123D47)],
              ),
        borderRadius: SiteRadius.cardRadius,
        border: Border.all(color: SiteColors.borderInverse),
        boxShadow: SiteShadows.card,
      ),
      child: child,
    );
  }
}

class _ImageFallback extends StatelessWidget {
  const _ImageFallback();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Icon(
        Icons.image_outlined,
        size: 28,
        color: SiteColors.textInverseSecondary,
      ),
    );
  }
}
