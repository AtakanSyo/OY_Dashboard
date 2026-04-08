import 'package:flutter/material.dart';
import 'package:oy_site/screens/auth/login_screen.dart';
import 'package:oy_site/screens/auth/register_screen.dart';

class HomeScreen extends StatefulWidget {
  final dynamic pressureRepository;
  const HomeScreen({super.key, required this.pressureRepository});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final ScrollController _scrollController = ScrollController();
  final GlobalKey _featuresKey = GlobalKey();
  final GlobalKey _aboutKey = GlobalKey();

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
            onScrollToFeatures: () => _scrollTo(_featuresKey),
            onScrollToAbout: () => _scrollTo(_aboutKey),
            isNarrow: isNarrow,
          ),
          Expanded(
            child: SingleChildScrollView(
              controller: _scrollController,
              child: Column(
                children: [
                  _HeroSection(isNarrow: isNarrow, onGetStarted: _goToRegister),
                  Container(key: _featuresKey, child: _FeaturesSection(isNarrow: isNarrow)),
                  Container(key: _aboutKey, child: _AboutSection(isNarrow: isNarrow)),
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
  final VoidCallback onScrollToFeatures;
  final VoidCallback onScrollToAbout;
  final bool isNarrow;

  const _Navbar({
    required this.onLogin,
    required this.onRegister,
    required this.onScrollToFeatures,
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
          // Logo
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Colors.teal.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Image.asset(
                  'assets/images/favicon.png',
                  height: 20,
                ),
              ),

              const SizedBox(width: 20),

              Image.asset(
                'assets/images/logo.png',
                height: 50,
              ),
            ],
          ),
          const Spacer(),
          // Nav links (wide only)
          if (!isNarrow) ...[  
            _NavLink(label: 'Özellikler', onTap: onScrollToFeatures),
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
              child: const Text('Giriş Yap',
                  style: TextStyle(fontWeight: FontWeight.w600)),
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
              child: const Text('Kayıt Ol',
                  style: TextStyle(fontWeight: FontWeight.w600)),
            ),
          ] else
            // Hamburger menu (narrow)
            PopupMenuButton<String>(
              icon: const Icon(Icons.menu, color: Color(0xFF1A2340), size: 26),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              offset: const Offset(0, 52),
              onSelected: (value) {
                switch (value) {
                  case 'features':
                    onScrollToFeatures();
                  case 'about':
                    onScrollToAbout();
                  case 'login':
                    onLogin();
                  case 'register':
                    onRegister();
                }
              },
              itemBuilder: (_) => [
                const PopupMenuItem(
                  value: 'features',
                  child: Row(
                    children: [
                      Icon(Icons.star_outline, size: 18, color: Colors.teal),
                      SizedBox(width: 10),
                      Text('Özellikler'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'about',
                  child: Row(
                    children: [
                      Icon(Icons.info_outline, size: 18, color: Colors.teal),
                      SizedBox(width: 10),
                      Text('Hakkımızda'),
                    ],
                  ),
                ),
                const PopupMenuDivider(),
                const PopupMenuItem(
                  value: 'login',
                  child: Row(
                    children: [
                      Icon(Icons.login, size: 18, color: Colors.teal),
                      SizedBox(width: 10),
                      Text('Giriş Yap'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'register',
                  child: Row(
                    children: [
                      Icon(Icons.person_add_outlined,
                          size: 18, color: Colors.teal),
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

// ── Nav link with hover underline ────────────────────────────────────────────

class _NavLink extends StatefulWidget {
  final String label;
  final VoidCallback onTap;
  const _NavLink({required this.label, required this.onTap});

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
                  color:
                      _hovered ? Colors.teal : const Color(0xFF3D4E6B),
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
  const _HeroSection({required this.isNarrow, required this.onGetStarted});

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
            'Ortopedik Tabanlık Yönetim Platformu',
            style: TextStyle(
              color: Colors.white,
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        const SizedBox(height: 20),
        Text(
          'Ayak Sağlığında\nYeni Nesil\nYönetim',
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
          'OptiYou, klinisyenler için geliştirilmiş bütünleşik bir ayak tarama, basınç analizi ve özel tabanlık tasarım platformudur. Hastalarınızı yönetin, ölçümleri takip edin, siparişleri dijital ortamda işleyin.',
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
                padding: const EdgeInsets.symmetric(
                    horizontal: 28, vertical: 16),
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: const Text(
                'Ücretsiz Başla',
                style:
                    TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(width: 14),
            OutlinedButton(
              onPressed: () {},
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.white,
                side: BorderSide(color: Colors.white.withOpacity(0.6)),
                padding: const EdgeInsets.symmetric(
                    horizontal: 24, vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: const Text('Daha Fazla Bilgi',
                  style: TextStyle(fontSize: 16)),
            ),
          ],
        ),
        const SizedBox(height: 48),
        if (!isNarrow)
          Row(
            children: [
              _statBadge('2,500+', 'Analiz Edilmiş Ayak'),
              const SizedBox(width: 32),
              _statBadge('150+', 'Aktif Klinisyen'),
              const SizedBox(width: 32),
              _statBadge('98%', 'Müşteri Memnuniyeti'),
            ],
          ),
      ],
    );
  }

  Widget _statBadge(String value, String label) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(value,
            style: const TextStyle(
                color: Colors.white,
                fontSize: 28,
                fontWeight: FontWeight.bold)),
        Text(label,
            style: TextStyle(
                color: Colors.white.withOpacity(0.75), fontSize: 13)),
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
              top: 30,
              left: 30,
              child: _floatingCard(
                icon: Icons.show_chart,
                label: 'Basınç Haritası',
                color: Colors.orange,
              ),
            ),
            Positioned(
              top: 110,
              right: 20,
              child: _floatingCard(
                icon: Icons.rotate_90_degrees_ccw,
                label: '3D Ayak Tarama',
                color: Colors.purple,
              ),
            ),
            Positioned(
              bottom: 60,
              left: 20,
              child: _floatingCard(
                icon: Icons.inventory_2,
                label: 'Sipariş Takibi',
                color: Colors.teal,
              ),
            ),
            const Icon(Icons.accessibility_new,
                size: 100, color: Colors.white54),
          ],
        ),
      ),
    );
  }

  Widget _floatingCard(
      {required IconData icon,
      required String label,
      required Color color}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
              color: color.withOpacity(0.25),
              blurRadius: 12,
              offset: const Offset(0, 4))
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(width: 6),
          Text(label,
              style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey.shade800)),
        ],
      ),
    );
  }
}

// ── Features ─────────────────────────────────────────────────────────────────

class _FeaturesSection extends StatelessWidget {
  final bool isNarrow;
  const _FeaturesSection({required this.isNarrow});

  static const List<Map<String, dynamic>> _features = [
    {
      'icon': Icons.scanner,
      'color': Color(0xFF00897B),
      'title': 'Ayak Tarama',
      'desc':
          'Yüksek çözünürlüklü 3D tarama ile ayak profilini hassas biçimde ölçün. Sonuçları anında kaydedin ve geçmişle karşılaştırın.',
    },
    {
      'icon': Icons.thermostat,
      'color': Color(0xFFE64A19),
      'title': 'Basınç Analizi',
      'desc':
          'Gerçek zamanlı plantar basınç haritalaması ile yük dağılımını görselleştirin. Seri port entegrasyonu ile donanım direkt bağlanır.',
    },
    {
      'icon': Icons.design_services,
      'color': Color(0xFF5C6BC0),
      'title': 'Tabanlık Tasarımı',
      'desc':
          'Hastanın ölçümlerine göre özelleştirilmiş ortopedik tabanlık tasarımı oluşturun ve üretim için hazırlayın.',
    },
    {
      'icon': Icons.people_alt,
      'color': Color(0xFF039BE5),
      'title': 'Hasta Yönetimi',
      'desc':
          'Tüm fizyometrik verileri, tedavi notlarını ve seans geçmişini tek bir dijital hasta profilinde saklayın.',
    },
    {
      'icon': Icons.shopping_cart,
      'color': Color(0xFF43A047),
      'title': 'Sipariş & Stok',
      'desc':
          'Tabanlık siparişlerini oluşturun, takip edin ve laboratuvar ile kolay entegrasyon sağlayan bir akış üzerinden yönetin.',
    },
    {
      'icon': Icons.bar_chart,
      'color': Color(0xFFF9A825),
      'title': 'Raporlama',
      'desc':
          'Klinik performansı, hasta istatistiklerini ve ürün analizlerini interaktif grafiklerle görüntüleyin.',
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
            'Klinik iş akışınızı uçtan uca dijitalleştiren özellikler',
            style: TextStyle(color: Colors.grey.shade600, fontSize: 16),
          ),
          const SizedBox(height: 52),
          Wrap(
            spacing: 24,
            runSpacing: 24,
            alignment: WrapAlignment.center,
            children: _features
                .map((f) => _FeatureCard(
                      icon: f['icon'] as IconData,
                      color: f['color'] as Color,
                      title: f['title'] as String,
                      desc: f['desc'] as String,
                      isNarrow: isNarrow,
                    ))
                .toList(),
          ),
        ],
      ),
    );
  }
}

class _FeatureCard extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;
  final String desc;
  final bool isNarrow;

  const _FeatureCard({
    required this.icon,
    required this.color,
    required this.title,
    required this.desc,
    required this.isNarrow,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: isNarrow ? double.infinity : 310,
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
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
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 26),
          ),
          const SizedBox(height: 16),
          Text(title,
              style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1A2340))),
          const SizedBox(height: 8),
          Text(desc,
              style: TextStyle(
                  color: Colors.grey.shade600,
                  fontSize: 14,
                  height: 1.55)),
        ],
      ),
    );
  }
}

// ── About ────────────────────────────────────────────────────────────────────

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
          padding:
              const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
          decoration: BoxDecoration(
            color: Colors.teal.withOpacity(0.1),
            borderRadius: BorderRadius.circular(20),
          ),
          child: const Text('Hakkımızda',
              style: TextStyle(
                  color: Colors.teal,
                  fontWeight: FontWeight.w600,
                  fontSize: 13)),
        ),
        const SizedBox(height: 16),
        const Text(
          'OptiYou Kimdir?',
          style: TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1A2340),
          ),
        ),
        const SizedBox(height: 16),
        Text(
          'OptiYou, ortopedik sağlık profesyonelleri için geliştirilmiş bir teknoloji şirketidir. Misyonumuz; ayak sağlığı ve ortotik çözümler alanında klinisyenlere güçlü dijital araçlar sunarak hasta bakımını iyileştirmek ve iş süreçlerini optimize etmektir.',
          style: TextStyle(
              color: Colors.grey.shade600, fontSize: 15, height: 1.65),
        ),
        const SizedBox(height: 16),
        Text(
          'Platformumuz; ayak tarama cihazları, basınç sensörleri ve özel yazılım altyapısı ile bütünleşik bir ekosistem sunar. Veri güvenliği ve hasta mahremiyeti her zaman ön plandadır.',
          style: TextStyle(
              color: Colors.grey.shade600, fontSize: 15, height: 1.65),
        ),
        const SizedBox(height: 28),
        _bulletPoint('Bulut tabanlı güvenli altyapı'),
        _bulletPoint('Çoklu klinik ve kullanıcı yönetimi'),
        _bulletPoint('Gerçek zamanlı donanım entegrasyonu'),
        _bulletPoint('KVKK uyumlu veri işleme'),
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
            child:
                const Icon(Icons.check, color: Colors.white, size: 13),
          ),
          const SizedBox(width: 10),
          Text(text,
              style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF1A2340))),
        ],
      ),
    );
  }

  Widget _visual() {
    return Container(
      height: 380,
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
            top: 40,
            left: 40,
            child: _infoChip(Icons.verified_user, 'KVKK Uyumlu', Colors.teal),
          ),
          Positioned(
            bottom: 40,
            right: 40,
            child: _infoChip(
                Icons.cloud_done, 'Bulut Yedekleme', Colors.blue),
          ),
          const Icon(Icons.accessibility_new,
              size: 140, color: Colors.teal),
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
              offset: const Offset(0, 3))
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(width: 6),
          Text(label,
              style: const TextStyle(
                  fontWeight: FontWeight.w600, fontSize: 13)),
        ],
      ),
    );
  }
}

// ── CTA ──────────────────────────────────────────────────────────────────────

class _CtaSection extends StatelessWidget {
  final VoidCallback onGetStarted;
  final VoidCallback onLogin;
  const _CtaSection({required this.onGetStarted, required this.onLogin});

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
            'Klinik Yönetiminizi Dijitalleştirin',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white,
              fontSize: 34,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 14),
          Text(
            'Hemen ücretsiz hesap oluşturun ve OptiYou\'nun tüm özelliklerini deneyin.',
            textAlign: TextAlign.center,
            style: TextStyle(
                color: Colors.white.withOpacity(0.85), fontSize: 16),
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
                  padding: const EdgeInsets.symmetric(
                      horizontal: 32, vertical: 16),
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                ),
                child: const Text('Ücretsiz Kaydol',
                    style: TextStyle(
                        fontSize: 16, fontWeight: FontWeight.bold)),
              ),
              const SizedBox(width: 14),
              OutlinedButton(
                onPressed: onLogin,
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.white,
                  side:
                      BorderSide(color: Colors.white.withOpacity(0.6)),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 28, vertical: 16),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                ),
                child: const Text('Giriş Yap',
                    style: TextStyle(fontSize: 16)),
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
      padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 36),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: Colors.teal,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.accessibility_new,
                    color: Colors.white, size: 18),
              ),
              const SizedBox(width: 10),
              const Text('OptiYou',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            'Ayak sağlığında dijital dönüşüm.',
            style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 13),
          ),
          const SizedBox(height: 20),
          Divider(color: Colors.white.withOpacity(0.1)),
          const SizedBox(height: 14),
          Text(
            '© 2026 OptiYou. Tüm hakları saklıdır.',
            style: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 12),
          ),
        ],
      ),
    );
  }
}
