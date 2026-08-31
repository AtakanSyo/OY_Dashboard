import 'dart:async';

import 'package:oy_site/models/anthropometric_clinical_info_model.dart';

class MockAnthropometricClinicalInfoRepository {
  Future<AnthropometricClinicalInfoModel> getBySessionId(int sessionId) async {
    await Future.delayed(const Duration(milliseconds: 300));

    return AnthropometricClinicalInfoModel(
      anthropometricId: 1,
      sessionId: sessionId,
      heightCm: 176,
      weightKg: 82,
      bmi: 26.5,
      shoeSizeEu: 42.5,
      profession: 'Öğretmen',
      dailyStandingHours: 7.5,
      jobDescription: 'Gün içinde uzun süre ayakta kalıyor.',
      doesSport: true,
      sportDescription: 'Haftada 2 gün yürüyüş ve fitness',
      currentComplaint:
          'Uzun süre ayakta kaldığında topuk ve metatars bölgesinde ağrı oluşuyor.',
      diagnosisPreDiagnosis:
          'Pes planus eğilimi ve yük dağılımında dengesizlik şüphesi.',
      hasDiabetes: false,
      diabetesNote: null,
      halluxValgus: false,
      heelSpur: true,
      flatFoot: true,
      pesCavus: false,
      mortonNeuroma: false,
      achillesProblem: false,
      metatarsalPain: true,
      otherPathologies: 'Zaman zaman plantar fasya hassasiyeti bildiriliyor.',
      createdAt: DateTime.now().subtract(const Duration(days: 3)),
      updatedAt: DateTime.now(),
    );
  }

  Future<void> save(AnthropometricClinicalInfoModel model) async {
    await Future.delayed(const Duration(milliseconds: 300));
  }
}