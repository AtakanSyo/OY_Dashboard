import 'package:oy_site/models/store_product_model.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class StoreClinic {
  const StoreClinic({required this.id, required this.name});
  final int id;
  final String name;
}

class SupabaseStoreRepository {
  SupabaseClient get _client => Supabase.instance.client;

  Future<List<StoreProduct>> getProducts({
    int? clinicId,
    bool includeInactive = false,
  }) async {
    final rows = await _client.rpc(
      'get_store_products',
      params: {'p_clinic_id': clinicId, 'p_include_inactive': includeInactive},
    );
    return (rows as List).map((raw) {
      final row = Map<String, dynamic>.from(raw as Map);
      final amount = (row['effective_price'] as num?)?.toDouble() ?? 0;
      final currency = (row['currency_code'] ?? 'TRY').toString();
      return StoreProduct.fromMap(
        row,
        priceLabel: '${_formatAmount(amount)} $currency',
      );
    }).toList();
  }

  Future<List<StoreClinic>> getClinics() async {
    final rows = await _client
        .from('clinics')
        .select('id, clinic_name')
        .order('clinic_name');
    return (rows as List).map((raw) {
      final row = Map<String, dynamic>.from(raw as Map);
      return StoreClinic(
        id: (row['id'] as num).toInt(),
        name: row['clinic_name'].toString(),
      );
    }).toList();
  }

  Future<void> saveProduct({
    String? id,
    required Map<String, dynamic> values,
  }) async {
    if (id == null) {
      final title = (values['title'] ?? 'urun').toString().toLowerCase();
      final slug = title
          .replaceAll(RegExp(r'[^a-z0-9]+'), '-')
          .replaceAll(RegExp(r'^-|-$'), '');
      await _client.from('store_products').insert({
        ...values,
        'id':
            '${slug.isEmpty ? 'urun' : slug}-${DateTime.now().millisecondsSinceEpoch}',
      });
    } else {
      await _client.from('store_products').update(values).eq('id', id);
    }
  }

  Future<void> setActive(String id, bool active) async {
    await _client
        .from('store_products')
        .update({'is_active': active})
        .eq('id', id);
  }

  Future<void> setClinicPrice({
    required String productId,
    required int clinicId,
    required double? price,
  }) async {
    if (price == null) {
      await _client
          .from('store_product_clinic_prices')
          .delete()
          .eq('product_id', productId)
          .eq('clinic_id', clinicId);
      return;
    }
    await _client.from('store_product_clinic_prices').upsert({
      'product_id': productId,
      'clinic_id': clinicId,
      'price': price,
    }, onConflict: 'product_id,clinic_id');
  }

  static String _formatAmount(double value) {
    final fixed = value.toStringAsFixed(
      value.truncateToDouble() == value ? 0 : 2,
    );
    final parts = fixed.split('.');
    final chars = parts.first.split('').reversed.toList();
    final groups = <String>[];
    for (var i = 0; i < chars.length; i += 3) {
      groups.add(chars.skip(i).take(3).toList().reversed.join());
    }
    final whole = groups.reversed.join('.');
    return parts.length == 1 ? whole : '$whole,${parts[1]}';
  }
}
