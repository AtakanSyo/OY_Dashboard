import 'dart:async';

import 'package:flutter/material.dart';

import '../site_routes.dart';
import '../theme/site_responsive.dart';
import '../theme/site_tokens.dart';
import '../theme/site_typography.dart';
import 'site_buttons.dart';

/// Sabit üst bar + mega-menü.
///
/// Superspec §6.1: logo solda, ana menü ortada, sağda "Giriş Yap" ve
/// "Tarama Standı İçin Başvur". Mobilde menü hamburgere düşer, iki aksiyon
/// görünürlüğünü korur (§14).
class AppHeader extends StatefulWidget {
  /// Sayfa yukarıdan kaydırıldığında gölge ve daha yoğun zemin uygulanır.
  final bool scrolled;

  final VoidCallback onMenuTap;

  const AppHeader({
    super.key,
    required this.scrolled,
    required this.onMenuTap,
  });

  static double heightFor(SiteDevice device) =>
      device.isMobile ? 64 : (device.isTablet ? 72 : 78);

  @override
  State<AppHeader> createState() => _AppHeaderState();
}

class _AppHeaderState extends State<AppHeader> {
  String? _openMenu;
  bool _hoveringBarItem = false;
  bool _hoveringPanel = false;
  Timer? _closeTimer;

  /// Barda o an görünen öğeler; mega-menü paneli bunun üzerinden çözülür.
  List<SiteNavItem> _visibleItems = siteNavigation;

  @override
  void dispose() {
    _closeTimer?.cancel();
    super.dispose();
  }

  void _requestOpen(SiteNavItem item) {
    _closeTimer?.cancel();
    if (_openMenu != item.label) {
      setState(() => _openMenu = item.label);
    }
  }

  void _requestClose() {
    _closeTimer?.cancel();
    _closeTimer = Timer(const Duration(milliseconds: 120), () {
      if (!mounted) return;
      if (_hoveringBarItem || _hoveringPanel) return;
      setState(() => _openMenu = null);
    });
  }

  void _closeNow() {
    _closeTimer?.cancel();
    if (_openMenu != null) setState(() => _openMenu = null);
  }

  // ── Yerleşim ölçümü ───────────────────────────────────────────────────────
  //
  // Yedi ana menü öğesi + iki aksiyon her ekran genişliğine sığmaz. Sabit bir
  // kırılım noktası yerine gerçek metin genişlikleri ölçülür; sığmayan öğeler
  // "Daha Fazla" menüsüne, hiç sığmıyorsa tüm menü hamburgere düşer.

  double _textWidth(String text, TextStyle style) {
    final painter = TextPainter(
      text: TextSpan(text: text, style: style),
      textDirection: TextDirection.ltr,
      maxLines: 1,
    )..layout();
    return painter.width;
  }

  double _navItemWidth(BuildContext context, SiteNavItem item) {
    return _textWidth(item.shortLabel, SiteType.action(context)) +
        (item.hasMenu ? 20 : 0) +
        SiteSpacing.md * 2 +
        8;
  }

  double _buttonWidth(
    BuildContext context,
    String label, {
    bool hasIcon = false,
  }) {
    return _textWidth(label, SiteType.action(context, strong: true)) +
        SiteSpacing.x2 * 2 +
        (hasIcon ? 26 : 0) +
        8;
  }

  /// Sığmayan öğeleri tek bir "Daha Fazla" menüsünde toplar.
  static SiteNavItem _overflowItem(List<SiteNavItem> items) {
    return SiteNavItem(
      'Daha Fazla',
      children: [
        for (final item in items)
          SiteNavLink(
            item.label,
            item.route ?? item.children.first.route,
          ),
      ],
    );
  }

  List<SiteNavItem>? _resolveBarItems(BuildContext context, double available) {
    if (available <= 0) return null;

    final widths = {
      for (final item in siteNavigation) item.label: _navItemWidth(context, item),
    };

    final total = widths.values.fold<double>(0, (sum, value) => sum + value);
    if (total <= available) return siteNavigation;

    final moreWidth = _navItemWidth(
      context,
      const SiteNavItem('Daha Fazla', children: [SiteNavLink('', '/')]),
    );

    final visible = <SiteNavItem>[];
    final overflow = <SiteNavItem>[];
    var used = moreWidth;

    for (final item in siteNavigation) {
      final width = widths[item.label]!;
      if (overflow.isEmpty && used + width <= available) {
        visible.add(item);
        used += width;
      } else {
        overflow.add(item);
      }
    }

    // En az üç öğe kalmıyorsa bar anlamını yitirir; hamburger daha dürüst.
    if (visible.length < 3) return null;

    return [...visible, _overflowItem(overflow)];
  }

  @override
  Widget build(BuildContext context) {
    final device = context.device;
    final barHeight = AppHeader.heightFor(device);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        AnimatedContainer(
          duration: SiteMotion.duration(context, SiteMotion.base),
          height: barHeight,
          decoration: BoxDecoration(
            color: SiteColors.surfaceRaised,
            border: const Border(
              bottom: BorderSide(color: SiteColors.border),
            ),
            boxShadow: widget.scrolled ? SiteShadows.header : null,
          ),
          padding: EdgeInsets.symmetric(horizontal: device.gutter),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(
                maxWidth: SiteBreakpoints.headerMaxWidth,
              ),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  const logoWidth = 108.0;
                  const actionsGap = SiteSpacing.lg;

                  final actionsWidth = _buttonWidth(
                        context,
                        'Giriş Yap',
                        hasIcon: true,
                      ) +
                      SiteSpacing.md +
                      _buttonWidth(context, 'Tarama İçin Randevu Al');

                  final available = constraints.maxWidth -
                      logoWidth -
                      SiteSpacing.x2 -
                      actionsGap -
                      actionsWidth;

                  final barItems = device.isCompact
                      ? null
                      : _resolveBarItems(context, available);

                  if (barItems == null) {
                    // Dar ekranda menü hamburgere düşer, ancak §14 gereği her
                    // iki aksiyon da barda kalır. Çok dar ekranlarda taşma
                    // yerine küçülmeleri için FittedBox kullanılır.
                    return Row(
                      children: [
                        const _HeaderLogo(),
                        Expanded(
                          child: Align(
                            alignment: Alignment.centerRight,
                            child: FittedBox(
                              fit: BoxFit.scaleDown,
                              alignment: Alignment.centerRight,
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  SecondaryButton(
                                    label: 'Giriş Yap',
                                    onPressed: () =>
                                        SiteNav.go(context, SiteRoutes.login),
                                  ),
                                  const SizedBox(width: SiteSpacing.sm),
                                  PrimaryButton(
                                    label: 'Randevu Al',
                                    onPressed: () => SiteNav.go(
                                      context,
                                      SiteRoutes.taramaRandevusu,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: SiteSpacing.xs),
                        IconButton(
                          onPressed: widget.onMenuTap,
                          icon: const Icon(Icons.menu),
                          color: SiteColors.textPrimary,
                          tooltip: 'Menüyü aç',
                        ),
                      ],
                    );
                  }

                  _visibleItems = barItems;

                  return Row(
                    children: [
                      const _HeaderLogo(),
                      const SizedBox(width: SiteSpacing.x2),
                      Expanded(
                        child: Row(
                          children: [
                            for (final item in barItems)
                              _NavBarItem(
                                item: item,
                                open: _openMenu == item.label,
                                onHover: (hovering) {
                                  _hoveringBarItem = hovering;
                                  if (hovering) {
                                    if (item.hasMenu) {
                                      _requestOpen(item);
                                    } else {
                                      _closeNow();
                                    }
                                  } else {
                                    _requestClose();
                                  }
                                },
                                onTap: () {
                                  if (item.route != null) {
                                    _closeNow();
                                    SiteNav.go(context, item.route!);
                                  } else {
                                    setState(() {
                                      _openMenu = _openMenu == item.label
                                          ? null
                                          : item.label;
                                    });
                                  }
                                },
                              ),
                          ],
                        ),
                      ),
                      const SizedBox(width: actionsGap),
                      SecondaryButton(
                        label: 'Giriş Yap',
                        icon: Icons.person_outline,
                        onPressed: () => SiteNav.go(context, SiteRoutes.login),
                      ),
                      const SizedBox(width: SiteSpacing.md),
                      PrimaryButton(
                        label: 'Tarama İçin Randevu Al',
                        onPressed: () =>
                            SiteNav.go(context, SiteRoutes.taramaRandevusu),
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
        ),
        if (_openMenu != null && !device.isCompact)
          Builder(
            builder: (context) {
              final openItem = _visibleItems
                  .where((item) => item.label == _openMenu)
                  .firstOrNull;

              if (openItem == null || !openItem.hasMenu) {
                return const SizedBox.shrink();
              }

              return MouseRegion(
                onEnter: (_) {
                  _hoveringPanel = true;
                  _closeTimer?.cancel();
                },
                onExit: (_) {
                  _hoveringPanel = false;
                  _requestClose();
                },
                child: MegaMenu(
                  item: openItem,
                  onSelect: (link) {
                    _closeNow();
                    SiteNav.go(context, link.route);
                  },
                ),
              );
            },
          ),
      ],
    );
  }
}

class _HeaderLogo extends StatelessWidget {
  const _HeaderLogo();

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'OPTIYOU ana sayfa',
      button: true,
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: GestureDetector(
          onTap: () => SiteNav.go(context, SiteRoutes.home),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(SiteRadius.sm),
            child: Image.asset(
              'assets/images/branding/logo.png',
              height: context.device.isMobile ? 26 : 32,
              fit: BoxFit.contain,
              filterQuality: FilterQuality.medium,
            ),
          ),
        ),
      ),
    );
  }
}

class _NavBarItem extends StatefulWidget {
  final SiteNavItem item;
  final bool open;
  final ValueChanged<bool> onHover;
  final VoidCallback onTap;

  const _NavBarItem({
    required this.item,
    required this.open,
    required this.onHover,
    required this.onTap,
  });

  @override
  State<_NavBarItem> createState() => _NavBarItemState();
}

class _NavBarItemState extends State<_NavBarItem> {
  bool _hovered = false;
  bool _focused = false;

  @override
  Widget build(BuildContext context) {
    final active = _hovered || widget.open;

    return Semantics(
      button: true,
      child: FocusableActionDetector(
        mouseCursor: SystemMouseCursors.click,
        onShowHoverHighlight: (value) {
          setState(() => _hovered = value);
          widget.onHover(value);
        },
        onShowFocusHighlight: (value) => setState(() => _focused = value),
        actions: {
          ActivateIntent: CallbackAction<ActivateIntent>(
            onInvoke: (_) {
              widget.onTap();
              return null;
            },
          ),
        },
        child: GestureDetector(
          onTap: widget.onTap,
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 2),
            padding: const EdgeInsets.symmetric(
              horizontal: SiteSpacing.md,
              vertical: SiteSpacing.sm,
            ),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(SiteRadius.sm),
              border: Border.all(
                color: _focused ? SiteColors.focus : Colors.transparent,
                width: 2,
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      widget.item.shortLabel,
                      style: SiteType.action(context).copyWith(
                        color: active
                            ? SiteColors.primary
                            : SiteColors.textPrimary,
                      ),
                    ),
                    if (widget.item.hasMenu) ...[
                      const SizedBox(width: 4),
                      AnimatedRotation(
                        turns: widget.open ? 0.5 : 0,
                        duration: SiteMotion.duration(context, SiteMotion.fast),
                        child: Icon(
                          Icons.keyboard_arrow_down,
                          size: 16,
                          color: active
                              ? SiteColors.primary
                              : SiteColors.textSecondary,
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 5),
                AnimatedContainer(
                  duration: SiteMotion.duration(context, SiteMotion.fast),
                  height: 2,
                  width: active ? 18 : 0,
                  decoration: BoxDecoration(
                    color: SiteColors.primary,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Mega-menü paneli. Bar'ın hemen altında, tam genişlikte açılır.
class MegaMenu extends StatelessWidget {
  final SiteNavItem item;
  final ValueChanged<SiteNavLink> onSelect;

  const MegaMenu({
    super.key,
    required this.item,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    final device = context.device;
    final columns = device.isDesktop ? 3 : 2;
    final links = item.children;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: SiteColors.surfaceRaised,
        border: const Border(bottom: BorderSide(color: SiteColors.border)),
        boxShadow: SiteShadows.floating,
      ),
      padding: EdgeInsets.symmetric(
        horizontal: device.gutter,
        vertical: SiteSpacing.x2,
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            maxWidth: SiteBreakpoints.contentMaxWidth,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                item.label.toUpperCase(),
                style: SiteType.dataLabel(context),
              ),
              const SizedBox(height: SiteSpacing.lg),
              LayoutBuilder(
                builder: (context, constraints) {
                  const gap = SiteSpacing.lg;
                  final itemWidth =
                      (constraints.maxWidth - gap * (columns - 1)) / columns;

                  return Wrap(
                    spacing: gap,
                    runSpacing: gap,
                    children: [
                      for (final link in links)
                        SizedBox(
                          width: itemWidth,
                          child: _MegaMenuLink(
                            link: link,
                            onTap: () => onSelect(link),
                          ),
                        ),
                    ],
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MegaMenuLink extends StatefulWidget {
  final SiteNavLink link;
  final VoidCallback onTap;

  const _MegaMenuLink({required this.link, required this.onTap});

  @override
  State<_MegaMenuLink> createState() => _MegaMenuLinkState();
}

class _MegaMenuLinkState extends State<_MegaMenuLink> {
  bool _hovered = false;
  bool _focused = false;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      child: FocusableActionDetector(
        mouseCursor: SystemMouseCursors.click,
        onShowHoverHighlight: (value) => setState(() => _hovered = value),
        onShowFocusHighlight: (value) => setState(() => _focused = value),
        actions: {
          ActivateIntent: CallbackAction<ActivateIntent>(
            onInvoke: (_) {
              widget.onTap();
              return null;
            },
          ),
        },
        child: GestureDetector(
          onTap: widget.onTap,
          child: AnimatedContainer(
            duration: SiteMotion.duration(context, SiteMotion.fast),
            padding: const EdgeInsets.all(SiteSpacing.md),
            decoration: BoxDecoration(
              color: _hovered ? SiteColors.surface : Colors.transparent,
              borderRadius: BorderRadius.circular(SiteRadius.md),
              border: Border.all(
                color: _focused
                    ? SiteColors.focus
                    : (_hovered ? SiteColors.border : Colors.transparent),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        widget.link.label,
                        style: SiteType.action(context, strong: true).copyWith(
                          color: _hovered
                              ? SiteColors.primary
                              : SiteColors.textPrimary,
                        ),
                      ),
                    ),
                    AnimatedOpacity(
                      duration: SiteMotion.duration(context, SiteMotion.fast),
                      opacity: _hovered ? 1 : 0,
                      child: const Icon(
                        Icons.arrow_forward,
                        size: 16,
                        color: SiteColors.primary,
                      ),
                    ),
                  ],
                ),
                if (widget.link.description != null) ...[
                  const SizedBox(height: SiteSpacing.xs),
                  Text(
                    widget.link.description!,
                    style: SiteType.small(context).copyWith(fontSize: 13),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Mobil / tablet menüsü — sağdan açılan panel.
class SiteMobileMenu extends StatelessWidget {
  const SiteMobileMenu({super.key});

  @override
  Widget build(BuildContext context) {
    return Drawer(
      backgroundColor: SiteColors.surfaceRaised,
      width: MediaQuery.sizeOf(context).width.clamp(280, 380).toDouble(),
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                SiteSpacing.x2,
                SiteSpacing.lg,
                SiteSpacing.md,
                SiteSpacing.sm,
              ),
              child: Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(SiteRadius.sm),
                    child: Image.asset(
                      'assets/images/branding/logo.png',
                      height: 26,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                    tooltip: 'Menüyü kapat',
                  ),
                ],
              ),
            ),
            const Divider(height: 1, color: SiteColors.border),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(vertical: SiteSpacing.sm),
                children: [
                  for (final item in siteNavigation)
                    if (item.hasMenu)
                      Theme(
                        data: Theme.of(context).copyWith(
                          dividerColor: Colors.transparent,
                        ),
                        child: ExpansionTile(
                          title: Text(
                            item.label,
                            style: SiteType.action(context, strong: true),
                          ),
                          iconColor: SiteColors.primary,
                          collapsedIconColor: SiteColors.textSecondary,
                          childrenPadding: const EdgeInsets.only(
                            left: SiteSpacing.sm,
                            bottom: SiteSpacing.sm,
                          ),
                          children: [
                            for (final link in item.children)
                              ListTile(
                                dense: true,
                                title: Text(
                                  link.label,
                                  style: SiteType.small(context),
                                ),
                                onTap: () {
                                  Navigator.pop(context);
                                  SiteNav.go(context, link.route);
                                },
                              ),
                          ],
                        ),
                      )
                    else
                      ListTile(
                        title: Text(
                          item.label,
                          style: SiteType.action(context, strong: true),
                        ),
                        onTap: () {
                          Navigator.pop(context);
                          SiteNav.go(context, item.route!);
                        },
                      ),
                ],
              ),
            ),
            const Divider(height: 1, color: SiteColors.border),
            Padding(
              padding: const EdgeInsets.all(SiteSpacing.lg),
              child: Column(
                children: [
                  PrimaryButton(
                    label: 'Tarama İçin Randevu Al',
                    expand: true,
                    onPressed: () {
                      Navigator.pop(context);
                      SiteNav.go(context, SiteRoutes.taramaRandevusu);
                    },
                  ),
                  const SizedBox(height: SiteSpacing.md),
                  SecondaryButton(
                    label: 'Giriş Yap',
                    icon: Icons.person_outline,
                    expand: true,
                    onPressed: () {
                      Navigator.pop(context);
                      SiteNav.go(context, SiteRoutes.login);
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
