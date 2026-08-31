import 'package:flutter_test/flutter_test.dart';
import 'package:oy_site/services/payment/iyzico_checkout_service.dart';

void main() {
  group('IyzicoCheckoutResult', () {
    test('maps the server-authoritative checkout response', () {
      final result = IyzicoCheckoutResult.fromMap({
        'ok': true,
        'paymentPageUrl': 'https://sandbox.example/checkout',
        'token': 'token-1',
        'conversationId': 'conversation-1',
        'checkoutId': 'checkout-1',
        'amount': 4000,
        'currency': 'TRY',
        'status': 'initialized',
      });

      expect(result.ok, isTrue);
      expect(result.checkoutId, 'checkout-1');
      expect(result.amount, 4000);
      expect(result.currency, 'TRY');
    });
  });

  group('IyzicoCheckoutStatusResult', () {
    test('maps a verified payment and its created order', () {
      final result = IyzicoCheckoutStatusResult.fromMap({
        'status': 'paid',
        'orderId': 42,
        'orderNo': 'OY-20260816-ABC12345',
        'productName': 'Kişiye Özel İç Taban',
        'amount': '4000.00',
        'currency': 'TRY',
      });

      expect(result.isPaid, isTrue);
      expect(result.isPending, isFalse);
      expect(result.orderId, 42);
      expect(result.orderNo, 'OY-20260816-ABC12345');
      expect(result.amount, 4000);
    });

    test('treats initialized checkout as pending', () {
      final result = IyzicoCheckoutStatusResult.fromMap({
        'status': 'initialized',
      });

      expect(result.isPending, isTrue);
      expect(result.isPaid, isFalse);
      expect(result.isFailed, isFalse);
    });
  });
}
