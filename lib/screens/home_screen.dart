import 'package:flutter/material.dart';

import '../site/pages/site_home_page.dart';

/// Uygulamanın public giriş sayfası.
///
/// Gerçek içerik OPTIYOU Superspec §7'ye göre [SiteHomePage] içinde kurulur.
/// Bu sınıf, mevcut çağrı noktalarının (main.dart, giriş ekranındaki
/// "Ana Sayfa" butonu, ödeme sonucu ekranı) imzasını bozmadan yeni siteye
/// bağlanması için ince bir sarmalayıcıdır.
///
/// Önceki tek sayfalık landing içeriği referans olarak
/// `home_screen_legacy.dart` dosyasında korunmaktadır; uygulamada
/// kullanılmaz.
class HomeScreen extends StatelessWidget {
  /// Dashboard tarafına taşınan bağımlılık. Public sayfalar kullanmaz;
  /// yalnızca mevcut çağrı imzası korunsun diye tutulur.
  final dynamic pressureRepository;

  const HomeScreen({
    super.key,
    required this.pressureRepository,
  });

  @override
  Widget build(BuildContext context) {
    return const SiteHomePage();
  }
}
