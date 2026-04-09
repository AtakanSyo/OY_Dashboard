class CustomerFootSummary {
  final String side; // left / right
  final String footType;
  final String pressureSummary;
  final String balanceSummary;
  final String archSupportNeed;
  final String mainFinding;
  final double pressureScore;
  final double stabilityScore;
  final double archScore;

  const CustomerFootSummary({
    required this.side,
    required this.footType,
    required this.pressureSummary,
    required this.balanceSummary,
    required this.archSupportNeed,
    required this.mainFinding,
    required this.pressureScore,
    required this.stabilityScore,
    required this.archScore,
  });
}

class CustomerAnalysisMetric {
  final String label;
  final String value;
  final String description;

  const CustomerAnalysisMetric({
    required this.label,
    required this.value,
    required this.description,
  });
}

class CustomerRecommendationItem {
  final String title;
  final String description;

  const CustomerRecommendationItem({
    required this.title,
    required this.description,
  });
}

class CustomerAnalysisResult {
  final DateTime analysisDate;
  final String overallSummary;
  final String generalRiskNote;
  final CustomerFootSummary leftFoot;
  final CustomerFootSummary rightFoot;
  final List<CustomerAnalysisMetric> metrics;
  final List<CustomerRecommendationItem> recommendations;
  final CustomerAnalysisVisualSet visuals;

  const CustomerAnalysisResult({
    required this.analysisDate,
    required this.overallSummary,
    required this.generalRiskNote,
    required this.leftFoot,
    required this.rightFoot,
    required this.metrics,
    required this.recommendations,
    required this.visuals
  });
}

class CustomerAnalysisVisualSet {
  final String sessionCode;

  final String archLeftImage;
  final String archRightImage;

  final String archSectionLeftImage;
  final String archSectionRightImage;

  final String foot2dLeftImage;
  final String foot2dRightImage;

  final String pronatorLeftImage;
  final String pronatorRightImage;

  final String leftStlFile;
  final String rightStlFile;

  const CustomerAnalysisVisualSet({
    required this.sessionCode,
    required this.archLeftImage,
    required this.archRightImage,
    required this.archSectionLeftImage,
    required this.archSectionRightImage,
    required this.foot2dLeftImage,
    required this.foot2dRightImage,
    required this.pronatorLeftImage,
    required this.pronatorRightImage,
    required this.leftStlFile,
    required this.rightStlFile,
  });
}