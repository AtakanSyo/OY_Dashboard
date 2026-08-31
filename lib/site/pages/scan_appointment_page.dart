import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../components/page_hero.dart';
import '../components/site_buttons.dart';
import '../components/site_scaffold.dart';
import '../components/site_section.dart';
import '../data/scan_appointment_service.dart';
import '../site_routes.dart';
import '../theme/site_tokens.dart';
import '../theme/site_typography.dart';

/// "Tarama Yap" akışı: bireysel randevu ve kurumsal talep formları.
///
/// Gönderimde talep Supabase'e yazılır ve `send-scan-appointment` edge
/// function OPTIYOU gelen kutusuna + talep sahibine (KVKK aydınlatma özeti)
/// e-posta gönderir.
class ScanAppointmentPage extends StatefulWidget {
  const ScanAppointmentPage({super.key, this.initialCorporate = false});

  /// Kurumsal sekmesiyle açar.
  final bool initialCorporate;

  @override
  State<ScanAppointmentPage> createState() => _ScanAppointmentPageState();
}

class _ScanAppointmentPageState extends State<ScanAppointmentPage> {
  late bool _corporate = widget.initialCorporate;

  final ScanAppointmentService _service = ScanAppointmentService();

  @override
  Widget build(BuildContext context) {
    return SiteScaffold(
      children: [
        const PageHero(
          eyebrow: 'Randevu',
          title: 'Tarama Yap',
          description:
              '3D ayak tarama ve plantar basınç ölçümü anlaşmalı noktalarda '
              'yapılır. Bireysel randevunuzu oluşturun ya da kurumunuz için '
              'talep gönderin; bilgileriniz ekibimize iletilir ve size '
              'dönüş yapılır.',
        ),
        SiteSection(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _AudienceSwitch(
                corporate: _corporate,
                onChanged: (value) => setState(() => _corporate = value),
              ),
              const SizedBox(height: SiteSpacing.x3),
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 720),
                child: _corporate
                    ? _CorporateForm(service: _service)
                    : _IndividualForm(service: _service),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ── Bireysel / Kurumsal seçici ───────────────────────────────────────────────

class _AudienceSwitch extends StatelessWidget {
  const _AudienceSwitch({required this.corporate, required this.onChanged});

  final bool corporate;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(SiteSpacing.xs),
      decoration: BoxDecoration(
        color: SiteColors.surfaceRaised,
        borderRadius: SiteRadius.buttonRadius,
        border: Border.all(color: SiteColors.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _SwitchTab(
            label: 'Bireysel',
            selected: !corporate,
            onTap: () => onChanged(false),
          ),
          _SwitchTab(
            label: 'Kurumsal',
            selected: corporate,
            onTap: () => onChanged(true),
          ),
        ],
      ),
    );
  }
}

class _SwitchTab extends StatelessWidget {
  const _SwitchTab({
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
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: SiteMotion.duration(context, SiteMotion.fast),
          padding: const EdgeInsets.symmetric(
            horizontal: SiteSpacing.x2,
            vertical: SiteSpacing.md,
          ),
          decoration: BoxDecoration(
            color: selected ? SiteColors.primary : Colors.transparent,
            borderRadius: const BorderRadius.all(
              Radius.circular(SiteRadius.sm),
            ),
          ),
          child: Text(
            label,
            style: SiteType.action(context, strong: true).copyWith(
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

// ── Ortak form parçaları ─────────────────────────────────────────────────────

class _FieldLabel extends StatelessWidget {
  const _FieldLabel(this.text, {this.optional = false});

  final String text;
  final bool optional;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: SiteSpacing.sm),
      child: Text(
        optional ? '$text (opsiyonel)' : text,
        style: SiteType.action(context, strong: true),
      ),
    );
  }
}

InputDecoration _fieldDecoration(String hint) {
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
    errorBorder: const OutlineInputBorder(
      borderRadius: SiteRadius.buttonRadius,
      borderSide: BorderSide(color: Color(0xFFB4322A)),
    ),
    focusedErrorBorder: const OutlineInputBorder(
      borderRadius: SiteRadius.buttonRadius,
      borderSide: BorderSide(color: Color(0xFFB4322A), width: 1.6),
    ),
  );
}

class _Field extends StatelessWidget {
  const _Field({
    required this.label,
    required this.child,
    this.optional = false,
  });

  final String label;
  final Widget child;
  final bool optional;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: SiteSpacing.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _FieldLabel(label, optional: optional),
          child,
        ],
      ),
    );
  }
}

/// Site stiline uygun, Material'a bağlı olmayan tek seçimli seçenek satırı.
class _ChoiceRow extends StatelessWidget {
  const _ChoiceRow({
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
      inMutuallyExclusiveGroup: true,
      selected: selected,
      button: true,
      label: label,
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: GestureDetector(
          onTap: onTap,
          behavior: HitTestBehavior.opaque,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: SiteSpacing.sm),
            child: Row(
              children: [
                AnimatedContainer(
                  duration: SiteMotion.duration(context, SiteMotion.fast),
                  width: 20,
                  height: 20,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: selected ? SiteColors.primary : SiteColors.border,
                      width: 2,
                    ),
                  ),
                  child: selected
                      ? Center(
                          child: Container(
                            width: 10,
                            height: 10,
                            decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                              color: SiteColors.primary,
                            ),
                          ),
                        )
                      : null,
                ),
                const SizedBox(width: SiteSpacing.md),
                Expanded(child: Text(label, style: SiteType.body(context))),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

String? _requiredValidator(String? value) {
  if (value == null || value.trim().isEmpty) return 'Bu alan zorunludur.';
  return null;
}

String? _emailValidator(String? value) {
  final required = _requiredValidator(value);
  if (required != null) return required;
  final ok = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(value!.trim());
  return ok ? null : 'Geçerli bir e-posta girin.';
}

String? _phoneValidator(String? value) {
  final required = _requiredValidator(value);
  if (required != null) return required;
  final digits = value!.replaceAll(RegExp(r'\D'), '');
  return digits.length >= 10 ? null : 'Geçerli bir telefon numarası girin.';
}

class _PrivacyNoticeAcknowledgement extends StatelessWidget {
  const _PrivacyNoticeAcknowledgement({
    required this.value,
    required this.onChanged,
    this.error,
  });

  final bool value;
  final ValueChanged<bool> onChanged;
  final String? error;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Checkbox(
              value: value,
              onChanged: (v) => onChanged(v ?? false),
              activeColor: SiteColors.primary,
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            const SizedBox(width: SiteSpacing.sm),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(top: 10),
                child: Wrap(
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Text(
                      'Randevu ve tarama sürecinde kişisel verilerimin nasıl '
                      'işlendiğini açıklayan ',
                      style: SiteType.small(context),
                    ),
                    SiteTextLink(
                      label: 'KVKK Aydınlatma Metni',
                      style: SiteType.small(context),
                      onPressed: () => SiteNav.go(context, SiteRoutes.kvkk),
                    ),
                    Text(
                      '’ni okudum.',
                      style: SiteType.small(context),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        if (error != null)
          Padding(
            padding: const EdgeInsets.only(left: 12, top: 4),
            child: Text(
              error!,
              style: SiteType.small(
                context,
              ).copyWith(color: const Color(0xFFB4322A)),
            ),
          ),
      ],
    );
  }
}

class _SubmitResult extends StatelessWidget {
  const _SubmitResult({
    required this.title,
    required this.message,
    required this.onReset,
    this.warning,
  });

  final String title;
  final String message;
  final VoidCallback onReset;
  final String? warning;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(SiteSpacing.x2),
      decoration: BoxDecoration(
        color: SiteColors.primarySoft,
        borderRadius: SiteRadius.cardRadius,
        border: Border.all(color: SiteColors.primarySoftBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.check_circle_outline, color: SiteColors.primary),
              const SizedBox(width: SiteSpacing.sm),
              Expanded(child: Text(title, style: SiteType.h3(context))),
            ],
          ),
          const SizedBox(height: SiteSpacing.md),
          Text(message, style: SiteType.body(context)),
          if (warning != null) ...[
            const SizedBox(height: SiteSpacing.md),
            Text(
              warning!,
              style: SiteType.small(
                context,
              ).copyWith(fontStyle: FontStyle.italic),
            ),
          ],
          const SizedBox(height: SiteSpacing.xl),
          SecondaryButton(label: 'Yeni talep', onPressed: onReset),
        ],
      ),
    );
  }
}

class _ErrorBanner extends StatelessWidget {
  const _ErrorBanner(this.message);

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: SiteSpacing.lg),
      padding: const EdgeInsets.all(SiteSpacing.lg),
      decoration: BoxDecoration(
        color: const Color(0x14B4322A),
        borderRadius: SiteRadius.buttonRadius,
        border: Border.all(color: const Color(0x33B4322A)),
      ),
      child: Text(
        message,
        style: SiteType.small(context).copyWith(color: const Color(0xFFB4322A)),
      ),
    );
  }
}

// ── Bireysel form ────────────────────────────────────────────────────────────

class _IndividualForm extends StatefulWidget {
  const _IndividualForm({required this.service});

  final ScanAppointmentService service;

  @override
  State<_IndividualForm> createState() => _IndividualFormState();
}

class _IndividualFormState extends State<_IndividualForm> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _phone = TextEditingController();
  final _email = TextEditingController();

  final List<String> _slots = buildDailyScanSlots();

  ScanLocation? _location;
  DateTime? _date;
  String? _time;
  bool _consent = false;
  bool _consentError = false;

  bool _submitting = false;
  bool _done = false;
  bool _emailWarning = false;
  String? _error;
  String? _requestId;

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    _email.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final first = DateTime(now.year, now.month, now.day);
    final picked = await showDatePicker(
      context: context,
      initialDate: _date ?? first.add(const Duration(days: 1)),
      firstDate: first,
      lastDate: first.add(const Duration(days: 120)),
      helpText: 'Randevu tarihi seçin',
    );
    if (picked != null) setState(() => _date = picked);
  }

  String get _isoDate {
    final d = _date!;
    return '${d.year.toString().padLeft(4, '0')}-'
        '${d.month.toString().padLeft(2, '0')}-'
        '${d.day.toString().padLeft(2, '0')}';
  }

  Future<void> _submit() async {
    final formOk = _formKey.currentState?.validate() ?? false;
    final consentOk = _consent;
    setState(() => _consentError = !consentOk);
    if (!formOk ||
        !consentOk ||
        _location == null ||
        _date == null ||
        _time == null) {
      if (_location == null || _date == null || _time == null) {
        setState(() => _error = 'Lokasyon, tarih ve saati seçin.');
      }
      return;
    }

    setState(() {
      _submitting = true;
      _error = null;
    });

    try {
      final result = await widget.service.submitIndividual(
        IndividualScanRequest(
          requestId: _requestId ??= buildScanRequestId(),
          fullName: _name.text,
          phone: _phone.text,
          email: _email.text,
          location: _location!,
          date: _isoDate,
          time: _time!,
          privacyNoticeAcknowledged: true,
        ),
      );
      if (!mounted) return;
      setState(() {
        _done = true;
        _emailWarning = !result.emailDispatched;
      });
    } on ScanAppointmentSubmissionException catch (error) {
      if (!mounted) return;
      setState(
        () => _error = error.message,
      );
    } catch (_) {
      if (!mounted) return;
      setState(
        () => _error = 'Beklenmeyen bir hata oluştu. Lütfen tekrar deneyin.',
      );
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  void _reset() {
    _formKey.currentState?.reset();
    _name.clear();
    _phone.clear();
    _email.clear();
    setState(() {
      _location = null;
      _date = null;
      _time = null;
      _consent = false;
      _consentError = false;
      _done = false;
      _emailWarning = false;
      _error = null;
      _requestId = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_done) {
      return _SubmitResult(
        title: 'Randevu talebiniz alındı',
        message:
            'Talebiniz ekibimize iletildi. Seçtiğiniz lokasyon ve saat için '
            'onay amacıyla sizinle iletişime geçeceğiz. Bilgilendirme ve KVKK '
            'aydınlatma özeti e-posta adresinize gönderildi.',
        warning: _emailWarning
            ? 'Not: Bilgilendirme e-postası şu an gönderilemedi, ancak '
                  'talebiniz kaydedildi.'
            : null,
        onReset: _reset,
      );
    }

    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (_error != null) _ErrorBanner(_error!),
          _Field(
            label: 'Ad Soyad',
            child: TextFormField(
              controller: _name,
              textCapitalization: TextCapitalization.words,
              decoration: _fieldDecoration('Adınız ve soyadınız'),
              validator: _requiredValidator,
            ),
          ),
          _Field(
            label: 'Telefon',
            child: TextFormField(
              controller: _phone,
              keyboardType: TextInputType.phone,
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[0-9+\s()-]')),
              ],
              decoration: _fieldDecoration('05xx xxx xx xx'),
              validator: _phoneValidator,
            ),
          ),
          _Field(
            label: 'E-posta',
            child: TextFormField(
              controller: _email,
              keyboardType: TextInputType.emailAddress,
              decoration: _fieldDecoration('ornek@eposta.com'),
              validator: _emailValidator,
            ),
          ),
          _Field(
            label: 'Lokasyon',
            child: DropdownButtonFormField<ScanLocation>(
              initialValue: _location,
              isExpanded: true,
              decoration: _fieldDecoration('Tarama noktası seçin'),
              items: [
                for (final loc in ScanLocation.values)
                  DropdownMenuItem(value: loc, child: Text(loc.label)),
              ],
              onChanged: (value) => setState(() => _location = value),
              validator: (value) => value == null ? 'Lokasyon seçin.' : null,
            ),
          ),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: _Field(
                  label: 'Tarih',
                  child: InkWell(
                    onTap: _pickDate,
                    borderRadius: SiteRadius.buttonRadius,
                    child: InputDecorator(
                      decoration: _fieldDecoration('Tarih seçin'),
                      child: Text(
                        _date == null ? 'Tarih seçin' : _isoDate,
                        style: SiteType.body(context).copyWith(
                          color: _date == null
                              ? SiteColors.textSecondary
                              : SiteColors.textPrimary,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: SiteSpacing.lg),
              Expanded(
                child: _Field(
                  label: 'Saat',
                  child: DropdownButtonFormField<String>(
                    initialValue: _time,
                    isExpanded: true,
                    decoration: _fieldDecoration('Saat seçin'),
                    items: [
                      for (final slot in _slots)
                        DropdownMenuItem(value: slot, child: Text(slot)),
                    ],
                    onChanged: (value) => setState(() => _time = value),
                    validator: (value) => value == null ? 'Saat seçin.' : null,
                  ),
                ),
              ),
            ],
          ),
          Text(
            'Tüm tarama noktalarında (LiveLifeTaller — Kartal, İZTÜ DML — '
            'Buca ve Alsancak — İzmir) randevular her gün 11:00–17:00 arası '
            '15 dakikalık aralıklarla verilir.',
            style: SiteType.small(context),
          ),
          const SizedBox(height: SiteSpacing.xl),
          _PrivacyNoticeAcknowledgement(
            value: _consent,
            onChanged: (v) => setState(() {
              _consent = v;
              if (v) _consentError = false;
            }),
            error: _consentError
                ? 'Devam etmek için metni okuduğunuzu işaretleyin.'
                : null,
          ),
          const SizedBox(height: SiteSpacing.x2),
          PrimaryButton(
            label: _submitting ? 'Gönderiliyor…' : 'Randevu Oluştur',
            icon: Icons.event_available_outlined,
            size: SiteButtonSize.large,
            onPressed: _submitting ? null : _submit,
          ),
        ],
      ),
    );
  }
}

// ── Kurumsal form ────────────────────────────────────────────────────────────

class _CorporateForm extends StatefulWidget {
  const _CorporateForm({required this.service});

  final ScanAppointmentService service;

  @override
  State<_CorporateForm> createState() => _CorporateFormState();
}

class _CorporateFormState extends State<_CorporateForm> {
  final _formKey = GlobalKey<FormState>();
  final _company = TextEditingController();
  final _contact = TextEditingController();
  final _email = TextEditingController();
  final _phone = TextEditingController();
  final _count = TextEditingController();
  final _note = TextEditingController();

  CorporateRequestType _type = CorporateRequestType.b2bService;
  bool _consent = false;
  bool _consentError = false;

  bool _submitting = false;
  bool _done = false;
  bool _emailWarning = false;
  String? _error;
  String? _requestId;

  @override
  void dispose() {
    _company.dispose();
    _contact.dispose();
    _email.dispose();
    _phone.dispose();
    _count.dispose();
    _note.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final formOk = _formKey.currentState?.validate() ?? false;
    final consentOk = _consent;
    setState(() => _consentError = !consentOk);
    if (!formOk || !consentOk) return;

    setState(() {
      _submitting = true;
      _error = null;
    });

    try {
      final result = await widget.service.submitCorporate(
        CorporateScanRequest(
          requestId: _requestId ??= buildScanRequestId(),
          companyName: _company.text,
          contactName: _contact.text,
          email: _email.text,
          phone: _phone.text,
          personCount: int.parse(_count.text.trim()),
          requestType: _type,
          privacyNoticeAcknowledged: true,
          note: _note.text,
        ),
      );
      if (!mounted) return;
      setState(() {
        _done = true;
        _emailWarning = !result.emailDispatched;
      });
    } on ScanAppointmentSubmissionException catch (error) {
      if (!mounted) return;
      setState(
        () => _error = error.message,
      );
    } catch (_) {
      if (!mounted) return;
      setState(
        () => _error = 'Beklenmeyen bir hata oluştu. Lütfen tekrar deneyin.',
      );
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  void _reset() {
    _formKey.currentState?.reset();
    _company.clear();
    _contact.clear();
    _email.clear();
    _phone.clear();
    _count.clear();
    _note.clear();
    setState(() {
      _type = CorporateRequestType.b2bService;
      _consent = false;
      _consentError = false;
      _done = false;
      _emailWarning = false;
      _error = null;
      _requestId = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_done) {
      return _SubmitResult(
        title: 'Kurumsal talebiniz alındı',
        message:
            'Talebiniz ekibimize iletildi. En kısa sürede sizinle iletişime '
            'geçeceğiz. Bilgilendirme ve KVKK aydınlatma özeti e-posta '
            'adresinize gönderildi.',
        warning: _emailWarning
            ? 'Not: Bilgilendirme e-postası şu an gönderilemedi, ancak '
                  'talebiniz kaydedildi.'
            : null,
        onReset: _reset,
      );
    }

    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (_error != null) _ErrorBanner(_error!),
          _Field(
            label: 'Şirket ismi',
            child: TextFormField(
              controller: _company,
              textCapitalization: TextCapitalization.words,
              decoration: _fieldDecoration('Şirketinizin adı'),
              validator: _requiredValidator,
            ),
          ),
          _Field(
            label: 'Yetkili kişi',
            child: TextFormField(
              controller: _contact,
              textCapitalization: TextCapitalization.words,
              decoration: _fieldDecoration('Ad ve soyad'),
              validator: _requiredValidator,
            ),
          ),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: _Field(
                  label: 'E-posta',
                  child: TextFormField(
                    controller: _email,
                    keyboardType: TextInputType.emailAddress,
                    decoration: _fieldDecoration('ornek@sirket.com'),
                    validator: _emailValidator,
                  ),
                ),
              ),
              const SizedBox(width: SiteSpacing.lg),
              Expanded(
                child: _Field(
                  label: 'Telefon',
                  child: TextFormField(
                    controller: _phone,
                    keyboardType: TextInputType.phone,
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'[0-9+\s()-]')),
                    ],
                    decoration: _fieldDecoration('05xx xxx xx xx'),
                    validator: _phoneValidator,
                  ),
                ),
              ),
            ],
          ),
          _Field(
            label: 'Kaç kişi tarama yapılacak',
            child: TextFormField(
              controller: _count,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              decoration: _fieldDecoration('Örn. 40'),
              validator: (value) {
                final required = _requiredValidator(value);
                if (required != null) return required;
                final n = int.tryParse(value!.trim());
                return (n != null && n > 0) ? null : 'Geçerli bir sayı girin.';
              },
            ),
          ),
          _Field(
            label: 'Talep türü',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (final type in CorporateRequestType.values)
                  _ChoiceRow(
                    label: type.label,
                    selected: _type == type,
                    onTap: () => setState(() => _type = type),
                  ),
              ],
            ),
          ),
          _Field(
            label: 'Not',
            optional: true,
            child: TextFormField(
              controller: _note,
              maxLines: 3,
              decoration: _fieldDecoration(
                'Eklemek istedikleriniz (adres, takvim, vb.)',
              ),
            ),
          ),
          _PrivacyNoticeAcknowledgement(
            value: _consent,
            onChanged: (v) => setState(() {
              _consent = v;
              if (v) _consentError = false;
            }),
            error: _consentError
                ? 'Devam etmek için metni okuduğunuzu işaretleyin.'
                : null,
          ),
          const SizedBox(height: SiteSpacing.x2),
          PrimaryButton(
            label: _submitting ? 'Gönderiliyor…' : 'Talep Gönder',
            icon: Icons.send_outlined,
            size: SiteButtonSize.large,
            onPressed: _submitting ? null : _submit,
          ),
        ],
      ),
    );
  }
}
