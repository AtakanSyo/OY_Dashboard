import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:oy_site/data/repositories/supabase_analysis_repository.dart';
import 'package:oy_site/data/repositories/supabase_store_repository.dart';
import 'package:oy_site/l10n/app_localizations.dart';
import 'package:oy_site/models/customer_analysis_result_model.dart';
import 'package:oy_site/models/store_measurement_summary_model.dart';
import 'package:oy_site/models/store_product_model.dart';
import 'package:oy_site/models/app_user.dart';
import 'package:oy_site/screens/dashboard/store/store_product_detail_screen.dart';

class StoreScreen extends StatefulWidget {
  const StoreScreen({super.key, required this.currentUser});
  final AppUser currentUser;

  @override
  State<StoreScreen> createState() => _StoreScreenState();
}

class _StoreScreenState extends State<StoreScreen> {
  final SupabaseAnalysisRepository _analysisRepository =
      SupabaseAnalysisRepository();
  final SupabaseStoreRepository _storeRepository = SupabaseStoreRepository();
  List<StoreProduct> _catalogProducts = const [];
  bool _isLoadingProducts = true;
  bool _productsLoadFailed = false;

  StoreMeasurementSummary? _latestMeasurement;
  bool _isLoadingMeasurement = true;
  bool _measurementLoadFailed = false;

  @override
  void initState() {
    super.initState();
    _loadLatestMeasurement();
    _loadProducts();
  }

  Future<void> _loadProducts() async {
    setState(() {
      _isLoadingProducts = true;
      _productsLoadFailed = false;
    });
    try {
      final products = await _storeRepository.getProducts(
        clinicId: widget.currentUser.clinicId,
      );
      if (!mounted) return;
      setState(() {
        _catalogProducts = products;
        _isLoadingProducts = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _catalogProducts = const [];
        _isLoadingProducts = false;
        _productsLoadFailed = true;
      });
    }
  }

  Future<void> _loadLatestMeasurement() async {
    setState(() {
      _isLoadingMeasurement = true;
      _measurementLoadFailed = false;
    });
    try {
      final analysis = await _analysisRepository
          .getLatestAnalysisForCurrentCustomer();
      if (!mounted) return;
      setState(() {
        _latestMeasurement = _measurementFromAnalysis(analysis);
        _isLoadingMeasurement = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _latestMeasurement = null;
        _isLoadingMeasurement = false;
        _measurementLoadFailed = true;
      });
    }
  }

  StoreMeasurementSummary? _measurementFromAnalysis(
    CustomerAnalysisResult? analysis,
  ) {
    if (analysis == null) return null;
    return StoreMeasurementSummary(
      sessionId: analysis.sessionId,
      sessionCode: analysis.sessionCode,
      analysisDate: analysis.analysisDate,
      locationLabel: analysis.locationLabel,
      shortMessage: '',
    );
  }

  void _openProduct(StoreProduct product) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => StoreProductDetailScreen(
          product: product,
          measurement: _latestMeasurement,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final products = _catalogProducts;
    final mainProducts = products.where((product) => !product.isAddOn).toList();
    final addOns = products.where((product) => product.isAddOn).toList();

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      body: LayoutBuilder(
        builder: (context, constraints) {
          final pagePadding = constraints.maxWidth < 650 ? 16.0 : 24.0;
          return SingleChildScrollView(
            padding: EdgeInsets.all(pagePadding),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1100),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.store,
                      style: Theme.of(context).textTheme.headlineSmall
                          ?.copyWith(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      l10n.storeIntro,
                      style: TextStyle(color: Colors.grey.shade700),
                    ),
                    const SizedBox(height: 20),
                    _buildMeasurementArea(l10n),
                    const SizedBox(height: 28),
                    if (_isLoadingProducts)
                      const SizedBox(
                        height: 180,
                        child: Center(child: CircularProgressIndicator()),
                      )
                    else if (_productsLoadFailed)
                      _MessageCard(
                        icon: Icons.sync_problem_outlined,
                        title: l10n.genericError,
                        description: 'Mağaza ürünleri yüklenemedi.',
                        action: OutlinedButton.icon(
                          onPressed: _loadProducts,
                          icon: const Icon(Icons.refresh),
                          label: Text(l10n.retry),
                        ),
                      )
                    else if (products.isEmpty)
                      const _MessageCard(
                        icon: Icons.storefront_outlined,
                        title: 'Şu anda yayında ürün bulunmuyor',
                        description:
                            'Yeni ürünler yayınlandığında burada görüntülenecek.',
                      )
                    else ...[
                      if (mainProducts.isNotEmpty) ...[
                        _SectionHeading(
                          title: l10n.mainProducts,
                          subtitle: l10n.mainProductsSubtitle,
                        ),
                        const SizedBox(height: 16),
                        _buildProductWrap(mainProducts, isAddOn: false),
                      ],
                      if (mainProducts.isNotEmpty && addOns.isNotEmpty)
                        const SizedBox(height: 30),
                      if (addOns.isNotEmpty) ...[
                        _SectionHeading(
                          title: l10n.accessoryProducts,
                          subtitle: l10n.accessoryProductsSubtitle,
                        ),
                        const SizedBox(height: 16),
                        _buildProductWrap(addOns, isAddOn: true),
                      ],
                    ],
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildMeasurementArea(AppLocalizations l10n) {
    if (_isLoadingMeasurement) {
      return const SizedBox(
        height: 150,
        child: Center(child: CircularProgressIndicator()),
      );
    }
    if (_measurementLoadFailed) {
      return _MessageCard(
        icon: Icons.sync_problem_outlined,
        title: l10n.genericError,
        description: l10n.noLinkedMeasurementDescription,
        action: OutlinedButton.icon(
          onPressed: _loadLatestMeasurement,
          icon: const Icon(Icons.refresh),
          label: Text(l10n.retry),
        ),
      );
    }
    if (_latestMeasurement == null) {
      return _MessageCard(
        icon: Icons.fact_check_outlined,
        title: l10n.noLinkedMeasurementTitle,
        description: l10n.noLinkedMeasurementDescription,
      );
    }
    return buildMeasurementCard(
      context: context,
      measurement: _latestMeasurement!,
      compact: true,
    );
  }

  Widget _buildProductWrap(
    List<StoreProduct> products, {
    required bool isAddOn,
  }) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final targetWidth = isAddOn ? 250.0 : 360.0;
        final columns = (constraints.maxWidth / targetWidth).floor().clamp(
          1,
          4,
        );
        final spacing = 16.0;
        final width =
            (constraints.maxWidth - (columns - 1) * spacing) / columns;

        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: products.map((product) {
            return StoreProductCard(
              width: width,
              product: product,
              onTap: () => _openProduct(product),
            );
          }).toList(),
        );
      },
    );
  }
}

Widget buildMeasurementCard({
  required BuildContext context,
  required StoreMeasurementSummary measurement,
  required bool compact,
}) {
  final l10n = AppLocalizations.of(context);
  final formattedDate = DateFormat.yMMMd(
    Localizations.localeOf(context).toLanguageTag(),
  ).format(measurement.analysisDate.toLocal());
  final clinicName = measurement.locationLabel.trim().isEmpty
      ? '—'
      : measurement.locationLabel;

  return Container(
    width: compact ? 520 : double.infinity,
    padding: const EdgeInsets.all(18),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: Colors.teal.withValues(alpha: 0.16)),
      boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 8)],
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            CircleAvatar(
              radius: 22,
              backgroundColor: Colors.teal.withValues(alpha: 0.12),
              child: const Icon(Icons.fact_check_outlined, color: Colors.teal),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                l10n.latestMeasurement,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        _MeasurementRow(
          label: l10n.sessionLabel,
          value: measurement.sessionCode,
        ),
        _MeasurementRow(label: l10n.dateLabel, value: formattedDate),
        _MeasurementRow(label: l10n.clinicLabel, value: clinicName),
        const SizedBox(height: 8),
        Text(
          l10n.linkedMeasurementMessage,
          style: TextStyle(color: Colors.grey.shade700, height: 1.4),
        ),
      ],
    ),
  );
}

class StoreProductCard extends StatelessWidget {
  final double width;
  final StoreProduct product;
  final VoidCallback onTap;

  const StoreProductCard({
    super.key,
    required this.width,
    required this.product,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return SizedBox(
      width: width,
      child: Material(
        color: Colors.white,
        elevation: 1,
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(18),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AspectRatio(
                  aspectRatio: product.isAddOn ? 1.8 : 2.1,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(14),
                    child: Container(
                      color: Colors.grey.shade100,
                      child: Image.asset(
                        product.imagePath,
                        fit: BoxFit.contain,
                        errorBuilder: (_, _, _) =>
                            Center(child: Text(l10n.imageUnavailable)),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  product.title,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 7),
                Text(
                  product.shortDescription,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: Colors.grey.shade700, height: 1.4),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        product.priceLabel,
                        style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                          color: Colors.teal,
                        ),
                      ),
                    ),
                    const Icon(Icons.chevron_right, color: Colors.black45),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SectionHeading extends StatelessWidget {
  final String title;
  final String subtitle;

  const _SectionHeading({required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 6),
        Text(subtitle, style: TextStyle(color: Colors.grey.shade700)),
      ],
    );
  }
}

class _MeasurementRow extends StatelessWidget {
  final String label;
  final String value;

  const _MeasurementRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 82,
            child: Text(
              label,
              style: TextStyle(
                color: Colors.grey.shade700,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }
}

class _MessageCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;
  final Widget? action;

  const _MessageCard({
    required this.icon,
    required this.title,
    required this.description,
    this.action,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: Colors.teal, size: 30),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  description,
                  style: TextStyle(color: Colors.grey.shade700, height: 1.4),
                ),
                if (action != null) ...[const SizedBox(height: 12), action!],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
