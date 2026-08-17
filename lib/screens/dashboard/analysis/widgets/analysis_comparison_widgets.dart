import 'package:flutter/material.dart';
import 'package:oy_site/l10n/app_localizations.dart';

class AnalysisComparisonValue {
  final String label;
  final String leftValue;
  final String rightValue;
  final String? description;
  final IconData icon;

  const AnalysisComparisonValue({
    required this.label,
    required this.leftValue,
    required this.rightValue,
    required this.icon,
    this.description,
  });
}

class AnalysisComparisonTable extends StatelessWidget {
  final List<AnalysisComparisonValue> values;

  const AnalysisComparisonTable({super.key, required this.values});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ...values.map(
          (value) => Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: _ComparisonValueRow(value: value),
          ),
        ),
      ],
    );
  }
}

class _ComparisonValueRow extends StatelessWidget {
  final AnalysisComparisonValue value;

  const _ComparisonValueRow({required this.value});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 680) {
          return _buildNarrow(context);
        }
        return _buildWide();
      },
    );
  }

  Widget _buildWide() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Row(
        children: [
          Expanded(
            child: _ValueBox(
              value: value.leftValue,
              alignment: CrossAxisAlignment.start,
              color: Colors.teal,
            ),
          ),
          SizedBox(width: 220, child: _MetricIdentity(value: value)),
          Expanded(
            child: _ValueBox(
              value: value.rightValue,
              alignment: CrossAxisAlignment.end,
              color: Colors.indigo,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNarrow(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Row(
        children: [
          Expanded(child: _MetricIdentity(value: value, compact: true)),
          const SizedBox(width: 10),
          SizedBox(
            width: 82,
            child: _LabeledValue(
              label: l10n.left,
              value: value.leftValue,
              color: Colors.teal,
              compact: true,
            ),
          ),
          const SizedBox(width: 7),
          SizedBox(
            width: 82,
            child: _LabeledValue(
              label: l10n.right,
              value: value.rightValue,
              color: Colors.indigo,
              compact: true,
            ),
          ),
        ],
      ),
    );
  }
}

class _MetricIdentity extends StatelessWidget {
  final AnalysisComparisonValue value;
  final bool compact;

  const _MetricIdentity({required this.value, this.compact = false});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(value.icon, color: Colors.blueGrey, size: compact ? 17 : 20),
        SizedBox(height: compact ? 3 : 5),
        Text(
          value.label,
          textAlign: compact ? TextAlign.left : TextAlign.center,
          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
        ),
        if (value.description != null) ...[
          const SizedBox(height: 3),
          Text(
            value.description!,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.grey.shade600,
              fontSize: compact ? 9 : 10,
              height: 1.25,
            ),
          ),
        ],
      ],
    );
  }
}

class _ValueBox extends StatelessWidget {
  final String value;
  final CrossAxisAlignment alignment;
  final Color color;

  const _ValueBox({
    required this.value,
    required this.alignment,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: alignment,
      children: [
        Text(
          value,
          textAlign: alignment == CrossAxisAlignment.end
              ? TextAlign.right
              : TextAlign.left,
          style: TextStyle(
            color: value == '—' ? Colors.grey.shade600 : color,
            fontWeight: FontWeight.w800,
            fontSize: 20,
          ),
        ),
      ],
    );
  }
}

class _LabeledValue extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  final bool compact;

  const _LabeledValue({
    required this.label,
    required this.value,
    required this.color,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(compact ? 7 : 11),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        children: [
          Text(label, style: TextStyle(color: color, fontSize: 11)),
          SizedBox(height: compact ? 2 : 4),
          Text(
            value,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: value == '—' ? Colors.grey.shade600 : color,
              fontWeight: FontWeight.w800,
              fontSize: compact ? 13 : 17,
            ),
          ),
        ],
      ),
    );
  }
}

class AnalysisFindingComparisonData {
  final String title;
  final String subtitle;
  final IconData icon;
  final String leftDescription;
  final String rightDescription;
  final List<AnalysisComparisonValue> metrics;
  final List<AnalysisFindingImage> images;
  final List<AnalysisAssessmentData> assessments;

  const AnalysisFindingComparisonData({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.leftDescription,
    required this.rightDescription,
    required this.metrics,
    required this.images,
    this.assessments = const [],
  });
}

class AnalysisAssessmentData {
  final String title;
  final String leftLabel;
  final String rightLabel;
  final double? leftPosition;
  final double? rightPosition;

  const AnalysisAssessmentData({
    required this.title,
    required this.leftLabel,
    required this.rightLabel,
    required this.leftPosition,
    required this.rightPosition,
  });
}

class AnalysisFindingImage {
  final String title;
  final String? leftUrl;
  final String? rightUrl;
  final List<AnalysisAssessmentData> assessments;

  const AnalysisFindingImage({
    required this.title,
    this.leftUrl,
    this.rightUrl,
    this.assessments = const [],
  });
}

class AnalysisFindingComparisonPanel extends StatelessWidget {
  final AnalysisFindingComparisonData data;
  final Widget Function(String? url, String title) imageBuilder;

  const AnalysisFindingComparisonPanel({
    super.key,
    required this.data,
    required this.imageBuilder,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: Colors.teal.withValues(alpha: 0.09),
                  borderRadius: BorderRadius.circular(11),
                ),
                child: Icon(data.icon, color: Colors.teal, size: 21),
              ),
              const SizedBox(width: 11),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      data.title,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 17,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      data.subtitle,
                      style: TextStyle(
                        color: Colors.grey.shade700,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _visualResults(context),
        ],
      ),
    );
  }

  Widget _visualResults(BuildContext context) {
    return Column(
      children: [
        _images(context),
        if (data.assessments.isNotEmpty) ...[
          const SizedBox(height: 10),
          ...data.assessments.map(
            (assessment) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: _AssessmentHeatBar(data: assessment),
            ),
          ),
        ],
        if (data.metrics.isNotEmpty) ...[
          const SizedBox(height: 2),
          AnalysisComparisonTable(values: data.metrics),
        ],
      ],
    );
  }

  Widget _images(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    if (data.images.isEmpty) {
      return Container(
        height: 150,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: Colors.grey.shade50,
          borderRadius: BorderRadius.circular(13),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: Text(
          l10n.imageNotFound,
          style: TextStyle(color: Colors.grey.shade600),
        ),
      );
    }

    return Column(
      children: data.images
          .map(
            (image) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Column(
                children: [
                  Text(
                    image.title,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 7),
                  Row(
                    children: [
                      Expanded(
                        child: imageBuilder(
                          image.leftUrl,
                          '${image.title} - ${l10n.leftFoot}',
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: imageBuilder(
                          image.rightUrl,
                          '${image.title} - ${l10n.rightFoot}',
                        ),
                      ),
                    ],
                  ),
                  if (image.assessments.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    ...image.assessments.map(
                      (assessment) => Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: _AssessmentHeatBar(data: assessment),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          )
          .toList(),
    );
  }
}

class _AssessmentHeatBar extends StatelessWidget {
  final AnalysisAssessmentData data;

  const _AssessmentHeatBar({required this.data});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Container(
      padding: const EdgeInsets.all(11),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(11),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            data.title,
            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12),
          ),
          const SizedBox(height: 9),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: _HeatBarSide(
                  side: l10n.left,
                  label: data.leftLabel,
                  position: data.leftPosition,
                  color: Colors.teal,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _HeatBarSide(
                  side: l10n.right,
                  label: data.rightLabel,
                  position: data.rightPosition,
                  color: Colors.indigo,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _HeatBarSide extends StatelessWidget {
  final String side;
  final String label;
  final double? position;
  final Color color;

  const _HeatBarSide({
    required this.side,
    required this.label,
    required this.position,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final normalized = position?.clamp(0.0, 1.0);
    return Column(
      children: [
        Row(
          children: [
            Text(
              side,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.w700,
                fontSize: 10,
              ),
            ),
            const SizedBox(width: 7),
            Expanded(
              child: Text(
                label,
                textAlign: TextAlign.right,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 10,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 5),
        SizedBox(
          height: 13,
          child: LayoutBuilder(
            builder: (context, constraints) {
              return Stack(
                clipBehavior: Clip.none,
                children: [
                  Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      gradient: const LinearGradient(
                        colors: [
                          Color(0xFFD32F2F),
                          Color(0xFFFFC107),
                          Color(0xFF43A047),
                          Color(0xFFFFC107),
                          Color(0xFFD32F2F),
                        ],
                        stops: [0, 0.25, 0.5, 0.75, 1],
                      ),
                    ),
                  ),
                  if (normalized != null)
                    Positioned(
                      left: normalized * (constraints.maxWidth - 10),
                      top: -3,
                      child: Container(
                        width: 10,
                        height: 19,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          border: Border.all(color: color, width: 3),
                          boxShadow: const [
                            BoxShadow(color: Colors.black26, blurRadius: 2),
                          ],
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
        ),
      ],
    );
  }
}
