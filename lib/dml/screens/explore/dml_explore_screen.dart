import 'package:flutter/material.dart';
import 'package:oy_site/dml/app/dml_theme.dart';
import 'package:oy_site/dml/data/mock_dml_explore_repository.dart';
import 'package:oy_site/dml/models/dml_explore_item.dart';

enum _ExploreTab { services, methods }

class DmlExploreScreen extends StatefulWidget {
  final VoidCallback onRequestTap;

  const DmlExploreScreen({super.key, required this.onRequestTap});

  @override
  State<DmlExploreScreen> createState() => _DmlExploreScreenState();
}

class _DmlExploreScreenState extends State<DmlExploreScreen> {
  final _repository = MockDmlExploreRepository();
  late final Future<DmlExploreData> _dataFuture = _repository.getData();
  _ExploreTab _tab = _ExploreTab.services;
  DmlServiceItem? _selectedService;
  DmlProductionMethod? _selectedMethod;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<DmlExploreData>(
      future: _dataFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Center(child: CircularProgressIndicator());
        }
        if (!snapshot.hasData || snapshot.hasError) {
          return const Center(child: Text('Keşfet içerikleri yüklenemedi.'));
        }
        if (_selectedService != null) {
          return _buildServiceDetail(_selectedService!);
        }
        if (_selectedMethod != null) {
          return _buildMethodDetail(_selectedMethod!);
        }
        return _buildHub(snapshot.data!);
      },
    );
  }

  Widget _buildHub(DmlExploreData data) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final padding = constraints.maxWidth < 700 ? 16.0 : 28.0;
        return SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(padding, 24, padding, 46),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1220),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'DML’yi keşfedin',
                    style: TextStyle(
                      color: DmlColors.ink,
                      fontSize: 30,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'İhtiyacınıza uygun hizmetleri ve bu hizmetlerin arkasındaki üretim yöntemlerini anlaşılır biçimde inceleyin.',
                    style: TextStyle(
                      color: DmlColors.slate,
                      fontSize: 15,
                      height: 1.45,
                    ),
                  ),
                  const SizedBox(height: 24),
                  SegmentedButton<_ExploreTab>(
                    segments: const [
                      ButtonSegment(
                        value: _ExploreTab.services,
                        icon: Icon(Icons.design_services_outlined),
                        label: Text('Neler Yapabiliriz?'),
                      ),
                      ButtonSegment(
                        value: _ExploreTab.methods,
                        icon: Icon(Icons.precision_manufacturing_outlined),
                        label: Text('Üretim Altyapısı ve Yöntemleri'),
                      ),
                    ],
                    selected: {_tab},
                    onSelectionChanged: (value) =>
                        setState(() => _tab = value.first),
                  ),
                  const SizedBox(height: 26),
                  if (_tab == _ExploreTab.services)
                    _buildServices(data.services, constraints.maxWidth)
                  else
                    _buildMethods(data.methods, constraints.maxWidth),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildServices(List<DmlServiceItem> services, double width) {
    final columns = width >= 1000
        ? 3
        : width >= 650
        ? 2
        : 1;
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: services.length,
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: columns,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: columns == 1 ? 1.25 : .8,
      ),
      itemBuilder: (context, index) {
        final service = services[index];
        return _ImageCard(
          imagePath: service.imagePath,
          eyebrow: service.id,
          title: service.title,
          description: service.summary,
          footer: service.audience,
          onTap: () => setState(() => _selectedService = service),
        );
      },
    );
  }

  Widget _buildMethods(List<DmlProductionMethod> methods, double width) {
    final columns = width >= 950
        ? 3
        : width >= 620
        ? 2
        : 1;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _MethodIntro(),
        const SizedBox(height: 22),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: methods.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: columns,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            childAspectRatio: columns == 1 ? 1.2 : .75,
          ),
          itemBuilder: (context, index) {
            final method = methods[index];
            return _ImageCard(
              imagePath: method.imagePath,
              eyebrow: method.fullName,
              title: method.title,
              description: method.summary,
              footer: method.materials.take(3).join(' · '),
              onTap: () => setState(() => _selectedMethod = method),
            );
          },
        ),
      ],
    );
  }

  Widget _buildServiceDetail(DmlServiceItem item) {
    return _DetailFrame(
      onBack: () => setState(() => _selectedService = null),
      backLabel: 'Hizmetlere dön',
      imagePath: item.imagePath,
      eyebrow: item.id,
      title: item.title,
      summary: item.summary,
      action: ElevatedButton.icon(
        onPressed: widget.onRequestTap,
        icon: const Icon(Icons.add_box_outlined),
        label: const Text('Bu hizmet için talep oluştur'),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _InfoGrid(
            items: [
              ('Kimler için?', item.audience, Icons.groups_outlined),
              (
                'Başlangıçta ne gerekir?',
                item.requiredInput,
                Icons.upload_file_outlined,
              ),
              (
                'Ne teslim edilir?',
                item.deliverable,
                Icons.inventory_2_outlined,
              ),
              ('Süre', item.duration, Icons.schedule_outlined),
            ],
          ),
          const SizedBox(height: 28),
          const _SectionTitle('Hizmet süreci'),
          const SizedBox(height: 16),
          ...item.processSteps.asMap().entries.map(
            (entry) => _ProcessRow(number: entry.key + 1, title: entry.value),
          ),
          const SizedBox(height: 25),
          const _SectionTitle('Kullanılabilecek üretim yöntemleri'),
          const SizedBox(height: 12),
          Wrap(
            spacing: 9,
            runSpacing: 9,
            children: item.relatedMethods
                .map(
                  (method) => Chip(
                    avatar: const Icon(
                      Icons.precision_manufacturing_outlined,
                      size: 17,
                    ),
                    label: Text(method),
                  ),
                )
                .toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildMethodDetail(DmlProductionMethod item) {
    return _DetailFrame(
      onBack: () => setState(() => _selectedMethod = null),
      backLabel: 'Üretim yöntemlerine dön',
      imagePath: item.imagePath,
      eyebrow: item.fullName,
      title: item.title,
      summary: item.summary,
      action: OutlinedButton.icon(
        onPressed: widget.onRequestTap,
        icon: const Icon(Icons.chat_bubble_outline),
        label: const Text('Projem için uygun mu?'),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SectionTitle('Nasıl çalışır?'),
          const SizedBox(height: 10),
          Text(
            item.workingPrinciple,
            style: const TextStyle(fontSize: 15, height: 1.55),
          ),
          const SizedBox(height: 26),
          LayoutBuilder(
            builder: (context, constraints) {
              final compact = constraints.maxWidth < 760;
              final sections = [
                _BulletSection(
                  title: 'Hangi işler için uygun?',
                  values: item.suitableFor,
                ),
                _BulletSection(title: 'Malzemeler', values: item.materials),
                _BulletSection(title: 'Güçlü yönleri', values: item.strengths),
                _BulletSection(
                  title: 'Dikkat edilmesi gerekenler',
                  values: item.considerations,
                ),
              ];
              if (compact) {
                return Column(
                  children: sections
                      .expand(
                        (section) => [section, const SizedBox(height: 14)],
                      )
                      .toList(),
                );
              }
              return Wrap(
                spacing: 16,
                runSpacing: 16,
                children: sections
                    .map(
                      (section) => SizedBox(
                        width: (constraints.maxWidth - 16) / 2,
                        child: section,
                      ),
                    )
                    .toList(),
              );
            },
          ),
          const SizedBox(height: 16),
          const _RepresentativeNotice(),
        ],
      ),
    );
  }
}

class _ImageCard extends StatelessWidget {
  final String imagePath;
  final String eyebrow;
  final String title;
  final String description;
  final String footer;
  final VoidCallback onTap;

  const _ImageCard({
    required this.imagePath,
    required this.eyebrow,
    required this.title,
    required this.description,
    required this.footer,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: DmlColors.mist),
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
                    imagePath,
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
                      eyebrow.toUpperCase(),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: DmlColors.slate,
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1,
                      ),
                    ),
                    const SizedBox(height: 7),
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      description,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: DmlColors.slate,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 14),
                    const Divider(),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            footer,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 11,
                              color: DmlColors.slate,
                            ),
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
  }
}

class _DetailFrame extends StatelessWidget {
  final VoidCallback onBack;
  final String backLabel;
  final String imagePath;
  final String eyebrow;
  final String title;
  final String summary;
  final Widget action;
  final Widget child;

  const _DetailFrame({
    required this.onBack,
    required this.backLabel,
    required this.imagePath,
    required this.eyebrow,
    required this.title,
    required this.summary,
    required this.action,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 840;
        final padding = constraints.maxWidth < 700 ? 16.0 : 28.0;
        final image = ClipRRect(
          borderRadius: BorderRadius.circular(18),
          child: AspectRatio(
            aspectRatio: 1.45,
            child: Image.asset(imagePath, fit: BoxFit.cover),
          ),
        );
        final intro = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              eyebrow.toUpperCase(),
              style: const TextStyle(
                color: DmlColors.slate,
                fontSize: 11,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.1,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              title,
              style: const TextStyle(
                color: DmlColors.ink,
                fontSize: 31,
                fontWeight: FontWeight.w700,
                height: 1.15,
              ),
            ),
            const SizedBox(height: 16),
            Text(summary, style: const TextStyle(fontSize: 15, height: 1.55)),
            const SizedBox(height: 22),
            action,
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
                    onPressed: onBack,
                    icon: const Icon(Icons.arrow_back),
                    label: Text(backLabel),
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
                  const SizedBox(height: 32),
                  child,
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _InfoGrid extends StatelessWidget {
  final List<(String, String, IconData)> items;

  const _InfoGrid({required this.items});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth >= 800
            ? 4
            : constraints.maxWidth >= 500
            ? 2
            : 1;
        final width = (constraints.maxWidth - ((columns - 1) * 12)) / columns;
        return Wrap(
          spacing: 12,
          runSpacing: 12,
          children: items
              .map(
                (item) => Container(
                  width: width,
                  constraints: const BoxConstraints(minHeight: 155),
                  padding: const EdgeInsets.all(17),
                  decoration: BoxDecoration(
                    color: DmlColors.surface,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(item.$3, color: DmlColors.ink),
                      const SizedBox(height: 13),
                      Text(
                        item.$1,
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        item.$2,
                        style: const TextStyle(
                          color: DmlColors.slate,
                          fontSize: 12,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
              )
              .toList(),
        );
      },
    );
  }
}

class _ProcessRow extends StatelessWidget {
  final int number;
  final String title;

  const _ProcessRow({required this.number, required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 11),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
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
            child: Text(
              title,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}

class _BulletSection extends StatelessWidget {
  final String title;
  final List<String> values;

  const _BulletSection({required this.title, required this.values});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(19),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: DmlColors.mist),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
          const SizedBox(height: 11),
          ...values.map(
            (value) => Padding(
              padding: const EdgeInsets.only(bottom: 7),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Padding(
                    padding: EdgeInsets.only(top: 5),
                    child: Icon(Icons.circle, size: 6, color: DmlColors.slate),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      value,
                      style: const TextStyle(color: DmlColors.slate),
                    ),
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

class _MethodIntro extends StatelessWidget {
  const _MethodIntro();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(21),
      decoration: BoxDecoration(
        color: const Color(0xFFE9EEEE),
        borderRadius: BorderRadius.circular(15),
      ),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.lightbulb_outline, color: DmlColors.ink),
          SizedBox(width: 12),
          Expanded(
            child: Text(
              'Üretim yöntemini sizin seçmeniz gerekmez. DML ekibi; kullanım amacı, geometri, malzeme, adet ve bütçeyi birlikte değerlendirerek uygun yöntemi önerir.',
              style: TextStyle(color: DmlColors.slate, height: 1.45),
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;

  const _SectionTitle(this.title);

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: const TextStyle(
        color: DmlColors.ink,
        fontSize: 21,
        fontWeight: FontWeight.w700,
      ),
    );
  }
}

class _RepresentativeNotice extends StatelessWidget {
  const _RepresentativeNotice();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: DmlColors.surface,
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.info_outline, size: 20, color: DmlColors.slate),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              'Görseller üretim yöntemini temsili olarak anlatır. Gerçek cihaz, malzeme ve proses parametreleri proje gereksinimine göre belirlenir.',
              style: TextStyle(color: DmlColors.slate, height: 1.4),
            ),
          ),
        ],
      ),
    );
  }
}
