import 'dart:io';

import 'package:flutter/material.dart';
import 'package:oy_site/models/app_user.dart';
import 'package:oy_site/models/customer_analysis_result_model.dart';
import 'package:oy_site/widgets/analysis_score_trend_chart.dart';

enum FootSelectionSide { left, right }

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
  bool _showFootPanel = true;

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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionCard(
            title: 'Ölçüm Geçmişi',
            child: _buildSessionCards(),
          ),
          const SizedBox(height: 18),
          _buildSectionCard(
            title: 'Analiz Bilgileri',
            child: _buildCompactGeneralResults(selected),
          ),
          const SizedBox(height: 18),
          _buildSectionCard(
            title: 'Ayak Seçimi',
            child: _buildFootSelector(),
          ),
          const SizedBox(height: 18),
          AnimatedSize(
            duration: const Duration(milliseconds: 320),
            curve: Curves.easeInOut,
            alignment: Alignment.topCenter,
            child: _showFootPanel
                ? _buildSelectedFootPanel(selected)
                : const SizedBox.shrink(),
          ),
          const SizedBox(height: 18),
          _buildSectionCard(
            title: 'Zamana Göre Skor Değişimi',
            child: _buildTrendCharts(),
          ),
          const SizedBox(height: 18),
          _buildSectionCard(
            title: 'Ölçüm Değerlerinin Zaman İçindeki Değişimi',
            child: _buildMeasurementTrendCharts(),
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

  Widget _buildFootSelector() {
    return Row(
      children: [
        Expanded(
          child: _footSelectionButton(
            label: 'Sol Ayak',
            icon: Icons.arrow_circle_left_outlined,
            isSelected: _selectedFootSide == FootSelectionSide.left,
            onTap: () {
              setState(() {
                _selectedFootSide = FootSelectionSide.left;
                _showFootPanel = true;
              });
            },
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: _footSelectionButton(
            label: 'Sağ Ayak',
            icon: Icons.arrow_circle_right_outlined,
            isSelected: _selectedFootSide == FootSelectionSide.right,
            onTap: () {
              setState(() {
                _selectedFootSide = FootSelectionSide.right;
                _showFootPanel = true;
              });
            },
          ),
        ),
      ],
    );
  }

  Widget _footSelectionButton({
    required String label,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
        decoration: BoxDecoration(
          color: isSelected ? Colors.teal.withOpacity(0.10) : Colors.grey.shade50,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected ? Colors.teal : Colors.grey.shade300,
            width: isSelected ? 1.4 : 1,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: isSelected ? Colors.teal : Colors.grey.shade700),
            const SizedBox(width: 10),
            Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 15,
                color: isSelected ? Colors.teal : const Color(0xFF1A2340),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCompactGeneralResults(CustomerAnalysisResult result) {
    final metrics = result.metrics;

    String metricValue(String label) {
      final match = metrics.where((m) => m.label == label);
      return match.isEmpty ? '—' : match.first.value;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            _compactTile(
              title: 'Session',
              value: result.sessionCode,
              icon: Icons.tag,
            ),
            _compactTile(
              title: 'Tarih',
              value: _formatDate(result.analysisDate),
              icon: Icons.calendar_today_outlined,
            ),
            _compactTile(
              title: 'Yer',
              value: result.locationLabel,
              icon: Icons.location_on_outlined,
            ),
            _compactTile(
              title: 'Denge',
              value: metricValue('Sol / Sağ Denge'),
              icon: Icons.balance,
            ),
            _compactTile(
              title: 'Maks. Basınç',
              value: metricValue('Maksimum Basınç Bölgesi'),
              icon: Icons.my_location_outlined,
            ),
            _compactTile(
              title: 'Risk',
              value: metricValue('Gün Sonu Yorgunluk Riski'),
              icon: Icons.warning_amber_outlined,
            ),
          ],
        ),
        const SizedBox(height: 14),

        Align(
          alignment: Alignment.centerLeft,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 620),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.08),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.orange.withOpacity(0.2)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Genel Özet',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    result.overallSummary,
                    style: const TextStyle(height: 1.4),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    result.generalRiskNote,
                    style: TextStyle(
                      color: Colors.orange.shade900,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),

        if (result.recommendations.isNotEmpty) ...[
          const SizedBox(height: 14),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: result.recommendations.map((item) {
              return Container(
                width: 260,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.teal.withOpacity(0.06),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.teal.withOpacity(0.18)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(
                      Icons.check_circle_outline,
                      color: Colors.teal,
                      size: 18,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      item.title,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      item.description,
                      style: TextStyle(
                        color: Colors.grey[700],
                        height: 1.35,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ],
      ],
    );
  }

  Widget _buildSelectedFootPanel(CustomerAnalysisResult result) {
    final isLeft = _selectedFootSide == FootSelectionSide.left;
    final foot = isLeft ? result.leftFoot : result.rightFoot;
    final report = result.parsedReport;

    final title = isLeft ? 'Sol Ayak Detayı' : 'Sağ Ayak Detayı';
    final textAlign = isLeft ? TextAlign.left : TextAlign.right;
    final crossAlign =
        isLeft ? CrossAxisAlignment.start : CrossAxisAlignment.end;

    return _buildSectionCard(
      title: title,
      child: Column(
        crossAxisAlignment: crossAlign,
        children: [
          Wrap(
            spacing: 10,
            runSpacing: 10,
            alignment: isLeft ? WrapAlignment.start : WrapAlignment.end,
            children: [
              _scoreTile(
                title: 'Basınç Konfor Skoru',
                score: foot.pressureScore,
                textAlign: textAlign,
                contentAlignment: crossAlign,
              ),
              _scoreTile(
                title: 'Stabilite Skoru',
                score: foot.stabilityScore,
                textAlign: textAlign,
                contentAlignment: crossAlign,
              ),
              _scoreTile(
                title: 'Ark Desteği Skoru',
                score: foot.archScore,
                textAlign: textAlign,
                contentAlignment: crossAlign,
              ),
            ],
          ),
          const SizedBox(height: 18),
          _buildInfoGrid(
            foot: foot,
            textAlign: textAlign,
            crossAlign: crossAlign,
          ),
          if (report != null) ...[
            const SizedBox(height: 18),
            _buildClinicalEvaluationPanel(
              result: result,
              isLeft: isLeft,
            ),
          ],
          const SizedBox(height: 18),
          _buildFootVisuals(
            isLeft: isLeft,
            result: result,
          ),
        ],
      ),
    );
  }

  Widget _buildInfoGrid({
    required CustomerFootSummary foot,
    required TextAlign textAlign,
    required CrossAxisAlignment crossAlign,
  }) {
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      alignment: textAlign == TextAlign.left
          ? WrapAlignment.start
          : WrapAlignment.end,
      children: [
        _infoBox('Ayak Tipi', foot.footType, textAlign, crossAlign),
        _infoBox('Basınç Özeti', foot.pressureSummary, textAlign, crossAlign),
        _infoBox('Denge Özeti', foot.balanceSummary, textAlign, crossAlign),
        _infoBox('Kemer Desteği', foot.archSupportNeed, textAlign, crossAlign),
        _infoBox('Ana Bulgular', foot.mainFinding, textAlign, crossAlign),
      ],
    );
  }


  Widget _buildClinicalEvaluationPanel({
    required CustomerAnalysisResult result,
    required bool isLeft,
  }) {
    final report = result.parsedReport;
    if (report == null) return const SizedBox.shrink();

    final archIndex =
        isLeft ? report.leftArchIndex : report.rightArchIndex;
    final archWidthIndex =
        isLeft ? report.leftArchWidthIndex : report.rightArchWidthIndex;
    final halluxAngle =
        (isLeft ? report.leftHalluxAngle : report.rightHalluxAngle)?.abs();
    final heelAngle =
        (isLeft ? report.leftPronatorAngle : report.rightPronatorAngle)?.abs();
    final kneeAngle =
        (isLeft ? report.leftKneeAngle : report.rightKneeAngle)?.abs();

    return _subPanel(
      title: 'Klinik Değerlendirme',
      child: Wrap(
        spacing: 12,
        runSpacing: 12,
        children: [
          ClinicalEvaluationCard(
            title: 'Kemer Yüksekliği Faktörü',
            value: archIndex,
            unit: '',
            minValue: 0.16,
            maxValue: 0.34,
            normalMin: 0.21,
            normalMax: 0.26,
            lowLabel: 'Yüksek Ark',
            normalLabel: 'Normal',
            highLabel: 'Düz Taban',
          ),
          ClinicalEvaluationCard(
            title: 'Kemer Genişliği Faktörü',
            value: archWidthIndex,
            unit: '',
            minValue: 0.30,
            maxValue: 0.70,
            normalMin: 0.42,
            normalMax: 0.52,
            lowLabel: 'Yüksek Ark Eğilimi',
            normalLabel: 'Normal',
            highLabel: 'Düz Taban Eğilimi',
          ),
          ClinicalEvaluationCard(
            title: 'Halluks Açısı',
            value: halluxAngle,
            unit: '°',
            minValue: 0,
            maxValue: 40,
            normalMin: 0,
            normalMax: 10,
            lowLabel: 'Normal',
            normalLabel: 'Normal',
            highLabel: 'Risk Artışı',
            oneDirectional: true,
          ),
          ClinicalEvaluationCard(
            title: 'Topuk Açısı',
            value: heelAngle,
            unit: '°',
            minValue: 0,
            maxValue: 20,
            normalMin: 0,
            normalMax: 4,
            lowLabel: 'Normal',
            normalLabel: 'Normal',
            highLabel: 'Risk Artışı',
            oneDirectional: true,
          ),
          ClinicalEvaluationCard(
            title: 'Diz Açısı',
            value: kneeAngle,
            unit: '°',
            minValue: 0,
            maxValue: 20,
            normalMin: 0,
            normalMax: 4,
            lowLabel: 'Normal',
            normalLabel: 'Normal',
            highLabel: 'Risk Artışı',
            oneDirectional: true,
          ),
        ],
      ),
    );
  }

  Widget _subPanel({
    required String title,
    required Widget child,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 15,
            ),
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }

  Widget _infoBox(
    String label,
    String value,
    TextAlign textAlign,
    CrossAxisAlignment crossAlign,
  ) {
    return Container(
      width: 220,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        crossAxisAlignment: crossAlign,
        children: [
          Text(
            label,
            textAlign: textAlign,
            style: TextStyle(
              color: Colors.grey[700],
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            textAlign: textAlign,
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              height: 1.3,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMeasurementTrendCharts() {
    final parsedResults =
        widget.results.where((e) => e.parsedReport != null).toList();

    if (parsedResults.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.grey.shade50,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: Text(
          'Bu bölüm için henüz ölçüm raporu verisi bulunmuyor.',
          style: TextStyle(
            color: Colors.grey[700],
            height: 1.4,
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Biyomekanik Göstergeler',
          style: TextStyle(
            color: Colors.grey[800],
            fontWeight: FontWeight.bold,
            fontSize: 15,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'Zamana göre değişimi takip edilmesi anlamlı olan ölçüm değerleri gösterilir.',
          style: TextStyle(
            color: Colors.grey[600],
            fontSize: 13,
            height: 1.4,
          ),
        ),
        const SizedBox(height: 14),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            AnalysisScoreTrendChart(
              title: 'Kemer Yüksekliği (mm)',
              results: parsedResults,
              leftScoreSelector: (result) =>
                  result.parsedReport?.leftArchHeight ?? 0,
              rightScoreSelector: (result) =>
                  result.parsedReport?.rightArchHeight ?? 0,
            ),
            AnalysisScoreTrendChart(
              title: 'Halluks Açısı (°)',
              results: parsedResults,
              leftScoreSelector: (result) =>
                  result.parsedReport?.leftHalluxAngle ?? 0,
              rightScoreSelector: (result) =>
                  result.parsedReport?.rightHalluxAngle ?? 0,
            ),
            AnalysisScoreTrendChart(
              title: 'Pronasyon Açısı (°)',
              results: parsedResults,
              leftScoreSelector: (result) =>
                  result.parsedReport?.leftPronatorAngle ?? 0,
              rightScoreSelector: (result) =>
                  result.parsedReport?.rightPronatorAngle ?? 0,
            ),
          ],
        ),
      ],
    );
  }
  
  Widget _buildTrendCharts() {
    return Wrap(
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
    );
  }

  Widget _buildFootVisuals({
    required bool isLeft,
    required CustomerAnalysisResult result,
  }) {
    final visuals = result.visuals;
    final textAlign = isLeft ? TextAlign.left : TextAlign.right;
    final crossAlign =
        isLeft ? CrossAxisAlignment.start : CrossAxisAlignment.end;

    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: [
        _imageTile(
          title: 'Yükseklik Haritası',
          filePath:
              isLeft ? visuals.archLeftImagePath : visuals.archRightImagePath,
          textAlign: textAlign,
          contentAlignment: crossAlign,
        ),
        _imageTile(
          title: 'Ark Analizi',
          filePath: isLeft
              ? visuals.archSectionLeftImagePath
              : visuals.archSectionRightImagePath,
          textAlign: textAlign,
          contentAlignment: crossAlign,
        ),
        _imageTile(
          title: '2D Ayak Görüntüsü',
          filePath:
              isLeft ? visuals.foot2dLeftImagePath : visuals.foot2dRightImagePath,
          textAlign: textAlign,
          contentAlignment: crossAlign,
        ),
        _imageTile(
          title: 'Ayak-Bilek Açısı',
          filePath: isLeft
              ? visuals.pronatorLeftImagePath
              : visuals.pronatorRightImagePath,
          textAlign: textAlign,
          contentAlignment: crossAlign,
        ),
      ],
    );
  }

  Widget _compactTile({
    required String title,
    required String value,
    required IconData icon,
  }) {
    return Container(
      width: 150,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        children: [
          Icon(icon, size: 18, color: Colors.teal),
          const SizedBox(height: 6),
          Text(
            title,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.grey[700],
              fontSize: 11,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 13,
              height: 1.3,
            ),
          ),
        ],
      ),
    );
  }

  Widget _scoreTile({
    required String title,
    required double score,
    required TextAlign textAlign,
    required CrossAxisAlignment contentAlignment,
  }) {
    final color = _scoreColor(score);

    return Container(
      width: 220,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        crossAxisAlignment: contentAlignment,
        children: [
          Text(
            title,
            textAlign: textAlign,
            style: TextStyle(
              color: Colors.grey[700],
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            score.toStringAsFixed(0),
            textAlign: textAlign,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(999),
              child: LinearProgressIndicator(
                value: score / 100,
                minHeight: 8,
                backgroundColor: Colors.grey.shade300,
                color: color,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _imageTile({
    required String title,
    required String? filePath,
    required TextAlign textAlign,
    required CrossAxisAlignment contentAlignment,
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
          crossAxisAlignment: contentAlignment,
          children: [
            Text(
              title,
              textAlign: textAlign,
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
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(color: Colors.black12, blurRadius: 8),
        ],
      ),
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
}

class ClinicalEvaluationCard extends StatelessWidget {
  final String title;
  final double? value;
  final String unit;
  final double minValue;
  final double maxValue;
  final double normalMin;
  final double normalMax;
  final String lowLabel;
  final String normalLabel;
  final String highLabel;
  final bool oneDirectional;

  const ClinicalEvaluationCard({
    super.key,
    required this.title,
    required this.value,
    required this.unit,
    required this.minValue,
    required this.maxValue,
    required this.normalMin,
    required this.normalMax,
    required this.lowLabel,
    required this.normalLabel,
    required this.highLabel,
    this.oneDirectional = false,
  });

  @override
  Widget build(BuildContext context) {
    final currentValue = value;
    final safeValue = currentValue == null
        ? null
        : currentValue!.clamp(minValue, maxValue).toDouble();

    final markerPosition = safeValue == null
        ? 0.0
        : ((safeValue - minValue) / (maxValue - minValue)).clamp(0.0, 1.0);

    final status = _statusText(currentValue);
    final statusColor = _statusColor(currentValue);

    return Container(
      width: 240,
      padding: const EdgeInsets.all(12),
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
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
              ),
              Text(
                currentValue == null
                    ? '—'
                    : '${currentValue.toStringAsFixed(2)}$unit',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.teal,
                  fontSize: 13,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          LayoutBuilder(
            builder: (context, constraints) {
              final width = constraints.maxWidth;
              final markerLeft = (width * markerPosition) - 6;

              return SizedBox(
                height: 28,
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Positioned(
                      top: 9,
                      left: 0,
                      right: 0,
                      child: Container(
                        height: 8,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(999),
                          gradient: LinearGradient(
                            colors: oneDirectional
                                ? const [
                                    Colors.green,
                                    Colors.orange,
                                    Colors.red,
                                  ]
                                : const [
                                    Colors.red,
                                    Colors.orange,
                                    Colors.green,
                                    Colors.orange,
                                    Colors.red,
                                  ],
                          ),
                        ),
                      ),
                    ),
                    if (safeValue != null)
                      Positioned(
                        top: 3,
                        left: markerLeft.clamp(0, width - 12),
                        child: Container(
                          width: 12,
                          height: 20,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(999),
                            border: Border.all(
                              color: Colors.teal,
                              width: 2,
                            ),
                            boxShadow: const [
                              BoxShadow(
                                color: Colors.black26,
                                blurRadius: 4,
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
              );
            },
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: Text(
                  lowLabel,
                  style: TextStyle(
                    fontSize: 10,
                    color: Colors.grey[600],
                  ),
                ),
              ),
              Expanded(
                child: Text(
                  normalLabel,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 10,
                    color: Colors.grey[600],
                  ),
                ),
              ),
              Expanded(
                child: Text(
                  highLabel,
                  textAlign: TextAlign.right,
                  style: TextStyle(
                    fontSize: 10,
                    color: Colors.grey[600],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.10),
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              status,
              style: TextStyle(
                color: statusColor,
                fontWeight: FontWeight.w600,
                fontSize: 11,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _statusText(double? value) {
    if (value == null) return 'Veri yok';

    if (oneDirectional) {
      if (value <= normalMax) return 'Normal';
      if (value <= (normalMax * 2)) return 'Hafif';
      if (value <= (normalMax * 3)) return 'Orta';
      return 'İleri';
    }

    if (value >= normalMin && value <= normalMax) {
      return 'Normal aralık';
    }

    if (value < normalMin) {
      return lowLabel;
    }

    return highLabel;
  }

  Color _statusColor(double? value) {
    if (value == null) return Colors.grey;

    if (oneDirectional) {
      if (value <= normalMax) return Colors.green;
      if (value <= (normalMax * 2)) return Colors.orange;
      if (value <= (normalMax * 3)) return Colors.deepOrange;
      return Colors.red;
    }

    if (value >= normalMin && value <= normalMax) return Colors.green;
    return Colors.red;
  }
}