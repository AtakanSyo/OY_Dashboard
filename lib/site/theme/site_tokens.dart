import 'package:flutter/material.dart';

/// OPTIYOU tasarım sistemi — 1. katman: primitive token'lar.
///
/// Ham marka değerleri. Bu sınıf doğrudan widget'larda kullanılmaz;
/// yalnızca [SiteColors] semantik katmanı tarafından referans alınır.
/// Kaynak: OPTIYOU Master Superspec §5.1.
class SitePrimitives {
  const SitePrimitives._();

  static const Color deepTeal = Color(0xFF0E1F22);
  static const Color pineGreen = Color(0xFF2E8C7A);
  static const Color deepPine = Color(0xFF1F3F3D);
  static const Color iceWhite = Color(0xFFF5FBFD);
  static const Color pureWhite = Color(0xFFFFFFFF);
  static const Color charcoal = Color(0xFF38474B);
  static const Color softBorder = Color(0xFFDCE6EA);
}

/// 2. katman: semantik renkler. Widget'lar yalnızca bu katmanı kullanır.
class SiteColors {
  const SiteColors._();

  /// Sayfa zemini — açık bölümler.
  static const Color surface = SitePrimitives.iceWhite;

  /// Kart, navbar, form yüzeyi.
  static const Color surfaceRaised = SitePrimitives.pureWhite;

  /// Koyu bant ve footer yüzeyi.
  static const Color surfaceInverse = SitePrimitives.deepTeal;

  /// Koyu bant içindeki ikincil yüzey.
  static const Color surfaceInverseRaised = SitePrimitives.deepPine;

  /// Birincil eylem rengi (CTA, aktif durum, ikon).
  static const Color primary = SitePrimitives.pineGreen;

  /// Birincil eylemin hover / basılı durumu.
  static const Color primaryHover = SitePrimitives.deepPine;

  /// Ana metin.
  static const Color textPrimary = SitePrimitives.deepTeal;

  /// İkincil metin, açıklama.
  static const Color textSecondary = SitePrimitives.charcoal;

  /// Koyu yüzey üzerindeki ana metin.
  static const Color textInverse = SitePrimitives.pureWhite;

  /// Koyu yüzey üzerindeki ikincil metin.
  static const Color textInverseSecondary = Color(0xFFA8C0BE);

  /// Görsel/video üzerindeki ikincil metin — scrim üstünde okunabilirlik için
  /// [textInverseSecondary]'den daha açık.
  static const Color textOnMedia = Color(0xFFDCE7E5);

  /// Koyu yüzeyde vurgu rengi. Pine Green koyu zeminde yeterli kontrast
  /// vermediği için açıklaştırılmış varyantı kullanılır.
  static const Color primaryOnDark = Color(0xFF6FD3BC);

  /// Border, divider, hairline.
  static const Color border = SitePrimitives.softBorder;

  /// Koyu yüzeydeki border.
  static const Color borderInverse = Color(0xFF2A4245);

  /// Odak halkası (erişilebilirlik).
  static const Color focus = SitePrimitives.pineGreen;

  /// Primary rengin düşük yoğunluklu zemin varyantı (chip, ikon kutusu).
  static Color get primarySoft =>
      SitePrimitives.pineGreen.withValues(alpha: 0.10);

  /// Primary rengin border varyantı.
  static Color get primarySoftBorder =>
      SitePrimitives.pineGreen.withValues(alpha: 0.24);
}

/// Boşluk skalası — 4 px tabanlı.
class SiteSpacing {
  const SiteSpacing._();

  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 20;
  static const double x2 = 24;
  static const double x3 = 32;
  static const double x4 = 40;
  static const double x5 = 48;
  static const double x6 = 64;
  static const double x7 = 80;
  static const double x8 = 96;
  static const double x9 = 120;
}

/// Köşe yarıçapları.
class SiteRadius {
  const SiteRadius._();

  static const double sm = 8;
  static const double md = 12;
  static const double lg = 18;
  static const double xl = 24;
  static const double pill = 999;

  static const BorderRadius cardRadius = BorderRadius.all(Radius.circular(lg));
  static const BorderRadius buttonRadius = BorderRadius.all(
    Radius.circular(md),
  );
  static const BorderRadius chipRadius = BorderRadius.all(
    Radius.circular(pill),
  );
}

/// Gölge tanımları. Marka dili "temiz + mühendislik hassasiyeti" olduğu için
/// gölgeler düşük yoğunluklu ve geniş yayılımlıdır.
class SiteShadows {
  const SiteShadows._();

  static List<BoxShadow> get card => [
    BoxShadow(
      color: SitePrimitives.deepTeal.withValues(alpha: 0.06),
      blurRadius: 24,
      offset: const Offset(0, 8),
    ),
  ];

  static List<BoxShadow> get cardHover => [
    BoxShadow(
      color: SitePrimitives.deepTeal.withValues(alpha: 0.12),
      blurRadius: 32,
      offset: const Offset(0, 14),
    ),
  ];

  static List<BoxShadow> get header => [
    BoxShadow(
      color: SitePrimitives.deepTeal.withValues(alpha: 0.08),
      blurRadius: 20,
      offset: const Offset(0, 4),
    ),
  ];

  static List<BoxShadow> get floating => [
    BoxShadow(
      color: SitePrimitives.deepTeal.withValues(alpha: 0.14),
      blurRadius: 40,
      offset: const Offset(0, 18),
    ),
  ];
}

/// Hareket token'ları. Kullanıcı "azaltılmış hareket" tercih ediyorsa
/// süreler [SiteMotion.duration] üzerinden sıfırlanır.
class SiteMotion {
  const SiteMotion._();

  static const Duration fast = Duration(milliseconds: 140);
  static const Duration base = Duration(milliseconds: 240);
  static const Duration slow = Duration(milliseconds: 600);
  static const Duration reveal = Duration(milliseconds: 900);

  static const Curve curve = Curves.easeOutCubic;

  /// Erişilebilirlik: `MediaQuery.disableAnimations` açıksa hareketi kapatır.
  static Duration duration(BuildContext context, Duration value) {
    return MediaQuery.maybeOf(context)?.disableAnimations ?? false
        ? Duration.zero
        : value;
  }
}
