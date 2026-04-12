import 'dart:io';

import 'package:flutter/material.dart';
import 'package:oy_site/data/mock/mock_customer_analysis_repository.dart';
import 'package:oy_site/models/app_user.dart';
import 'package:oy_site/models/customer_analysis_result_model.dart';

class CustomerAnalysisResultsScreen extends StatefulWidget {
  final AppUser currentUser;

  const CustomerAnalysisResultsScreen({
    super.key,
    required this.currentUser,
  });

  @override
  State<CustomerAnalysisResultsScreen> createState() =>
      _CustomerAnalysisResultsScreenState();
}

class _CustomerAnalysisResultsScreenState
    extends State<CustomerAnalysisResultsScreen> {
  final MockCustomerAnalysisRepository _repository =
      MockCustomerAnalysisRepository();

  bool _isLoading = true;
  String? _errorMessage;

  List<CustomerAnalysisResult> _results = [];
  int _selectedIndex = 0;

  CustomerAnalysisResult? get _selectedResult {
    if (_results.isEmpty) return null;
    if (_selectedIndex < 0 || _selectedIndex >= _results.length) return null;
    return _results[_selectedIndex];
  }

  @override
  void initState() {
    super.initState();
    _loadAnalyses();
  }

  Future<void> _loadAnalyses() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final latest = await _repository.getLatestAnalysis(
        userId: widget.currentUser.userId!,
      );

      final older1 = CustomerAnalysisResult(
        analysisDate: DateTime(2026, 3, 18),
        sessionCode: 'SES-2026-0318',
        locationLabel: 'İzmir Klinik',
        overallSummary:
            'Önceki ölçümde sol ayakta yük dağılımı daha dengesiz görünmektedir. Yeni ölçümde genel konfor göstergelerinde iyileşme vardır.',
        generalRiskNote:
            'Uzun süre ayakta kalma durumunda destekli kullanım sürdürülmelidir.',
        leftFoot: latest.leftFoot,
        rightFoot: latest.rightFoot,
        metrics: latest.metrics,
        recommendations: latest.recommendations,
        visuals: latest.visuals,
      );

      final older2 = CustomerAnalysisResult(
        analysisDate: DateTime(2026, 2, 10),
        sessionCode: 'SES-2026-0210',
        locationLabel: 'İstanbul Merkez',
        overallSummary:
            'İlk ölçümlerde kemer desteği ihtiyacı daha belirgindir. Sonraki ölçümlerde yük dağılımında kısmi iyileşme görülmektedir.',
        generalRiskNote:
            'Destekleyici iç taban kullanımı önerilmeye devam edilmektedir.',
        leftFoot: latest.leftFoot,
        rightFoot: latest.rightFoot,
        metrics: latest.metrics,
        recommendations: latest.recommendations,
        visuals: latest.visuals,
      );

      final current = CustomerAnalysisResult(
        analysisDate: latest.analysisDate,
        sessionCode: latest.sessionCode.isEmpty
            ? 'SES-2026-0408'
            : latest.sessionCode,
        locationLabel: latest.locationLabel.isEmpty
            ? 'OptiYou İzmir'
            : latest.locationLabel,
        overallSummary: latest.overallSummary,
        generalRiskNote: latest.generalRiskNote,
        leftFoot: latest.leftFoot,
        rightFoot: latest.rightFoot,
        metrics: latest.metrics,
        recommendations: latest.recommendations,
        visuals: latest.visuals,
      );

      if (!mounted) return;

      setState(() {
        _results = [current, older1, older2];
        _selectedIndex = 0;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _errorMessage = 'Analiz sonuçları yüklenirken hata oluştu: $e';
        _isLoading = false;
      });
    }
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
    return Scaffold(
      appBar: AppBar(
        title: const Text('Analiz Sonuçlarım'),
        backgroundColor: Colors.teal,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: _buildContent(),
      ),
    );
  }

  Widget _buildContent() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorMessage != null) {
      return Center(
        child: Text(
          _errorMessage!,
          style: const TextStyle(color: Colors.red),
        ),
      );
    }

    final selected = _selectedResult;
    if (selected == null) {
      return const Center(child: Text('Analiz sonucu bulunamadı.'));
    }

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionCard(
            title: 'Ölçüm Geçmişi',
            child: _buildSessionCards(),
          ),
          const SizedBox(height: 18),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: _buildFootPanel(
                  title: 'Sol Ayak',
                  foot: selected.leftFoot,
                  isRightAligned: false,
                  visuals: _buildFootVisuals(
                    isLeft: true,
                    result: selected,
                  ),
                ),
              ),
              const SizedBox(width: 18),
              Expanded(
                child: _buildFootPanel(
                  title: 'Sağ Ayak',
                  foot: selected.rightFoot,
                  isRightAligned: true,
                  visuals: _buildFootVisuals(
                    isLeft: false,
                    result: selected,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          _buildSectionCard(
            title: 'Genel Analiz Sonuçları',
            child: _buildGeneralResultsPanel(selected),
          ),
          const SizedBox(height: 18),
          _buildSectionCard(
            title: 'Genel Durum',
            child: _buildOverviewCard(),
          ),
        ],
      ),
    );
  }

  Widget _buildSessionCards() {
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: List.generate(_results.length, (index) {
        final result = _results[index];
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

  Widget _buildFootPanel({
    required String title,
    required CustomerFootSummary foot,
    required bool isRightAligned,
    required Widget visuals,
  }) {
    final textAlign = isRightAligned ? TextAlign.right : TextAlign.left;
    final crossAlign = isRightAligned
        ? CrossAxisAlignment.end
        : CrossAxisAlignment.start;

    return _buildSectionCard(
      title: title,
      child: Column(
        crossAxisAlignment: crossAlign,
        children: [
          _infoLine(
            'Ayak Tipi',
            foot.footType,
            textAlign: textAlign,
            crossAxisAlignment: crossAlign,
          ),
          const SizedBox(height: 10),
          _infoLine(
            'Basınç Özeti',
            foot.pressureSummary,
            textAlign: textAlign,
            crossAxisAlignment: crossAlign,
          ),
          const SizedBox(height: 10),
          _infoLine(
            'Denge Özeti',
            foot.balanceSummary,
            textAlign: textAlign,
            crossAxisAlignment: crossAlign,
          ),
          const SizedBox(height: 10),
          _infoLine(
            'Kemer Desteği',
            foot.archSupportNeed,
            textAlign: textAlign,
            crossAxisAlignment: crossAlign,
          ),
          const SizedBox(height: 10),
          _infoLine(
            'Ana Bulgular',
            foot.mainFinding,
            textAlign: textAlign,
            crossAxisAlignment: crossAlign,
          ),
          const SizedBox(height: 16),
          _scoreTile(
            title: 'Basınç Konfor Skoru',
            score: foot.pressureScore,
            textAlign: textAlign,
            contentAlignment: crossAlign,
          ),
          const SizedBox(height: 10),
          _scoreTile(
            title: 'Stabilite Skoru',
            score: foot.stabilityScore,
            textAlign: textAlign,
            contentAlignment: crossAlign,
          ),
          const SizedBox(height: 10),
          _scoreTile(
            title: 'Ark Desteği Skoru',
            score: foot.archScore,
            textAlign: textAlign,
            contentAlignment: crossAlign,
          ),
          const SizedBox(height: 16),
          visuals,
        ],
      ),
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
          title: isLeft ? 'Yükseklik Haritası' : 'Yükseklik Haritası',
          filePath: isLeft
              ? visuals.archLeftImagePath
              : visuals.archRightImagePath,
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
          filePath: isLeft
              ? visuals.foot2dLeftImagePath
              : visuals.foot2dRightImagePath,
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
        _fileTile(
          title: isLeft ? 'Sol STL' : 'Sağ STL',
          path: isLeft ? visuals.leftStlPath : visuals.rightStlPath,
          textAlign: textAlign,
          contentAlignment: crossAlign,
        ),
      ],
    );
  }

  Widget _buildGeneralResultsPanel(CustomerAnalysisResult result) {
    final metrics = result.metrics;

    String metricValue(String label) {
      final match = metrics.where((m) => m.label == label);
      return match.isEmpty ? '—' : match.first.value;
    }

    return Column(
      children: [
        Wrap(
          spacing: 12,
          runSpacing: 12,
          alignment: WrapAlignment.center,
          children: [
            _centerTile(
              title: 'Session ID',
              value: result.sessionCode,
              icon: Icons.tag,
            ),
            _centerTile(
              title: 'Tarih',
              value: _formatDate(result.analysisDate),
              icon: Icons.calendar_today_outlined,
            ),
            _centerTile(
              title: 'Yer',
              value: result.locationLabel,
              icon: Icons.location_on_outlined,
            ),
            _centerTile(
              title: 'Denge',
              value: metricValue('Sol / Sağ Denge'),
              icon: Icons.balance,
            ),
            _centerTile(
              title: 'Maks. Basınç',
              value: metricValue('Maksimum Basınç Bölgesi'),
              icon: Icons.my_location_outlined,
            ),
            _centerTile(
              title: 'Risk',
              value: metricValue('Gün Sonu Yorgunluk Riski'),
              icon: Icons.warning_amber_outlined,
            ),
          ],
        ),
        const SizedBox(height: 16),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.orange.withOpacity(0.08),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.orange.withOpacity(0.2)),
          ),
          child: Column(
            children: [
              const Text(
                'Genel Özet',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                result.overallSummary,
                textAlign: TextAlign.center,
                style: const TextStyle(height: 1.4),
              ),
              const SizedBox(height: 8),
              Text(
                result.generalRiskNote,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.orange.shade900,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
        if (result.recommendations.isNotEmpty) ...[
          const SizedBox(height: 16),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            alignment: WrapAlignment.center,
            children: result.recommendations.map((item) {
              return Container(
                width: 300,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.teal.withOpacity(0.06),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.teal.withOpacity(0.18)),
                ),
                child: Column(
                  children: [
                    const Icon(
                      Icons.check_circle_outline,
                      color: Colors.teal,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      item.title,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      item.description,
                      textAlign: TextAlign.center,
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

  Widget _buildOverviewCard() {
    final latest = _results.first;

    return Column(
      children: [
        const Text(
          'Genel Durum',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Toplam ${_results.length} ölçüm kaydınız var. En güncel ölçüm ${latest.sessionCode} ve tarihi ${_formatDate(latest.analysisDate)}.',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Colors.grey[700],
            height: 1.4,
          ),
        ),
      ],
    );
  }

  Widget _infoLine(
    String label,
    String value, {
    required TextAlign textAlign,
    required CrossAxisAlignment crossAxisAlignment,
  }) {
    return Column(
      crossAxisAlignment: crossAxisAlignment,
      children: [
        Text(
          label,
          textAlign: textAlign,
          style: TextStyle(
            color: Colors.grey[700],
            fontSize: 12,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          textAlign: textAlign,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            height: 1.3,
          ),
        ),
      ],
    );
  }

  Widget _centerTile({
    required String title,
    required String value,
    required IconData icon,
  }) {
    return Container(
      width: 170,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Icon(icon, size: 18, color: Colors.teal),
          const SizedBox(height: 8),
          Text(
            title,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.grey[700],
              fontSize: 12,
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
              fontSize: 14,
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

  Widget _fileTile({
    required String title,
    required String? path,
    required TextAlign textAlign,
    required CrossAxisAlignment contentAlignment,
  }) {
    final fileName = path == null ? 'Dosya yok' : path.split('\\').last;

    return Container(
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
          const Icon(
            Icons.insert_drive_file_outlined,
            color: Colors.teal,
          ),
          const SizedBox(height: 8),
          Text(
            title,
            textAlign: textAlign,
            style: TextStyle(
              color: Colors.grey[700],
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            fileName,
            textAlign: textAlign,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 13,
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