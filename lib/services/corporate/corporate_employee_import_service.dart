import 'package:csv/csv.dart';
import 'package:oy_site/data/repositories/supabase_patient_repository.dart';
import 'package:oy_site/models/app_user.dart';
import 'package:oy_site/models/corporate_dashboard_model.dart';
import 'package:oy_site/models/patient.dart';

class CorporateEmployeeImportResult {
  final int totalRows;
  final int skippedExisting;
  final int invalidRows;
  final List<Patient> createdPatients;

  const CorporateEmployeeImportResult({
    required this.totalRows,
    required this.skippedExisting,
    required this.invalidRows,
    required this.createdPatients,
  });

  int get createdCount => createdPatients.length;
}

class CorporateEmployeeImportService {
  final SupabasePatientRepository patientRepository;

  const CorporateEmployeeImportService({
    this.patientRepository = const SupabasePatientRepository(),
  });

  List<CorporateEmployeeItem> parseEmployeesCsv(String csvText) {
    final trimmed = csvText.trim();
    if (trimmed.isEmpty) return const [];

    final rows = const CsvToListConverter(
      shouldParseNumbers: false,
      eol: '\n',
    ).convert(trimmed);

    if (rows.length < 2) return const [];

    final headers = rows.first
        .map((value) => value.toString().trim().toLowerCase())
        .toList();

    return rows.skip(1).where((row) => row.isNotEmpty).map((row) {
      final values = row.map((value) => value.toString()).toList();
      final map = <String, String>{};
      for (var index = 0; index < headers.length; index++) {
        map[headers[index]] = index < values.length ? values[index] : '';
      }
      return CorporateEmployeeItem.fromCsvMap(map);
    }).toList();
  }

  Future<CorporateEmployeeImportResult> importEmployeesAsPatients({
    required AppUser currentUser,
    required List<CorporateEmployeeItem> employees,
  }) async {
    final ownerUserId = currentUser.userId;
    if (ownerUserId == null) {
      throw Exception('Kurumsal kullanıcı ID bulunamadı.');
    }

    final validEmployees = employees.where(_isValidEmployee).toList();
    final invalidRows = employees.length - validEmployees.length;

    final existingPatients = await patientRepository.getPatientsByCodes(
      ownerUserId: ownerUserId,
      patientCodes: validEmployees
          .map((employee) => employee.employeeCode)
          .toList(),
    );
    final existingCodes = existingPatients
        .map((patient) => patient.patientCode.trim().toLowerCase())
        .toSet();

    final createdPatients = <Patient>[];
    var skippedExisting = 0;

    for (final employee in validEmployees) {
      final code = employee.employeeCode.trim();
      if (existingCodes.contains(code.toLowerCase())) {
        skippedExisting++;
        continue;
      }

      final patient = _employeeToPatient(
        employee: employee,
        currentUser: currentUser,
      );
      final createdPatient = await patientRepository.createPatient(patient);
      createdPatients.add(createdPatient);
      existingCodes.add(code.toLowerCase());
    }

    return CorporateEmployeeImportResult(
      totalRows: employees.length,
      skippedExisting: skippedExisting,
      invalidRows: invalidRows,
      createdPatients: createdPatients,
    );
  }

  bool _isValidEmployee(CorporateEmployeeItem employee) {
    return employee.employeeCode.trim().isNotEmpty &&
        employee.firstName.trim().isNotEmpty &&
        employee.lastName.trim().isNotEmpty;
  }

  Patient _employeeToPatient({
    required CorporateEmployeeItem employee,
    required AppUser currentUser,
  }) {
    return Patient(
      patientId: null,
      clinicId: currentUser.clinicId,
      createdByUserId: currentUser.userId,
      patientCode: employee.employeeCode.trim(),
      firstName: employee.firstName.trim(),
      lastName: employee.lastName.trim(),
      email: _blankToNull(employee.email),
      birthDate: employee.birthDate,
      gender: _normalizeGender(employee.gender),
      phone: _blankToNull(employee.phone),
      notes: _buildNotes(employee),
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
  }

  String? _normalizeGender(String? value) {
    switch ((value ?? '').trim().toLowerCase()) {
      case 'male':
      case 'female':
      case 'other':
      case 'unspecified':
        return value!.trim().toLowerCase();
      case 'erkek':
        return 'male';
      case 'kadın':
      case 'kadin':
        return 'female';
      default:
        return null;
    }
  }

  String? _blankToNull(String? value) {
    final trimmed = (value ?? '').trim();
    return trimmed.isEmpty ? null : trimmed;
  }

  String _buildNotes(CorporateEmployeeItem employee) {
    final parts = [
      'Kurumsal CSV import',
      'Çalışan kodu: ${employee.employeeCode}',
      if (employee.departmentName.trim().isNotEmpty)
        'Departman: ${employee.departmentName}',
      if (employee.jobTitle.trim().isNotEmpty) 'Görev: ${employee.jobTitle}',
      if (employee.shift.trim().isNotEmpty) 'Vardiya: ${employee.shift}',
      if (employee.shoeSize != null) 'Ayakkabı numarası: ${employee.shoeSize}',
    ];
    return parts.join('\n');
  }
}
