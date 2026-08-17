import 'package:flutter/material.dart';
import 'package:oy_site/widgets/language_selector.dart';
import 'package:oy_site/data/repositories/supabase_patient_consent_repository.dart';
import 'package:oy_site/legal/legal_document_registry.dart';
import 'package:oy_site/models/patient_consent_request_model.dart';

enum _ConsentViewState {
  loading,
  invalid,
  expired,
  alreadyAccepted,
  pending,
  accepted,
}

class LegalConsentScreen extends StatefulWidget {
  final String token;

  const LegalConsentScreen({super.key, required this.token});

  @override
  State<LegalConsentScreen> createState() => _LegalConsentScreenState();
}

class _LegalConsentScreenState extends State<LegalConsentScreen> {
  final SupabasePatientConsentRepository _repository =
      SupabasePatientConsentRepository();

  _ConsentViewState _viewState = _ConsentViewState.loading;
  PatientConsentRequestModel? _request;
  bool _isAccepting = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadRequest();
  }

  Future<void> _loadRequest() async {
    setState(() {
      _viewState = _ConsentViewState.loading;
      _errorMessage = null;
    });

    try {
      final request = await _repository.getByToken(token: widget.token);

      if (!mounted) return;

      if (request == null) {
        setState(() => _viewState = _ConsentViewState.invalid);
        return;
      }

      if (request.isAccepted) {
        setState(() {
          _request = request;
          _viewState = _ConsentViewState.alreadyAccepted;
        });
        return;
      }

      if (request.isExpired) {
        setState(() {
          _request = request;
          _viewState = _ConsentViewState.expired;
        });
        return;
      }

      setState(() {
        _request = request;
        _viewState = _ConsentViewState.pending;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _viewState = _ConsentViewState.invalid;
        _errorMessage = e.toString();
      });
    }
  }

  Future<void> _accept() async {
    setState(() => _isAccepting = true);

    try {
      final updated = await _repository.acceptByToken(token: widget.token);

      if (!mounted) return;

      setState(() {
        _request = updated;
        _viewState = _ConsentViewState.accepted;
        _isAccepting = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() => _isAccepting = false);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Onay kaydedilemedi: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        actions: const [LanguageSelector(), SizedBox(width: 12)],
        title: const Text('KVKK Onayı'),
        backgroundColor: Colors.teal,
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 760),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: _buildContent(),
          ),
        ),
      ),
    );
  }

  Widget _buildContent() {
    switch (_viewState) {
      case _ConsentViewState.loading:
        return const Center(child: CircularProgressIndicator());
      case _ConsentViewState.invalid:
        return _buildMessageCard(
          icon: Icons.error_outline,
          iconColor: Colors.red,
          title: 'Bağlantı Geçersiz',
          message:
              _errorMessage ??
              'Bu onay bağlantısı bulunamadı. Bağlantının doğru kopyalandığından emin olun.',
        );
      case _ConsentViewState.expired:
        return _buildMessageCard(
          icon: Icons.schedule_outlined,
          iconColor: Colors.orange,
          title: 'Bağlantının Süresi Dolmuş',
          message:
              'Bu onay bağlantısının süresi dolmuş. Yeni bir bağlantı için uzmanınızla iletişime geçin.',
        );
      case _ConsentViewState.alreadyAccepted:
        return _buildMessageCard(
          icon: Icons.check_circle_outline,
          iconColor: Colors.green,
          title: 'Zaten Onaylanmış',
          message: 'Bu KVKK onayını daha önce vermiştiniz. Teşekkür ederiz.',
        );
      case _ConsentViewState.accepted:
        return _buildMessageCard(
          icon: Icons.check_circle_outline,
          iconColor: Colors.green,
          title: 'Onayınız Kaydedildi',
          message:
              'KVKK Aydınlatma Metni onayınız kaydedildi. Teşekkür ederiz.',
        );
      case _ConsentViewState.pending:
        return _buildPendingCard();
    }
  }

  Widget _buildMessageCard({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String message,
  }) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: iconColor, size: 48),
            const SizedBox(height: 16),
            Text(
              title,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              message,
              style: TextStyle(color: Colors.grey[700], height: 1.4),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPendingCard() {
    final document = LegalDocumentRegistry.findByCode(
      LegalDocumentCodes.aydinlatmaMetni,
    );
    final patientName = _request?.patientName?.trim();

    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              document?.title ?? 'Aydınlatma Metni',
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(
              (patientName != null && patientName.isNotEmpty)
                  ? '$patientName, kişisel verilerinizin işlenmesine ilişkin aşağıdaki metni onayınıza sunuyoruz.'
                  : 'Kişisel verilerinizin işlenmesine ilişkin aşağıdaki metni onayınıza sunuyoruz.',
              style: TextStyle(color: Colors.grey[700]),
            ),
            const SizedBox(height: 16),
            Container(
              constraints: const BoxConstraints(maxHeight: 420),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: SingleChildScrollView(
                child: SelectableText(
                  document?.content ?? 'Belge bulunamadı.',
                  style: const TextStyle(height: 1.5),
                ),
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isAccepting ? null : _accept,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.teal,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                child: _isAccepting
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : const Text(
                        'Onaylıyorum',
                        style: TextStyle(color: Colors.white, fontSize: 16),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
