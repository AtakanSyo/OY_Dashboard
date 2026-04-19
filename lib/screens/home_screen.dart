import 'package:flutter/material.dart';
import 'package:oy_site/screens/auth/login_screen.dart';
import 'package:oy_site/screens/auth/register_screen.dart';

class HomeScreen extends StatefulWidget {
  final dynamic pressureRepository;

  const HomeScreen({
    super.key,
    required this.pressureRepository,
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final ScrollController _scrollController = ScrollController();
  final GlobalKey _featuresKey = GlobalKey();
  final GlobalKey _aboutKey = GlobalKey();
  final GlobalKey _servicesKey = GlobalKey();
  final GlobalKey _productsKey = GlobalKey();
  final GlobalKey _centersKey = GlobalKey();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _goToLogin() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => LoginScreen(
          pressureRepository: widget.pressureRepository,
        ),
      ),
    );
  }

  void _goToRegister() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const RegisterScreen()),
    );
  }

  void _scrollTo(GlobalKey key) {
    final ctx = key.currentContext;
    if (ctx != null) {
      Scrollable.ensureVisible(
        ctx,
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.of(context).size.width;
    final isNarrow = w < 800;

    return Scaffold(
      backgroundColor: const Color(0xFFF7F9FB),
      body: Column(
        children: [
          _Navbar(
            onLogin: _goToLogin,
            onRegister: _goToRegister,
            onScrollToServices: () => _scrollTo(_servicesKey),
            onScrollToProducts: () => _scrollTo(_productsKey),
            onScrollToCenters: () => _scrollTo(_centersKey),
            onScrollToAbout: () => _scrollTo(_aboutKey),
            isNarrow: isNarrow,
          ),
          Expanded(
            child: SingleChildScrollView(
              controller: _scrollController,
              child: Column(
                children: [
                  _HeroSection(
                    isNarrow: isNarrow,
                    onGetStarted: _goToRegister,
                  ),
                  _ImpactStatsSection(isNarrow: isNarrow),
                  _KimIcinSection(isNarrow: isNarrow),
                  Container(
                    key: _featuresKey,
                    child: _FeaturesSection(isNarrow: isNarrow),
                  ),
                  _AnalysisSystemsSection(isNarrow: isNarrow),
                  Container(
                    key: _servicesKey,
                    child: _ServicesSection(isNarrow: isNarrow),
                  ),
                  Container(
                    key: _productsKey,
                    child: _ProductsSection(
                      isNarrow: isNarrow,
                      onOpenStore: _goToRegister,
                    ),
                  ),
                  Container(
                    key: _centersKey,
                    child: _MeasurementCentersSection(isNarrow: isNarrow),
                  ),
                  Container(
                    key: _aboutKey,
                    child: _AboutSection(isNarrow: isNarrow),
                  ),
                  _CtaSection(onGetStarted: _goToRegister, onLogin: _goToLogin),
                  const _Footer(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Navbar ──────────────────────────────────────────────────────────────────

class _Navbar extends StatelessWidget {
  final VoidCallback onLogin;
  final VoidCallback onRegister;
  final VoidCallback onScrollToServices;
  final VoidCallback onScrollToProducts;
  final VoidCallback onScrollToCenters;
  final VoidCallback onScrollToAbout;
  final bool isNarrow;

  const _Navbar({
    required this.onLogin,
    required this.onRegister,
    required this.onScrollToServices,
    required this.onScrollToProducts,
    required this.onScrollToCenters,
    required this.onScrollToAbout,
    required this.isNarrow,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 66,
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Row(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Colors.teal.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Image.asset(
                  'assets/images/branding/favicon.png',
                  height: 20,
                ),
              ),
              const SizedBox(width: 20),
              Image.asset(
                'assets/images/branding/logo.png',
                height: 50,
              ),
            ],
          ),
          const Spacer(),
          if (!isNarrow) ...[
            _NavLink(label: 'Hizmetler', onTap: onScrollToServices),
            _NavLink(label: 'Ürünler', onTap: onScrollToProducts),
            _NavLink(label: 'Merkezler', onTap: onScrollToCenters),
            _NavLink(label: 'Hakkımızda', onTap: onScrollToAbout),
            const SizedBox(width: 16),
            OutlinedButton(
              onPressed: onLogin,
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.teal,
                side: const BorderSide(color: Colors.teal),
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text(
                'Giriş Yap',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
            const SizedBox(width: 10),
            ElevatedButton(
              onPressed: onRegister,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.teal,
                foregroundColor: Colors.white,
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text(
                'Kayıt Ol',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
          ] else
            PopupMenuButton<String>(
              icon: const Icon(
                Icons.menu,
                color: Color(0xFF1A2340),
                size: 26,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              offset: const Offset(0, 52),
              onSelected: (value) {
                switch (value) {
                  case 'services':
                    onScrollToServices();
                    break;
                  case 'products':
                    onScrollToProducts();
                    break;
                  case 'centers':
                    onScrollToCenters();
                    break;
                  case 'about':
                    onScrollToAbout();
                    break;
                  case 'login':
                    onLogin();
                    break;
                  case 'register':
                    onRegister();
                    break;
                }
              },
              itemBuilder: (_) => const [
                PopupMenuItem(
                  value: 'services',
                  child: Row(
                    children: [
                      Icon(
                        Icons.design_services_outlined,
                        size: 18,
                        color: Colors.teal,
                      ),
                      SizedBox(width: 10),
                      Text('Hizmetler'),
                    ],
                  ),
                ),
                PopupMenuItem(
                  value: 'products',
                  child: Row(
                    children: [
                      Icon(
                        Icons.inventory_2_outlined,
                        size: 18,
                        color: Colors.teal,
                      ),
                      SizedBox(width: 10),
                      Text('Ürünler'),
                    ],
                  ),
                ),
                PopupMenuItem(
                  value: 'centers',
                  child: Row(
                    children: [
                      Icon(
                        Icons.location_on_outlined,
                        size: 18,
                        color: Colors.teal,
                      ),
                      SizedBox(width: 10),
                      Text('Merkezler'),
                    ],
                  ),
                ),
                PopupMenuItem(
                  value: 'about',
                  child: Row(
                    children: [
                      Icon(
                        Icons.info_outline,
                        size: 18,
                        color: Colors.teal,
                      ),
                      SizedBox(width: 10),
                      Text('Hakkımızda'),
                    ],
                  ),
                ),
                PopupMenuDivider(),
                PopupMenuItem(
                  value: 'login',
                  child: Row(
                    children: [
                      Icon(Icons.login, size: 18, color: Colors.teal),
                      SizedBox(width: 10),
                      Text('Giriş Yap'),
                    ],
                  ),
                ),
                PopupMenuItem(
                  value: 'register',
                  child: Row(
                    children: [
                      Icon(
                        Icons.person_add_outlined,
                        size: 18,
                        color: Colors.teal,
                      ),
                      SizedBox(width: 10),
                      Text('Kayıt Ol'),
                    ],
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }
}

class _NavLink extends StatefulWidget {
  final String label;
  final VoidCallback onTap;

  const _NavLink({
    required this.label,
    required this.onTap,
  });

  @override
  State<_NavLink> createState() => _NavLinkState();
}

class _NavLinkState extends State<_NavLink> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                widget.label,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                  color: _hovered ? Colors.teal : const Color(0xFF3D4E6B),
                ),
              ),
              const SizedBox(height: 3),
              AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                height: 2,
                width: _hovered ? 32.0 : 0.0,
                decoration: BoxDecoration(
                  color: Colors.teal,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Hero ────────────────────────────────────────────────────────────────────

class _HeroSection extends StatelessWidget {
  final bool isNarrow;
  final VoidCallback onGetStarted;

  const _HeroSection({
    required this.isNarrow,
    required this.onGetStarted,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF004D40), Color(0xFF00897B), Color(0xFF26C6DA)],
        ),
      ),
      padding: EdgeInsets.symmetric(
        horizontal: isNarrow ? 24 : 80,
        vertical: 80,
      ),
      child: isNarrow
          ? _heroContent(context, isNarrow)
          : Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(flex: 5, child: _heroContent(context, isNarrow)),
                Expanded(flex: 4, child: _heroIllustration()),
              ],
            ),
    );
  }

  Widget _heroContent(BuildContext context, bool isNarrow) {
    return Column(
      crossAxisAlignment:
          isNarrow ? CrossAxisAlignment.center : CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.15),
            borderRadius: BorderRadius.circular(20),
          ),
          child: const Text(
            'Ayak Sağlığında Dijital Çözüm Ekosistemi',
            style: TextStyle(
              color: Colors.white,
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        const SizedBox(height: 20),
        Text(
          'Ayak Sağlığında\nYeni Nesil\nTakip ve Analiz',
          textAlign: isNarrow ? TextAlign.center : TextAlign.left,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 46,
            fontWeight: FontWeight.bold,
            height: 1.15,
            letterSpacing: -1,
          ),
        ),
        const SizedBox(height: 20),
        Text(
          'Optiyou; bireysel kullanıcılar, uzmanlar ve kurumsal firmalar için ayak sağlığı analizi, basınç değerlendirmesi, kişisel ortopedik ürün tasarımı ve periyodik takip altyapısı sunar.',
          textAlign: isNarrow ? TextAlign.center : TextAlign.left,
          style: TextStyle(
            color: Colors.white.withOpacity(0.88),
            fontSize: 16,
            height: 1.6,
          ),
        ),
        const SizedBox(height: 36),
        Row(
          mainAxisAlignment:
              isNarrow ? MainAxisAlignment.center : MainAxisAlignment.start,
          children: [
            ElevatedButton(
              onPressed: onGetStarted,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: Colors.teal.shade800,
                padding:
                    const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: const Text(
                'Analiz Randevusu Alın',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        const SizedBox(height: 48),
        if (!isNarrow)
          Row(
            children: [
              _statBadge('2,500+', 'Analiz Edilmiş Ayak'),
              const SizedBox(width: 32),
              _statBadge('150+', 'Aktif Uzman'),
              const SizedBox(width: 32),
              _statBadge('98%', 'Memnuniyet'),
            ],
          ),
      ],
    );
  }

  Widget _statBadge(String value, String label) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 28,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withOpacity(0.75),
            fontSize: 13,
          ),
        ),
      ],
    );
  }

  Widget _heroIllustration() {
    return Center(
      child: Container(
        width: 320,
        height: 320,
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.10),
          borderRadius: BorderRadius.circular(24),
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            Positioned(
              top: 26,
              left: 26,
              child: _floatingCard(
                icon: Icons.show_chart,
                label: 'Basınç Analizi',
                color: Colors.orange,
              ),
            ),
            Positioned(
              top: 90,
              right: 18,
              child: _floatingCard(
                icon: Icons.rotate_90_degrees_ccw,
                label: '3D Ayak Tarama',
                color: Colors.purple,
              ),
            ),
            Positioned(
              bottom: 108,
              left: 10,
              child: _floatingCard(
                icon: Icons.sports_soccer,
                label: 'Sporcu Takibi',
                color: Colors.blue,
              ),
            ),
            Positioned(
              bottom: 60,
              right: 16,
              child: _floatingCard(
                icon: Icons.apartment_outlined,
                label: 'Kurumsal Analiz',
                color: Colors.teal,
              ),
            ),
            Positioned(
              bottom: 18,
              left: 30,
              child: _floatingCard(
                icon: Icons.design_services,
                label: 'Kişisel İç Taban',
                color: Colors.green,
              ),
            ),
            const Icon(
              Icons.accessibility_new,
              size: 96,
              color: Colors.white54,
            ),
          ],
        ),
      ),
    );
  }

  Widget _floatingCard({
    required IconData icon,
    required String label,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.20),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 15),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade800,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Platforma Genel Bakış ───────────────────────────────────────────────────

class _FeaturesSection extends StatelessWidget {
  final bool isNarrow;

  const _FeaturesSection({required this.isNarrow});

  static const List<Map<String, dynamic>> _groups = [
    {
      'title': 'Uzmanlar',
      'icon': Icons.medical_services_outlined,
      'items': [
        '3D ayak tarama ve analiz yönetimi',
        'Basınç verisi takibi',
        'Kişisel tabanlık tasarım süreci',
        'Hasta ve sipariş operasyonları',
      ],
    },
    {
      'title': 'Kullanıcılar',
      'icon': Icons.accessibility_new,
      'items': [
        'Analiz sonuçlarını inceleme',
        'Ölçüm geçmişini takip etme',
        'Kişisel ürünlere erişim',
        'Zamana göre gelişim grafikleri',
      ],
    },
    {
      'title': 'Kurumsal',
      'icon': Icons.apartment_outlined,
      'items': [
        'Departman bazlı ayak sağlığı analizi',
        'Çalışan grubu risk takibi',
        'Periyodik gelişim raporları',
        'Operasyonel içgörü ve öneriler',
      ],
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      color: const Color(0xFFF7F9FB),
      padding: EdgeInsets.symmetric(
        horizontal: isNarrow ? 24 : 80,
        vertical: 72,
      ),
      child: Column(
        children: [
          const Text(
            'Platforma Genel Bakış',
            style: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1A2340),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'Optiyou farklı kullanıcı grupları için özelleştirilmiş takip ve analiz deneyimi sunar.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey.shade600, fontSize: 16),
          ),
          const SizedBox(height: 42),
          Wrap(
            spacing: 22,
            runSpacing: 22,
            alignment: WrapAlignment.center,
            children: _groups.map((group) {
              return _FeatureGroupCard(
                title: group['title'] as String,
                icon: group['icon'] as IconData,
                items: group['items'] as List<String>,
                isNarrow: isNarrow,
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}

class _FeatureGroupCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final List<String> items;
  final bool isNarrow;

  const _FeatureGroupCard({
    required this.title,
    required this.icon,
    required this.items,
    required this.isNarrow,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: isNarrow ? double.infinity : 340,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: Colors.teal.withOpacity(0.10),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: Colors.teal, size: 26),
          ),
          const SizedBox(height: 16),
          Text(
            title,
            style: const TextStyle(
              fontSize: 19,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1A2340),
            ),
          ),
          const SizedBox(height: 14),
          ...items.map(
            (item) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Padding(
                    padding: EdgeInsets.only(top: 3),
                    child: Icon(
                      Icons.check_circle_outline,
                      size: 17,
                      color: Colors.teal,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      item,
                      style: TextStyle(
                        color: Colors.grey.shade700,
                        height: 1.45,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Analiz Sistemleri ────────────────────────────────────────────────────────────────
class _AnalysisSystemsSection extends StatelessWidget {
  final bool isNarrow;

  const _AnalysisSystemsSection({required this.isNarrow});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      color: Colors.white,
      padding: EdgeInsets.symmetric(
        horizontal: isNarrow ? 24 : 80,
        vertical: 72,
      ),
      child: Column(
        children: [
          const Text(
            'Analiz Sistemlerimiz',
            style: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1A2340),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Optiyou analiz sistemleri; 3D ayak tarama, ayak sağlığı analizi ve farklı operasyonel ihtiyaçlara uygun tarama altyapısı sunar.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.grey.shade600,
              fontSize: 16,
              height: 1.6,
            ),
          ),
          const SizedBox(height: 42),
          Wrap(
            spacing: 24,
            runSpacing: 24,
            alignment: WrapAlignment.center,
            children: [
              _AnalysisSystemCard(
                isNarrow: isNarrow,
                title: 'OY Scan',
                subtitle: 'Modüler ayak sağlığı analiz sistemi',
                description:
                    'OY Scan; 3D ayak tarama ve ayak sağlığı analizi için geliştirilen modüler bir sistemdir. Klinik, uzman ve bireysel kullanım senaryolarına uygundur.',
                imagePath: 'assets/images/systems/oy_scan.png',
                highlights: const [
                  '3D ayak tarama',
                  'Ayak sağlığı analizi',
                  'Modüler genişleme yapısı',
                  'Klinik ve uzman kullanımı',
                ],
                comparisonItems: const [
                  _SystemComparisonItem(label: '3D ayak tarama', available: true),
                  _SystemComparisonItem(label: 'Ayak sağlığı analizi', available: true),
                  _SystemComparisonItem(label: 'Plantar basınç ölçümü', available: true),
                  _SystemComparisonItem(label: 'Ayakkabı içi dinamik ölçüm', available: true),
                  _SystemComparisonItem(label: 'Yüksek hacimli tarama', available: false),
                  _SystemComparisonItem(label: 'Fabrika / yoğun sirkülasyon', available: false),
                ],
                modules: const [
                  _SystemMiniModule(
                    title: 'Plantar Basınç Ölçüm Pedi',
                    imagePath: 'assets/images/systems/plantar_pressure_pad.png',
                  ),
                  _SystemMiniModule(
                    title: 'Ayakkabı İçi Dinamik Modül',
                    imagePath: 'assets/images/systems/inshoe_dynamic_pressure.png',
                  ),
                ],
              ),
              _AnalysisSystemCard(
                isNarrow: isNarrow,
                title: 'OY Scan Pro',
                subtitle: 'Yüksek hacimli tarama için gelişmiş sistem',
                description:
                    'OY Scan Pro; daha hızlı ayak tarama yapısı ile yüksek sirkülasyonlu alanlarda, kurumsal tarama operasyonlarında ve fabrikalarda verimli kullanım sağlar.',
                imagePath: 'assets/images/systems/oy_scan_pro.png',
                highlights: const [
                  'Yüksek hızda ayak tarama',
                  'Kurumsal saha kullanımı',
                  'Yoğun çalışan grupları için uygun',
                  'Toplu analiz operasyonları',
                ],
                comparisonItems: const [
                  _SystemComparisonItem(label: '3D ayak tarama', available: true),
                  _SystemComparisonItem(label: 'Ayak sağlığı analizi', available: true),
                  _SystemComparisonItem(label: 'Plantar basınç ölçümü', available: false),
                  _SystemComparisonItem(label: 'Ayakkabı içi dinamik ölçüm', available: false),
                  _SystemComparisonItem(label: 'Yüksek hacimli tarama', available: true),
                  _SystemComparisonItem(label: 'Fabrika / yoğun sirkülasyon', available: true),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SystemComparisonItem {
  final String label;
  final bool available;

  const _SystemComparisonItem({
    required this.label,
    required this.available,
  });
}

class _SystemMiniModule {
  final String title;
  final String imagePath;

  const _SystemMiniModule({
    required this.title,
    required this.imagePath,
  });
}

class _AnalysisSystemCard extends StatefulWidget {
  final bool isNarrow;
  final String title;
  final String subtitle;
  final String description;
  final String imagePath;
  final List<String> highlights;
  final List<_SystemComparisonItem> comparisonItems;
  final List<_SystemMiniModule> modules;

  const _AnalysisSystemCard({
    required this.isNarrow,
    required this.title,
    required this.subtitle,
    required this.description,
    required this.imagePath,
    required this.highlights,
    required this.comparisonItems,
    this.modules = const [],
  });

  @override
  State<_AnalysisSystemCard> createState() => _AnalysisSystemCardState();
}

class _AnalysisSystemCardState extends State<_AnalysisSystemCard> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOut,
        width: widget.isNarrow ? double.infinity : 520,
        padding: const EdgeInsets.all(22),
        decoration: BoxDecoration(
          color: const Color(0xFFF7F9FB),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: Colors.teal.withOpacity(_hovered ? 0.20 : 0.10),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(_hovered ? 0.08 : 0.04),
              blurRadius: _hovered ? 18 : 10,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Image.asset(
                widget.imagePath,
                height: 220,
                width: double.infinity,
                fit: BoxFit.cover,
              ),
            ),
            const SizedBox(height: 18),
            Text(
              widget.title,
              style: const TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1A2340),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              widget.subtitle,
              style: TextStyle(
                fontSize: 15,
                color: Colors.teal.shade700,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 14),
            Text(
              widget.description,
              style: TextStyle(
                color: Colors.grey.shade700,
                fontSize: 14,
                height: 1.6,
              ),
            ),
            const SizedBox(height: 18),
            const Text(
              'Öne Çıkanlar',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: Color(0xFF1A2340),
              ),
            ),
            const SizedBox(height: 12),
            ...widget.highlights.map(
              (item) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Padding(
                      padding: EdgeInsets.only(top: 3),
                      child: Icon(
                        Icons.check_circle_outline,
                        size: 17,
                        color: Colors.teal,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        item,
                        style: TextStyle(
                          color: Colors.grey.shade800,
                          fontSize: 14,
                          height: 1.45,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            if (widget.modules.isNotEmpty) ...[
              const SizedBox(height: 10),
              const Text(
                'Opsiyonel Ölçüm Modülleri',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: Color(0xFF1A2340),
                ),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: widget.modules.map((module) {
                  return _SystemMiniModuleCard(module: module);
                }).toList(),
              ),
            ],
            const SizedBox(height: 18),
            const Text(
              'Sistem Uygunluğu',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: Color(0xFF1A2340),
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: widget.comparisonItems.map((item) {
                return _SystemAvailabilityChip(item: item);
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }
}

class _SystemMiniModuleCard extends StatelessWidget {
  final _SystemMiniModule module;

  const _SystemMiniModuleCard({
    required this.module,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 220,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.teal.withOpacity(0.08)),
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: Image.asset(
              module.imagePath,
              width: 54,
              height: 54,
              fit: BoxFit.cover,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              module.title,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Color(0xFF1A2340),
                height: 1.35,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SystemAvailabilityChip extends StatelessWidget {
  final _SystemComparisonItem item;

  const _SystemAvailabilityChip({
    required this.item,
  });

  @override
  Widget build(BuildContext context) {
    final bgColor = item.available
        ? Colors.green.withOpacity(0.10)
        : Colors.grey.withOpacity(0.12);

    final textColor = item.available ? Colors.green.shade700 : Colors.grey.shade700;
    final iconColor = item.available ? Colors.green : Colors.grey;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            item.available ? Icons.check_circle : Icons.remove_circle_outline,
            size: 16,
            color: iconColor,
          ),
          const SizedBox(width: 6),
          Text(
            item.label,
            style: TextStyle(
              color: textColor,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Hizmetler ────────────────────────────────────────────────────────────────

class _ServicesSection extends StatelessWidget {
  final bool isNarrow;

  const _ServicesSection({required this.isNarrow});

  static const services = [
    {
      'icon': Icons.health_and_safety,
      'title': 'Ayak Sağlığı Ekosistemi',
      'desc': 'Dijital takip ve analiz sistemi ile ayak sağlığınızı izleyin.',
      'more':
          'Periyodik analizler, risk dağılımı, kullanıcı geçmişi ve veri tabanlı içgörüleri tek platformda yönetin.',
      'image': 'assets/images/services/foot_health_ecosystem.png',
    },
    {
      'icon': Icons.design_services,
      'title': 'Kişisel Ortopedik Tasarım',
      'desc': 'Kişiye özel ortopedik ürünler ve tabanlık tasarımları.',
      'more':
          'Tarama ve basınç analizinden sonra ayağa özel ürün geliştirme ve üretim hazırlık sürecini destekler.',
      'image': 'assets/images/services/personal_orthopedic_design.png',
    },
    {
      'icon': Icons.sports_soccer,
      'title': 'Sporcu Takip Sistemi',
      'desc': 'Performans ve sakatlık riskini takip eden sistem.',
      'more':
          'Sporcularda basış, yük dağılımı ve destek ihtiyacı analiz edilerek performans takibi yapılır.',
      'image': 'assets/images/services/athlete_tracking.png',
    },
    {
      'icon': Icons.factory,
      'title': 'Kurumsal Üretim (B2B)',
      'desc': 'Toplu üretim ve takip sistemleri.',
      'more':
          'Departman, görev ve demografik kırılımlarla kurumsal firmalarda ayak sağlığı eğilimlerini analiz edin.',
      'image': 'assets/images/services/corporate_b2b.png',
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      color: Colors.white,
      padding: EdgeInsets.symmetric(
        horizontal: isNarrow ? 24 : 80,
        vertical: 70,
      ),
      child: Column(
        children: [
          const Text(
            'Hizmetlerimiz',
            style: TextStyle(fontSize: 30, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          Text(
            'Optiyou çözümleri bireysel, uzman ve kurumsal kullanım senaryolarına göre şekillenir.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.grey.shade600,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 40),
          Wrap(
            spacing: 20,
            runSpacing: 20,
            children: services.map((s) {
              return _ServiceCard(
                icon: s['icon'] as IconData,
                title: s['title'] as String,
                desc: s['desc'] as String,
                more: s['more'] as String,
                imagePath: s['image'] as String,
                isNarrow: isNarrow,
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}

class _ServiceCard extends StatefulWidget {
  final IconData icon;
  final String title;
  final String desc;
  final String more;
  final String imagePath;
  final bool isNarrow;

  const _ServiceCard({
    required this.icon,
    required this.title,
    required this.desc,
    required this.more,
    required this.imagePath,
    required this.isNarrow,
  });

  @override
  State<_ServiceCard> createState() => _ServiceCardState();
}

class _ServiceCardState extends State<_ServiceCard> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final width = widget.isNarrow ? double.infinity : 270.0;
    final height = _hovered ? 360.0 : 230.0;

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOut,
        width: width,
        height: height,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.grey.shade50,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(_hovered ? 0.08 : 0.03),
              blurRadius: _hovered ? 16 : 8,
              offset: const Offset(0, 4),
            ),
          ],
          border: Border.all(
            color: Colors.teal.withOpacity(_hovered ? 0.20 : 0.08),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(widget.icon, size: 38, color: Colors.teal),
            const SizedBox(height: 12),
            Text(
              widget.title,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 17,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              widget.desc,
              style: TextStyle(
                color: Colors.grey.shade700,
                height: 1.45,
              ),
            ),
            if (_hovered) ...[
              const SizedBox(height: 14),
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.asset(
                  widget.imagePath,
                  height: 120,
                  width: double.infinity,
                  fit: BoxFit.cover,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                widget.more,
                style: TextStyle(
                  color: Colors.grey.shade700,
                  fontSize: 13,
                  height: 1.4,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ── Ürünler ──────────────────────────────────────────────────────────────────

class _ProductsSection extends StatelessWidget {
  final bool isNarrow;
  final VoidCallback onOpenStore;

  const _ProductsSection({
    required this.isNarrow,
    required this.onOpenStore,
  });

  static const products = [
    {
      'title': 'Kişisel Ortopedik İç Taban',
      'desc': 'Günlük kullanım için kişiye özel destek.',
      'image': 'assets/images/products/personal_insole.png',
    },
    {
      'title': 'Sporcu Tabanlığı',
      'desc': 'Performans ve hareket için destekleyici yapı.',
      'image': 'assets/images/products/sport_insole.png',
    },
    {
      'title': 'Yenileyici Sandalet',
      'desc': 'Gün sonu rahatlama ve destek hissi.',
      'image': 'assets/images/products/recovery_sandal.png',
    },
    {
      'title': 'Kişisel Ayakkabı',
      'desc': 'Ayak yapınıza göre geliştirilen kişisel kullanım çözümü.',
      'image': 'assets/images/products/personal_shoe.png',
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      color: const Color(0xFFF7F9FB),
      padding: EdgeInsets.symmetric(
        horizontal: isNarrow ? 24 : 80,
        vertical: 70,
      ),
      child: Column(
        children: [
          const Text(
            'Ürünlerimiz',
            style: TextStyle(fontSize: 30, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          Text(
            'Optiyou ürünleri analiz sonuçlarına göre kişisel veya hedefli kullanım senaryolarına uyarlanır.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.grey.shade600,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 40),
          Wrap(
            spacing: 20,
            runSpacing: 20,
            children: products.map((p) {
              return _ProductCard(
                title: p['title'] as String,
                desc: p['desc'] as String,
                imagePath: p['image'] as String,
                isNarrow: isNarrow,
                onOpen: onOpenStore,
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}

class _ProductCard extends StatefulWidget {
  final String title;
  final String desc;
  final String imagePath;
  final bool isNarrow;
  final VoidCallback onOpen;

  const _ProductCard({
    required this.title,
    required this.desc,
    required this.imagePath,
    required this.isNarrow,
    required this.onOpen,
  });

  @override
  State<_ProductCard> createState() => _ProductCardState();
}

class _ProductCardState extends State<_ProductCard> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: widget.isNarrow ? double.infinity : 270,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(_hovered ? 0.09 : 0.05),
              blurRadius: _hovered ? 16 : 10,
              offset: const Offset(0, 6),
            ),
          ],
          border: Border.all(
            color: Colors.teal.withOpacity(_hovered ? 0.18 : 0.06),
          ),
        ),
        child: Column(
          children: [
            ClipRRect(
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(16),
              ),
              child: Image.asset(
                widget.imagePath,
                height: 180,
                width: double.infinity,
                fit: BoxFit.cover,
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.title,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 17,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    widget.desc,
                    style: TextStyle(
                      color: Colors.grey.shade700,
                      height: 1.45,
                    ),
                  ),
                  const SizedBox(height: 14),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: widget.onOpen,
                      style: ElevatedButton.styleFrom(
                        backgroundColor:
                            _hovered ? Colors.teal.shade700 : Colors.teal,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: const Text('Ürünü İncele'),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Rakamlarla Etkimiz ───────────────────────────────────────────────────────

class _ImpactStatsSection extends StatelessWidget {
  final bool isNarrow;

  const _ImpactStatsSection({required this.isNarrow});

  static const stats = [
    {
      'value': '%30',
      'title': 'Ağrılarda Azalma',
      'desc':
          'Kişisel iç tabanlık kullanımında ayak, bel ve eklem ağrılarında düşüş gözlemlenebilir.',
    },
    {
      'value': '%40',
      'title': 'Metatarsal Basınç Azalması',
      'desc':
          'Ayağın metatarsal bölgesindeki yük ve basınç belirgin biçimde azaltılabilir.',
    },
    {
      'value': '%87',
      'title': 'Kullanıcı Memnuniyeti',
      'desc':
          'Ortopedik iç taban kullanan bireylerde yüksek memnuniyet oranı görülmektedir.',
    },
    {
      'value': '%10',
      'title': 'Diz Rotasyonunda Azalma',
      'desc':
          'Diz eklemindeki yanal dönüş hareketinde azalma ile biyomekanik denge desteklenebilir.',
    },
    {
      'value': '%12',
      'title': 'İçe Dönmede Azalma',
      'desc':
          'Ayak bileği inversiyon momentindeki düşüş daha dengeli bir basış sağlayabilir.',
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      color: Colors.white,
      padding: EdgeInsets.symmetric(
        horizontal: isNarrow ? 24 : 80,
        vertical: 70,
      ),
      child: Column(
        children: [
          const Text(
            'Rakamlarla Etkimiz',
            style: TextStyle(
              fontSize: 30,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1A2340),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'Ayak sağlığı ve ortopedik destek süreçlerinde öne çıkan etkiler',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.grey.shade600,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 40),
          Wrap(
            spacing: 20,
            runSpacing: 20,
            alignment: WrapAlignment.center,
            children: stats.map((item) {
              return _ImpactStatCard(
                value: item['value']!,
                title: item['title']!,
                desc: item['desc']!,
                isNarrow: isNarrow,
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}

class _ImpactStatCard extends StatelessWidget {
  final String value;
  final String title;
  final String desc;
  final bool isNarrow;

  const _ImpactStatCard({
    required this.value,
    required this.title,
    required this.desc,
    required this.isNarrow,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: isNarrow ? double.infinity : 300,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: const Color(0xFFF7F9FB),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.teal.withOpacity(0.10)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            style: const TextStyle(
              fontSize: 34,
              fontWeight: FontWeight.bold,
              color: Colors.teal,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            title,
            style: const TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1A2340),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            desc,
            style: TextStyle(
              color: Colors.grey.shade600,
              fontSize: 14,
              height: 1.55,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Kimin İçin ───────────────────────────────────────────────────────────────

class _KimIcinSection extends StatelessWidget {
  final bool isNarrow;

  const _KimIcinSection({required this.isNarrow});

  static const targets = [
    {
      'icon': Icons.child_care,
      'title': 'Gelişim Çağındaki Çocuklar',
      'desc': 'Ayak sağlığı gelişiminde destek isteyen çocuklar',
      'items': [
        'Düz taban / çukur taban eğilimleri',
        'İçe veya dışa basma sorunları',
        'Büyüme sürecinde ortopedik destek ihtiyacı',
      ],
    },
    {
      'icon': Icons.accessibility_new,
      'title': 'Ortopedik Kullanım',
      'desc': 'Yürüme ve basma sorunu yaşayan yetişkinler',
      'items': [
        'Düz / çukur taban',
        'İçe basma',
        'Diyabetik ayak',
        'Topuk dikeni',
        'Hallux valgus',
      ],
    },
    {
      'icon': Icons.engineering,
      'title': 'Çalışanlar ve Emekçiler',
      'desc': 'Ayakta uzun süre çalışan iş kolları',
      'items': [
        'Emek yoğun çalışanlar',
        'Sağlık çalışanları',
        'Öğretmenler',
        'Fabrika işçileri',
      ],
    },
    {
      'icon': Icons.sports,
      'title': 'Sporcular',
      'desc': 'Performansını geliştirmek isteyen sporcular',
      'items': [
        'Bireysel sporcular',
        'Takım sporcuları',
      ],
    },
    {
      'icon': Icons.favorite_border,
      'title': 'Hayat Kalitesini Artırmak İsteyenler',
      'desc': 'Daha konforlu ve sağlıklı bir basış hedefleyen bireyler',
      'items': [
        'Ayak, bel ve kas ağrısı yaşayan bireyler',
        'Kilo problemi olan bireyler',
        'Ayak sağlığını korumak isteyenler',
        'Sağlıklı ve konforlu bir basış deneyimi isteyenler',
      ],
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      color: const Color(0xFFF7F9FB),
      padding: EdgeInsets.symmetric(
        horizontal: isNarrow ? 24 : 80,
        vertical: 70,
      ),
      child: Column(
        children: [
          const Text(
            'Kimin İçin?',
            style: TextStyle(
              fontSize: 30,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1A2340),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'Optiyou çözümleri farklı yaş, ihtiyaç ve kullanım senaryolarına uygun olarak tasarlanır.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.grey.shade600,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 40),
          Wrap(
            spacing: 20,
            runSpacing: 20,
            alignment: WrapAlignment.center,
            children: targets.map((item) {
              return _TargetUserCard(
                icon: item['icon'] as IconData,
                title: item['title'] as String,
                desc: item['desc'] as String,
                items: item['items'] as List<String>,
                isNarrow: isNarrow,
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}

class _TargetUserCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String desc;
  final List<String> items;
  final bool isNarrow;

  const _TargetUserCard({
    required this.icon,
    required this.title,
    required this.desc,
    required this.items,
    required this.isNarrow,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: isNarrow ? double.infinity : 320,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: Colors.teal.withOpacity(0.10),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: Colors.teal, size: 24),
          ),
          const SizedBox(height: 16),
          Text(
            title,
            style: const TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1A2340),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            desc,
            style: TextStyle(
              color: Colors.grey.shade600,
              fontSize: 14,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 14),
          ...items.map(
            (item) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Padding(
                    padding: EdgeInsets.only(top: 3),
                    child: Icon(
                      Icons.check_circle,
                      size: 16,
                      color: Colors.teal,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      item,
                      style: const TextStyle(
                        fontSize: 13.5,
                        color: Color(0xFF3D4E6B),
                        height: 1.45,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Merkezler ────────────────────────────────────────────────────────────────

class _MeasurementCentersSection extends StatelessWidget {
  final bool isNarrow;

  const _MeasurementCentersSection({required this.isNarrow});

  static const centers = [
    {
      'title': 'CAST Cerrahpaşa Araştırma Simülasyon ve Tasarım Merkezi',
      'subtitle': 'İstanbul Üniversitesi-Cerrahpaşa',
      'city': 'İstanbul',
      'address':
          'Cerrahpaşa Yerleşkesi, O Blok, 2.Kat, Kocamustafapaşa Caddesi, No:53 Cerrahpaşa 34098 Fatih/İstanbul',
      'icon': Icons.local_hospital_outlined,
    },
    {
      'title': 'İzmir Tınaztepe Üniversitesi Dijital Üretim Laboratuvarı (DML)',
      'subtitle': 'İzmir Tınaztepe Üniversitesi',
      'city': 'İzmir',
      'address': 'Aydoğdu, 1267/1 Sk No:4 C Blok, 35400 Buca/İzmir',
      'icon': Icons.precision_manufacturing_outlined,
    },
    {
      'title': 'Entertech İstanbul Teknokent Üniversite',
      'subtitle': 'Entertech İstanbul Teknokent',
      'city': 'İstanbul',
      'address': 'Sarıgül Sk. No:37/1 İç Kapı No:97, 34320 Avcılar/İstanbul',
      'icon': Icons.apartment_outlined,
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      color: Colors.white,
      padding: EdgeInsets.symmetric(
        horizontal: isNarrow ? 24 : 80,
        vertical: 70,
      ),
      child: Column(
        children: [
          const Text(
            'Ölçüm Merkezlerimiz',
            style: TextStyle(
              fontSize: 30,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1A2340),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'Ayak analizi, ölçüm ve değerlendirme süreçlerimize farklı merkezlerimiz üzerinden erişebilirsiniz.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.grey.shade600,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 40),
          Wrap(
            spacing: 20,
            runSpacing: 20,
            alignment: WrapAlignment.center,
            children: centers.map((center) {
              return _MeasurementCenterCard(
                title: center['title'] as String,
                subtitle: center['subtitle'] as String,
                city: center['city'] as String,
                address: center['address'] as String,
                icon: center['icon'] as IconData,
                isNarrow: isNarrow,
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}

class _MeasurementCenterCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final String city;
  final String address;
  final IconData icon;
  final bool isNarrow;

  const _MeasurementCenterCard({
    required this.title,
    required this.subtitle,
    required this.city,
    required this.address,
    required this.icon,
    required this.isNarrow,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: isNarrow ? double.infinity : 320,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: const Color(0xFFF7F9FB),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.teal.withOpacity(0.10)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: Colors.teal.withOpacity(0.10),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: Colors.teal, size: 24),
              ),
              const Spacer(),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.teal.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  city,
                  style: const TextStyle(
                    color: Colors.teal,
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            title,
            style: const TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1A2340),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: TextStyle(
              color: Colors.grey.shade700,
              fontWeight: FontWeight.w600,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                Icons.location_on_outlined,
                size: 18,
                color: Colors.grey.shade700,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  address,
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontSize: 14,
                    height: 1.5,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Hakkımızda ───────────────────────────────────────────────────────────────

class _AboutSection extends StatelessWidget {
  final bool isNarrow;

  const _AboutSection({required this.isNarrow});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      color: Colors.white,
      padding: EdgeInsets.symmetric(
        horizontal: isNarrow ? 24 : 80,
        vertical: 80,
      ),
      child: isNarrow
          ? _content()
          : Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(flex: 5, child: _visual()),
                const SizedBox(width: 64),
                Expanded(flex: 5, child: _content()),
              ],
            ),
    );
  }

  Widget _content() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
          decoration: BoxDecoration(
            color: Colors.teal.withOpacity(0.1),
            borderRadius: BorderRadius.circular(20),
          ),
          child: const Text(
            'Hakkımızda',
            style: TextStyle(
              color: Colors.teal,
              fontWeight: FontWeight.w600,
              fontSize: 13,
            ),
          ),
        ),
        const SizedBox(height: 16),
        const Text(
          'Optiyou Nedir?',
          style: TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1A2340),
          ),
        ),
        const SizedBox(height: 16),
        Text(
          'Optiyou; ayak sağlığı analizi, ortopedik ürün tasarımı ve dijital takip süreçlerini bir araya getiren teknoloji odaklı bir çözüm ekosistemidir. Bireysel kullanıcılar, uzmanlar ve kurumsal firmalar için veri destekli değerlendirme ve ürünleştirme altyapısı sunar.',
          style: TextStyle(
            color: Colors.grey.shade600,
            fontSize: 15,
            height: 1.65,
          ),
        ),
        const SizedBox(height: 16),
        Text(
          'Amacımız; ayak sağlığı verilerini daha anlaşılır, daha takip edilebilir ve daha uygulanabilir hale getirerek hem kişisel yaşam kalitesini hem de operasyonel faydayı artırmaktır.',
          style: TextStyle(
            color: Colors.grey.shade600,
            fontSize: 15,
            height: 1.65,
          ),
        ),
        const SizedBox(height: 28),
        _bulletPoint('Bireysel ve uzman odaklı dijital analiz deneyimi'),
        _bulletPoint('Kişisel ortopedik ürün tasarım ve yönlendirme süreci'),
        _bulletPoint('Sporcu performansı ve yük takibi'),
        _bulletPoint('Kurumsal firmalar için toplu sağlık içgörüleri'),
      ],
    );
  }

  Widget _bulletPoint(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Container(
            width: 20,
            height: 20,
            decoration: const BoxDecoration(
              color: Colors.teal,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.check, color: Colors.white, size: 13),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Color(0xFF1A2340),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _visual() {
    return Container(
      height: 400,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.teal.shade50,
            Colors.teal.shade100,
          ],
        ),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Positioned(
            top: 34,
            left: 24,
            child: _infoChip(
              Icons.show_chart,
              'Dijital Ayak Analizi',
              Colors.teal,
            ),
          ),
          Positioned(
            top: 110,
            right: 20,
            child: _infoChip(
              Icons.design_services,
              'Kişisel Ortopedik Ürünler',
              Colors.deepPurple,
            ),
          ),
          Positioned(
            bottom: 110,
            left: 24,
            child: _infoChip(
              Icons.sports_soccer,
              'Sporcu Takibi',
              Colors.blue,
            ),
          ),
          Positioned(
            bottom: 34,
            right: 24,
            child: _infoChip(
              Icons.apartment_outlined,
              'Kurumsal Sağlık Analitiği',
              Colors.orange,
            ),
          ),
          const Icon(
            Icons.accessibility_new,
            size: 140,
            color: Colors.teal,
          ),
        ],
      ),
    );
  }

  Widget _infoChip(IconData icon, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.2),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
          ),
        ],
      ),
    );
  }
}

// ── CTA ──────────────────────────────────────────────────────────────────────

class _CtaSection extends StatelessWidget {
  final VoidCallback onGetStarted;
  final VoidCallback onLogin;

  const _CtaSection({
    required this.onGetStarted,
    required this.onLogin,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF00695C), Color(0xFF00897B)],
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 72),
      child: Column(
        children: [
          const Text(
            'Ayak Sağlığında Dijital Takibe Geçin',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white,
              fontSize: 34,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 14),
          Text(
            'Optiyou ile analiz, takip ve kişisel çözüm süreçlerini tek platformda deneyimleyin.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white.withOpacity(0.85),
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 36),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ElevatedButton(
                onPressed: onGetStarted,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: Colors.teal.shade800,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: const Text(
                  'Kayıt Ol',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(width: 14),
              OutlinedButton(
                onPressed: onLogin,
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.white,
                  side: BorderSide(color: Colors.white.withOpacity(0.6)),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: const Text(
                  'Giriş Yap',
                  style: TextStyle(fontSize: 16),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Footer ───────────────────────────────────────────────────────────────────

class _Footer extends StatelessWidget {
  const _Footer();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFF1A2340),
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 30),
      child: Column(
        children: [
          Image.asset(
            'assets/images/branding/logo_footer.png',
            height: 48,
          ),
          const SizedBox(height: 18),
          Text(
            '© 2026 Tüm hakları saklıdır.',
            style: TextStyle(
              color: Colors.white.withOpacity(0.45),
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}