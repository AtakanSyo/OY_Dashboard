import 'package:supabase_flutter/supabase_flutter.dart';

class IyzicoCheckoutResult {
  final bool ok;
  final String? paymentPageUrl;
  final String? token;
  final String? conversationId;
  final String? status;
  final String? errorCode;
  final String? errorMessage;

  const IyzicoCheckoutResult({
    required this.ok,
    required this.paymentPageUrl,
    required this.token,
    required this.conversationId,
    required this.status,
    required this.errorCode,
    required this.errorMessage,
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
    );
  }
}

class IyzicoCheckoutService {
  SupabaseClient get _client => Supabase.instance.client;

  Future<IyzicoCheckoutResult> initializeCheckout({
    required String productId,
  }) async {
    final body = <String, dynamic>{
      'productId': productId,
    };

    final returnUrl = _buildReturnUrl();
    if (returnUrl != null) {
      body['returnUrl'] = returnUrl;
    }

    final response = await _client.functions.invoke(
      'swift-task',
      body: body,
    );

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

  String? _buildReturnUrl() {
    final base = Uri.base;
    if (base.scheme == 'http' || base.scheme == 'https') {
      return '${base.origin}/#/payment-result';
    }
    return null;
  }
}
