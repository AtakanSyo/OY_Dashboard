import 'package:flutter/material.dart';
import 'package:oy_site/data/repositories/supabase_store_repository.dart';
import 'package:oy_site/models/store_product_model.dart';

class StoreManagementScreen extends StatefulWidget {
  const StoreManagementScreen({super.key});

  @override
  State<StoreManagementScreen> createState() => _StoreManagementScreenState();
}

class _StoreManagementScreenState extends State<StoreManagementScreen> {
  final _repository = SupabaseStoreRepository();
  List<StoreProduct> _products = const [];
  List<StoreClinic> _clinics = const [];
  int? _clinicId;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final results = await Future.wait([
        _repository.getProducts(clinicId: _clinicId, includeInactive: true),
        _repository.getClinics(),
      ]);
      if (!mounted) return;
      setState(() {
        _products = results[0] as List<StoreProduct>;
        _clinics = results[1] as List<StoreClinic>;
        _loading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _error = error.toString();
        _loading = false;
      });
    }
  }

  Future<void> _editProduct([StoreProduct? product]) async {
    final saved = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => _ProductEditor(repository: _repository, product: product),
    );
    if (saved == true) await _load();
  }

  Future<void> _editClinicPrice(StoreProduct product) async {
    if (_clinicId == null) return;
    final controller = TextEditingController(
      text: product.price.toStringAsFixed(2),
    );
    final result = await showDialog<double?>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('${product.title} • Klinik fiyatı'),
        content: TextField(
          controller: controller,
          autofocus: true,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: const InputDecoration(
            labelText: 'Fiyat',
            suffixText: 'TRY',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('İptal'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, -1.0),
            child: const Text('Genel fiyatı kullan'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(
              context,
              double.tryParse(controller.text.replaceAll(',', '.')),
            ),
            child: const Text('Kaydet'),
          ),
        ],
      ),
    );
    controller.dispose();
    if (result == null) return;
    await _repository.setClinicPrice(
      productId: product.id,
      clinicId: _clinicId!,
      price: result < 0 ? null : result,
    );
    await _load();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xfff6f8f8),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Mağaza yönetimi',
                        style: TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Ürünleri, görünürlüğü ve kliniğe özel satış fiyatlarını yönetin.',
                      ),
                    ],
                  ),
                ),
                FilledButton.icon(
                  onPressed: () => _editProduct(),
                  icon: const Icon(Icons.add),
                  label: const Text('Yeni ürün'),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    const Icon(Icons.location_on_outlined, color: Colors.teal),
                    const SizedBox(width: 12),
                    const Text(
                      'Fiyat görünümü:',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(width: 12),
                    SizedBox(
                      width: 280,
                      child: DropdownButtonFormField<int?>(
                        initialValue: _clinicId,
                        decoration: const InputDecoration(
                          isDense: true,
                          border: OutlineInputBorder(),
                        ),
                        items: [
                          const DropdownMenuItem(
                            value: null,
                            child: Text('Genel mağaza fiyatları'),
                          ),
                          ..._clinics.map(
                            (c) => DropdownMenuItem(
                              value: c.id,
                              child: Text(c.name),
                            ),
                          ),
                        ],
                        onChanged: (value) {
                          setState(() => _clinicId = value);
                          _load();
                        },
                      ),
                    ),
                    if (_clinicId != null) ...[
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Text(
                          'Bu klinikte müşteriye gösterilecek etkili fiyatları düzenliyorsunuz.',
                          style: TextStyle(color: Colors.black54),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Expanded(child: _buildContent()),
          ],
        ),
      ),
    );
  }

  Widget _buildContent() {
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_error != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.cloud_off, size: 44),
            const SizedBox(height: 12),
            const Text('Ürünler yüklenemedi.'),
            const SizedBox(height: 8),
            OutlinedButton(onPressed: _load, child: const Text('Tekrar dene')),
          ],
        ),
      );
    }
    if (_products.isEmpty) {
      return Center(
        child: OutlinedButton.icon(
          onPressed: () => _editProduct(),
          icon: const Icon(Icons.add),
          label: const Text('İlk ürünü ekle'),
        ),
      );
    }
    return Card(
      clipBehavior: Clip.antiAlias,
      child: ListView.separated(
        itemCount: _products.length,
        separatorBuilder: (_, _) => const Divider(height: 1),
        itemBuilder: (context, index) {
          final product = _products[index];
          return ListTile(
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 18,
              vertical: 8,
            ),
            leading: CircleAvatar(
              backgroundColor: product.isActive
                  ? Colors.teal.shade50
                  : Colors.grey.shade200,
              child: Icon(
                product.icon,
                color: product.isActive ? Colors.teal : Colors.grey,
              ),
            ),
            title: Row(
              children: [
                Expanded(
                  child: Text(
                    product.title,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
                if (!product.isActive)
                  const Chip(
                    label: Text('Yayında değil'),
                    visualDensity: VisualDensity.compact,
                  ),
              ],
            ),
            subtitle: Text(
              product.shortDescription,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  width: 120,
                  child: Text(
                    product.priceLabel,
                    textAlign: TextAlign.end,
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      color: Colors.teal,
                    ),
                  ),
                ),
                if (_clinicId != null)
                  IconButton(
                    tooltip: 'Klinik fiyatını düzenle',
                    onPressed: () => _editClinicPrice(product),
                    icon: const Icon(Icons.price_change_outlined),
                  ),
                IconButton(
                  tooltip: 'Ürünü düzenle',
                  onPressed: () => _editProduct(product),
                  icon: const Icon(Icons.edit_outlined),
                ),
                Switch(
                  value: product.isActive,
                  onChanged: (value) async {
                    await _repository.setActive(product.id, value);
                    await _load();
                  },
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _ProductEditor extends StatefulWidget {
  const _ProductEditor({required this.repository, this.product});
  final SupabaseStoreRepository repository;
  final StoreProduct? product;
  @override
  State<_ProductEditor> createState() => _ProductEditorState();
}

class _ProductEditorState extends State<_ProductEditor> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _title,
      _short,
      _full,
      _usage,
      _price,
      _image;
  bool _isAddOn = false, _active = true, _saving = false;
  @override
  void initState() {
    super.initState();
    final p = widget.product;
    _title = TextEditingController(text: p?.title);
    _short = TextEditingController(text: p?.shortDescription);
    _full = TextEditingController(text: p?.fullDescription);
    _usage = TextEditingController(text: p?.usageDescription);
    _price = TextEditingController(
      text: p == null ? '' : p.price.toStringAsFixed(2),
    );
    _image = TextEditingController(text: p?.imagePath);
    _isAddOn = p?.isAddOn ?? false;
    _active = p?.isActive ?? true;
  }

  @override
  void dispose() {
    for (final c in [_title, _short, _full, _usage, _price, _image]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      await widget.repository.saveProduct(
        id: widget.product?.id,
        values: {
          'title': _title.text.trim(),
          'short_description': _short.text.trim(),
          'full_description': _full.text.trim(),
          'usage_title': 'Kimler için uygun?',
          'usage_description': _usage.text.trim(),
          'why_recommended': 'Öneriler bilgilendirme amaçlıdır.',
          'base_price': double.parse(_price.text.replaceAll(',', '.')),
          'currency_code': 'TRY',
          'image_path': _image.text.trim(),
          'is_add_on': _isAddOn,
          'can_be_purchased_alone': true,
          'is_active': _active,
        },
      );
      if (mounted) {
        Navigator.pop(context, true);
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Kaydedilemedi: $error')));
      }
    }
    if (mounted) {
      setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    InputDecoration decoration(String label) =>
        InputDecoration(labelText: label, border: const OutlineInputBorder());
    String? requiredField(String? value) =>
        value == null || value.trim().isEmpty ? 'Bu alan zorunludur.' : null;
    return AlertDialog(
      title: Text(widget.product == null ? 'Yeni ürün' : 'Ürünü düzenle'),
      content: SizedBox(
        width: 620,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              children: [
                TextFormField(
                  controller: _title,
                  decoration: decoration('Ürün adı'),
                  validator: requiredField,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _short,
                  decoration: decoration('Kısa açıklama'),
                  validator: requiredField,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _full,
                  decoration: decoration('Detaylı açıklama'),
                  maxLines: 3,
                  validator: requiredField,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _usage,
                  decoration: decoration('Kullanım / uygunluk bilgisi'),
                  maxLines: 2,
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _price,
                        decoration: decoration('Genel fiyat (TRY)'),
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        validator: (v) =>
                            double.tryParse((v ?? '').replaceAll(',', '.')) ==
                                null
                            ? 'Geçerli bir fiyat girin.'
                            : null,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextFormField(
                        controller: _image,
                        decoration: decoration('Görsel yolu'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Aksesuar / ek ürün'),
                  value: _isAddOn,
                  onChanged: (v) => setState(() => _isAddOn = v),
                ),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Mağazada yayınla'),
                  value: _active,
                  onChanged: (v) => setState(() => _active = v),
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _saving ? null : () => Navigator.pop(context),
          child: const Text('İptal'),
        ),
        FilledButton(
          onPressed: _saving ? null : _save,
          child: Text(_saving ? 'Kaydediliyor…' : 'Kaydet'),
        ),
      ],
    );
  }
}
