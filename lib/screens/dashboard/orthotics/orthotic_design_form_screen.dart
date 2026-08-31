import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:oy_site/data/repositories/supabase_orthotic_design_form_repository.dart';
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

class _OrthoticDesignFormScreenState extends State<OrthoticDesignFormScreen> {
  static const String _assetBase = 'assets/images/orthotic_design';

  static const String _materialComfortSoft = 'comfort_soft';
  static const String _materialSupportMediumFirm = 'support_medium_firm';

  static const List<String> _materialTypes = [
    _materialComfortSoft,
    _materialSupportMediumFirm,
  ];

  final SupabaseOrthoticDesignFormRepository _repository =
      SupabaseOrthoticDesignFormRepository();

  bool _isLoading = true;
  bool _isSaving = false;

  late String _selectedMaterialType;

  late TextEditingController _medialArchLeftController;
  late TextEditingController _medialArchRightController;

  late int _lateralArchLeftMm;
  late int _lateralArchRightMm;

  late bool _heelCupStandard5mm;
  late TextEditingController _heelCupHeightController;

  late bool _noValgusVarus;
  late TextEditingController _pronationLeftController;
  late TextEditingController _pronationRightController;
  late TextEditingController _supinationLeftController;
  late TextEditingController _supinationRightController;

  late bool _showWedgeReferenceTable;

  late bool _noFlangeRequired;
  late TextEditingController _medialFlangeLeftController;
  late TextEditingController _medialFlangeRightController;
  late TextEditingController _lateralFlangeLeftController;
  late TextEditingController _lateralFlangeRightController;

  late TextEditingController _metatarsalPadLeftController;
  late TextEditingController _metatarsalPadRightController;
  late TextEditingController _heelPadLeftController;
  late TextEditingController _heelPadRightController;

  late TextEditingController _expertNotesController;

  String? _aiRecommendationJson;
  late bool _approvedForOrder;

  @override
  void initState() {
    super.initState();

    _medialArchLeftController = TextEditingController();
    _medialArchRightController = TextEditingController();

    _heelCupHeightController = TextEditingController();

    _pronationLeftController = TextEditingController();
    _pronationRightController = TextEditingController();
    _supinationLeftController = TextEditingController();
    _supinationRightController = TextEditingController();

    _medialFlangeLeftController = TextEditingController();
    _medialFlangeRightController = TextEditingController();
    _lateralFlangeLeftController = TextEditingController();
    _lateralFlangeRightController = TextEditingController();

    _metatarsalPadLeftController = TextEditingController();
    _metatarsalPadRightController = TextEditingController();
    _heelPadLeftController = TextEditingController();
    _heelPadRightController = TextEditingController();

    _expertNotesController = TextEditingController();

    _setDefaultValues();
    _loadForm();
  }

  @override
  void dispose() {
    _medialArchLeftController.dispose();
    _medialArchRightController.dispose();

    _heelCupHeightController.dispose();

    _pronationLeftController.dispose();
    _pronationRightController.dispose();
    _supinationLeftController.dispose();
    _supinationRightController.dispose();

    _medialFlangeLeftController.dispose();
    _medialFlangeRightController.dispose();
    _lateralFlangeLeftController.dispose();
    _lateralFlangeRightController.dispose();

    _metatarsalPadLeftController.dispose();
    _metatarsalPadRightController.dispose();
    _heelPadLeftController.dispose();
    _heelPadRightController.dispose();

    _expertNotesController.dispose();

    super.dispose();
  }

  void _setDefaultValues() {
    _selectedMaterialType = _materialComfortSoft;

    _lateralArchLeftMm = 0;
    _lateralArchRightMm = 0;

    _heelCupStandard5mm = true;
    _heelCupHeightController.text = '5';

    _noValgusVarus = true;
    _showWedgeReferenceTable = false;

    _noFlangeRequired = true;

    _aiRecommendationJson = null;
    _approvedForOrder = false;
  }

  Future<void> _loadForm() async {
    final form = await _repository.getBySessionId(
      widget.session.sessionId ?? 0,
    );

    if (!mounted) return;

    if (form == null) {
      setState(() {
        _isLoading = false;
      });
      return;
    }

    setState(() {
      _approvedForOrder = form.approvedForOrder;
      _aiRecommendationJson = form.aiRecommendationJson;
      _expertNotesController.text = form.expertNotes ?? '';

      if (form.deepHeelCupMm != null) {
        final heelCup = form.deepHeelCupMm!;
        _heelCupStandard5mm = heelCup == 5;
        _heelCupHeightController.text = _formatNumber(heelCup);
      }

      if (form.metatarsalPad) {
        _metatarsalPadLeftController.text = '1';
        _metatarsalPadRightController.text = '1';
      }

      if (form.heelPad) {
        _heelPadLeftController.text = '1';
        _heelPadRightController.text = '1';
      }

      if (form.transverseArchSupport) {
        _lateralArchLeftMm = 1;
        _lateralArchRightMm = 1;
      }

      _applyDesignParametersJson(form.aiRecommendationJson);
      final savedMaterialType = form.materialType;

      if (savedMaterialType != null && _materialTypes.contains(savedMaterialType)) {
        _selectedMaterialType = savedMaterialType;
      }

      _isLoading = false;
    });
  }

  double? _parseDouble(String value) {
    final text = value.trim();
    if (text.isEmpty) return null;
    return double.tryParse(text.replaceAll(',', '.'));
  }

  bool _hasNonZeroValue(TextEditingController controller) {
    final value = _parseDouble(controller.text);
    if (value == null) return false;
    return value != 0;
  }

  String _formatNumber(dynamic value) {
    final number = _numberFromJson(value);
    if (number == null) return '';

    if (number % 1 == 0) {
      return number.toInt().toString();
    }

    return number.toString();
  }

  Future<void> _saveForm() async {
    setState(() => _isSaving = true);

    try {
      final designParametersJson = _buildDesignParametersJson();

      final hasHeelPad = _hasNonZeroValue(_heelPadLeftController) ||
          _hasNonZeroValue(_heelPadRightController);

      final hasMetatarsalPad = _hasNonZeroValue(_metatarsalPadLeftController) ||
          _hasNonZeroValue(_metatarsalPadRightController);

      final hasMedialArchSupport =
          _hasNonZeroValue(_medialArchLeftController) ||
              _hasNonZeroValue(_medialArchRightController);

      final hasLateralArchSupport =
          _lateralArchLeftMm != 0 || _lateralArchRightMm != 0;

      final form = OrthoticDesignFormModel(
        sessionId: widget.session.sessionId ?? 0,
        expertUserId: widget.currentUser.userId ?? 0,

        materialType: _selectedMaterialType,

        heelPad: hasHeelPad,
        deepHeelCupMm: _heelCupStandard5mm
            ? 5
            : _parseDouble(_heelCupHeightController.text),
        heelRaiseMm: null,
        medialArchSupport: hasMedialArchSupport,
        metatarsalPad: hasMetatarsalPad,
        transverseArchSupport: hasLateralArchSupport,
        posteriorReliefMm: null,
        mortonRelief: false,
        bunionPad: false,

        expertNotes: _expertNotesController.text.trim(),
        aiRecommendationJson: designParametersJson,
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
          backgroundColor: Colors.green,
        ),
      );

      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;

      setState(() => _isSaving = false);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Tasarım formu kaydedilemedi: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  String _buildDesignParametersJson() {
    final payload = {
      'schema': 'orthotic_design_parameters_v1',
      'source': 'orthotic_design_form_screen',
      'updated_at': DateTime.now().toIso8601String(),
      'design_parameters': {
        'material_selection': {
          'material_type': _selectedMaterialType,
          'label': _materialLabel(_selectedMaterialType),
          'description': _materialDescription(_selectedMaterialType),
        },
        'medial_arch': {
          'left_mm': _parseDouble(_medialArchLeftController.text),
          'right_mm': _parseDouble(_medialArchRightController.text),
        },
        'lateral_arch': {
          'left_mm': _lateralArchLeftMm,
          'right_mm': _lateralArchRightMm,
        },
        'heel_cup': {
          'standard_5mm': _heelCupStandard5mm,
          'height_mm': _heelCupStandard5mm
              ? 5
              : _parseDouble(_heelCupHeightController.text),
        },
        'gait': {
          'no_valgus_varus': _noValgusVarus,
          'pronation_left_degree': _noValgusVarus
              ? null
              : _parseDouble(_pronationLeftController.text),
          'pronation_right_degree': _noValgusVarus
              ? null
              : _parseDouble(_pronationRightController.text),
          'supination_left_degree': _noValgusVarus
              ? null
              : _parseDouble(_supinationLeftController.text),
          'supination_right_degree': _noValgusVarus
              ? null
              : _parseDouble(_supinationRightController.text),
        },
        'flanges': {
          'not_required': _noFlangeRequired,
          'medial_left_mm': _noFlangeRequired
              ? null
              : _parseDouble(_medialFlangeLeftController.text),
          'medial_right_mm': _noFlangeRequired
              ? null
              : _parseDouble(_medialFlangeRightController.text),
          'lateral_left_mm': _noFlangeRequired
              ? null
              : _parseDouble(_lateralFlangeLeftController.text),
          'lateral_right_mm': _noFlangeRequired
              ? null
              : _parseDouble(_lateralFlangeRightController.text),
        },
        'pads': {
          'metatarsal_left_mm': _parseDouble(_metatarsalPadLeftController.text),
          'metatarsal_right_mm':
              _parseDouble(_metatarsalPadRightController.text),
          'heel_left_mm': _parseDouble(_heelPadLeftController.text),
          'heel_right_mm': _parseDouble(_heelPadRightController.text),
        },
      },
    };

    return const JsonEncoder.withIndent('  ').convert(payload);
  }

  void _applyDesignParametersJson(String? rawJson) {
    if (rawJson == null || rawJson.trim().isEmpty) return;

    try {
      final decoded = jsonDecode(rawJson);
      final root = _mapFromJson(decoded);

      if (root.isEmpty) return;

      final params = root['design_parameters'] == null
          ? root
          : _mapFromJson(root['design_parameters']);

      final materialSelection = _mapFromJson(params['material_selection']);
      final materialType = (materialSelection['material_type'] ?? '').toString();

      if (_materialTypes.contains(materialType)) {
        _selectedMaterialType = materialType;
      }

      final medialArch = _mapFromJson(params['medial_arch']);
      final lateralArch = _mapFromJson(params['lateral_arch']);
      final heelCup = _mapFromJson(params['heel_cup']);
      final gait = _mapFromJson(params['gait']);
      final flanges = _mapFromJson(params['flanges']);
      final pads = _mapFromJson(params['pads']);

      _setControllerFromJson(
        controller: _medialArchLeftController,
        value: medialArch['left_mm'],
      );
      _setControllerFromJson(
        controller: _medialArchRightController,
        value: medialArch['right_mm'],
      );

      _lateralArchLeftMm = _intFromJson(
        lateralArch['left_mm'],
        fallback: _lateralArchLeftMm,
      );
      _lateralArchRightMm = _intFromJson(
        lateralArch['right_mm'],
        fallback: _lateralArchRightMm,
      );

      _heelCupStandard5mm = _boolFromJson(
        heelCup['standard_5mm'],
        fallback: _heelCupStandard5mm,
      );
      _setControllerFromJson(
        controller: _heelCupHeightController,
        value: heelCup['height_mm'],
      );

      _noValgusVarus = _boolFromJson(
        gait['no_valgus_varus'],
        fallback: _noValgusVarus,
      );
      _setControllerFromJson(
        controller: _pronationLeftController,
        value: gait['pronation_left_degree'],
      );
      _setControllerFromJson(
        controller: _pronationRightController,
        value: gait['pronation_right_degree'],
      );
      _setControllerFromJson(
        controller: _supinationLeftController,
        value: gait['supination_left_degree'],
      );
      _setControllerFromJson(
        controller: _supinationRightController,
        value: gait['supination_right_degree'],
      );

      _noFlangeRequired = _boolFromJson(
        flanges['not_required'],
        fallback: _noFlangeRequired,
      );
      _setControllerFromJson(
        controller: _medialFlangeLeftController,
        value: flanges['medial_left_mm'],
      );
      _setControllerFromJson(
        controller: _medialFlangeRightController,
        value: flanges['medial_right_mm'],
      );
      _setControllerFromJson(
        controller: _lateralFlangeLeftController,
        value: flanges['lateral_left_mm'],
      );
      _setControllerFromJson(
        controller: _lateralFlangeRightController,
        value: flanges['lateral_right_mm'],
      );

      _setControllerFromJson(
        controller: _metatarsalPadLeftController,
        value: pads['metatarsal_left_mm'],
      );
      _setControllerFromJson(
        controller: _metatarsalPadRightController,
        value: pads['metatarsal_right_mm'],
      );
      _setControllerFromJson(
        controller: _heelPadLeftController,
        value: pads['heel_left_mm'],
      );
      _setControllerFromJson(
        controller: _heelPadRightController,
        value: pads['heel_right_mm'],
      );
    } catch (_) {
      // Eski aiRecommendationJson içeriği bu yeni şemaya uygun değilse yok sayılır.
    }
  }

  Map<String, dynamic> _mapFromJson(dynamic value) {
    if (value is Map<String, dynamic>) return value;
    if (value is Map) return Map<String, dynamic>.from(value);
    return <String, dynamic>{};
  }

  double? _numberFromJson(dynamic value) {
    if (value == null) return null;
    if (value is num) return value.toDouble();
    return double.tryParse(value.toString().replaceAll(',', '.'));
  }

  int _intFromJson(dynamic value, {required int fallback}) {
    if (value == null) return fallback;
    if (value is int) return value;
    if (value is num) return value.round();
    return int.tryParse(value.toString()) ?? fallback;
  }

  bool _boolFromJson(dynamic value, {required bool fallback}) {
    if (value == null) return fallback;
    if (value is bool) return value;

    final text = value.toString().toLowerCase().trim();

    if (text == 'true') return true;
    if (text == 'false') return false;

    return fallback;
  }

  void _setControllerFromJson({
    required TextEditingController controller,
    required dynamic value,
  }) {
    controller.text = _formatNumber(value);
  }

  String _formatSessionTitle() {
    return '${widget.session.sessionCode} • ${widget.currentUser.displayName}';
  }

  String _materialLabel(String materialType) {
    switch (materialType) {
      case _materialComfortSoft:
        return 'Konfor Odaklı Yumuşak Malzeme';
      case _materialSupportMediumFirm:
        return 'Ortopedik Destek Odaklı Orta-Sert Malzeme';
      default:
        return 'Malzeme seçilmedi';
    }
  }

  String _materialDescription(String materialType) {
    switch (materialType) {
      case _materialComfortSoft:
        return 'Daha yumuşak temas hissi sağlar. Günlük kullanımda konforu artırmak, basınç noktalarını yumuşatmak ve uzun süreli kullanım rahatlığı sağlamak için tercih edilir.';
      case _materialSupportMediumFirm:
        return 'Ayağı daha iyi sabitleyen, kavis desteğini daha net taşıyan ve ortopedik yönlendirme sağlayan daha kontrollü bir malzemedir. Destek ihtiyacı yüksek kullanıcılarda tercih edilir.';
      default:
        return '';
    }
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
        title: const Text('Ortez Tasarım Formu'),
        backgroundColor: Colors.teal,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1120),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeaderCard(),
                const SizedBox(height: 24),
                _buildMaterialSelectionSection(),
                const SizedBox(height: 18),
                _buildArchSection(),
                const SizedBox(height: 18),
                _buildHeelCupSection(),
                const SizedBox(height: 18),
                _buildGaitSection(),
                const SizedBox(height: 18),
                _buildFlangeSection(),
                const SizedBox(height: 18),
                _buildPadsSection(),
                const SizedBox(height: 18),
                _buildNotesSection(),
                const SizedBox(height: 90),
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
            'İç Taban Tasarımı',
            style: TextStyle(
              fontSize: 23,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _formatSessionTitle(),
            style: TextStyle(color: Colors.grey[700]),
          ),
          const SizedBox(height: 10),
          Text(
            'Bu formda iç taban üretimi için gerekli malzeme, kavis, topuk, basış, duvar ve ped parametreleri girilir.',
            style: TextStyle(
              color: Colors.grey[700],
              height: 1.35,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMaterialSelectionSection() {
    return _buildSectionCard(
      title: 'Malzeme Seçimi',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'İç taban üretiminde kullanılacak ana malzemeyi seçin. Bu seçim üretim ekibinin malzeme hazırlığını ve ürün sertlik karakterini belirler.',
            style: TextStyle(
              color: Colors.grey[700],
              height: 1.35,
            ),
          ),
          const SizedBox(height: 16),
          LayoutBuilder(
            builder: (context, constraints) {
              final isNarrow = constraints.maxWidth < 720;

              final cards = [
                _buildMaterialOptionCard(
                  materialType: _materialComfortSoft,
                  title: _materialLabel(_materialComfortSoft),
                  description: _materialDescription(_materialComfortSoft),
                  icon: Icons.spa_outlined,
                ),
                _buildMaterialOptionCard(
                  materialType: _materialSupportMediumFirm,
                  title: _materialLabel(_materialSupportMediumFirm),
                  description:
                      _materialDescription(_materialSupportMediumFirm),
                  icon: Icons.health_and_safety_outlined,
                ),
              ];

              if (isNarrow) {
                return Column(
                  children: [
                    cards[0],
                    const SizedBox(height: 12),
                    cards[1],
                  ],
                );
              }

              return Row(
                children: [
                  Expanded(child: cards[0]),
                  const SizedBox(width: 14),
                  Expanded(child: cards[1]),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildMaterialOptionCard({
    required String materialType,
    required String title,
    required String description,
    required IconData icon,
  }) {
    final selected = _selectedMaterialType == materialType;

    return InkWell(
      onTap: () {
        setState(() {
          _selectedMaterialType = materialType;
        });
      },
      borderRadius: BorderRadius.circular(16),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: selected ? Colors.teal.withOpacity(0.08) : Colors.grey.shade50,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: selected ? Colors.teal : Colors.grey.shade300,
            width: selected ? 1.6 : 1,
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Radio<String>(
              value: materialType,
              groupValue: _selectedMaterialType,
              activeColor: Colors.teal,
              onChanged: (value) {
                if (value == null) return;

                setState(() {
                  _selectedMaterialType = value;
                });
              },
            ),
            const SizedBox(width: 4),
            CircleAvatar(
              radius: 22,
              backgroundColor:
                  selected ? Colors.teal.withOpacity(0.14) : Colors.white,
              child: Icon(
                icon,
                color: selected ? Colors.teal : Colors.grey[700],
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: selected ? Colors.teal.shade900 : Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    description,
                    style: TextStyle(
                      color: Colors.grey[700],
                      height: 1.35,
                    ),
                  ),
                  if (selected) ...[
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.teal.withOpacity(0.10),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        'Seçili malzeme',
                        style: TextStyle(
                          color: Colors.teal.shade800,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildArchSection() {
    return _buildSectionCard(
      title: 'Kavisler',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildParameterCard(
            title: 'Medial Ark',
            imageAssetPath: '$_assetBase/medial_arch.png',
            description:
                'İç kavis yüksekliğini milimetre cinsinden giriniz.',
            child: _buildSideNumberFields(
              leftController: _medialArchLeftController,
              rightController: _medialArchRightController,
              unit: 'mm',
            ),
          ),
          const SizedBox(height: 16),
          _buildParameterCard(
            title: 'Lateral Ark',
            imageAssetPath: '$_assetBase/lateral_arch.png',
            description:
                'Dış kavisi yükseltmek ya da kısaltmak için değer seçiniz.',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildMmChoiceRow(
                  label: 'Sol',
                  selectedValue: _lateralArchLeftMm,
                  onChanged: (value) {
                    setState(() {
                      _lateralArchLeftMm = value;
                    });
                  },
                ),
                const SizedBox(height: 10),
                _buildMmChoiceRow(
                  label: 'Sağ',
                  selectedValue: _lateralArchRightMm,
                  onChanged: (value) {
                    setState(() {
                      _lateralArchRightMm = value;
                    });
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeelCupSection() {
    final expanded = !_heelCupStandard5mm;

    return _buildSectionCard(
      title: 'Topuk Yüksekliği (Heel Cup)',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildCheckboxRow(
            title: 'Standart 5 mm kullan',
            subtitle: 'Topukta bir sorun gözlenmemiştir.',
            value: _heelCupStandard5mm,
            onChanged: (value) {
              setState(() {
                _heelCupStandard5mm = value ?? true;

                if (_heelCupStandard5mm) {
                  _heelCupHeightController.text = '5';
                }
              });
            },
          ),
          if (_heelCupStandard5mm) ...[
            const SizedBox(height: 10),
            _buildCollapsedInfo(
              icon: Icons.check_circle_outline,
              text: 'Standart topuk yüksekliği 5 mm olarak kullanılacak.',
            ),
          ],
          _buildExpandableContent(
            expanded: expanded,
            child: _buildParameterCard(
              title: 'Özel Topuk Yüksekliği',
              imageAssetPath: '$_assetBase/heel_cup.png',
              description: 'Topuğun ihtiyacı olan yüksekliği girin.',
              child: _buildNumberField(
                controller: _heelCupHeightController,
                label: 'Topuk yüksekliği',
                unit: 'mm',
                enabled: expanded,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGaitSection() {
    final expanded = !_noValgusVarus;

    return _buildSectionCard(
      title: 'Basış Problemleri',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildCheckboxRow(
            title:
                'İçe ya da dışa basma (Valgus/Varus) gözlemlenmemiştir.',
            value: _noValgusVarus,
            onChanged: (value) {
              setState(() {
                _noValgusVarus = value ?? true;
              });
            },
          ),
          if (_noValgusVarus) ...[
            const SizedBox(height: 10),
            _buildCollapsedInfo(
              icon: Icons.check_circle_outline,
              text:
                  'Basış problemi yok olarak işaretlendi. Pronasyon ve supinasyon alanları kapalı.',
            ),
          ],
          _buildExpandableContent(
            expanded: expanded,
            child: Column(
              children: [
                _buildParameterCard(
                  title: 'İçe Basma / Pronasyon (Valgus)',
                  imageAssetPath: '$_assetBase/valgus_pronation.png',
                  description:
                      'Gerekli topuk kamasını derece cinsinden giriniz.',
                  child: _buildSideNumberFields(
                    leftController: _pronationLeftController,
                    rightController: _pronationRightController,
                    unit: '°',
                    enabled: expanded,
                  ),
                ),
                const SizedBox(height: 16),
                _buildParameterCard(
                  title: 'Dışa Basma / Supinasyon (Varus)',
                  imageAssetPath: '$_assetBase/varus_supination.png',
                  description:
                      'Gerekli topuk kamasını derece cinsinden giriniz.',
                  child: _buildSideNumberFields(
                    leftController: _supinationLeftController,
                    rightController: _supinationRightController,
                    unit: '°',
                    enabled: expanded,
                  ),
                ),
                const SizedBox(height: 16),
                _buildWedgeReferenceToggle(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFlangeSection() {
    final expanded = !_noFlangeRequired;

    return _buildSectionCard(
      title: 'Duvarlar (Ark Bölgesi)',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildCheckboxRow(
            title: 'İçe ya da dış kama gereksinimi gözlemlenmemiştir.',
            value: _noFlangeRequired,
            onChanged: (value) {
              setState(() {
                _noFlangeRequired = value ?? true;
              });
            },
          ),
          if (_noFlangeRequired) ...[
            const SizedBox(height: 10),
            _buildCollapsedInfo(
              icon: Icons.check_circle_outline,
              text:
                  'Duvar/kama gereksinimi yok olarak işaretlendi. Medial ve lateral flange alanları kapalı.',
            ),
          ],
          _buildExpandableContent(
            expanded: expanded,
            child: Column(
              children: [
                _buildParameterCard(
                  title: 'İç Duvar (Medial Flange)',
                  imageAssetPath: '$_assetBase/medial_flange.png',
                  description: 'Gerekli kamayı milimetre cinsinden giriniz.',
                  child: _buildSideNumberFields(
                    leftController: _medialFlangeLeftController,
                    rightController: _medialFlangeRightController,
                    unit: 'mm',
                    enabled: expanded,
                  ),
                ),
                const SizedBox(height: 16),
                _buildParameterCard(
                  title: 'Dış Duvar (Lateral Flange)',
                  imageAssetPath: '$_assetBase/lateral_flange.png',
                  description: 'Gerekli kamayı milimetre cinsinden giriniz.',
                  child: _buildSideNumberFields(
                    leftController: _lateralFlangeLeftController,
                    rightController: _lateralFlangeRightController,
                    unit: 'mm',
                    enabled: expanded,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPadsSection() {
    return _buildSectionCard(
      title: 'Pedler',
      child: Column(
        children: [
          _buildParameterCard(
            title: 'Tarak Kemiği Yastığı (Metatarsal Ped)',
            imageAssetPath: '$_assetBase/metatarsal_pad.png',
            description: 'Gerekli yükseltiyi milimetre cinsinden giriniz.',
            child: _buildSideNumberFields(
              leftController: _metatarsalPadLeftController,
              rightController: _metatarsalPadRightController,
              unit: 'mm',
            ),
          ),
          const SizedBox(height: 16),
          _buildParameterCard(
            title: 'Topuk Yastığı (Heel Ped)',
            imageAssetPath: '$_assetBase/heel_pad.png',
            description: 'Gerekli yükseltiyi milimetre cinsinden giriniz.',
            child: _buildSideNumberFields(
              leftController: _heelPadLeftController,
              rightController: _heelPadRightController,
              unit: 'mm',
            ),
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

  Widget _buildCheckboxRow({
    required String title,
    String? subtitle,
    required bool value,
    required ValueChanged<bool?> onChanged,
  }) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: CheckboxListTile(
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 4,
        ),
        controlAffinity: ListTileControlAffinity.leading,
        activeColor: Colors.teal,
        title: Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
          ),
        ),
        subtitle: subtitle == null ? null : Text(subtitle),
        value: value,
        onChanged: onChanged,
      ),
    );
  }

  Widget _buildCollapsedInfo({
    required IconData icon,
    required String text,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.teal.withOpacity(0.06),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.teal.withOpacity(0.15)),
      ),
      child: Row(
        children: [
          Icon(
            icon,
            color: Colors.teal,
            size: 20,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                color: Colors.teal.shade900,
                height: 1.35,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExpandableContent({
    required bool expanded,
    required Widget child,
  }) {
    return AnimatedCrossFade(
      firstChild: const SizedBox(width: double.infinity),
      secondChild: Padding(
        padding: const EdgeInsets.only(top: 16),
        child: child,
      ),
      crossFadeState:
          expanded ? CrossFadeState.showSecond : CrossFadeState.showFirst,
      duration: const Duration(milliseconds: 220),
      sizeCurve: Curves.easeInOut,
    );
  }

  Widget _buildParameterCard({
    required String title,
    required String imageAssetPath,
    required String description,
    required Widget child,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isNarrow = constraints.maxWidth < 560;

          if (isNarrow) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildReferenceImage(imageAssetPath),
                const SizedBox(height: 14),
                _buildParameterContent(
                  title: title,
                  description: description,
                  child: child,
                ),
              ],
            );
          }

          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: 360,
                child: _buildReferenceImage(imageAssetPath),
              ),
              const SizedBox(width: 18),
              Expanded(
                child: _buildParameterContent(
                  title: title,
                  description: description,
                  child: child,
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildParameterContent({
    required String title,
    required String description,
    required Widget child,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          description,
          style: TextStyle(
            color: Colors.grey[700],
            height: 1.35,
          ),
        ),
        const SizedBox(height: 14),
        child,
      ],
    );
  }

  Widget _buildReferenceImage(String assetPath) {
    return Container(
      width: double.infinity,
      height: 180,
      alignment: Alignment.center,
      padding: const EdgeInsets.all(5),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Image.asset(
        assetPath,
        fit: BoxFit.contain,
        errorBuilder: (_, __, ___) {
          return Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.image_not_supported_outlined,
                color: Colors.grey[500],
              ),
              const SizedBox(height: 6),
              Text(
                'Görsel bulunamadı',
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                assetPath,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.grey[500],
                  fontSize: 10,
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildSideNumberFields({
    required TextEditingController leftController,
    required TextEditingController rightController,
    required String unit,
    bool enabled = true,
  }) {
    return Row(
      children: [
        Expanded(
          child: _buildNumberField(
            controller: leftController,
            label: 'Sol',
            unit: unit,
            enabled: enabled,
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: _buildNumberField(
            controller: rightController,
            label: 'Sağ',
            unit: unit,
            enabled: enabled,
          ),
        ),
      ],
    );
  }

  Widget _buildNumberField({
    required TextEditingController controller,
    required String label,
    required String unit,
    bool enabled = true,
  }) {
    return TextField(
      controller: controller,
      enabled: enabled,
      keyboardType: const TextInputType.numberWithOptions(
        decimal: true,
        signed: true,
      ),
      decoration: InputDecoration(
        labelText: label,
        suffixText: unit,
        filled: !enabled,
        fillColor: Colors.grey.shade100,
        border: const OutlineInputBorder(),
      ),
    );
  }

  Widget _buildMmChoiceRow({
    required String label,
    required int selectedValue,
    required ValueChanged<int> onChanged,
  }) {
    const values = [-2, -1, 0, 1, 2, 3, 4];

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 44,
          child: Padding(
            padding: const EdgeInsets.only(top: 10),
            child: Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
        Expanded(
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            children: values.map((value) {
              final selected = value == selectedValue;

              return ChoiceChip(
                label: Text(_formatSignedMm(value)),
                selected: selected,
                selectedColor: Colors.teal,
                backgroundColor: Colors.white,
                labelStyle: TextStyle(
                  color: selected ? Colors.white : Colors.black87,
                  fontWeight: selected ? FontWeight.bold : FontWeight.normal,
                ),
                side: BorderSide(
                  color: selected ? Colors.teal : Colors.grey.shade300,
                ),
                onSelected: (_) => onChanged(value),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  String _formatSignedMm(int value) {
    if (value > 0) return '+$value mm';
    return '$value mm';
  }

  Widget _buildWedgeReferenceToggle() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        children: [
          InkWell(
            onTap: () {
              setState(() {
                _showWedgeReferenceTable = !_showWedgeReferenceTable;
              });
            },
            borderRadius: BorderRadius.circular(14),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 14,
                vertical: 13,
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.straighten,
                    color: Colors.teal.shade700,
                    size: 20,
                  ),
                  const SizedBox(width: 10),
                  const Expanded(
                    child: Text(
                      'Kama Açısı Referans Tablosu',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Icon(
                    _showWedgeReferenceTable
                        ? Icons.keyboard_arrow_up
                        : Icons.keyboard_arrow_down,
                    color: Colors.grey[700],
                  ),
                ],
              ),
            ),
          ),
          AnimatedCrossFade(
            firstChild: const SizedBox(width: double.infinity),
            secondChild: Padding(
              padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
              child: _buildWedgeReferenceTable(),
            ),
            crossFadeState: _showWedgeReferenceTable
                ? CrossFadeState.showSecond
                : CrossFadeState.showFirst,
            duration: const Duration(milliseconds: 180),
          ),
        ],
      ),
    );
  }

  Widget _buildWedgeReferenceTable() {
    final rows = [
      ['1°', '0.9 mm', '1.0 mm', '1.2 mm'],
      ['2°', '1.7 mm', '2.1 mm', '2.4 mm'],
      ['3°', '2.6 mm', '3.1 mm', '3.7 mm'],
      ['4°', '3.5 mm', '4.2 mm', '4.9 mm'],
    ];

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: SizedBox(
          width: 640,
          child: Table(
            border: TableBorder(
              horizontalInside: BorderSide(
                color: Colors.grey.shade200,
              ),
            ),
            columnWidths: const {
              0: FixedColumnWidth(120),
              1: FixedColumnWidth(170),
              2: FixedColumnWidth(170),
              3: FixedColumnWidth(170),
            },
            children: [
              TableRow(
                children: [
                  _tableCell('Kama Açısı (θ)', header: true),
                  _tableCell('Dar Topuk (50 mm)', header: true),
                  _tableCell('Ortalama Topuk (60 mm)', header: true),
                  _tableCell('Geniş Topuk', header: true),
                ],
              ),
              ...rows.map(
                (row) => TableRow(
                  children: [
                    _tableCell(row[0]),
                    _tableCell(row[1]),
                    _tableCell(row[2]),
                    _tableCell(row[3]),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _tableCell(String text, {bool header = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: 8,
        vertical: 10,
      ),
      child: Text(
        text,
        style: TextStyle(
          fontWeight: header ? FontWeight.bold : FontWeight.normal,
          color: header ? Colors.teal.shade900 : Colors.black87,
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
          const SizedBox(height: 8),
          Divider(color: Colors.grey.shade300),
          const SizedBox(height: 12),
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
}