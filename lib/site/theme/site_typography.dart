import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'site_responsive.dart';
import 'site_tokens.dart';

/// Tipografi ölçeği — Superspec §5.2.
///
/// Başlıklar Montserrat, gövde ve arayüz metni Public Sans.
/// Üçüncü bir "utility" rolü olarak ölçüm etiketleri ([dataLabel]) kullanılır:
/// büyük harf, geniş harf aralığı, küçük punto — kumpas/ölçü çizelgesi dili.
class SiteType {
  const SiteType._();

  // ── Display / başlık (Montserrat) ────────────────────────────────────────

  /// Hero başlığı: desktop 46, tablet 38, mobil 32.
  ///
  /// Spesifikasyondaki 52 px, daha kısa bir hero başlığı içindi. Güncel iki
  /// cümlelik başlıkta 52 px, "Edin." gibi tek kelimelik öksüz satırlar
  /// bırakıyordu; ölçek bir kademe indirilerek cümleler dengeli kırılıyor.
  static TextStyle hero(BuildContext context) {
    final size = context.responsive<double>(
      mobile: 32,
      tablet: 38,
      desktop: 46,
    );
    return GoogleFonts.montserrat(
      fontSize: size,
      height: 1.12,
      fontWeight: FontWeight.w700,
      letterSpacing: -0.8,
      color: SiteColors.textPrimary,
    );
  }

  static TextStyle h1(BuildContext context) {
    final size = context.responsive<double>(
      mobile: 28,
      tablet: 34,
      desktop: 38,
    );
    return GoogleFonts.montserrat(
      fontSize: size,
      height: 1.18,
      fontWeight: FontWeight.w700,
      letterSpacing: -0.5,
      color: SiteColors.textPrimary,
    );
  }

  static TextStyle h2(BuildContext context) {
    final size = context.responsive<double>(
      mobile: 24,
      tablet: 27,
      desktop: 30,
    );
    return GoogleFonts.montserrat(
      fontSize: size,
      height: 1.22,
      fontWeight: FontWeight.w700,
      letterSpacing: -0.4,
      color: SiteColors.textPrimary,
    );
  }

  static TextStyle h3(BuildContext context) {
    return GoogleFonts.montserrat(
      fontSize: 20,
      height: 1.3,
      fontWeight: FontWeight.w600,
      letterSpacing: -0.2,
      color: SiteColors.textPrimary,
    );
  }

  // ── Gövde (Public Sans) ──────────────────────────────────────────────────

  static TextStyle bodyLarge(BuildContext context) {
    final size = context.responsive<double>(
      mobile: 16,
      tablet: 17,
      desktop: 18,
    );
    return GoogleFonts.publicSans(
      fontSize: size,
      height: 1.62,
      fontWeight: FontWeight.w400,
      color: SiteColors.textSecondary,
    );
  }

  static TextStyle body(BuildContext context) {
    return GoogleFonts.publicSans(
      fontSize: 16,
      height: 1.6,
      fontWeight: FontWeight.w400,
      color: SiteColors.textSecondary,
    );
  }

  static TextStyle small(BuildContext context) {
    return GoogleFonts.publicSans(
      fontSize: 14,
      height: 1.5,
      fontWeight: FontWeight.w400,
      color: SiteColors.textSecondary,
    );
  }

  /// Buton ve navigasyon metni: 15 px, 600–700.
  static TextStyle action(BuildContext context, {bool strong = false}) {
    return GoogleFonts.publicSans(
      fontSize: 15,
      height: 1.2,
      fontWeight: strong ? FontWeight.w700 : FontWeight.w600,
      letterSpacing: 0.1,
      color: SiteColors.textPrimary,
    );
  }

  // ── Utility: ölçüm / veri etiketi ────────────────────────────────────────

  /// Bölüm eyebrow'ları, kumpas etiketleri ve veri rozetleri.
  /// Sitenin imza motifi olan "ölçü çizelgesi" dilini taşır.
  static TextStyle dataLabel(
    BuildContext context, {
    Color color = SiteColors.primary,
  }) {
    return GoogleFonts.publicSans(
      fontSize: 12,
      height: 1.2,
      fontWeight: FontWeight.w700,
      letterSpacing: 1.6,
      color: color,
    );
  }

  /// Sayısal vurgular (istatistik şeridi, fiyat).
  static TextStyle numeric(
    BuildContext context, {
    double size = 32,
    Color color = SiteColors.textPrimary,
  }) {
    return GoogleFonts.montserrat(
      fontSize: size,
      height: 1.1,
      fontWeight: FontWeight.w700,
      letterSpacing: -0.6,
      color: color,
      fontFeatures: const [FontFeature.tabularFigures()],
    );
  }
}
