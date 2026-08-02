import 'package:flutter/material.dart';

import '../theme/site_tokens.dart';
import '../theme/site_typography.dart';
import 'site_section.dart';

/// Model bulma modülü — Superspec §7.5.
///
/// Üç parametre alır: ayakkabı numarası, kemer tipi, yürüme dengesi.
/// Gerçek öneri motoru bağlanmadığı için seçimler yalnızca vitrin amaçlıdır;
/// motor entegrasyonu için giriş noktası açık bırakılmıştır (§4.3).
class SelectionWizard extends StatelessWidget {
  final int size;
  final String arch;
  final String balance;

  final ValueChanged<int> onSizeChanged;
  final ValueChanged<String> onArchChanged;
  final ValueChanged<String> onBalanceChanged;

  static const List<int> sizes = [
    36, 37, 38, 39, 40, 41, 42, 43, 44, 45, 46,
  ];
  static const List<String> archTypes = ['Düşük', 'Orta', 'Yüksek'];
  static const List<String> balanceTypes = ['İç basış', 'Nötr', 'Dış basış'];

  const SelectionWizard({
    super.key,
    required this.size,
    required this.arch,
    required this.balance,
    required this.onSizeChanged,
    required this.onArchChanged,
    required this.onBalanceChanged,
  });

  @override
  Widget build(BuildContext context) {
    return SiteCard(
      interactive: false,
      padding: const EdgeInsets.all(SiteSpacing.x2),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const CaliperRule(width: 28),
              const SizedBox(width: SiteSpacing.md),
              Text('SEÇİM', style: SiteType.dataLabel(context)),
            ],
          ),
          const SizedBox(height: SiteSpacing.xl),
          Text('Ayakkabı numarası', style: SiteType.action(context, strong: true)),
          const SizedBox(height: SiteSpacing.md),
          _SizeSelector(value: size, onChanged: onSizeChanged),
          const SizedBox(height: SiteSpacing.x2),
          Text('Kemer tipi', style: SiteType.action(context, strong: true)),
          const SizedBox(height: SiteSpacing.md),
          _ChipRow(
            options: archTypes,
            value: arch,
            onChanged: onArchChanged,
          ),
          const SizedBox(height: SiteSpacing.x2),
          Text('Yürüme dengesi', style: SiteType.action(context, strong: true)),
          const SizedBox(height: SiteSpacing.md),
          _ChipRow(
            options: balanceTypes,
            value: balance,
            onChanged: onBalanceChanged,
          ),
          const SizedBox(height: SiteSpacing.x2),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(SiteSpacing.md),
            decoration: BoxDecoration(
              color: SiteColors.surface,
              borderRadius: BorderRadius.circular(SiteRadius.md),
              border: Border.all(color: SiteColors.border),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.info_outline,
                  size: 16,
                  color: SiteColors.primary,
                ),
                const SizedBox(width: SiteSpacing.sm),
                Expanded(
                  child: Text(
                    'Seçimleriniz yalnızca ön öneri içindir. Kesin uyum, '
                    'tarama ve basınç ölçümü sonrası belirlenir.',
                    style: SiteType.small(context).copyWith(fontSize: 13),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SizeSelector extends StatelessWidget {
  final int value;
  final ValueChanged<int> onChanged;

  const _SizeSelector({required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: SiteSpacing.md),
      decoration: BoxDecoration(
        borderRadius: SiteRadius.buttonRadius,
        border: Border.all(color: SiteColors.border),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<int>(
          value: value,
          isExpanded: true,
          borderRadius: SiteRadius.buttonRadius,
          icon: const Icon(
            Icons.keyboard_arrow_down,
            color: SiteColors.textSecondary,
          ),
          style: SiteType.action(context, strong: true),
          items: [
            for (final option in SelectionWizard.sizes)
              DropdownMenuItem<int>(
                value: option,
                child: Text(
                  '$option',
                  style: SiteType.action(context, strong: true),
                ),
              ),
          ],
          onChanged: (selected) {
            if (selected != null) onChanged(selected);
          },
        ),
      ),
    );
  }
}

class _ChipRow extends StatelessWidget {
  final List<String> options;
  final String value;
  final ValueChanged<String> onChanged;

  const _ChipRow({
    required this.options,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: SiteSpacing.sm,
      runSpacing: SiteSpacing.sm,
      children: [
        for (final option in options)
          _SelectableChip(
            label: option,
            selected: option == value,
            onTap: () => onChanged(option),
          ),
      ],
    );
  }
}

class _SelectableChip extends StatefulWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _SelectableChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  State<_SelectableChip> createState() => _SelectableChipState();
}

class _SelectableChipState extends State<_SelectableChip> {
  bool _hovered = false;
  bool _focused = false;

  @override
  Widget build(BuildContext context) {
    final selected = widget.selected;

    return Semantics(
      button: true,
      selected: selected,
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
            padding: const EdgeInsets.symmetric(
              horizontal: SiteSpacing.lg,
              vertical: SiteSpacing.md,
            ),
            decoration: BoxDecoration(
              color: selected
                  ? SiteColors.primary
                  : (_hovered ? SiteColors.primarySoft : Colors.transparent),
              borderRadius: SiteRadius.chipRadius,
              border: Border.all(
                color: _focused
                    ? SiteColors.focus
                    : selected
                        ? SiteColors.primary
                        : SiteColors.border,
                width: _focused ? 2 : 1.2,
              ),
            ),
            child: Text(
              widget.label,
              style: SiteType.action(context).copyWith(
                color: selected ? SiteColors.textInverse : SiteColors.textPrimary,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
