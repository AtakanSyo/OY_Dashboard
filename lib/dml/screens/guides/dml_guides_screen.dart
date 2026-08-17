import 'package:flutter/material.dart';
import 'package:oy_site/dml/app/dml_theme.dart';

class DmlGuidesScreen extends StatefulWidget {
  final VoidCallback onRequestTap;

  const DmlGuidesScreen({super.key, required this.onRequestTap});

  @override
  State<DmlGuidesScreen> createState() => _DmlGuidesScreenState();
}

class _DmlGuidesScreenState extends State<DmlGuidesScreen> {
  static const _guides = <({String category, String title, String summary, IconData icon, List<String> points})>[
    (
      category: 'Medikal görüntü',
      title: 'DICOM nedir?',
      summary:
          'CT ve MR görüntülerinin hangi biçimde saklandığını ve paylaşım öncesi temel kontrolleri öğrenin.',
      icon: Icons.folder_copy_outlined,
      points: [
        'Tek bir görüntü yerine aynı çekime ait seri dosyaları birlikte saklayın.',
        'Dosyaları yeniden adlandırmak veya yalnızca birkaç kesit seçmek veri bütünlüğünü bozabilir.',
        'Paylaşım öncesinde kurumunuzun kişisel sağlık verisi ve anonimleştirme kurallarına uyun.',
      ],
    ),
    (
      category: 'Medikal görüntü',
      title: 'CT verisi modele nasıl dönüşür?',
      summary:
          'Görüntü kontrolünden segmentasyon ve üretime uzanan temel adımları görün.',
      icon: Icons.view_in_ar_outlined,
      points: [
        'Görüntü kalitesi ve hedef anatomik yapı değerlendirilir.',
        'İlgili yapı kesitlerden ayrıştırılarak üç boyutlu geometri oluşturulur.',
        'Uzman onayından sonra model üretime hazırlanır ve kalite kontrol edilir.',
      ],
    ),
    (
      category: 'Talep hazırlığı',
      title: 'İyi bir talep nasıl hazırlanır?',
      summary:
          'DML ekibinin ihtiyacınızı daha hızlı değerlendirebilmesi için kısa kontrol listesi.',
      icon: Icons.fact_check_outlined,
      points: [
        'Modelin eğitim, planlama, araştırma veya prototipleme amacını açıklayın.',
        'İlgili anatomik bölgeyi ve varsa kritik yapıları belirtin.',
        'Teslim tarihi, ölçek, renk ve malzeme beklentinizi ekleyin.',
      ],
    ),
    (
      category: 'Üretim',
      title: 'FDM, SLA veya CNC?',
      summary:
          'Yöntem seçimini teknik terimler yerine kullanım amacına göre anlayın.',
      icon: Icons.precision_manufacturing_outlined,
      points: [
        'FDM, dayanıklı ve ekonomik büyük parçalar için uygundur.',
        'SLA, küçük detaylar ve yüksek yüzey kalitesi gerektiğinde öne çıkar.',
        'CNC, levha veya blok malzemeden hassas ve tekrarlanabilir parça üretir.',
      ],
    ),
    (
      category: 'Araştırma',
      title: 'Araştırma aparatından önce',
      summary:
          'Deney aparatları ve özel prototipler için paylaşılması yararlı bilgileri inceleyin.',
      icon: Icons.science_outlined,
      points: [
        'Numune boyutlarını, yük yönlerini ve bağlantı noktalarını tanımlayın.',
        'Tekrar sayısı, çalışma ortamı ve temas edecek malzemeleri belirtin.',
        'Varsa çizim, fotoğraf ve deney düzeneği şemasını ekleyin.',
      ],
    ),
  ];

  String _query = '';
  String _category = 'Tümü';

  @override
  Widget build(BuildContext context) {
    final categories = [
      'Tümü',
      ...{for (final guide in _guides) guide.category},
    ];
    final filtered = _guides.where((guide) {
      final query = _query.trim().toLowerCase();
      return (_category == 'Tümü' || guide.category == _category) &&
          (query.isEmpty ||
              '${guide.title} ${guide.summary}'.toLowerCase().contains(query));
    }).toList();
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
                    'Rehber ve öğrenme merkezi',
                    style: TextStyle(
                      fontSize: 30,
                      fontWeight: FontWeight.w700,
                      color: DmlColors.ink,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Teknik deneyiminiz olmasa da doğru veriyi hazırlamanıza ve uygun üretim yolunu anlamanıza yardımcı olan kısa rehberler.',
                    style: TextStyle(color: DmlColors.slate, height: 1.5),
                  ),
                  const SizedBox(height: 22),
                  TextField(
                    onChanged: (value) => setState(() => _query = value),
                    decoration: const InputDecoration(
                      prefixIcon: Icon(Icons.search),
                      hintText: 'Rehberlerde ara',
                    ),
                  ),
                  const SizedBox(height: 14),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: categories
                          .map(
                            (category) => Padding(
                              padding: const EdgeInsets.only(right: 8),
                              child: ChoiceChip(
                                label: Text(category),
                                selected: category == _category,
                                onSelected: (_) =>
                                    setState(() => _category = category),
                              ),
                            ),
                          )
                          .toList(),
                    ),
                  ),
                  const SizedBox(height: 18),
                  ...filtered.map((guide) => _GuideCard(guide: guide)),
                  const SizedBox(height: 16),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(22),
                    decoration: BoxDecoration(
                      color: DmlColors.ink,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Wrap(
                      alignment: WrapAlignment.spaceBetween,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      spacing: 20,
                      runSpacing: 14,
                      children: [
                        const SizedBox(
                          width: 570,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Hangi hizmete ihtiyacınız olduğundan emin değil misiniz?',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              SizedBox(height: 6),
                              Text(
                                'İhtiyacınızı kendi kelimelerinizle anlatın; DML ekibi uygun akışı birlikte belirlesin.',
                                style: TextStyle(
                                  color: DmlColors.accent,
                                  height: 1.4,
                                ),
                              ),
                            ],
                          ),
                        ),
                        ElevatedButton(
                          onPressed: widget.onRequestTap,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: DmlColors.ink,
                          ),
                          child: const Text('Yönlendirme iste'),
                        ),
                      ],
                    ),
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

class _GuideCard extends StatelessWidget {
  final ({
    String category,
    String title,
    String summary,
    IconData icon,
    List<String> points,
  })
  guide;
  const _GuideCard({required this.guide});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: const BorderSide(color: DmlColors.mist),
      ),
      child: ExpansionTile(
        leading: CircleAvatar(
          backgroundColor: DmlColors.mist,
          foregroundColor: DmlColors.ink,
          child: Icon(guide.icon),
        ),
        title: Text(
          guide.title,
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Text(
            guide.summary,
            style: const TextStyle(color: DmlColors.slate),
          ),
        ),
        childrenPadding: const EdgeInsets.fromLTRB(72, 0, 20, 20),
        expandedCrossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            guide.category.toUpperCase(),
            style: const TextStyle(
              fontSize: 10,
              letterSpacing: 1,
              fontWeight: FontWeight.w700,
              color: DmlColors.slate,
            ),
          ),
          const SizedBox(height: 10),
          ...guide.points.map(
            (point) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(
                    Icons.check_circle_outline,
                    size: 18,
                    color: DmlColors.slate,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(point, style: const TextStyle(height: 1.4)),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
