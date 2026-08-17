import 'package:flutter/material.dart';
import 'package:oy_site/dml/app/dml_theme.dart';
import 'package:oy_site/dml/data/mock_dml_home_repository.dart';
import 'package:oy_site/dml/models/dml_home_data.dart';

class DmlHomeScreen extends StatefulWidget {
  final VoidCallback onCatalogTap;
  final VoidCallback onCustomRequestTap;
  final VoidCallback onCasesTap;
  final VoidCallback onHelpTap;

  const DmlHomeScreen({
    super.key,
    required this.onCatalogTap,
    required this.onCustomRequestTap,
    required this.onCasesTap,
    required this.onHelpTap,
  });

  @override
  State<DmlHomeScreen> createState() => _DmlHomeScreenState();
}

class _DmlHomeScreenState extends State<DmlHomeScreen> {
  final _repository = MockDmlHomeRepository();
  late final Future<DmlHomeData> _dataFuture = _repository.getHomeData();

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<DmlHomeData>(
      future: _dataFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError || !snapshot.hasData) {
          return const Center(child: Text('DML içerikleri yüklenemedi.'));
        }
        return _buildContent(snapshot.data!);
      },
    );
  }

  Widget _buildContent(DmlHomeData data) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final padding = constraints.maxWidth < 700 ? 18.0 : 32.0;
        return SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(padding, 26, padding, 48),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1280),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHero(constraints.maxWidth),
                  const SizedBox(height: 54),
                  _sectionTitle(
                    eyebrow: 'DML İLE NELER YAPABİLİRSİNİZ?',
                    title: 'İhtiyacınızdan üretime uzanan bütüncül destek',
                    description:
                        'Teknik üretim yöntemi seçmek zorunda değilsiniz. Amacınızı anlatın, uygun süreci birlikte planlayalım.',
                  ),
                  const SizedBox(height: 24),
                  _buildCapabilities(data.capabilities),
                  const SizedBox(height: 58),
                  _buildGuidanceBanner(),
                  const SizedBox(height: 58),
                  _sectionTitle(
                    eyebrow: 'SÜREÇ NASIL İŞLİYOR?',
                    title: 'Karmaşık teknolojiler, anlaşılır bir iş akışı',
                    description:
                        'Talebinizin hangi aşamada olduğunu her zaman görebileceğiniz yönlendirilmiş bir süreç.',
                  ),
                  const SizedBox(height: 26),
                  _buildWorkflow(data.workflowSteps),
                  const SizedBox(height: 58),
                  Row(
                    children: [
                      Expanded(
                        child: _sectionTitle(
                          eyebrow: 'VAKA ÇALIŞMALARI',
                          title: 'Dijital üretimin uygulamadaki karşılığı',
                          description:
                              'Geçmiş çalışmalarımızdan seçilmiş örnek süreçler.',
                        ),
                      ),
                      if (constraints.maxWidth >= 720)
                        TextButton.icon(
                          onPressed: widget.onCasesTap,
                          icon: const Icon(Icons.arrow_forward),
                          label: const Text('Tüm vakaları incele'),
                        ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  _buildCases(data.caseStudies),
                  const SizedBox(height: 58),
                  _buildAboutBand(),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildHero(double width) {
    final compact = width < 850;
    final copy = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Text(
          'İZMİR TINAZTEPE ÜNİVERSİTESİ',
          style: TextStyle(
            color: DmlColors.accent,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.5,
            fontSize: 12,
          ),
        ),
        const SizedBox(height: 18),
        Text(
          'Fikrinizi dijital üretimle gerçeğe dönüştürün.',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w700,
            height: 1.08,
            fontSize: compact ? 34 : 47,
          ),
        ),
        const SizedBox(height: 18),
        const Text(
          'Medikal görüntülerden anatomik modellere, araştırma prototiplerinden eğitim araçlarına kadar üretim yolculuğunuzda yanınızdayız.',
          style: TextStyle(
            color: Color(0xFFD2DCDD),
            fontSize: 16,
            height: 1.55,
          ),
        ),
        const SizedBox(height: 28),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            ElevatedButton.icon(
              onPressed: widget.onCustomRequestTap,
              icon: const Icon(Icons.add_circle_outline),
              label: const Text('Özel model talebi oluştur'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: DmlColors.ink,
              ),
            ),
            OutlinedButton.icon(
              onPressed: widget.onCatalogTap,
              icon: const Icon(Icons.grid_view_outlined),
              label: const Text('Hazır modelleri incele'),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.white,
                side: const BorderSide(color: DmlColors.accent),
              ),
            ),
          ],
        ),
        const SizedBox(height: 18),
        TextButton.icon(
          onPressed: widget.onHelpTap,
          icon: const Icon(Icons.help_outline, size: 19),
          label: const Text('Nereden başlayacağımı bilmiyorum'),
          style: TextButton.styleFrom(foregroundColor: DmlColors.accent),
        ),
      ],
    );

    final logo = Container(
      constraints: const BoxConstraints(maxHeight: 280),
      padding: const EdgeInsets.all(18),
      child: Image.asset('assets/images/dml/dml_logo.png', fit: BoxFit.contain),
    );

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(compact ? 26 : 46),
      decoration: BoxDecoration(
        color: DmlColors.ink,
        borderRadius: BorderRadius.circular(24),
        boxShadow: const [
          BoxShadow(
            color: Color(0x26000000),
            blurRadius: 26,
            offset: Offset(0, 12),
          ),
        ],
      ),
      child: compact
          ? copy
          : Row(
              children: [
                Expanded(flex: 6, child: copy),
                const SizedBox(width: 34),
                Expanded(flex: 4, child: logo),
              ],
            ),
    );
  }

  Widget _buildCapabilities(List<DmlCapability> capabilities) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth >= 980
            ? 4
            : constraints.maxWidth >= 600
            ? 2
            : 1;
        final cardWidth =
            (constraints.maxWidth - ((columns - 1) * 16)) / columns;
        return Wrap(
          spacing: 16,
          runSpacing: 16,
          children: capabilities.map((item) {
            return Container(
              width: cardWidth,
              constraints: const BoxConstraints(minHeight: 205),
              padding: const EdgeInsets.all(22),
              decoration: _cardDecoration(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: DmlColors.ink,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(item.icon, color: Colors.white),
                  ),
                  const SizedBox(height: 22),
                  Text(
                    item.title,
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 9),
                  Text(
                    item.description,
                    style: const TextStyle(
                      color: DmlColors.slate,
                      height: 1.45,
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        );
      },
    );
  }

  Widget _buildGuidanceBanner() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: const Color(0xFFE9EEEE),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Wrap(
        alignment: WrapAlignment.spaceBetween,
        crossAxisAlignment: WrapCrossAlignment.center,
        spacing: 28,
        runSpacing: 20,
        children: [
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 720),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.lightbulb_outline, size: 34, color: DmlColors.ink),
                SizedBox(width: 16),
                Flexible(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Teknik ayrıntıları bilmeniz gerekmiyor.',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      SizedBox(height: 7),
                      Text(
                        'Kullanım amacınızı ve elinizdeki verileri paylaşın. Uygun malzeme ve üretim yöntemini DML ekibi değerlendirsin.',
                        style: TextStyle(color: DmlColors.slate, height: 1.45),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          OutlinedButton.icon(
            onPressed: widget.onHelpTap,
            icon: const Icon(Icons.route_outlined),
            label: const Text('Beni yönlendirin'),
          ),
        ],
      ),
    );
  }

  Widget _buildWorkflow(List<String> steps) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final vertical = constraints.maxWidth < 760;
        if (vertical) {
          return Column(
            children: List.generate(steps.length, (index) {
              return _workflowStep(index, steps[index], vertical: true);
            }),
          );
        }
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: List.generate(steps.length, (index) {
            return Expanded(
              child: _workflowStep(index, steps[index], vertical: false),
            );
          }),
        );
      },
    );
  }

  Widget _workflowStep(int index, String title, {required bool vertical}) {
    final number = Container(
      width: 38,
      height: 38,
      alignment: Alignment.center,
      decoration: const BoxDecoration(
        color: DmlColors.ink,
        shape: BoxShape.circle,
      ),
      child: Text(
        '${index + 1}',
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w700,
        ),
      ),
    );

    if (vertical) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Row(
          children: [
            number,
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
      );
    }
    return Column(
      children: [
        number,
        const SizedBox(height: 12),
        Text(
          title,
          textAlign: TextAlign.center,
          style: const TextStyle(fontWeight: FontWeight.w600, height: 1.35),
        ),
      ],
    );
  }

  Widget _buildCases(List<DmlCaseStudy> cases) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth >= 900 ? 3 : 1;
        final cardWidth =
            (constraints.maxWidth - ((columns - 1) * 16)) / columns;
        return Wrap(
          spacing: 16,
          runSpacing: 16,
          children: cases.map((item) {
            return Container(
              width: cardWidth,
              padding: const EdgeInsets.all(22),
              decoration: _cardDecoration(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.category.toUpperCase(),
                    style: const TextStyle(
                      color: DmlColors.slate,
                      fontSize: 11,
                      letterSpacing: 1.1,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    item.title,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    item.description,
                    style: const TextStyle(
                      color: DmlColors.slate,
                      height: 1.45,
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Divider(),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      const Icon(Icons.build_outlined, size: 17),
                      const SizedBox(width: 7),
                      Expanded(
                        child: Text(
                          item.method,
                          style: const TextStyle(fontSize: 12),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          }).toList(),
        );
      },
    );
  }

  Widget _buildAboutBand() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: DmlColors.inkSoft,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Wrap(
        alignment: WrapAlignment.spaceBetween,
        crossAxisAlignment: WrapCrossAlignment.center,
        spacing: 30,
        runSpacing: 24,
        children: [
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 760),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Üniversite, sağlık ve üretim aynı platformda.',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 25,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                SizedBox(height: 10),
                Text(
                  'İZTÜ Dijital Üretim Laboratuvarı; uzmanların, araştırmacıların ve öğrencilerin fikirlerini güvenilir üretim süreçleriyle buluşturur.',
                  style: TextStyle(color: Color(0xFFD3DDDE), height: 1.5),
                ),
              ],
            ),
          ),
          ElevatedButton(
            onPressed: widget.onHelpTap,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: DmlColors.ink,
            ),
            child: const Text('Laboratuvarı keşfet'),
          ),
        ],
      ),
    );
  }

  Widget _sectionTitle({
    required String eyebrow,
    required String title,
    required String description,
  }) {
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 780),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            eyebrow,
            style: const TextStyle(
              color: DmlColors.slate,
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.35,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            title,
            style: const TextStyle(
              color: DmlColors.ink,
              fontSize: 28,
              height: 1.2,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            description,
            style: const TextStyle(
              color: DmlColors.slate,
              fontSize: 15,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  BoxDecoration _cardDecoration() {
    return BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: DmlColors.mist),
      boxShadow: const [
        BoxShadow(
          color: Color(0x09000000),
          blurRadius: 14,
          offset: Offset(0, 5),
        ),
      ],
    );
  }
}
