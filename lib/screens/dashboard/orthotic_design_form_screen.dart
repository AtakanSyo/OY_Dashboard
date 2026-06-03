import 'package:flutter/material.dart';
import 'package:oy_site/models/app_user.dart';
import 'package:oy_site/models/measurement_session.dart';
import 'package:oy_site/models/orthotic_design_form_model.dart';
import 'package:oy_site/data/repositories/supabase_orthotic_design_form_repository.dart';

class OrthoticDesignFormScreen extends StatefulWidget {
  final AppUser currentUser;
  final MeasurementSession session;

  const OrthoticDesignFormScreen({
    super.key,
    required this.currentUser,
    required this.session,
  });

  @override
  State<OrthoticDesignFormScreen> createState() =>
      _OrthoticDesignFormScreenState();
}

class _OrthoticDesignFormScreenState
    extends State<OrthoticDesignFormScreen> {
  final SupabaseOrthoticDesignFormRepository _repository =
      SupabaseOrthoticDesignFormRepository();

  bool _isLoading = true;
  bool _isSaving = false;

  late bool _heelPad;
  late TextEditingController _deepHeelCupController;
  late TextEditingController _heelRaiseController;

  late bool _medialArchSupport;
  late bool _metatarsalPad;
  late bool _transverseArchSupport;

  late TextEditingController _posteriorReliefController;
  late bool _mortonRelief;
  late bool _bunionPad;

  late TextEditingController _expertNotesController;
  String? _aiRecommendationJson;
  late bool _approvedForOrder;

  @override
  void initState() {
    super.initState();
    _deepHeelCupController = TextEditingController();
    _heelRaiseController = TextEditingController();
    _posteriorReliefController = TextEditingController();
    _expertNotesController = TextEditingController();
    _loadForm();
  }

  @override
  void dispose() {
    _deepHeelCupController.dispose();
    _heelRaiseController.dispose();
    _posteriorReliefController.dispose();
    _expertNotesController.dispose();
    super.dispose();
  }

  Future<void> _loadForm() async {
    final form = await _repository.getBySessionId(
      widget.session.sessionId ?? 0,
    );

    if (form == null) {
      setState(() {
        _heelPad = false;
        _medialArchSupport = false;
        _metatarsalPad = false;
        _transverseArchSupport = false;
        _mortonRelief = false;
        _bunionPad = false;
        _approvedForOrder = false;
        _isLoading = false;
      });
      return;
    }

    if (!mounted) return;

    setState(() {
      _heelPad = form.heelPad;
      _deepHeelCupController.text = form.deepHeelCupMm?.toString() ?? '';
      _heelRaiseController.text = form.heelRaiseMm?.toString() ?? '';
      _medialArchSupport = form.medialArchSupport;
      _metatarsalPad = form.metatarsalPad;
      _transverseArchSupport = form.transverseArchSupport;
      _posteriorReliefController.text =
          form.posteriorReliefMm?.toString() ?? '';
      _mortonRelief = form.mortonRelief;
      _bunionPad = form.bunionPad;
      _expertNotesController.text = form.expertNotes ?? '';
      _aiRecommendationJson = form.aiRecommendationJson;
      _approvedForOrder = form.approvedForOrder;
      _isLoading = false;
    });
  }

  double? _parseDouble(String value) {
    final text = value.trim();
    if (text.isEmpty) return null;
    return double.tryParse(text.replaceAll(',', '.'));
  }

  Future<void> _saveForm() async {
    setState(() => _isSaving = true);

    final form = OrthoticDesignFormModel(
      sessionId: widget.session.sessionId ?? 0,
      expertUserId: widget.currentUser.userId ?? 0,
      heelPad: _heelPad,
      deepHeelCupMm: _parseDouble(_deepHeelCupController.text),
      heelRaiseMm: _parseDouble(_heelRaiseController.text),
      medialArchSupport: _medialArchSupport,
      metatarsalPad: _metatarsalPad,
      transverseArchSupport: _transverseArchSupport,
      posteriorReliefMm: _parseDouble(_posteriorReliefController.text),
      mortonRelief: _mortonRelief,
      bunionPad: _bunionPad,
      expertNotes: _expertNotesController.text.trim(),
      aiRecommendationJson: _aiRecommendationJson,
      approvedForOrder: _approvedForOrder,
      updatedAt: DateTime.now(),
    );

    await _repository.upsert(
      model: form,
      patientId: widget.session.patientId,
    );

    if (!mounted) return;

    setState(() => _isSaving = false);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Tasarım formu kaydedildi.'),
      ),
    );

    Navigator.pop(context, true);
  }

  String _formatSessionTitle() {
    return '${widget.session.sessionCode} • ${widget.currentUser.displayName}';
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        appBar: null,
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Ortez Tasarım Formu'),
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
                _buildSupportSection(),
                const SizedBox(height: 16),
                _buildReliefSection(),
                const SizedBox(height: 16),
                _buildNotesSection(),
              ],
            ),
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _isSaving ? null : _saveForm,
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
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Session Bazlı Tasarım',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _formatSessionTitle(),
            style: TextStyle(color: Colors.grey[700]),
          ),
          const SizedBox(height: 8),
          Text(
            'Bu form, orthotic_design_forms tablosundaki alanlara göre hazırlanmıştır.',
            style: TextStyle(color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }

  Widget _buildSupportSection() {
    return _buildSectionCard(
      title: 'Destek ve Yükseltmeler',
      child: Column(
        children: [
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Topuk Pedi (Heel Pad)'),
            value: _heelPad,
            onChanged: (v) => setState(() => _heelPad = v),
          ),
          _buildNumberField(
            controller: _deepHeelCupController,
            label: 'Derin Topuk Kapsülü (Deep Heel Cup) mm',
          ),
          const SizedBox(height: 12),
          _buildNumberField(
            controller: _heelRaiseController,
            label: 'Topuk Yükseltme (Heel Raise) mm',
          ),
          const SizedBox(height: 12),
          CheckboxListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Medial Ark Desteği (Medial Arch Support)'),
            value: _medialArchSupport,
            onChanged: (v) =>
                setState(() => _medialArchSupport = v ?? false),
          ),
          CheckboxListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Metatarsal Ped (Metatarsal Pad)'),
            value: _metatarsalPad,
            onChanged: (v) => setState(() => _metatarsalPad = v ?? false),
          ),
          CheckboxListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text(
              'Transvers Ark Desteği (Transverse Arch Support)',
            ),
            value: _transverseArchSupport,
            onChanged: (v) =>
                setState(() => _transverseArchSupport = v ?? false),
          ),
        ],
      ),
    );
  }

  Widget _buildReliefSection() {
    return _buildSectionCard(
      title: 'Rahatlatma / Bölgesel Düzenlemeler',
      child: Column(
        children: [
          _buildNumberField(
            controller: _posteriorReliefController,
            label: 'Posterior Rahatlatma (Posterior Relief) mm',
          ),
          const SizedBox(height: 12),
          CheckboxListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Morton Rahatlatması (Morton Relief)'),
            value: _mortonRelief,
            onChanged: (v) => setState(() => _mortonRelief = v ?? false),
          ),
          CheckboxListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Bunyon Pedi (Bunion Pad)'),
            value: _bunionPad,
            onChanged: (v) => setState(() => _bunionPad = v ?? false),
          ),
        ],
      ),
    );
  }

  Widget _buildNotesSection() {
    return _buildSectionCard(
      title: 'Uzman Notları',
      child: TextField(
        controller: _expertNotesController,
        maxLines: 8,
        decoration: const InputDecoration(
          hintText: 'Uzman notlarını buraya yazın...',
          border: OutlineInputBorder(),
        ),
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
      decoration: _cardDecoration(),
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

  BoxDecoration _cardDecoration() {
    return BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      boxShadow: const [
        BoxShadow(
          color: Colors.black12,
          blurRadius: 8,
        ),
      ],
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
}