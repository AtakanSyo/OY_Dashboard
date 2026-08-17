import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:oy_site/dml/app/dml_theme.dart';

class DmlRequestWizardScreen extends StatefulWidget {
  const DmlRequestWizardScreen({super.key});

  @override
  State<DmlRequestWizardScreen> createState() => _DmlRequestWizardScreenState();
}

class _DmlRequestWizardScreenState extends State<DmlRequestWizardScreen> {
  static const _stepTitles = [
    'Kullanım amacı',
    'Anatomik bölge',
    'Veri türü',
    'Dosyalar',
    'Model beklentisi',
    'Teslim bilgileri',
    'Özet ve gönderim',
  ];

  static const _purposes = [
    ('Cerrahi planlama', Icons.medical_services_outlined),
    ('Anatomi eğitimi', Icons.school_outlined),
    ('Akademik araştırma', Icons.science_outlined),
    ('Hasta bilgilendirme', Icons.record_voice_over_outlined),
    ('Prototipleme', Icons.view_in_ar_outlined),
    ('Diğer', Icons.more_horiz),
  ];

  static const _regions = [
    'Kafa ve çene',
    'Omurga',
    'Üst ekstremite',
    'Göğüs kafesi',
    'Pelvis',
    'Diz',
    'Ayak ve ayak bileği',
    'Organ',
    'Diğer',
  ];

  static const _dataTypes = [
    ('DICOM / CT görüntüleri', 'Bir görüntüleme merkezinden alınan seri'),
    ('MR görüntüleri', 'Manyetik rezonans görüntüleri'),
    ('STL / OBJ / 3MF modeli', 'Hazır bir üç boyutlu model'),
    ('Fotoğraf veya ölçüm', 'Görsel, çizim ya da ölçü verileri'),
    ('Henüz veri yok', 'Önce DML ekibiyle görüşmek istiyorum'),
    ('Hangisi olduğunu bilmiyorum', 'Dosyalarımı ekip değerlendirsin'),
  ];

  static const _expectations = [
    'Gerçek boyut',
    'Küçültülmüş model',
    'Büyütülmüş model',
    'Tek renk',
    'Farklı yapılar farklı renklerde',
    'Şeffaf dış yapı',
    'Parçalara ayrılabilir',
    'Esnek malzeme',
    'DML ekibi önersin',
  ];

  final _notesController = TextEditingController();
  final _contactController = TextEditingController();
  int _currentStep = 0;
  String? _purpose;
  String? _region;
  String? _dataType;
  final List<PlatformFile> _files = [];
  bool _shareFilesLater = false;
  final Set<String> _selectedExpectations = {};
  int _quantity = 1;
  DateTime? _targetDate;
  bool _isUrgent = false;
  bool _confirmed = false;
  bool _isSubmitting = false;
  String? _submittedRequestCode;

  @override
  void dispose() {
    _notesController.dispose();
    _contactController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_submittedRequestCode != null) return _buildSuccessState();

    return LayoutBuilder(
      builder: (context, constraints) {
        final padding = constraints.maxWidth < 700 ? 16.0 : 28.0;
        return SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(padding, 24, padding, 42),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1120),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Özel model talebi',
                    style: TextStyle(
                      color: DmlColors.ink,
                      fontSize: 30,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Teknik ayrıntıları bilmeniz gerekmiyor. İhtiyacınızı adım adım birlikte tanımlayalım.',
                    style: TextStyle(
                      color: DmlColors.slate,
                      fontSize: 15,
                      height: 1.45,
                    ),
                  ),
                  const SizedBox(height: 26),
                  _buildProgress(),
                  const SizedBox(height: 22),
                  Container(
                    width: double.infinity,
                    padding: EdgeInsets.all(
                      constraints.maxWidth < 700 ? 20 : 30,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: DmlColors.mist),
                    ),
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 220),
                      child: KeyedSubtree(
                        key: ValueKey(_currentStep),
                        child: _buildStepContent(),
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),
                  _buildNavigationButtons(),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildProgress() {
    return Column(
      children: [
        Row(
          children: List.generate(_stepTitles.length, (index) {
            final completed = index < _currentStep;
            final active = index == _currentStep;
            return Expanded(
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      children: [
                        Container(
                          width: 32,
                          height: 32,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: completed || active
                                ? DmlColors.ink
                                : DmlColors.mist,
                            shape: BoxShape.circle,
                          ),
                          child: completed
                              ? const Icon(
                                  Icons.check,
                                  size: 17,
                                  color: Colors.white,
                                )
                              : Text(
                                  '${index + 1}',
                                  style: TextStyle(
                                    color: active
                                        ? Colors.white
                                        : DmlColors.slate,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                        ),
                        const SizedBox(height: 7),
                        if (MediaQuery.sizeOf(context).width >= 850)
                          Text(
                            _stepTitles[index],
                            textAlign: TextAlign.center,
                            maxLines: 2,
                            style: TextStyle(
                              fontSize: 11,
                              color: active ? DmlColors.ink : DmlColors.slate,
                              fontWeight: active
                                  ? FontWeight.w700
                                  : FontWeight.w500,
                            ),
                          ),
                      ],
                    ),
                  ),
                  if (index < _stepTitles.length - 1)
                    Container(
                      width: 12,
                      height: 2,
                      margin: const EdgeInsets.only(bottom: 22),
                      color: index < _currentStep
                          ? DmlColors.ink
                          : DmlColors.mist,
                    ),
                ],
              ),
            );
          }),
        ),
        if (MediaQuery.sizeOf(context).width < 850) ...[
          const SizedBox(height: 10),
          Text(
            '${_currentStep + 1}. ${_stepTitles[_currentStep]}',
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
        ],
      ],
    );
  }

  Widget _buildStepContent() {
    switch (_currentStep) {
      case 0:
        return _buildPurposeStep();
      case 1:
        return _buildRegionStep();
      case 2:
        return _buildDataTypeStep();
      case 3:
        return _buildFilesStep();
      case 4:
        return _buildExpectationsStep();
      case 5:
        return _buildDeliveryStep();
      case 6:
        return _buildSummaryStep();
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _stepHeading(String title, String description) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(fontSize: 23, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 7),
        Text(
          description,
          style: const TextStyle(color: DmlColors.slate, height: 1.45),
        ),
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _buildPurposeStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _stepHeading(
          'Modeli hangi amaçla kullanacaksınız?',
          'Bu bilgi, hazırlanacak modelin ayrıntı düzeyini ve üretim yaklaşımını belirlememize yardımcı olur.',
        ),
        _selectionGrid(
          _purposes.map((item) {
            return _SelectionCard(
              icon: item.$2,
              title: item.$1,
              selected: _purpose == item.$1,
              onTap: () => setState(() => _purpose = item.$1),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildRegionStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _stepHeading(
          'Hangi anatomik bölge üzerinde çalışılacak?',
          'Birden fazla bölge söz konusuysa en yakın seçeneği işaretleyip son adımda açıklayabilirsiniz.',
        ),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: _regions.map((region) {
            return ChoiceChip(
              label: Text(region),
              selected: _region == region,
              onSelected: (_) => setState(() => _region = region),
              selectedColor: DmlColors.ink,
              labelStyle: TextStyle(
                color: _region == region ? Colors.white : DmlColors.ink,
                fontWeight: FontWeight.w600,
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildDataTypeStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _stepHeading(
          'Elinizde hangi tür veri bulunuyor?',
          'Emin değilseniz dosyanızı daha sonra DML ekibinin değerlendirmesi için paylaşabilirsiniz.',
        ),
        _selectionGrid(
          _dataTypes.map((item) {
            return _SelectionCard(
              icon: Icons.insert_drive_file_outlined,
              title: item.$1,
              description: item.$2,
              selected: _dataType == item.$1,
              onTap: () => setState(() => _dataType = item.$1),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildFilesStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _stepHeading(
          'Dosyalarınızı ekleyin',
          'Bu prototip sürümde dosyalar yalnızca cihazınızdan seçilir; herhangi bir sunucuya yüklenmez.',
        ),
        InkWell(
          onTap: _pickFiles,
          borderRadius: BorderRadius.circular(16),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 34),
            decoration: BoxDecoration(
              color: DmlColors.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: DmlColors.accent, width: 1.5),
            ),
            child: const Column(
              children: [
                Icon(
                  Icons.cloud_upload_outlined,
                  size: 44,
                  color: DmlColors.ink,
                ),
                SizedBox(height: 12),
                Text(
                  'Dosya seçmek için tıklayın',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
                SizedBox(height: 6),
                Text(
                  'DICOM, ZIP, NII, STL, OBJ, 3MF veya görsel dosyaları',
                  style: TextStyle(color: DmlColors.slate),
                ),
              ],
            ),
          ),
        ),
        if (_files.isNotEmpty) ...[
          const SizedBox(height: 18),
          ..._files.asMap().entries.map(
            (entry) => Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border.all(color: DmlColors.mist),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.description_outlined,
                    color: DmlColors.slate,
                  ),
                  const SizedBox(width: 10),
                  Expanded(child: Text(entry.value.name)),
                  Text(
                    _formatFileSize(entry.value.size),
                    style: const TextStyle(
                      fontSize: 12,
                      color: DmlColors.slate,
                    ),
                  ),
                  IconButton(
                    onPressed: () => setState(() => _files.removeAt(entry.key)),
                    tooltip: 'Dosyayı kaldır',
                    icon: const Icon(Icons.close, size: 18),
                  ),
                ],
              ),
            ),
          ),
        ],
        const SizedBox(height: 12),
        CheckboxListTile(
          value: _shareFilesLater,
          onChanged: (value) =>
              setState(() => _shareFilesLater = value ?? false),
          contentPadding: EdgeInsets.zero,
          controlAffinity: ListTileControlAffinity.leading,
          title: const Text('Dosyaları daha sonra paylaşacağım'),
          subtitle: const Text('Talep taslağı dosya olmadan devam eder.'),
        ),
        const _InfoBox(
          icon: Icons.shield_outlined,
          text:
              'Gerçek kullanımda medikal dosyalar için güvenli yükleme, erişim yetkisi ve anonimleştirme kontrolleri ayrıca uygulanacaktır.',
        ),
      ],
    );
  }

  Widget _buildExpectationsStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _stepHeading(
          'Modelle ilgili beklentilerinizi seçin',
          'Birden fazla seçenek işaretleyebilirsiniz. Kararsızsanız DML ekibinin önermesini seçin.',
        ),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: _expectations.map((expectation) {
            final selected = _selectedExpectations.contains(expectation);
            return FilterChip(
              label: Text(expectation),
              selected: selected,
              onSelected: (value) => setState(() {
                if (value) {
                  _selectedExpectations.add(expectation);
                } else {
                  _selectedExpectations.remove(expectation);
                }
              }),
              selectedColor: DmlColors.ink,
              checkmarkColor: Colors.white,
              labelStyle: TextStyle(
                color: selected ? Colors.white : DmlColors.ink,
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 26),
        const Text(
          'İstenen adet',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 10),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton.outlined(
              onPressed: _quantity > 1
                  ? () => setState(() => _quantity--)
                  : null,
              icon: const Icon(Icons.remove),
            ),
            SizedBox(
              width: 62,
              child: Text(
                '$_quantity',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            IconButton.outlined(
              onPressed: () => setState(() => _quantity++),
              icon: const Icon(Icons.add),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildDeliveryStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _stepHeading(
          'Teslim ve iletişim bilgilerini ekleyin',
          'Tarih yalnızca planlama için alınır; teknik inceleme tamamlanmadan teslim sözü verilmez.',
        ),
        LayoutBuilder(
          builder: (context, constraints) {
            final compact = constraints.maxWidth < 700;
            final dateField = InkWell(
              onTap: _pickTargetDate,
              borderRadius: BorderRadius.circular(12),
              child: InputDecorator(
                decoration: const InputDecoration(
                  labelText: 'Hedef teslim tarihi',
                  suffixIcon: Icon(Icons.calendar_today_outlined),
                ),
                child: Text(
                  _targetDate == null
                      ? 'Tarih seçilmedi'
                      : _formatDate(_targetDate!),
                ),
              ),
            );
            final contactField = TextField(
              controller: _contactController,
              decoration: const InputDecoration(
                labelText: 'İletişim e-postası',
                prefixIcon: Icon(Icons.email_outlined),
              ),
              keyboardType: TextInputType.emailAddress,
            );
            return compact
                ? Column(
                    children: [
                      dateField,
                      const SizedBox(height: 14),
                      contactField,
                    ],
                  )
                : Row(
                    children: [
                      Expanded(child: dateField),
                      const SizedBox(width: 14),
                      Expanded(child: contactField),
                    ],
                  );
          },
        ),
        const SizedBox(height: 14),
        TextField(
          controller: _notesController,
          maxLines: 5,
          decoration: const InputDecoration(
            labelText: 'Ek açıklamalar',
            hintText:
                'Modelde özellikle gösterilmesini istediğiniz yapılar, kullanım koşulları veya proje bilgileri...',
            alignLabelWithHint: true,
          ),
        ),
        const SizedBox(height: 8),
        CheckboxListTile(
          value: _isUrgent,
          onChanged: (value) => setState(() => _isUrgent = value ?? false),
          contentPadding: EdgeInsets.zero,
          controlAffinity: ListTileControlAffinity.leading,
          title: const Text(
            'Planlanan ameliyat, eğitim veya etkinlik tarihi bulunuyor',
          ),
          subtitle: const Text(
            'DML ekibi zaman uygunluğunu teknik inceleme sonrasında bildirecektir.',
          ),
        ),
      ],
    );
  }

  Widget _buildSummaryStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _stepHeading(
          'Talebinizi kontrol edin',
          'Göndermeden önce verdiğiniz bilgilerin kısa özetini inceleyin.',
        ),
        _summarySection('Talep bilgileri', [
          ('Kullanım amacı', _purpose ?? '—'),
          ('Anatomik bölge', _region ?? '—'),
          ('Veri türü', _dataType ?? '—'),
          (
            'Dosya',
            _files.isEmpty
                ? (_shareFilesLater ? 'Daha sonra paylaşılacak' : 'Eklenmedi')
                : '${_files.length} dosya seçildi',
          ),
        ]),
        const SizedBox(height: 14),
        _summarySection('Üretim beklentisi', [
          (
            'Tercihler',
            _selectedExpectations.isEmpty
                ? 'DML ekibi değerlendirsin'
                : _selectedExpectations.join(', '),
          ),
          ('Adet', '$_quantity'),
          (
            'Hedef tarih',
            _targetDate == null ? 'Belirtilmedi' : _formatDate(_targetDate!),
          ),
          ('Öncelikli tarih', _isUrgent ? 'Var' : 'Yok'),
        ]),
        const SizedBox(height: 14),
        const _InfoBox(
          icon: Icons.info_outline,
          text:
              'Bu bir üretim onayı veya kesin fiyat değildir. DML ekibi dosyaları ve gereksinimleri inceleyerek sizinle iletişime geçecektir.',
        ),
        const SizedBox(height: 10),
        CheckboxListTile(
          value: _confirmed,
          onChanged: (value) => setState(() => _confirmed = value ?? false),
          contentPadding: EdgeInsets.zero,
          controlAffinity: ListTileControlAffinity.leading,
          title: const Text(
            'Bilgilerin doğru olduğunu ve talebin teknik ön incelemeye gönderileceğini onaylıyorum.',
          ),
        ),
      ],
    );
  }

  Widget _summarySection(String title, List<(String, String)> rows) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: DmlColors.surface,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 12),
          ...rows.map(
            (row) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 5),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: 150,
                    child: Text(
                      row.$1,
                      style: const TextStyle(color: DmlColors.slate),
                    ),
                  ),
                  Expanded(
                    child: Text(
                      row.$2,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _selectionGrid(List<Widget> children) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth >= 760
            ? 3
            : constraints.maxWidth >= 480
            ? 2
            : 1;
        final width = (constraints.maxWidth - ((columns - 1) * 12)) / columns;
        return Wrap(
          spacing: 12,
          runSpacing: 12,
          children: children
              .map((child) => SizedBox(width: width, child: child))
              .toList(),
        );
      },
    );
  }

  Widget _buildNavigationButtons() {
    final lastStep = _currentStep == _stepTitles.length - 1;
    return Row(
      children: [
        if (_currentStep > 0)
          OutlinedButton.icon(
            onPressed: _isSubmitting
                ? null
                : () => setState(() => _currentStep--),
            icon: const Icon(Icons.arrow_back),
            label: const Text('Geri'),
          ),
        const Spacer(),
        ElevatedButton.icon(
          onPressed: _isSubmitting ? null : (lastStep ? _submit : _next),
          icon: _isSubmitting
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : Icon(lastStep ? Icons.send_outlined : Icons.arrow_forward),
          label: Text(lastStep ? 'Talebi gönder' : 'Devam et'),
        ),
      ],
    );
  }

  void _next() {
    final validationMessage = _validationMessage();
    if (validationMessage != null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(validationMessage)));
      return;
    }
    setState(() => _currentStep++);
  }

  String? _validationMessage() {
    switch (_currentStep) {
      case 0:
        return _purpose == null ? 'Lütfen kullanım amacını seçin.' : null;
      case 1:
        return _region == null ? 'Lütfen anatomik bölgeyi seçin.' : null;
      case 2:
        return _dataType == null
            ? 'Lütfen elinizdeki veri türünü seçin.'
            : null;
      case 3:
        return _files.isEmpty && !_shareFilesLater
            ? 'Dosya seçin veya daha sonra paylaşacağınızı belirtin.'
            : null;
      case 4:
        return _selectedExpectations.isEmpty
            ? 'En az bir beklenti seçin. Kararsızsanız DML ekibi önersin seçeneğini kullanabilirsiniz.'
            : null;
      case 5:
        final email = _contactController.text.trim();
        if (email.isEmpty || !email.contains('@')) {
          return 'Geçerli bir iletişim e-postası girin.';
        }
        return null;
      default:
        return null;
    }
  }

  Future<void> _pickFiles() async {
    final result = await FilePicker.pickFiles(
      allowMultiple: true,
      type: FileType.custom,
      allowedExtensions: const [
        'dcm',
        'zip',
        'nii',
        'stl',
        'obj',
        '3mf',
        'png',
        'jpg',
        'jpeg',
        'pdf',
      ],
    );
    if (result == null || !mounted) return;
    setState(() {
      _files.addAll(result.files);
      _shareFilesLater = false;
    });
  }

  Future<void> _pickTargetDate() async {
    final now = DateTime.now();
    final selected = await showDatePicker(
      context: context,
      initialDate: _targetDate ?? now.add(const Duration(days: 14)),
      firstDate: now,
      lastDate: now.add(const Duration(days: 730)),
    );
    if (selected != null && mounted) setState(() => _targetDate = selected);
  }

  Future<void> _submit() async {
    if (!_confirmed) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Göndermeden önce onay kutusunu işaretleyin.'),
        ),
      );
      return;
    }
    setState(() => _isSubmitting = true);
    await Future<void>.delayed(const Duration(milliseconds: 700));
    if (!mounted) return;
    final now = DateTime.now();
    setState(() {
      _isSubmitting = false;
      _submittedRequestCode =
          'DML-${now.year}-${now.millisecondsSinceEpoch.toString().substring(7)}';
    });
  }

  Widget _buildSuccessState() {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(28),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 620),
          child: Container(
            padding: const EdgeInsets.all(34),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: DmlColors.mist),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 76,
                  height: 76,
                  decoration: const BoxDecoration(
                    color: DmlColors.ink,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.check, size: 38, color: Colors.white),
                ),
                const SizedBox(height: 22),
                const Text(
                  'Talep taslağınız oluşturuldu',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 25, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 10),
                Text(
                  'Talep kodu: $_submittedRequestCode',
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Bu prototip sürümünde bilgiler sunucuya kaydedilmedi. Gerçek veri bağlantısı kurulduğunda talebiniz DML ekibinin inceleme havuzuna gönderilecek.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: DmlColors.slate, height: 1.5),
                ),
                const SizedBox(height: 24),
                OutlinedButton.icon(
                  onPressed: _reset,
                  icon: const Icon(Icons.add),
                  label: const Text('Yeni talep oluştur'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _reset() {
    setState(() {
      _currentStep = 0;
      _purpose = null;
      _region = null;
      _dataType = null;
      _files.clear();
      _shareFilesLater = false;
      _selectedExpectations.clear();
      _quantity = 1;
      _targetDate = null;
      _isUrgent = false;
      _confirmed = false;
      _submittedRequestCode = null;
      _notesController.clear();
      _contactController.clear();
    });
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}.${date.month.toString().padLeft(2, '0')}.${date.year}';
  }

  String _formatFileSize(int bytes) {
    if (bytes >= 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
    if (bytes >= 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '$bytes B';
  }
}

class _SelectionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? description;
  final bool selected;
  final VoidCallback onTap;

  const _SelectionCard({
    required this.icon,
    required this.title,
    this.description,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? const Color(0xFFE6ECEC) : Colors.white,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          constraints: const BoxConstraints(minHeight: 130),
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: selected ? DmlColors.ink : DmlColors.mist,
              width: selected ? 1.5 : 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(icon, color: DmlColors.ink),
                  const Spacer(),
                  if (selected)
                    const Icon(
                      Icons.check_circle,
                      color: DmlColors.ink,
                      size: 20,
                    ),
                ],
              ),
              const SizedBox(height: 15),
              Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
              if (description != null) ...[
                const SizedBox(height: 6),
                Text(
                  description!,
                  style: const TextStyle(
                    color: DmlColors.slate,
                    fontSize: 12,
                    height: 1.35,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _InfoBox extends StatelessWidget {
  final IconData icon;
  final String text;

  const _InfoBox({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: DmlColors.surface,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: DmlColors.slate, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(color: DmlColors.slate, height: 1.4),
            ),
          ),
        ],
      ),
    );
  }
}
