import 'package:flutter/material.dart';
import 'package:oy_site/data/repositories/supabase_patient_repository.dart';
import 'package:oy_site/models/app_user.dart';
import 'package:oy_site/models/patient.dart';
import 'package:oy_site/screens/dashboard/patient_create_screen.dart';
import 'package:oy_site/screens/dashboard/patient_detail_screen.dart';

class PatientListScreen extends StatefulWidget {
  final AppUser currentUser;
  final dynamic pressureRepository;

  const PatientListScreen({
    super.key,
    required this.currentUser,
    required this.pressureRepository,
  });

  @override
  State<PatientListScreen> createState() => _PatientListScreenState();
}

class _PatientListScreenState extends State<PatientListScreen> {
  final SupabasePatientRepository _patientRepository =
      SupabasePatientRepository();

  final TextEditingController _searchController = TextEditingController();

  List<Patient> _allPatients = [];
  List<Patient> _filteredPatients = [];

  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadPatients();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadPatients() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final expertUserId = widget.currentUser.userId;

      if (expertUserId == null) {
        throw Exception('Uzman kullanıcı ID bulunamadı.');
      }

      final patients = await _patientRepository.getPatientsByExpert(
        expertUserId: expertUserId,
      );

      if (!mounted) return;

      setState(() {
        _allPatients = patients;
        _filteredPatients = patients;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _errorMessage = 'Kullanıcı listesi yüklenirken hata oluştu: $e';
        _isLoading = false;
      });
    }
  }

  void _filterPatients(String query) {
    final q = query.trim().toLowerCase();

    setState(() {
      if (q.isEmpty) {
        _filteredPatients = _allPatients;
        return;
      }

      _filteredPatients = _allPatients.where((patient) {
        return patient.fullName.toLowerCase().contains(q) ||
            patient.patientCode.toLowerCase().contains(q) ||
            (patient.email ?? '').toLowerCase().contains(q) ||
            (patient.phone ?? '').toLowerCase().contains(q);
      }).toList();
    });
  }

  String _formatBirthDate(DateTime? date) {
    if (date == null) return 'Doğum tarihi yok';
    return '${date.day.toString().padLeft(2, '0')}.'
        '${date.month.toString().padLeft(2, '0')}.'
        '${date.year}';
  }

  Future<void> _openCreatePatientScreen() async {
    final newPatient = await Navigator.push<Patient>(
      context,
      MaterialPageRoute(
        builder: (_) => PatientCreateScreen(
          currentUser: widget.currentUser,
        ),
      ),
    );

    if (newPatient == null || !mounted) return;

    await _loadPatients();

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${newPatient.fullName} Kullanıcı kaydı oluşturuldu.'),
      ),
    );
  }

  void _openPatientDetail(Patient patient) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PatientDetailScreen(
          currentUser: widget.currentUser,
          patient: patient,
          pressureRepository: widget.pressureRepository,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Kullanıcı Listesi'),
        backgroundColor: Colors.teal,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Hoş geldin, ${widget.currentUser.displayName}',
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Kayıtlı Kullanıcıları buradan görüntüleyebilir ve arayabilirsin.',
              style: TextStyle(
                color: Colors.grey[700],
              ),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _searchController,
              onChanged: _filterPatients,
              decoration: InputDecoration(
                hintText: 'Kullanıcı adı, kodu, e-posta veya telefon ile ara',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchController.text.trim().isEmpty
                    ? null
                    : IconButton(
                        onPressed: () {
                          _searchController.clear();
                          _filterPatients('');
                        },
                        icon: const Icon(Icons.clear),
                      ),
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
        onPressed: _openCreatePatientScreen,
        backgroundColor: Colors.teal,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text(
          'Yeni Kullanıcı',
          style: TextStyle(color: Colors.white),
        ),
      ),
    );
  }

  Widget _buildContent() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (_errorMessage != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              _errorMessage!,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.red),
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: _loadPatients,
              icon: const Icon(Icons.refresh),
              label: const Text('Tekrar Dene'),
            ),
          ],
        ),
      );
    }

    if (_filteredPatients.isEmpty) {
      final hasSearch = _searchController.text.trim().isNotEmpty;

      return Center(
        child: Text(
          hasSearch
              ? 'Arama kriterine uygun Kullanıcı bulunamadı.'
              : 'Kayıtlı Kullanıcı bulunamadı.',
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadPatients,
      child: ListView.separated(
        itemCount: _filteredPatients.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          final patient = _filteredPatients[index];

          return InkWell(
            onTap: () => _openPatientDetail(patient),
            borderRadius: BorderRadius.circular(16),
            child: Container(
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
                    backgroundColor: Colors.teal.withOpacity(0.12),
                    child: const Icon(
                      Icons.person,
                      color: Colors.teal,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          patient.fullName,
                          style: const TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Kullanıcı Kodu: ${patient.patientCode}',
                          style: TextStyle(color: Colors.grey[700]),
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          runSpacing: 6,
                          spacing: 12,
                          children: [
                            _buildInfoChip(Icons.email, patient.displayEmail),
                            _buildInfoChip(Icons.phone, patient.displayPhone),
                            _buildInfoChip(
                              Icons.cake_outlined,
                              _formatBirthDate(patient.birthDate),
                            ),
                            _buildInfoChip(Icons.wc, patient.displayGender),
                          ],
                        ),
                        if ((patient.notes ?? '').trim().isNotEmpty) ...[
                          const SizedBox(height: 10),
                          Text(
                            'Not: ${patient.notes!}',
                            style: TextStyle(
                              color: Colors.grey[800],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  IconButton(
                    onPressed: () => _openPatientDetail(patient),
                    icon: const Icon(Icons.arrow_forward_ios),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildInfoChip(IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: Colors.teal),
          const SizedBox(width: 6),
          Text(
            text,
            style: const TextStyle(fontSize: 13),
          ),
        ],
      ),
    );
  }
}