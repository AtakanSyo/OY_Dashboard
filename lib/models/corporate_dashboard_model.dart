class CorporateKpiItem {
  final String title;
  final String value;
  final String subtitle;

  const CorporateKpiItem({
    required this.title,
    required this.value,
    required this.subtitle,
  });
}

class CorporateRiskDistributionItem {
  final String label;
  final int count;

  const CorporateRiskDistributionItem({
    required this.label,
    required this.count,
  });
}

class CorporateIssueItem {
  final String title;
  final String percentage;
  final String description;

  const CorporateIssueItem({
    required this.title,
    required this.percentage,
    required this.description,
  });
}

class CorporateAlertItem {
  final String title;
  final String description;

  const CorporateAlertItem({
    required this.title,
    required this.description,
  });
}

class CorporateDepartmentInsightItem {
  final String departmentName;
  final String keyFinding;
  final String riskLevel;

  const CorporateDepartmentInsightItem({
    required this.departmentName,
    required this.keyFinding,
    required this.riskLevel,
  });
}

class CorporateDepartmentItem {
  final String departmentName;
  final int employeeCount;
  final double avgRiskScore;
  final String topIssue;
  final String trendLabel;

  const CorporateDepartmentItem({
    required this.departmentName,
    required this.employeeCount,
    required this.avgRiskScore,
    required this.topIssue,
    required this.trendLabel,
  });
}

class CorporateTrendPoint {
  final String label;
  final double value;

  const CorporateTrendPoint({
    required this.label,
    required this.value,
  });
}

class CorporateEmployeeItem {
  final String employeeCode;
  final String fullName;
  final String departmentName;
  final String taskGroup;
  final String riskLevel;
  final String lastAnalysisDate;

  const CorporateEmployeeItem({
    required this.employeeCode,
    required this.fullName,
    required this.departmentName,
    required this.taskGroup,
    required this.riskLevel,
    required this.lastAnalysisDate,
  });
}

class CorporateReportItem {
  final String title;
  final String description;
  final String date;
  final String status;

  const CorporateReportItem({
    required this.title,
    required this.description,
    required this.date,
    required this.status,
  });
}

class CorporateDashboardModel {
  final List<CorporateKpiItem> kpis;
  final List<CorporateRiskDistributionItem> riskDistribution;
  final List<CorporateIssueItem> topIssues;
  final List<CorporateAlertItem> alerts;
  final List<CorporateDepartmentInsightItem> departmentInsights;

  const CorporateDashboardModel({
    required this.kpis,
    required this.riskDistribution,
    required this.topIssues,
    required this.alerts,
    required this.departmentInsights,
  });
}