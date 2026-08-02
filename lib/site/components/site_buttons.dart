import 'package:flutter/material.dart';

import '../theme/site_tokens.dart';
import '../theme/site_typography.dart';

enum SiteButtonSize { regular, large }

/// Birincil eylem butonu — dolu Pine Green yüzey.
///
/// | Durum    | Zemin        | Metin | Gölge |
/// |----------|--------------|-------|-------|
/// | default  | primary      | white | yok   |
/// | hover    | primaryHover | white | card  |
/// | focus    | primary      | white | odak halkası |
/// | disabled | border       | textSecondary | yok |
class PrimaryButton extends StatefulWidget {
  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final SiteButtonSize size;
  final bool expand;

  const PrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.size = SiteButtonSize.regular,
    this.expand = false,
  });

  @override
  State<PrimaryButton> createState() => _PrimaryButtonState();
}

class _PrimaryButtonState extends State<PrimaryButton> {
  bool _hovered = false;
  bool _focused = false;

  @override
  Widget build(BuildContext context) {
    final enabled = widget.onPressed != null;
    final isLarge = widget.size == SiteButtonSize.large;

    final background = !enabled
        ? SiteColors.border
        : _hovered
            ? SiteColors.primaryHover
            : SiteColors.primary;

    return _SiteButtonShell(
      onPressed: widget.onPressed,
      onHover: (value) => setState(() => _hovered = value),
      onFocus: (value) => setState(() => _focused = value),
      focused: _focused,
      expand: widget.expand,
      child: AnimatedContainer(
        duration: SiteMotion.duration(context, SiteMotion.fast),
        curve: SiteMotion.curve,
        padding: EdgeInsets.symmetric(
          horizontal: isLarge ? SiteSpacing.x3 : SiteSpacing.x2,
          vertical: isLarge ? SiteSpacing.lg : SiteSpacing.md,
        ),
        decoration: BoxDecoration(
          color: background,
          borderRadius: SiteRadius.buttonRadius,
          boxShadow: _hovered && enabled ? SiteShadows.card : null,
        ),
        child: _ButtonContent(
          label: widget.label,
          icon: widget.icon,
          color: enabled ? SiteColors.textInverse : SiteColors.textSecondary,
          expand: widget.expand,
        ),
      ),
    );
  }
}

/// İkincil eylem butonu — çerçeveli, şeffaf zemin.
class SecondaryButton extends StatefulWidget {
  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final SiteButtonSize size;
  final bool expand;

  /// Koyu yüzeylerde (footer, koyu bant) kullanılacak varyant.
  final bool onDark;

  const SecondaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.size = SiteButtonSize.regular,
    this.expand = false,
    this.onDark = false,
  });

  @override
  State<SecondaryButton> createState() => _SecondaryButtonState();
}

class _SecondaryButtonState extends State<SecondaryButton> {
  bool _hovered = false;
  bool _focused = false;

  @override
  Widget build(BuildContext context) {
    final isLarge = widget.size == SiteButtonSize.large;

    final foreground = widget.onDark
        ? SiteColors.textInverse
        : _hovered
            ? SiteColors.primaryHover
            : SiteColors.textPrimary;

    final borderColor = widget.onDark
        ? (_hovered ? SiteColors.textInverse : SiteColors.borderInverse)
        : (_hovered ? SiteColors.primary : SiteColors.border);

    final background = _hovered
        ? (widget.onDark
            ? SiteColors.textInverse.withValues(alpha: 0.08)
            : SiteColors.primarySoft)
        : Colors.transparent;

    return _SiteButtonShell(
      onPressed: widget.onPressed,
      onHover: (value) => setState(() => _hovered = value),
      onFocus: (value) => setState(() => _focused = value),
      focused: _focused,
      expand: widget.expand,
      child: AnimatedContainer(
        duration: SiteMotion.duration(context, SiteMotion.fast),
        curve: SiteMotion.curve,
        padding: EdgeInsets.symmetric(
          horizontal: isLarge ? SiteSpacing.x3 : SiteSpacing.x2,
          vertical: isLarge ? SiteSpacing.lg : SiteSpacing.md,
        ),
        decoration: BoxDecoration(
          color: background,
          borderRadius: SiteRadius.buttonRadius,
          border: Border.all(color: borderColor, width: 1.4),
        ),
        child: _ButtonContent(
          label: widget.label,
          icon: widget.icon,
          color: foreground,
          expand: widget.expand,
        ),
      ),
    );
  }
}

/// Metin bağlantısı — footer ve satır içi kullanım.
class SiteTextLink extends StatefulWidget {
  final String label;
  final VoidCallback? onPressed;
  final bool onDark;
  final TextStyle? style;

  const SiteTextLink({
    super.key,
    required this.label,
    required this.onPressed,
    this.onDark = false,
    this.style,
  });

  @override
  State<SiteTextLink> createState() => _SiteTextLinkState();
}

class _SiteTextLinkState extends State<SiteTextLink> {
  bool _hovered = false;
  bool _focused = false;

  @override
  Widget build(BuildContext context) {
    final baseColor = widget.onDark
        ? SiteColors.textInverseSecondary
        : SiteColors.textSecondary;

    final color = _hovered
        ? (widget.onDark ? SiteColors.textInverse : SiteColors.primary)
        : baseColor;

    return _SiteButtonShell(
      onPressed: widget.onPressed,
      onHover: (value) => setState(() => _hovered = value),
      onFocus: (value) => setState(() => _focused = value),
      focused: _focused,
      borderRadius: SiteRadius.sm,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: SiteSpacing.xs),
        child: Text(
          widget.label,
          style: (widget.style ?? SiteType.small(context)).copyWith(
            color: color,
            decoration: _hovered ? TextDecoration.underline : null,
            decorationColor: color,
          ),
        ),
      ),
    );
  }
}

class _ButtonContent extends StatelessWidget {
  final String label;
  final IconData? icon;
  final Color color;
  final bool expand;

  const _ButtonContent({
    required this.label,
    required this.icon,
    required this.color,
    required this.expand,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: expand ? MainAxisSize.max : MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (icon != null) ...[
          Icon(icon, size: 18, color: color),
          const SizedBox(width: SiteSpacing.sm),
        ],
        Flexible(
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: SiteType.action(context, strong: true).copyWith(color: color),
          ),
        ),
      ],
    );
  }
}

/// Ortak etkileşim kabuğu: hover, klavye odağı, görünür focus halkası,
/// dokunma hedefi ve semantik buton rolü.
class _SiteButtonShell extends StatelessWidget {
  final Widget child;
  final VoidCallback? onPressed;
  final ValueChanged<bool> onHover;
  final ValueChanged<bool> onFocus;
  final bool focused;
  final bool expand;
  final double borderRadius;

  const _SiteButtonShell({
    required this.child,
    required this.onPressed,
    required this.onHover,
    required this.onFocus,
    required this.focused,
    this.expand = false,
    this.borderRadius = SiteRadius.md,
  });

  @override
  Widget build(BuildContext context) {
    final enabled = onPressed != null;

    return Semantics(
      button: true,
      enabled: enabled,
      child: FocusableActionDetector(
        enabled: enabled,
        mouseCursor:
            enabled ? SystemMouseCursors.click : SystemMouseCursors.basic,
        onShowHoverHighlight: onHover,
        onShowFocusHighlight: onFocus,
        actions: {
          ActivateIntent: CallbackAction<ActivateIntent>(
            onInvoke: (_) {
              onPressed?.call();
              return null;
            },
          ),
        },
        child: GestureDetector(
          onTap: onPressed,
          child: Container(
            width: expand ? double.infinity : null,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(borderRadius + 3),
              border: Border.all(
                color: focused ? SiteColors.focus : Colors.transparent,
                width: 2,
              ),
            ),
            padding: const EdgeInsets.all(2),
            child: child,
          ),
        ),
      ),
    );
  }
}
