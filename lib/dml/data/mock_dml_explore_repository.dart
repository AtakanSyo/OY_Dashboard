import 'dart:async';

import 'package:oy_site/dml/models/dml_explore_item.dart';

class MockDmlExploreRepository {
  Future<DmlExploreData> getData() async {
    await Future<void>.delayed(const Duration(milliseconds: 260));
    return const DmlExploreData(
      services: [
        DmlServiceItem(
          id: 'SRV-01',
          title: 'Medikal Görüntüden 3D Model',
          summary:
              'CT veya MR verilerinin amaca uygun dijital modele ve fiziksel prototipe dönüştürülmesi.',
          imagePath: 'assets/images/dml/services/medical_imaging_to_model.png',
          audience: 'Uzmanlar, akademisyenler ve araştırmacılar',
          requiredInput:
              'DICOM/CT/MR görüntü serisi, anatomik bölge ve kullanım amacı',
          deliverable:
              'Kontrol edilmiş dijital model ve seçilen yönteme göre fiziksel çıktı',
          duration: 'Teknik inceleme sonrasında planlanır',
          processSteps: [
            'Görüntü ve talep uygunluk kontrolü',
            'İlgili anatomik yapının ayrıştırılması',
            'Dijital modelin temizlenmesi ve üretime hazırlanması',
            'Kullanıcı kontrolü ve üretim planı',
            'Üretim, son işlem ve teslim',
          ],
          relatedMethods: ['SLA', 'FDM'],
        ),
        DmlServiceItem(
          id: 'SRV-02',
          title: 'Cerrahi Planlama Modeli',
          summary:
              'Vaka özelinde anatomik ilişkilerin fiziksel model üzerinden incelenmesine yönelik çalışma.',
          imagePath: 'assets/images/dml/services/surgical_planning.png',
          audience: 'Cerrahlar ve klinik ekipler',
          requiredInput:
              'Uygun medikal görüntü, hedef anatomik yapılar ve planlanan kullanım tarihi',
          deliverable:
              'Vaka özelinde hazırlanmış, teknik kapsamı onaylanmış anatomik model',
          duration: 'Vaka ve görüntü kalitesine göre belirlenir',
          processSteps: [
            'Klinik ihtiyacın tanımlanması',
            'Görüntü kalitesinin değerlendirilmesi',
            'Anatomik modelleme ve uzman kontrolü',
            'Ölçek, renk ve parça planlaması',
            'Üretim ve kalite kontrol',
          ],
          relatedMethods: ['SLA', 'FDM'],
        ),
        DmlServiceItem(
          id: 'SRV-03',
          title: 'Anatomi Eğitim Materyali',
          summary:
              'Ders, laboratuvar ve demonstrasyon amaçlı tekrar kullanılabilir anatomik model ve setler.',
          imagePath: 'assets/images/dml/services/anatomy_education.png',
          audience: 'Öğrenciler, eğitmenler ve bölüm laboratuvarları',
          requiredInput:
              'Öğrenme hedefi, anatomik bölge, adet ve kullanım ortamı',
          deliverable:
              'Tek veya çok parçalı eğitim modeli, gerektiğinde taşıma ve sergileme aparatı',
          duration: 'Genellikle 5–15 iş günü',
          processSteps: [
            'Eğitim hedeflerinin belirlenmesi',
            'Hazır model veya özel tasarım seçimi',
            'Malzeme ve renk planı',
            'Örnek üretim ve değerlendirme',
            'Set üretimi ve teslim',
          ],
          relatedMethods: ['FDM', 'SLA'],
        ),
        DmlServiceItem(
          id: 'SRV-04',
          title: 'Araştırma ve Prototipleme',
          summary:
              'Akademik çalışma, deney düzeneği, aparat ve yeni ürün fikirleri için tasarım-üretim desteği.',
          imagePath: 'assets/images/dml/services/research_prototyping.png',
          audience: 'Araştırmacılar, öğrenciler ve proje ekipleri',
          requiredInput:
              'Problem tanımı, çizim veya ölçüler, çalışma koşulları ve hedef tarih',
          deliverable:
              'Dijital tasarım, prototip, özel aparat veya doğrulama numunesi',
          duration: 'Kapsama göre aşamalı planlanır',
          processSteps: [
            'İhtiyaç ve kısıtların belirlenmesi',
            'Konsept tasarım',
            'Üretim yöntemi ve malzeme seçimi',
            'Prototip üretimi',
            'Geri bildirim ve tasarım iyileştirmesi',
          ],
          relatedMethods: ['FDM', 'SLA', 'CNC'],
        ),
        DmlServiceItem(
          id: 'SRV-05',
          title: 'Ortez ve Protez Prototipi',
          summary:
              'Bireysel ölçü veya araştırma verisine göre ergonomik ürün ve bileşen prototipleri.',
          imagePath: 'assets/images/dml/services/research_prototyping.png',
          audience: 'Ortez-protez uzmanları, öğrenciler ve ürün ekipleri',
          requiredInput:
              '3D tarama, ölçüler, kullanım amacı ve yük gereksinimleri',
          deliverable:
              'Test edilebilir prototip, kalıp veya üretime hazırlık modeli',
          duration: 'Tasarım döngüsüne göre belirlenir',
          processSteps: [
            'Ölçü ve kullanım verisinin değerlendirilmesi',
            'Dijital geometrinin hazırlanması',
            'Prototip malzemesinin seçilmesi',
            'Üretim ve uygunluk kontrolü',
            'Revizyon ve son çıktı',
          ],
          relatedMethods: ['FDM', 'CNC'],
        ),
        DmlServiceItem(
          id: 'SRV-06',
          title: 'Özel Parça ve Aparat Üretimi',
          summary:
              'Araştırma, eğitim veya laboratuvar süreçleri için ölçüye göre özel parça üretimi.',
          imagePath: 'assets/images/dml/methods/cnc_machining.png',
          audience: 'Laboratuvarlar, araştırmacılar ve teknik ekipler',
          requiredInput:
              'Teknik çizim, ölçüler, kullanım yükü ve malzeme beklentisi',
          deliverable: 'İşlevsel aparat, fikstür, kalıp veya özel parça',
          duration: 'Geometri ve malzemeye göre tekliflendirilir',
          processSteps: [
            'Teknik gereksinim kontrolü',
            'Üretilebilirlik değerlendirmesi',
            'Malzeme ve tolerans planı',
            'Üretim',
            'Ölçü ve işlev kontrolü',
          ],
          relatedMethods: ['CNC', 'FDM'],
        ),
      ],
      methods: [
        DmlProductionMethod(
          id: 'METHOD-FDM',
          title: 'FDM 3D Baskı',
          fullName: 'Eriyik Yığma Modelleme',
          summary:
              'Termoplastik filamentin katmanlar halinde biriktirilmesiyle dayanıklı ve ekonomik parçalar üretir.',
          imagePath: 'assets/images/dml/methods/fdm_printing.png',
          workingPrinciple:
              'Filament ısıtılarak ince bir uçtan kontrollü biçimde çıkarılır. Parça, dijital modeldeki kesitlere göre katman katman oluşturulur.',
          suitableFor: [
            'Eğitim modelleri',
            'Büyük hacimli prototipler',
            'Deney aparatları',
            'Esnek veya dayanıklı işlevsel parçalar',
          ],
          materials: ['PLA', 'PETG', 'TPU', 'ABS', 'Mühendislik filamentleri'],
          strengths: [
            'Ekonomik prototipleme',
            'Geniş malzeme seçeneği',
            'Büyük parça üretimi',
            'Hızlı tasarım tekrarı',
          ],
          considerations: [
            'Katman çizgileri görülebilir',
            'Çok ince anatomik detaylarda SLA daha uygun olabilir',
            'Destek yapıları son işlem gerektirebilir',
          ],
        ),
        DmlProductionMethod(
          id: 'METHOD-SLA',
          title: 'SLA Reçine Baskı',
          fullName: 'Stereolitografi',
          summary:
              'Sıvı fotopolimer reçineyi ışıkla katılaştırarak yüksek detaylı ve düzgün yüzeyli modeller üretir.',
          imagePath: 'assets/images/dml/methods/sla_printing.png',
          workingPrinciple:
              'Reçine haznesindeki malzeme, her katmanda kontrollü ışıkla sertleştirilir. Üretim sonrasında parça yıkanır ve UV ile son kürleme yapılır.',
          suitableFor: [
            'Detaylı anatomik modeller',
            'Küçük ve hassas prototipler',
            'Şeffaf veya özel yüzeyli parçalar',
            'Sunum ve demonstrasyon modelleri',
          ],
          materials: [
            'Standart reçine',
            'Mühendislik reçinesi',
            'Şeffaf reçine',
            'Esnek reçine',
          ],
          strengths: [
            'Yüksek detay seviyesi',
            'Düzgün yüzey kalitesi',
            'Karmaşık geometriler',
            'Küçük yapıların üretimi',
          ],
          considerations: [
            'Yıkama ve kürleme gerekir',
            'Malzeme seçimi kullanım koşuluna göre yapılmalıdır',
            'Büyük hacimli modellerde maliyet artabilir',
          ],
        ),
        DmlProductionMethod(
          id: 'METHOD-CNC',
          title: 'CNC İşleme',
          fullName: 'Bilgisayar Kontrollü Talaşlı İmalat',
          summary:
              'Katı malzeme bloğundan kontrollü talaş kaldırarak hassas kalıp, aparat ve işlevsel parça üretir.',
          imagePath: 'assets/images/dml/methods/cnc_machining.png',
          workingPrinciple:
              'Kesici takım, dijital takım yollarını izleyerek malzeme bloğunu işler. Geometri, tolerans ve yüzey beklentisine göre farklı takımlar kullanılır.',
          suitableFor: [
            'Ortez ve taban kalıpları',
            'Deney aparatları',
            'Fikstürler',
            'Dayanıklı işlevsel parçalar',
          ],
          materials: [
            'EVA ve köpük',
            'Plastik',
            'Ahşap',
            'Alüminyum',
            'Kompozit',
          ],
          strengths: [
            'Yüksek ölçü tekrarlanabilirliği',
            'Dayanıklı malzemeler',
            'İyi yüzey kalitesi',
            'İşlevsel son parça üretimi',
          ],
          considerations: [
            'Geometri takım erişimine uygun olmalıdır',
            'Malzeme firesi oluşur',
            'Bağlama ve takım yolu hazırlığı gerekir',
          ],
        ),
      ],
    );
  }
}
