import 'dart:convert';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:oy_site/models/app_user.dart';
import 'package:oy_site/models/corporate_dashboard_model.dart';
import 'package:oy_site/screens/dashboard/corporate/widgets/lsf350_scan_result_panel.dart';
import 'package:oy_site/services/corporate/corporate_employee_source_service.dart';
import 'package:oy_site/services/corporate/corporate_employee_import_service.dart';
import 'package:oy_site/services/scan/lsf350_scan_output_parser.dart';
import 'package:oy_site/services/scanner/oy_scanner_automation_service.dart';

class CorporateEmployeesScreen extends StatefulWidget {
  final AppUser currentUser;

  const CorporateEmployeesScreen({super.key, required this.currentUser});

  @override
  State<CorporateEmployeesScreen> createState() =>
      _CorporateEmployeesScreenState();
}

class _CorporateEmployeesScreenState extends State<CorporateEmployeesScreen> {
  final CorporateEmployeeImportService _importService =
      const CorporateEmployeeImportService();
  final CorporateEmployeeSourceService _employeeSource =
      const CorporateEmployeeSourceService();
  final Lsf350ScanOutputParser _scanOutputParser =
      const Lsf350ScanOutputParser();
  late final OYScannerAutomationService _automationService;
  final TextEditingController _searchController = TextEditingController();

  bool _isLoading = true;
  bool _isImporting = false;
  String? _errorMessage;
  List<CorporateEmployeeItem> _employees = [];
  CorporateScanStatus? _statusFilter;

  @override
  void initState() {
    super.initState();
    _automationService = createOYScannerAutomationService();
    _searchController.addListener(() => setState(() {}));
    _load();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final items = await _employeeSource.getEmployees(
        currentUser: widget.currentUser,
      );
      if (!mounted) return;

      setState(() {
        _employees = items;
        _isLoading = false;
      });
    } catch (error) {
      if (!mounted) return;

      setState(() {
        _employees = const [];
        _errorMessage =
            'Çalışan listesi yüklenemedi. Bağlantıyı kontrol edin veya CSV içe aktararak yeni liste oluşturun.';
        _isLoading = false;
      });
    }
  }

  List<CorporateEmployeeItem> get _filteredEmployees {
    final query = _searchController.text.trim().toLowerCase();
    return _employees.where((employee) {
      final matchesStatus =
          _statusFilter == null || employee.scanStatus == _statusFilter;
      if (!matchesStatus) return false;
      if (query.isEmpty) return true;

      return employee.employeeCode.toLowerCase().contains(query) ||
          employee.fullName.toLowerCase().contains(query) ||
          employee.departmentName.toLowerCase().contains(query) ||
          employee.jobTitle.toLowerCase().contains(query) ||
          employee.shift.toLowerCase().contains(query);
    }).toList();
  }

  Future<void> _importEmployeesCsv() async {
    if (_isImporting) return;

    final result = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['csv'],
      allowMultiple: false,
      withData: true,
    );
    if (result == null || result.files.isEmpty) return;

    final file = result.files.single;
    final bytes = file.bytes;
    if (bytes == null || bytes.isEmpty) {
      _showMessage('CSV dosyası okunamadı.');
      return;
    }

    try {
      final csvText = utf8.decode(bytes, allowMalformed: true);
      final employees = _importService.parseEmployeesCsv(csvText);
      if (employees.isEmpty) {
        _showMessage('CSV içinde içe aktarılabilecek çalışan bulunamadı.');
        return;
      }

      final confirmed = await _showImportPreviewDialog(
        fileName: file.name,
        employees: employees,
      );
      if (confirmed != true) return;

      setState(() => _isImporting = true);

      final importResult = await _importService.importEmployeesAsPatients(
        currentUser: widget.currentUser,
        employees: employees,
      );

      if (!mounted) return;
      await _load();
      if (!mounted) return;
      setState(() => _isImporting = false);

      await _showImportResultDialog(importResult);
    } catch (error) {
      if (!mounted) return;
      setState(() => _isImporting = false);
      _showMessage(_friendlyImportError(error));
    }
  }

  String _friendlyImportError(Object error) {
    final raw = error.toString();
    final lower = raw.toLowerCase();
    if (lower.contains('failed host lookup') ||
        lower.contains('socketexception') ||
        lower.contains('clientexception') ||
        lower.contains('supabase.co')) {
      return 'CSV Supabase’e kaydedilemedi. İnternet veya DNS bağlantısını kontrol edip tekrar deneyin.';
    }
    return 'CSV içe aktarılamadı: $raw';
  }

  Future<void> _downloadCsvTemplate() async {
    try {
      final data = await rootBundle.load(
        'assets/templates/corporate_employees_template.csv',
      );
      final bytes = data.buffer.asUint8List(
        data.offsetInBytes,
        data.lengthInBytes,
      );
      final savedPath = await FilePicker.saveFile(
        dialogTitle: 'CSV template kaydet',
        fileName: 'corporate_employees_template.csv',
        bytes: Uint8List.fromList(bytes),
        type: FileType.custom,
        allowedExtensions: const ['csv'],
      );
      if (savedPath == null) return;
      _showMessage('CSV template kaydedildi.');
    } catch (error) {
      _showMessage('CSV template indirilemedi: $error');
    }
  }

  Future<bool?> _showImportPreviewDialog({
    required String fileName,
    required List<CorporateEmployeeItem> employees,
  }) {
    final validCount = employees
        .where(
          (employee) =>
              employee.employeeCode.trim().isNotEmpty &&
              employee.firstName.trim().isNotEmpty &&
              employee.lastName.trim().isNotEmpty,
        )
        .length;
    final invalidCount = employees.length - validCount;

    return showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('CSV İçe Aktar'),
          content: SizedBox(
            width: 560,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(fileName),
                const SizedBox(height: 12),
                Text('$validCount çalışan hasta kaydı olarak oluşturulacak.'),
                if (invalidCount > 0) ...[
                  const SizedBox(height: 6),
                  Text(
                    '$invalidCount satır eksik bilgi nedeniyle atlanacak.',
                    style: const TextStyle(color: Color(0xFFB3261E)),
                  ),
                ],
                const SizedBox(height: 12),
                ConstrainedBox(
                  constraints: const BoxConstraints(maxHeight: 220),
                  child: ListView.separated(
                    shrinkWrap: true,
                    itemCount: employees.take(6).length,
                    separatorBuilder: (_, _) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final employee = employees[index];
                      return ListTile(
                        dense: true,
                        contentPadding: EdgeInsets.zero,
                        title: Text(employee.fullName),
                        subtitle: Text(
                          '${employee.employeeCode} • ${employee.departmentName}',
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Vazgeç'),
            ),
            FilledButton.icon(
              onPressed: validCount == 0
                  ? null
                  : () => Navigator.of(context).pop(true),
              icon: const Icon(Icons.upload_file_outlined),
              label: const Text('Kaydet'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _showImportResultDialog(CorporateEmployeeImportResult result) {
    return showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('İçe Aktarma Tamamlandı'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Yeni kayıt: ${result.createdCount}'),
              Text('Zaten kayıtlı: ${result.skippedExisting}'),
              Text('Atlanan satır: ${result.invalidRows}'),
            ],
          ),
          actions: [
            FilledButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Tamam'),
            ),
          ],
        );
      },
    );
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _showScanResult(CorporateEmployeeItem employee) async {
    final outputPath = employee.localScanOutputPath?.trim();
    if (outputPath == null || outputPath.isEmpty) {
      _showMessage('Bu çalışan için kayıtlı tarama klasörü bulunamadı.');
      return;
    }

    final result = _scanOutputParser.parseFolder(outputPath);
    if (!mounted) return;

    await showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('${employee.fullName} Tarama Sonucu'),
          content: SizedBox(
            width: 820,
            height: 640,
            child: Lsf350ScanResultPanel(
              result: result,
              onOpenPath: _automationService.openGeneratedFile,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Kapat'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    final summary = CorporateScanSummary.fromEmployees(_employees);
    final filteredEmployees = _filteredEmployees;

    return Scaffold(
      backgroundColor: const Color(0xFFF7F9FB),
      body: RefreshIndicator(
        onRefresh: _load,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            _Header(summary: summary),
            const SizedBox(height: 14),
            if (_errorMessage != null) ...[
              _Notice(message: _errorMessage!, onRetry: _load),
              const SizedBox(height: 14),
            ],
            _SummaryGrid(summary: summary),
            const SizedBox(height: 14),
            _FilterBar(
              controller: _searchController,
              selectedStatus: _statusFilter,
              isImporting: _isImporting,
              onImport: _importEmployeesCsv,
              onDownloadTemplate: _downloadCsvTemplate,
              onStatusChanged: (status) {
                setState(() => _statusFilter = status);
              },
            ),
            const SizedBox(height: 14),
            _EmployeeList(
              employees: filteredEmployees,
              onOpenResult: _showScanResult,
              onResetFilters: () {
                setState(() {
                  _searchController.clear();
                  _statusFilter = null;
                });
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  final CorporateScanSummary summary;

  const _Header({required this.summary});

  @override
  Widget build(BuildContext context) {
    final percent = (summary.completionRatio * 100).round();

    return _Surface(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: const Color(0xFFE7F7F4),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.groups_outlined,
                  color: Color(0xFF087F73),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Kurumsal Tarama Listesi',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${summary.completed}/${summary.total} çalışan tamamlandı',
                      style: TextStyle(color: Colors.grey[700]),
                    ),
                  ],
                ),
              ),
              _ProgressBadge(percent: percent),
            ],
          ),
          const SizedBox(height: 14),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: summary.completionRatio,
              minHeight: 9,
              color: const Color(0xFF087F73),
              backgroundColor: const Color(0xFFE5E7EB),
            ),
          ),
        ],
      ),
    );
  }
}

class _ProgressBadge extends StatelessWidget {
  final int percent;

  const _ProgressBadge({required this.percent});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
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
    );
  }
}

class _SummaryGrid extends StatelessWidget {
  final CorporateScanSummary summary;

  const _SummaryGrid({required this.summary});

  @override
  Widget build(BuildContext context) {
    final items = [
      _SummaryItem(
        label: 'Toplam',
        value: summary.total.toString(),
        icon: Icons.badge_outlined,
        color: const Color(0xFF374151),
      ),
      _SummaryItem(
        label: 'Tamamlandı',
        value: summary.completed.toString(),
        icon: Icons.check_circle_outline,
        color: const Color(0xFF087F73),
      ),
      _SummaryItem(
        label: 'Bekliyor',
        value: summary.waiting.toString(),
        icon: Icons.schedule_outlined,
        color: const Color(0xFF7C3AED),
      ),
      _SummaryItem(
        label: 'Kontrol',
        value: (summary.failed + summary.needsRepeat).toString(),
        icon: Icons.error_outline,
        color: const Color(0xFFB3261E),
      ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth >= 900;
        final width = isWide
            ? (constraints.maxWidth - 30) / 4
            : (constraints.maxWidth - 10) / 2;

        return Wrap(
          spacing: 10,
          runSpacing: 10,
          children: items.map((item) {
            return SizedBox(width: width, child: item);
          }).toList(),
        );
      },
    );
  }
}

class _SummaryItem extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _SummaryItem({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return _Surface(
      child: Row(
        children: [
          Icon(icon, color: color),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: TextStyle(color: Colors.grey[700])),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: TextStyle(
                    color: color,
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _FilterBar extends StatelessWidget {
  final TextEditingController controller;
  final CorporateScanStatus? selectedStatus;
  final bool isImporting;
  final VoidCallback onImport;
  final VoidCallback onDownloadTemplate;
  final ValueChanged<CorporateScanStatus?> onStatusChanged;

  const _FilterBar({
    required this.controller,
    required this.selectedStatus,
    required this.isImporting,
    required this.onImport,
    required this.onDownloadTemplate,
    required this.onStatusChanged,
  });

  @override
  Widget build(BuildContext context) {
    return _Surface(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: controller,
                  decoration: InputDecoration(
                    hintText: 'Ad, çalışan kodu, departman veya vardiya ara',
                    prefixIcon: const Icon(Icons.search),
                    isDense: true,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              OutlinedButton.icon(
                onPressed: isImporting ? null : onImport,
                icon: isImporting
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.upload_file_outlined),
                label: Text(isImporting ? 'Aktarılıyor' : 'CSV İçe Aktar'),
              ),
              const SizedBox(width: 8),
              IconButton(
                tooltip: 'CSV template indir',
                onPressed: isImporting ? null : onDownloadTemplate,
                icon: const Icon(Icons.download_outlined),
              ),
              const SizedBox(width: 4),
              IconButton(
                tooltip: 'CSV formatı',
                onPressed: () => _showCsvFormatDialog(context),
                icon: const Icon(Icons.help_outline),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _StatusFilterChip(
                label: 'Tümü',
                selected: selectedStatus == null,
                onSelected: () => onStatusChanged(null),
              ),
              for (final status in CorporateScanStatus.values)
                _StatusFilterChip(
                  label: _statusLabel(status),
                  selected: selectedStatus == status,
                  onSelected: () => onStatusChanged(status),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Notice extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _Notice({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return _Surface(
      child: Row(
        children: [
          const Icon(Icons.info_outline, color: Color(0xFFB3261E)),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(color: Color(0xFFB3261E)),
            ),
          ),
          const SizedBox(width: 10),
          OutlinedButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh),
            label: const Text('Tekrar Dene'),
          ),
        ],
      ),
    );
  }
}

class _StatusFilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onSelected;

  const _StatusFilterChip({
    required this.label,
    required this.selected,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => onSelected(),
      selectedColor: const Color(0xFFE7F7F4),
      labelStyle: TextStyle(
        color: selected ? const Color(0xFF087F73) : const Color(0xFF374151),
        fontWeight: selected ? FontWeight.w800 : FontWeight.w500,
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
    );
  }
}

class _EmployeeList extends StatelessWidget {
  final List<CorporateEmployeeItem> employees;
  final ValueChanged<CorporateEmployeeItem> onOpenResult;
  final VoidCallback onResetFilters;

  const _EmployeeList({
    required this.employees,
    required this.onOpenResult,
    required this.onResetFilters,
  });

  @override
  Widget build(BuildContext context) {
    return _Surface(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Çalışanlar',
                  style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
                ),
              ),
              Text(
                '${employees.length} kayıt',
                style: TextStyle(color: Colors.grey[700]),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (employees.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 28),
                child: Column(
                  children: [
                    const Icon(Icons.search_off_outlined, size: 34),
                    const SizedBox(height: 8),
                    const Text('Eşleşen çalışan bulunamadı.'),
                    const SizedBox(height: 10),
                    OutlinedButton(
                      onPressed: onResetFilters,
                      child: const Text('Filtreleri Temizle'),
                    ),
                  ],
                ),
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: employees.length,
              separatorBuilder: (_, _) => const Divider(height: 1),
              itemBuilder: (context, index) {
                return _EmployeeRow(
                  employee: employees[index],
                  onOpenResult: onOpenResult,
                );
              },
            ),
        ],
      ),
    );
  }
}

class _EmployeeRow extends StatelessWidget {
  final CorporateEmployeeItem employee;
  final ValueChanged<CorporateEmployeeItem> onOpenResult;

  const _EmployeeRow({required this.employee, required this.onOpenResult});

  @override
  Widget build(BuildContext context) {
    final statusColor = _statusColor(employee.scanStatus);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          SizedBox(
            width: 104,
            child: Text(
              employee.employeeCode,
              style: const TextStyle(fontWeight: FontWeight.w800),
            ),
          ),
          Expanded(
            flex: 2,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  employee.fullName,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 3),
                Text(
                  employee.email ?? employee.phone ?? 'İletişim yok',
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: Colors.grey[700], fontSize: 12),
                ),
              ],
            ),
          ),
          Expanded(child: Text(employee.departmentName)),
          Expanded(child: Text(employee.jobTitle)),
          SizedBox(width: 80, child: Text(employee.shift)),
          SizedBox(
            width: 132,
            child: _StatusPill(
              label: _statusLabel(employee.scanStatus),
              color: statusColor,
            ),
          ),
          SizedBox(width: 112, child: Text(_formatDate(employee.lastScanAt))),
          SizedBox(
            width: 106,
            child: employee.localScanOutputPath == null
                ? Text(
                    employee.scanStatus == CorporateScanStatus.completed
                        ? 'Klasör yok'
                        : '-',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey[600], fontSize: 12),
                  )
                : OutlinedButton.icon(
                    onPressed: () => onOpenResult(employee),
                    icon: const Icon(Icons.folder_open_outlined, size: 17),
                    label: const Text('Sonuç'),
                  ),
          ),
          SizedBox(
            width: 82,
            child: Tooltip(
              message: employee.hasPersonalAccount
                  ? 'Bireysel hesap var'
                  : 'Bireysel hesap yok',
              child: Icon(
                employee.hasPersonalAccount
                    ? Icons.verified_user_outlined
                    : Icons.person_add_alt_1_outlined,
                color: employee.hasPersonalAccount
                    ? const Color(0xFF087F73)
                    : Colors.grey[500],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  final String label;
  final Color color;

  const _StatusPill({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        textAlign: TextAlign.center,
        overflow: TextOverflow.ellipsis,
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

void _showCsvFormatDialog(BuildContext context) {
  const columns = [
    'employee_code',
    'first_name',
    'last_name',
    'department',
    'job_title',
    'shift',
    'phone',
    'email',
    'gender',
    'birth_date',
    'shoe_size',
  ];

  showDialog<void>(
    context: context,
    builder: (context) {
      return AlertDialog(
        title: const Text('CSV Formatı'),
        content: SizedBox(
          width: 520,
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            children: columns.map((column) {
              return Chip(label: Text(column));
            }).toList(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Kapat'),
          ),
        ],
      );
    },
  );
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

String _formatDate(DateTime? date) {
  if (date == null) return '-';
  return '${date.day.toString().padLeft(2, '0')}.'
      '${date.month.toString().padLeft(2, '0')}.'
      '${date.year}';
}
