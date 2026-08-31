import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:oy_site/data/repositories/supabase_customer_home_repository.dart';
import 'package:oy_site/l10n/app_localizations.dart';
import 'package:oy_site/models/app_user.dart';
import 'package:oy_site/models/customer_home_model.dart';
import 'package:oy_site/models/order_model.dart';

class CustomerHomeScreen extends StatefulWidget {
  final AppUser currentUser;
  final ValueChanged<int> onNavigate;
  final CustomerHomeRepository? repository;

  const CustomerHomeScreen({
    super.key,
    required this.currentUser,
    required this.onNavigate,
    this.repository,
  });

  @override
  State<CustomerHomeScreen> createState() => _CustomerHomeScreenState();
}

class _CustomerHomeScreenState extends State<CustomerHomeScreen> {
  static const _teal = Colors.teal;
  late final CustomerHomeRepository _repository;

  bool _isLoading = true;
  String? _errorMessage;
  CustomerHomeData? _data;

  @override
  void initState() {
    super.initState();
    _repository = widget.repository ?? SupabaseCustomerHomeRepository();
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
        _errorMessage = AppLocalizations.of(context).homeLoadError;
        _isLoading = false;
      });
    }
  }

  String _formatDate(DateTime? date) {
    if (date == null) return AppLocalizations.of(context).notSpecified;
    return DateFormat.yMMMd(
      Localizations.localeOf(context).toLanguageTag(),
    ).format(date.toLocal());
  }

  String _formatPrice(double price) {
    return NumberFormat.currency(
      locale: Localizations.localeOf(context).toLanguageTag(),
      symbol: '₺',
      decimalDigits: 0,
    ).format(price);
  }

  String _orderStatusLabel(String status, AppLocalizations l10n) {
    switch (status) {
      case OrderStatuses.pending:
        return l10n.pendingStatus;
      case OrderStatuses.designing:
        return l10n.designingStatus;
      case OrderStatuses.production:
        return l10n.productionStatus;
      case OrderStatuses.shipped:
        return l10n.shippedStatus;
      case OrderStatuses.delivered:
        return l10n.deliveredStatus;
      case OrderStatuses.cancelled:
        return l10n.cancelledStatus;
      default:
        return status;
    }
  }

  String _productLabel(String productType, AppLocalizations l10n) {
    switch (productType) {
      case 'insole':
        return l10n.insoleProduct;
      case 'sports_insole':
        return l10n.sportsInsoleProduct;
      case 'sandal':
        return l10n.sandalProduct;
      case 'heel_pad':
        return l10n.heelPadTitle;
      case 'met_pad':
        return l10n.metPadTitle;
      case 'cleaning_spray':
        return l10n.cleaningSprayTitle;
      case 'carry_case':
        return l10n.carryCaseTitle;
      default:
        return productType;
    }
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
    final l10n = AppLocalizations.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.cloud_off_outlined,
              size: 48,
              color: Colors.grey.shade500,
            ),
            const SizedBox(height: 12),
            Text(_errorMessage!, textAlign: TextAlign.center),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: _load,
              icon: const Icon(Icons.refresh),
              label: Text(l10n.retry),
            ),
          ],
        ),
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
                    if (data.analysisLoadFailed || data.ordersLoadFailed) ...[
                      const SizedBox(height: 16),
                      _buildPartialDataBanner(),
                    ],
                    const SizedBox(height: 20),
                    _buildQuickCards(data),
                    const SizedBox(height: 20),
                    _buildMainGrid(data, constraints.maxWidth),
                    const SizedBox(height: 20),
                    _buildAnalysisCard(data),
                    const SizedBox(height: 20),
                    _buildProductCard(
                      data.suggestedProduct,
                      constraints.maxWidth,
                    ),
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
    final l10n = AppLocalizations.of(context);
    final compact = width < 850;
    final firstName =
        data.patientName.trim().split(' ').firstOrNull ??
        widget.currentUser.firstName;
    final textContent = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          l10n.helloUser(firstName),
          style: TextStyle(
            color: Colors.teal.shade900,
            fontSize: compact ? 25 : 31,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 10),
        Text(
          l10n.customerHomeIntro,
          style: TextStyle(
            color: Colors.teal.shade900.withValues(alpha: 0.78),
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
              label: Text(l10n.viewMyAssessment),
              style: ElevatedButton.styleFrom(
                backgroundColor: _teal,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 18,
                  vertical: 16,
                ),
              ),
            ),
            OutlinedButton.icon(
              onPressed: () => widget.onNavigate(2),
              icon: const Icon(Icons.local_shipping_outlined),
              label: Text(l10n.trackMyOrder),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.teal.shade800,
                side: BorderSide(color: Colors.teal.shade300),
                padding: const EdgeInsets.symmetric(
                  horizontal: 18,
                  vertical: 16,
                ),
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
                      'assets/images/products/personal_insole.png',
                      fit: BoxFit.contain,
                      errorBuilder: (_, _, _) => Icon(
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

  Widget _buildPartialDataBanner() {
    final l10n = AppLocalizations.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.orange.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.orange.withValues(alpha: 0.25)),
      ),
      child: Row(
        children: [
          const Icon(Icons.sync_problem_outlined, color: Colors.orange),
          const SizedBox(width: 10),
          Expanded(child: Text(l10n.partialHomeDataWarning)),
          IconButton(
            onPressed: _load,
            tooltip: l10n.retry,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickCards(CustomerHomeData data) {
    final l10n = AppLocalizations.of(context);
    final assessment = data.latestAssessment;
    final order = data.activeOrder;
    final product = data.suggestedProduct;

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
              title: l10n.latestAssessment,
              value: data.analysisLoadFailed
                  ? l10n.dataUnavailable
                  : assessment == null
                  ? l10n.noAssessmentYet
                  : l10n.assessmentReady,
              detail: assessment == null
                  ? l10n.notSpecified
                  : _formatDate(assessment.analysisDate),
              onTap: () => widget.onNavigate(1),
            ),
            _quickCard(
              width: cardWidth,
              icon: Icons.inventory_2_outlined,
              title: l10n.activeOrder,
              value: data.ordersLoadFailed
                  ? l10n.dataUnavailable
                  : order == null
                  ? l10n.noActiveOrder
                  : _orderStatusLabel(order.orderStatus, l10n),
              detail: order?.orderNo ?? l10n.notSpecified,
              onTap: () => widget.onNavigate(2),
            ),
            _quickCard(
              width: cardWidth,
              icon: Icons.recommend_outlined,
              title: l10n.recommendedProduct,
              value: product?.name ?? l10n.productNotDetermined,
              detail: product == null
                  ? l10n.recommendationPending
                  : l10n.personalRecommendation,
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
                      Text(
                        title,
                        style: TextStyle(color: Colors.grey.shade600),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        value,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        detail,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                      ),
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
      return Column(
        children: [order, const SizedBox(height: 20), recommendation],
      );
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
    final l10n = AppLocalizations.of(context);
    final order = data.activeOrder;
    if (data.ordersLoadFailed) {
      return _stateCard(
        icon: Icons.sync_problem_outlined,
        title: l10n.dataUnavailable,
        description: l10n.partialHomeDataWarning,
        actionLabel: l10n.retry,
        onAction: _load,
      );
    }
    if (order == null) {
      return _stateCard(
        icon: Icons.inventory_2_outlined,
        title: l10n.noActiveOrder,
        description: l10n.noActiveOrderDescription,
        actionLabel: l10n.orders,
        onAction: () => widget.onNavigate(2),
      );
    }

    final steps = [
      l10n.orderReceived,
      l10n.design,
      l10n.production,
      l10n.shipped,
      l10n.delivered,
    ];
    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionHeader(Icons.local_shipping_outlined, l10n.orderProcess),
          const SizedBox(height: 18),
          Text(
            _productLabel(order.productType, l10n),
            style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 5),
          Text(
            '${order.orderNo}  •  ${l10n.orderedOn(_formatDate(order.orderedAt))}',
            style: TextStyle(color: Colors.grey.shade600),
          ),
          const SizedBox(height: 26),
          LayoutBuilder(
            builder: (context, constraints) => Row(
              children: List.generate(steps.length, (index) {
                final active = index <= order.progressStep;
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
                              child: Icon(
                                active ? Icons.check : Icons.circle,
                                size: active ? 17 : 7,
                                color: active
                                    ? Colors.white
                                    : Colors.grey.shade500,
                              ),
                            ),
                            const SizedBox(height: 7),
                            Text(
                              steps[index],
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: constraints.maxWidth < 500 ? 10 : 12,
                                fontWeight: active
                                    ? FontWeight.w600
                                    : FontWeight.normal,
                                color: active
                                    ? Colors.teal.shade800
                                    : Colors.grey.shade600,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (index < steps.length - 1)
                        Container(
                          width: constraints.maxWidth < 500 ? 5 : 14,
                          height: 2,
                          margin: const EdgeInsets.only(bottom: 24),
                          color: index < order.progressStep
                              ? _teal
                              : Colors.grey.shade300,
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
              label: Text(l10n.goToOrderDetails),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecommendationCard(CustomerHomeData data) {
    final l10n = AppLocalizations.of(context);
    final assessment = data.latestAssessment;
    final note = assessment?.recommendationNote?.trim() ?? '';
    final title = assessment?.recommendationTitle?.trim() ?? '';

    return _card(
      color: Colors.teal.shade50,
      borderColor: Colors.teal.shade100,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionHeader(
            Icons.health_and_safety_outlined,
            l10n.specialistRecommendation,
          ),
          const SizedBox(height: 18),
          if (data.analysisLoadFailed)
            _inlineState(
              Icons.sync_problem_outlined,
              l10n.dataUnavailable,
              l10n.partialHomeDataWarning,
            )
          else if (assessment == null || note.isEmpty)
            _inlineState(
              Icons.hourglass_empty_outlined,
              l10n.recommendationPending,
              l10n.recommendationPendingDescription,
            )
          else ...[
            if (title.isNotEmpty) ...[
              Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
              const SizedBox(height: 8),
            ],
            Text(note, style: const TextStyle(fontSize: 15, height: 1.55)),
            const SizedBox(height: 18),
            Text(
              l10n.updatedOn(_formatDate(assessment.analysisDate)),
              style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildAnalysisCard(CustomerHomeData data) {
    final l10n = AppLocalizations.of(context);
    final assessment = data.latestAssessment;
    if (data.analysisLoadFailed) {
      return _stateCard(
        icon: Icons.sync_problem_outlined,
        title: l10n.dataUnavailable,
        description: l10n.partialHomeDataWarning,
        actionLabel: l10n.retry,
        onAction: _load,
      );
    }
    if (assessment == null) {
      return _stateCard(
        icon: Icons.insights_outlined,
        title: l10n.noAssessmentYet,
        description: l10n.noAssessmentYetDescription,
        actionLabel: l10n.checkAgain,
        onAction: _load,
      );
    }

    final summary = assessment.summary.isEmpty
        ? l10n.assessmentSummaryAvailable
        : assessment.summary;
    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: _sectionHeader(
                  Icons.insights_outlined,
                  l10n.yourLatestAssessment,
                ),
              ),
              Text(
                _formatDate(assessment.analysisDate),
                style: TextStyle(color: Colors.grey.shade600),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(summary, style: const TextStyle(fontSize: 15, height: 1.5)),
          if (assessment.highlights.isNotEmpty) ...[
            const SizedBox(height: 18),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: assessment.highlights
                  .map(
                    (item) => Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.teal.shade50,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.check_circle_outline,
                            size: 17,
                            color: _teal,
                          ),
                          const SizedBox(width: 6),
                          Flexible(child: Text(item)),
                        ],
                      ),
                    ),
                  )
                  .toList(),
            ),
          ],
          const SizedBox(height: 16),
          Align(
            alignment: Alignment.centerRight,
            child: OutlinedButton.icon(
              onPressed: () => widget.onNavigate(1),
              icon: const Icon(Icons.description_outlined),
              label: Text(l10n.viewDetailedAssessment),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProductCard(CustomerHomeProductData? product, double width) {
    final l10n = AppLocalizations.of(context);
    if (product == null) {
      return _stateCard(
        icon: Icons.recommend_outlined,
        title: l10n.productNotDetermined,
        description: l10n.productSelectionPendingDescription,
        actionLabel: l10n.browseProducts,
        onAction: () => widget.onNavigate(3),
      );
    }

    final compact = width < 760;
    final image = Container(
      width: compact ? double.infinity : 290,
      height: 210,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Image.asset(
        product.imagePath,
        fit: BoxFit.contain,
        errorBuilder: (_, _, _) => Center(child: Text(l10n.imageUnavailable)),
      ),
    );
    final details = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionHeader(Icons.recommend_outlined, l10n.productRecommendedForYou),
        const SizedBox(height: 14),
        Text(
          product.name,
          style: const TextStyle(fontSize: 21, fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 8),
        Text(product.description, style: const TextStyle(height: 1.45)),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.teal.shade50,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.info_outline, color: _teal, size: 20),
              const SizedBox(width: 8),
              Expanded(child: Text(product.reason)),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: Text(
                _formatPrice(product.price),
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () => widget.onNavigate(3),
              style: ElevatedButton.styleFrom(
                backgroundColor: _teal,
                foregroundColor: Colors.white,
              ),
              child: Text(l10n.viewProduct),
            ),
          ],
        ),
      ],
    );
    return _card(
      child: compact
          ? Column(children: [image, const SizedBox(height: 20), details])
          : Row(
              children: [
                image,
                const SizedBox(width: 28),
                Expanded(child: details),
              ],
            ),
    );
  }

  Widget _stateCard({
    required IconData icon,
    required String title,
    required String description,
    required String actionLabel,
    required VoidCallback onAction,
  }) {
    return _card(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 25,
            backgroundColor: Colors.teal.withValues(alpha: 0.10),
            child: Icon(icon, color: _teal),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  description,
                  style: TextStyle(color: Colors.grey.shade700, height: 1.4),
                ),
                const SizedBox(height: 12),
                OutlinedButton(onPressed: onAction, child: Text(actionLabel)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _inlineState(IconData icon, String title, String description) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: _teal),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
              const SizedBox(height: 5),
              Text(description, style: const TextStyle(height: 1.4)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSupportBanner() {
    final l10n = AppLocalizations.of(context);
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
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.support_agent_outlined, color: _teal, size: 30),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.haveAQuestion,
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                  Text(l10n.supportTeamCanHelp),
                ],
              ),
            ],
          ),
          OutlinedButton.icon(
            onPressed: () => widget.onNavigate(4),
            icon: const Icon(Icons.chat_bubble_outline),
            label: Text(l10n.getSupport),
          ),
        ],
      ),
    );
  }

  Widget _sectionHeader(IconData icon, String title) {
    return Row(
      children: [
        Icon(icon, color: _teal, size: 23),
        const SizedBox(width: 9),
        Expanded(
          child: Text(
            title,
            style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
          ),
        ),
      ],
    );
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
          BoxShadow(
            color: Color(0x0A000000),
            blurRadius: 10,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: child,
    );
  }
}
