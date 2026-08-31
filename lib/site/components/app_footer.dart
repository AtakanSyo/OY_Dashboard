import 'package:flutter/material.dart';

import '../content/site_contact.dart';
import '../site_routes.dart';
import '../theme/site_responsive.dart';
import '../theme/site_tokens.dart';
import '../theme/site_typography.dart';
import 'site_buttons.dart';

/// Site alt bilgisi — Superspec §7.9.
class AppFooter extends StatelessWidget {
  const AppFooter({super.key});

  @override
  Widget build(BuildContext context) {
    final device = context.device;

    final columns = <Widget>[
      const _FooterColumn(
        title: 'Ürünler',
        links: [
          SiteNavLink('Günlük Tabanlıklar', SiteRoutes.tabanliklarGunluk),
          SiteNavLink('Spor Tabanlıkları', SiteRoutes.tabanliklarSpor),
          SiteNavLink('Recovery Ürünleri', SiteRoutes.tabanliklarRecovery),
          SiteNavLink(
            'Veri Güdümlü Ortopedik İş Ayakkabısı',
            SiteRoutes.isAyakkabisi,
          ),
        ],
      ),
      const _FooterColumn(
        title: 'Keşfet',
        links: [
          SiteNavLink('Nasıl Çalışır?', SiteRoutes.nasilCalisir),
          SiteNavLink(
            'Anatomik Kategorilerimiz',
            SiteRoutes.anatomikKategoriler,
          ),
          SiteNavLink('Teknolojilerimiz', SiteRoutes.teknolojiler),
          SiteNavLink('Ölçüm Merkezleri', SiteRoutes.olcumMerkezleri),
          SiteNavLink('SSS', SiteRoutes.sss),
        ],
      ),
      const _FooterColumn(
        title: 'Kurumsal',
        links: [
          SiteNavLink('Hakkımızda', SiteRoutes.hakkimizda),
          SiteNavLink('Ekibimiz', SiteRoutes.ekibimiz),
          SiteNavLink('Kariyer', SiteRoutes.kariyer),
          SiteNavLink('TÜBİTAK Projelerimiz', SiteRoutes.tubitak),
          SiteNavLink('İletişim', SiteRoutes.iletisim),
        ],
      ),
    ];

    return Container(
      width: double.infinity,
      color: SiteColors.surfaceInverse,
      padding: EdgeInsets.symmetric(
        horizontal: device.gutter,
        vertical: device.isMobile ? SiteSpacing.x5 : SiteSpacing.x6,
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            maxWidth: SiteBreakpoints.contentMaxWidth,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (device.isDesktop)
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Expanded(flex: 5, child: _FooterBrand()),
                    const SizedBox(width: SiteSpacing.x5),
                    for (var i = 0; i < columns.length; i++) ...[
                      if (i > 0) const SizedBox(width: SiteSpacing.x3),
                      Expanded(flex: 3, child: columns[i]),
                    ],
                  ],
                )
              else ...[
                const _FooterBrand(),
                const SizedBox(height: SiteSpacing.x4),
                if (device.isTablet)
                  Wrap(
                    spacing: SiteSpacing.x4,
                    runSpacing: SiteSpacing.x4,
                    children: [
                      for (final column in columns)
                        SizedBox(width: 280, child: column),
                    ],
                  )
                else
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      for (var i = 0; i < columns.length; i++) ...[
                        if (i > 0) const SizedBox(height: SiteSpacing.x3),
                        columns[i],
                      ],
                    ],
                  ),
              ],
              const SizedBox(height: SiteSpacing.x5),
              const Divider(color: SiteColors.borderInverse, height: 1),
              const SizedBox(height: SiteSpacing.x2),
              Wrap(
                spacing: SiteSpacing.x2,
                runSpacing: SiteSpacing.sm,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  Text(
                    '© ${DateTime.now().year} OPTIYOU',
                    style: SiteType.small(
                      context,
                    ).copyWith(color: SiteColors.textInverseSecondary),
                  ),
                  SiteTextLink(
                    label: 'Gizlilik Politikası',
                    onDark: true,
                    onPressed: () => SiteNav.go(context, SiteRoutes.gizlilik),
                  ),
                  SiteTextLink(
                    label: 'Kullanım Koşulları',
                    onDark: true,
                    onPressed: () =>
                        SiteNav.go(context, SiteRoutes.kullanimKosullari),
                  ),
                  SiteTextLink(
                    label: 'KVKK Aydınlatma Metni',
                    onDark: true,
                    onPressed: () => SiteNav.go(context, SiteRoutes.kvkk),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FooterBrand extends StatelessWidget {
  const _FooterBrand();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(SiteRadius.sm),
          child: Image.asset(
            'assets/images/branding/logo_footer.png',
            height: 30,
            fit: BoxFit.contain,
          ),
        ),
        const SizedBox(height: SiteSpacing.lg),
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 320),
          child: Text(
            'Dijital ayak ölçümü, veri güdümlü değerlendirme, uygun ürün '
            'seçimi, üretim ve takip altyapısını bir araya getiren yeni nesil '
            'ayak deneyimi platformu.',
            style: SiteType.small(
              context,
            ).copyWith(color: SiteColors.textInverseSecondary, height: 1.65),
          ),
        ),
        const SizedBox(height: SiteSpacing.lg),
        _FooterContactLine(Icons.mail_outline, SiteContact.email),
        _FooterContactLine(
          Icons.call_outlined,
          'İzmir · ${SiteContact.phoneIzmir}',
        ),
        _FooterContactLine(
          Icons.call_outlined,
          'İstanbul · ${SiteContact.phoneIstanbul}',
        ),
        _FooterContactLine(
          Icons.location_on_outlined,
          SiteContact.addressShort,
        ),
      ],
    );
  }
}

class _FooterContactLine extends StatelessWidget {
  const _FooterContactLine(this.icon, this.text);

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: SiteSpacing.sm),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 15, color: SiteColors.primaryOnDark),
          const SizedBox(width: SiteSpacing.sm),
          Expanded(
            child: Text(
              text,
              style: SiteType.small(
                context,
              ).copyWith(color: SiteColors.textInverseSecondary),
            ),
          ),
        ],
      ),
    );
  }
}

class _FooterColumn extends StatelessWidget {
  final String title;
  final List<SiteNavLink> links;

  const _FooterColumn({required this.title, required this.links});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title.toUpperCase(),
          style: SiteType.dataLabel(context, color: SiteColors.textInverse),
        ),
        const SizedBox(height: SiteSpacing.lg),
        for (final link in links)
          Padding(
            padding: const EdgeInsets.only(bottom: SiteSpacing.xs),
            child: SiteTextLink(
              label: link.label,
              onDark: true,
              onPressed: () => SiteNav.go(context, link.route),
            ),
          ),
      ],
    );
  }
}
