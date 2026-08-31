import 'package:flutter/material.dart';
import 'package:oy_site/l10n/app_localizations.dart';
import 'package:oy_site/screens/auth/forgot_password_screen.dart';
import 'package:oy_site/screens/auth/register_screen.dart';
import 'package:oy_site/site/pages/site_home_page.dart';
import 'package:oy_site/services/auth_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:oy_site/screens/dashboard/shell/dashboard_screen.dart';
import 'package:oy_site/widgets/language_selector.dart';

class LoginScreen extends StatefulWidget {
  final dynamic pressureRepository;

  const LoginScreen({super.key, required this.pressureRepository});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final AuthService _authService = AuthService();

  String? _errorMessage;
  bool _isLoading = false;
  bool _obscurePassword = true;

  Future<void> _login() async {
    final l10n = AppLocalizations.of(context);
    final email = _emailController.text.trim();
    final password = _passwordController.text;

    if (email.isEmpty) {
      setState(() => _errorMessage = l10n.enterEmail);
      return;
    }

    if (password.isEmpty) {
      setState(() => _errorMessage = l10n.enterPassword);
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final appUser = await _authService.signIn(
        email: email,
        password: password,
      );

      if (!mounted) return;

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => DashboardScreen(
            currentUser: appUser,
            pressureRepository: widget.pressureRepository,
          ),
        ),
      );
    } on AccountApprovalException catch (e) {
      if (!mounted) return;
      setState(() => _errorMessage = e.message);
    } on AuthException catch (e) {
      if (!mounted) return;
      setState(() => _errorMessage = _localizeAuthError(e.message));
    } catch (_) {
      if (!mounted) return;
      setState(() => _errorMessage = l10n.genericError);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  /// "Giriş Yap"tan gelindiğinde her durumda public site ana sayfasına döner
  /// ve giriş ekranını yığından temizler.
  void _goHome() {
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(
        settings: const RouteSettings(name: '/'),
        builder: (_) => const SiteHomePage(),
      ),
      (route) => false,
    );
  }

  void _openForgotPasswordScreen() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) =>
            ForgotPasswordScreen(initialEmail: _emailController.text.trim()),
      ),
    );
  }

  String _localizeAuthError(String message) {
    final l10n = AppLocalizations.of(context);
    final lower = message.toLowerCase();

    if (lower.contains('invalid login') ||
        lower.contains('invalid credentials')) {
      return l10n.invalidCredentials;
    }

    if (lower.contains('email not confirmed')) {
      return l10n.emailNotConfirmed;
    }

    if (lower.contains('too many requests')) {
      return l10n.tooManyAttempts;
    }

    return message;
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          tooltip: l10n.home,
          onPressed: _isLoading ? null : _goHome,
        ),
        actions: const [LanguageSelector(), SizedBox(width: 12)],
      ),
      body: Center(
        child: Container(
          padding: const EdgeInsets.all(24),
          width: 380,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                l10n.login,
                style: const TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 24),
              TextField(
                controller: _emailController,
                enabled: !_isLoading,
                keyboardType: TextInputType.emailAddress,
                decoration: InputDecoration(
                  labelText: l10n.email,
                  hintText: 'ornek@eposta.com',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onChanged: (_) {
                  if (_errorMessage != null) {
                    setState(() => _errorMessage = null);
                  }
                },
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _passwordController,
                enabled: !_isLoading,
                obscureText: _obscurePassword,
                decoration: InputDecoration(
                  labelText: l10n.password,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  errorText: _errorMessage,
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscurePassword
                          ? Icons.visibility_off
                          : Icons.visibility,
                    ),
                    onPressed: _isLoading
                        ? null
                        : () {
                            setState(() {
                              _obscurePassword = !_obscurePassword;
                            });
                          },
                  ),
                ),
                onChanged: (_) {
                  if (_errorMessage != null) {
                    setState(() => _errorMessage = null);
                  }
                },
                onSubmitted: (_) {
                  if (!_isLoading) _login();
                },
              ),
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: _isLoading ? null : _openForgotPasswordScreen,
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.teal,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 4,
                      vertical: 4,
                    ),
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: Text(l10n.forgotPassword),
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _login,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.teal,
                    padding: const EdgeInsets.symmetric(
                      vertical: 14,
                      horizontal: 40,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : Text(
                          l10n.login,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                          ),
                        ),
                ),
              ),
              const SizedBox(height: 16),
              TextButton(
                onPressed: _isLoading
                    ? null
                    : () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const RegisterScreen(),
                        ),
                      ),
                child: Text(l10n.noAccount),
              ),
              const SizedBox(height: 8),
              TextButton.icon(
                onPressed: _isLoading ? null : _goHome,
                icon: const Icon(Icons.arrow_back, size: 18),
                label: Text(l10n.home),
                style: TextButton.styleFrom(foregroundColor: Colors.teal),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
