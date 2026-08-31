import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

import '../../legal/legal_document_registry.dart';
import '../components/app_header.dart';
import '../components/page_hero.dart';
import '../components/site_buttons.dart';
import '../components/site_cards.dart';
import '../components/site_image.dart';
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
///
/// Sayfa içi çapa (anchor): `SiteHeadingBlock.anchorId` dolu bloklara
/// `GlobalKey` verilir; `/route#id` ile açıldığında ya da
/// [SiteAnchorNavBlock] tıklandığında sabit üst bar payı düşülerek
/// hedefe kaydırılır.
class SiteContentPage extends StatefulWidget {
  final SitePageContent content;

  const SiteContentPage({super.key, required this.content});

  @override
  State<SiteContentPage> createState() => _SiteContentPageState();
}

class _SiteContentPageState extends State<SiteContentPage> {
  final Map<String, GlobalKey> _anchorKeys = {};
  bool _handledInitialAnchor = false;

  @override
  void initState() {
    super.initState();
    for (final block in widget.content.blocks) {
      if (block is SiteHeadingBlock && block.anchorId != null) {
        _anchorKeys[block.anchorId!] = GlobalKey();
      }
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_handledInitialAnchor) return;
    _handledInitialAnchor = true;

    final name = ModalRoute.of(context)?.settings.name;
    final fragment = name == null ? null : Uri.tryParse(name)?.fragment;
    if (fragment != null && fragment.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _scrollTo(fragment));
    }
  }

  void _scrollTo(String id) {
    final target = _anchorKeys[id]?.currentContext;
    if (target == null || !mounted) return;

    final box = target.findRenderObject();
    if (box is! RenderBox) return;

    final controller = PrimaryScrollController.maybeOf(context);
    if (controller == null || !controller.hasClients) return;

    final headerOffset = AppHeader.heightFor(context.device) + SiteSpacing.x2;
    final reveal =
        RenderAbstractViewport.of(box).getOffsetToReveal(box, 0).offset -
        headerOffset;

    controller.animateTo(
      reveal.clamp(0.0, controller.position.maxScrollExtent),
      duration: const Duration(milliseconds: 420),
      curve: Curves.easeOutCubic,
    );
  }

  @override
  Widget build(BuildContext context) {
    final blocks = widget.content.blocks;
    final sections = <Widget>[];

    for (var i = 0; i < blocks.length; i++) {
      final block = blocks[i];
      final anchorId = block is SiteHeadingBlock ? block.anchorId : null;
      sections.add(
        KeyedSubtree(
          key: anchorId != null ? _anchorKeys[anchorId] : null,
          child: _SiteBlockView(
            block: block,
            // Bloklar bir açık bir yükseltilmiş yüzeyde dönüşümlü ilerler.
            raised: i.isOdd,
            onAnchorTap: _scrollTo,
          ),
        ),
      );
    }

    return SiteScaffold(
      children: [
        PageHero(
          eyebrow: widget.content.eyebrow,
          title: widget.content.title,
          description: widget.content.description,
        ),
        ...sections,
      ],
    );
  }
}

class _SiteBlockView extends StatelessWidget {
  final SiteBlock block;
  final bool raised;
  final void Function(String anchorId) onAnchorTap;

  const _SiteBlockView({
    required this.block,
    required this.raised,
    required this.onAnchorTap,
  });

  @override
  Widget build(BuildContext context) {
    final background = raised ? SiteColors.surfaceRaised : SiteColors.surface;

    switch (block) {
      case SiteHeadingBlock(:final eyebrow, :final title, :final description):
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
                  style: SiteType.small(
                    context,
                  ).copyWith(fontStyle: FontStyle.italic),
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

      case SiteImageTextBlock():
        return _SiteImageText(
          block: block as SiteImageTextBlock,
          raised: raised,
        );

      case SiteStepsBlock(:final title, :final steps):
        return SiteSection(
          background: background,
          child: _SiteSteps(title: title, steps: steps),
        );

      case SiteStatsBlock(:final stats):
        return SiteSection(
          background: background,
          child: _SiteStats(stats: stats),
        );

      case SiteFigureBlock():
        return SiteSection(
          background: background,
          child: _SiteFigure(block: block as SiteFigureBlock),
        );

      case SiteFaqBlock(:final title, :final items):
        return SiteSection(
          background: background,
          child: _SiteFaq(title: title, items: items),
        );

      case SiteAnchorNavBlock(:final items):
        return SiteSection(
          background: background,
          padding: EdgeInsets.symmetric(
            horizontal: context.device.gutter,
            vertical: SiteSpacing.x3,
          ),
          child: _SiteAnchorNav(items: items, onTap: onAnchorTap),
        );

      case SiteSplitCtaBlock():
        return _SiteSplitCta(block: block as SiteSplitCtaBlock);

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
                style: SiteType.h2(
                  context,
                ).copyWith(color: SiteColors.textInverse),
              ),
              const SizedBox(height: SiteSpacing.lg),
              ConstrainedBox(
                constraints: const BoxConstraints(
                  maxWidth: SiteBreakpoints.proseMaxWidth,
                ),
                child: Text(
                  description,
                  style: SiteType.bodyLarge(
                    context,
                  ).copyWith(color: SiteColors.textInverseSecondary),
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

// ── Görsel + metin ───────────────────────────────────────────────────────────

class _SiteImageText extends StatelessWidget {
  final SiteImageTextBlock block;
  final bool raised;

  const _SiteImageText({required this.block, required this.raised});

  @override
  Widget build(BuildContext context) {
    final compact = context.device.isCompact;
    final background = raised ? SiteColors.surfaceRaised : SiteColors.surface;

    final media = SiteImage(
      asset: block.image,
      semanticLabel: block.imageAlt ?? block.title,
      fit: block.contain ? BoxFit.contain : BoxFit.cover,
      aspectRatio: block.contain ? 4 / 3 : 3 / 2,
      radius: SiteRadius.cardRadius,
      background: block.contain ? SiteColors.surface : null,
    );

    final text = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (block.eyebrow != null) ...[
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CaliperRule(),
              const SizedBox(width: SiteSpacing.md),
              Flexible(
                child: Text(
                  block.eyebrow!.toUpperCase(),
                  style: SiteType.dataLabel(context),
                ),
              ),
            ],
          ),
          const SizedBox(height: SiteSpacing.lg),
        ],
        Text(block.title, style: SiteType.h2(context)),
        if (block.body != null) ...[
          const SizedBox(height: SiteSpacing.lg),
          Text(block.body!, style: SiteType.bodyLarge(context)),
        ],
        if (block.bullets.isNotEmpty) ...[
          const SizedBox(height: SiteSpacing.lg),
          for (final bullet in block.bullets)
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
                  Expanded(child: Text(bullet, style: SiteType.body(context))),
                ],
              ),
            ),
        ],
        if (block.disclaimer != null) ...[
          const SizedBox(height: SiteSpacing.md),
          _DisclaimerNote(block.disclaimer!),
        ],
      ],
    );

    final Widget body;
    if (compact) {
      body = Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          media,
          const SizedBox(height: SiteSpacing.x2),
          text,
        ],
      );
    } else {
      final children = block.imageRight
          ? [
              Expanded(flex: 6, child: text),
              const SizedBox(width: SiteSpacing.x4),
              Expanded(flex: 5, child: media),
            ]
          : [
              Expanded(flex: 5, child: media),
              const SizedBox(width: SiteSpacing.x4),
              Expanded(flex: 6, child: text),
            ];
      body = Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: children,
      );
    }

    return SiteSection(background: background, child: body);
  }
}

// ── Süreç adımları ───────────────────────────────────────────────────────────

class _SiteSteps extends StatelessWidget {
  final String? title;
  final List<({String number, String title, String body})> steps;

  const _SiteSteps({required this.title, required this.steps});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (title != null) ...[
          Text(title!, style: SiteType.h2(context)),
          const SizedBox(height: SiteSpacing.x3),
        ],
        SiteResponsiveGrid(
          columns: steps.length >= 5 ? 5 : steps.length.clamp(1, 4),
          tabletColumns: 2,
          children: [
            for (final step in steps)
              Container(
                padding: const EdgeInsets.all(SiteSpacing.xl),
                decoration: BoxDecoration(
                  color: SiteColors.surfaceRaised,
                  borderRadius: SiteRadius.cardRadius,
                  border: Border.all(color: SiteColors.border),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      step.number,
                      style: SiteType.numeric(
                        context,
                        size: 18,
                        color: SiteColors.primary,
                      ),
                    ),
                    const SizedBox(height: SiteSpacing.sm),
                    const CaliperRule(width: 40),
                    const SizedBox(height: SiteSpacing.md),
                    Text(
                      step.title,
                      style: SiteType.h3(context).copyWith(fontSize: 17),
                    ),
                    const SizedBox(height: SiteSpacing.sm),
                    Text(
                      step.body,
                      style: SiteType.body(context).copyWith(fontSize: 14),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ],
    );
  }
}

// ── Değer şeridi ─────────────────────────────────────────────────────────────

class _SiteStats extends StatelessWidget {
  final List<({String value, String label})> stats;

  const _SiteStats({required this.stats});

  @override
  Widget build(BuildContext context) {
    return SiteResponsiveGrid(
      columns: stats.length.clamp(1, 4),
      tabletColumns: 2,
      children: [
        for (final stat in stats)
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              const CaliperRule(width: 40),
              const SizedBox(height: SiteSpacing.md),
              Text(
                stat.value,
                style: SiteType.h2(context).copyWith(color: SiteColors.primary),
              ),
              const SizedBox(height: SiteSpacing.sm),
              Text(stat.label, style: SiteType.body(context)),
            ],
          ),
      ],
    );
  }
}

// ── Tek görsel ───────────────────────────────────────────────────────────────

class _SiteFigure extends StatelessWidget {
  final SiteFigureBlock block;

  const _SiteFigure({required this.block});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 900),
          child: SiteImage(
            asset: block.image,
            semanticLabel: block.imageAlt ?? block.caption ?? 'Görsel',
            fit: block.contain ? BoxFit.contain : BoxFit.cover,
            aspectRatio: 16 / 9,
            radius: SiteRadius.cardRadius,
            background: SiteColors.surface,
          ),
        ),
        if (block.caption != null) ...[
          const SizedBox(height: SiteSpacing.md),
          Text(block.caption!, style: SiteType.small(context)),
        ],
        if (block.disclaimer != null) ...[
          const SizedBox(height: SiteSpacing.sm),
          _DisclaimerNote(block.disclaimer!),
        ],
      ],
    );
  }
}

class _DisclaimerNote extends StatelessWidget {
  final String text;

  const _DisclaimerNote(this.text);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: SiteSpacing.md,
        vertical: SiteSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: SiteColors.primarySoft,
        borderRadius: SiteRadius.chipRadius,
        border: Border.all(color: SiteColors.primarySoftBorder),
      ),
      child: Text(text, style: SiteType.small(context).copyWith(fontSize: 12)),
    );
  }
}

// ── SSS (accordion) ──────────────────────────────────────────────────────────

class _SiteFaq extends StatefulWidget {
  final String? title;
  final List<({String question, String answer})> items;

  const _SiteFaq({required this.title, required this.items});

  @override
  State<_SiteFaq> createState() => _SiteFaqState();
}

class _SiteFaqState extends State<_SiteFaq> {
  final Set<int> _open = {};

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.title != null) ...[
          Text(widget.title!, style: SiteType.h2(context)),
          const SizedBox(height: SiteSpacing.x2),
        ],
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 820),
          child: Column(
            children: [
              for (var i = 0; i < widget.items.length; i++)
                _FaqRow(
                  item: widget.items[i],
                  open: _open.contains(i),
                  onToggle: () => setState(() {
                    _open.contains(i) ? _open.remove(i) : _open.add(i);
                  }),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class _FaqRow extends StatelessWidget {
  final ({String question, String answer}) item;
  final bool open;
  final VoidCallback onToggle;

  const _FaqRow({
    required this.item,
    required this.open,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: SiteSpacing.md),
      decoration: BoxDecoration(
        color: SiteColors.surfaceRaised,
        borderRadius: SiteRadius.cardRadius,
        border: Border.all(
          color: open ? SiteColors.primarySoftBorder : SiteColors.border,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Semantics(
            button: true,
            expanded: open,
            child: InkWell(
              onTap: onToggle,
              borderRadius: SiteRadius.cardRadius,
              child: Padding(
                padding: const EdgeInsets.all(SiteSpacing.xl),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        item.question,
                        style: SiteType.h3(context).copyWith(fontSize: 17),
                      ),
                    ),
                    const SizedBox(width: SiteSpacing.md),
                    Icon(
                      open
                          ? Icons.remove_circle_outline
                          : Icons.add_circle_outline,
                      color: SiteColors.primary,
                      size: 22,
                    ),
                  ],
                ),
              ),
            ),
          ),
          AnimatedCrossFade(
            firstChild: const SizedBox(width: double.infinity),
            secondChild: Padding(
              padding: const EdgeInsets.fromLTRB(
                SiteSpacing.xl,
                0,
                SiteSpacing.xl,
                SiteSpacing.xl,
              ),
              child: Text(item.answer, style: SiteType.body(context)),
            ),
            crossFadeState: open
                ? CrossFadeState.showSecond
                : CrossFadeState.showFirst,
            duration: SiteMotion.duration(context, SiteMotion.base),
          ),
        ],
      ),
    );
  }
}

// ── Çapa navigasyonu ─────────────────────────────────────────────────────────

class _SiteAnchorNav extends StatelessWidget {
  final List<({String id, String label})> items;
  final void Function(String id) onTap;

  const _SiteAnchorNav({required this.items, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: SiteSpacing.sm,
      runSpacing: SiteSpacing.sm,
      children: [
        for (final item in items)
          Semantics(
            button: true,
            child: InkWell(
              onTap: () => onTap(item.id),
              borderRadius: SiteRadius.chipRadius,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: SiteSpacing.lg,
                  vertical: SiteSpacing.sm,
                ),
                decoration: BoxDecoration(
                  color: SiteColors.surfaceRaised,
                  borderRadius: SiteRadius.chipRadius,
                  border: Border.all(color: SiteColors.border),
                ),
                child: Text(item.label, style: SiteType.action(context)),
              ),
            ),
          ),
      ],
    );
  }
}

// ── İkili CTA ────────────────────────────────────────────────────────────────

class _SiteSplitCta extends StatelessWidget {
  final SiteSplitCtaBlock block;

  const _SiteSplitCta({required this.block});

  @override
  Widget build(BuildContext context) {
    final compact = context.device.isCompact;

    final primary = _CtaCard(
      title: block.primaryTitle,
      label: block.primaryLabel,
      onTap: () => SiteNav.go(context, block.primaryRoute),
      emphasized: true,
    );
    final secondary = _CtaCard(
      title: block.secondaryTitle,
      label: block.secondaryLabel,
      onTap: () => SiteNav.go(context, block.secondaryRoute),
      emphasized: false,
    );

    return SiteSection(
      background: SiteColors.surface,
      child: compact
          ? Column(
              children: [
                primary,
                const SizedBox(height: SiteSpacing.lg),
                secondary,
              ],
            )
          : Row(
              // IntrinsicHeight kod tabanında yasak; iki kartın içeriği kısa
              // ve benzer olduğundan doğal yükseklikte bırakılır.
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: primary),
                const SizedBox(width: SiteSpacing.lg),
                Expanded(child: secondary),
              ],
            ),
    );
  }
}

class _CtaCard extends StatelessWidget {
  final String title;
  final String label;
  final VoidCallback onTap;
  final bool emphasized;

  const _CtaCard({
    required this.title,
    required this.label,
    required this.onTap,
    required this.emphasized,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(SiteSpacing.x3),
      decoration: BoxDecoration(
        color: emphasized ? SiteColors.primary : SiteColors.surfaceInverse,
        borderRadius: SiteRadius.cardRadius,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            title,
            style: SiteType.h3(context).copyWith(color: SiteColors.textInverse),
          ),
          const SizedBox(height: SiteSpacing.xl),
          emphasized
              ? SecondaryButton(
                  label: label,
                  size: SiteButtonSize.large,
                  onDark: true,
                  onPressed: onTap,
                )
              : PrimaryButton(
                  label: label,
                  size: SiteButtonSize.large,
                  onPressed: onTap,
                ),
        ],
      ),
    );
  }
}

/// Yasal metin bölümü — mevcut belge kayıtlarından okunur.
class _LegalSection extends StatelessWidget {
  final String documentCode;
  final Color background;

  const _LegalSection({required this.documentCode, required this.background});

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
