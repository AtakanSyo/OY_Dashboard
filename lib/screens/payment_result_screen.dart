import 'dart:async';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:oy_site/l10n/app_localizations.dart';
import 'package:oy_site/models/app_user.dart';
import 'package:oy_site/screens/dashboard/shell/dashboard_screen.dart';
import 'package:oy_site/screens/home_screen.dart';
import 'package:oy_site/services/payment/iyzico_checkout_service.dart';
import 'package:oy_site/widgets/language_selector.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class PaymentResultScreen extends StatefulWidget {
  const PaymentResultScreen({
    super.key,
    this.success,
    required this.token,
    required this.pressureRepository,
    this.checkoutService,
  });

  final bool? success;
  final String? token;
  final dynamic pressureRepository;
  final IyzicoCheckoutService? checkoutService;

  @override
  State<PaymentResultScreen> createState() => _PaymentResultScreenState();
}

class _PaymentResultScreenState extends State<PaymentResultScreen> {
  late final IyzicoCheckoutService _checkoutService;
  IyzicoCheckoutStatusResult? _result;
  Timer? _pollTimer;
  bool _isLoading = false;
  String? _loadError;
  int _pollCount = 0;

  @override
  void initState() {
    super.initState();
    _checkoutService = widget.checkoutService ?? IyzicoCheckoutService();
    if ((widget.token ?? '').isNotEmpty) {
      _refreshStatus(startPolling: true);
    }
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    super.dispose();
  }

  Future<void> _refreshStatus({bool startPolling = false}) async {
    final token = widget.token;
    if (token == null || token.isEmpty || _isLoading) return;

    setState(() {
      _isLoading = true;
      _loadError = null;
    });
    try {
      final result = await _checkoutService.getCheckoutStatus(token: token);
      if (!mounted) return;
      setState(() {
        _result = result;
        _isLoading = false;
      });

      if (result.isPaid || result.isFailed) {
        _pollTimer?.cancel();
      } else if (startPolling || _pollTimer == null) {
        _startPolling();
      }
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _loadError = error.toString();
      });
      if (startPolling) _startPolling();
    }
  }

  void _startPolling() {
    _pollTimer?.cancel();
    _pollTimer = Timer.periodic(const Duration(seconds: 3), (timer) {
      _pollCount += 1;
      if (_pollCount >= 40) {
        timer.cancel();
        return;
      }
      _refreshStatus();
    });
  }

  Future<void> _goToOrders() async {
    final client = Supabase.instance.client;
    final authUser = client.auth.currentUser;

    if (authUser == null) {
      if (!mounted) return;
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(
          builder: (_) =>
              HomeScreen(pressureRepository: widget.pressureRepository),
        ),
        (_) => false,
      );
      return;
    }

    final profileData = await client
        .from('user_profiles_full')
        .select()
        .eq('auth_id', authUser.id)
        .single();
    final currentUser = AppUser.fromMap(profileData);

    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(
        builder: (_) => DashboardScreen(
          currentUser: currentUser,
          pressureRepository: widget.pressureRepository,
          initialIndex: _ordersIndexForRole(currentUser.roleCode),
        ),
      ),
      (_) => false,
    );
  }

  int _ordersIndexForRole(String roleCode) {
    switch (roleCode) {
      case RoleCodes.customer:
        return 2;
      case RoleCodes.expert:
      case RoleCodes.optiYouTeam:
        return 3;
      default:
        return 0;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final state = _visualState(l10n);

    return Scaffold(
      appBar: AppBar(
        actions: const [LanguageSelector(), SizedBox(width: 12)],
        title: Text(l10n.paymentResultTitle),
        backgroundColor: Colors.teal,
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(28),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (state.showProgress)
                      const SizedBox(
                        width: 68,
                        height: 68,
                        child: CircularProgressIndicator(strokeWidth: 5),
                      )
                    else
                      Icon(state.icon, size: 76, color: state.color),
                    const SizedBox(height: 20),
                    Text(
                      state.title,
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      state.description,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.grey.shade700,
                        height: 1.45,
                      ),
                    ),
                    if (_result?.orderNo != null) ...[
                      const SizedBox(height: 22),
                      _ResultInfoRow(
                        icon: Icons.receipt_long_outlined,
                        text: l10n.orderNumberValue(_result!.orderNo!),
                      ),
                    ],
                    if (_result?.amount != null) ...[
                      const SizedBox(height: 10),
                      _ResultInfoRow(
                        icon: Icons.verified_outlined,
                        text: l10n.paidAmountValue(_formatAmount(_result!)),
                      ),
                    ],
                    if (_loadError != null) ...[
                      const SizedBox(height: 18),
                      Text(
                        l10n.paymentStatusLoadError(_loadError!),
                        style: const TextStyle(color: Colors.red),
                        textAlign: TextAlign.center,
                      ),
                    ],
                    const SizedBox(height: 26),
                    Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      alignment: WrapAlignment.center,
                      children: [
                        if (!(_result?.isPaid ?? false))
                          OutlinedButton.icon(
                            onPressed: _isLoading ? null : _refreshStatus,
                            icon: const Icon(Icons.refresh),
                            label: Text(l10n.checkAgain),
                          ),
                        ElevatedButton.icon(
                          onPressed: () async {
                            try {
                              await _goToOrders();
                            } catch (error) {
                              if (!context.mounted) return;
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    l10n.ordersNavigationError(
                                      error.toString(),
                                    ),
                                  ),
                                ),
                              );
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.teal,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 22,
                              vertical: 14,
                            ),
                          ),
                          icon: const Icon(Icons.shopping_bag_outlined),
                          label: Text(l10n.goToMyOrders),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  String _formatAmount(IyzicoCheckoutStatusResult result) {
    final formatted = NumberFormat.currency(
      locale: Localizations.localeOf(context).toLanguageTag(),
      symbol: '',
      decimalDigits: 2,
    ).format(result.amount).trim();
    return '$formatted ${result.currency ?? 'TRY'}';
  }

  _PaymentVisualState _visualState(AppLocalizations l10n) {
    if (_result?.isPaid == true) {
      return _PaymentVisualState(
        title: l10n.paymentSuccessTitle,
        description: l10n.paymentSuccessDescription,
        icon: Icons.check_circle,
        color: Colors.green,
      );
    }
    if (_result?.isFailed == true ||
        (_result == null && widget.token == null && widget.success == false)) {
      return _PaymentVisualState(
        title: l10n.paymentFailedTitle,
        description: l10n.paymentFailedDescription,
        icon: Icons.cancel,
        color: Colors.red,
      );
    }
    if (_result == null && widget.token == null && widget.success == true) {
      return _PaymentVisualState(
        title: l10n.paymentSuccessTitle,
        description: l10n.paymentSuccessDescription,
        icon: Icons.check_circle,
        color: Colors.green,
      );
    }
    return _PaymentVisualState(
      title: l10n.paymentCheckingTitle,
      description: l10n.paymentCheckingDescription,
      icon: Icons.hourglass_top,
      color: Colors.orange,
      showProgress: true,
    );
  }
}

class _PaymentVisualState {
  const _PaymentVisualState({
    required this.title,
    required this.description,
    required this.icon,
    required this.color,
    this.showProgress = false,
  });

  final String title;
  final String description;
  final IconData icon;
  final Color color;
  final bool showProgress;
}

class _ResultInfoRow extends StatelessWidget {
  const _ResultInfoRow({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.teal.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(icon, color: Colors.teal),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}
