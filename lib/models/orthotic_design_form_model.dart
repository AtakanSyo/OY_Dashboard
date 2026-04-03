class OrthoticDesignFormModel {
  final int? designFormId;
  final int sessionId;
  final int expertUserId;

  final bool heelPad;
  final double? deepHeelCupMm;
  final double? heelRaiseMm;

  final bool medialArchSupport;
  final bool metatarsalPad;
  final bool transverseArchSupport;

  final double? posteriorReliefMm;
  final bool mortonRelief;
  final bool bunionPad;

  final String? expertNotes;
  final String? aiRecommendationJson;
  final bool approvedForOrder;

  final DateTime? createdAt;
  final DateTime? updatedAt;

  const OrthoticDesignFormModel({
    this.designFormId,
    required this.sessionId,
    required this.expertUserId,
    this.heelPad = false,
    this.deepHeelCupMm,
    this.heelRaiseMm,
    this.medialArchSupport = false,
    this.metatarsalPad = false,
    this.transverseArchSupport = false,
    this.posteriorReliefMm,
    this.mortonRelief = false,
    this.bunionPad = false,
    this.expertNotes,
    this.aiRecommendationJson,
    this.approvedForOrder = false,
    this.createdAt,
    this.updatedAt,
  });

  OrthoticDesignFormModel copyWith({
    int? designFormId,
    int? sessionId,
    int? expertUserId,
    bool? heelPad,
    double? deepHeelCupMm,
    double? heelRaiseMm,
    bool? medialArchSupport,
    bool? metatarsalPad,
    bool? transverseArchSupport,
    double? posteriorReliefMm,
    bool? mortonRelief,
    bool? bunionPad,
    String? expertNotes,
    String? aiRecommendationJson,
    bool? approvedForOrder,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return OrthoticDesignFormModel(
      designFormId: designFormId ?? this.designFormId,
      sessionId: sessionId ?? this.sessionId,
      expertUserId: expertUserId ?? this.expertUserId,
      heelPad: heelPad ?? this.heelPad,
      deepHeelCupMm: deepHeelCupMm ?? this.deepHeelCupMm,
      heelRaiseMm: heelRaiseMm ?? this.heelRaiseMm,
      medialArchSupport: medialArchSupport ?? this.medialArchSupport,
      metatarsalPad: metatarsalPad ?? this.metatarsalPad,
      transverseArchSupport:
          transverseArchSupport ?? this.transverseArchSupport,
      posteriorReliefMm: posteriorReliefMm ?? this.posteriorReliefMm,
      mortonRelief: mortonRelief ?? this.mortonRelief,
      bunionPad: bunionPad ?? this.bunionPad,
      expertNotes: expertNotes ?? this.expertNotes,
      aiRecommendationJson:
          aiRecommendationJson ?? this.aiRecommendationJson,
      approvedForOrder: approvedForOrder ?? this.approvedForOrder,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  factory OrthoticDesignFormModel.fromMap(Map<String, dynamic> map) {
    return OrthoticDesignFormModel(
      designFormId: map['design_form_id'] as int?,
      sessionId: map['session_id'] as int? ?? 0,
      expertUserId: map['expert_user_id'] as int? ?? 0,
      heelPad: map['heel_pad'] as bool? ?? false,
      deepHeelCupMm: _toDoubleOrNull(map['deep_heel_cup_mm']),
      heelRaiseMm: _toDoubleOrNull(map['heel_raise_mm']),
      medialArchSupport: map['medial_arch_support'] as bool? ?? false,
      metatarsalPad: map['metatarsal_pad'] as bool? ?? false,
      transverseArchSupport:
          map['transverse_arch_support'] as bool? ?? false,
      posteriorReliefMm: _toDoubleOrNull(map['posterior_relief_mm']),
      mortonRelief: map['morton_relief'] as bool? ?? false,
      bunionPad: map['bunion_pad'] as bool? ?? false,
      expertNotes: map['expert_notes'] as String?,
      aiRecommendationJson: map['ai_recommendation_json'] as String?,
      approvedForOrder: map['approved_for_order'] as bool? ?? false,
      createdAt: _parseDate(map['created_at']),
      updatedAt: _parseDate(map['updated_at']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'design_form_id': designFormId,
      'session_id': sessionId,
      'expert_user_id': expertUserId,
      'heel_pad': heelPad,
      'deep_heel_cup_mm': deepHeelCupMm,
      'heel_raise_mm': heelRaiseMm,
      'medial_arch_support': medialArchSupport,
      'metatarsal_pad': metatarsalPad,
      'transverse_arch_support': transverseArchSupport,
      'posterior_relief_mm': posteriorReliefMm,
      'morton_relief': mortonRelief,
      'bunion_pad': bunionPad,
      'expert_notes': expertNotes,
      'ai_recommendation_json': aiRecommendationJson,
      'approved_for_order': approvedForOrder,
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