import 'dart:async';

import 'package:oy_site/models/corporate_dashboard_model.dart';

class MockCorporateRepository {
  Future<CorporateDashboardModel> getDashboardData() async {
    await Future.delayed(const Duration(milliseconds: 300));

    return const CorporateDashboardModel(
      kpis: [
        CorporateKpiItem(
          title: 'Toplam Çalışan',
          value: '1.240',
          subtitle: 'Analiz sistemine kayıtlı çalışan',
        ),
        CorporateKpiItem(
          title: 'Analiz Yapılan',
          value: '864',
          subtitle: 'Son 12 ay içinde ölçüm yapılan kişi',
        ),
        CorporateKpiItem(
          title: 'Yüksek Risk',
          value: '172',
          subtitle: 'Yakın takip önerilen çalışan',
        ),
        CorporateKpiItem(
          title: 'Son Dönem İyileşme',
          value: '%14',
          subtitle: 'Önceki periyoda göre genel iyileşme',
        ),
      ],
      riskDistribution: [
        CorporateRiskDistributionItem(label: 'Düşük Risk', count: 412),
        CorporateRiskDistributionItem(label: 'Orta Risk', count: 280),
        CorporateRiskDistributionItem(label: 'Yüksek Risk', count: 172),
      ],
      topIssues: [
        CorporateIssueItem(
          title: 'Düz taban eğilimi',
          percentage: '%31',
          description: 'Çalışan grubunda en sık görülen temel bulgu.',
        ),
        CorporateIssueItem(
          title: 'Metatarsal basınç artışı',
          percentage: '%24',
          description: 'Uzun süre ayakta çalışan gruplarda öne çıkıyor.',
        ),
        CorporateIssueItem(
          title: 'Pronasyon artışı',
          percentage: '%18',
          description: 'Bazı operasyonel görevlerde daha yüksek gözleniyor.',
        ),
      ],
      alerts: [
        CorporateAlertItem(
          title: 'Montaj hattında risk artışı',
          description:
              'Montaj bölümünde çalışanlarda ön ayak basınç yüklenmesi son dönemde artış göstermiştir.',
        ),
        CorporateAlertItem(
          title: 'Gece vardiyasında stabilite düşüşü',
          description:
              'Gece vardiyasında görev yapan çalışanlarda stabilite skorlarında düşüş gözlemlendi.',
        ),
      ],
      departmentInsights: [
        CorporateDepartmentInsightItem(
          departmentName: 'Montaj',
          keyFinding: 'Ön ayak ve topuk basıncı yüksek',
          riskLevel: 'Yüksek',
        ),
        CorporateDepartmentInsightItem(
          departmentName: 'Lojistik',
          keyFinding: 'Uzun süreli yüklenmeye bağlı konfor kaybı',
          riskLevel: 'Orta',
        ),
        CorporateDepartmentInsightItem(
          departmentName: 'Kalite Kontrol',
          keyFinding: 'Genel risk düşük, stabilite daha iyi',
          riskLevel: 'Düşük',
        ),
      ],
    );
  }

  Future<List<CorporateDepartmentItem>> getDepartmentItems() async {
    await Future.delayed(const Duration(milliseconds: 250));

    return const [
      CorporateDepartmentItem(
        departmentName: 'Montaj',
        employeeCount: 240,
        avgRiskScore: 78,
        topIssue: 'Ön ayak basıncı',
        trendLabel: 'Artış',
      ),
      CorporateDepartmentItem(
        departmentName: 'Lojistik',
        employeeCount: 130,
        avgRiskScore: 66,
        topIssue: 'Topuk yüklenmesi',
        trendLabel: 'Sabit',
      ),
      CorporateDepartmentItem(
        departmentName: 'Kalite Kontrol',
        employeeCount: 96,
        avgRiskScore: 41,
        topIssue: 'Düşük risk',
        trendLabel: 'İyileşme',
      ),
      CorporateDepartmentItem(
        departmentName: 'Paketleme',
        employeeCount: 180,
        avgRiskScore: 59,
        topIssue: 'Metatarsal basınç',
        trendLabel: 'Artış',
      ),
    ];
  }

  Future<Map<String, List<CorporateTrendPoint>>> getTrendData() async {
    await Future.delayed(const Duration(milliseconds: 250));

    return const {
      'risk': [
        CorporateTrendPoint(label: 'Oca', value: 68),
        CorporateTrendPoint(label: 'Şub', value: 66),
        CorporateTrendPoint(label: 'Mar', value: 65),
        CorporateTrendPoint(label: 'Nis', value: 63),
        CorporateTrendPoint(label: 'May', value: 61),
      ],
      'pronation': [
        CorporateTrendPoint(label: 'Oca', value: 22),
        CorporateTrendPoint(label: 'Şub', value: 21),
        CorporateTrendPoint(label: 'Mar', value: 20),
        CorporateTrendPoint(label: 'Nis', value: 19),
        CorporateTrendPoint(label: 'May', value: 18),
      ],
      'pressure': [
        CorporateTrendPoint(label: 'Oca', value: 74),
        CorporateTrendPoint(label: 'Şub', value: 72),
        CorporateTrendPoint(label: 'Mar', value: 71),
        CorporateTrendPoint(label: 'Nis', value: 69),
        CorporateTrendPoint(label: 'May', value: 67),
      ],
    };
  }

  Future<List<CorporateEmployeeItem>> getEmployees() async {
    await Future.delayed(const Duration(milliseconds: 250));

    return const [
      CorporateEmployeeItem(
        employeeCode: 'EMP-001',
        fullName: 'Ahmet Yılmaz',
        departmentName: 'Montaj',
        taskGroup: 'Hat Operatörü',
        riskLevel: 'Yüksek',
        lastAnalysisDate: '12.04.2026',
      ),
      CorporateEmployeeItem(
        employeeCode: 'EMP-002',
        fullName: 'Ayşe Demir',
        departmentName: 'Lojistik',
        taskGroup: 'Taşıma Operasyonu',
        riskLevel: 'Orta',
        lastAnalysisDate: '10.04.2026',
      ),
      CorporateEmployeeItem(
        employeeCode: 'EMP-003',
        fullName: 'Mehmet Kaya',
        departmentName: 'Kalite Kontrol',
        taskGroup: 'Kontrol Uzmanı',
        riskLevel: 'Düşük',
        lastAnalysisDate: '08.04.2026',
      ),
      CorporateEmployeeItem(
        employeeCode: 'EMP-004',
        fullName: 'Zeynep Arslan',
        departmentName: 'Paketleme',
        taskGroup: 'Paketleme Uzmanı',
        riskLevel: 'Orta',
        lastAnalysisDate: '09.04.2026',
      ),
    ];
  }

  Future<List<CorporateReportItem>> getReports() async {
    await Future.delayed(const Duration(milliseconds: 250));

    return const [
      CorporateReportItem(
        title: 'Nisan 2026 Kurumsal Ayak Sağlığı Raporu',
        description:
            'Genel risk dağılımı, departman kırılımı ve önerilen aksiyonlar.',
        date: '15.04.2026',
        status: 'Hazır',
      ),
      CorporateReportItem(
        title: 'Montaj Bölümü Karşılaştırmalı Analiz',
        description:
            'Son 3 periyottaki eğilimlerin ve operasyon etkilerinin özeti.',
        date: '11.04.2026',
        status: 'Hazır',
      ),
      CorporateReportItem(
        title: 'Mayıs 2026 Planlı Tarama Özeti',
        description:
            'Yaklaşan taramalar ve hedef çalışan grupları.',
        date: '18.04.2026',
        status: 'Taslak',
      ),
    ];
  }
}