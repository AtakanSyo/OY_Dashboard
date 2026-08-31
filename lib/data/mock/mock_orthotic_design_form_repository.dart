import 'dart:async';

import 'package:oy_site/models/orthotic_design_form_model.dart';

class MockOrthoticDesignFormRepository {
  Future<OrthoticDesignFormModel> getDesignFormBySessionId(int sessionId) async {
    await Future.delayed(const Duration(milliseconds: 300));

    return OrthoticDesignFormModel(
      designFormId: 1,
      sessionId: sessionId,
      expertUserId: 1,
      heelPad: true,
      deepHeelCupMm: 12.0,
      heelRaiseMm: 4.0,
      medialArchSupport: true,
      metatarsalPad: true,
      transverseArchSupport: false,
      posteriorReliefMm: 2.5,
      mortonRelief: false,
      bunionPad: false,
      expertNotes:
          'Sol ayakta ark desteği belirgin tutulmalı. Sağ tarafta daha dengeli yaklaşım yeterli olabilir.',
      aiRecommendationJson:
          '{"summary":"Medial arch support + metatarsal pad önerilir","confidence":"0.82"}',
      approvedForOrder: false,
      createdAt: DateTime.now().subtract(const Duration(days: 2)),
      updatedAt: DateTime.now(),
    );
  }

  Future<void> saveDesignForm(OrthoticDesignFormModel form) async {
    await Future.delayed(const Duration(milliseconds: 300));
  }
}