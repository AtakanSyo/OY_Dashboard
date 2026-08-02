import 'package:flutter/material.dart';

import '../../legal/legal_document_registry.dart';
import '../components/page_hero.dart';
import '../components/site_buttons.dart';
import '../components/site_cards.dart';
import '../components/site_scaffold.dart';
import '../components/site_section.dart';
import '../content/site_page_content.dart';
import '../site_routes.dart';
import '../theme/site_responsive.dart';
import '../theme/site_tokens.dart';
import '../theme/site_typography.dart';

/// Menü sayfalarının ortak render'ı.
///
/// İçerik [sitePageContent] içinde veri olarak tutulur; bu sayfa yalnızca
/// blokları ekrana basar. Böylece yeni bir menü sayfası eklemek tek bir
/// içerik kaydı yazmak demektir.
class SiteContentPage extends StatelessWidget {
  final SitePageContent content;

  const SiteContentPage({super.key, required this.content});

  @override
  Widget build(BuildContext context) {
    final sections = <Widget>[];

    for (var i = 0; i < content.blocks.length; i++) {
      sections.add(
        _SiteBlockView(
          block: content.blocks[i],
          // Bloklar bir açık bir yükseltilmiş yüzeyde dönüşümlü ilerler.
          raised: i.isOdd,
        ),
      );
    }

    return SiteScaffold(
      children: [
        PageHero(
          eyebrow: content.eyebrow,
          title: content.title,
          description: content.description,
        ),
        ...sections,
      ],
    );
  }
}

class _SiteBlockView extends StatelessWidget {
  final SiteBlock block;
  final bool raised;

  const _SiteBlockView({required this.block, required this.raised});

  @override
  Widget build(BuildContext context) {
    final background =
        raised ? SiteColors.surfaceRaised : SiteColors.surface;

    switch (block) {
      case SiteHeadingBlock(
          :final eyebrow,
          :final title,
          :final description,
        ):
        return SiteSection(
          background: background,
          child: SectionHeading(
            eyebrow: eyebrow,
            title: title,
            description: description,
          ),
        );

      case SiteFeaturesBlock(:final items, :final columns):
        return SiteSection(
          background: background,
          child: FeatureGrid(items: items, columns: columns),
        );

      case SiteBulletsBlock(:final title, :final bullets, :final note):
        return SiteSection(
          background: background,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (title != null) ...[
                Text(title, style: SiteType.h2(context)),
                const SizedBox(height: SiteSpacing.x2),
              ],
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 820),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    for (final bullet in bullets)
                      Padding(
                        padding: const EdgeInsets.only(bottom: SiteSpacing.md),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              margin: const EdgeInsets.only(top: 9),
                              width: 14,
                              height: 2,
                              color: SiteColors.primary,
                            ),
                            const SizedBox(width: SiteSpacing.md),
                            Expanded(
                              child: Text(
                                bullet,
                                style: SiteType.bodyLarge(context),
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
              if (note != null) ...[
                const SizedBox(height: SiteSpacing.lg),
                Text(
                  note,
                  style: SiteType.small(context).copyWith(
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ],
          ),
        );

      case SiteCategoryCodeBlock(:final code, :final legend):
        return SiteSection(
          background: background,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 720),
            child: CategoryCodeBlock(code: code, legend: legend),
          ),
        );

      case SiteProjectsBlock(:final projects):
        return SiteSection(
          background: background,
          child: SiteResponsiveGrid(
            columns: 2,
            tabletColumns: 2,
            children: [
              for (final project in projects)
                ProjectCard(
                  code: project.code,
                  title: project.title,
                  description: project.description,
                  onPressed: () => SiteNav.go(context, project.route),
                ),
            ],
          ),
        );

      case SiteProductsBlock(:final products):
        return SiteSection(
          background: background,
          child: SiteResponsiveGrid(
            columns: 3,
            tabletColumns: 2,
            children: [
              for (final product in products)
                TechnologyCard(
                  imageAsset: product.image,
                  title: product.title,
                  description: product.description,
                  onPressed: () => SiteNav.go(context, product.route),
                ),
            ],
          ),
        );

      case SitePlaceholderBlock(:final label, :final note):
        return SiteSection(
          background: background,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 720),
                child: AssetPlaceholder(label: label, height: 220),
              ),
              if (note != null) ...[
                const SizedBox(height: SiteSpacing.lg),
                ConstrainedBox(
                  constraints: const BoxConstraints(
                    maxWidth: SiteBreakpoints.proseMaxWidth,
                  ),
                  child: Text(note, style: SiteType.small(context)),
                ),
              ],
            ],
          ),
        );

      case SiteLegalBlock(:final documentCode):
        return _LegalSection(
          documentCode: documentCode,
          background: background,
        );

      case SiteCtaBlock(
          :final title,
          :final description,
          :final primaryLabel,
          :final primaryRoute,
          :final secondaryLabel,
          :final secondaryRoute,
        ):
        return SiteSection(
          inverse: true,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: SiteType.h2(context).copyWith(
                  color: SiteColors.textInverse,
                ),
              ),
              const SizedBox(height: SiteSpacing.lg),
              ConstrainedBox(
                constraints: const BoxConstraints(
                  maxWidth: SiteBreakpoints.proseMaxWidth,
                ),
                child: Text(
                  description,
                  style: SiteType.bodyLarge(context).copyWith(
                    color: SiteColors.textInverseSecondary,
                  ),
                ),
              ),
              const SizedBox(height: SiteSpacing.x3),
              Wrap(
                spacing: SiteSpacing.md,
                runSpacing: SiteSpacing.md,
                children: [
                  PrimaryButton(
                    label: primaryLabel,
                    size: SiteButtonSize.large,
                    onPressed: () => SiteNav.go(context, primaryRoute),
                  ),
                  if (secondaryLabel != null && secondaryRoute != null)
                    SecondaryButton(
                      label: secondaryLabel,
                      size: SiteButtonSize.large,
                      onDark: true,
                      onPressed: () => SiteNav.go(context, secondaryRoute),
                    ),
                ],
              ),
            ],
          ),
        );
    }
  }
}

/// Yasal metin bölümü — mevcut belge kayıtlarından okunur.
class _LegalSection extends StatelessWidget {
  final String documentCode;
  final Color background;

  const _LegalSection({
    required this.documentCode,
    required this.background,
  });

  @override
  Widget build(BuildContext context) {
    final document = LegalDocumentRegistry.findByCode(documentCode);

    if (document == null) {
      return SiteSection(
        background: background,
        child: const AssetPlaceholder(
          label: 'Belge bulunamadı',
          height: 160,
          icon: Icons.description_outlined,
        ),
      );
    }

    return SiteSection(
      background: background,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: SiteSpacing.md,
            runSpacing: SiteSpacing.xs,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Text(
                document.title.toUpperCase(),
                style: SiteType.dataLabel(context),
              ),
              Text(
                'v${document.version}',
                style: SiteType.small(context).copyWith(fontSize: 12),
              ),
            ],
          ),
          const SizedBox(height: SiteSpacing.x2),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 820),
            child: SelectionArea(
              child: Text(
                document.content,
                style: SiteType.body(context).copyWith(height: 1.7),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
