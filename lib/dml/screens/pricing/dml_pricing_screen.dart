import 'package:flutter/material.dart';
import 'package:oy_site/dml/app/dml_theme.dart';

class DmlPricingScreen extends StatelessWidget {
  final VoidCallback onRequestTap;
  const DmlPricingScreen({super.key, required this.onRequestTap});

  @override
  Widget build(BuildContext context) {
    const groups = [
      (
        'Hazır anatomik modeller',
        'Katalog ürünü, ölçek ve malzeme seçimine göre',
        'Teklif ile',
        Icons.accessibility_new_outlined,
      ),
      (
        'Medikal görüntüden model',
        'Veri kontrolü, segmentasyon, uzman onayı ve üretim',
        'Vaka bazlı',
        Icons.medical_information_outlined,
      ),
      (
        '3D baskı hizmeti',
        'Malzeme, baskı süresi, hacim ve son işleme göre',
        'Dosya bazlı',
        Icons.view_in_ar_outlined,
      ),
      (
        'CNC işleme',
        'Malzeme, takım yolu, işleme süresi ve adet bilgisine göre',
        'Dosya bazlı',
        Icons.precision_manufacturing_outlined,
      ),
      (
        'Tasarım ve prototipleme',
        'Gereksinim analizi, modelleme ve iterasyon kapsamına göre',
        'Proje bazlı',
        Icons.design_services_outlined,
      ),
      (
        'Eğitim ve atölye',
        'Katılımcı sayısı, süre, içerik ve sarf malzemelerine göre',
        'Program bazlı',
        Icons.school_outlined,
      ),
    ];
    return LayoutBuilder(
      builder: (context, constraints) {
        final padding = constraints.maxWidth < 700 ? 16.0 : 28.0;
        return SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(padding, 24, padding, 48),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1100),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Hizmet ve fiyatlandırma',
                    style: TextStyle(
                      fontSize: 30,
                      fontWeight: FontWeight.w700,
                      color: DmlColors.ink,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Her çalışma farklı veri, hassasiyet ve üretim ihtiyacına sahip olabilir. Bu nedenle bu ilk sürümde sabit tutarlar yerine fiyatı belirleyen kapsamı açıkça gösteriyoruz.',
                    style: TextStyle(color: DmlColors.slate, height: 1.5),
                  ),
                  const SizedBox(height: 14),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE9EEEE),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(Icons.info_outline, color: DmlColors.ink),
                        SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'Buradaki ifadeler örnek fiyatlandırma yapısını gösterir; bağlayıcı teklif değildir. Nihai kapsam, veri kontrolü ve teknik değerlendirmeden sonra netleşir.',
                            style: TextStyle(height: 1.4),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 22),
                  ...groups.map(
                    (item) => Container(
                      margin: const EdgeInsets.only(bottom: 11),
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: DmlColors.mist),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              color: DmlColors.mist,
                              borderRadius: BorderRadius.circular(11),
                            ),
                            child: Icon(item.$4, color: DmlColors.ink),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  item.$1,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 16,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  item.$2,
                                  style: const TextStyle(
                                    color: DmlColors.slate,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),
                          Chip(label: Text(item.$3)),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'Teklif için yararlı bilgiler',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 10),
                  const Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: [
                      Chip(
                        avatar: Icon(Icons.check, size: 16),
                        label: Text('Kullanım amacı'),
                      ),
                      Chip(
                        avatar: Icon(Icons.check, size: 16),
                        label: Text('Dosya veya görüntü türü'),
                      ),
                      Chip(
                        avatar: Icon(Icons.check, size: 16),
                        label: Text('Adet ve yaklaşık ölçü'),
                      ),
                      Chip(
                        avatar: Icon(Icons.check, size: 16),
                        label: Text('Beklenen teslim tarihi'),
                      ),
                      Chip(
                        avatar: Icon(Icons.check, size: 16),
                        label: Text('Malzeme ve renk beklentisi'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton.icon(
                    onPressed: onRequestTap,
                    icon: const Icon(Icons.request_quote_outlined),
                    label: const Text('Kapsam değerlendirmesi iste'),
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
