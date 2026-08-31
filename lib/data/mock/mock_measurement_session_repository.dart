import 'dart:async';

import 'package:oy_site/models/measurement_session.dart';

class MockMeasurementSessionRepository {
  Future<List<MeasurementSession>> getSessions() async {
    await Future.delayed(const Duration(milliseconds: 350));

    return [
      MeasurementSession(
        sessionId: 1,
        clinicId: 101,
        patientId: 1,
        expertUserId: 1,
        assignedOptityouUserId: 2,
        sessionCode: 'MS-2026-001',
        sessionDate: DateTime(2026, 3, 21),
        sessionTime: '10:30',
        status: SessionStatuses.completed,
        has3dScan: true,
        hasPlantarCsv: true,
        hasInsolePhoto: true,
        orderCreated: true,
        completedAt: DateTime(2026, 3, 21, 11, 20),
        createdAt: DateTime(2026, 3, 21, 10, 0),
        updatedAt: DateTime(2026, 3, 21, 11, 20),
      ),
      MeasurementSession(
        sessionId: 2,
        clinicId: 101,
        patientId: 2,
        expertUserId: 1,
        assignedOptityouUserId: 2,
        sessionCode: 'MS-2026-002',
        sessionDate: DateTime(2026, 3, 28),
        sessionTime: '14:00',
        status: SessionStatuses.completed,
        has3dScan: true,
        hasPlantarCsv: true,
        hasInsolePhoto: false,
        orderCreated: false,
        completedAt: DateTime(2026, 3, 28, 14, 45),
        createdAt: DateTime(2026, 3, 28, 13, 40),
        updatedAt: DateTime(2026, 3, 28, 14, 45),
      ),
      MeasurementSession(
        sessionId: 3,
        clinicId: 101,
        patientId: 3,
        expertUserId: 1,
        assignedOptityouUserId: null,
        sessionCode: 'MS-2026-003',
        sessionDate: DateTime(2026, 4, 1),
        sessionTime: '09:15',
        status: SessionStatuses.inProgress,
        has3dScan: true,
        hasPlantarCsv: false,
        hasInsolePhoto: true,
        orderCreated: false,
        createdAt: DateTime(2026, 4, 1, 9, 0),
        updatedAt: DateTime(2026, 4, 1, 9, 30),
      ),
      MeasurementSession(
        sessionId: 4,
        clinicId: 101,
        patientId: 1,
        expertUserId: 1,
        assignedOptityouUserId: null,
        sessionCode: 'MS-2026-004',
        sessionDate: DateTime(2026, 4, 2),
        sessionTime: '16:10',
        status: SessionStatuses.draft,
        has3dScan: false,
        hasPlantarCsv: false,
        hasInsolePhoto: false,
        orderCreated: false,
        createdAt: DateTime(2026, 4, 2, 15, 45),
        updatedAt: DateTime(2026, 4, 2, 15, 50),
      ),
    ];
  }
}