import 'package:oy_site/data/repositories/supabase_corporate_scan_session_repository.dart';
import 'package:oy_site/data/repositories/supabase_patient_repository.dart';
import 'package:oy_site/models/app_user.dart';
import 'package:oy_site/models/corporate_dashboard_model.dart';
import 'package:oy_site/models/patient.dart';

class CorporateEmployeeSourceService {
  final SupabasePatientRepository patientRepository;
  final SupabaseCorporateScanSessionRepository scanSessionRepository;

  const CorporateEmployeeSourceService({
    this.patientRepository = const SupabasePatientRepository(),
    this.scanSessionRepository = const SupabaseCorporateScanSessionRepository(),
  });

  Future<List<CorporateEmployeeItem>> getEmployees({
    required AppUser currentUser,
  }) async {
    final userId = currentUser.userId;
    if (userId == null) return const [];

    final patients = await patientRepository.getPatientsByExpert(
      expertUserId: userId,
    );
    final employees = patients.map(_patientToEmployee).toList();

    final List<CorporateScanSessionItem> sessions;
    try {
      sessions = await scanSessionRepository.getSessions(
        corporateUserId: userId,
      );
    } catch (_) {
      return employees;
    }
    return _mergeScanSessions(employees, sessions);
  }

  CorporateEmployeeItem _patientToEmployee(Patient patient) {
    final metadata = _parseNotes(patient.notes);
    return CorporateEmployeeItem(
      employeeCode: patient.patientCode,
      firstName: patient.firstName,
      lastName: patient.lastName,
      departmentName: metadata['departman'] ?? '',
      jobTitle: metadata['görev'] ?? metadata['gorev'] ?? '',
      shift: metadata['vardiya'] ?? '',
      phone: patient.phone,
      email: patient.email,
      gender: patient.gender,
      birthDate: patient.birthDate,
      shoeSize: int.tryParse(metadata['ayakkabı numarası'] ?? ''),
      scanStatus: CorporateScanStatus.waiting,
      hasPersonalAccount: false,
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
    List<CorporateScanSessionItem> sessions,
  ) {
    final sessionsByCode = <String, CorporateScanSessionItem>{};
    for (final session in sessions) {
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
}
