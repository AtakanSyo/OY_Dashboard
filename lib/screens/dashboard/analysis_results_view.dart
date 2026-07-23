import 'dart:io';

import 'package:flutter/material.dart';
import 'package:oy_site/models/app_user.dart';
import 'package:oy_site/models/customer_analysis_result_model.dart';
import 'package:oy_site/widgets/analysis_score_trend_chart.dart';

enum FootSelectionSide { left, right }

enum AnalysisLayer { general, arch, pressure, posture, visuals }

enum FootHotspot { hallux, arch, metatarsal, heel, posture }

class AnalysisResultsView extends StatefulWidget {
  final AppUser currentUser;
  final String pageTitle;
  final List<CustomerAnalysisResult> results;
  final int initialSelectedIndex;

  const AnalysisResultsView({
    super.key,
    required this.currentUser,
    required this.pageTitle,
    required this.results,
    this.initialSelectedIndex = 0,
  });

  @override
  State<AnalysisResultsView> createState() => _AnalysisResultsViewState();
}

class _AnalysisResultsViewState extends State<AnalysisResultsView> {
  late int _selectedIndex;

  FootSelectionSide _selectedFootSide = FootSelectionSide.left;
  AnalysisLayer _selectedLayer = AnalysisLayer.general;
  FootHotspot _selectedHotspot = FootHotspot.arch;

  CustomerAnalysisResult? get _selectedResult {
    if (widget.results.isEmpty) return null;
    if (_selectedIndex < 0 || _selectedIndex >= widget.results.length) {
      return null;
    }
    return widget.results[_selectedIndex];
  }

  @override
  void initState() {
    super.initState();
    _selectedIndex = widget.initialSelectedIndex;
  }

  String _footTopAsset() {
    return _selectedFootSide == FootSelectionSide.left
        ? 'assets/images/analysis/left_foot_top.png'
        : 'assets/images/analysis/right_foot_top.png';
  }

  String _footSideAsset() {
    return _selectedFootSide == FootSelectionSide.left
        ? 'assets/images/analysis/left_foot_side.png'
        : 'assets/images/analysis/right_foot_side.png';
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}.'
        '${date.month.toString().padLeft(2, '0')}.'
        '${date.year}';
  }

  Color _scoreColor(double score) {
    if (score >= 75) return Colors.green;
    if (score >= 50) return Colors.orange;
    return Colors.red;
  }

  CustomerFootSummary _selectedFoot(CustomerAnalysisResult result) {
    return _selectedFootSide == FootSelectionSide.left
        ? result.leftFoot
        : result.rightFoot;
  }

  String _sideLabel() {
    return _selectedFootSide == FootSelectionSide.left ? 'Sol Ayak' : 'Sağ Ayak';
  }

  String _layerLabel(AnalysisLayer layer) {
    switch (layer) {
      case AnalysisLayer.general:
        return 'Genel';
      case AnalysisLayer.arch:
        return 'Ark';
      case AnalysisLayer.pressure:
        return 'Basınç';
      case AnalysisLayer.posture:
        return 'Duruş';
      case AnalysisLayer.visuals:
        return 'Görseller';
    }
  }

  IconData _layerIcon(AnalysisLayer layer) {
    switch (layer) {
      case AnalysisLayer.general:
        return Icons.dashboard_outlined;
      case AnalysisLayer.arch:
        return Icons.architecture_outlined;
      case AnalysisLayer.pressure:
        return Icons.touch_app_outlined;
      case AnalysisLayer.posture:
        return Icons.accessibility_new_outlined;
      case AnalysisLayer.visuals:
        return Icons.image_outlined;
    }
  }

  FootHotspot _defaultHotspotForLayer(AnalysisLayer layer) {
    switch (layer) {
      case AnalysisLayer.general:
        return FootHotspot.arch;
      case AnalysisLayer.arch:
        return FootHotspot.arch;
      case AnalysisLayer.pressure:
        return FootHotspot.metatarsal;
      case AnalysisLayer.posture:
        return FootHotspot.posture;
      case AnalysisLayer.visuals:
        return FootHotspot.arch;
    }
  }

  Alignment _sideAwareAlignment(Alignment leftFootAlignment) {
    if (_selectedFootSide == FootSelectionSide.left) {
      return leftFootAlignment;
    }

    return Alignment(
      -leftFootAlignment.x,
      leftFootAlignment.y,
    );
  }

  void _openImagePreview(String title, String filePath) {
    showDialog<void>(
      context: context,
      builder: (_) => Dialog(
        insetPadding: const EdgeInsets.all(24),
        child: SizedBox(
          width: 950,
          height: 720,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        title,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Expanded(
                  child: InteractiveViewer(
                    child: Image.file(
                      File(filePath),
                      fit: BoxFit.contain,
                      errorBuilder: (_, __, ___) => const Center(
                        child: Text('Görsel yüklenemedi'),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final selected = _selectedResult;

    if (widget.results.isEmpty || selected == null) {
      return const Center(
        child: Text('Analiz sonucu bulunamadı.'),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1180),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeaderSummary(selected),
              const SizedBox(height: 18),
              _buildSectionCard(
                title: 'Ölçüm Geçmişi',
                child: _buildSessionCards(),
              ),
              const SizedBox(height: 18),
              _buildLayerTabs(),
              const SizedBox(height: 18),
              _buildInteractiveFootSection(selected),
              const SizedBox(height: 18),
              _buildGeneralLayer(selected),
              if (_selectedLayer == AnalysisLayer.visuals) ...[
                const SizedBox(height: 18),
                _buildVisualLayer(selected),
              ],
              const SizedBox(height: 18),
              _buildCompactTrendSection(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeaderSummary(CustomerAnalysisResult result) {
    final left = result.leftFoot;
    final right = result.rightFoot;

    final averageScore = ((left.pressureScore +
                left.stabilityScore +
                left.archScore +
                right.pressureScore +
                right.stabilityScore +
                right.archScore) /
            6)
        .round();

    final color = _scoreColor(averageScore.toDouble());

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: _cardDecoration(),
      child: Row(
        children: [
          CircleAvatar(
            radius: 38,
            backgroundColor: color.withOpacity(0.12),
            child: Text(
              averageScore.toString(),
              style: TextStyle(
                color: color,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: 18),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.pageTitle,
                  style: const TextStyle(
                    fontSize: 23,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  result.overallSummary.isEmpty
                      ? 'Seçili ölçüm için analiz özeti görüntüleniyor.'
                      : result.overallSummary,
                  style: TextStyle(
                    color: Colors.grey[700],
                    height: 1.4,
                  ),
                ),
                if (result.generalRiskNote.trim().isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    result.generalRiskNote,
                    style: TextStyle(
                      color: Colors.orange.shade900,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 18),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                result.sessionCode,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                _formatDate(result.analysisDate),
                style: TextStyle(color: Colors.grey[700]),
              ),
              const SizedBox(height: 4),
              Text(
                result.locationLabel,
                style: TextStyle(color: Colors.grey[700]),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSessionCards() {
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: List.generate(widget.results.length, (index) {
        final result = widget.results[index];
        final isSelected = index == _selectedIndex;

        return InkWell(
          onTap: () {
            setState(() {
              _selectedIndex = index;
            });
          },
          borderRadius: BorderRadius.circular(14),
          child: Container(
            width: 230,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: isSelected ? Colors.teal.withOpacity(0.08) : Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: isSelected ? Colors.teal : Colors.grey.shade300,
                width: isSelected ? 1.4 : 1,
              ),
              boxShadow: const [
                BoxShadow(color: Colors.black12, blurRadius: 6),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  result.sessionCode,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(Icons.calendar_today_outlined, size: 15),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        _formatDate(result.analysisDate),
                        style: TextStyle(
                          color: Colors.grey[700],
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    const Icon(Icons.location_on_outlined, size: 15),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        result.locationLabel,
                        style: TextStyle(
                          color: Colors.grey[700],
                          fontSize: 13,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      }),
    );
  }

  Widget _buildLayerTabs() {
    return _buildSectionCard(
      title: 'Analiz Katmanı',
      child: Wrap(
        spacing: 10,
        runSpacing: 10,
        children: AnalysisLayer.values.map((layer) {
          final selected = layer == _selectedLayer;

          return ChoiceChip(
            selected: selected,
            avatar: Icon(
              _layerIcon(layer),
              size: 18,
              color: selected ? Colors.white : Colors.teal,
            ),
            label: Text(_layerLabel(layer)),
            selectedColor: Colors.teal,
            labelStyle: TextStyle(
              color: selected ? Colors.white : Colors.black87,
              fontWeight: selected ? FontWeight.bold : FontWeight.normal,
            ),
            onSelected: (_) {
              setState(() {
                _selectedLayer = layer;
                _selectedHotspot = _defaultHotspotForLayer(layer);
              });
            },
          );
        }).toList(),
      ),
    );
  }

  Widget _buildInteractiveFootSection(CustomerAnalysisResult result) {
    return _buildSectionCard(
      title: 'Ayak Haritası',
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _footSideButton(
                  label: 'Sol Ayak',
                  selected: _selectedFootSide == FootSelectionSide.left,
                  onTap: () {
                    setState(() {
                      _selectedFootSide = FootSelectionSide.left;
                    });
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _footSideButton(
                  label: 'Sağ Ayak',
                  selected: _selectedFootSide == FootSelectionSide.right,
                  onTap: () {
                    setState(() {
                      _selectedFootSide = FootSelectionSide.right;
                    });
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          LayoutBuilder(
            builder: (context, constraints) {
              final isCompact = constraints.maxWidth < 820;

              if (isCompact) {
                return Column(
                  children: [
                    _buildFootMap(result),
                    const SizedBox(height: 18),
                    _buildSelectedHotspotCard(result),
                  ],
                );
              }

              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    flex: 3,
                    child: _buildFootMap(result),
                  ),
                  const SizedBox(width: 20),
                  Expanded(
                    flex: 2,
                    child: _buildSelectedHotspotCard(result),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _footSideButton({
    required String label,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        decoration: BoxDecoration(
          color: selected ? Colors.teal.withOpacity(0.10) : Colors.grey.shade50,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected ? Colors.teal : Colors.grey.shade300,
            width: selected ? 1.4 : 1,
          ),
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: selected ? Colors.teal : Colors.black87,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFootMap(CustomerAnalysisResult result) {
    final foot = _selectedFoot(result);

    return Container(
      height: 520,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildTopFootMap(result, foot),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: _buildSideFootMap(result),
          ),
        ],
      ),
    );
  }

  Widget _buildTopFootMap(
    CustomerAnalysisResult result,
    CustomerFootSummary foot,
  ) {
    final halluxTarget = _sideAwareAlignment(const Alignment(0.3, -0.34));
    final halluxBox = _sideAwareAlignment(const Alignment(1.20, -0.42));

    final metatarsalTarget = _sideAwareAlignment(const Alignment(0.00, -0.3));
    final metatarsalBox = _sideAwareAlignment(const Alignment(0.40, -1.0));

    final archTarget = _sideAwareAlignment(const Alignment(0.20, 0.05));
    final archBox = _sideAwareAlignment(const Alignment(-0.20, 0.05));

    return Stack(
      children: [
        Positioned.fill(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Image.asset(
              _footTopAsset(),
              fit: BoxFit.contain,
            ),
          ),
        ),
        _connector(
          targetAlignment: halluxTarget,
          boxAlignment: halluxBox,
          selected: _selectedHotspot == FootHotspot.hallux,
        ),
        _connector(
          targetAlignment: metatarsalTarget,
          boxAlignment: metatarsalBox,
          selected: _selectedHotspot == FootHotspot.metatarsal,
        ),
        _connector(
          targetAlignment: archTarget,
          boxAlignment: archBox,
          selected: _selectedHotspot == FootHotspot.arch,
        ),
        _hotspot(
          hotspot: FootHotspot.hallux,
          boxAlignment: halluxBox,
          title: 'Halluks',
          value: _halluxValue(result),
        ),
        _hotspot(
          hotspot: FootHotspot.metatarsal,
          boxAlignment: metatarsalBox,
          title: 'Metatars',
          value: _pressureShortValue(foot),
        ),
        _hotspot(
          hotspot: FootHotspot.arch,
          boxAlignment: archBox,
          title: 'Ark',
          value: foot.archScore.toStringAsFixed(0),
        ),
      ],
    );
  }

  Widget _buildSideFootMap(CustomerAnalysisResult result) {
    final heelTarget = _sideAwareAlignment(const Alignment(-0.62, 0.28));
    final heelBox = _sideAwareAlignment(const Alignment(-0.82, 0.52));

    final postureTarget = _sideAwareAlignment(const Alignment(-0.2, -0.28));
    final postureBox = _sideAwareAlignment(const Alignment(0.42, -0.32));

    return Stack(
      children: [
        Positioned.fill(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Image.asset(
              _footSideAsset(),
              fit: BoxFit.contain,
            ),
          ),
        ),
        _connector(
          targetAlignment: heelTarget,
          boxAlignment: heelBox,
          selected: _selectedHotspot == FootHotspot.heel,
        ),
        _connector(
          targetAlignment: postureTarget,
          boxAlignment: postureBox,
          selected: _selectedHotspot == FootHotspot.posture,
        ),
        _hotspot(
          hotspot: FootHotspot.heel,
          boxAlignment: heelBox,
          title: 'Topuk',
          value: _heelValue(result),
        ),
        _hotspot(
          hotspot: FootHotspot.posture,
          boxAlignment: postureBox,
          title: 'Duruş',
          value: _postureValue(result),
        ),
      ],
    );
  }

  Widget _connector({
    required Alignment targetAlignment,
    required Alignment boxAlignment,
    required bool selected,
  }) {
    return Positioned.fill(
      child: IgnorePointer(
        child: CustomPaint(
          painter: _HotspotConnectorPainter(
            targetAlignment: targetAlignment,
            boxAlignment: boxAlignment,
            color: selected ? Colors.teal : Colors.grey,
          ),
        ),
      ),
    );
  }

  Widget _hotspot({
    required FootHotspot hotspot,
    required Alignment boxAlignment,
    required String title,
    required String value,
  }) {
    final selected = hotspot == _selectedHotspot;

    return Align(
      alignment: boxAlignment,
      child: InkWell(
        onTap: () {
          setState(() {
            _selectedHotspot = hotspot;
          });
        },
        borderRadius: BorderRadius.circular(999),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
          decoration: BoxDecoration(
            color: selected ? Colors.teal : Colors.white,
            borderRadius: BorderRadius.circular(999),
            border: Border.all(
              color: selected ? Colors.teal : Colors.grey.shade300,
              width: selected ? 1.6 : 1,
            ),
            boxShadow: const [
              BoxShadow(
                color: Colors.black12,
                blurRadius: 8,
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 9,
                height: 9,
                decoration: BoxDecoration(
                  color: selected ? Colors.white : Colors.teal,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
              Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: selected ? Colors.white : Colors.black87,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                  Text(
                    value,
                    style: TextStyle(
                      color: selected ? Colors.white : Colors.grey[700],
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSelectedHotspotCard(CustomerAnalysisResult result) {
    final detail = _hotspotDetail(result, _selectedHotspot);
    final gradientBarSpec = _gradientBarSpecForHotspot(
      result,
      _selectedHotspot,
    );

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            detail.title,
            style: const TextStyle(
              fontSize: 19,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            detail.subtitle,
            style: TextStyle(
              color: Colors.grey[700],
              height: 1.4,
            ),
          ),
          const SizedBox(height: 18),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: detail.metrics.map((metric) {
              return _miniMetricCard(
                title: metric.label,
                value: metric.value,
                helper: metric.helper,
                color: metric.color,
              );
            }).toList(),
          ),
          if (gradientBarSpec != null) ...[
            const SizedBox(height: 18),
            _buildGradientValueBar(gradientBarSpec),
          ],
          if (detail.description.trim().isNotEmpty) ...[
            const SizedBox(height: 18),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.teal.withOpacity(0.06),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                detail.description,
                style: const TextStyle(height: 1.45),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _miniMetricCard({
    required String title,
    required String value,
    required String helper,
    required Color color,
  }) {
    return Container(
      width: 150,
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withOpacity(0.20)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              color: Colors.grey[700],
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          if (helper.trim().isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              helper,
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 11,
              ),
            ),
          ],
        ],
      ),
    );
  }

  _GradientBarSpec? _gradientBarSpecForHotspot(
    CustomerAnalysisResult result,
    FootHotspot hotspot,
  ) {
    final foot = _selectedFoot(result);
    final report = result.parsedReport;
    final isLeft = _selectedFootSide == FootSelectionSide.left;

    final archIndex = isLeft ? report?.leftArchIndex : report?.rightArchIndex;
    final halluxAngle =
        (isLeft ? report?.leftHalluxAngle : report?.rightHalluxAngle)?.abs();
    final heelAngle =
        (isLeft ? report?.leftPronatorAngle : report?.rightPronatorAngle)
            ?.abs();
    final kneeAngle =
        (isLeft ? report?.leftKneeAngle : report?.rightKneeAngle)?.abs();

    switch (hotspot) {
      case FootHotspot.arch:
        if (archIndex != null) {
          return _GradientBarSpec(
            title: 'Ark İndeksi',
            value: archIndex,
            valueText: archIndex.toStringAsFixed(2),
            min: 0.12,
            max: 0.35,
            minLabel: 'Düşük ark',
            centerLabel: 'Normal',
            maxLabel: 'Yüksek ark',
            helper: 'Yeşil aralık yaklaşık 0.21–0.26 aralığını temsil eder.',
            colors: _balancedRiskGradientColors(),
          );
        }

        return _GradientBarSpec(
          title: 'Ark Skoru',
          value: foot.archScore,
          valueText: foot.archScore.toStringAsFixed(0),
          min: 0,
          max: 100,
          minLabel: 'Düşük',
          centerLabel: 'Orta',
          maxLabel: 'İyi',
          helper: 'Ark indeksi verisi bulunmadığı için ark skoru gösteriliyor.',
          colors: _highValueBetterGradientColors(),
        );

      case FootHotspot.hallux:
        if (halluxAngle == null) return null;

        return _GradientBarSpec(
          title: 'Halluks Açısı',
          value: halluxAngle,
          valueText: '${halluxAngle.toStringAsFixed(1)}°',
          min: 0,
          max: 25,
          minLabel: '0°',
          centerLabel: '10°',
          maxLabel: '25°+',
          helper: 'Düşük değer daha iyidir. 0–10° aralığı normal kabul edilir.',
          colors: _lowValueBetterGradientColors(),
        );

      case FootHotspot.metatarsal:
        return _GradientBarSpec(
          title: 'Basınç Konfor Skoru',
          value: foot.pressureScore,
          valueText: foot.pressureScore.toStringAsFixed(0),
          min: 0,
          max: 100,
          minLabel: 'Düşük',
          centerLabel: 'Orta',
          maxLabel: 'İyi',
          helper:
              'Yüksek skor daha dengeli ve konforlu basınç dağılımını temsil eder.',
          colors: _highValueBetterGradientColors(),
        );

      case FootHotspot.heel:
        if (heelAngle == null) return null;

        return _GradientBarSpec(
          title: 'Topuk Açısı',
          value: heelAngle,
          valueText: '${heelAngle.toStringAsFixed(1)}°',
          min: 0,
          max: 12,
          minLabel: '0°',
          centerLabel: '4°',
          maxLabel: '12°+',
          helper: 'Düşük değer daha iyidir. 0–4° aralığı normal kabul edilir.',
          colors: _lowValueBetterGradientColors(),
        );

      case FootHotspot.posture:
        if (kneeAngle == null) return null;

        return _GradientBarSpec(
          title: 'Diz Açısı',
          value: kneeAngle,
          valueText: '${kneeAngle.toStringAsFixed(1)}°',
          min: 0,
          max: 12,
          minLabel: '0°',
          centerLabel: '4°',
          maxLabel: '12°+',
          helper: 'Düşük değer daha iyidir. 0–4° aralığı normal kabul edilir.',
          colors: _lowValueBetterGradientColors(),
        );
    }
  }

  List<Color> _balancedRiskGradientColors() {
    return const [
      Colors.red,
      Colors.orange,
      Colors.yellow,
      Colors.green,
      Colors.yellow,
      Colors.orange,
      Colors.red,
    ];
  }

  List<Color> _lowValueBetterGradientColors() {
    return const [
      Colors.green,
      Colors.yellow,
      Colors.orange,
      Colors.red,
    ];
  }

  List<Color> _highValueBetterGradientColors() {
    return const [
      Colors.red,
      Colors.orange,
      Colors.yellow,
      Colors.green,
    ];
  }

  Widget _buildGradientValueBar(_GradientBarSpec spec) {
    final normalized = _normalizeValue(
      value: spec.value,
      min: spec.min,
      max: spec.max,
    );

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  spec.title,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: Text(
                  spec.valueText,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          LayoutBuilder(
            builder: (context, constraints) {
              final width = constraints.maxWidth;
              final markerLeft = ((normalized * width) - 10)
                  .clamp(0.0, width - 20)
                  .toDouble();

              return SizedBox(
                height: 36,
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Positioned(
                      left: 0,
                      right: 0,
                      top: 14,
                      child: Container(
                        height: 13,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(999),
                          gradient: LinearGradient(
                            colors: spec.colors,
                          ),
                          border: Border.all(
                            color: Colors.grey.shade300,
                            width: 0.7,
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      left: markerLeft,
                      top: 0,
                      child: Column(
                        children: [
                          const Icon(
                            Icons.arrow_drop_down,
                            size: 24,
                            color: Colors.black87,
                          ),
                          Container(
                            width: 2,
                            height: 16,
                            decoration: BoxDecoration(
                              color: Colors.black87,
                              borderRadius: BorderRadius.circular(999),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Expanded(
                child: Text(
                  spec.minLabel,
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 11,
                  ),
                ),
              ),
              if (spec.centerLabel != null)
                Expanded(
                  child: Text(
                    spec.centerLabel!,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 11,
                    ),
                  ),
                ),
              Expanded(
                child: Text(
                  spec.maxLabel,
                  textAlign: TextAlign.right,
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 11,
                  ),
                ),
              ),
            ],
          ),
          if (spec.helper.trim().isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              spec.helper,
              style: TextStyle(
                color: Colors.grey[700],
                fontSize: 12,
                height: 1.35,
              ),
            ),
          ],
        ],
      ),
    );
  }

  double _normalizeValue({
    required double value,
    required double min,
    required double max,
  }) {
    if (max <= min) return 0;

    return ((value - min) / (max - min)).clamp(0.0, 1.0).toDouble();
  }

  _HotspotDetail _hotspotDetail(
    CustomerAnalysisResult result,
    FootHotspot hotspot,
  ) {
    final foot = _selectedFoot(result);
    final report = result.parsedReport;
    final isLeft = _selectedFootSide == FootSelectionSide.left;

    final archHeight =
        isLeft ? report?.leftArchHeight : report?.rightArchHeight;
    final archIndex = isLeft ? report?.leftArchIndex : report?.rightArchIndex;
    final archWidth =
        isLeft ? report?.leftArchWidthIndex : report?.rightArchWidthIndex;
    final hallux =
        (isLeft ? report?.leftHalluxAngle : report?.rightHalluxAngle)?.abs();
    final heel =
        (isLeft ? report?.leftPronatorAngle : report?.rightPronatorAngle)
            ?.abs();
    final knee =
        (isLeft ? report?.leftKneeAngle : report?.rightKneeAngle)?.abs();

    switch (hotspot) {
      case FootHotspot.hallux:
        return _HotspotDetail(
          title: 'Halluks / Başparmak Bölgesi',
          subtitle: '${_sideLabel()} için başparmak açısı değerlendirmesi.',
          description: hallux == null
              ? 'Bu ölçümde halluks açısı verisi bulunmuyor.'
              : hallux <= 10
                  ? 'Halluks açısı normal aralıkta görünüyor.'
                  : 'Halluks açısı normal sınırın üzerinde. Başparmak hizalanması takip edilebilir.',
          metrics: [
            _HotspotMetric(
              label: 'Halluks Açısı',
              value: hallux == null ? '—' : '${hallux.toStringAsFixed(1)}°',
              helper: 'Normal: 0–10°',
              color: _riskColorByValue(hallux, 10, 20),
            ),
            _HotspotMetric(
              label: 'Ana Bulgu',
              value: foot.mainFinding.isEmpty ? '—' : 'Var',
              helper: foot.mainFinding,
              color: Colors.teal,
            ),
          ],
        );

      case FootHotspot.arch:
        return _HotspotDetail(
          title: 'Ark / Kemer Bölgesi',
          subtitle: '${_sideLabel()} için ark yüksekliği ve destek ihtiyacı.',
          description: foot.archSupportNeed,
          metrics: [
            _HotspotMetric(
              label: 'Ark Skoru',
              value: foot.archScore.toStringAsFixed(0),
              helper: foot.footType,
              color: _scoreColor(foot.archScore),
            ),
            _HotspotMetric(
              label: 'Ark Yüksekliği',
              value: archHeight == null
                  ? '—'
                  : '${archHeight.toStringAsFixed(1)} mm',
              helper: '3D scan verisi',
              color: Colors.teal,
            ),
            _HotspotMetric(
              label: 'Ark İndeksi',
              value: archIndex == null ? '—' : archIndex.toStringAsFixed(2),
              helper: 'Kemer yüksekliği faktörü',
              color: _riskColorByRange(archIndex, 0.21, 0.26),
            ),
            _HotspotMetric(
              label: 'Ark Genişliği',
              value: archWidth == null ? '—' : archWidth.toStringAsFixed(2),
              helper: 'Kemer genişliği faktörü',
              color: _riskColorByRange(archWidth, 0.42, 0.52),
            ),
          ],
        );

      case FootHotspot.metatarsal:
        return _HotspotDetail(
          title: 'Metatars / Ön Ayak Bölgesi',
          subtitle: '${_sideLabel()} için basınç ve ön ayak değerlendirmesi.',
          description: foot.pressureSummary,
          metrics: [
            _HotspotMetric(
              label: 'Basınç Skoru',
              value: foot.pressureScore.toStringAsFixed(0),
              helper: 'Konfor skoru',
              color: _scoreColor(foot.pressureScore),
            ),
            _HotspotMetric(
              label: 'Denge',
              value: _metricValue(result, 'Sol / Sağ Denge'),
              helper: 'Basınç dağılımı',
              color: Colors.teal,
            ),
            _HotspotMetric(
              label: 'Maks. Basınç',
              value: _metricValue(result, 'Maksimum Basınç Bölgesi'),
              helper: 'Riskli bölge',
              color: Colors.orange,
            ),
          ],
        );

      case FootHotspot.heel:
        return _HotspotDetail(
          title: 'Topuk Bölgesi',
          subtitle: '${_sideLabel()} için topuk açısı ve arka ayak takibi.',
          description: foot.balanceSummary,
          metrics: [
            _HotspotMetric(
              label: 'Topuk Açısı',
              value: heel == null ? '—' : '${heel.toStringAsFixed(1)}°',
              helper: 'Normal: 0–4°',
              color: _riskColorByValue(heel, 4, 8),
            ),
            _HotspotMetric(
              label: 'Stabilite',
              value: foot.stabilityScore.toStringAsFixed(0),
              helper: 'Stabilite skoru',
              color: _scoreColor(foot.stabilityScore),
            ),
          ],
        );

      case FootHotspot.posture:
        return _HotspotDetail(
          title: 'Duruş / Hizalanma',
          subtitle: '${_sideLabel()} için diz ve arka ayak hizalanması.',
          description: foot.balanceSummary,
          metrics: [
            _HotspotMetric(
              label: 'Diz Açısı',
              value: knee == null ? '—' : '${knee.toStringAsFixed(1)}°',
              helper: 'Normal: 0–4°',
              color: _riskColorByValue(knee, 4, 8),
            ),
            _HotspotMetric(
              label: 'Topuk Açısı',
              value: heel == null ? '—' : '${heel.toStringAsFixed(1)}°',
              helper: 'Pronasyon / supinasyon',
              color: _riskColorByValue(heel, 4, 8),
            ),
            _HotspotMetric(
              label: 'Risk',
              value: _metricValue(result, 'Gün Sonu Yorgunluk Riski'),
              helper: 'Genel yorgunluk riski',
              color: Colors.orange,
            ),
          ],
        );
    }
  }

  String _metricValue(CustomerAnalysisResult result, String label) {
    final match = result.metrics.where((m) => m.label == label);
    return match.isEmpty ? '—' : match.first.value;
  }

  Color _riskColorByValue(double? value, double normalMax, double mediumMax) {
    if (value == null) return Colors.grey;
    if (value <= normalMax) return Colors.green;
    if (value <= mediumMax) return Colors.orange;
    return Colors.red;
  }

  Color _riskColorByRange(double? value, double min, double max) {
    if (value == null) return Colors.grey;
    if (value >= min && value <= max) return Colors.green;
    return Colors.orange;
  }

  String _halluxValue(CustomerAnalysisResult result) {
    final report = result.parsedReport;
    final isLeft = _selectedFootSide == FootSelectionSide.left;
    final value =
        (isLeft ? report?.leftHalluxAngle : report?.rightHalluxAngle)?.abs();

    return value == null ? '—' : '${value.toStringAsFixed(1)}°';
  }

  String _heelValue(CustomerAnalysisResult result) {
    final report = result.parsedReport;
    final isLeft = _selectedFootSide == FootSelectionSide.left;
    final value =
        (isLeft ? report?.leftPronatorAngle : report?.rightPronatorAngle)
            ?.abs();

    return value == null ? '—' : '${value.toStringAsFixed(1)}°';
  }

  String _postureValue(CustomerAnalysisResult result) {
    final report = result.parsedReport;
    final isLeft = _selectedFootSide == FootSelectionSide.left;
    final value =
        (isLeft ? report?.leftKneeAngle : report?.rightKneeAngle)?.abs();

    return value == null ? '—' : '${value.toStringAsFixed(1)}°';
  }

  String _pressureShortValue(CustomerFootSummary foot) {
    return foot.pressureScore.toStringAsFixed(0);
  }

  Widget _buildGeneralLayer(CustomerAnalysisResult result) {
    final foot = _selectedFoot(result);

    return _buildSectionCard(
      title: 'Genel Özet',
      child: Wrap(
        spacing: 12,
        runSpacing: 12,
        children: [
          _scoreTile(
            title: 'Basınç Konforu',
            score: foot.pressureScore,
          ),
          _scoreTile(
            title: 'Stabilite',
            score: foot.stabilityScore,
          ),
          _scoreTile(
            title: 'Ark Desteği',
            score: foot.archScore,
          ),
          _infoBox('Ayak Tipi', foot.footType),
          _infoBox('Ana Bulgu', foot.mainFinding),
          _infoBox('Kemer Desteği', foot.archSupportNeed),
        ],
      ),
    );
  }

  Widget _buildVisualLayer(CustomerAnalysisResult result) {
    return _buildSectionCard(
      title: 'Görseller',
      child: _buildFootVisuals(
        isLeft: _selectedFootSide == FootSelectionSide.left,
        result: result,
      ),
    );
  }

  Widget _buildCompactTrendSection() {
    if (widget.results.length < 2) {
      return _buildSectionCard(
        title: 'Zamana Göre Genel Değişim',
        child: _buildTrendEmptyState(),
      );
    }

    return _buildSectionCard(
      title: 'Zamana Göre Genel Değişim',
      child: Wrap(
        spacing: 12,
        runSpacing: 12,
        children: [
          AnalysisScoreTrendChart(
            title: 'Basınç Konfor Skoru',
            results: widget.results,
            leftScoreSelector: (result) => result.leftFoot.pressureScore,
            rightScoreSelector: (result) => result.rightFoot.pressureScore,
          ),
          AnalysisScoreTrendChart(
            title: 'Stabilite Skoru',
            results: widget.results,
            leftScoreSelector: (result) => result.leftFoot.stabilityScore,
            rightScoreSelector: (result) => result.rightFoot.stabilityScore,
          ),
          AnalysisScoreTrendChart(
            title: 'Ark Desteği Skoru',
            results: widget.results,
            leftScoreSelector: (result) => result.leftFoot.archScore,
            rightScoreSelector: (result) => result.rightFoot.archScore,
          ),
        ],
      ),
    );
  }

  Widget _buildTrendEmptyState() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Row(
        children: [
          Icon(
            Icons.timeline_outlined,
            color: Colors.teal.shade700,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Zamana göre değişim grafikleri için en az iki ölçüm gereklidir. Yeni ölçümler eklendikçe basınç, stabilite ve ark skoru değişimleri burada görüntülenecektir.',
              style: TextStyle(
                color: Colors.grey[700],
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFootVisuals({
    required bool isLeft,
    required CustomerAnalysisResult result,
  }) {
    final visuals = result.visuals;

    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: [
        _imageTile(
          title: 'Yükseklik Haritası',
          filePath:
              isLeft ? visuals.archLeftImagePath : visuals.archRightImagePath,
        ),
        _imageTile(
          title: 'Ark Analizi',
          filePath: isLeft
              ? visuals.archSectionLeftImagePath
              : visuals.archSectionRightImagePath,
        ),
        _imageTile(
          title: '2D Ayak Görüntüsü',
          filePath: isLeft
              ? visuals.foot2dLeftImagePath
              : visuals.foot2dRightImagePath,
        ),
        _imageTile(
          title: 'Ayak-Bilek Açısı',
          filePath: isLeft
              ? visuals.pronatorLeftImagePath
              : visuals.pronatorRightImagePath,
        ),
      ],
    );
  }

  Widget _scoreTile({
    required String title,
    required double score,
  }) {
    final color = _scoreColor(score);

    return Container(
      width: 220,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withOpacity(0.06),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.18)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              color: Colors.grey[700],
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            score.toStringAsFixed(0),
            style: TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 8),
          LinearProgressIndicator(
            value: (score / 100).clamp(0, 1),
            minHeight: 8,
            backgroundColor: Colors.grey.shade300,
            color: color,
          ),
        ],
      ),
    );
  }

  Widget _infoBox(String label, String value) {
    return Container(
      width: 220,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              color: Colors.grey[700],
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            value.trim().isEmpty ? '—' : value,
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              height: 1.3,
            ),
          ),
        ],
      ),
    );
  }

  Widget _imageTile({
    required String title,
    required String? filePath,
  }) {
    final hasFile = filePath != null && filePath.trim().isNotEmpty;

    return InkWell(
      onTap: hasFile ? () => _openImagePreview(title, filePath) : null,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: 220,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.grey.shade50,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 10),
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: hasFile
                  ? Container(
                      width: double.infinity,
                      height: 150,
                      color: Colors.white,
                      child: Image.file(
                        File(filePath),
                        fit: BoxFit.contain,
                        errorBuilder: (_, __, ___) => Container(
                          alignment: Alignment.center,
                          color: Colors.grey.shade200,
                          child: const Text('Görsel yüklenemedi'),
                        ),
                      ),
                    )
                  : Container(
                      height: 150,
                      width: double.infinity,
                      color: Colors.grey.shade200,
                      alignment: Alignment.center,
                      child: const Text('Dosya yok'),
                    ),
            ),
          ],
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
      padding: const EdgeInsets.all(18),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 18,
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
      borderRadius: BorderRadius.circular(16),
      boxShadow: const [
        BoxShadow(color: Colors.black12, blurRadius: 8),
      ],
    );
  }
}

class _HotspotConnectorPainter extends CustomPainter {
  final Alignment targetAlignment;
  final Alignment boxAlignment;
  final Color color;

  const _HotspotConnectorPainter({
    required this.targetAlignment,
    required this.boxAlignment,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final target = targetAlignment.alongSize(size);
    final box = boxAlignment.alongSize(size);

    final paint = Paint()
      ..color = color.withOpacity(0.65)
      ..strokeWidth = 1.4
      ..style = PaintingStyle.stroke;

    canvas.drawLine(target, box, paint);

    final dotPaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    canvas.drawCircle(target, 4, dotPaint);
  }

  @override
  bool shouldRepaint(covariant _HotspotConnectorPainter oldDelegate) {
    return oldDelegate.targetAlignment != targetAlignment ||
        oldDelegate.boxAlignment != boxAlignment ||
        oldDelegate.color != color;
  }
}

class _GradientBarSpec {
  final String title;
  final double value;
  final String valueText;
  final double min;
  final double max;
  final String minLabel;
  final String? centerLabel;
  final String maxLabel;
  final String helper;
  final List<Color> colors;

  const _GradientBarSpec({
    required this.title,
    required this.value,
    required this.valueText,
    required this.min,
    required this.max,
    required this.minLabel,
    required this.centerLabel,
    required this.maxLabel,
    required this.helper,
    required this.colors,
  });
}

class _HotspotDetail {
  final String title;
  final String subtitle;
  final String description;
  final List<_HotspotMetric> metrics;

  const _HotspotDetail({
    required this.title,
    required this.subtitle,
    required this.description,
    required this.metrics,
  });
}

class _HotspotMetric {
  final String label;
  final String value;
  final String helper;
  final Color color;

  const _HotspotMetric({
    required this.label,
    required this.value,
    required this.helper,
    required this.color,
  });
}