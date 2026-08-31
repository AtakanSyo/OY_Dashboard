import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../components/page_hero.dart';
import '../components/site_buttons.dart';
import '../components/site_scaffold.dart';
import '../components/site_section.dart';
import '../content/site_contact.dart';
import '../theme/site_responsive.dart';
import '../theme/site_tokens.dart';
import '../theme/site_typography.dart';

// ═══════════════════════════════════════════════════════════════════════════
//  Ortak form parçaları
// ═══════════════════════════════════════════════════════════════════════════

InputDecoration _dec(String hint) {
  const border = OutlineInputBorder(
    borderRadius: SiteRadius.buttonRadius,
    borderSide: BorderSide(color: SiteColors.border),
  );
  return InputDecoration(
    hintText: hint,
    filled: true,
    fillColor: SiteColors.surfaceRaised,
    isDense: true,
    contentPadding: const EdgeInsets.symmetric(
      horizontal: SiteSpacing.lg,
      vertical: SiteSpacing.lg,
    ),
    border: border,
    enabledBorder: border,
    focusedBorder: const OutlineInputBorder(
      borderRadius: SiteRadius.buttonRadius,
      borderSide: BorderSide(color: SiteColors.primary, width: 1.6),
    ),
  );
}

class _LabeledField extends StatelessWidget {
  const _LabeledField({required this.label, required this.child});

  final String label;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: SiteSpacing.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: SiteType.action(context, strong: true)),
          const SizedBox(height: SiteSpacing.sm),
          child,
        ],
      ),
    );
  }
}

String? _vRequired(String? v) =>
    (v == null || v.trim().isEmpty) ? 'Bu alan zorunludur.' : null;

String? _vEmail(String? v) {
  final r = _vRequired(v);
  if (r != null) return r;
  final ok = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(v!.trim());
  return ok ? null : 'Geçerli bir e-posta girin.';
}

// ═══════════════════════════════════════════════════════════════════════════
//  Ölçüm Merkezleri — arama + şehir filtresi + liste
// ═══════════════════════════════════════════════════════════════════════════

/// Tarama noktaları [siteScanPoints] içinde tek kaynaktan gelir. Tam adres
/// ve yol tarifi randevu onayında paylaşılır.
const List<ScanPoint> _centers = siteScanPoints;

class MeasurementCentersPage extends StatefulWidget {
  const MeasurementCentersPage({super.key});

  @override
  State<MeasurementCentersPage> createState() => _MeasurementCentersPageState();
}

class _MeasurementCentersPageState extends State<MeasurementCentersPage> {
  final _query = TextEditingController();
  String _city = 'Tümü';

  List<String> get _cities => [
    'Tümü',
    ...{for (final c in _centers) c.city},
  ];

  List<ScanPoint> get _filtered {
    final q = _query.text.trim().toLowerCase();
    return _centers.where((c) {
      final cityOk = _city == 'Tümü' || c.city == _city;
      final queryOk =
          q.isEmpty ||
          c.name.toLowerCase().contains(q) ||
          c.city.toLowerCase().contains(q) ||
          c.area.toLowerCase().contains(q);
      return cityOk && queryOk;
    }).toList();
  }

  @override
  void dispose() {
    _query.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final compact = context.device.isCompact;
    final results = _filtered;

    return SiteScaffold(
      children: [
        const PageHero(
          eyebrow: 'Ölçüm Merkezleri',
          title: 'Sana en yakın ölçüm noktası',
          description:
              '3D ayak tarama ve plantar basınç ölçümü anlaşmalı klinik, '
              'eczane ve mağazalarda yapılır. Ölçüm yaklaşık iki dakika '
              'sürer.',
        ),
        SiteSection(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Flex(
                direction: compact ? Axis.vertical : Axis.horizontal,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    flex: compact ? 0 : 3,
                    child: _LabeledField(
                      label: 'Ara',
                      child: TextField(
                        controller: _query,
                        decoration: _dec('Merkez adı, şehir veya ilçe'),
                        onChanged: (_) => setState(() {}),
                      ),
                    ),
                  ),
                  if (!compact) const SizedBox(width: SiteSpacing.lg),
                  Expanded(
                    flex: compact ? 0 : 2,
                    child: _LabeledField(
                      label: 'Şehir',
                      child: DropdownButtonFormField<String>(
                        initialValue: _city,
                        isExpanded: true,
                        decoration: _dec('Şehir'),
                        items: [
                          for (final c in _cities)
                            DropdownMenuItem(value: c, child: Text(c)),
                        ],
                        onChanged: (v) => setState(() => _city = v ?? 'Tümü'),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: SiteSpacing.md),
              if (results.isEmpty)
                _EmptyState(
                  icon: Icons.location_off_outlined,
                  title: 'Bu aramaya uygun merkez bulunamadı',
                  message:
                      'Farklı bir şehir seçin ya da aramayı temizleyin. Yeni '
                      'noktalar eklendikçe burada listelenecek.',
                )
              else
                Column(
                  children: [
                    for (final c in results)
                      Container(
                        margin: const EdgeInsets.only(bottom: SiteSpacing.md),
                        padding: const EdgeInsets.all(SiteSpacing.xl),
                        decoration: BoxDecoration(
                          color: SiteColors.surfaceRaised,
                          borderRadius: SiteRadius.cardRadius,
                          border: Border.all(color: SiteColors.border),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'TARAMA NOKTASI',
                              style: SiteType.dataLabel(context),
                            ),
                            const SizedBox(height: SiteSpacing.sm),
                            Text(
                              c.name,
                              style: SiteType.h3(
                                context,
                              ).copyWith(fontSize: 18),
                            ),
                            const SizedBox(height: SiteSpacing.xs),
                            _CenterLine(
                              icon: Icons.location_on_outlined,
                              text: c.area,
                            ),
                            const SizedBox(height: SiteSpacing.xs),
                            _CenterLine(
                              icon: Icons.call_outlined,
                              text: c.phone,
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              const SizedBox(height: SiteSpacing.lg),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(SiteSpacing.xl),
                decoration: BoxDecoration(
                  color: SiteColors.primarySoft,
                  borderRadius: SiteRadius.cardRadius,
                  border: Border.all(color: SiteColors.primarySoftBorder),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'KONUM VE YOL TARİFİ',
                      style: SiteType.dataLabel(context),
                    ),
                    const SizedBox(height: SiteSpacing.sm),
                    Text(
                      'Yukarıdaki noktalar ilçe / yerleşke düzeyinde verilmiştir. '
                      'Tam adres, kat/oda bilgisi ve yol tarifi randevu onay '
                      'e-postasında paylaşılır. İzmir için '
                      '${SiteContact.phoneIzmir}, İstanbul için '
                      '${SiteContact.phoneIstanbul} numarasını '
                      'arayabilirsiniz.',
                      style: SiteType.small(context),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _CenterLine extends StatelessWidget {
  const _CenterLine({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 2),
          child: Icon(icon, size: 16, color: SiteColors.primary),
        ),
        const SizedBox(width: SiteSpacing.sm),
        Expanded(child: Text(text, style: SiteType.body(context))),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
//  İletişim — kanallar + mesaj formu (mailto)
// ═══════════════════════════════════════════════════════════════════════════

class ContactPage extends StatefulWidget {
  const ContactPage({super.key});

  @override
  State<ContactPage> createState() => _ContactPageState();
}

class _ContactPageState extends State<ContactPage> {
  static const String _inbox = SiteContact.email;

  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _subject = TextEditingController();
  final _message = TextEditingController();

  String? _status;
  bool _isError = false;

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _subject.dispose();
    _message.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final subject = _subject.text.trim().isEmpty
        ? 'Web sitesi iletişim formu'
        : _subject.text.trim();
    final body =
        'Ad: ${_name.text.trim()}\n'
        'E-posta: ${_email.text.trim()}\n\n'
        '${_message.text.trim()}';

    final uri = Uri(
      scheme: 'mailto',
      path: _inbox,
      query:
          'subject=${Uri.encodeComponent(subject)}'
          '&body=${Uri.encodeComponent(body)}',
    );

    final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!mounted) return;
    setState(() {
      if (ok) {
        _isError = false;
        _status =
            'E-posta uygulamanız hazır mesajla açıldı. Göndererek iletebilir '
            'ya da doğrudan $_inbox adresine yazabilirsiniz.';
      } else {
        _isError = true;
        _status =
            'E-posta uygulaması açılamadı. Lütfen doğrudan $_inbox adresine '
            'yazın.';
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final compact = context.device.isCompact;

    final channels = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('İLETİŞİM KANALLARI', style: SiteType.dataLabel(context)),
        const SizedBox(height: SiteSpacing.lg),
        _ChannelRow(icon: Icons.mail_outline, label: 'E-posta', value: _inbox),
        _ChannelRow(
          icon: Icons.call_outlined,
          label: 'Telefon — İzmir',
          value: SiteContact.phoneIzmir,
        ),
        _ChannelRow(
          icon: Icons.call_outlined,
          label: 'Telefon — İstanbul',
          value: SiteContact.phoneIstanbul,
        ),
        _ChannelRow(
          icon: Icons.location_on_outlined,
          label: 'Merkez',
          value: SiteContact.addressShort,
        ),
        _ChannelRow(
          icon: Icons.place_outlined,
          label: 'Tarama noktaları',
          value: siteScanPoints.map((p) => p.name).join('\n'),
        ),
        _ChannelRow(
          icon: Icons.handshake_outlined,
          label: 'Kurumsal iş birliği',
          value: 'Klinik, eczane, mağaza ve iş yerleri için',
        ),
      ],
    );

    final form = Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Mesaj gönderin', style: SiteType.h3(context)),
          const SizedBox(height: SiteSpacing.lg),
          _LabeledField(
            label: 'Ad Soyad',
            child: TextFormField(
              controller: _name,
              decoration: _dec('Adınız ve soyadınız'),
              validator: _vRequired,
            ),
          ),
          _LabeledField(
            label: 'E-posta',
            child: TextFormField(
              controller: _email,
              keyboardType: TextInputType.emailAddress,
              decoration: _dec('ornek@eposta.com'),
              validator: _vEmail,
            ),
          ),
          _LabeledField(
            label: 'Konu',
            child: TextFormField(
              controller: _subject,
              decoration: _dec('Kısa bir başlık'),
            ),
          ),
          _LabeledField(
            label: 'Mesajınız',
            child: TextFormField(
              controller: _message,
              maxLines: 5,
              decoration: _dec('Nasıl yardımcı olabiliriz?'),
              validator: _vRequired,
            ),
          ),
          if (_status != null) ...[
            Container(
              width: double.infinity,
              margin: const EdgeInsets.only(bottom: SiteSpacing.md),
              padding: const EdgeInsets.all(SiteSpacing.lg),
              decoration: BoxDecoration(
                color: _isError
                    ? const Color(0x14B4322A)
                    : SiteColors.primarySoft,
                borderRadius: SiteRadius.buttonRadius,
                border: Border.all(
                  color: _isError
                      ? const Color(0x33B4322A)
                      : SiteColors.primarySoftBorder,
                ),
              ),
              child: Text(_status!, style: SiteType.small(context)),
            ),
          ],
          PrimaryButton(
            label: 'E-posta ile Gönder',
            icon: Icons.mail_outline,
            size: SiteButtonSize.large,
            onPressed: _submit,
          ),
        ],
      ),
    );

    return SiteScaffold(
      children: [
        const PageHero(
          eyebrow: 'İletişim',
          title: 'Bize ulaşın',
          description:
              'Kurumsal iş birliği, tarama standı başvurusu ve ürün soruları '
              'için iletişime geçebilirsiniz.',
        ),
        SiteSection(
          child: compact
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    channels,
                    const SizedBox(height: SiteSpacing.x3),
                    form,
                  ],
                )
              : Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(flex: 4, child: channels),
                    const SizedBox(width: SiteSpacing.x4),
                    Expanded(flex: 6, child: form),
                  ],
                ),
        ),
      ],
    );
  }
}

class _ChannelRow extends StatelessWidget {
  const _ChannelRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: SiteSpacing.lg),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: SiteColors.primary),
          const SizedBox(width: SiteSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: SiteType.small(context)),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: SiteType.body(
                    context,
                  ).copyWith(fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
//  Haberler — filtre + boş durum
// ═══════════════════════════════════════════════════════════════════════════

class _NewsItem {
  const _NewsItem({
    required this.category,
    required this.date,
    required this.title,
    required this.summary,
  });

  final String category;
  final String date;
  final String title;
  final String summary;
}

/// Yayımlanacak haber olmadığında MD §8 gereği açıklayıcı boş durum gösterilir.
const List<_NewsItem> _news = [];

class NewsPage extends StatefulWidget {
  const NewsPage({super.key});

  @override
  State<NewsPage> createState() => _NewsPageState();
}

class _NewsPageState extends State<NewsPage> {
  String _category = 'Tümü';

  List<String> get _categories => ['Tümü', 'Duyuru', 'Basın', 'Etkinlik'];

  List<_NewsItem> get _filtered => _news
      .where((n) => _category == 'Tümü' || n.category == _category)
      .toList();

  @override
  Widget build(BuildContext context) {
    final results = _filtered;

    return SiteScaffold(
      children: [
        const PageHero(
          eyebrow: 'Kurumsal',
          title: 'Haberler / Basın',
          description: 'Duyurular, basın bültenleri ve etkinlik notları.',
        ),
        SiteSection(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Wrap(
                spacing: SiteSpacing.sm,
                runSpacing: SiteSpacing.sm,
                children: [
                  for (final c in _categories)
                    _FilterChip(
                      label: c,
                      selected: _category == c,
                      onTap: () => setState(() => _category = c),
                    ),
                ],
              ),
              const SizedBox(height: SiteSpacing.x2),
              if (results.isEmpty)
                _EmptyState(
                  icon: Icons.article_outlined,
                  title: 'Henüz yayımlanmış içerik yok',
                  message:
                      'Duyuru, basın bülteni ve etkinlik notları burada '
                      'yayımlanacak. Sorularınız için iletişim sayfasından '
                      'bize ulaşabilirsiniz.',
                )
              else
                Column(
                  children: [
                    for (final n in results)
                      Container(
                        margin: const EdgeInsets.only(bottom: SiteSpacing.md),
                        padding: const EdgeInsets.all(SiteSpacing.xl),
                        decoration: BoxDecoration(
                          color: SiteColors.surfaceRaised,
                          borderRadius: SiteRadius.cardRadius,
                          border: Border.all(color: SiteColors.border),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${n.category.toUpperCase()} · ${n.date}',
                              style: SiteType.dataLabel(context),
                            ),
                            const SizedBox(height: SiteSpacing.sm),
                            Text(n.title, style: SiteType.h3(context)),
                            const SizedBox(height: SiteSpacing.xs),
                            Text(n.summary, style: SiteType.body(context)),
                          ],
                        ),
                      ),
                  ],
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: selected,
      child: InkWell(
        onTap: onTap,
        borderRadius: SiteRadius.chipRadius,
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: SiteSpacing.lg,
            vertical: SiteSpacing.sm,
          ),
          decoration: BoxDecoration(
            color: selected ? SiteColors.primary : SiteColors.surfaceRaised,
            borderRadius: SiteRadius.chipRadius,
            border: Border.all(
              color: selected ? SiteColors.primary : SiteColors.border,
            ),
          ),
          child: Text(
            label,
            style: SiteType.action(context).copyWith(
              color: selected
                  ? SiteColors.textInverse
                  : SiteColors.textSecondary,
            ),
          ),
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({
    required this.icon,
    required this.title,
    required this.message,
  });

  final IconData icon;
  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(SiteSpacing.x3),
      decoration: BoxDecoration(
        color: SiteColors.surfaceRaised,
        borderRadius: SiteRadius.cardRadius,
        border: Border.all(color: SiteColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 28, color: SiteColors.primary),
          const SizedBox(height: SiteSpacing.md),
          Text(title, style: SiteType.h3(context).copyWith(fontSize: 18)),
          const SizedBox(height: SiteSpacing.sm),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: Text(message, style: SiteType.body(context)),
          ),
        ],
      ),
    );
  }
}
