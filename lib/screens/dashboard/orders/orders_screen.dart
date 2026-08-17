import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:oy_site/data/repositories/supabase_order_repository.dart';
import 'package:oy_site/l10n/app_localizations.dart';
import 'package:oy_site/models/app_user.dart';
import 'package:oy_site/models/order_model.dart';
import 'package:oy_site/screens/dashboard/orders/order_detail_screen.dart';

class OrdersScreen extends StatefulWidget {
  final AppUser currentUser;

  const OrdersScreen({super.key, required this.currentUser});

  @override
  State<OrdersScreen> createState() => _OrdersScreenState();
}

class _OrdersScreenState extends State<OrdersScreen> {
  final SupabaseOrderRepository _orderRepository = SupabaseOrderRepository();
  final TextEditingController _searchController = TextEditingController();

  List<OrderModel> _allOrders = [];
  List<OrderModel> _filteredOrders = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadOrders();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadOrders() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final orders = widget.currentUser.isCustomer
          ? await _orderRepository.getOrdersForCurrentCustomer()
          : await _loadExpertOrders();

      if (!mounted) return;
      setState(() {
        _allOrders = orders;
        _isLoading = false;
      });
      _filterOrders(_searchController.text);
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _errorMessage = AppLocalizations.of(
          context,
        ).ordersLoadError(error.toString());
        _isLoading = false;
      });
    }
  }

  Future<List<OrderModel>> _loadExpertOrders() {
    final userId = widget.currentUser.userId;
    if (userId == null) {
      return Future.error(Exception('User ID is missing.'));
    }
    return _orderRepository.getOrdersByExpert(expertUserId: userId);
  }

  void _filterOrders(String query) {
    final q = query.trim().toLowerCase();
    final l10n = AppLocalizations.of(context);

    setState(() {
      if (q.isEmpty) {
        _filteredOrders = List<OrderModel>.of(_allOrders);
        return;
      }

      _filteredOrders = _allOrders.where((order) {
        final values = [
          order.orderNo,
          order.productType,
          _productLabel(order.productType, l10n),
          order.orderStatus,
          _statusLabel(order.orderStatus, l10n),
          order.currencyCode,
        ];
        return values.any((value) => value.toLowerCase().contains(q));
      }).toList();
    });
  }

  String _formatDate(BuildContext context, DateTime? date) {
    if (date == null) return '—';
    return DateFormat.yMd(
      Localizations.localeOf(context).toLanguageTag(),
    ).format(date.toLocal());
  }

  String _formatMoney(
    BuildContext context,
    double amount,
    String currencyCode,
  ) {
    final value = NumberFormat.currency(
      locale: Localizations.localeOf(context).toLanguageTag(),
      symbol: '',
      decimalDigits: 2,
    ).format(amount).trim();
    return '$value $currencyCode';
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

  String _statusLabel(String status, AppLocalizations l10n) {
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

  Color _statusColor(String status) {
    switch (status) {
      case OrderStatuses.pending:
        return Colors.orange;
      case OrderStatuses.designing:
        return Colors.deepPurple;
      case OrderStatuses.production:
        return Colors.blue;
      case OrderStatuses.shipped:
        return Colors.teal;
      case OrderStatuses.delivered:
        return Colors.green;
      case OrderStatuses.cancelled:
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  void _openOrderDetail(OrderModel order) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) =>
            OrderDetailScreen(currentUser: widget.currentUser, order: order),
      ),
    ).then((_) {
      if (mounted) _loadOrders();
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      body: LayoutBuilder(
        builder: (context, constraints) {
          final horizontalPadding = constraints.maxWidth < 700 ? 16.0 : 28.0;
          return Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1200),
              child: Padding(
                padding: EdgeInsets.fromLTRB(
                  horizontalPadding,
                  24,
                  horizontalPadding,
                  24,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.currentUser.isCustomer
                          ? l10n.myOrders
                          : l10n.orders,
                      style: Theme.of(context).textTheme.headlineSmall
                          ?.copyWith(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      widget.currentUser.isCustomer
                          ? l10n.customerOrdersIntro
                          : l10n.orderManagementIntro,
                      style: TextStyle(color: Colors.grey.shade700),
                    ),
                    const SizedBox(height: 20),
                    TextField(
                      controller: _searchController,
                      onChanged: _filterOrders,
                      decoration: InputDecoration(
                        hintText: l10n.orderSearchHint,
                        prefixIcon: const Icon(Icons.search),
                        suffixIcon: _searchController.text.trim().isEmpty
                            ? null
                            : IconButton(
                                onPressed: () {
                                  _searchController.clear();
                                  _filterOrders('');
                                },
                                icon: const Icon(Icons.clear),
                              ),
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Colors.grey.shade300),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Colors.grey.shade300),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Expanded(child: _buildContent(l10n)),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildContent(AppLocalizations l10n) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorMessage != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, color: Colors.red, size: 44),
            const SizedBox(height: 12),
            Text(
              _errorMessage!,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.red),
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: _loadOrders,
              icon: const Icon(Icons.refresh),
              label: Text(l10n.checkAgain),
            ),
          ],
        ),
      );
    }

    if (_filteredOrders.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.shopping_bag_outlined,
              size: 56,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 12),
            Text(
              widget.currentUser.isCustomer
                  ? l10n.noCustomerOrders
                  : l10n.noSavedOrders,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadOrders,
      child: ListView.separated(
        physics: const AlwaysScrollableScrollPhysics(),
        itemCount: _filteredOrders.length,
        separatorBuilder: (_, _) => const SizedBox(height: 12),
        itemBuilder: (context, index) =>
            _buildOrderCard(_filteredOrders[index], l10n),
      ),
    );
  }

  Widget _buildOrderCard(OrderModel order, AppLocalizations l10n) {
    final statusColor = _statusColor(order.orderStatus);

    return Material(
      color: Colors.white,
      elevation: 1,
      shadowColor: Colors.black12,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: () => _openOrderDetail(order),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 24,
                    backgroundColor: statusColor.withValues(alpha: 0.12),
                    child: Icon(
                      Icons.shopping_bag_outlined,
                      color: statusColor,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Wrap(
                      spacing: 10,
                      runSpacing: 8,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Text(
                          order.orderNo,
                          style: const TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        _buildStatusChip(
                          _statusLabel(order.orderStatus, l10n),
                          statusColor,
                        ),
                      ],
                    ),
                  ),
                  const Icon(Icons.chevron_right),
                ],
              ),
              const SizedBox(height: 14),
              Wrap(
                spacing: 24,
                runSpacing: 8,
                children: [
                  _buildLabelValue(
                    l10n.productLabel,
                    _productLabel(order.productType, l10n),
                  ),
                  _buildLabelValue(
                    l10n.netAmountLabel,
                    _formatMoney(context, order.netAmount, order.currencyCode),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Wrap(
                spacing: 10,
                runSpacing: 8,
                children: [
                  _buildInfoChip(
                    Icons.calendar_today_outlined,
                    l10n.orderedChip(_formatDate(context, order.orderedAt)),
                  ),
                  _buildInfoChip(
                    Icons.local_shipping_outlined,
                    l10n.shippedChip(_formatDate(context, order.shippedAt)),
                  ),
                  _buildInfoChip(
                    Icons.home_outlined,
                    l10n.deliveredChip(_formatDate(context, order.deliveredAt)),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusChip(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w600,
          fontSize: 12,
        ),
      ),
    );
  }

  Widget _buildLabelValue(String label, String value) {
    return RichText(
      text: TextSpan(
        style: DefaultTextStyle.of(context).style,
        children: [
          TextSpan(
            text: '$label: ',
            style: TextStyle(color: Colors.grey.shade700),
          ),
          TextSpan(
            text: value,
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoChip(IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: Colors.teal),
          const SizedBox(width: 6),
          Text(text, style: const TextStyle(fontSize: 13)),
        ],
      ),
    );
  }
}
