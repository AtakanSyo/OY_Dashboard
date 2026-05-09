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
        .map((item) => OrderModel.fromMap(
              Map<String, dynamic>.from(item as Map),
            ))
        .toList();
  }

  Future<List<OrderModel>> getAllOrders() async {
    final response = await _client
        .from('orders')
        .select()
        .order('ordered_at', ascending: false);

    return (response as List<dynamic>)
        .map(
          (item) => OrderModel.fromMap(
            Map<String, dynamic>.from(item as Map),
          ),
        )
        .toList();
  }

  Future<List<OrderModel>> getOrdersByUser({
    required int userId,
  }) async {
    final response = await _client
        .from('orders')
        .select()
        .eq('expert_user_id', userId)
        .order('ordered_at', ascending: false);

    return (response as List<dynamic>)
        .map((item) => OrderModel.fromMap(
              Map<String, dynamic>.from(item as Map),
            ))
        .toList();
  }

  Future<OrderModel> createOrder(OrderModel order) async {
    final response = await _client
        .from('orders')
        .insert(order.toInsertMap())
        .select()
        .single();

    return OrderModel.fromMap(
      Map<String, dynamic>.from(response as Map),
    );
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