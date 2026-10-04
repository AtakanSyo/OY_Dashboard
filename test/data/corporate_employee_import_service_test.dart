import 'package:flutter_test/flutter_test.dart';
import 'package:oy_site/data/repositories/supabase_patient_repository.dart';
import 'package:oy_site/models/app_user.dart';
import 'package:oy_site/models/corporate_dashboard_model.dart';
import 'package:oy_site/models/patient.dart';
import 'package:oy_site/services/corporate/corporate_employee_import_service.dart';

void main() {
  test('parses corporate employee csv rows with scan status', () {
    const csv = '''
employee_code,first_name,last_name,department,job_title,shift,phone,email,gender,birth_date,shoe_size,scan_status,last_scan_at,has_personal_account
EMP-001,Ayşe,Demir,Montaj,Operatör,Gündüz,5551112233,ayse@example.com,female,1990-02-03,38,completed,2026-09-24,true
EMP-002,Mehmet,Kaya,Lojistik,Depo,Gece,,,,,42,waiting,,
''';

    final employees = const CorporateEmployeeImportService().parseEmployeesCsv(
      csv,
    );

    expect(employees, hasLength(2));
    expect(employees.first.employeeCode, 'EMP-001');
    expect(employees.first.fullName, 'Ayşe Demir');
    expect(employees.first.departmentName, 'Montaj');
    expect(employees.first.scanStatus, CorporateScanStatus.completed);
    expect(employees.first.hasPersonalAccount, isTrue);
    expect(employees.first.shoeSize, 38);
    expect(employees.last.scanStatus, CorporateScanStatus.waiting);
  });

  test(
    'imports corporate employees as patients and skips existing codes',
    () async {
      final repository = _FakePatientRepository(
        existingPatients: [
          const Patient(
            patientId: 10,
            clinicId: 7,
            createdByUserId: 99,
            patientCode: 'EMP-001',
            firstName: 'Existing',
            lastName: 'Person',
          ),
        ],
      );
      final service = CorporateEmployeeImportService(
        patientRepository: repository,
      );

      final result = await service.importEmployeesAsPatients(
        currentUser: const AppUser(
          userId: 99,
          clinicId: 7,
          firstName: 'Corporate',
          lastName: 'User',
          email: 'corporate@example.com',
          roleCode: RoleCodes.corporate,
          roleName: 'Corporate',
        ),
        employees: const [
          CorporateEmployeeItem(
            employeeCode: 'EMP-001',
            firstName: 'Ahmet',
            lastName: 'Yılmaz',
            departmentName: 'Montaj',
            jobTitle: 'Operatör',
            shift: 'Gündüz',
          ),
          CorporateEmployeeItem(
            employeeCode: 'EMP-002',
            firstName: 'Ayşe',
            lastName: 'Demir',
            departmentName: 'Lojistik',
            jobTitle: 'Depo Personeli',
            shift: 'Gece',
            shoeSize: 38,
          ),
          CorporateEmployeeItem(
            employeeCode: '',
            firstName: 'Eksik',
            lastName: 'Kod',
            departmentName: 'Üretim',
            jobTitle: 'Operatör',
            shift: 'Gündüz',
          ),
        ],
      );

      expect(result.totalRows, 3);
      expect(result.skippedExisting, 1);
      expect(result.invalidRows, 1);
      expect(result.createdCount, 1);
      expect(repository.createdPatients.single.patientCode, 'EMP-002');
      expect(repository.createdPatients.single.clinicId, 7);
      expect(repository.createdPatients.single.createdByUserId, 99);
      expect(repository.createdPatients.single.notes, contains('Lojistik'));
      expect(
        repository.createdPatients.single.notes,
        contains('Ayakkabı numarası: 38'),
      );
    },
  );
}

class _FakePatientRepository extends SupabasePatientRepository {
  final List<Patient> existingPatients;
  final List<Patient> createdPatients = [];

  _FakePatientRepository({required this.existingPatients});

  @override
  Future<List<Patient>> getPatientsByCodes({
    required int ownerUserId,
    required List<String> patientCodes,
  }) async {
    final requestedCodes = patientCodes
        .map((code) => code.toLowerCase())
        .toSet();
    return existingPatients
        .where(
          (patient) =>
              requestedCodes.contains(patient.patientCode.toLowerCase()),
        )
        .toList();
  }

  @override
  Future<Patient> createPatient(Patient patient) async {
    final created = patient.copyWith(patientId: createdPatients.length + 1);
    createdPatients.add(created);
    return created;
  }
}
