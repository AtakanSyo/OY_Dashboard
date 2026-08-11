import 'package:flutter/material.dart';
import 'package:oy_site/data/mock/mock_customer_home_repository.dart';
import 'package:oy_site/models/app_user.dart';
import 'package:oy_site/models/customer_home_model.dart';

class CustomerHomeScreen extends StatefulWidget {
  final AppUser currentUser;
  final ValueChanged<int> onNavigate;

  const CustomerHomeScreen({
    super.key,
    required this.currentUser,
    required this.onNavigate,
  });

  @override
  State<CustomerHomeScreen> createState() => _CustomerHomeScreenState();
}

class _CustomerHomeScreenState extends State<CustomerHomeScreen> {
  static const _teal = Colors.teal;
  final _repository = MockCustomerHomeRepository();

  bool _isLoading = true;
  String? _errorMessage;
  CustomerHomeData? _data;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final data = await _repository.getHomeData(
        patientName: widget.currentUser.fullName,
      );
      if (!mounted) return;
      setState(() {
        _data = data;
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _errorMessage = 'Ana sayfa bilgileri yüklenemedi.';
        _isLoading = false;
      });
    }
  }

  String _formatDate(DateTime? date) {
    if (date == null) return 'Belirtilmedi';
    return '${date.day.toString().padLeft(2, '0')}.'
        '${date.month.toString().padLeft(2, '0')}.${date.year}';
  }

  String _formatPrice(double price) {
    final value = price.toStringAsFixed(0);
    final buffer = StringBuffer();
    for (var i = 0; i < value.length; i++) {
      if (i > 0 && (value.length - i) % 3 == 0) buffer.write('.');
      buffer.write(value[i]);
    }
    return '${buffer.toString()} TL';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: _teal))
          : _errorMessage != null
              ? _buildErrorState()
              : _buildPage(_data!),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.cloud_off_outlined, size: 48, color: Colors.grey.shade500),
          const SizedBox(height: 12),
          Text(_errorMessage!),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: _load,
            icon: const Icon(Icons.refresh),
            label: const Text('Tekrar dene'),
          ),
        ],
      ),
    );
  }

  Widget _buildPage(CustomerHomeData data) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final horizontalPadding = constraints.maxWidth < 760 ? 16.0 : 28.0;
        return RefreshIndicator(
          onRefresh: _load,
          color: _teal,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: EdgeInsets.fromLTRB(
              horizontalPadding,
              24,
              horizontalPadding,
              36,
            ),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1320),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildHero(data, constraints.maxWidth),
                    const SizedBox(height: 20),
                    _buildQuickCards(data),
                    const SizedBox(height: 20),
                    _buildMainGrid(data, constraints.maxWidth),
                    const SizedBox(height: 20),
                    _buildAnalysisCard(data),
                    const SizedBox(height: 20),
                    _buildProductCard(data, constraints.maxWidth),
                    const SizedBox(height: 20),
                    _buildSupportBanner(),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildHero(CustomerHomeData data, double width) {
    final compact = width < 850;
    final textContent = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          'Merhaba, ${data.patientName.split(' ').first}',
          style: TextStyle(
            color: Colors.teal.shade900,
            fontSize: compact ? 25 : 31,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 10),
        Text(
          'Ayak sağlığınızla ilgili değerlendirmelerinizi, önerilerinizi ve siparişlerinizi buradan takip edebilirsiniz.',
          style: TextStyle(
            color: Colors.teal.shade900.withOpacity(.78),
            fontSize: 16,
            height: 1.45,
          ),
        ),
        const SizedBox(height: 22),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            ElevatedButton.icon(
              onPressed: () => widget.onNavigate(1),
              icon: const Icon(Icons.insights_outlined),
              label: const Text('Değerlendirmemi görüntüle'),
              style: ElevatedButton.styleFrom(
                backgroundColor: _teal,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
              ),
            ),
            OutlinedButton.icon(
              onPressed: () => widget.onNavigate(2),
              icon: const Icon(Icons.local_shipping_outlined),
              label: const Text('Siparişimi takip et'),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.teal.shade800,
                side: BorderSide(color: Colors.teal.shade300),
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
              ),
            ),
          ],
        ),
      ],
    );

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(compact ? 24 : 34),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.teal.shade50, Colors.white],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: Colors.teal.shade100),
      ),
      child: compact
          ? textContent
          : Row(
              children: [
                Expanded(flex: 3, child: textContent),
                const SizedBox(width: 30),
                Expanded(
                  flex: 2,
                  child: SizedBox(
                    height: 220,
                    child: Image.asset(
                      data.suggestedProductImagePath,
                      fit: BoxFit.contain,
                      errorBuilder: (_, __, ___) => Icon(
                        Icons.health_and_safety_outlined,
                        size: 110,
                        color: Colors.teal.shade200,
                      ),
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildQuickCards(CustomerHomeData data) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final cardWidth = constraints.maxWidth >= 960
            ? (constraints.maxWidth - 32) / 3
            : constraints.maxWidth >= 620
                ? (constraints.maxWidth - 16) / 2
                : constraints.maxWidth;
        return Wrap(
          spacing: 16,
          runSpacing: 16,
          children: [
            _quickCard(
              width: cardWidth,
              icon: Icons.fact_check_outlined,
              title: 'Son değerlendirme',
              value: data.analysisStatus,
              detail: _formatDate(data.lastAnalysisDate),
              onTap: () => widget.onNavigate(1),
            ),
            _quickCard(
              width: cardWidth,
              icon: Icons.inventory_2_outlined,
              title: 'Aktif sipariş',
              value: data.orderStatus,
              detail: data.orderNo,
              onTap: () => widget.onNavigate(2),
            ),
            _quickCard(
              width: cardWidth,
              icon: Icons.recommend_outlined,
              title: 'Önerilen ürün',
              value: data.suggestedProductName,
              detail: 'Size özel öneri',
              onTap: () => widget.onNavigate(3),
            ),
          ],
        );
      },
    );
  }

  Widget _quickCard({
    required double width,
    required IconData icon,
    required String title,
    required String value,
    required String detail,
    required VoidCallback onTap,
  }) {
    return SizedBox(
      width: width,
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: Colors.teal.shade50,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(icon, color: _teal),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title, style: TextStyle(color: Colors.grey.shade600)),
                      const SizedBox(height: 4),
                      Text(value, style: const TextStyle(fontWeight: FontWeight.w700)),
                      const SizedBox(height: 2),
                      Text(detail, style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                    ],
                  ),
                ),
                Icon(Icons.chevron_right, color: Colors.grey.shade400),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMainGrid(CustomerHomeData data, double width) {
    final order = _buildOrderCard(data);
    final recommendation = _buildRecommendationCard(data);
    if (width < 950) {
      return Column(children: [order, const SizedBox(height: 20), recommendation]);
    }
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(flex: 3, child: order),
          const SizedBox(width: 20),
          Expanded(flex: 2, child: recommendation),
        ],
      ),
    );
  }

  Widget _buildOrderCard(CustomerHomeData data) {
    const steps = ['Alındı', 'Tasarım', 'Üretim', 'Kargoda', 'Teslim'];
    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionHeader(Icons.local_shipping_outlined, 'Sipariş süreci'),
          const SizedBox(height: 18),
          Text(data.productName, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
          const SizedBox(height: 5),
          Text('${data.orderNo}  •  Tahmini teslim: ${_formatDate(data.estimatedDelivery)}',
              style: TextStyle(color: Colors.grey.shade600)),
          const SizedBox(height: 26),
          LayoutBuilder(
            builder: (context, constraints) => Row(
              children: List.generate(steps.length, (index) {
                final active = index <= data.orderProgressStep;
                return Expanded(
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          children: [
                            Container(
                              width: 28,
                              height: 28,
                              decoration: BoxDecoration(
                                color: active ? _teal : Colors.grey.shade200,
                                shape: BoxShape.circle,
                              ),
                              child: Icon(active ? Icons.check : Icons.circle,
                                  size: active ? 17 : 7,
                                  color: active ? Colors.white : Colors.grey.shade500),
                            ),
                            const SizedBox(height: 7),
                            Text(steps[index],
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: constraints.maxWidth < 500 ? 10 : 12,
                                  fontWeight: active ? FontWeight.w600 : FontWeight.normal,
                                  color: active ? Colors.teal.shade800 : Colors.grey.shade600,
                                )),
                          ],
                        ),
                      ),
                      if (index < steps.length - 1)
                        Container(
                          width: constraints.maxWidth < 500 ? 5 : 14,
                          height: 2,
                          margin: const EdgeInsets.only(bottom: 24),
                          color: index < data.orderProgressStep ? _teal : Colors.grey.shade300,
                        ),
                    ],
                  ),
                );
              }),
            ),
          ),
          const SizedBox(height: 18),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton.icon(
              onPressed: () => widget.onNavigate(2),
              icon: const Icon(Icons.arrow_forward, size: 18),
              label: const Text('Sipariş detayına git'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecommendationCard(CustomerHomeData data) {
    return _card(
      color: Colors.teal.shade50,
      borderColor: Colors.teal.shade100,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionHeader(Icons.health_and_safety_outlined, 'Uzmanınızdan öneri'),
          const SizedBox(height: 18),
          Text(data.recommendationNote, style: const TextStyle(fontSize: 15, height: 1.55)),
          const SizedBox(height: 18),
          Text('Güncelleme: ${_formatDate(data.recommendationUpdatedAt)}',
              style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
        ],
      ),
    );
  }

  Widget _buildAnalysisCard(CustomerHomeData data) {
    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(child: _sectionHeader(Icons.insights_outlined, 'Son değerlendirmeniz')),
              Text(_formatDate(data.lastAnalysisDate), style: TextStyle(color: Colors.grey.shade600)),
            ],
          ),
          const SizedBox(height: 16),
          Text(data.summary, style: const TextStyle(fontSize: 15, height: 1.5)),
          const SizedBox(height: 18),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: data.analysisHighlights.map((item) => Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.teal.shade50,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                const Icon(Icons.check_circle_outline, size: 17, color: _teal),
                const SizedBox(width: 6),
                Text(item),
              ]),
            )).toList(),
          ),
          const SizedBox(height: 16),
          Align(
            alignment: Alignment.centerRight,
            child: OutlinedButton.icon(
              onPressed: () => widget.onNavigate(1),
              icon: const Icon(Icons.description_outlined),
              label: const Text('Detaylı değerlendirmeyi görüntüle'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProductCard(CustomerHomeData data, double width) {
    final compact = width < 760;
    final image = Container(
      width: compact ? double.infinity : 290,
      height: 210,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: Colors.grey.shade50, borderRadius: BorderRadius.circular(16)),
      child: Image.asset(data.suggestedProductImagePath, fit: BoxFit.contain),
    );
    final details = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionHeader(Icons.recommend_outlined, 'Size önerilen ürün'),
        const SizedBox(height: 14),
        Text(data.suggestedProductName, style: const TextStyle(fontSize: 21, fontWeight: FontWeight.w800)),
        const SizedBox(height: 8),
        Text(data.suggestedProductDescription, style: const TextStyle(height: 1.45)),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: Colors.teal.shade50, borderRadius: BorderRadius.circular(12)),
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Icon(Icons.info_outline, color: _teal, size: 20),
            const SizedBox(width: 8),
            Expanded(child: Text(data.suggestedProductReason)),
          ]),
        ),
        const SizedBox(height: 16),
        Row(children: [
          Expanded(child: Text(_formatPrice(data.suggestedProductPrice),
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800))),
          ElevatedButton(
            onPressed: () => widget.onNavigate(3),
            style: ElevatedButton.styleFrom(backgroundColor: _teal, foregroundColor: Colors.white),
            child: const Text('Ürünü incele'),
          ),
        ]),
      ],
    );
    return _card(
      child: compact
          ? Column(children: [image, const SizedBox(height: 20), details])
          : Row(children: [image, const SizedBox(width: 28), Expanded(child: details)]),
    );
  }

  Widget _buildSupportBanner() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Wrap(
        alignment: WrapAlignment.spaceBetween,
        crossAxisAlignment: WrapCrossAlignment.center,
        spacing: 20,
        runSpacing: 12,
        children: [
          const Row(mainAxisSize: MainAxisSize.min, children: [
            Icon(Icons.support_agent_outlined, color: _teal, size: 30),
            SizedBox(width: 12),
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Bir sorunuz mu var?', style: TextStyle(fontWeight: FontWeight.w700)),
              Text('Destek ekibimiz size yardımcı olabilir.'),
            ]),
          ]),
          OutlinedButton.icon(
            onPressed: () => widget.onNavigate(4),
            icon: const Icon(Icons.chat_bubble_outline),
            label: const Text('Destek al'),
          ),
        ],
      ),
    );
  }

  Widget _sectionHeader(IconData icon, String title) {
    return Row(children: [
      Icon(icon, color: _teal, size: 23),
      const SizedBox(width: 9),
      Text(title, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
    ]);
  }

  Widget _card({
    required Widget child,
    Color color = Colors.white,
    Color? borderColor,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: borderColor ?? Colors.grey.shade200),
        boxShadow: const [
          BoxShadow(color: Color(0x0A000000), blurRadius: 10, offset: Offset(0, 3)),
        ],
      ),
      child: child,
    );
  }
}
