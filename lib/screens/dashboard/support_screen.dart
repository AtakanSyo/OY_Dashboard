import 'package:flutter/material.dart';
import 'package:oy_site/models/app_user.dart';

class SupportScreen extends StatelessWidget {
  final AppUser currentUser;

  const SupportScreen({
    super.key,
    required this.currentUser,
  });

  String _getWelcomeText() {
    if (currentUser.isExpert) {
      return 'Uzman paneli, ölçüm süreçleri ve sipariş yönetimi hakkında destek alabilirsiniz.';
    }

    if (currentUser.isCustomer) {
      return 'Siparişleriniz, ürünleriniz ve kullanım süreci hakkında destek alabilirsiniz.';
    }

    if (currentUser.isOptiYouTeam) {
      return 'Operasyon, hasta akışı ve sistem yönetimi için destek seçeneklerini kullanabilirsiniz.';
    }

    return 'Yardıma mı ihtiyacınız var? Aşağıdaki seçeneklerden birini seçebilirsiniz.';
  }

  List<_SupportItem> _getSupportItems() {
    if (currentUser.isExpert) {
      return const [
        _SupportItem(
          icon: Icons.groups,
          title: 'Hasta ve Oturum Yardımı',
          subtitle: 'Hasta kayıtları ve ölçüm oturumlarıyla ilgili destek alın.',
        ),
        _SupportItem(
          icon: Icons.analytics,
          title: 'Analiz ve Ölçüm Desteği',
          subtitle: '3D tarama, plantar basınç ve analiz ekranları hakkında yardım alın.',
        ),
        _SupportItem(
          icon: Icons.shopping_bag,
          title: 'Sipariş Süreci',
          subtitle: 'Sipariş oluşturma ve üretim takibiyle ilgili yardım alın.',
        ),
        _SupportItem(
          icon: Icons.bug_report,
          title: 'Sorun Bildir',
          subtitle: 'Yaşadığınız teknik problemi detaylı şekilde iletin.',
        ),
      ];
    }

    if (currentUser.isCustomer) {
      return const [
        _SupportItem(
          icon: Icons.shopping_bag,
          title: 'Sipariş Desteği',
          subtitle: 'Sipariş durumu, teslimat ve süreç bilgilerini inceleyin.',
        ),
        _SupportItem(
          icon: Icons.storefront,
          title: 'Ürün ve Kullanım Yardımı',
          subtitle: 'Ürün seçimi ve kullanım süreciyle ilgili destek alın.',
        ),
        _SupportItem(
          icon: Icons.question_answer,
          title: 'Sık Sorulan Sorular',
          subtitle: 'En çok sorulan soruların cevaplarına göz atın.',
        ),
        _SupportItem(
          icon: Icons.email,
          title: 'Bize Ulaş',
          subtitle: 'Destek ekibine doğrudan ulaşın.',
        ),
      ];
    }

    if (currentUser.isOptiYouTeam) {
      return const [
        _SupportItem(
          icon: Icons.fact_check,
          title: 'Operasyon Takibi',
          subtitle: 'Oturum, analiz ve sipariş akışları için destek alın.',
        ),
        _SupportItem(
          icon: Icons.support_agent,
          title: 'Klinik ve Uzman Desteği',
          subtitle: 'Klinik kullanıcıları ve uzman süreçleriyle ilgili yardım alın.',
        ),
        _SupportItem(
          icon: Icons.bug_report,
          title: 'Sistem Sorunları',
          subtitle: 'Teknik hataları ve yönetimsel problemleri bildirin.',
        ),
        _SupportItem(
          icon: Icons.email,
          title: 'İç İletişim',
          subtitle: 'Operasyon ve ürün ekibiyle iletişime geçin.',
        ),
      ];
    }

    return const [
      _SupportItem(
        icon: Icons.question_answer,
        title: 'Sık Sorulan Sorular',
        subtitle: 'Yardım içeriklerini inceleyin.',
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final supportItems = _getSupportItems();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Destek Merkezi'),
        backgroundColor: Colors.teal,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 950),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const Icon(
                  Icons.support_agent,
                  size: 80,
                  color: Colors.indigo,
                ),
                const SizedBox(height: 20),
                Text(
                  'Merhaba, ${currentUser.displayName}',
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  _getWelcomeText(),
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.black54,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  '${currentUser.roleName}${currentUser.clinicName != null && currentUser.clinicName!.trim().isNotEmpty ? ' • ${currentUser.clinicName}' : ''}',
                  style: TextStyle(
                    color: Colors.teal.shade700,
                    fontWeight: FontWeight.w600,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 30),
                ...supportItems.map(
                  (item) => Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: _buildSupportCard(
                      context,
                      icon: item.icon,
                      title: item.title,
                      subtitle: item.subtitle,
                      onTap: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              '"${item.title}" ekranını sonra bağlayacağız.',
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.teal.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    children: [
                      const Text(
                        'İletişim',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'support@oy.com',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.teal,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Kayıtlı e-posta: ${currentUser.email}',
                        style: const TextStyle(color: Colors.black54),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                const Text(
                  'En kısa sürede geri dönüş yapacağız.',
                  style: TextStyle(color: Colors.black54),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSupportCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: const [
            BoxShadow(
              blurRadius: 6,
              offset: Offset(0, 2),
              color: Colors.black12,
            ),
          ],
        ),
        child: Row(
          children: [
            Icon(icon, size: 40, color: Colors.teal),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: const TextStyle(color: Colors.black54),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.arrow_forward_ios,
              size: 16,
              color: Colors.black38,
            ),
          ],
        ),
      ),
    );
  }
}

class _SupportItem {
  final IconData icon;
  final String title;
  final String subtitle;

  const _SupportItem({
    required this.icon,
    required this.title,
    required this.subtitle,
  });
}