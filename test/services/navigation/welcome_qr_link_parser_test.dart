import 'package:flutter_test/flutter_test.dart';
import 'package:oy_site/services/navigation/welcome_qr_link_parser.dart';

void main() {
  group('WelcomeQrLinkParser', () {
    test('hash tabanlı welcome bağlantısını ayrıştırır', () {
      final result = WelcomeQrLinkParser.parse(
        'https://www.optiyou.fit/#/welcome?invite=inv_testToken123&source=package',
      );

      expect(result?.inviteToken, 'inv_testToken123');
      expect(result?.source, 'package');
    });

    test('path tabanlı welcome bağlantısını ayrıştırır', () {
      final result = WelcomeQrLinkParser.parse(
        'https://www.optiyou.fit/welcome?invite=inv_pathToken123&source=session',
      );

      expect(result?.inviteToken, 'inv_pathToken123');
      expect(result?.source, 'session');
    });

    test('ham davet tokenını kabul eder', () {
      final result = WelcomeQrLinkParser.parse('inv_rawToken123');

      expect(result?.inviteToken, 'inv_rawToken123');
      expect(result?.source, 'in_app');
    });

    test('davet içermeyen bağlantıyı reddeder', () {
      final result = WelcomeQrLinkParser.parse(
        'https://www.optiyou.fit/#/welcome?source=package',
      );

      expect(result, isNull);
    });
  });
}
