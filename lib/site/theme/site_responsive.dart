import 'package:flutter/widgets.dart';

import 'site_tokens.dart';

/// Kırılım noktaları — Superspec §14.
class SiteBreakpoints {
  const SiteBreakpoints._();

  /// Bu değerin altı: mobil (4 kolon).
  static const double mobile = 720;

  /// Bu değerin altı: tablet (8 kolon).
  static const double tablet = 1080;

  /// İçerik kabuğunun azami genişliği.
  static const double contentMaxWidth = 1200;

  /// Üst bar, içerikten biraz daha geniş bir kabuk kullanır; böylece yedi
  /// menü öğesi ve iki aksiyon geniş ekranlarda tek satırda kalır.
  static const double headerMaxWidth = 1440;

  /// Dar metin blokları (okunabilirlik için ~65 karakter).
  static const double proseMaxWidth = 680;
}

enum SiteDevice { mobile, tablet, desktop }

extension SiteDeviceX on SiteDevice {
  bool get isMobile => this == SiteDevice.mobile;
  bool get isTablet => this == SiteDevice.tablet;
  bool get isDesktop => this == SiteDevice.desktop;

  /// Mobil + tablet: menü hamburgere düşer.
  bool get isCompact => this != SiteDevice.desktop;

  /// Grid kolon sayısı (§14).
  int get columns {
    switch (this) {
      case SiteDevice.mobile:
        return 4;
      case SiteDevice.tablet:
        return 8;
      case SiteDevice.desktop:
        return 12;
    }
  }

  /// Bölümler arası dikey ritim.
  double get sectionSpacing {
    switch (this) {
      case SiteDevice.mobile:
        return SiteSpacing.x6;
      case SiteDevice.tablet:
        return SiteSpacing.x7;
      case SiteDevice.desktop:
        return SiteSpacing.x8;
    }
  }

  /// İçerik kabuğunun yatay iç boşluğu.
  double get gutter {
    switch (this) {
      case SiteDevice.mobile:
        return SiteSpacing.x2;
      case SiteDevice.tablet:
        return SiteSpacing.x3;
      case SiteDevice.desktop:
        return SiteSpacing.x4;
    }
  }

  /// Kart ızgarasındaki boşluk.
  double get gridGap {
    switch (this) {
      case SiteDevice.mobile:
        return SiteSpacing.lg;
      case SiteDevice.tablet:
        return SiteSpacing.xl;
      case SiteDevice.desktop:
        return SiteSpacing.x2;
    }
  }
}

extension SiteResponsiveContext on BuildContext {
  /// Ekran genişliğinden cihaz sınıfı türetir.
  SiteDevice get device {
    final width = MediaQuery.sizeOf(this).width;
    if (width < SiteBreakpoints.mobile) return SiteDevice.mobile;
    if (width < SiteBreakpoints.tablet) return SiteDevice.tablet;
    return SiteDevice.desktop;
  }

  /// Cihaza göre değer seçer. [tablet] verilmezse [desktop] değerine düşer.
  T responsive<T>({required T mobile, T? tablet, required T desktop}) {
    switch (device) {
      case SiteDevice.mobile:
        return mobile;
      case SiteDevice.tablet:
        return tablet ?? desktop;
      case SiteDevice.desktop:
        return desktop;
    }
  }
}
