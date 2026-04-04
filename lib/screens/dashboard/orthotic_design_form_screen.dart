import 'package:flutter/material.dart';
import 'package:oy_site/data/mock/mock_orthotic_design_form_repository.dart';
import 'package:oy_site/models/app_user.dart';
import 'package:oy_site/models/measurement_session.dart';
import 'package:oy_site/models/orthotic_design_form_model.dart';

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
  final MockOrthoticDesignFormRepository _repository =
      MockOrthoticDesignFormRepository();

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
    final form =
        await _repository.getDesignFormBySessionId(widget.session.sessionId ?? 0);

    if (!mounted) return;

    setState(() {
      _heelPad = form.heelPad;
      _deepHeelCupController.text =
          form.deepHeelCupMm?.toString() ?? '';
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

    await _repository.saveDesignForm(form);

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
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      flex: 3,
                      child: Column(
                        children: [
                          _buildSupportSection(),
                          const SizedBox(height: 16),
                          _buildReliefSection(),
                          const SizedBox(height: 16),
                          _buildNotesSection(),
                        ],
                      ),
                    ),
                    const SizedBox(width: 24),
                    Expanded(
                      flex: 2,
                      child: Column(
                        children: [
                          _buildAiSection(),
                          const SizedBox(height: 16),
                          _buildApprovalSection(),
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
            title: const Text('Heel Pad'),
            value: _heelPad,
            onChanged: (v) => setState(() => _heelPad = v),
          ),
          _buildNumberField(
            controller: _deepHeelCupController,
            label: 'Deep Heel Cup (mm)',
          ),
          const SizedBox(height: 12),
          _buildNumberField(
            controller: _heelRaiseController,
            label: 'Heel Raise (mm)',
          ),
          const SizedBox(height: 12),
          CheckboxListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Medial Arch Support'),
            value: _medialArchSupport,
            onChanged: (v) =>
                setState(() => _medialArchSupport = v ?? false),
          ),
          CheckboxListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Metatarsal Pad'),
            value: _metatarsalPad,
            onChanged: (v) => setState(() => _metatarsalPad = v ?? false),
          ),
          CheckboxListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Transverse Arch Support'),
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
      title: 'Relief / Bölgesel Düzenlemeler',
      child: Column(
        children: [
          _buildNumberField(
            controller: _posteriorReliefController,
            label: 'Posterior Relief (mm)',
          ),
          const SizedBox(height: 12),
          CheckboxListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Morton Relief'),
            value: _mortonRelief,
            onChanged: (v) => setState(() => _mortonRelief = v ?? false),
          ),
          CheckboxListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Bunion Pad'),
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

  Widget _buildAiSection() {
    return _buildSectionCard(
      title: 'AI Recommendation',
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.teal.withOpacity(0.06),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          _aiRecommendationJson ?? 'AI recommendation henüz yok.',
          style: const TextStyle(height: 1.5),
        ),
      ),
    );
  }

  Widget _buildApprovalSection() {
    return _buildSectionCard(
      title: 'Sipariş Onayı',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CheckboxListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Approved For Order'),
            value: _approvedForOrder,
            onChanged: (v) => setState(() => _approvedForOrder = v ?? false),
          ),
          const SizedBox(height: 8),
          Text(
            _approvedForOrder
                ? 'Bu form sipariş oluşturma için onaylandı.'
                : 'Bu form henüz siparişe hazır değil.',
            style: TextStyle(
              color: _approvedForOrder ? Colors.green : Colors.orange,
              fontWeight: FontWeight.w600,
            ),
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
}