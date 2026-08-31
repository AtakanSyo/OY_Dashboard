import 'package:flutter/material.dart';

import '../theme/site_responsive.dart';
import '../theme/site_tokens.dart';
import '../theme/site_typography.dart';
import 'site_section.dart';

/// İç sayfaların üst bloğu: eyebrow, başlık, açıklama.
class PageHero extends StatelessWidget {
  final String eyebrow;
  final String title;
  final String description;
  final List<Widget> actions;

  const PageHero({
    super.key,
    required this.eyebrow,
    required this.title,
    required this.description,
    this.actions = const [],
  });

  @override
  Widget build(BuildContext context) {
    final device = context.device;

    return SiteSection(
      background: SiteColors.surfaceRaised,
      padding: EdgeInsets.symmetric(
        horizontal: device.gutter,
        vertical: device.isMobile ? SiteSpacing.x5 : SiteSpacing.x7,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CaliperRule(),
              const SizedBox(width: SiteSpacing.md),
              Flexible(
                child: Text(
                  eyebrow.toUpperCase(),
                  overflow: TextOverflow.ellipsis,
                  style: SiteType.dataLabel(context),
                ),
              ),
            ],
          ),
          const SizedBox(height: SiteSpacing.xl),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 860),
            child: Text(title, style: SiteType.h1(context)),
          ),
          const SizedBox(height: SiteSpacing.xl),
          ConstrainedBox(
            constraints: const BoxConstraints(
              maxWidth: SiteBreakpoints.proseMaxWidth,
            ),
            child: Text(description, style: SiteType.bodyLarge(context)),
          ),
          if (actions.isNotEmpty) ...[
            const SizedBox(height: SiteSpacing.x3),
            Wrap(
              spacing: SiteSpacing.md,
              runSpacing: SiteSpacing.md,
              children: actions,
            ),
          ],
        ],
      ),
    );
  }
}
