import 'package:flutter/material.dart';
import 'package:oy_site/dml/app/dml_theme.dart';
import 'package:oy_site/dml/data/mock_dml_catalog_repository.dart';
import 'package:oy_site/dml/models/dml_catalog_item.dart';

class DmlCatalogScreen extends StatefulWidget {
  final VoidCallback onRequestTap;

  const DmlCatalogScreen({super.key, required this.onRequestTap});

  @override
  State<DmlCatalogScreen> createState() => _DmlCatalogScreenState();
}

class _DmlCatalogScreenState extends State<DmlCatalogScreen> {
  final _repository = MockDmlCatalogRepository();
  final _searchController = TextEditingController();
  late final Future<List<DmlCatalogItem>> _itemsFuture = _repository.getItems();
  String _category = 'Tümü';
  DmlCatalogItem? _selectedItem;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<DmlCatalogItem>>(
      future: _itemsFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Center(child: CircularProgressIndicator());
        }
        if (!snapshot.hasData || snapshot.hasError) {
          return const Center(child: Text('Katalog bilgileri yüklenemedi.'));
        }
        if (_selectedItem != null) return _buildDetail(_selectedItem!);
        return _buildCatalog(snapshot.data!);
      },
    );
  }

  Widget _buildCatalog(List<DmlCatalogItem> allItems) {
    final query = _searchController.text.trim().toLowerCase();
    final items = allItems.where((item) {
      final matchesCategory = _category == 'Tümü' || item.category == _category;
      final matchesQuery =
          query.isEmpty ||
          item.name.toLowerCase().contains(query) ||
          item.category.toLowerCase().contains(query) ||
          item.useCases.any((use) => use.toLowerCase().contains(query));
      return matchesCategory && matchesQuery;
    }).toList();
    final categories = [
      'Tümü',
      ...{for (final item in allItems) item.category},
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final padding = constraints.maxWidth < 700 ? 16.0 : 28.0;
        return SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(padding, 24, padding, 44),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1220),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Anatomik model kataloğu',
                    style: TextStyle(
                      color: DmlColors.ink,
                      fontSize: 30,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Eğitim, araştırma ve demonstrasyon amaçlı temsili model seçeneklerini inceleyin.',
                    style: TextStyle(color: DmlColors.slate, fontSize: 15),
                  ),
                  const SizedBox(height: 24),
                  TextField(
                    controller: _searchController,
                    onChanged: (_) => setState(() {}),
                    decoration: InputDecoration(
                      hintText: 'Model, anatomik bölge veya kullanım amacı ara',
                      prefixIcon: const Icon(Icons.search),
                      suffixIcon: query.isEmpty
                          ? null
                          : IconButton(
                              onPressed: () {
                                _searchController.clear();
                                setState(() {});
                              },
                              icon: const Icon(Icons.close),
                            ),
                    ),
                  ),
                  const SizedBox(height: 16),
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
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                  const SizedBox(height: 18),
                  Text(
                    '${items.length} model gösteriliyor',
                    style: const TextStyle(color: DmlColors.slate),
                  ),
                  const SizedBox(height: 14),
                  if (items.isEmpty)
                    _buildEmptyState()
                  else
                    _buildGrid(items, constraints.maxWidth),
                  const SizedBox(height: 28),
                  _buildCustomModelBanner(),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildGrid(List<DmlCatalogItem> items, double availableWidth) {
    final columns = availableWidth >= 1050
        ? 3
        : availableWidth >= 650
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
        childAspectRatio: columns == 1 ? 1.2 : .76,
      ),
      itemBuilder: (context, index) => _buildModelCard(items[index]),
    );
  }

  Widget _buildModelCard(DmlCatalogItem item) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: () => setState(() => _selectedItem = item),
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
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      Image.asset(item.imagePath, fit: BoxFit.cover),
                      Positioned(
                        left: 12,
                        top: 12,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 9,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: DmlColors.ink.withValues(alpha: .9),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Text(
                            item.category,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.id,
                      style: const TextStyle(
                        color: DmlColors.slate,
                        fontSize: 11,
                        letterSpacing: .6,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      item.name,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      item.shortDescription,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: DmlColors.slate,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        const Icon(
                          Icons.schedule_outlined,
                          size: 17,
                          color: DmlColors.slate,
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            item.productionTime,
                            style: const TextStyle(fontSize: 12),
                          ),
                        ),
                        const Icon(Icons.arrow_forward, size: 19),
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

  Widget _buildDetail(DmlCatalogItem item) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 820;
        final padding = constraints.maxWidth < 700 ? 16.0 : 28.0;
        final image = ClipRRect(
          borderRadius: BorderRadius.circular(18),
          child: AspectRatio(
            aspectRatio: 1,
            child: Image.asset(item.imagePath, fit: BoxFit.cover),
          ),
        );
        final info = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              item.category.toUpperCase(),
              style: const TextStyle(
                color: DmlColors.slate,
                fontSize: 11,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.2,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              item.name,
              style: const TextStyle(
                color: DmlColors.ink,
                fontSize: 31,
                fontWeight: FontWeight.w700,
                height: 1.15,
              ),
            ),
            const SizedBox(height: 9),
            Text(item.id, style: const TextStyle(color: DmlColors.slate)),
            const SizedBox(height: 20),
            Text(
              item.description,
              style: const TextStyle(fontSize: 15, height: 1.55),
            ),
            const SizedBox(height: 20),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: item.useCases
                  .map((use) => Chip(label: Text(use)))
                  .toList(),
            ),
            const SizedBox(height: 22),
            _detailLine(
              Icons.schedule_outlined,
              'Tahmini üretim',
              item.productionTime,
            ),
            _detailLine(
              Icons.payments_outlined,
              'Fiyatlandırma',
              item.priceLabel,
            ),
            _detailLine(
              Icons.tune_outlined,
              'Özelleştirme',
              item.customizable ? 'Uygun' : 'Standart model',
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: widget.onRequestTap,
                icon: const Icon(Icons.add_box_outlined),
                label: const Text('Bu model için talep oluştur'),
              ),
            ),
          ],
        );
        return SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(padding, 20, padding, 44),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1150),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextButton.icon(
                    onPressed: () => setState(() => _selectedItem = null),
                    icon: const Icon(Icons.arrow_back),
                    label: const Text('Kataloğa dön'),
                  ),
                  const SizedBox(height: 14),
                  if (compact)
                    Column(children: [image, const SizedBox(height: 24), info])
                  else
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(child: image),
                        const SizedBox(width: 36),
                        Expanded(child: info),
                      ],
                    ),
                  const SizedBox(height: 30),
                  _buildSpecifications(item),
                  const SizedBox(height: 14),
                  const _RepresentativeVisualNotice(),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildSpecifications(DmlCatalogItem item) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 700;
        final sections = [
          _specSection('İçerdiği yapılar', item.includedStructures),
          _specSection('Malzeme seçenekleri', item.materials),
          _specSection('Ölçek seçenekleri', item.scaleOptions),
        ];
        return Container(
          width: double.infinity,
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: DmlColors.mist),
          ),
          child: compact
              ? Column(
                  children: sections
                      .expand(
                        (section) => [section, const SizedBox(height: 18)],
                      )
                      .toList(),
                )
              : Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(child: sections[0]),
                    const SizedBox(width: 24),
                    Expanded(child: sections[1]),
                    const SizedBox(width: 24),
                    Expanded(child: sections[2]),
                  ],
                ),
        );
      },
    );
  }

  Widget _specSection(String title, List<String> values) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
        const SizedBox(height: 10),
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
    );
  }

  Widget _detailLine(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: DmlColors.slate),
          const SizedBox(width: 10),
          SizedBox(
            width: 110,
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

  Widget _buildEmptyState() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(44),
      alignment: Alignment.center,
      child: const Column(
        children: [
          Icon(Icons.search_off, size: 46, color: DmlColors.slate),
          SizedBox(height: 12),
          Text(
            'Aramanızla eşleşen model bulunamadı',
            style: TextStyle(fontWeight: FontWeight.w700),
          ),
          SizedBox(height: 5),
          Text(
            'Filtreleri değiştirin veya özel model talebi oluşturun.',
            style: TextStyle(color: DmlColors.slate),
          ),
        ],
      ),
    );
  }

  Widget _buildCustomModelBanner() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: DmlColors.ink,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Wrap(
        alignment: WrapAlignment.spaceBetween,
        crossAxisAlignment: WrapCrossAlignment.center,
        spacing: 24,
        runSpacing: 16,
        children: [
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 720),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Aradığınız model katalogda yok mu?',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                SizedBox(height: 7),
                Text(
                  'Elinizdeki medikal görüntü veya proje fikri için kişiye özel model talebi oluşturabilirsiniz.',
                  style: TextStyle(color: Color(0xFFD2DCDD), height: 1.4),
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
            child: const Text('Özel model talebi'),
          ),
        ],
      ),
    );
  }
}

class _RepresentativeVisualNotice extends StatelessWidget {
  const _RepresentativeVisualNotice();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
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
              'Görsel temsilidir. Üretilecek modelin geometri, renk, malzeme ve parça özellikleri teknik değerlendirme sonrasında kesinleşir.',
              style: TextStyle(color: DmlColors.slate, height: 1.4),
            ),
          ),
        ],
      ),
    );
  }
}
