import 'package:supabase_flutter/supabase_flutter.dart';

import '../../models/corporate_dashboard_model.dart';
import '../../models/corporate_scan_project.dart';

class CorporateScanProjectRepository {
  CorporateScanProjectRepository({SupabaseClient? client})
    : _client = client ?? Supabase.instance.client;

  final SupabaseClient _client;

  Future<List<CorporateScanProjectOverview>> fetchProjectOverviews() async {
    try {
      final rows = await _client
          .from('corporate_scan_projects')
          .select()
          .order('created_at', ascending: false);

      final projects = (rows as List<dynamic>)
          .whereType<Map<String, dynamic>>()
          .map(CorporateScanProject.fromMap)
          .toList();

      final overviews = <CorporateScanProjectOverview>[];
      for (final project in projects) {
        overviews.add(
          CorporateScanProjectOverview(
            project: project,
            stats: await _fetchStats(project),
          ),
        );
      }

      return overviews;
    } on PostgrestException catch (error) {
      if (_isMissingTable(error)) {
        throw const CorporateScanProjectRepositoryException(
          'Kurumsal tarama proje tablosu bulunamadı. Supabase migration dosyasını çalıştırın.',
        );
      }
      throw CorporateScanProjectRepositoryException(error.message);
    } catch (error) {
      throw CorporateScanProjectRepositoryException(error.toString());
    }
  }

  Future<CorporateScanProjectStats> fetchProjectStats(
    CorporateScanProject project,
  ) {
    return _fetchStats(project);
  }

  Future<CorporateScanProjectStats> _fetchStats(
    CorporateScanProject project,
  ) async {
    final importedEmployees = await _fetchImportedEmployeeCount(project);
    final sessions = await _fetchSessions(project);

    var completed = 0;
    var failed = 0;
    DateTime? lastScanAt;

    for (final row in sessions) {
      final status = (row['status'] ?? row['result_status'] ?? '')
          .toString()
          .toLowerCase();
      if (status.contains('fail') ||
          status.contains('error') ||
          status.contains('hata')) {
        failed += 1;
      } else if (status.contains('complete') ||
          status.contains('done') ||
          status.contains('success') ||
          status.contains('tamam')) {
        completed += 1;
      } else if (row['completed_at'] != null || row['exported_at'] != null) {
        completed += 1;
      }

      final candidate = DateTime.tryParse(
        (row['completed_at'] ??
                row['exported_at'] ??
                row['created_at'] ??
                row['updated_at'] ??
                '')
            .toString(),
      );
      if (candidate != null &&
          (lastScanAt == null || candidate.isAfter(lastScanAt))) {
        lastScanAt = candidate;
      }
    }

    final pending = importedEmployees > completed
        ? importedEmployees - completed
        : 0;

    return CorporateScanProjectStats(
      importedEmployees: importedEmployees,
      completedScans: completed,
      failedScans: failed,
      pendingScans: pending,
      lastScanAt: lastScanAt,
    );
  }

  Future<int> _fetchImportedEmployeeCount(CorporateScanProject project) async {
    final profileId = project.corporateProfileId;

    if (profileId == null) {
      return project.targetEmployeeCount;
    }

    try {
      final rows = await _client
          .from('patients')
          .select('id')
          .eq('created_by_user_id', profileId);
      final count = (rows as List<dynamic>).length;
      if (count > 0) return count;
    } catch (_) {
      // Employee import stats are a convenience metric. Keep the project list
      // usable even if the legacy patients query changes.
    }

    return project.targetEmployeeCount;
  }

  Future<List<CorporateEmployeeItem>> fetchProjectEmployees(
    CorporateScanProject project,
  ) async {
    final profileId = project.corporateProfileId;
    if (profileId == null) return const [];

    try {
      final patientRows = await _client
          .from('patients')
          .select()
          .eq('created_by_user_id', profileId)
          .order('created_at', ascending: false);

      final employees = (patientRows as List<dynamic>)
          .whereType<Map<String, dynamic>>()
          .map(_patientRowToEmployee)
          .toList();

      final sessions = await _fetchSessions(project);
      return _mergeScanSessions(employees, sessions);
    } on PostgrestException catch (error) {
      throw CorporateScanProjectRepositoryException(error.message);
    } catch (error) {
      throw CorporateScanProjectRepositoryException(error.toString());
    }
  }

  Future<List<Map<String, dynamic>>> _fetchSessions(
    CorporateScanProject project,
  ) async {
    final byId = <String, Map<String, dynamic>>{};

    try {
      final rows = await _client
          .from('corporate_scan_sessions')
          .select()
          .eq('project_id', project.id)
          .order('created_at', ascending: false);
      for (final row
          in (rows as List<dynamic>).whereType<Map<String, dynamic>>()) {
        byId[_sessionKey(row)] = row;
      }
    } on PostgrestException catch (error) {
      if (!_isMissingTable(error) && !_isMissingColumn(error)) {
        rethrow;
      }
    }

    final profileId = project.corporateProfileId;
    if (profileId != null) {
      try {
        final rows = await _client
            .from('corporate_scan_sessions')
            .select()
            .eq('corporate_user_id', profileId)
            .order('updated_at', ascending: false);
        for (final row
            in (rows as List<dynamic>).whereType<Map<String, dynamic>>()) {
          byId[_sessionKey(row)] = row;
        }
      } on PostgrestException catch (error) {
        if (!_isMissingTable(error) && !_isMissingColumn(error)) {
          rethrow;
        }
      }
    }

    return byId.values.toList();
  }

  CorporateEmployeeItem _patientRowToEmployee(Map<String, dynamic> row) {
    final metadata = _parseNotes(row['notes']?.toString());
    return CorporateEmployeeItem(
      employeeCode: row['patient_code']?.toString() ?? '',
      firstName: row['first_name']?.toString() ?? '',
      lastName: row['last_name']?.toString() ?? '',
      departmentName: metadata['departman'] ?? '',
      jobTitle: metadata['görev'] ?? metadata['gorev'] ?? '',
      shift: metadata['vardiya'] ?? '',
      phone: row['phone']?.toString(),
      email: row['email']?.toString(),
      gender: row['gender']?.toString(),
      birthDate: DateTime.tryParse(row['birth_date']?.toString() ?? ''),
      shoeSize: int.tryParse(metadata['ayakkabı numarası'] ?? ''),
      scanStatus: CorporateScanStatus.waiting,
      hasPersonalAccount: row['auth_user_id'] != null,
    );
  }

  Map<String, String> _parseNotes(String? notes) {
    final result = <String, String>{};
    final raw = notes ?? '';
    for (final line in raw.split('\n')) {
      final separator = line.indexOf(':');
      if (separator < 0) continue;
      final key = line.substring(0, separator).trim().toLowerCase();
      final value = line.substring(separator + 1).trim();
      if (key.isEmpty || value.isEmpty) continue;
      result[key] = value;
    }
    return result;
  }

  List<CorporateEmployeeItem> _mergeScanSessions(
    List<CorporateEmployeeItem> employees,
    List<Map<String, dynamic>> sessions,
  ) {
    final sessionsByCode = <String, CorporateScanSessionItem>{};
    for (final row in sessions) {
      final session = CorporateScanSessionItem.fromMap(row);
      final code = session.patientCode.trim().toLowerCase();
      if (code.isEmpty) continue;
      final current = sessionsByCode[code];
      if (current == null ||
          _isSessionNewer(session.displayDate, current.displayDate)) {
        sessionsByCode[code] = session;
      }
    }

    return employees.map((employee) {
      final session = sessionsByCode[employee.employeeCode.toLowerCase()];
      if (session == null) return employee;
      return employee.copyWith(
        scanStatus: session.status,
        lastScanAt: session.displayDate,
        localScanOutputPath: session.localOutputPath,
        scanErrorMessage: session.errorMessage,
      );
    }).toList();
  }

  bool _isSessionNewer(DateTime? candidate, DateTime? current) {
    if (candidate == null) return false;
    if (current == null) return true;
    return candidate.isAfter(current);
  }

  String _sessionKey(Map<String, dynamic> row) {
    return (row['id'] ?? row['patient_code'] ?? row.hashCode).toString();
  }

  bool _isMissingTable(PostgrestException error) {
    return error.code == '42P01' ||
        error.message.toLowerCase().contains('does not exist') ||
        error.message.toLowerCase().contains('schema cache');
  }

  bool _isMissingColumn(PostgrestException error) {
    return error.code == '42703' ||
        error.message.toLowerCase().contains('column') &&
            error.message.toLowerCase().contains('does not exist');
  }
}

class CorporateScanProjectRepositoryException implements Exception {
  const CorporateScanProjectRepositoryException(this.message);

  final String message;

  @override
  String toString() => message;
}
