/// OPTIYOU kurumsal iletişim bilgileri — tek kaynak.
///
/// İletişim sayfası, footer ve ölçüm merkezleri listesi buradan beslenir.
class SiteContact {
  const SiteContact._();

  static const String email = 'info@optiyou.com.tr';

  /// Ekranda gösterilen telefon biçimleri (şehre göre).
  static const String phoneIstanbul = '0534 884 23 19';
  static const String phoneIzmir = '+90 507 290 37 13';

  /// `tel:` bağlantısı için sadeleştirilmiş biçimler.
  static const String phoneIstanbulDial = '+905348842319';
  static const String phoneIzmirDial = '+905072903713';

  /// Kurumsal merkez.
  static const String addressShort = 'Alsancak, Konak / İzmir';
  static const String addressLong = 'OPTIYOU — Alsancak, Konak / İzmir';
}

/// Tarama noktası. `code` alanı Supabase `location` kısıtıyla (LLT / OPTIYOU /
/// IZTU_DML) uyumludur; yalnızca ekranda gösterilen ad ve konum güncellenir.
class ScanPoint {
  const ScanPoint({
    required this.code,
    required this.name,
    required this.city,
    required this.area,
    required this.phone,
  });

  final String code;
  final String name;
  final String city;

  /// İlçe / yerleşke düzeyinde konum. Tam adres ve yol tarifi randevu
  /// onayında paylaşılır.
  final String area;
  final String phone;
}

const List<ScanPoint> siteScanPoints = [
  ScanPoint(
    code: 'LLT',
    name: 'LiveLifeTaller — Kartal',
    city: 'İstanbul',
    area: 'LiveLifeTaller Kliniği · Kartal / İstanbul',
    phone: SiteContact.phoneIstanbul,
  ),
  ScanPoint(
    code: 'IZTU_DML',
    name: 'İZTÜ DML — Buca İzmir',
    city: 'İzmir',
    area: 'İzmir Tınaztepe Üniversitesi, Tınaztepe Yerleşkesi · Buca / İzmir',
    phone: SiteContact.phoneIzmir,
  ),
  ScanPoint(
    code: 'OPTIYOU',
    name: 'Alsancak İzmir',
    city: 'İzmir',
    area: 'Alsancak, Konak / İzmir',
    phone: SiteContact.phoneIzmir,
  ),
];

/// Randevu formu / e-posta için `code` → gösterilecek ad.
const Map<String, String> scanPointLabels = {
  'LLT': 'LiveLifeTaller — Kartal, İstanbul',
  'IZTU_DML': 'İZTÜ DML — Buca, İzmir',
  'OPTIYOU': 'Alsancak, İzmir',
};
