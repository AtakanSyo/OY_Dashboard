import 'package:supabase_flutter/supabase_flutter.dart';

/// "Tarama Yap" akışının backend'i: talep Supabase'e yazılır, ardından
/// `send-scan-appointment` edge function e-postaları gönderir (OPTIYOU gelen
/// kutusu + talep sahibine KVKK aydınlatma özeti).
///
/// Bu servis yalnızca public site formları için kullanılır; kullanıcı /
/// oturum akışlarına dokunmaz.
class ScanAppointmentService {
  ScanAppointmentService({SupabaseClient? client}) : _override = client;

  final SupabaseClient? _override;

  /// Client, ilk gönderim anında çözülür; böylece sayfanın kurulması
  /// Supabase.initialize'a bağlı olmaz (widget testleri).
  SupabaseClient get _client => _override ?? Supabase.instance.client;

  /// Bireysel randevu talebi.
  Future<void> submitIndividual(IndividualScanRequest request) async {
    final payload = request.toJson();

    final inserted = await _client
        .from('scan_appointment_requests')
        .insert(payload)
        .select('id')
        .single();

    await _dispatchEmail(
      kind: 'individual',
      payload: payload,
      requestId: inserted['id'] as String?,
      table: 'scan_appointment_requests',
    );
  }

  /// Kurumsal talep (tarayıcı satın alma / B2B hizmet).
  Future<void> submitCorporate(CorporateScanRequest request) async {
    final payload = request.toJson();

    final inserted = await _client
        .from('corporate_scan_requests')
        .insert(payload)
        .select('id')
        .single();

    await _dispatchEmail(
      kind: 'corporate',
      payload: payload,
      requestId: inserted['id'] as String?,
      table: 'corporate_scan_requests',
    );
  }

  Future<void> _dispatchEmail({
    required String kind,
    required Map<String, dynamic> payload,
    required String? requestId,
    required String table,
  }) async {
    // E-posta gönderimi kaydın kendisinden ayrı tutulur: kayıt başarılıysa
    // form başarılı sayılır, e-posta ayrı denenip işaretlenir. Function henüz
    // deploy edilmemişse ya da Resend hatası olursa yalnızca uyarı gösterilir.
    dynamic data;
    try {
      final response = await _client.functions.invoke(
        'send-scan-appointment',
        body: {'kind': kind, 'payload': payload},
      );
      data = response.data;
    } catch (error) {
      throw ScanAppointmentEmailException(error.toString());
    }

    final ok = data is Map && data['success'] == true;
    if (!ok) {
      throw ScanAppointmentEmailException(
        data is Map ? data['error']?.toString() : 'Bilinmeyen e-posta hatası',
      );
    }

    if (requestId != null) {
      await _client
          .from(table)
          .update({'email_dispatched': true})
          .eq('id', requestId);
    }
  }
}

/// Kayıt açıldı ama bilgilendirme e-postası gönderilemedi. Form yine de
/// başarıyla tamamlanmış sayılır; çağıran taraf yalnızca uyarı gösterir.
class ScanAppointmentEmailException implements Exception {
  ScanAppointmentEmailException(this.message);
  final String? message;

  @override
  String toString() => 'ScanAppointmentEmailException: $message';
}

enum ScanLocation {
  llt('LLT', 'LiveLifeTaller — Kartal, İstanbul'),
  iztuDml('IZTU_DML', 'İZTÜ DML — Buca, İzmir'),
  optiyou('OPTIYOU', 'Alsancak, İzmir');

  const ScanLocation(this.code, this.label);

  /// Veritabanı / edge function değeri.
  final String code;

  /// Kullanıcıya gösterilen etiket.
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
    required this.fullName,
    required this.phone,
    required this.email,
    required this.location,
    required this.date,
    required this.time,
    required this.kvkkConsent,
    this.note,
  });

  final String fullName;
  final String phone;
  final String email;
  final ScanLocation location;

  /// ISO tarih (yyyy-MM-dd).
  final String date;

  /// "HH:mm".
  final String time;
  final bool kvkkConsent;
  final String? note;

  Map<String, dynamic> toJson() => {
    'full_name': fullName.trim(),
    'phone': phone.trim(),
    'email': email.trim(),
    'location': location.code,
    'appointment_date': date,
    'appointment_time': time,
    'kvkk_consent': kvkkConsent,
    if (note != null && note!.trim().isNotEmpty) 'note': note!.trim(),
  };
}

class CorporateScanRequest {
  const CorporateScanRequest({
    required this.companyName,
    required this.contactName,
    required this.email,
    required this.phone,
    required this.personCount,
    required this.requestType,
    required this.kvkkConsent,
    this.note,
  });

  final String companyName;
  final String contactName;
  final String email;
  final String phone;
  final int personCount;
  final CorporateRequestType requestType;
  final bool kvkkConsent;
  final String? note;

  Map<String, dynamic> toJson() => {
    'company_name': companyName.trim(),
    'contact_name': contactName.trim(),
    'email': email.trim(),
    'phone': phone.trim(),
    'person_count': personCount,
    'request_type': requestType.code,
    'kvkk_consent': kvkkConsent,
    if (note != null && note!.trim().isNotEmpty) 'note': note!.trim(),
  };
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
