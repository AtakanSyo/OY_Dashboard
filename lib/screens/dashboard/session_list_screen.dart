import 'package:flutter/material.dart';
import 'package:oy_site/data/mock/mock_measurement_session_repository.dart';
import 'package:oy_site/models/app_user.dart';
import 'package:oy_site/models/measurement_session.dart';
import 'package:oy_site/models/patient.dart';
import 'package:oy_site/screens/dashboard/create_session_screen.dart';
import 'package:oy_site/screens/dashboard/session_detail_screen.dart';

class SessionListScreen extends StatefulWidget {
  final AppUser currentUser;

  const SessionListScreen({
    super.key,
    required this.currentUser,
  });

  @override
  State<SessionListScreen> createState() => _SessionListScreenState();
}

class _SessionListScreenState extends State<SessionListScreen> {
  final MockMeasurementSessionRepository _sessionRepository =
      MockMeasurementSessionRepository();
  final TextEditingController _searchController = TextEditingController();

  List<MeasurementSession> _allSessions = [];
  List<MeasurementSession> _filteredSessions = [];

  bool _isLoading = true;
  String? _errorMessage;

  final List<Patient> _mockPatients = const [
    Patient(
      patientId: 1,
      clinicId: 101,
      createdByUserId: 1,
      patientCode: 'PT-0001',
      firstName: 'Ayşe',
      lastName: 'Demir',
      email: 'ayse.demir@example.com',
      gender: 'female',
      phone: '+90 555 111 11 11',
    ),
    Patient(
      patientId: 2,
      clinicId: 101,
      createdByUserId: 1,
      patientCode: 'PT-0002',
      firstName: 'Mehmet',
      lastName: 'Kaya',
      email: 'mehmet.kaya@example.com',
      gender: 'male',
      phone: '+90 555 222 22 22',
    ),
    Patient(
      patientId: 3,
      clinicId: 101,
      createdByUserId: 1,
      patientCode: 'PT-0003',
      firstName: 'Elif',
      lastName: 'Yıldız',
      gender: 'female',
    ),
  ];

  @override
  void initState() {
    super.initState();
    _loadSessions();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadSessions() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final sessions = await _sessionRepository.getSessions();

      if (!mounted) return;

      setState(() {
        _allSessions = sessions;
        _filteredSessions = sessions;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _errorMessage = 'Oturumlar yüklenirken hata oluştu: $e';
        _isLoading = false;
      });
    }
  }

  void _filterSessions(String query) {
    final q = query.trim().toLowerCase();

    setState(() {
      if (q.isEmpty) {
        _filteredSessions = _allSessions;
        return;
      }

      _filteredSessions = _allSessions.where((session) {
        return session.sessionCode.toLowerCase().contains(q) ||
            session.effectiveStatus.toLowerCase().contains(q) ||
            (session.sessionTime ?? '').toLowerCase().contains(q);
      }).toList();
    });
  }

  String _formatDate(DateTime date) {
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

Future<void> _openCreateSessionScreen() async {
  final newSession = await Navigator.push<MeasurementSession>(
    context,
    MaterialPageRoute(
      builder: (_) => CreateSessionScreen(
        currentUser: widget.currentUser,
        patients: _mockPatients,
      ),
    ),
  );

  if (newSession != null && mounted) {
    setState(() {
      _allSessions = [newSession, ..._allSessions];
      _filteredSessions = [newSession, ..._filteredSessions];
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${newSession.sessionCode} oluşturuldu.'),
      ),
    );

    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => SessionDetailScreen(
          currentUser: widget.currentUser,
          session: newSession,
        ),
      ),
    );
  }
}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ölçüm Oturumları'),
        backgroundColor: Colors.teal,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Ölçüm sürecini buradan yönetebilirsin',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              'Taslak, devam eden ve tamamlanan oturumlar bu ekranda listelenir.',
              style: TextStyle(color: Colors.grey[700]),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _searchController,
              onChanged: _filterSessions,
              decoration: InputDecoration(
                hintText: 'Oturum kodu, durum veya saat ile ara',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: _buildContent(),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openCreateSessionScreen,
        backgroundColor: Colors.teal,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text(
          'Yeni Oturum',
          style: TextStyle(color: Colors.white),
        ),
      ),
    );
  }

  Widget _buildContent() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorMessage != null) {
      return Center(
        child: Text(
          _errorMessage!,
          style: const TextStyle(color: Colors.red),
        ),
      );
    }

    if (_filteredSessions.isEmpty) {
      return const Center(
        child: Text('Kayıtlı ölçüm oturumu bulunamadı.'),
      );
    }

    return ListView.separated(
      itemCount: _filteredSessions.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final session = _filteredSessions[index];
        final statusColor = _statusColor(session.effectiveStatus);

        return Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: const [
              BoxShadow(
                color: Colors.black12,
                blurRadius: 8,
              ),
            ],
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                radius: 26,
                backgroundColor: statusColor.withOpacity(0.12),
                child: Icon(
                  Icons.assignment,
                  color: statusColor,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Wrap(
                      spacing: 10,
                      runSpacing: 8,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Text(
                          session.sessionCode,
                          style: const TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: statusColor.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Text(
                            _statusLabel(session.effectiveStatus),
                            style: TextStyle(
                              color: statusColor,
                              fontWeight: FontWeight.w600,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Tarih: ${_formatDate(session.sessionDate)}'
                      '${session.sessionTime != null ? ' • Saat: ${session.sessionTime}' : ''}',
                      style: TextStyle(color: Colors.grey[700]),
                    ),
                    const SizedBox(height: 10),
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
                  ],
                ),
              ),
              const SizedBox(width: 12),
              IconButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => SessionDetailScreen(
                        currentUser: widget.currentUser,
                        session: session,
                      ),
                    ),
                  );
                },
                icon: const Icon(Icons.arrow_forward_ios),
              ),
            ],
          ),
        );
      },
    );
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
}