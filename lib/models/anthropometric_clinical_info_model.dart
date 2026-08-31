class AnthropometricClinicalInfoModel {
  final int? anthropometricId;
  final int sessionId;

  final double? heightCm;
  final double? weightKg;
  final double? bmi;
  final double? shoeSizeEu;

  final String? profession;
  final double? dailyStandingHours;
  final String? jobDescription;

  final bool doesSport;
  final String? sportDescription;

  final String? currentComplaint;
  final String? diagnosisPreDiagnosis;

  final bool hasDiabetes;
  final String? diabetesNote;

  final bool halluxValgus;
  final bool heelSpur;
  final bool flatFoot;
  final bool pesCavus;
  final bool mortonNeuroma;
  final bool achillesProblem;
  final bool metatarsalPain;

  final String? otherPathologies;

  final DateTime? createdAt;
  final DateTime? updatedAt;

  const AnthropometricClinicalInfoModel({
    this.anthropometricId,
    required this.sessionId,
    this.heightCm,
    this.weightKg,
    this.bmi,
    this.shoeSizeEu,
    this.profession,
    this.dailyStandingHours,
    this.jobDescription,
    this.doesSport = false,
    this.sportDescription,
    this.currentComplaint,
    this.diagnosisPreDiagnosis,
    this.hasDiabetes = false,
    this.diabetesNote,
    this.halluxValgus = false,
    this.heelSpur = false,
    this.flatFoot = false,
    this.pesCavus = false,
    this.mortonNeuroma = false,
    this.achillesProblem = false,
    this.metatarsalPain = false,
    this.otherPathologies,
    this.createdAt,
    this.updatedAt,
  });

  AnthropometricClinicalInfoModel copyWith({
    int? anthropometricId,
    int? sessionId,
    double? heightCm,
    double? weightKg,
    double? bmi,
    double? shoeSizeEu,
    String? profession,
    double? dailyStandingHours,
    String? jobDescription,
    bool? doesSport,
    String? sportDescription,
    String? currentComplaint,
    String? diagnosisPreDiagnosis,
    bool? hasDiabetes,
    String? diabetesNote,
    bool? halluxValgus,
    bool? heelSpur,
    bool? flatFoot,
    bool? pesCavus,
    bool? mortonNeuroma,
    bool? achillesProblem,
    bool? metatarsalPain,
    String? otherPathologies,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return AnthropometricClinicalInfoModel(
      anthropometricId: anthropometricId ?? this.anthropometricId,
      sessionId: sessionId ?? this.sessionId,
      heightCm: heightCm ?? this.heightCm,
      weightKg: weightKg ?? this.weightKg,
      bmi: bmi ?? this.bmi,
      shoeSizeEu: shoeSizeEu ?? this.shoeSizeEu,
      profession: profession ?? this.profession,
      dailyStandingHours: dailyStandingHours ?? this.dailyStandingHours,
      jobDescription: jobDescription ?? this.jobDescription,
      doesSport: doesSport ?? this.doesSport,
      sportDescription: sportDescription ?? this.sportDescription,
      currentComplaint: currentComplaint ?? this.currentComplaint,
      diagnosisPreDiagnosis:
          diagnosisPreDiagnosis ?? this.diagnosisPreDiagnosis,
      hasDiabetes: hasDiabetes ?? this.hasDiabetes,
      diabetesNote: diabetesNote ?? this.diabetesNote,
      halluxValgus: halluxValgus ?? this.halluxValgus,
      heelSpur: heelSpur ?? this.heelSpur,
      flatFoot: flatFoot ?? this.flatFoot,
      pesCavus: pesCavus ?? this.pesCavus,
      mortonNeuroma: mortonNeuroma ?? this.mortonNeuroma,
      achillesProblem: achillesProblem ?? this.achillesProblem,
      metatarsalPain: metatarsalPain ?? this.metatarsalPain,
      otherPathologies: otherPathologies ?? this.otherPathologies,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  factory AnthropometricClinicalInfoModel.fromMap(Map<String, dynamic> map) {
    return AnthropometricClinicalInfoModel(
      anthropometricId: map['anthropometric_id'] as int?,
      sessionId: map['session_id'] as int? ?? 0,
      heightCm: _toDoubleOrNull(map['height_cm']),
      weightKg: _toDoubleOrNull(map['weight_kg']),
      bmi: _toDoubleOrNull(map['bmi']),
      shoeSizeEu: _toDoubleOrNull(map['shoe_size_eu']),
      profession: map['profession'] as String?,
      dailyStandingHours: _toDoubleOrNull(map['daily_standing_hours']),
      jobDescription: map['job_description'] as String?,
      doesSport: map['does_sport'] as bool? ?? false,
      sportDescription: map['sport_description'] as String?,
      currentComplaint: map['current_complaint'] as String?,
      diagnosisPreDiagnosis: map['diagnosis_pre_diagnosis'] as String?,
      hasDiabetes: map['has_diabetes'] as bool? ?? false,
      diabetesNote: map['diabetes_note'] as String?,
      halluxValgus: map['hallux_valgus'] as bool? ?? false,
      heelSpur: map['heel_spur'] as bool? ?? false,
      flatFoot: map['flat_foot'] as bool? ?? false,
      pesCavus: map['pes_cavus'] as bool? ?? false,
      mortonNeuroma: map['morton_neuroma'] as bool? ?? false,
      achillesProblem: map['achilles_problem'] as bool? ?? false,
      metatarsalPain: map['metatarsal_pain'] as bool? ?? false,
      otherPathologies: map['other_pathologies'] as String?,
      createdAt: _parseDate(map['created_at']),
      updatedAt: _parseDate(map['updated_at']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'anthropometric_id': anthropometricId,
      'session_id': sessionId,
      'height_cm': heightCm,
      'weight_kg': weightKg,
      'bmi': bmi,
      'shoe_size_eu': shoeSizeEu,
      'profession': profession,
      'daily_standing_hours': dailyStandingHours,
      'job_description': jobDescription,
      'does_sport': doesSport,
      'sport_description': sportDescription,
      'current_complaint': currentComplaint,
      'diagnosis_pre_diagnosis': diagnosisPreDiagnosis,
      'has_diabetes': hasDiabetes,
      'diabetes_note': diabetesNote,
      'hallux_valgus': halluxValgus,
      'heel_spur': heelSpur,
      'flat_foot': flatFoot,
      'pes_cavus': pesCavus,
      'morton_neuroma': mortonNeuroma,
      'achilles_problem': achillesProblem,
      'metatarsal_pain': metatarsalPain,
      'other_pathologies': otherPathologies,
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  static double? _toDoubleOrNull(dynamic value) {
    if (value == null) return null;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    return double.tryParse(value.toString());
  }

  static DateTime? _parseDate(dynamic value) {
    if (value == null) return null;
    if (value is DateTime) return value;
    return DateTime.tryParse(value.toString());
  }
}