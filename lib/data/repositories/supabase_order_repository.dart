import 'package:oy_site/models/order_model.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseOrderRepository {
  SupabaseClient get _client => Supabase.instance.client;

  Future<List<OrderModel>> getOrdersByExpert({
    required int expertUserId,
  }) async {
    final response = await _client
        .from('orders')
        .select()
        .eq('expert_user_id', expertUserId)
        .order('ordered_at', ascending: false);

    return (response as List<dynamic>)
        .map(
          (item) => OrderModel.fromMap(Map<String, dynamic>.from(item as Map)),
        )
        .toList();
  }

  Future<List<OrderModel>> getAllOrders() async {
    final response = await _client
        .from('orders')
        .select()
        .order('ordered_at', ascending: false);

    return (response as List<dynamic>)
        .map(
          (item) => OrderModel.fromMap(Map<String, dynamic>.from(item as Map)),
        )
        .toList();
  }

  Future<List<OrderModel>> getOrdersForCurrentCustomer() async {
    final authUser = _client.auth.currentUser;
    if (authUser == null) {
      throw Exception('No authenticated user was found.');
    }

    final patientResponse = await _client
        .from('patients')
        .select('id')
        .eq('auth_user_id', authUser.id)
        .maybeSingle();

    final patientId = _toInt(patientResponse?['id']);
    if (patientId == null) return [];

    final response = await _client
        .from('orders')
        .select()
        .eq('patient_id', patientId)
        .order('ordered_at', ascending: false);

    return (response as List<dynamic>)
        .map(
          (item) => OrderModel.fromMap(Map<String, dynamic>.from(item as Map)),
        )
        .toList();
  }

  static int? _toInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value.toString());
  }

  Future<OrderModel> createOrder(OrderModel order) async {
    final response = await _client
        .from('orders')
        .insert(order.toInsertMap())
        .select()
        .single();

    return OrderModel.fromMap(Map<String, dynamic>.from(response as Map));
  }

  Future<void> updateOrder(OrderModel order) async {
    if (order.orderId == null) {
      throw Exception('Sipariş ID bulunamadı.');
    }

    await _client
        .from('orders')
        .update(order.toUpdateMap())
        .eq('id', order.orderId!);
  }
}
