import 'package:flutter/material.dart';
import 'package:oy_site/models/app_user.dart';
import 'package:oy_site/models/corporate_dashboard_model.dart';
import 'package:oy_site/services/corporate/corporate_employee_source_service.dart';

class CorporateDashboardScreen extends StatefulWidget {
  final AppUser currentUser;

  const CorporateDashboardScreen({super.key, required this.currentUser});

  @override
  State<CorporateDashboardScreen> createState() =>
      _CorporateDashboardScreenState();
}

class _CorporateDashboardScreenState extends State<CorporateDashboardScreen> {
  final CorporateEmployeeSourceService _employeeSource =
      const CorporateEmployeeSourceService();

  bool _isLoading = true;
  String? _errorMessage;
  List<CorporateEmployeeItem> _employees = [];

  @override
  void initState() {
    super.initState();
    _loadDashboard();
  }

  Future<void> _loadDashboard() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final employees = await _employeeSource.getEmployees(
        currentUser: widget.currentUser,
      );
      if (!mounted) return;

      setState(() {
        _employees = employees;
        _isLoading = false;
      });
    } catch (error) {
      if (!mounted) return;

      setState(() {
        _errorMessage = 'Kurumsal tarama durumu yüklenemedi.';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorMessage != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              _errorMessage!,
              style: const TextStyle(color: Color(0xFFB3261E)),
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: _loadDashboard,
              icon: const Icon(Icons.refresh),
              label: const Text('Tekrar Dene'),
            ),
          ],
        ),
      );
    }

    final summary = CorporateScanSummary.fromEmployees(_employees);
    final waitingEmployees = _employees
        .where((employee) => employee.scanStatus == CorporateScanStatus.waiting)
        .take(5)
        .toList();
    final attentionEmployees = _employees
        .where(
          (employee) =>
              employee.scanStatus == CorporateScanStatus.failed ||
              employee.scanStatus == CorporateScanStatus.needsRepeat,
        )
        .take(5)
        .toList();

    return Scaffold(
      backgroundColor: const Color(0xFFF7F9FB),
      body: RefreshIndicator(
        onRefresh: _loadDashboard,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            _Hero(summary: summary),
            const SizedBox(height: 14),
            _SummaryGrid(summary: summary),
            const SizedBox(height: 14),
            LayoutBuilder(
              builder: (context, constraints) {
                final isWide = constraints.maxWidth >= 980;
                final waiting = _EmployeePreviewCard(
                  title: 'Sıradaki Çalışanlar',
                  emptyText: 'Bekleyen çalışan yok.',
                  employees: waitingEmployees,
                );
                final attention = _EmployeePreviewCard(
                  title: 'Kontrol Gerekenler',
                  emptyText: 'Kontrol bekleyen kayıt yok.',
                  employees: attentionEmployees,
                );

                if (!isWide) {
                  return Column(
                    children: [waiting, const SizedBox(height: 14), attention],
                  );
                }

                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(child: waiting),
                    const SizedBox(width: 14),
                    Expanded(child: attention),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _Hero extends StatelessWidget {
  final CorporateScanSummary summary;

  const _Hero({required this.summary});

  @override
  Widget build(BuildContext context) {
    final percent = (summary.completionRatio * 100).round();

    return _Surface(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: const Color(0xFFE7F7F4),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.document_scanner_outlined,
                  color: Color(0xFF087F73),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Kurumsal Tarama Durumu',
                      style: TextStyle(
                        fontSize: 21,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      '${summary.completed} çalışan tamamlandı, ${summary.remaining} çalışan bekliyor.',
                      style: TextStyle(color: Colors.grey[700]),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFF087F73).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  '%$percent',
                  style: const TextStyle(
                    color: Color(0xFF087F73),
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: summary.completionRatio,
              minHeight: 10,
              color: const Color(0xFF087F73),
              backgroundColor: const Color(0xFFE5E7EB),
            ),
          ),
        ],
      ),
    );
  }
}

class _SummaryGrid extends StatelessWidget {
  final CorporateScanSummary summary;

  const _SummaryGrid({required this.summary});

  @override
  Widget build(BuildContext context) {
    final items = [
      _SummaryCard('Toplam', summary.total, Icons.groups_outlined),
      _SummaryCard('Tamamlandı', summary.completed, Icons.check_circle_outline),
      _SummaryCard('Bekliyor', summary.waiting, Icons.schedule_outlined),
      _SummaryCard(
        'Kontrol',
        summary.failed + summary.needsRepeat,
        Icons.error_outline,
      ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth >= 900
            ? (constraints.maxWidth - 30) / 4
            : (constraints.maxWidth - 10) / 2;

        return Wrap(
          spacing: 10,
          runSpacing: 10,
          children: items
              .map((item) => SizedBox(width: width, child: item))
              .toList(),
        );
      },
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final String label;
  final int value;
  final IconData icon;

  const _SummaryCard(this.label, this.value, this.icon);

  @override
  Widget build(BuildContext context) {
    return _Surface(
      child: Row(
        children: [
          Icon(icon, color: const Color(0xFF087F73)),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: TextStyle(color: Colors.grey[700])),
              const SizedBox(height: 4),
              Text(
                value.toString(),
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _EmployeePreviewCard extends StatelessWidget {
  final String title;
  final String emptyText;
  final List<CorporateEmployeeItem> employees;

  const _EmployeePreviewCard({
    required this.title,
    required this.emptyText,
    required this.employees,
  });

  @override
  Widget build(BuildContext context) {
    return _Surface(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 10),
          if (employees.isEmpty)
            Text(emptyText, style: TextStyle(color: Colors.grey[700]))
          else
            ...employees.map(
              (employee) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            employee.fullName,
                            style: const TextStyle(fontWeight: FontWeight.w700),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            '${employee.employeeCode} • ${employee.departmentName}',
                            style: TextStyle(
                              color: Colors.grey[700],
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    _StatusPill(status: employee.scanStatus),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  final CorporateScanStatus status;

  const _StatusPill({required this.status});

  @override
  Widget build(BuildContext context) {
    final color = _statusColor(status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        _statusLabel(status),
        style: TextStyle(color: color, fontWeight: FontWeight.w800),
      ),
    );
  }
}

class _Surface extends StatelessWidget {
  final Widget child;

  const _Surface({required this.child});

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Padding(padding: const EdgeInsets.all(16), child: child),
    );
  }
}

String _statusLabel(CorporateScanStatus status) {
  switch (status) {
    case CorporateScanStatus.waiting:
      return 'Bekliyor';
    case CorporateScanStatus.scanning:
      return 'Taranıyor';
    case CorporateScanStatus.completed:
      return 'Tamamlandı';
    case CorporateScanStatus.failed:
      return 'Hata';
    case CorporateScanStatus.needsRepeat:
      return 'Tekrar Gerekli';
  }
}

Color _statusColor(CorporateScanStatus status) {
  switch (status) {
    case CorporateScanStatus.completed:
      return const Color(0xFF087F73);
    case CorporateScanStatus.failed:
      return const Color(0xFFB3261E);
    case CorporateScanStatus.needsRepeat:
      return const Color(0xFFC2410C);
    case CorporateScanStatus.scanning:
      return const Color(0xFF2563EB);
    case CorporateScanStatus.waiting:
      return const Color(0xFF6B7280);
  }
}
