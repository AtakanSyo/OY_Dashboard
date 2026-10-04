import 'package:flutter/material.dart';

import '../../../data/repositories/supabase_corporate_scan_project_repository.dart';
import '../../../models/corporate_dashboard_model.dart';
import '../../../models/corporate_scan_project.dart';

class CorporateScanProjectDetailScreen extends StatelessWidget {
  const CorporateScanProjectDetailScreen({super.key, required this.overview});

  final CorporateScanProjectOverview overview;
  static final CorporateScanProjectRepository _repository =
      CorporateScanProjectRepository();

  @override
  Widget build(BuildContext context) {
    final project = overview.project;
    final stats = overview.stats;

    return DefaultTabController(
      length: 4,
      child: Scaffold(
        backgroundColor: const Color(0xFFF6F8F7),
        appBar: AppBar(
          title: Text(project.displayName),
          backgroundColor: Colors.white,
          foregroundColor: const Color(0xFF111827),
          elevation: 0,
          bottom: const TabBar(
            labelColor: Color(0xFF0F766E),
            unselectedLabelColor: Color(0xFF66736F),
            tabs: [
              Tab(icon: Icon(Icons.dashboard_outlined), text: 'Genel'),
              Tab(icon: Icon(Icons.groups_outlined), text: 'Çalışanlar'),
              Tab(icon: Icon(Icons.folder_copy_outlined), text: 'Veri'),
              Tab(icon: Icon(Icons.task_alt_outlined), text: 'Operasyon'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _OverviewTab(project: project, stats: stats),
            _EmployeesTab(
              project: project,
              stats: stats,
              repository: _repository,
            ),
            _DataTab(project: project),
            _OperationsTab(project: project),
          ],
        ),
      ),
    );
  }
}

class _OverviewTab extends StatelessWidget {
  const _OverviewTab({required this.project, required this.stats});

  final CorporateScanProject project;
  final CorporateScanProjectStats stats;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 2,
              child: _Section(
                title: 'Tarama ilerlemesi',
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '%${(stats.completionRate * 100).round()}',
                      style: const TextStyle(
                        fontSize: 44,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 12),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(999),
                      child: LinearProgressIndicator(
                        value: stats.completionRate,
                        minHeight: 10,
                        backgroundColor: const Color(0xFFE8EEEB),
                        valueColor: const AlwaysStoppedAnimation(
                          Color(0xFF0F766E),
                        ),
                      ),
                    ),
                    const SizedBox(height: 18),
                    Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      children: [
                        _StatPill(
                          label: 'Çalışan',
                          value: stats.importedEmployees.toString(),
                        ),
                        _StatPill(
                          label: 'Taranan',
                          value: stats.completedScans.toString(),
                        ),
                        _StatPill(
                          label: 'Bekleyen',
                          value: stats.pendingScans.toString(),
                        ),
                        _StatPill(
                          label: 'Hatalı',
                          value: stats.failedScans.toString(),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _Section(
                title: 'Proje bilgileri',
                child: Column(
                  children: [
                    _DetailRow(label: 'Durum', value: project.statusLabel),
                    _DetailRow(
                      label: 'Lokasyon',
                      value: project.location ?? 'Girilmedi',
                    ),
                    _DetailRow(
                      label: 'Cihaz',
                      value: project.deviceId ?? 'Atanmadı',
                    ),
                    _DetailRow(
                      label: 'İlgili kişi',
                      value: project.contactName ?? 'Girilmedi',
                    ),
                    _DetailRow(
                      label: 'Telefon',
                      value: project.contactPhone ?? 'Girilmedi',
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        _Section(
          title: 'Sonraki aksiyonlar',
          child: Wrap(
            spacing: 12,
            runSpacing: 12,
            children: const [
              _ActionChip(icon: Icons.upload_file, label: 'CSV kontrolü'),
              _ActionChip(icon: Icons.sensors, label: 'Kiosk durumu'),
              _ActionChip(icon: Icons.rule_folder, label: 'Eksik sonuçlar'),
              _ActionChip(icon: Icons.summarize, label: 'Kapanış raporu'),
            ],
          ),
        ),
      ],
    );
  }
}

class _EmployeesTab extends StatelessWidget {
  const _EmployeesTab({
    required this.project,
    required this.stats,
    required this.repository,
  });

  final CorporateScanProject project;
  final CorporateScanProjectStats stats;
  final CorporateScanProjectRepository repository;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        _Section(
          title: 'Çalışan özeti',
          child: Column(
            children: [
              _DetailRow(
                label: 'CSV ile gelen çalışan',
                value: stats.importedEmployees.toString(),
              ),
              _DetailRow(
                label: 'Taraması tamamlanan',
                value: stats.completedScans.toString(),
              ),
              _DetailRow(
                label: 'Taraması bekleyen',
                value: stats.pendingScans.toString(),
              ),
              _DetailRow(
                label: 'Kontrol gereken',
                value: stats.failedScans.toString(),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        _Section(
          title: 'CSV çalışan listesi',
          child: FutureBuilder<List<CorporateEmployeeItem>>(
            future: repository.fetchProjectEmployees(project),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const SizedBox(
                  height: 180,
                  child: Center(child: CircularProgressIndicator()),
                );
              }

              if (snapshot.hasError) {
                return _InlineError(message: snapshot.error.toString());
              }

              final employees = snapshot.data ?? const [];
              if (employees.isEmpty) {
                return const _PlaceholderPanel(
                  icon: Icons.groups_outlined,
                  title: 'Çalışan bulunamadı',
                  message:
                      'Bu corporate hesap için CSV ile eklenmiş çalışan görünmüyor veya Supabase RLS erişimi henüz açılmadı.',
                );
              }

              return _EmployeeList(employees: employees);
            },
          ),
        ),
      ],
    );
  }
}

class _DataTab extends StatelessWidget {
  const _DataTab({required this.project});

  final CorporateScanProject project;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        _Section(
          title: 'Veri yönetimi',
          child: Column(
            children: [
              _DetailRow(
                label: 'Corporate profil',
                value: project.corporateProfileId?.toString() ?? 'Bağlı değil',
              ),
              _DetailRow(
                label: 'Auth kullanıcı',
                value: project.corporateUserId ?? 'Bağlı değil',
              ),
              _DetailRow(
                label: 'Hedef çalışan',
                value: project.targetEmployeeCount.toString(),
              ),
              _DetailRow(label: 'Not', value: project.notes ?? 'Not yok'),
            ],
          ),
        ),
        const SizedBox(height: 16),
        const _PlaceholderPanel(
          icon: Icons.folder_copy_outlined,
          title: 'Sonuç dosyaları bağlanacak',
          message:
              'Bu alanda üretilen STL, PDF, görsel ve ham tarama dosyaları proje bazında yönetilecek.',
        ),
      ],
    );
  }
}

class _OperationsTab extends StatelessWidget {
  const _OperationsTab({required this.project});

  final CorporateScanProject project;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        _Section(
          title: 'Operasyon checklist - ${project.statusLabel}',
          child: const Column(
            children: [
              _ChecklistRow(label: 'Firma bilgileri doğrulandı'),
              _ChecklistRow(label: 'CSV çalışan listesi alındı'),
              _ChecklistRow(label: 'Kiosk kurulumu tamamlandı'),
              _ChecklistRow(label: 'Test taraması yapıldı'),
              _ChecklistRow(label: 'Kapanış raporu hazırlandı'),
            ],
          ),
        ),
      ],
    );
  }
}

class _EmployeeList extends StatelessWidget {
  const _EmployeeList({required this.employees});

  final List<CorporateEmployeeItem> employees;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: const Color(0xFFF6F8F7),
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Row(
            children: [
              SizedBox(width: 110, child: Text('Kod')),
              Expanded(flex: 2, child: Text('Çalışan')),
              Expanded(child: Text('Departman')),
              Expanded(child: Text('Görev')),
              SizedBox(width: 130, child: Text('Durum')),
            ],
          ),
        ),
        const SizedBox(height: 8),
        ...employees.map((employee) => _EmployeeRow(employee: employee)),
      ],
    );
  }
}

class _EmployeeRow extends StatelessWidget {
  const _EmployeeRow({required this.employee});

  final CorporateEmployeeItem employee;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Color(0xFFE3E9E6))),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 110,
            child: Text(
              employee.employeeCode,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Expanded(
            flex: 2,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  employee.fullName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                Text(
                  employee.email ?? employee.phone ?? '',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF66736F),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: Text(
              employee.departmentName.isEmpty ? '-' : employee.departmentName,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Expanded(
            child: Text(
              employee.jobTitle.isEmpty ? '-' : employee.jobTitle,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          SizedBox(
            width: 130,
            child: _ScanStatusBadge(status: employee.scanStatus),
          ),
        ],
      ),
    );
  }
}

class _ScanStatusBadge extends StatelessWidget {
  const _ScanStatusBadge({required this.status});

  final CorporateScanStatus status;

  @override
  Widget build(BuildContext context) {
    final color = switch (status) {
      CorporateScanStatus.completed => const Color(0xFF0F766E),
      CorporateScanStatus.scanning => const Color(0xFF2563EB),
      CorporateScanStatus.failed => const Color(0xFFB42318),
      CorporateScanStatus.needsRepeat => const Color(0xFFB7791F),
      CorporateScanStatus.waiting => const Color(0xFF66736F),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        _scanStatusLabel(status),
        textAlign: TextAlign.center,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _InlineError extends StatelessWidget {
  const _InlineError({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF4F2),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFFECACA)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline, color: Color(0xFFB42318)),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(color: Color(0xFFB42318)),
            ),
          ),
        ],
      ),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE3E9E6)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }
}

class _StatPill extends StatelessWidget {
  const _StatPill({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 132,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF6F8F7),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w700),
          ),
          Text(label, style: const TextStyle(color: Color(0xFF66736F))),
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 150,
            child: Text(
              label,
              style: const TextStyle(color: Color(0xFF66736F)),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionChip extends StatelessWidget {
  const _ActionChip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Chip(
      avatar: Icon(icon, size: 18, color: const Color(0xFF0F766E)),
      label: Text(label),
      backgroundColor: const Color(0xFFF6F8F7),
      side: const BorderSide(color: Color(0xFFE3E9E6)),
    );
  }
}

class _ChecklistRow extends StatelessWidget {
  const _ChecklistRow({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return CheckboxListTile(
      value: false,
      onChanged: null,
      dense: true,
      contentPadding: EdgeInsets.zero,
      title: Text(label),
    );
  }
}

class _PlaceholderPanel extends StatelessWidget {
  const _PlaceholderPanel({
    required this.icon,
    required this.title,
    required this.message,
  });

  final IconData icon;
  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE3E9E6)),
      ),
      child: Row(
        children: [
          Icon(icon, size: 32, color: const Color(0xFF0F766E)),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(message, style: const TextStyle(color: Color(0xFF66736F))),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

String _scanStatusLabel(CorporateScanStatus status) {
  switch (status) {
    case CorporateScanStatus.completed:
      return 'Tamamlandı';
    case CorporateScanStatus.scanning:
      return 'Taranıyor';
    case CorporateScanStatus.failed:
      return 'Hata';
    case CorporateScanStatus.needsRepeat:
      return 'Tekrar';
    case CorporateScanStatus.waiting:
      return 'Bekliyor';
  }
}
