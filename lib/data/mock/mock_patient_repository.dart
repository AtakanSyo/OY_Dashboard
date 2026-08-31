import 'dart:async';

import 'package:oy_site/models/patient.dart';

class MockPatientRepository {
  Future<List<Patient>> getPatients() async {
    await Future.delayed(const Duration(milliseconds: 300));

    return [
      Patient(
        patientId: 1,
        clinicId: 101,
        createdByUserId: 1,
        patientCode: 'PT-0001',
        firstName: 'Ayşe',
        lastName: 'Demir',
        email: 'ayse.demir@example.com',
        birthDate: DateTime(1992, 5, 14),
        gender: 'female',
        phone: '+90 555 111 11 11',
        notes: 'Uzun süre ayakta çalışıyor.',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
      Patient(
        patientId: 2,
        clinicId: 101,
        createdByUserId: 1,
        patientCode: 'PT-0002',
        firstName: 'Mehmet',
        lastName: 'Kaya',
        email: 'mehmet.kaya@example.com',
        birthDate: DateTime(1987, 11, 3),
        gender: 'male',
        phone: '+90 555 222 22 22',
        notes: 'Topuk dikeni şikayeti mevcut.',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
      Patient(
        patientId: 3,
        clinicId: 101,
        createdByUserId: 1,
        patientCode: 'PT-0003',
        firstName: 'Elif',
        lastName: 'Yıldız',
        email: null,
        birthDate: DateTime(2001, 8, 21),
        gender: 'female',
        phone: null,
        notes: 'Sporcu tabanlık için ön değerlendirme.',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
    ];
  }
}