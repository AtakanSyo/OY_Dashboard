import 'package:flutter/material.dart';
import 'package:oy_site/l10n/app_localizations.dart';
import 'package:oy_site/services/auth_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:oy_site/widgets/language_selector.dart';

class ResetPasswordScreen extends StatefulWidget {
  const ResetPasswordScreen({super.key});

  @override
  State<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends State<ResetPasswordScreen> {
  final AuthService _authService = AuthService();

  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _passwordAgainController =
      TextEditingController();

  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscurePasswordAgain = true;

  String? _errorMessage;
  bool _isCompleted = false;

  @override
  void dispose() {
    _passwordController.dispose();
    _passwordAgainController.dispose();
    super.dispose();
  }

  Future<void> _updatePassword() async {
    final l10n = AppLocalizations.of(context);
    final password = _passwordController.text;
    final passwordAgain = _passwordAgainController.text;

    if (password.isEmpty || passwordAgain.isEmpty) {
      setState(() {
        _errorMessage = l10n.enterPasswordTwice;
      });
      return;
    }

    if (password.length < 8) {
      setState(() {
        _errorMessage = l10n.passwordMinEight;
      });
      return;
    }

    if (password != passwordAgain) {
      setState(() {
        _errorMessage = l10n.passwordsDoNotMatch;
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      await _authService.updatePassword(newPassword: password);

      await Supabase.instance.client.auth.signOut();

      if (!mounted) return;

      setState(() {
        _isCompleted = true;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Şifreniz güncellendi. Yeni şifrenizle giriş yapabilirsiniz.',
          ),
          backgroundColor: Colors.green,
        ),
      );
    } on AuthException catch (e) {
      if (!mounted) return;

      setState(() {
        _errorMessage = _localizeAuthError(e.message);
      });
    } catch (_) {
      if (!mounted) return;

      setState(() {
        _errorMessage = 'Şifre güncellenemedi. Lütfen tekrar deneyin.';
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

    if (lower.contains('session') || lower.contains('jwt')) {
      return 'Şifre sıfırlama oturumu bulunamadı veya süresi doldu. Lütfen yeniden şifre sıfırlama bağlantısı isteyin.';
    }

    if (lower.contains('password')) {
      return 'Şifre güncellenemedi. Lütfen daha güçlü bir şifre deneyin.';
    }

    return message;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.setNewPassword),
        foregroundColor: Colors.black87,
        backgroundColor: Colors.white,
        elevation: 0.6,
        actions: const [LanguageSelector(), SizedBox(width: 12)],
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
                BoxShadow(color: Colors.black12, blurRadius: 10),
              ],
            ),
            child: _isCompleted
                ? Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CircleAvatar(
                        radius: 34,
                        backgroundColor: Colors.green.withOpacity(0.10),
                        child: Icon(
                          Icons.check_circle_outline,
                          color: Colors.green.shade700,
                          size: 34,
                        ),
                      ),
                      const SizedBox(height: 18),
                      Text(
                        l10n.passwordUpdated,
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        'Yeni şifreniz kaydedildi. Güvenlik için oturum kapatıldı. Yeni şifrenizle tekrar giriş yapabilirsiniz.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.grey[700], height: 1.4),
                      ),
                      const SizedBox(height: 24),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () {
                            Navigator.popUntil(
                              context,
                              (route) => route.isFirst,
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.teal,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: Text(l10n.backToLogin),
                        ),
                      ),
                    ],
                  )
                : Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CircleAvatar(
                        radius: 34,
                        backgroundColor: Colors.teal.withOpacity(0.10),
                        child: Icon(
                          Icons.password_outlined,
                          color: Colors.teal.shade700,
                          size: 34,
                        ),
                      ),
                      const SizedBox(height: 18),
                      Text(
                        l10n.setNewPassword,
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        l10n.setPasswordDescription,
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.grey[700], height: 1.4),
                      ),
                      const SizedBox(height: 24),
                      TextField(
                        controller: _passwordController,
                        enabled: !_isLoading,
                        obscureText: _obscurePassword,
                        decoration: InputDecoration(
                          labelText: l10n.newPassword,
                          prefixIcon: const Icon(Icons.lock_outline),
                          errorText: _errorMessage,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          suffixIcon: IconButton(
                            onPressed: _isLoading
                                ? null
                                : () {
                                    setState(() {
                                      _obscurePassword = !_obscurePassword;
                                    });
                                  },
                            icon: Icon(
                              _obscurePassword
                                  ? Icons.visibility_off
                                  : Icons.visibility,
                            ),
                          ),
                        ),
                        onChanged: (_) {
                          if (_errorMessage != null) {
                            setState(() {
                              _errorMessage = null;
                            });
                          }
                        },
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: _passwordAgainController,
                        enabled: !_isLoading,
                        obscureText: _obscurePasswordAgain,
                        decoration: InputDecoration(
                          labelText: l10n.newPasswordAgain,
                          prefixIcon: const Icon(Icons.lock_reset_outlined),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          suffixIcon: IconButton(
                            onPressed: _isLoading
                                ? null
                                : () {
                                    setState(() {
                                      _obscurePasswordAgain =
                                          !_obscurePasswordAgain;
                                    });
                                  },
                            icon: Icon(
                              _obscurePasswordAgain
                                  ? Icons.visibility_off
                                  : Icons.visibility,
                            ),
                          ),
                        ),
                        onSubmitted: (_) {
                          if (!_isLoading) _updatePassword();
                        },
                      ),
                      const SizedBox(height: 24),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: _isLoading ? null : _updatePassword,
                          icon: _isLoading
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Icon(Icons.save_outlined),
                          label: Text(
                            _isLoading ? l10n.saving : l10n.saveNewPassword,
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
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}
