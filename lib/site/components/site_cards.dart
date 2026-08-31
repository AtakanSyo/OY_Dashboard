import 'package:flutter/material.dart';

import '../theme/site_responsive.dart';
import '../theme/site_tokens.dart';
import '../theme/site_typography.dart';
import 'site_buttons.dart';
import 'site_section.dart';

/// Süreç adımı kartı — Superspec §7.3.
///
/// Numaralandırma burada süsleme değil: içerik gerçekten sıralı bir akış
/// (tarama → ölçüm → değerlendirme → teslimat), sıra bilgisi okur için anlamlı.
class ProcessStepCard extends StatelessWidget {
  final int index;
  final String title;
  final String description;
  final IconData icon;

  const ProcessStepCard({
    super.key,
    required this.index,
    required this.title,
    required this.description,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return SiteCard(
      padding: const EdgeInsets.all(SiteSpacing.x2),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                index.toString().padLeft(2, '0'),
                style: SiteType.numeric(
                  context,
                  size: 15,
                  color: SiteColors.primary,
                ),
              ),
              const SizedBox(width: SiteSpacing.sm),
              const Expanded(child: CaliperRule(width: double.infinity)),
              const SizedBox(width: SiteSpacing.sm),
              Icon(icon, size: 20, color: SiteColors.primary),
            ],
          ),
          const SizedBox(height: SiteSpacing.xl),
          Text(title, style: SiteType.h3(context)),
          const SizedBox(height: SiteSpacing.sm),
          Text(description, style: SiteType.body(context)),
        ],
      ),
    );
  }
}

/// Ürün / teknoloji kartı — Superspec §7.4.
class TechnologyCard extends StatelessWidget {
  final String imageAsset;
  final String title;
  final String description;
  final VoidCallback onPressed;
  final String actionLabel;

  const TechnologyCard({
    super.key,
    required this.imageAsset,
    required this.title,
    required this.description,
    required this.onPressed,
    this.actionLabel = 'İncele',
  });

  @override
  Widget build(BuildContext context) {
    return SiteCard(
      padding: const EdgeInsets.all(SiteSpacing.xl),
      onTap: onPressed,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 180,
            width: double.infinity,
            decoration: BoxDecoration(
              color: SiteColors.surface,
              borderRadius: BorderRadius.circular(SiteRadius.md),
            ),
            padding: const EdgeInsets.all(SiteSpacing.md),
            child: Image.asset(
              imageAsset,
              fit: BoxFit.contain,
              filterQuality: FilterQuality.medium,
            ),
          ),
          const SizedBox(height: SiteSpacing.xl),
          Text(title, style: SiteType.h3(context)),
          const SizedBox(height: SiteSpacing.sm),
          Text(description, style: SiteType.body(context)),
          const SizedBox(height: SiteSpacing.xl),
          SecondaryButton(label: actionLabel, onPressed: onPressed),
        ],
      ),
    );
  }
}

/// Önerilen model kartı — Superspec §7.6.
class RecommendedProductCard extends StatelessWidget {
  final String badge;
  final String name;
  final String description;
  final List<String> features;
  final String price;
  final String priceNote;
  final String imageAsset;
  final VoidCallback onDetails;
  final VoidCallback onAddToCart;

  const RecommendedProductCard({
    super.key,
    required this.badge,
    required this.name,
    required this.description,
    required this.features,
    required this.price,
    required this.priceNote,
    required this.imageAsset,
    required this.onDetails,
    required this.onAddToCart,
  });

  @override
  Widget build(BuildContext context) {
    final device = context.device;

    return SiteCard(
      padding: const EdgeInsets.all(SiteSpacing.x2),
      interactive: false,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: SiteSpacing.md,
              vertical: 6,
            ),
            decoration: BoxDecoration(
              color: SiteColors.primarySoft,
              borderRadius: SiteRadius.chipRadius,
              border: Border.all(color: SiteColors.primarySoftBorder),
            ),
            child: Text(
              badge.toUpperCase(),
              style: SiteType.dataLabel(context),
            ),
          ),
          const SizedBox(height: SiteSpacing.lg),
          ClipRRect(
            borderRadius: BorderRadius.circular(SiteRadius.md),
            child: Container(
              height: device.isMobile ? 150 : 180,
              width: double.infinity,
              color: SiteColors.surface,
              child: Image.asset(
                imageAsset,
                fit: BoxFit.cover,
                filterQuality: FilterQuality.medium,
              ),
            ),
          ),
          const SizedBox(height: SiteSpacing.xl),
          Text(name, style: SiteType.h3(context)),
          const SizedBox(height: SiteSpacing.sm),
          Text(description, style: SiteType.body(context)),
          const SizedBox(height: SiteSpacing.lg),
          for (final feature in features)
            Padding(
              padding: const EdgeInsets.only(bottom: SiteSpacing.sm),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(
                    Icons.check_circle_outline,
                    size: 17,
                    color: SiteColors.primary,
                  ),
                  const SizedBox(width: SiteSpacing.sm),
                  Expanded(
                    child: Text(feature, style: SiteType.small(context)),
                  ),
                ],
              ),
            ),
          const SizedBox(height: SiteSpacing.lg),
          const Divider(color: SiteColors.border, height: 1),
          const SizedBox(height: SiteSpacing.lg),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(price, style: SiteType.numeric(context, size: 26)),
                  Text(
                    priceNote,
                    style: SiteType.small(context).copyWith(fontSize: 12),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: SiteSpacing.lg),
          if (device.isMobile) ...[
            PrimaryButton(
              label: 'Sepete Ekle',
              expand: true,
              onPressed: onAddToCart,
            ),
            const SizedBox(height: SiteSpacing.sm),
            SecondaryButton(
              label: 'Detayları Gör',
              expand: true,
              onPressed: onDetails,
            ),
          ] else
            Row(
              children: [
                Expanded(
                  child: PrimaryButton(
                    label: 'Sepete Ekle',
                    expand: true,
                    onPressed: onAddToCart,
                  ),
                ),
                const SizedBox(width: SiteSpacing.md),
                Expanded(
                  child: SecondaryButton(
                    label: 'Detayları Gör',
                    expand: true,
                    onPressed: onDetails,
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }
}

/// TÜBİTAK proje kartı — Superspec §8.2.
/// Proje statüleri hardcode edilmez; yalnızca kod ve kapsam sunulur.
class ProjectCard extends StatelessWidget {
  final String code;
  final String title;
  final String description;
  final VoidCallback onPressed;

  const ProjectCard({
    super.key,
    required this.code,
    required this.title,
    required this.description,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return SiteCard(
      onTap: onPressed,
      padding: const EdgeInsets.all(SiteSpacing.x2),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                code,
                style: SiteType.numeric(
                  context,
                  size: 34,
                  color: SiteColors.primary,
                ),
              ),
              const SizedBox(width: SiteSpacing.md),
              const Expanded(child: CaliperRule(width: double.infinity)),
            ],
          ),
          const SizedBox(height: SiteSpacing.lg),
          Text(title, style: SiteType.h3(context)),
          const SizedBox(height: SiteSpacing.sm),
          Text(description, style: SiteType.body(context)),
          const SizedBox(height: SiteSpacing.lg),
          SecondaryButton(label: 'Projeyi İncele', onPressed: onPressed),
        ],
      ),
    );
  }
}

/// Başlık + metin çiftlerinden oluşan sade içerik ızgarası.
class FeatureGrid extends StatelessWidget {
  final List<({String title, String body})> items;
  final int columns;

  const FeatureGrid({super.key, required this.items, this.columns = 2});

  @override
  Widget build(BuildContext context) {
    return SiteResponsiveGrid(
      columns: columns,
      tabletColumns: columns > 2 ? 2 : columns,
      children: [
        for (final item in items)
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const CaliperRule(width: 28),
              const SizedBox(height: SiteSpacing.md),
              Text(item.title, style: SiteType.h3(context)),
              const SizedBox(height: SiteSpacing.sm),
              Text(item.body, style: SiteType.body(context)),
            ],
          ),
      ],
    );
  }
}

/// Sayısal vurgu şeridi.
class StatsStrip extends StatelessWidget {
  final List<({String value, String label})> stats;
  final bool inverse;

  const StatsStrip({super.key, required this.stats, this.inverse = false});

  @override
  Widget build(BuildContext context) {
    final device = context.device;

    final items = [
      for (final stat in stats)
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              stat.value,
              style: SiteType.numeric(
                context,
                size: device.isMobile ? 26 : 32,
                color: inverse
                    ? SiteColors.textInverse
                    : SiteColors.textPrimary,
              ),
            ),
            const SizedBox(height: SiteSpacing.xs),
            Text(
              stat.label,
              style: SiteType.small(context).copyWith(
                color: inverse
                    ? SiteColors.textInverseSecondary
                    : SiteColors.textSecondary,
              ),
            ),
          ],
        ),
    ];

    return SiteResponsiveGrid(
      columns: stats.length.clamp(2, 4),
      tabletColumns: 2,
      children: items,
    );
  }
}

/// Kategori kodu bloğu — Superspec §9.4 (`42-R-M-N-B`).
class CategoryCodeBlock extends StatelessWidget {
  final String code;
  final List<({String part, String meaning})> legend;

  const CategoryCodeBlock({
    super.key,
    required this.code,
    required this.legend,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(SiteSpacing.x2),
      decoration: BoxDecoration(
        color: SiteColors.surfaceRaised,
        borderRadius: SiteRadius.cardRadius,
        border: Border.all(color: SiteColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('UYUM SINIFI KODU', style: SiteType.dataLabel(context)),
          const SizedBox(height: SiteSpacing.md),
          Wrap(
            spacing: SiteSpacing.sm,
            runSpacing: SiteSpacing.sm,
            children: [
              for (final segment in code.split('-'))
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: SiteSpacing.md,
                    vertical: SiteSpacing.sm,
                  ),
                  decoration: BoxDecoration(
                    color: SiteColors.surface,
                    borderRadius: BorderRadius.circular(SiteRadius.sm),
                    border: Border.all(color: SiteColors.primarySoftBorder),
                  ),
                  child: Text(
                    segment,
                    style: SiteType.numeric(context, size: 20),
                  ),
                ),
            ],
          ),
          const SizedBox(height: SiteSpacing.xl),
          for (final entry in legend)
            Padding(
              padding: const EdgeInsets.only(bottom: SiteSpacing.sm),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: 42,
                    child: Text(entry.part, style: SiteType.dataLabel(context)),
                  ),
                  const SizedBox(width: SiteSpacing.md),
                  Expanded(
                    child: Text(entry.meaning, style: SiteType.small(context)),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
