import 'dart:async';

import 'package:flutter/material.dart';
import 'package:oy_site/dml/models/dml_home_data.dart';

class MockDmlHomeRepository {
  Future<DmlHomeData> getHomeData() async {
    await Future<void>.delayed(const Duration(milliseconds: 350));

    return const DmlHomeData(
      capabilities: [
        DmlCapability(
          icon: Icons.accessibility_new_outlined,
          title: 'Anatomik modeller',
          description:
              'Eğitim, araştırma ve planlama için hazır veya kişiye özel anatomik modeller.',
        ),
        DmlCapability(
          icon: Icons.view_in_ar_outlined,
          title: 'Medikal görüntüden 3D model',
          description:
              'CT ve MR verilerinden ihtiyaca uygun dijital model ve fiziksel prototip.',
        ),
        DmlCapability(
          icon: Icons.precision_manufacturing_outlined,
          title: 'Prototipleme ve üretim',
          description:
              'Eklemeli ve talaşlı imalat yöntemleriyle araştırma ve ürün prototipleri.',
        ),
        DmlCapability(
          icon: Icons.science_outlined,
          title: 'Akademik proje desteği',
          description:
              'Öğrenci, araştırmacı ve uzmanların projeleri için teknik değerlendirme.',
        ),
      ],
      caseStudies: [
        DmlCaseStudy(
          category: 'Cerrahi planlama',
          title: 'CT verisinden kişiye özel kemik modeli',
          description:
              'Medikal görüntüler segmentasyon ve model düzenleme adımlarından geçirilerek gerçek ölçekte üretildi.',
          method: 'SLA baskı · Reçine',
        ),
        DmlCaseStudy(
          category: 'Anatomi eğitimi',
          title: 'Çok parçalı eğitim modeli',
          description:
              'Farklı anatomik yapıların ayrıştırılabildiği, tekrar kullanılabilir bir eğitim seti hazırlandı.',
          method: 'FDM baskı · Çoklu malzeme',
        ),
        DmlCaseStudy(
          category: 'Araştırma',
          title: 'Deney düzeneği için özel aparat',
          description:
              'Araştırma ihtiyacına göre modellenen aparat hızlı prototipleme ile doğrulandı.',
          method: 'CNC + FDM · Hibrit üretim',
        ),
      ],
      workflowSteps: [
        'İhtiyacınızı anlatın',
        'Verilerinizi güvenle paylaşın',
        'Teknik inceleme ve teklif alın',
        'Tasarımı onaylayın',
        'Üretimi takip edin',
        'Çalışmanızı teslim alın',
      ],
    );
  }
}
