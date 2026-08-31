import 'dart:math';

import 'package:supabase_flutter/supabase_flutter.dart';

typedef ScanAppointmentInvoker =
    Future<dynamic> Function(Map<String, dynamic> body);

/// Public "Tarama Yap" formlarını tek bir güvenli backend çağrısıyla iletir.
///
/// Tarayıcı tablolara doğrudan yazmaz. Kayıt oluşturma, hız sınırı, e-posta
/// gönderimi ve gönderim durumunun güncellenmesi Edge Function tarafından
/// gerçekleştirilir. Bu sayede anonim kullanıcıya tablo SELECT/UPDATE yetkisi
/// verilmesi gerekmez.
class ScanAppointmentService {
  ScanAppointmentService({
    SupabaseClient? client,
    ScanAppointmentInvoker? invoker,
  }) : _override = client,
       _invoker = invoker;

  final SupabaseClient? _override;
  final ScanAppointmentInvoker? _invoker;

  SupabaseClient get _client => _override ?? Supabase.instance.client;

  Future<ScanAppointmentSubmissionResult> submitIndividual(
    IndividualScanRequest request,
  ) => _submit(kind: 'individual', payload: request.toJson());

  Future<ScanAppointmentSubmissionResult> submitCorporate(
    CorporateScanRequest request,
  ) => _submit(kind: 'corporate', payload: request.toJson());

  Future<ScanAppointmentSubmissionResult> _submit({
    required String kind,
    required Map<String, dynamic> payload,
  }) async {
    dynamic data;
    try {
      final body = {'kind': kind, 'payload': payload};
      if (_invoker != null) {
        data = await _invoker(body);
      } else {
        final response = await _client.functions.invoke(
          'send-scan-appointment',
          body: body,
        );
        data = response.data;
      }
    } on FunctionException catch (error) {
      final details = error.details;
      final publicMessage = details is Map
          ? details['message']?.toString().trim()
          : null;
      throw ScanAppointmentSubmissionException(
        publicMessage?.isNotEmpty == true
            ? publicMessage!
            : 'Talep servisine şu an ulaşılamıyor.',
      );
    } catch (_) {
      throw const ScanAppointmentSubmissionException(
        'Talep servisine şu an ulaşılamıyor.',
      );
    }

    if (data is! Map || data['success'] != true) {
      final publicMessage = data is Map ? data['message']?.toString() : null;
      throw ScanAppointmentSubmissionException(
        publicMessage?.trim().isNotEmpty == true
            ? publicMessage!
            : 'Talep şu an kaydedilemedi.',
      );
    }

    return ScanAppointmentSubmissionResult(
      requestId: data['request_id']?.toString(),
      emailDispatched: data['email_dispatched'] == true,
      duplicate: data['duplicate'] == true,
    );
  }
}

class ScanAppointmentSubmissionResult {
  const ScanAppointmentSubmissionResult({
    required this.requestId,
    required this.emailDispatched,
    required this.duplicate,
  });

  final String? requestId;
  final bool emailDispatched;
  final bool duplicate;
}

class ScanAppointmentSubmissionException implements Exception {
  const ScanAppointmentSubmissionException(this.message);

  final String message;

  @override
  String toString() => 'ScanAppointmentSubmissionException: $message';
}

enum ScanLocation {
  llt('LLT', 'LiveLifeTaller — Kartal, İstanbul'),
  iztuDml('IZTU_DML', 'İZTÜ DML — Buca, İzmir'),
  optiyou('OPTIYOU', 'Alsancak, İzmir');

  const ScanLocation(this.code, this.label);

  final String code;
  final String label;
}

enum CorporateRequestType {
  scannerPurchase('scanner_purchase', 'Tarayıcı sistem satın alma'),
  b2bService('b2b_service', 'B2B tarama hizmeti');

  const CorporateRequestType(this.code, this.label);

  final String code;
  final String label;
}

class IndividualScanRequest {
  const IndividualScanRequest({
    required this.requestId,
    required this.fullName,
    required this.phone,
    required this.email,
    required this.location,
    required this.date,
    required this.time,
    required this.privacyNoticeAcknowledged,
    this.note,
  });

  final String requestId;
  final String fullName;
  final String phone;
  final String email;
  final ScanLocation location;

  /// ISO tarih (yyyy-MM-dd).
  final String date;

  /// "HH:mm".
  final String time;
  final bool privacyNoticeAcknowledged;
  final String? note;

  Map<String, dynamic> toJson() => {
    'client_request_id': requestId,
    'full_name': fullName.trim(),
    'phone': phone.trim(),
    'email': email.trim().toLowerCase(),
    'location': location.code,
    'appointment_date': date,
    'appointment_time': time,
    'privacy_notice_acknowledged': privacyNoticeAcknowledged,
    if (note != null && note!.trim().isNotEmpty) 'note': note!.trim(),
  };
}

class CorporateScanRequest {
  const CorporateScanRequest({
    required this.requestId,
    required this.companyName,
    required this.contactName,
    required this.email,
    required this.phone,
    required this.personCount,
    required this.requestType,
    required this.privacyNoticeAcknowledged,
    this.note,
  });

  final String requestId;
  final String companyName;
  final String contactName;
  final String email;
  final String phone;
  final int personCount;
  final CorporateRequestType requestType;
  final bool privacyNoticeAcknowledged;
  final String? note;

  Map<String, dynamic> toJson() => {
    'client_request_id': requestId,
    'company_name': companyName.trim(),
    'contact_name': contactName.trim(),
    'email': email.trim().toLowerCase(),
    'phone': phone.trim(),
    'person_count': personCount,
    'request_type': requestType.code,
    'privacy_notice_acknowledged': privacyNoticeAcknowledged,
    if (note != null && note!.trim().isNotEmpty) 'note': note!.trim(),
  };
}

/// Form yeniden gönderildiğinde aynı kimlik korunarak yinelenen kayıt ve
/// e-postaların önüne geçilir.
String buildScanRequestId([Random? random]) {
  final source = random ?? Random.secure();
  final bytes = List<int>.generate(16, (_) => source.nextInt(256));
  bytes[6] = (bytes[6] & 0x0f) | 0x40;
  bytes[8] = (bytes[8] & 0x3f) | 0x80;
  final value = bytes
      .map((item) => item.toRadixString(16).padLeft(2, '0'))
      .join();
  return '${value.substring(0, 8)}-'
      '${value.substring(8, 12)}-'
      '${value.substring(12, 16)}-'
      '${value.substring(16, 20)}-'
      '${value.substring(20)}';
}

/// Günlük 11:00–17:00 arası 15 dakikalık slotlar (son slot 16:45).
List<String> buildDailyScanSlots() {
  final slots = <String>[];
  for (var minutes = 11 * 60; minutes <= 16 * 60 + 45; minutes += 15) {
    final h = (minutes ~/ 60).toString().padLeft(2, '0');
    final m = (minutes % 60).toString().padLeft(2, '0');
    slots.add('$h:$m');
  }
  return slots;
}
