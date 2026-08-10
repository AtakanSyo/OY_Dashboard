import 'package:flutter/material.dart';
import 'package:oy_site/models/store_product_model.dart';
import 'package:oy_site/models/store_measurement_summary_model.dart';
import 'package:oy_site/screens/dashboard/store/store_screen.dart';

import 'package:oy_site/services/payment/iyzico_checkout_service.dart';
import 'package:oy_site/services/payment/payment_popup_handle.dart';
import 'package:url_launcher/url_launcher.dart';

class StoreProductDetailScreen extends StatefulWidget {
  final StoreProduct product;
  final StoreMeasurementSummary measurement;

  const StoreProductDetailScreen({
    super.key,
    required this.product,
    required this.measurement,
  });

  @override
  State<StoreProductDetailScreen> createState() =>
      _StoreProductDetailScreenState();
}

class _StoreProductDetailScreenState extends State<StoreProductDetailScreen> {
  final IyzicoCheckoutService _checkoutService = IyzicoCheckoutService();

  bool _isStartingPayment = false;
  StoreDeliveryAddress? _selectedAddress;

  final List<StoreDeliveryAddress> _savedAddresses = [
    const StoreDeliveryAddress(
      title: 'Ev Adresi',
      fullName: 'Test Kullanıcı',
      phone: '+90 555 000 00 00',
      city: 'İzmir',
      district: 'Balçova',
      addressLine:
          'Örnek Mahallesi, Örnek Sokak No: 1 Daire: 2',
    ),
  ];

  Future<void> _handleBuyPressed() async {
    final address = await _showAddressDialog();

    if (address == null) return;

    setState(() {
      _selectedAddress = address;
    });

    await _startPayment();
  }

  Future<StoreDeliveryAddress?> _showAddressDialog() async {
    return showDialog<StoreDeliveryAddress>(
      context: context,
      barrierDismissible: false,
      builder: (_) => StoreAddressDialog(
        savedAddresses: _savedAddresses,
        selectedAddress: _selectedAddress,
      ),
    );
  }

  Future<void> _startPayment() async {
    if (_isStartingPayment) return;

    setState(() => _isStartingPayment = true);

    final popup = openPaymentPopup();
    var popupNavigated = false;

    try {
      final checkout = await _checkoutService.initializeCheckout(
        productId: widget.product.id,
      );

      final url = checkout.paymentPageUrl!;
      final uri = Uri.tryParse(url);

      if (uri == null) {
        throw Exception('Geçersiz ödeme URL\'i alındı.');
      }

      if (popup != null) {
        popup.navigate(url);
        popupNavigated = true;
      } else {
        final opened = await launchUrl(
          uri,
          webOnlyWindowName: '_blank',
        );

        if (!opened) {
          throw Exception('Ödeme sayfası açılamadı.');
        }
      }
    } catch (e) {
      if (popup != null && !popupNavigated) {
        popup.close();
      }

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Ödeme başlatılamadı: $e'),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isStartingPayment = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.product.title),
        backgroundColor: Colors.teal,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1000),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                buildMeasurementCard(
                  measurement: widget.measurement,
                  compact: false,
                ),
                const SizedBox(height: 24),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(22),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(18),
                    boxShadow: const [
                      BoxShadow(
                        color: Colors.black12,
                        blurRadius: 8,
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Stack(
                            children: [
                              Container(
                                width: 110,
                                height: 110,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(16),
                                  color: Colors.grey.shade100,
                                ),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(16),
                                  child: Image.asset(
                                    widget.product.imagePath,
                                    fit: BoxFit.contain,
                                  ),
                                ),
                              ),
                              Positioned(
                                bottom: 8,
                                right: 8,
                                child: CircleAvatar(
                                  radius: 18,
                                  backgroundColor: Colors.white,
                                  child: Icon(
                                    widget.product.icon,
                                    size: 18,
                                    color: Colors.teal,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
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
                                    color: Colors.grey[700],
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
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      _buildInfoSection(
                        title: 'Ürün Hakkında',
                        content: widget.product.fullDescription,
                      ),
                      const SizedBox(height: 18),
                      _buildInfoSection(
                        title: widget.product.usageTitle,
                        content: widget.product.usageDescription,
                      ),
                      const SizedBox(height: 18),
                      _buildInfoSection(
                        title: 'Neden Bu Ürün Öneriliyor?',
                        content: widget.product.whyRecommended,
                      ),
                      if (_selectedAddress != null) ...[
                        const SizedBox(height: 22),
                        _buildSelectedAddressCard(_selectedAddress!),
                      ],
                      const SizedBox(height: 28),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: ElevatedButton(
                          onPressed:
                              _isStartingPayment ? null : _handleBuyPressed,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.teal,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 24,
                              vertical: 16,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: _isStartingPayment
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Text(
                                  'Satın Al',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSelectedAddressCard(StoreDeliveryAddress address) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.teal.withOpacity(0.06),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.teal.withOpacity(0.18)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.location_on_outlined, color: Colors.teal),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              '${address.title}\n'
              '${address.fullName} • ${address.phone}\n'
              '${address.addressLine}, ${address.district}/${address.city}',
              style: const TextStyle(height: 1.45),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoSection({
    required String title,
    required String content,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          content,
          style: TextStyle(
            color: Colors.grey[800],
            height: 1.5,
          ),
        ),
      ],
    );
  }
}

class StoreDeliveryAddress {
  final String title;
  final String fullName;
  final String phone;
  final String city;
  final String district;
  final String addressLine;

  const StoreDeliveryAddress({
    required this.title,
    required this.fullName,
    required this.phone,
    required this.city,
    required this.district,
    required this.addressLine,
  });
}

class StoreAddressDialog extends StatefulWidget {
  final List<StoreDeliveryAddress> savedAddresses;
  final StoreDeliveryAddress? selectedAddress;

  const StoreAddressDialog({
    super.key,
    required this.savedAddresses,
    this.selectedAddress,
  });

  @override
  State<StoreAddressDialog> createState() => _StoreAddressDialogState();
}

class _StoreAddressDialogState extends State<StoreAddressDialog> {
  final _formKey = GlobalKey<FormState>();

  late List<StoreDeliveryAddress> _addresses;
  StoreDeliveryAddress? _selectedAddress;
  bool _showAddressForm = false;

  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _fullNameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _cityController = TextEditingController();
  final TextEditingController _districtController = TextEditingController();
  final TextEditingController _addressLineController =
      TextEditingController();

  @override
  void initState() {
    super.initState();
    _addresses = List<StoreDeliveryAddress>.from(widget.savedAddresses);
    _selectedAddress = widget.selectedAddress ??
        (_addresses.isNotEmpty ? _addresses.first : null);
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

  void _editAddress(StoreDeliveryAddress address) {
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

  void _saveAddressForm() {
    if (!_formKey.currentState!.validate()) return;

    final address = StoreDeliveryAddress(
      title: _titleController.text.trim(),
      fullName: _fullNameController.text.trim(),
      phone: _phoneController.text.trim(),
      city: _cityController.text.trim(),
      district: _districtController.text.trim(),
      addressLine: _addressLineController.text.trim(),
    );

    setState(() {
      if (_selectedAddress != null) {
        final index = _addresses.indexOf(_selectedAddress!);
        if (index >= 0) {
          _addresses[index] = address;
        }
      } else {
        _addresses.add(address);
      }

      _selectedAddress = address;
      _showAddressForm = false;
    });
  }

  void _continueToPayment() {
    if (_showAddressForm) {
      _saveAddressForm();
      return;
    }

    if (_selectedAddress == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Lütfen bir teslimat adresi seçin.'),
        ),
      );
      return;
    }

    Navigator.pop(context, _selectedAddress);
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: const EdgeInsets.all(24),
      child: SizedBox(
        width: 720,
        height: 640,
        child: Padding(
          padding: const EdgeInsets.all(22),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Teslimat Adresi',
                      style: TextStyle(
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
                'Ödeme sayfasına geçmeden önce teslimat adresinizi seçin veya yeni adres ekleyin.',
                style: TextStyle(color: Colors.grey[700]),
              ),
              const SizedBox(height: 18),
              Expanded(
                child: _showAddressForm
                    ? _buildAddressForm()
                    : _buildAddressList(),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  if (!_showAddressForm)
                    OutlinedButton.icon(
                      onPressed: _startNewAddress,
                      icon: const Icon(Icons.add),
                      label: const Text('Yeni Adres Ekle'),
                    )
                  else
                    OutlinedButton(
                      onPressed: () {
                        setState(() {
                          _showAddressForm = false;
                        });
                      },
                      child: const Text('Listeye Dön'),
                    ),
                  const Spacer(),
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Vazgeç'),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: _continueToPayment,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.teal,
                      foregroundColor: Colors.white,
                    ),
                    child: Text(
                      _showAddressForm
                          ? 'Adresi Kaydet'
                          : 'Ödemeye Geç',
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

  Widget _buildAddressList() {
    if (_addresses.isEmpty) {
      return Center(
        child: Text(
          'Kayıtlı adres bulunamadı. Yeni adres ekleyerek devam edin.',
          style: TextStyle(color: Colors.grey[700]),
        ),
      );
    }

    return ListView.separated(
      itemCount: _addresses.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        final address = _addresses[index];
        final isSelected = identical(address, _selectedAddress) ||
            address == _selectedAddress;

        return InkWell(
          onTap: () {
            setState(() {
              _selectedAddress = address;
            });
          },
          borderRadius: BorderRadius.circular(14),
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: isSelected
                  ? Colors.teal.withOpacity(0.08)
                  : Colors.grey.shade50,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: isSelected
                    ? Colors.teal
                    : Colors.grey.shade300,
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Radio<StoreDeliveryAddress>(
                  value: address,
                  groupValue: _selectedAddress,
                  onChanged: (value) {
                    setState(() {
                      _selectedAddress = value;
                    });
                  },
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    '${address.title}\n'
                    '${address.fullName} • ${address.phone}\n'
                    '${address.addressLine}, ${address.district}/${address.city}',
                    style: const TextStyle(height: 1.45),
                  ),
                ),
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

  Widget _buildAddressForm() {
    return SingleChildScrollView(
      child: Form(
        key: _formKey,
        child: Column(
          children: [
            _input(_titleController, 'Adres Başlığı'),
            const SizedBox(height: 12),
            _input(_fullNameController, 'Ad Soyad'),
            const SizedBox(height: 12),
            _input(_phoneController, 'Telefon'),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(child: _input(_cityController, 'İl')),
                const SizedBox(width: 12),
                Expanded(child: _input(_districtController, 'İlçe')),
              ],
            ),
            const SizedBox(height: 12),
            _input(
              _addressLineController,
              'Açık Adres',
              maxLines: 4,
            ),
          ],
        ),
      ),
    );
  }

  Widget _input(
    TextEditingController controller,
    String label, {
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
          return '$label zorunludur';
        }
        return null;
      },
    );
  }
}