import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/site_responsive.dart';
import '../theme/site_tokens.dart';
import '../theme/site_typography.dart';

/// "Sürecimiz" bölümündeki tek bir adım.
///
/// V3 revizyonu: her adım kartın tamamını dolduran bir sahne görselidir;
/// ayrı bir büyük medya paneli yoktur.
class ProcessStep {
  /// Kart üzerindeki sıra numarası ("01").
  final String number;

  /// Kartın alt köşesindeki küçük etiket ("01 · Tarama").
  final String category;

  /// Kart başlığı.
  final String title;

  /// Aktif kartta görünen açıklama.
  final String body;

  /// Kartı dolduran sahne görseli (WebP).
  final String image;

  /// Ekran okuyucu için görsel alt metni.
  final String imageAlt;

  const ProcessStep({
    required this.number,
    required this.category,
    required this.title,
    required this.body,
    required this.image,
    required this.imageAlt,
  });
}

/// Dört sahneli süreç rayı.
///
/// Masaüstü: dört kart aynı ray içinde; hover / klavye odağı aktif kartı
/// yaklaşık %42 genişliğe açar, diğer üçü kalanı paylaşır. Tıklama kartı
/// kilitler, tekrar tıklama açar, `Escape` eşit düzene döner.
/// Tablet: 2×2 ızgara, tıklama açıklamayı açar. Mobil: tek kolon akordeon.
class ProcessShowcase extends StatefulWidget {
  final List<ProcessStep> steps;

  final bool showPatentNotice;
  final String patentTitle;
  final String patentText;

  const ProcessShowcase({
    super.key,
    required this.steps,
    required this.patentTitle,
    required this.patentText,
    this.showPatentNotice = true,
  });

  @override
  State<ProcessShowcase> createState() => _ProcessShowcaseState();
}

class _ProcessShowcaseState extends State<ProcessShowcase> {
  static const double _railHeightDesktop = 610;
  static const double _cardHeightTablet = 470;
  static const double _cardHeightMobileClosed = 220;
  static const double _cardHeightMobileOpen = 520;
  static const double _gap = SiteSpacing.lg;

  int? _hovered;
  int? _locked;

  int? get _active => _locked ?? _hovered;

  bool get _reduceMotion =>
      MediaQuery.maybeOf(context)?.disableAnimations ?? false;

  Duration get _motion =>
      _reduceMotion ? Duration.zero : const Duration(milliseconds: 440);

  void _setHovered(int? index) {
    if (_locked != null) return;
    if (_hovered == index) return;
    setState(() => _hovered = index);
  }

  void _toggleLock(int index) {
    setState(() {
      _locked = _locked == index ? null : index;
      _hovered = null;
    });
  }

  void _reset() {
    if (_locked == null && _hovered == null) return;
    setState(() {
      _locked = null;
      _hovered = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final device = context.device;

    return FocusableActionDetector(
      shortcuts: const <ShortcutActivator, Intent>{
        SingleActivator(LogicalKeyboardKey.escape): DismissIntent(),
      },
      actions: <Type, Action<Intent>>{
        DismissIntent: CallbackAction<DismissIntent>(
          onInvoke: (_) {
            _reset();
            return null;
          },
        ),
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (device.isDesktop)
            _desktopRail()
          else if (device.isTablet)
            _tabletGrid()
          else
            _mobileAccordion(),
          if (device.isDesktop) ...[
            const SizedBox(height: SiteSpacing.md),
            Text(
              'Karta tıklayın; açıklamayı sabitler. Escape ile eşit düzene '
              'dönersiniz.',
              style: SiteType.small(context).copyWith(fontSize: 12),
            ),
          ],
          if (widget.showPatentNotice) ...[
            SizedBox(
              height: device.isCompact ? SiteSpacing.x2 : SiteSpacing.x3,
            ),
            _PatentBand(title: widget.patentTitle, text: widget.patentText),
          ],
        ],
      ),
    );
  }

  Widget _desktopRail() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final steps = widget.steps;
        final n = steps.length;
        final usable = constraints.maxWidth - _gap * (n - 1);
        final active = _active;

        double widthFor(int i) {
          if (active == null) return usable / n;
          if (i == active) return usable * 0.42;
          return usable * 0.58 / (n - 1);
        }

        return SizedBox(
          height: _railHeightDesktop,
          child: Row(
            children: [
              for (var i = 0; i < n; i++) ...[
                if (i > 0) const SizedBox(width: _gap),
                AnimatedContainer(
                  duration: _motion,
                  curve: Curves.easeOutCubic,
                  width: widthFor(i),
                  child: _RailCard(
                    step: steps[i],
                    index: i,
                    total: n,
                    active: active == i,
                    locked: _locked == i,
                    onHover: (v) => _setHovered(v ? i : null),
                    onToggle: () => _toggleLock(i),
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _tabletGrid() {
    final steps = widget.steps;
    return LayoutBuilder(
      builder: (context, constraints) {
        final itemWidth = (constraints.maxWidth - _gap) / 2;
        return Wrap(
          spacing: _gap,
          runSpacing: _gap,
          children: [
            for (var i = 0; i < steps.length; i++)
              SizedBox(
                width: itemWidth,
                height: _cardHeightTablet,
                child: _RailCard(
                  step: steps[i],
                  index: i,
                  total: steps.length,
                  active: _locked == i,
                  locked: _locked == i,
                  onHover: (_) {},
                  onToggle: () => _toggleLock(i),
                ),
              ),
          ],
        );
      },
    );
  }

  Widget _mobileAccordion() {
    final steps = widget.steps;
    return Column(
      children: [
        for (var i = 0; i < steps.length; i++) ...[
          if (i > 0) const SizedBox(height: SiteSpacing.md),
          AnimatedContainer(
            duration: _reduceMotion
                ? Duration.zero
                : const Duration(milliseconds: 360),
            curve: Curves.easeOutCubic,
            height: _locked == i
                ? _cardHeightMobileOpen
                : _cardHeightMobileClosed,
            child: _RailCard(
              step: steps[i],
              index: i,
              total: steps.length,
              active: _locked == i,
              locked: _locked == i,
              onHover: (_) {},
              onToggle: () => _toggleLock(i),
            ),
          ),
        ],
      ],
    );
  }
}

// ── Ray kartı ────────────────────────────────────────────────────────────────

class _RailCard extends StatefulWidget {
  final ProcessStep step;
  final int index;
  final int total;
  final bool active;
  final bool locked;
  final ValueChanged<bool> onHover;
  final VoidCallback onToggle;

  const _RailCard({
    required this.step,
    required this.index,
    required this.total,
    required this.active,
    required this.locked,
    required this.onHover,
    required this.onToggle,
  });

  @override
  State<_RailCard> createState() => _RailCardState();
}

class _RailCardState extends State<_RailCard> {
  final FocusNode _node = FocusNode(debugLabel: 'process-card');
  bool _focused = false;

  @override
  void dispose() {
    _node.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final step = widget.step;
    final active = widget.active;
    final motion = SiteMotion.duration(
      context,
      const Duration(milliseconds: 420),
    );

    return Semantics(
      button: true,
      toggled: widget.locked,
      label:
          '${widget.index + 1}. adım, ${widget.total} adımdan: ${step.title}',
      child: Focus(
        focusNode: _node,
        onFocusChange: (v) {
          setState(() => _focused = v);
          widget.onHover(v);
        },
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
          onEnter: (_) => widget.onHover(true),
          onExit: (_) => widget.onHover(false),
          child: GestureDetector(
            onTap: () {
              _node.requestFocus();
              widget.onToggle();
            },
            child: DecoratedBox(
              decoration: BoxDecoration(
                borderRadius: const BorderRadius.all(Radius.circular(28)),
                border: Border.all(
                  color: _focused
                      ? SiteColors.focus
                      : (active
                            ? SiteColors.primary
                            : SiteColors.borderInverse),
                  width: _focused || active ? 2 : 1,
                ),
                boxShadow: SiteShadows.card,
              ),
              child: ClipRRect(
                borderRadius: const BorderRadius.all(Radius.circular(28)),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    Semantics(
                      image: true,
                      label: step.imageAlt,
                      child: AnimatedScale(
                        duration: motion,
                        scale: active ? 1.04 : 1,
                        child: Image.asset(
                          step.image,
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
                          stops: [0.15, 0.5, 1.0],
                          colors: [
                            Color(0x0A0E1F22),
                            Color(0x730E1F22),
                            Color(0xF20E1F22),
                          ],
                        ),
                      ),
                    ),
                    Positioned(
                      top: SiteSpacing.lg,
                      left: SiteSpacing.lg,
                      child: Container(
                        width: 44,
                        height: 44,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: SiteColors.surfaceInverse.withValues(
                            alpha: 0.5,
                          ),
                          border: Border.all(color: SiteColors.primaryOnDark),
                        ),
                        child: Text(
                          step.number,
                          style: SiteType.numeric(
                            context,
                            size: 13,
                            color: SiteColors.textInverse,
                          ),
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
                            step.category.toUpperCase(),
                            style: SiteType.dataLabel(
                              context,
                              color: SiteColors.primaryOnDark,
                            ),
                          ),
                          const SizedBox(height: SiteSpacing.sm),
                          Text(
                            step.title,
                            maxLines: 3,
                            overflow: TextOverflow.ellipsis,
                            style: SiteType.h3(context).copyWith(
                              color: SiteColors.textInverse,
                              fontSize: 22,
                            ),
                          ),
                          AnimatedSize(
                            duration: motion,
                            curve: Curves.easeOutCubic,
                            alignment: Alignment.topLeft,
                            child: active
                                ? Padding(
                                    padding: const EdgeInsets.only(
                                      top: SiteSpacing.sm,
                                    ),
                                    child: ConstrainedBox(
                                      constraints: const BoxConstraints(
                                        maxWidth: 560,
                                      ),
                                      child: Text(
                                        step.body,
                                        style: SiteType.body(context).copyWith(
                                          color: SiteColors.textOnMedia,
                                          fontSize: 14,
                                        ),
                                      ),
                                    ),
                                  )
                                : const SizedBox(width: double.infinity),
                          ),
                          const SizedBox(height: SiteSpacing.md),
                          Row(
                            children: [
                              Flexible(
                                child: Text(
                                  widget.locked ? 'Sabitlendi' : 'Detayı gör',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: SiteType.action(
                                    context,
                                  ).copyWith(color: SiteColors.primaryOnDark),
                                ),
                              ),
                              const SizedBox(width: SiteSpacing.xs),
                              Icon(
                                widget.locked
                                    ? Icons.lock_outline
                                    : Icons.arrow_forward,
                                size: 15,
                                color: SiteColors.primaryOnDark,
                              ),
                            ],
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
      ),
    );
  }
}

// ── Patent bandı ─────────────────────────────────────────────────────────────

class _PatentBand extends StatelessWidget {
  final String title;
  final String text;

  const _PatentBand({required this.title, required this.text});

  @override
  Widget build(BuildContext context) {
    final compact = context.device.isCompact;

    const icon = SizedBox(
      width: 40,
      height: 40,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: Color(0x1A2E8C7A),
          borderRadius: SiteRadius.chipRadius,
        ),
        child: Icon(
          Icons.verified_outlined,
          size: 20,
          color: SiteColors.primary,
        ),
      ),
    );

    final copy = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(title, style: SiteType.h3(context).copyWith(fontSize: 17)),
        const SizedBox(height: SiteSpacing.xs),
        Text(text, style: SiteType.body(context).copyWith(fontSize: 14)),
      ],
    );

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(SiteSpacing.xl),
      decoration: BoxDecoration(
        color: SiteColors.surfaceRaised,
        borderRadius: SiteRadius.cardRadius,
        border: Border.all(color: SiteColors.primarySoftBorder),
      ),
      child: compact
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                icon,
                const SizedBox(height: SiteSpacing.md),
                copy,
              ],
            )
          : Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                icon,
                const SizedBox(width: SiteSpacing.lg),
                Expanded(child: copy),
              ],
            ),
    );
  }
}
