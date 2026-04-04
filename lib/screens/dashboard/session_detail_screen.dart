import 'package:flutter/material.dart';
import 'package:oy_site/models/app_user.dart';
import 'package:oy_site/models/measurement_session.dart';
import 'package:oy_site/models/order_model.dart';
import 'package:oy_site/screens/dashboard/anthropometric_clinical_info_screen.dart';
import 'package:oy_site/screens/dashboard/insole_photo_upload_dialog.dart';
import 'package:oy_site/screens/dashboard/order_create_screen.dart';
import 'package:oy_site/screens/dashboard/orthotic_design_form_screen.dart';

class SessionDetailScreen extends StatefulWidget {
  final AppUser currentUser;
  final MeasurementSession session;

  const SessionDetailScreen({
    super.key,
    required this.currentUser,
    required this.session,
  });

  @override
  State<SessionDetailScreen> createState() => _SessionDetailScreenState();
}

class _SessionDetailScreenState extends State<SessionDetailScreen> {
  late MeasurementSession _currentSession;

  @override
  void initState() {
    super.initState();
    _currentSession = widget.session;
  }

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

  List<_SessionStepItem> _buildSessionSteps() {
    return [
      _SessionStepItem(
        icon: Icons.monitor_weight,
        title: 'Klinik / Antropometrik Bilgiler',
        subtitle: 'Boy, kilo, BMI, şikayet, tanı ve patoloji bilgileri',
        isCompleted: _currentSession.clinicalInfoCompleted,
        onTap: _openClinicalInfoScreen,
      ),
      _SessionStepItem(
        icon: Icons.view_in_ar,
        title: '3D Scan',
        subtitle: '3D tarama dosyaları ve analiz sonuçları',
        isCompleted: _currentSession.has3dScan,
        onTap: () {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('3D Scan modülünü daha sonra bağlayacağız.'),
            ),
          );
        },
      ),
      _SessionStepItem(
        icon: Icons.speed,
        title: 'Plantar Pressure',
        subtitle: 'Basınç verisi ve özet sonuçları',
        isCompleted: _currentSession.hasPlantarCsv,
        onTap: () {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Plantar Pressure modülünü daha sonra bağlayacağız.'),
            ),
          );
        },
      ),
      _SessionStepItem(
        icon: Icons.photo_camera_back,
        title: 'Referans Fotoğraf',
        subtitle: 'İç tabanlık / ayak referans görselleri',
        isCompleted: _currentSession.hasInsolePhoto,
        onTap: _openInsolePhotoUploadDialog,
      ),
      _SessionStepItem(
        icon: Icons.design_services,
        title: 'Tasarım Formu',
        subtitle: 'Ortez tasarım kararları ve uzman notları',
        isCompleted: _currentSession.designFormCompleted,
        onTap: _openDesignFormScreen,
      ),
      _SessionStepItem(
        icon: Icons.shopping_bag,
        title: 'Sipariş',
        subtitle: 'Bu oturumdan sipariş oluşturma akışı',
        isCompleted: _currentSession.orderCreated,
        onTap: _openOrderCreateScreen,
      ),
    ];
  }

  double _completionRatio() {
    final items = _buildSessionSteps();
    final completedCount = items.where((e) => e.isCompleted).length;
    return items.isEmpty ? 0 : completedCount / items.length;
  }

  Future<void> _openClinicalInfoScreen() async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => AnthropometricClinicalInfoScreen(
          currentUser: widget.currentUser,
          session: _currentSession,
        ),
      ),
    );

    if (result == true && mounted) {
      setState(() {
        final updated = _currentSession.copyWith(
          clinicalInfoCompleted: true,
          updatedAt: DateTime.now(),
        );

        _currentSession = updated.copyWith(
          completedAt: updated.allStepsCompleted
              ? DateTime.now()
              : updated.completedAt,
        );
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Klinik / antropometrik bilgiler tamamlandı.'),
        ),
      );
    }
  }

  Future<void> _openDesignFormScreen() async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => OrthoticDesignFormScreen(
          currentUser: widget.currentUser,
          session: _currentSession,
        ),
      ),
    );

    if (result == true && mounted) {
      setState(() {
        final updated = _currentSession.copyWith(
          designFormCompleted: true,
          updatedAt: DateTime.now(),
        );

        _currentSession = updated.copyWith(
          completedAt: updated.allStepsCompleted
              ? DateTime.now()
              : updated.completedAt,
        );
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Tasarım formu tamamlandı.'),
        ),
      );
    }
  }

  Future<void> _openOrderCreateScreen() async {
    if (!_currentSession.canCreateOrder) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Sipariş oluşturmadan önce önceki tüm adımlar tamamlanmalıdır.',
          ),
        ),
      );
      return;
    }

    final newOrder = await Navigator.push<OrderModel>(
      context,
      MaterialPageRoute(
        builder: (_) => OrderCreateScreen(
          currentUser: widget.currentUser,
          session: _currentSession,
        ),
      ),
    );

    if (newOrder != null && mounted) {
      setState(() {
        final updated = _currentSession.copyWith(
          orderCreated: true,
          updatedAt: DateTime.now(),
        );

        _currentSession = updated.copyWith(
          completedAt: updated.allStepsCompleted
              ? DateTime.now()
              : updated.completedAt,
        );
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${newOrder.orderNo} oluşturuldu.'),
        ),
      );
    }
  }

  Future<void> _openInsolePhotoUploadDialog() async {
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => const InsolePhotoUploadDialog(),
    );

    if (result == true && mounted) {
      setState(() {
        final updated = _currentSession.copyWith(
          hasInsolePhoto: true,
          updatedAt: DateTime.now(),
        );

        _currentSession = updated.copyWith(
          completedAt: updated.allStepsCompleted
              ? DateTime.now()
              : updated.completedAt,
        );
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('İç taban fotoğrafı yüklendi.'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final statusColor = _statusColor(_currentSession.effectiveStatus);
    final sessionSteps = _buildSessionSteps();
    final progress = _completionRatio();

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
                              _currentSession.sessionCode,
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'Oturum Tarihi: ${_formatDate(_currentSession.sessionDate)}'
                              '${_currentSession.sessionTime != null ? ' • Saat: ${_currentSession.sessionTime}' : ''}',
                              style: TextStyle(color: Colors.grey[700]),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'İşlem yapan kullanıcı: ${widget.currentUser.displayName}',
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
                          _statusLabel(_currentSession.effectiveStatus),
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
                      child: _buildSectionCard(
                        title: 'Temel Bilgiler',
                        child: Column(
                          children: [
                            _buildKeyValueRow(
                              'Session ID',
                              _currentSession.sessionId?.toString() ?? '—',
                            ),
                            _buildKeyValueRow(
                              'Clinic ID',
                              _currentSession.clinicId.toString(),
                            ),
                            _buildKeyValueRow(
                              'Patient ID',
                              _currentSession.patientId.toString(),
                            ),
                            _buildKeyValueRow(
                              'Expert User ID',
                              _currentSession.expertUserId.toString(),
                            ),
                            _buildKeyValueRow(
                              'Assigned OptiYou User ID',
                              _currentSession.assignedOptityouUserId?.toString() ?? '—',
                            ),
                            _buildKeyValueRow(
                              'Oluşturulma',
                              _formatDate(_currentSession.createdAt),
                            ),
                            _buildKeyValueRow(
                              'Güncellenme',
                              _formatDate(_currentSession.updatedAt),
                            ),
                            _buildKeyValueRow(
                              'Tamamlanma',
                              _formatDate(_currentSession.completedAt),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 24),
                    Expanded(
                      flex: 3,
                      child: _buildSectionCard(
                        title: 'Oturum Akışı',
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Tamamlanma Oranı: ${(progress * 100).toStringAsFixed(0)}%',
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 10),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(999),
                              child: LinearProgressIndicator(
                                value: progress,
                                minHeight: 10,
                                backgroundColor: Colors.grey.shade300,
                                color: Colors.teal,
                              ),
                            ),
                            const SizedBox(height: 22),
                            ...List.generate(sessionSteps.length, (index) {
                              final step = sessionSteps[index];
                              final isLast = index == sessionSteps.length - 1;
                              return _buildFlowStep(
                                step: step,
                                isLast: isLast,
                              );
                            }),
                          ],
                        ),
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

  Widget _buildFlowStep({
    required _SessionStepItem step,
    required bool isLast,
  }) {
    final Color activeColor = step.isCompleted ? Colors.green : Colors.orange;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 52,
          child: Column(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: activeColor.withOpacity(0.12),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: activeColor.withOpacity(0.4),
                  ),
                ),
                child: Icon(
                  step.isCompleted ? Icons.check : step.icon,
                  color: activeColor,
                  size: 20,
                ),
              ),
              if (!isLast)
                Container(
                  width: 3,
                  height: 110,
                  margin: const EdgeInsets.only(top: 2, bottom: 2),
                  decoration: BoxDecoration(
                    color: step.isCompleted
                        ? Colors.green.withOpacity(0.45)
                        : Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: InkWell(
              onTap: step.onTap,
              borderRadius: BorderRadius.circular(14),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: step.isCompleted
                        ? Colors.green.withOpacity(0.35)
                        : Colors.grey.shade300,
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            step.title,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            step.subtitle,
                            style: const TextStyle(color: Colors.black54),
                          ),
                          const SizedBox(height: 10),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: step.isCompleted
                                  ? Colors.green.withOpacity(0.12)
                                  : Colors.orange.withOpacity(0.12),
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: Text(
                              step.isCompleted ? 'Tamamlandı' : 'Bekliyor',
                              style: TextStyle(
                                color: step.isCompleted
                                    ? Colors.green.shade700
                                    : Colors.orange.shade700,
                                fontWeight: FontWeight.w600,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Icon(
                      Icons.arrow_forward_ios,
                      size: 16,
                      color: Colors.black38,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _SessionStepItem {
  final IconData icon;
  final String title;
  final String subtitle;
  final bool isCompleted;
  final VoidCallback onTap;

  const _SessionStepItem({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.isCompleted,
    required this.onTap,
  });
}