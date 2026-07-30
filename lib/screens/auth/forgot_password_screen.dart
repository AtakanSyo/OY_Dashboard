import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:oy_site/services/auth_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ForgotPasswordScreen extends StatefulWidget {
  final String initialEmail;

  const ForgotPasswordScreen({
    super.key,
    this.initialEmail = '',
  });

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final AuthService _authService = AuthService();
  late final TextEditingController _emailController;

  bool _isLoading = false;
  bool _isSent = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();

    _emailController = TextEditingController(
      text: widget.initialEmail,
    );
  }

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  String? _resolvePasswordResetRedirectTo() {
    // Flutter Web kullanıyorsan Supabase mail linki bu adrese döner.
    // Bu URL Supabase Dashboard > Authentication > URL Configuration
    // içindeki Redirect URLs listesinde tanımlı olmalı.
    if (kIsWeb) {
      final origin = Uri.base.origin;
      return '$origin/#/reset-password';
    }

    // Windows/macOS masaüstü veya mobil için deep link ayarı yapılmadıysa
    // null bırakıyoruz. Bu durumda Supabase, Site URL ayarını kullanır.
    return null;
  }

  bool _isValidEmail(String value) {
    final email = value.trim();

    if (email.isEmpty) return false;

    return RegExp(
      r'^[^\s@]+@[^\s@]+\.[^\s@]+$',
    ).hasMatch(email);
  }

  Future<void> _sendResetEmail() async {
    final email = _emailController.text.trim();

    if (!_isValidEmail(email)) {
      setState(() {
        _errorMessage = 'Lütfen geçerli bir e-posta adresi girin.';
        _isSent = false;
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _isSent = false;
    });

    try {
      await _authService.sendPasswordResetEmail(
        email: email,
        redirectTo: _resolvePasswordResetRedirectTo(),
      );

      if (!mounted) return;

      setState(() {
        _isSent = true;
        _errorMessage = null;
      });
    } on AuthException catch (e) {
      if (!mounted) return;

      setState(() {
        _errorMessage = _localizeAuthError(e.message);
        _isSent = false;
      });
    } catch (_) {
      if (!mounted) return;

      setState(() {
        _errorMessage =
            'Şifre sıfırlama bağlantısı gönderilemedi. Lütfen tekrar deneyin.';
        _isSent = false;
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  String _localizeAuthError(String message) {
    final lower = message.toLowerCase();

    if (lower.contains('email rate limit') ||
        lower.contains('rate limit') ||
        lower.contains('too many requests')) {
      return 'Çok fazla istek gönderildi. Lütfen bir süre bekleyip tekrar deneyin.';
    }

    if (lower.contains('invalid email')) {
      return 'E-posta adresi geçerli değil.';
    }

    return message;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Şifremi Unuttum'),
        foregroundColor: Colors.black87,
        backgroundColor: Colors.white,
        elevation: 0.6,
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Container(
            width: 430,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: Colors.grey.shade300),
              boxShadow: const [
                BoxShadow(
                  color: Colors.black12,
                  blurRadius: 10,
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircleAvatar(
                  radius: 34,
                  backgroundColor: Colors.teal.withOpacity(0.10),
                  child: Icon(
                    Icons.lock_reset_outlined,
                    color: Colors.teal.shade700,
                    size: 34,
                  ),
                ),
                const SizedBox(height: 18),
                const Text(
                  'Şifre Sıfırlama',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  'Hesabınıza bağlı e-posta adresini girin. Size şifrenizi yenilemeniz için bir bağlantı göndereceğiz.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.grey[700],
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 24),
                TextField(
                  controller: _emailController,
                  enabled: !_isLoading,
                  keyboardType: TextInputType.emailAddress,
                  decoration: InputDecoration(
                    labelText: 'E-posta',
                    hintText: 'ornek@eposta.com',
                    errorText: _errorMessage,
                    prefixIcon: const Icon(Icons.email_outlined),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onChanged: (_) {
                    if (_errorMessage != null || _isSent) {
                      setState(() {
                        _errorMessage = null;
                        _isSent = false;
                      });
                    }
                  },
                  onSubmitted: (_) {
                    if (!_isLoading) _sendResetEmail();
                  },
                ),
                if (_isSent) ...[
                  const SizedBox(height: 14),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.green.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: Colors.green.withOpacity(0.25),
                      ),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          Icons.check_circle_outline,
                          color: Colors.green.shade700,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Şifre sıfırlama bağlantısı gönderildi. Lütfen e-posta kutunuzu kontrol edin.',
                            style: TextStyle(
                              color: Colors.green.shade800,
                              height: 1.35,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _isLoading ? null : _sendResetEmail,
                    icon: _isLoading
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.send_outlined),
                    label: Text(
                      _isLoading
                          ? 'Gönderiliyor...'
                          : 'Sıfırlama Bağlantısı Gönder',
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.teal,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        vertical: 14,
                        horizontal: 18,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                TextButton.icon(
                  onPressed: _isLoading
                      ? null
                      : () {
                          Navigator.pop(context);
                        },
                  icon: const Icon(Icons.arrow_back, size: 18),
                  label: const Text('Giriş ekranına dön'),
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.teal,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}