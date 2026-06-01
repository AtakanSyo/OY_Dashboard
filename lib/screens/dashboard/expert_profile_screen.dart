import 'package:flutter/material.dart';
import 'package:oy_site/models/app_user.dart';

class ExpertProfileScreen extends StatelessWidget {
  final AppUser currentUser;

  const ExpertProfileScreen({
    super.key,
    required this.currentUser,
  });

  @override
  Widget build(BuildContext context) {
    final user = currentUser;

    return Scaffold(
      backgroundColor: const Color(0xFFF7F9FB),
      appBar: AppBar(
        title: const Text('Uzman Profili'),
        backgroundColor: Colors.teal,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1100),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _ProfileHeaderCard(
                  title: user.displayName,
                  subtitle: user.title ?? 'Uzman Kullanıcı',
                  email: user.email,
                ),
                const SizedBox(height: 18),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      flex: 2,
                      child: _SectionCard(
                        title: 'Uzman Bilgileri',
                        child: Column(
                          children: [
                            _InfoRow(label: 'Ad Soyad', value: user.displayName),
                            _InfoRow(label: 'E-posta', value: user.email),
                            _InfoRow(label: 'Telefon', value: user.phone ?? '—'),
                            _InfoRow(label: 'Unvan', value: user.title ?? '—'),
                            _InfoRow(label: 'Rol', value: user.roleName ?? 'Uzman'),
                            _InfoRow(
                              label: 'Klinik',
                              value: user.clinicName ?? '—',
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 18),
                    Expanded(
                      flex: 3,
                      child: Column(
                        children: const [
                          _SectionCard(
                            title: 'Uzman Dashboard Özeti',
                            child: Row(
                              children: [
                                Expanded(
                                  child: _MiniStatTile(
                                    title: 'Toplam Kullanıcı',
                                    value: '128',
                                    icon: Icons.people_alt_outlined,
                                  ),
                                ),
                                SizedBox(width: 12),
                                Expanded(
                                  child: _MiniStatTile(
                                    title: 'Bu Ay Oturum',
                                    value: '34',
                                    icon: Icons.event_note_outlined,
                                  ),
                                ),
                                SizedBox(width: 12),
                                Expanded(
                                  child: _MiniStatTile(
                                    title: 'Bekleyen Tasarım',
                                    value: '7',
                                    icon: Icons.design_services_outlined,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          SizedBox(height: 18),
                          _SectionCard(
                            title: 'Kısa Notlar',
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('• En çok düz taban eğilimli vaka görülüyor.'),
                                SizedBox(height: 8),
                                Text('• Basınç ölçümü tamamlanan oturumlarda öneri kalitesi artıyor.'),
                                SizedBox(height: 8),
                                Text('• Siparişe dönüşen oturum oranı takip edilebilir.'),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ProfileHeaderCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final String email;

  const _ProfileHeaderCard({
    required this.title,
    required this.subtitle,
    required this.email,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: const [
          BoxShadow(color: Colors.black12, blurRadius: 8),
        ],
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 34,
            backgroundColor: Colors.teal.withOpacity(0.12),
            child: const Icon(
              Icons.medical_services_outlined,
              size: 34,
              color: Colors.teal,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 23,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  subtitle,
                  style: TextStyle(color: Colors.grey[700]),
                ),
                const SizedBox(height: 4),
                Text(
                  email,
                  style: TextStyle(color: Colors.grey[600]),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  final String title;
  final Widget child;

  const _SectionCard({
    required this.title,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(color: Colors.black12, blurRadius: 8),
        ],
      ),
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
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;

  const _InfoRow({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: TextStyle(color: Colors.grey[700]),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}

class _MiniStatTile extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;

  const _MiniStatTile({
    required this.title,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.teal.withOpacity(0.06),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        children: [
          Icon(icon, color: Colors.teal),
          const SizedBox(height: 8),
          Text(
            title,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.grey[700],
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
          ),
        ],
      ),
    );
  }
}