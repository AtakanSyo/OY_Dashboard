import 'dart:async';

import 'package:oy_site/dml/models/dml_catalog_item.dart';

class MockDmlCatalogRepository {
  Future<List<DmlCatalogItem>> getItems() async {
    await Future<void>.delayed(const Duration(milliseconds: 280));
    return const [
      DmlCatalogItem(
        id: 'DML-AN-001',
        name: 'Kafatası Eğitim Modeli',
        category: 'Kafa ve boyun',
        shortDescription:
            'Anatomi eğitimi ve demonstrasyon için gerçek boyutlu kafatası modeli.',
        description:
            'Kemik yapıların genel anatomisini incelemek, öğrenci eğitimleri ve hasta bilgilendirme çalışmaları için hazırlanabilen modüler eğitim modelidir.',
        imagePath: 'assets/images/dml/catalog/skull_model.png',
        useCases: ['Anatomi eğitimi', 'Hasta bilgilendirme', 'Demonstrasyon'],
        materials: ['Sert reçine', 'PLA', 'PETG'],
        scaleOptions: ['1:1 gerçek boyut', '1:2 masaüstü'],
        includedStructures: [
          'Kranium',
          'Mandibula',
          'Diş yapıları',
          'Temel sütür hatları',
        ],
        productionTime: '5–8 iş günü',
        priceLabel: 'Başlangıç fiyatı için teklif alın',
        customizable: true,
      ),
      DmlCatalogItem(
        id: 'DML-AN-002',
        name: 'Diz Eklemi Modeli',
        category: 'Alt ekstremite',
        shortDescription:
            'Kemik, menisküs ve temel bağ yapılarını gösteren eklem modeli.',
        description:
            'Diz ekleminin temel bileşenlerini üç boyutlu olarak incelemek için tasarlanan eğitim modelidir. Farklı yapıların renklerle ayrıştırılması mümkündür.',
        imagePath: 'assets/images/dml/catalog/knee_model.png',
        useCases: ['Anatomi eğitimi', 'Fizyoterapi eğitimi', 'Araştırma'],
        materials: ['Sert reçine', 'Esnek TPU', 'Çoklu malzeme'],
        scaleOptions: ['1:1 gerçek boyut', '1.5:1 büyütülmüş'],
        includedStructures: [
          'Femur',
          'Tibia',
          'Fibula',
          'Patella',
          'Menisküs',
          'Temel bağlar',
        ],
        productionTime: '6–10 iş günü',
        priceLabel: 'Yapı ve malzemeye göre tekliflendirilir',
        customizable: true,
      ),
      DmlCatalogItem(
        id: 'DML-AN-003',
        name: 'Omurga ve Pelvis Eğitim Seti',
        category: 'Omurga',
        shortDescription:
            'Omurga dizilimini ve pelvis ilişkisini gösteren tam boy eğitim seti.',
        description:
            'Servikal bölgeden pelvise uzanan yapıları bütüncül olarak göstermek için hazırlanabilen, standlı eğitim ve demonstrasyon modelidir.',
        imagePath: 'assets/images/dml/catalog/spine_model.png',
        useCases: ['Anatomi eğitimi', 'Ortez eğitimi', 'Postür çalışmaları'],
        materials: ['PLA', 'PETG', 'Sert reçine'],
        scaleOptions: ['1:1 gerçek boyut', '3:4 kompakt'],
        includedStructures: [
          'Servikal omurlar',
          'Torakal omurlar',
          'Lomber omurlar',
          'Sakrum',
          'Pelvis',
        ],
        productionTime: '8–12 iş günü',
        priceLabel: 'Set içeriğine göre tekliflendirilir',
        customizable: true,
      ),
      DmlCatalogItem(
        id: 'DML-AN-004',
        name: 'Kesitli Kalp Anatomisi',
        category: 'Organ modelleri',
        shortDescription:
            'Kalp boşluklarının ve temel damar bağlantılarının incelenebildiği model.',
        description:
            'İç yapıların gözlemlenebilmesi için ayrılabilir parçalar halinde üretilebilen anatomi eğitim modelidir.',
        imagePath: 'assets/images/dml/catalog/heart_model.png',
        useCases: ['Anatomi eğitimi', 'Hasta bilgilendirme', 'Sunum'],
        materials: ['Renkli reçine', 'Çoklu malzeme'],
        scaleOptions: ['1:1 gerçek boyut', '2:1 büyütülmüş'],
        includedStructures: [
          'Atriyumlar',
          'Ventriküller',
          'Temel damarlar',
          'Kapak bölgeleri',
        ],
        productionTime: '6–9 iş günü',
        priceLabel: 'Renk ve parça sayısına göre tekliflendirilir',
        customizable: true,
      ),
      DmlCatalogItem(
        id: 'DML-AN-005',
        name: 'Çene ve Diş Yapısı Modeli',
        category: 'Kafa ve boyun',
        shortDescription:
            'Maksilla, mandibula ve diş ilişkisini gösteren kompakt eğitim modeli.',
        description:
            'Diş hekimliği ve anatomi eğitimleri için temel kemik ve diş ilişkilerinin incelenmesini sağlayan modeldir.',
        imagePath: 'assets/images/dml/catalog/skull_model.png',
        useCases: ['Diş hekimliği eğitimi', 'Demonstrasyon'],
        materials: ['Sert reçine'],
        scaleOptions: ['1:1 gerçek boyut', '2:1 büyütülmüş'],
        includedStructures: ['Maksilla', 'Mandibula', 'Diş arkları'],
        productionTime: '5–7 iş günü',
        priceLabel: 'Başlangıç fiyatı için teklif alın',
        customizable: true,
      ),
      DmlCatalogItem(
        id: 'DML-AN-006',
        name: 'Ayak ve Ayak Bileği Modeli',
        category: 'Alt ekstremite',
        shortDescription:
            'Ayak kemikleri ve ayak bileği ilişkisini gösteren eğitim modeli.',
        description:
            'Ortez-protez, fizyoterapi ve anatomi eğitimlerinde kullanılmak üzere ayak iskelet geometrisini gösteren modeldir.',
        imagePath: 'assets/images/dml/catalog/knee_model.png',
        useCases: ['Ortez-protez eğitimi', 'Anatomi eğitimi', 'Araştırma'],
        materials: ['Sert reçine', 'PLA'],
        scaleOptions: ['1:1 gerçek boyut', '1.5:1 büyütülmüş'],
        includedStructures: [
          'Tibia distal',
          'Fibula distal',
          'Tarsal kemikler',
          'Metatarslar',
          'Falankslar',
        ],
        productionTime: '5–8 iş günü',
        priceLabel: 'Model detayına göre tekliflendirilir',
        customizable: true,
      ),
    ];
  }
}
