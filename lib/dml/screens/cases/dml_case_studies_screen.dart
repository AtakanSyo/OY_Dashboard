import 'package:flutter/material.dart';
import 'package:oy_site/dml/app/dml_theme.dart';

class DmlCaseStudyItem {
  final String id;
  final String category;
  final String title;
  final String summary;
  final String imagePath;
  final String initialData;
  final String method;
  final String material;
  final String duration;
  final List<(String, String)> timeline;
  final String result;

  const DmlCaseStudyItem({
    required this.id,
    required this.category,
    required this.title,
    required this.summary,
    required this.imagePath,
    required this.initialData,
    required this.method,
    required this.material,
    required this.duration,
    required this.timeline,
    required this.result,
  });
}

class DmlCaseStudiesScreen extends StatefulWidget {
  final VoidCallback onRequestTap;

  const DmlCaseStudiesScreen({super.key, required this.onRequestTap});

  @override
  State<DmlCaseStudiesScreen> createState() => _DmlCaseStudiesScreenState();
}

class _DmlCaseStudiesScreenState extends State<DmlCaseStudiesScreen> {
  static const _items = [
    DmlCaseStudyItem(
      id: 'CASE-01',
      category: 'Cerrahi planlama',
      title: 'CT Verisinden Pelvis Planlama Modeli',
      summary:
          'Kemik geometrisinin vaka özelinde incelenmesi amacıyla dijital ve fiziksel pelvis modeli hazırlanmasına yönelik örnek senaryo.',
      imagePath: 'assets/images/dml/cases/pelvis_planning_case.png',
      initialData: 'Pelvis bölgesine ait CT/DICOM görüntü serisi',
      method: 'Medikal görüntü işleme + SLA baskı',
      material: 'Yüksek detaylı sert reçine',
      duration: 'Örnek süreç: 8 iş günü',
      timeline: [
        (
          'Görüntü kontrolü',
          'Kesit kalitesi ve hedef anatomik yapı değerlendirildi.',
        ),
        (
          'Dijital modelleme',
          'Kemik geometri ayrıştırıldı ve üretime hazırlandı.',
        ),
        (
          'Uzman kontrolü',
          'Model kapsamı ve ölçek seçenekleri değerlendirildi.',
        ),
        ('Üretim', 'Model reçine baskı ile üretildi, yıkandı ve kürlendi.'),
        ('Kalite kontrol', 'Geometri ve yüzey kontrolleri tamamlandı.'),
      ],
      result:
          'İlgili anatomik yapının fiziksel olarak incelenebilmesini sağlayan gerçek boyutlu temsili model elde edildi.',
    ),
    DmlCaseStudyItem(
      id: 'CASE-02',
      category: 'Anatomi eğitimi',
      title: 'Modüler Omurga Eğitim Seti',
      summary:
          'Öğrencilerin vertebra ve disk ilişkilerini parça bazında inceleyebilmesi için modüler eğitim seti geliştirilmesine yönelik örnek çalışma.',
      imagePath: 'assets/images/dml/cases/spine_education_case.png',
      initialData: 'Eğitim hedefleri ve örnek anatomik dijital modeller',
      method: 'FDM baskı + çok parçalı tasarım',
      material: 'PLA, TPU ve renkli parça bileşenleri',
      duration: 'Örnek süreç: 12 iş günü',
      timeline: [
        ('Eğitim kapsamı', 'Gösterilecek anatomik yapılar belirlendi.'),
        (
          'Modüler tasarım',
          'Parçaların ayrılıp tekrar birleştirilebilmesi planlandı.',
        ),
        ('Örnek üretim', 'Bağlantı toleransları ve renkler test edildi.'),
        ('Set üretimi', 'Model parçaları ve taşıma tablası üretildi.'),
        (
          'Kullanım değerlendirmesi',
          'Eğitim senaryosuna göre son düzenlemeler yapıldı.',
        ),
      ],
      result:
          'Farklı yapıların renk ve parça ayrımıyla incelenebildiği tekrar kullanılabilir eğitim seti oluşturuldu.',
    ),
    DmlCaseStudyItem(
      id: 'CASE-03',
      category: 'Akademik araştırma',
      title: 'Biyomekanik Deney Aparatı',
      summary:
          'Özel bir numunenin kontrollü biçimde sabitlenmesi ve tekrar eden deneylerde kullanılabilmesi için aparat geliştirilmesine yönelik örnek çalışma.',
      imagePath: 'assets/images/dml/cases/biomechanics_fixture_case.png',
      initialData: 'Deney planı, numune geometrisi, yük yönleri ve ölçüler',
      method: 'FDM prototipleme + CNC bileşenler',
      material: 'Mühendislik plastiği ve metal bağlantılar',
      duration: 'Örnek süreç: 15 iş günü',
      timeline: [
        ('Gereksinim analizi', 'Yük, tekrar ve ölçüm koşulları belirlendi.'),
        (
          'Konsept tasarım',
          'Numune bağlantısı ve ayar mekanizması modellendi.',
        ),
        ('Hızlı prototip', 'Geometri ve kullanım erişimi test edildi.'),
        ('İşlevsel üretim', 'Son bileşenler uygun yöntemlerle üretildi.'),
        ('Deney kontrolü', 'Montaj ve tekrar edilebilirlik değerlendirildi.'),
      ],
      result:
          'Numunenin kontrollü sabitlenmesini sağlayan, ayarlanabilir ve tekrar kullanılabilir deney aparatı elde edildi.',
    ),
  ];

  String _category = 'Tümü';
  DmlCaseStudyItem? _selected;

  @override
  Widget build(BuildContext context) {
    if (_selected != null) return _buildDetail(_selected!);
    return LayoutBuilder(
      builder: (context, constraints) {
        final padding = constraints.maxWidth < 700 ? 16.0 : 28.0;
        final categories = [
          'Tümü',
          ...{for (final item in _items) item.category},
        ];
        final filtered = _category == 'Tümü'
            ? _items
            : _items.where((item) => item.category == _category).toList();
        return SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(padding, 24, padding, 46),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1200),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Vaka çalışmaları',
                    style: TextStyle(
                      color: DmlColors.ink,
                      fontSize: 30,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Dijital üretim sürecinin farklı ihtiyaçlara nasıl uygulanabileceğini örnek senaryolar üzerinden inceleyin.',
                    style: TextStyle(
                      color: DmlColors.slate,
                      fontSize: 15,
                      height: 1.45,
                    ),
                  ),
                  const SizedBox(height: 12),
                  const _ExampleNotice(),
                  const SizedBox(height: 20),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: categories.map((category) {
                        final selected = category == _category;
                        return Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: ChoiceChip(
                            label: Text(category),
                            selected: selected,
                            onSelected: (_) =>
                                setState(() => _category = category),
                            selectedColor: DmlColors.ink,
                            labelStyle: TextStyle(
                              color: selected ? Colors.white : DmlColors.ink,
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                  const SizedBox(height: 20),
                  _buildGrid(filtered, constraints.maxWidth),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildGrid(List<DmlCaseStudyItem> items, double width) {
    final columns = width >= 1000
        ? 3
        : width >= 650
        ? 2
        : 1;
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: items.length,
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: columns,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: columns == 1 ? 1.25 : .78,
      ),
      itemBuilder: (context, index) {
        final item = items[index];
        return Material(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          child: InkWell(
            onTap: () => setState(() => _selected = item),
            borderRadius: BorderRadius.circular(16),
            child: Container(
              decoration: BoxDecoration(
                border: Border.all(color: DmlColors.mist),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: ClipRRect(
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(15),
                      ),
                      child: Image.asset(
                        item.imagePath,
                        width: double.infinity,
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(18),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.category.toUpperCase(),
                          style: const TextStyle(
                            color: DmlColors.slate,
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 1,
                          ),
                        ),
                        const SizedBox(height: 7),
                        Text(
                          item.title,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          item.summary,
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: DmlColors.slate,
                            height: 1.4,
                          ),
                        ),
                        const SizedBox(height: 13),
                        Row(
                          children: [
                            const Icon(
                              Icons.build_outlined,
                              size: 16,
                              color: DmlColors.slate,
                            ),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                item.method,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(fontSize: 11),
                              ),
                            ),
                            const Icon(Icons.arrow_forward, size: 18),
                          ],
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

  Widget _buildDetail(DmlCaseStudyItem item) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 840;
        final padding = constraints.maxWidth < 700 ? 16.0 : 28.0;
        final image = ClipRRect(
          borderRadius: BorderRadius.circular(18),
          child: AspectRatio(
            aspectRatio: 1.45,
            child: Image.asset(item.imagePath, fit: BoxFit.cover),
          ),
        );
        final intro = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              item.category.toUpperCase(),
              style: const TextStyle(
                color: DmlColors.slate,
                fontSize: 11,
                fontWeight: FontWeight.w700,
                letterSpacing: 1,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              item.title,
              style: const TextStyle(
                color: DmlColors.ink,
                fontSize: 30,
                fontWeight: FontWeight.w700,
                height: 1.15,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              item.summary,
              style: const TextStyle(fontSize: 15, height: 1.5),
            ),
            const SizedBox(height: 18),
            _meta(
              Icons.folder_open_outlined,
              'Başlangıç verisi',
              item.initialData,
            ),
            _meta(
              Icons.precision_manufacturing_outlined,
              'Yöntem',
              item.method,
            ),
            _meta(Icons.layers_outlined, 'Malzeme', item.material),
            _meta(Icons.schedule_outlined, 'Süre', item.duration),
          ],
        );
        return SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(padding, 20, padding, 46),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1150),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextButton.icon(
                    onPressed: () => setState(() => _selected = null),
                    icon: const Icon(Icons.arrow_back),
                    label: const Text('Vaka çalışmalarına dön'),
                  ),
                  const SizedBox(height: 14),
                  if (compact)
                    Column(children: [image, const SizedBox(height: 24), intro])
                  else
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(flex: 6, child: image),
                        const SizedBox(width: 34),
                        Expanded(flex: 5, child: intro),
                      ],
                    ),
                  const SizedBox(height: 30),
                  const Text(
                    'Örnek süreç',
                    style: TextStyle(fontSize: 21, fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 15),
                  ...item.timeline.asMap().entries.map(
                    (entry) => _TimelineRow(
                      number: entry.key + 1,
                      title: entry.value.$1,
                      description: entry.value.$2,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE9EEEE),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Sonuç',
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 7),
                        Text(
                          item.result,
                          style: const TextStyle(
                            color: DmlColors.slate,
                            height: 1.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton.icon(
                    onPressed: widget.onRequestTap,
                    icon: const Icon(Icons.add_box_outlined),
                    label: const Text('Benzer talep oluştur'),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _meta(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 19, color: DmlColors.slate),
          const SizedBox(width: 9),
          SizedBox(
            width: 105,
            child: Text(label, style: const TextStyle(color: DmlColors.slate)),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}

class _TimelineRow extends StatelessWidget {
  final int number;
  final String title;
  final String description;

  const _TimelineRow({
    required this.number,
    required this.title,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 34,
            height: 34,
            alignment: Alignment.center,
            decoration: const BoxDecoration(
              color: DmlColors.ink,
              shape: BoxShape.circle,
            ),
            child: Text(
              '$number',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: const TextStyle(color: DmlColors.slate, height: 1.4),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ExampleNotice extends StatelessWidget {
  const _ExampleNotice();

  @override
  Widget build(BuildContext context) {
    return const Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(Icons.info_outline, size: 18, color: DmlColors.slate),
        SizedBox(width: 8),
        Expanded(
          child: Text(
            'Bu bölümdeki çalışmalar ve görseller platform tasarımını doğrulamak için hazırlanmış temsili örnek senaryolardır.',
            style: TextStyle(color: DmlColors.slate, fontSize: 12),
          ),
        ),
      ],
    );
  }
}
