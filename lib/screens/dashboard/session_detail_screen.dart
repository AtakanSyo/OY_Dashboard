import 'package:flutter/material.dart';
import 'package:oy_site/models/app_user.dart';
import 'package:oy_site/models/measurement_session.dart';
import 'package:oy_site/screens/dashboard/orthotic_design_form_screen.dart';
import 'package:oy_site/screens/dashboard/anthropometric_clinical_info_screen.dart';

class SessionDetailScreen extends StatelessWidget {
  final AppUser currentUser;
  final MeasurementSession session;

  const SessionDetailScreen({
    super.key,
    required this.currentUser,
    required this.session,
  });

  String _formatDate(DateTime? date) {
    if (date == null) return '—';
    return '${date.day.toString().padLeft(2, '0')}.'
        '${date.month.toString().padLeft(2, '0')}.'
        '${date.year}';
  }

  Color _statusColor(String status) {
    switch (status) {
      case SessionStatuses.completed:
        return Colors.green;
      case SessionStatuses.inProgress:
        return Colors.orange;
      case SessionStatuses.draft:
        return Colors.blueGrey;
      case SessionStatuses.cancelled:
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  String _statusLabel(String status) {
    switch (status) {
      case SessionStatuses.completed:
        return 'Tamamlandı';
      case SessionStatuses.inProgress:
        return 'Devam Ediyor';
      case SessionStatuses.draft:
        return 'Taslak';
      case SessionStatuses.cancelled:
        return 'İptal';
      default:
        return status;
    }
  }

  Widget _buildTag(String text, bool active) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: active ? Colors.green.withOpacity(0.12) : Colors.grey.shade200,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: active ? Colors.green.shade700 : Colors.grey.shade700,
          fontWeight: FontWeight.w500,
          fontSize: 12,
        ),
      ),
    );
  }

  Widget _buildSectionCard({
    required String title,
    required Widget child,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: const [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 8,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 19,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }

  Widget _buildKeyValueRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
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
              style: const TextStyle(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final statusColor = _statusColor(session.status);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Oturum Detayı'),
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
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(22),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(18),
                    boxShadow: const [
                      BoxShadow(
                        color: Colors.black12,
                        blurRadius: 8,
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 34,
                        backgroundColor: statusColor.withOpacity(0.12),
                        child: Icon(
                          Icons.fact_check,
                          size: 36,
                          color: statusColor,
                        ),
                      ),
                      const SizedBox(width: 18),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              session.sessionCode,
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'Oturum Tarihi: ${_formatDate(session.sessionDate)}'
                              '${session.sessionTime != null ? ' • Saat: ${session.sessionTime}' : ''}',
                              style: TextStyle(color: Colors.grey[700]),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'İşlem yapan kullanıcı: ${currentUser.displayName}',
                              style: TextStyle(color: Colors.grey[600]),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: statusColor.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          _statusLabel(session.status),
                          style: TextStyle(
                            color: statusColor,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      flex: 2,
                      child: Column(
                        children: [
                          _buildSectionCard(
                            title: 'Temel Bilgiler',
                            child: Column(
                              children: [
                                _buildKeyValueRow(
                                  'Session ID',
                                  session.sessionId?.toString() ?? '—',
                                ),
                                _buildKeyValueRow(
                                  'Clinic ID',
                                  session.clinicId.toString(),
                                ),
                                _buildKeyValueRow(
                                  'Patient ID',
                                  session.patientId.toString(),
                                ),
                                _buildKeyValueRow(
                                  'Expert User ID',
                                  session.expertUserId.toString(),
                                ),
                                _buildKeyValueRow(
                                  'Assigned OptiYou User ID',
                                  session.assignedOptityouUserId?.toString() ?? '—',
                                ),
                                _buildKeyValueRow(
                                  'Oluşturulma',
                                  _formatDate(session.createdAt),
                                ),
                                _buildKeyValueRow(
                                  'Güncellenme',
                                  _formatDate(session.updatedAt),
                                ),
                                _buildKeyValueRow(
                                  'Tamamlanma',
                                  _formatDate(session.completedAt),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),
                          _buildSectionCard(
                            title: 'İş Akışı Durumu',
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Wrap(
                                  spacing: 8,
                                  runSpacing: 8,
                                  children: [
                                    _buildTag(
                                      session.has3dScan ? '3D Scan Var' : '3D Scan Yok',
                                      session.has3dScan,
                                    ),
                                    _buildTag(
                                      session.hasPlantarCsv
                                          ? 'Plantar Veri Var'
                                          : 'Plantar Veri Yok',
                                      session.hasPlantarCsv,
                                    ),
                                    _buildTag(
                                      session.hasInsolePhoto
                                          ? 'Fotoğraf Var'
                                          : 'Fotoğraf Yok',
                                      session.hasInsolePhoto,
                                    ),
                                    _buildTag(
                                      session.orderCreated
                                          ? 'Sipariş Oluşturuldu'
                                          : 'Sipariş Yok',
                                      session.orderCreated,
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  'Bu alan daha sonra scan_3d_uploads, plantar_pressure_files, '
                                  'insole_reference_photos ve orders tablolarıyla detaylı bağlanacak.',
                                  style: TextStyle(
                                    color: Colors.grey[600],
                                    height: 1.4,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(width: 24),

                    Expanded(
                      flex: 3,
                      child: Column(
                        children: [
                          _buildSectionCard(
                            title: 'Modül Geçişleri',
                            child: Column(
                              children: [
                                _buildActionButton(
                                  context,
                                  icon: Icons.monitor_weight,
                                  title: 'Klinik / Antropometrik Bilgiler',
                                  subtitle: 'Boy, kilo, BMI, şikayet, tanı ve patoloji bilgileri.',
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => AnthropometricClinicalInfoScreen(
                                          currentUser: currentUser,
                                          session: session,
                                        ),
                                      ),
                                    );
                                  },
                                ),
                                _buildActionButton(
                                  context,
                                  icon: Icons.analytics,
                                  title: 'Analiz Sonuçlarını Gör',
                                  subtitle: '3D analiz ve plantar özet ekranına geçiş.',
                                  onTap: () {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text('Analiz detay bağlantısını sonra ekleyeceğiz.'),
                                      ),
                                    );
                                  },
                                ),
                                const SizedBox(height: 12),
                                _buildActionButton(
                                  context,
                                  icon: Icons.speed,
                                  title: 'Basınç Verisini Aç',
                                  subtitle: 'Plantar basınç ölçüm/veri ekranına geçiş.',
                                  onTap: () {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text('Basınç veri bağlantısını sonra ekleyeceğiz.'),
                                      ),
                                    );
                                  },
                                ),
                                const SizedBox(height: 12),
                                _buildActionButton(
                                  context,
                                  icon: Icons.photo_camera_back,
                                  title: 'Referans Fotoğraflar',
                                  subtitle: 'İç tabanlık referans fotoğraflarını görüntüle.',
                                  onTap: () {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text('Referans fotoğraf bağlantısını sonra ekleyeceğiz.'),
                                      ),
                                    );
                                  },
                                ),
                                const SizedBox(height: 12),
                                _buildActionButton(
                                  context,
                                  icon: Icons.design_services,
                                  title: 'Tasarım Formu',
                                  subtitle: 'Orthotic design form ekranına geçiş.',
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => OrthoticDesignFormScreen(
                                          currentUser: currentUser,
                                          session: session,
                                        ),
                                      ),
                                    );
                                  },
                                ),
                                const SizedBox(height: 12),
                                _buildActionButton(
                                  context,
                                  icon: Icons.shopping_bag,
                                  title: 'Siparişe Dönüştür',
                                  subtitle: 'Bu oturumdan sipariş oluşturma akışı.',
                                  onTap: () {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text('Sipariş oluşturma akışını sonra ekleyeceğiz.'),
                                      ),
                                    );
                                  },
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),
                          _buildSectionCard(
                            title: 'Oturum Özeti',
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Bu ekran measurement session merkezli iş akışının ana detay ekranıdır. '
                                  'Sonraki aşamada buraya:',
                                  style: TextStyle(
                                    color: Colors.grey[700],
                                    height: 1.5,
                                  ),
                                ),
                                const SizedBox(height: 12),
                                const Text('• antropometrik ve klinik bilgiler'),
                                const Text('• 3D scan upload / result detayları'),
                                const Text('• plantar pressure summary'),
                                const Text('• insole reference photo durumu'),
                                const Text('• orthotic design form'),
                                const Text('• sipariş ve komisyon bağlantıları'),
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

  Widget _buildActionButton(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.grey.shade50,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: Row(
          children: [
            Icon(icon, color: Colors.teal, size: 30),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
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