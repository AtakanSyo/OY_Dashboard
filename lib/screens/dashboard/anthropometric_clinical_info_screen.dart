import 'package:flutter/material.dart';
import 'package:oy_site/data/mock/mock_anthropometric_clinical_info_repository.dart';
import 'package:oy_site/models/anthropometric_clinical_info_model.dart';
import 'package:oy_site/models/app_user.dart';
import 'package:oy_site/models/measurement_session.dart';

class AnthropometricClinicalInfoScreen extends StatefulWidget {
  final AppUser currentUser;
  final MeasurementSession session;

  const AnthropometricClinicalInfoScreen({
    super.key,
    required this.currentUser,
    required this.session,
  });

  @override
  State<AnthropometricClinicalInfoScreen> createState() =>
      _AnthropometricClinicalInfoScreenState();
}

class _AnthropometricClinicalInfoScreenState
    extends State<AnthropometricClinicalInfoScreen> {
  final MockAnthropometricClinicalInfoRepository _repository =
      MockAnthropometricClinicalInfoRepository();

  bool _isLoading = true;
  bool _isSaving = false;

  late TextEditingController _heightController;
  late TextEditingController _weightController;
  late TextEditingController _bmiController;
  late TextEditingController _shoeSizeController;
  late TextEditingController _professionController;
  late TextEditingController _dailyStandingHoursController;
  late TextEditingController _jobDescriptionController;
  late TextEditingController _sportDescriptionController;
  late TextEditingController _currentComplaintController;
  late TextEditingController _diagnosisController;
  late TextEditingController _diabetesNoteController;
  late TextEditingController _otherPathologiesController;

  bool _doesSport = false;
  bool _hasDiabetes = false;

  bool _halluxValgus = false;
  bool _heelSpur = false;
  bool _flatFoot = false;
  bool _pesCavus = false;
  bool _mortonNeuroma = false;
  bool _achillesProblem = false;
  bool _metatarsalPain = false;

  @override
  void initState() {
    super.initState();
    _heightController = TextEditingController();
    _weightController = TextEditingController();
    _bmiController = TextEditingController();
    _shoeSizeController = TextEditingController();
    _professionController = TextEditingController();
    _dailyStandingHoursController = TextEditingController();
    _jobDescriptionController = TextEditingController();
    _sportDescriptionController = TextEditingController();
    _currentComplaintController = TextEditingController();
    _diagnosisController = TextEditingController();
    _diabetesNoteController = TextEditingController();
    _otherPathologiesController = TextEditingController();

    _loadData();
  }

  @override
  void dispose() {
    _heightController.dispose();
    _weightController.dispose();
    _bmiController.dispose();
    _shoeSizeController.dispose();
    _professionController.dispose();
    _dailyStandingHoursController.dispose();
    _jobDescriptionController.dispose();
    _sportDescriptionController.dispose();
    _currentComplaintController.dispose();
    _diagnosisController.dispose();
    _diabetesNoteController.dispose();
    _otherPathologiesController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    final model =
        await _repository.getBySessionId(widget.session.sessionId ?? 0);

    if (!mounted) return;

    setState(() {
      _heightController.text = model.heightCm?.toString() ?? '';
      _weightController.text = model.weightKg?.toString() ?? '';
      _bmiController.text = model.bmi?.toString() ?? '';
      _shoeSizeController.text = model.shoeSizeEu?.toString() ?? '';
      _professionController.text = model.profession ?? '';
      _dailyStandingHoursController.text =
          model.dailyStandingHours?.toString() ?? '';
      _jobDescriptionController.text = model.jobDescription ?? '';
      _sportDescriptionController.text = model.sportDescription ?? '';
      _currentComplaintController.text = model.currentComplaint ?? '';
      _diagnosisController.text = model.diagnosisPreDiagnosis ?? '';
      _diabetesNoteController.text = model.diabetesNote ?? '';
      _otherPathologiesController.text = model.otherPathologies ?? '';

      _doesSport = model.doesSport;
      _hasDiabetes = model.hasDiabetes;
      _halluxValgus = model.halluxValgus;
      _heelSpur = model.heelSpur;
      _flatFoot = model.flatFoot;
      _pesCavus = model.pesCavus;
      _mortonNeuroma = model.mortonNeuroma;
      _achillesProblem = model.achillesProblem;
      _metatarsalPain = model.metatarsalPain;

      _isLoading = false;
    });
  }

  double? _parseDouble(String value) {
    final text = value.trim();
    if (text.isEmpty) return null;
    return double.tryParse(text.replaceAll(',', '.'));
  }

  Future<void> _save() async {
    setState(() => _isSaving = true);

    final model = AnthropometricClinicalInfoModel(
      sessionId: widget.session.sessionId ?? 0,
      heightCm: _parseDouble(_heightController.text),
      weightKg: _parseDouble(_weightController.text),
      bmi: _parseDouble(_bmiController.text),
      shoeSizeEu: _parseDouble(_shoeSizeController.text),
      profession: _professionController.text.trim(),
      dailyStandingHours: _parseDouble(_dailyStandingHoursController.text),
      jobDescription: _jobDescriptionController.text.trim(),
      doesSport: _doesSport,
      sportDescription: _sportDescriptionController.text.trim(),
      currentComplaint: _currentComplaintController.text.trim(),
      diagnosisPreDiagnosis: _diagnosisController.text.trim(),
      hasDiabetes: _hasDiabetes,
      diabetesNote: _diabetesNoteController.text.trim(),
      halluxValgus: _halluxValgus,
      heelSpur: _heelSpur,
      flatFoot: _flatFoot,
      pesCavus: _pesCavus,
      mortonNeuroma: _mortonNeuroma,
      achillesProblem: _achillesProblem,
      metatarsalPain: _metatarsalPain,
      otherPathologies: _otherPathologiesController.text.trim(),
      updatedAt: DateTime.now(),
    );

    await _repository.save(model);

    if (!mounted) return;

    setState(() => _isSaving = false);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Antropometrik / klinik bilgiler kaydedildi.'),
      ),
    );
  }

  String _sessionSubtitle() {
    return '${widget.session.sessionCode} • ${widget.currentUser.displayName}';
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Antropometrik / Klinik Bilgiler'),
        backgroundColor: Colors.teal,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1100),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeaderCard(),
                const SizedBox(height: 24),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      flex: 2,
                      child: Column(
                        children: [
                          _buildBasicInfoSection(),
                          const SizedBox(height: 16),
                          _buildWorkAndSportSection(),
                        ],
                      ),
                    ),
                    const SizedBox(width: 24),
                    Expanded(
                      flex: 3,
                      child: Column(
                        children: [
                          _buildComplaintSection(),
                          const SizedBox(height: 16),
                          _buildPathologySection(),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _isSaving ? null : _save,
        backgroundColor: Colors.teal,
        icon: _isSaving
            ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
            : const Icon(Icons.save, color: Colors.white),
        label: const Text(
          'Kaydet',
          style: TextStyle(color: Colors.white),
        ),
      ),
    );
  }

  Widget _buildHeaderCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: const [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 8,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Session Bazlı Klinik Bilgi Formu',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _sessionSubtitle(),
            style: TextStyle(color: Colors.grey[700]),
          ),
          const SizedBox(height: 8),
          Text(
            'Bu ekran anthropometric_clinical_infos tablosuna göre hazırlanmıştır.',
            style: TextStyle(color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }

  Widget _buildBasicInfoSection() {
    return _buildSectionCard(
      title: 'Temel Ölçüler',
      child: Column(
        children: [
          _buildNumberField(
            controller: _heightController,
            label: 'Boy (cm)',
          ),
          const SizedBox(height: 12),
          _buildNumberField(
            controller: _weightController,
            label: 'Kilo (kg)',
          ),
          const SizedBox(height: 12),
          _buildNumberField(
            controller: _bmiController,
            label: 'BMI',
          ),
          const SizedBox(height: 12),
          _buildNumberField(
            controller: _shoeSizeController,
            label: 'Ayakkabı Numarası (EU)',
          ),
        ],
      ),
    );
  }

  Widget _buildWorkAndSportSection() {
    return _buildSectionCard(
      title: 'Meslek ve Aktivite',
      child: Column(
        children: [
          _buildTextField(
            controller: _professionController,
            label: 'Meslek',
          ),
          const SizedBox(height: 12),
          _buildNumberField(
            controller: _dailyStandingHoursController,
            label: 'Günlük Ayakta Kalma Süresi (saat)',
          ),
          const SizedBox(height: 12),
          _buildTextField(
            controller: _jobDescriptionController,
            label: 'İş Tanımı',
            maxLines: 3,
          ),
          const SizedBox(height: 12),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Spor Yapıyor'),
            value: _doesSport,
            onChanged: (v) => setState(() => _doesSport = v),
          ),
          const SizedBox(height: 12),
          _buildTextField(
            controller: _sportDescriptionController,
            label: 'Spor Açıklaması',
            maxLines: 2,
          ),
        ],
      ),
    );
  }

  Widget _buildComplaintSection() {
    return _buildSectionCard(
      title: 'Şikayet ve Klinik Değerlendirme',
      child: Column(
        children: [
          _buildTextField(
            controller: _currentComplaintController,
            label: 'Mevcut Şikayet',
            maxLines: 4,
          ),
          const SizedBox(height: 12),
          _buildTextField(
            controller: _diagnosisController,
            label: 'Tanı / Ön Tanı',
            maxLines: 4,
          ),
          const SizedBox(height: 12),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Diyabet Var'),
            value: _hasDiabetes,
            onChanged: (v) => setState(() => _hasDiabetes = v),
          ),
          const SizedBox(height: 12),
          _buildTextField(
            controller: _diabetesNoteController,
            label: 'Diyabet Notu',
            maxLines: 2,
          ),
        ],
      ),
    );
  }

  Widget _buildPathologySection() {
    return _buildSectionCard(
      title: 'Patolojiler',
      child: Column(
        children: [
          CheckboxListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Hallux Valgus'),
            value: _halluxValgus,
            onChanged: (v) => setState(() => _halluxValgus = v ?? false),
          ),
          CheckboxListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Heel Spur'),
            value: _heelSpur,
            onChanged: (v) => setState(() => _heelSpur = v ?? false),
          ),
          CheckboxListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Flat Foot'),
            value: _flatFoot,
            onChanged: (v) => setState(() => _flatFoot = v ?? false),
          ),
          CheckboxListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Pes Cavus'),
            value: _pesCavus,
            onChanged: (v) => setState(() => _pesCavus = v ?? false),
          ),
          CheckboxListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Morton Neuroma'),
            value: _mortonNeuroma,
            onChanged: (v) => setState(() => _mortonNeuroma = v ?? false),
          ),
          CheckboxListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Achilles Problem'),
            value: _achillesProblem,
            onChanged: (v) => setState(() => _achillesProblem = v ?? false),
          ),
          CheckboxListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Metatarsal Pain'),
            value: _metatarsalPain,
            onChanged: (v) => setState(() => _metatarsalPain = v ?? false),
          ),
          const SizedBox(height: 12),
          _buildTextField(
            controller: _otherPathologiesController,
            label: 'Diğer Patolojiler',
            maxLines: 3,
          ),
        ],
      ),
    );
  }

  Widget _buildSectionCard({
    required String title,
    required Widget child,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: const [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 8,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 19,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }

  Widget _buildNumberField({
    required TextEditingController controller,
    required String label,
  }) {
    return TextField(
      controller: controller,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    int maxLines = 1,
  }) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
      ),
    );
  }
}