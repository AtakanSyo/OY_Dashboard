import 'package:flutter/material.dart';
import 'package:oy_site/data/repositories/supabase_customer_address_repository.dart';
import 'package:oy_site/l10n/app_localizations.dart';
import 'package:oy_site/models/customer_address_model.dart';
import 'package:oy_site/models/store_measurement_summary_model.dart';
import 'package:oy_site/models/store_product_model.dart';
import 'package:oy_site/screens/payment_result_screen.dart';
import 'package:oy_site/screens/dashboard/store/store_screen.dart';
import 'package:oy_site/services/payment/iyzico_checkout_service.dart';
import 'package:oy_site/services/payment/payment_popup_handle.dart';
import 'package:url_launcher/url_launcher.dart';

class StoreProductDetailScreen extends StatefulWidget {
  final StoreProduct product;
  final StoreMeasurementSummary? measurement;

  const StoreProductDetailScreen({
    super.key,
    required this.product,
    this.measurement,
  });

  @override
  State<StoreProductDetailScreen> createState() =>
      _StoreProductDetailScreenState();
}

class _StoreProductDetailScreenState extends State<StoreProductDetailScreen> {
  final IyzicoCheckoutService _checkoutService = IyzicoCheckoutService();
  final CustomerAddressRepository _addressRepository =
      SupabaseCustomerAddressRepository();

  bool _isStartingPayment = false;
  bool _addressesLoaded = false;
  List<CustomerAddressModel> _addresses = [];
  CustomerAddressModel? _selectedAddress;

  Future<void> _loadAddresses() async {
    final addresses = await _addressRepository.getAddressesForCurrentCustomer();
    if (!mounted) return;
    setState(() {
      _addresses = addresses;
      _selectedAddress = addresses.cast<CustomerAddressModel?>().firstWhere(
        (address) => address?.isDefault == true,
        orElse: () => addresses.isEmpty ? null : addresses.first,
      );
      _addressesLoaded = true;
    });
  }

  Future<void> _handleBuyPressed() async {
    try {
      if (!_addressesLoaded) await _loadAddresses();
      if (!mounted) return;
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            AppLocalizations.of(context).addressLoadError(error.toString()),
          ),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final address = await showDialog<CustomerAddressModel>(
      context: context,
      barrierDismissible: false,
      builder: (_) => StoreAddressDialog(
        savedAddresses: _addresses,
        selectedAddress: _selectedAddress,
        onSave: _addressRepository.saveAddress,
      ),
    );
    if (address == null || !mounted) return;

    setState(() {
      _selectedAddress = address;
      final index = _addresses.indexWhere(
        (item) => item.addressId == address.addressId,
      );
      if (index >= 0) {
        _addresses[index] = address;
      } else {
        _addresses.add(address);
      }
    });
    await _startPayment();
  }

  Future<void> _startPayment() async {
    if (_isStartingPayment) return;
    setState(() => _isStartingPayment = true);

    final popup = openPaymentPopup();
    var popupNavigated = false;
    try {
      final l10n = AppLocalizations.of(context);
      final checkout = await _checkoutService.initializeCheckout(
        productId: widget.product.id,
        addressId: _selectedAddress!.addressId!,
        sessionId: widget.measurement?.sessionId,
        locale: Localizations.localeOf(context).languageCode,
      );
      final url = checkout.paymentPageUrl!;
      final uri = Uri.tryParse(url);
      if (uri == null) throw Exception(l10n.paymentInvalidUrl);

      if (popup != null) {
        popup.navigate(url);
        popupNavigated = true;
      } else {
        final opened = await launchUrl(uri, webOnlyWindowName: '_blank');
        if (!opened) throw Exception(l10n.paymentPageOpenError);
      }

      if (!mounted) return;
      await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => PaymentResultScreen(
            token: checkout.token,
            pressureRepository: null,
          ),
        ),
      );
    } catch (error) {
      if (popup != null && !popupNavigated) popup.close();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            AppLocalizations.of(context).paymentStartError(error.toString()),
          ),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) setState(() => _isStartingPayment = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: Text(widget.product.title),
        backgroundColor: Colors.teal,
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final pagePadding = constraints.maxWidth < 650 ? 16.0 : 24.0;
          return SingleChildScrollView(
            padding: EdgeInsets.all(pagePadding),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1000),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (widget.measurement != null) ...[
                      buildMeasurementCard(
                        context: context,
                        measurement: widget.measurement!,
                        compact: false,
                      ),
                      const SizedBox(height: 20),
                    ],
                    _buildProductCard(l10n),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildProductCard(AppLocalizations l10n) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 8)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          LayoutBuilder(
            builder: (context, constraints) {
              final image = Container(
                width: constraints.maxWidth < 560 ? double.infinity : 220,
                height: 180,
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Image.asset(
                    widget.product.imagePath,
                    fit: BoxFit.contain,
                    errorBuilder: (_, _, _) =>
                        Center(child: Text(l10n.imageUnavailable)),
                  ),
                ),
              );
              final summary = Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.product.title,
                    style: const TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    widget.product.shortDescription,
                    style: TextStyle(
                      color: Colors.grey.shade700,
                      height: 1.4,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    widget.product.priceLabel,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.teal,
                    ),
                  ),
                ],
              );

              if (constraints.maxWidth < 560) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [image, const SizedBox(height: 16), summary],
                );
              }
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  image,
                  const SizedBox(width: 20),
                  Expanded(child: summary),
                ],
              );
            },
          ),
          const SizedBox(height: 24),
          _InfoSection(
            title: l10n.productAbout,
            content: widget.product.fullDescription,
          ),
          const SizedBox(height: 18),
          _InfoSection(
            title: widget.product.usageTitle,
            content: widget.product.usageDescription,
          ),
          const SizedBox(height: 18),
          _InfoSection(
            title: l10n.whyRecommended,
            content: widget.product.whyRecommended,
          ),
          if (_selectedAddress != null) ...[
            const SizedBox(height: 22),
            _SelectedAddressCard(address: _selectedAddress!),
          ],
          const SizedBox(height: 26),
          ElevatedButton.icon(
            onPressed: _isStartingPayment ? null : _handleBuyPressed,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.teal,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            icon: _isStartingPayment
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Icon(Icons.shopping_bag_outlined),
            label: Text(l10n.purchase),
          ),
        ],
      ),
    );
  }
}

class StoreAddressDialog extends StatefulWidget {
  final List<CustomerAddressModel> savedAddresses;
  final CustomerAddressModel? selectedAddress;
  final Future<CustomerAddressModel> Function(CustomerAddressModel address)
  onSave;

  const StoreAddressDialog({
    super.key,
    required this.savedAddresses,
    required this.onSave,
    this.selectedAddress,
  });

  @override
  State<StoreAddressDialog> createState() => _StoreAddressDialogState();
}

class _StoreAddressDialogState extends State<StoreAddressDialog> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _fullNameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _cityController = TextEditingController();
  final _districtController = TextEditingController();
  final _addressLineController = TextEditingController();

  late List<CustomerAddressModel> _addresses;
  CustomerAddressModel? _selectedAddress;
  bool _showAddressForm = false;
  bool _isSaving = false;
  String? _saveError;

  @override
  void initState() {
    super.initState();
    _addresses = List<CustomerAddressModel>.from(widget.savedAddresses);
    _selectedAddress =
        widget.selectedAddress ??
        (_addresses.isNotEmpty ? _addresses.first : null);
    _showAddressForm = _addresses.isEmpty;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _fullNameController.dispose();
    _phoneController.dispose();
    _cityController.dispose();
    _districtController.dispose();
    _addressLineController.dispose();
    super.dispose();
  }

  void _startNewAddress() {
    setState(() {
      _showAddressForm = true;
      _selectedAddress = null;
      _titleController.clear();
      _fullNameController.clear();
      _phoneController.clear();
      _cityController.clear();
      _districtController.clear();
      _addressLineController.clear();
    });
  }

  void _editAddress(CustomerAddressModel address) {
    setState(() {
      _showAddressForm = true;
      _selectedAddress = address;
      _titleController.text = address.title;
      _fullNameController.text = address.fullName;
      _phoneController.text = address.phone;
      _cityController.text = address.city;
      _districtController.text = address.district;
      _addressLineController.text = address.addressLine;
    });
  }

  Future<CustomerAddressModel?> _saveAddressForm() async {
    if (!_formKey.currentState!.validate()) return null;
    final draft = CustomerAddressModel(
      addressId: _selectedAddress?.addressId,
      userId: _selectedAddress?.userId,
      patientId: _selectedAddress?.patientId,
      title: _titleController.text.trim(),
      fullName: _fullNameController.text.trim(),
      phone: _phoneController.text.trim(),
      city: _cityController.text.trim(),
      district: _districtController.text.trim(),
      addressLine: _addressLineController.text.trim(),
      isDefault: _selectedAddress?.isDefault ?? _addresses.isEmpty,
    );

    setState(() {
      _isSaving = true;
      _saveError = null;
    });
    try {
      final address = await widget.onSave(draft);
      if (!mounted) return null;
      setState(() {
        final index = _addresses.indexWhere(
          (item) => item.addressId == address.addressId,
        );
        if (index >= 0) {
          _addresses[index] = address;
        } else {
          _addresses.add(address);
        }
        _selectedAddress = address;
        _showAddressForm = false;
        _isSaving = false;
      });
      return address;
    } catch (error) {
      if (!mounted) return null;
      setState(() {
        _isSaving = false;
        _saveError = AppLocalizations.of(
          context,
        ).addressSaveError(error.toString());
      });
      return null;
    }
  }

  Future<void> _continue() async {
    if (_showAddressForm) {
      final address = await _saveAddressForm();
      if (address != null && mounted) Navigator.pop(context, address);
      return;
    }
    if (_selectedAddress == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context).selectDeliveryAddress),
        ),
      );
      return;
    }
    Navigator.pop(context, _selectedAddress);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final screen = MediaQuery.sizeOf(context);
    return Dialog(
      insetPadding: const EdgeInsets.all(16),
      child: SizedBox(
        width: 720,
        height: screen.height < 700 ? screen.height - 32 : 640,
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      l10n.deliveryAddressTitle,
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                l10n.deliveryAddressDescription,
                style: TextStyle(color: Colors.grey.shade700),
              ),
              const SizedBox(height: 18),
              Expanded(
                child: _showAddressForm
                    ? _buildAddressForm(l10n)
                    : _buildAddressList(l10n),
              ),
              if (_saveError != null) ...[
                const SizedBox(height: 10),
                Text(_saveError!, style: const TextStyle(color: Colors.red)),
              ],
              const SizedBox(height: 14),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                alignment: WrapAlignment.end,
                children: [
                  if (!_showAddressForm)
                    OutlinedButton.icon(
                      onPressed: _startNewAddress,
                      icon: const Icon(Icons.add),
                      label: Text(l10n.addNewAddress),
                    )
                  else if (_addresses.isNotEmpty)
                    OutlinedButton(
                      onPressed: () => setState(() => _showAddressForm = false),
                      child: Text(l10n.backToList),
                    ),
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text(l10n.cancel),
                  ),
                  ElevatedButton(
                    onPressed: _isSaving ? null : _continue,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.teal,
                      foregroundColor: Colors.white,
                    ),
                    child: _isSaving
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : Text(
                            _showAddressForm
                                ? l10n.save
                                : l10n.continueToPayment,
                          ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAddressList(AppLocalizations l10n) {
    if (_addresses.isEmpty) {
      return Center(child: Text(l10n.noSavedAddress));
    }
    return ListView.separated(
      itemCount: _addresses.length,
      separatorBuilder: (_, _) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        final address = _addresses[index];
        final selected = address.addressId == _selectedAddress?.addressId;
        return InkWell(
          onTap: () => setState(() => _selectedAddress = address),
          borderRadius: BorderRadius.circular(14),
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: selected
                  ? Colors.teal.withValues(alpha: 0.08)
                  : Colors.grey.shade50,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: selected ? Colors.teal : Colors.grey.shade300,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  selected
                      ? Icons.radio_button_checked
                      : Icons.radio_button_unchecked,
                  color: selected ? Colors.teal : Colors.grey.shade600,
                ),
                const SizedBox(width: 12),
                Expanded(child: Text(address.displayText)),
                IconButton(
                  onPressed: () => _editAddress(address),
                  icon: const Icon(Icons.edit_outlined),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildAddressForm(AppLocalizations l10n) {
    return SingleChildScrollView(
      child: Form(
        key: _formKey,
        child: Column(
          children: [
            _input(_titleController, l10n.addressTitle, l10n),
            const SizedBox(height: 12),
            _input(_fullNameController, l10n.fullName, l10n),
            const SizedBox(height: 12),
            _input(_phoneController, l10n.phone, l10n),
            const SizedBox(height: 12),
            LayoutBuilder(
              builder: (context, constraints) {
                final city = _input(_cityController, l10n.city, l10n);
                final district = _input(
                  _districtController,
                  l10n.district,
                  l10n,
                );
                if (constraints.maxWidth < 520) {
                  return Column(
                    children: [city, const SizedBox(height: 12), district],
                  );
                }
                return Row(
                  children: [
                    Expanded(child: city),
                    const SizedBox(width: 12),
                    Expanded(child: district),
                  ],
                );
              },
            ),
            const SizedBox(height: 12),
            _input(_addressLineController, l10n.addressLine, l10n, maxLines: 4),
          ],
        ),
      ),
    );
  }

  Widget _input(
    TextEditingController controller,
    String label,
    AppLocalizations l10n, {
    int maxLines = 1,
  }) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
      ),
      validator: (value) {
        if (value == null || value.trim().isEmpty) {
          return l10n.requiredField(label);
        }
        return null;
      },
    );
  }
}

class _InfoSection extends StatelessWidget {
  final String title;
  final String content;

  const _InfoSection({required this.title, required this.content});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Text(
          content,
          style: TextStyle(color: Colors.grey.shade800, height: 1.5),
        ),
      ],
    );
  }
}

class _SelectedAddressCard extends StatelessWidget {
  final CustomerAddressModel address;

  const _SelectedAddressCard({required this.address});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.teal.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.teal.withValues(alpha: 0.18)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.location_on_outlined, color: Colors.teal),
          const SizedBox(width: 10),
          Expanded(child: Text(address.displayText)),
        ],
      ),
    );
  }
}
