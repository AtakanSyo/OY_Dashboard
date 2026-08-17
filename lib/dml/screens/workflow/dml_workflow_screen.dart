import 'package:flutter/material.dart';
import 'package:oy_site/dml/app/dml_theme.dart';

class DmlWorkflowScreen extends StatelessWidget {
  final VoidCallback onRequestTap;
  const DmlWorkflowScreen({super.key, required this.onRequestTap});

  @override
  Widget build(BuildContext context) {
    const steps = [
      (
        '01',
        'İhtiyacın tanımlanması',
        'Kullanım amacı, hedef anatomi veya parçanın işlevi sade bir form ile anlatılır.',
        Icons.chat_bubble_outline,
      ),
      (
        '02',
        'Veri ve uygunluk kontrolü',
        'Görüntüler, çizimler ve beklentiler DML ekibi tarafından ön değerlendirmeye alınır.',
        Icons.fact_check_outlined,
      ),
      (
        '03',
        'Kapsam ve teklif',
        'Yöntem, malzeme, süre, teslim biçimi ve tahmini maliyet netleştirilir.',
        Icons.description_outlined,
      ),
      (
        '04',
        'Dijital hazırlık',
        'Segmentasyon, modelleme veya üretim dosyası hazırlığı tamamlanır; gereken noktalarda uzman görüşü alınır.',
        Icons.view_in_ar_outlined,
      ),
      (
        '05',
        'Onay ve üretim',
        'Dijital ön izleme onaylanır; uygun FDM, SLA veya CNC süreci başlatılır.',
        Icons.precision_manufacturing_outlined,
      ),
      (
        '06',
        'Kalite kontrol ve teslim',
        'Boyut, yüzey ve kapsam kontrollerinden sonra ürün teslim edilir; geri bildirim kaydedilir.',
        Icons.inventory_2_outlined,
      ),
    ];
    return LayoutBuilder(
      builder: (context, constraints) {
        final padding = constraints.maxWidth < 700 ? 16.0 : 28.0;
        return SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(padding, 24, padding, 48),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1050),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Bir fikir nasıl ürüne dönüşür?',
                    style: TextStyle(
                      fontSize: 30,
                      fontWeight: FontWeight.w700,
                      color: DmlColors.ink,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Teknik yöntemi sizin seçmeniz gerekmez. DML süreci, klinik veya akademik ihtiyacınızdan başlayarak anlaşılır onay noktalarıyla ilerler.',
                    style: TextStyle(color: DmlColors.slate, height: 1.5),
                  ),
                  const SizedBox(height: 26),
                  ...steps.map(
                    (step) => Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: DmlColors.mist),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SizedBox(
                            width: 50,
                            child: Text(
                              step.$1,
                              style: const TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.w800,
                                color: DmlColors.accent,
                              ),
                            ),
                          ),
                          Container(
                            width: 46,
                            height: 46,
                            decoration: BoxDecoration(
                              color: DmlColors.ink,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(step.$4, color: Colors.white),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  step.$2,
                                  style: const TextStyle(
                                    fontSize: 17,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                const SizedBox(height: 5),
                                Text(
                                  step.$3,
                                  style: const TextStyle(
                                    color: DmlColors.slate,
                                    height: 1.45,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  ElevatedButton.icon(
                    onPressed: onRequestTap,
                    icon: const Icon(Icons.arrow_forward),
                    label: const Text('Talebinizi anlatmaya başlayın'),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
