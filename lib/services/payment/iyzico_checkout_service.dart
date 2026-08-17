import 'package:supabase_flutter/supabase_flutter.dart';

class IyzicoCheckoutResult {
  final bool ok;
  final String? paymentPageUrl;
  final String? token;
  final String? conversationId;
  final String? status;
  final String? errorCode;
  final String? errorMessage;
  final String? checkoutId;
  final double? amount;
  final String? currency;

  const IyzicoCheckoutResult({
    required this.ok,
    required this.paymentPageUrl,
    required this.token,
    required this.conversationId,
    required this.status,
    required this.errorCode,
    required this.errorMessage,
    this.checkoutId,
    this.amount,
    this.currency,
  });

  factory IyzicoCheckoutResult.fromMap(Map<String, dynamic> map) {
    String? asString(dynamic value) => value is String ? value : null;

    return IyzicoCheckoutResult(
      ok: map['ok'] == true,
      paymentPageUrl: asString(map['paymentPageUrl']),
      token: asString(map['token']),
      conversationId: asString(map['conversationId']),
      status: asString(map['status']),
      errorCode: asString(map['errorCode']),
      errorMessage: asString(map['errorMessage']),
      checkoutId: asString(map['checkoutId']),
      amount: _asDouble(map['amount']),
      currency: asString(map['currency']),
    );
  }

  static double? _asDouble(dynamic value) {
    if (value is num) return value.toDouble();
    return double.tryParse(value?.toString() ?? '');
  }
}

class IyzicoCheckoutStatusResult {
  const IyzicoCheckoutStatusResult({
    required this.status,
    this.orderId,
    this.orderNo,
    this.productName,
    this.amount,
    this.currency,
    this.errorMessage,
  });

  final String status;
  final int? orderId;
  final String? orderNo;
  final String? productName;
  final double? amount;
  final String? currency;
  final String? errorMessage;

  bool get isPaid => status == 'paid';
  bool get isFailed => status == 'failed' || status == 'cancelled';
  bool get isPending => !isPaid && !isFailed;

  factory IyzicoCheckoutStatusResult.fromMap(Map<String, dynamic> map) {
    return IyzicoCheckoutStatusResult(
      status: map['status']?.toString() ?? 'pending',
      orderId: _asInt(map['orderId']),
      orderNo: map['orderNo']?.toString(),
      productName: map['productName']?.toString(),
      amount: _asDouble(map['amount']),
      currency: map['currency']?.toString(),
      errorMessage: map['errorMessage']?.toString(),
    );
  }

  static int? _asInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '');
  }

  static double? _asDouble(dynamic value) {
    if (value is num) return value.toDouble();
    return double.tryParse(value?.toString() ?? '');
  }
}

class IyzicoCheckoutService {
  SupabaseClient get _client => Supabase.instance.client;

  Future<IyzicoCheckoutResult> initializeCheckout({
    required String productId,
    required int addressId,
    int? sessionId,
    String locale = 'tr',
  }) async {
    final body = <String, dynamic>{
      'action': 'initialize',
      'productId': productId,
      'addressId': addressId,
      'sessionId': ?sessionId,
      'locale': locale == 'en' ? 'en' : 'tr',
    };

    final returnUrl = _buildReturnUrl();
    if (returnUrl != null) {
      body['returnUrl'] = returnUrl;
    }

    final response = await _client.functions.invoke('swift-task', body: body);

    final rawData = response.data;
    if (rawData is! Map) {
      throw Exception('Beklenmeyen ödeme yanıtı.');
    }

    final result = IyzicoCheckoutResult.fromMap(
      Map<String, dynamic>.from(rawData),
    );

    if (!result.ok) {
      throw Exception(result.errorMessage ?? 'Ödeme başlatılamadı.');
    }

    if (result.paymentPageUrl == null || result.paymentPageUrl!.isEmpty) {
      throw Exception('Ödeme sayfası URL bilgisi alınamadı.');
    }

    return result;
  }

  Future<IyzicoCheckoutStatusResult> getCheckoutStatus({
    required String token,
  }) async {
    final response = await _client.functions.invoke(
      'swift-task',
      body: {'action': 'status', 'token': token},
    );

    final rawData = response.data;
    if (rawData is! Map) {
      throw Exception('Beklenmeyen ödeme durumu yanıtı.');
    }

    final data = Map<String, dynamic>.from(rawData);
    if (data['ok'] != true) {
      throw Exception(data['errorMessage'] ?? 'Ödeme durumu alınamadı.');
    }
    return IyzicoCheckoutStatusResult.fromMap(data);
  }

  String? _buildReturnUrl() {
    final base = Uri.base;
    if (base.scheme == 'http' || base.scheme == 'https') {
      return '${base.origin}/#/payment-result';
    }
    return null;
  }
}
