import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:oy_site/site/data/scan_appointment_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() {
  group('ScanAppointmentService', () {
    test(
      'bireysel talebi yalnızca edge function gövdesiyle gönderir',
      () async {
        Map<String, dynamic>? captured;
        final service = ScanAppointmentService(
          invoker: (body) async {
            captured = body;
            return {
              'success': true,
              'request_id': 'server-id',
              'email_dispatched': true,
              'duplicate': false,
            };
          },
        );

        final result = await service.submitIndividual(
          const IndividualScanRequest(
            requestId: '79f6f92d-b0ca-4ad7-a92c-fb0dcd542d69',
            fullName: '  Ayşe Yılmaz  ',
            phone: ' 0555 111 22 33 ',
            email: ' AYSE@EXAMPLE.COM ',
            location: ScanLocation.optiyou,
            date: '2026-09-10',
            time: '13:15',
            privacyNoticeAcknowledged: true,
          ),
        );

        expect(captured?['kind'], 'individual');
        final payload = captured?['payload'] as Map<String, dynamic>;
        expect(payload['full_name'], 'Ayşe Yılmaz');
        expect(payload['email'], 'ayse@example.com');
        expect(payload['privacy_notice_acknowledged'], isTrue);
        expect(payload, isNot(contains('kvkk_consent')));
        expect(result.requestId, 'server-id');
        expect(result.emailDispatched, isTrue);
        expect(result.duplicate, isFalse);
      },
    );

    test('kayıt başarılı e-posta başarısız sonucunu korur', () async {
      final service = ScanAppointmentService(
        invoker: (_) async => {
          'success': true,
          'request_id': 'server-id',
          'email_dispatched': false,
          'duplicate': false,
        },
      );

      final result = await service.submitCorporate(
        const CorporateScanRequest(
          requestId: '79f6f92d-b0ca-4ad7-a92c-fb0dcd542d69',
          companyName: 'Örnek AŞ',
          contactName: 'Ali Veli',
          email: 'ali@example.com',
          phone: '05551112233',
          personCount: 40,
          requestType: CorporateRequestType.b2bService,
          privacyNoticeAcknowledged: true,
        ),
      );

      expect(result.emailDispatched, isFalse);
    });

    test('kamuya açık hata mesajını exception olarak döndürür', () async {
      final service = ScanAppointmentService(
        invoker: (_) async => {
          'success': false,
          'message': 'Lütfen 15 dakika sonra tekrar deneyin.',
        },
      );

      await expectLater(
        service.submitIndividual(
          const IndividualScanRequest(
            requestId: '79f6f92d-b0ca-4ad7-a92c-fb0dcd542d69',
            fullName: 'Ayşe Yılmaz',
            phone: '05551112233',
            email: 'ayse@example.com',
            location: ScanLocation.llt,
            date: '2026-09-10',
            time: '13:15',
            privacyNoticeAcknowledged: true,
          ),
        ),
        throwsA(
          isA<ScanAppointmentSubmissionException>().having(
            (error) => error.message,
            'message',
            'Lütfen 15 dakika sonra tekrar deneyin.',
          ),
        ),
      );
    });

    test('HTTP hata gövdesindeki güvenli mesajı korur', () async {
      final service = ScanAppointmentService(
        invoker: (_) async => throw const FunctionException(
          status: 429,
          details: {
            'success': false,
            'message': 'Çok kısa sürede çok sayıda talep gönderildi.',
          },
        ),
      );

      await expectLater(
        service.submitCorporate(
          const CorporateScanRequest(
            requestId: '79f6f92d-b0ca-4ad7-a92c-fb0dcd542d69',
            companyName: 'Örnek AŞ',
            contactName: 'Ali Veli',
            email: 'ali@example.com',
            phone: '05551112233',
            personCount: 40,
            requestType: CorporateRequestType.b2bService,
            privacyNoticeAcknowledged: true,
          ),
        ),
        throwsA(
          isA<ScanAppointmentSubmissionException>().having(
            (error) => error.message,
            'message',
            'Çok kısa sürede çok sayıda talep gönderildi.',
          ),
        ),
      );
    });
  });

  test('istek kimliği UUID v4 biçiminde üretilir', () {
    final value = buildScanRequestId(Random(7));
    expect(
      value,
      matches(
        RegExp(
          r'^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$',
        ),
      ),
    );
  });
}
