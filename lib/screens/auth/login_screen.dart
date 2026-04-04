import 'package:flutter/material.dart';
import 'package:oy_site/data/mock/mock_users.dart';
import 'package:oy_site/models/app_user.dart';
import 'package:oy_site/screens/dashboard/dashboard_screen.dart';

class LoginScreen extends StatefulWidget {
  final dynamic pressureRepository;

  const LoginScreen({
    super.key,
    required this.pressureRepository,
  });

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _emailController = TextEditingController();

  String? _errorMessage;
  bool _isLoading = false;
  String? _selectedRoleCode;

  final List<Map<String, String>> _roles = const [
    {
      'role_code': RoleCodes.expert,
      'role_name': 'Uzman',
    },
    {
      'role_code': RoleCodes.customer,
      'role_name': 'Müşteri',
    },
    {
      'role_code': RoleCodes.optiYouTeam,
      'role_name': 'OptiYou Ekibi',
    },
  ];

  Future<AppUser?> _mockLogin({
    required String email,
    required String roleCode,
  }) async {
    await Future.delayed(const Duration(milliseconds: 300));

    if (email != 'testuser@example.com') {
      return null;
    }

    if (!RoleCodes.values.contains(roleCode)) {
      return null;
    }

    return MockUsers.buildTestUser(
      email: email,
      roleCode: roleCode,
    );
  }

  Future<void> _login() async {
    final email = _emailController.text.trim();
    final roleCode = _selectedRoleCode;

    if (email.isEmpty) {
      setState(() {
        _errorMessage = 'Lütfen e-posta girin.';
      });
      return;
    }

    if (roleCode == null || roleCode.isEmpty) {
      setState(() {
        _errorMessage = 'Lütfen bir kullanıcı rolü seçin.';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final appUser = await _mockLogin(
      email: email,
      roleCode: roleCode,
    );

    if (!mounted) return;

    setState(() {
      _isLoading = false;
    });

    if (appUser != null) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => DashboardScreen(
            currentUser: appUser,
            pressureRepository: widget.pressureRepository,
          ),
        ),
      );
    } else {
      setState(() {
        _errorMessage =
            'Geçersiz giriş. Test kullanıcı bilgileri veya rol seçimi hatalı.';
      });
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Container(
          padding: const EdgeInsets.all(24),
          width: 380,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Giriş Yap',
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 20),
              DropdownButtonFormField<String>(
                initialValue: _selectedRoleCode,
                decoration: InputDecoration(
                  labelText: 'Kullanıcı Rolü',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                items: _roles.map((role) {
                  return DropdownMenuItem<String>(
                    value: role['role_code'],
                    child: Text(role['role_name']!),
                  );
                }).toList(),
                onChanged: _isLoading
                    ? null
                    : (value) {
                        setState(() {
                          _selectedRoleCode = value;
                          _errorMessage = null;
                        });
                      },
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _emailController,
                enabled: !_isLoading,
                decoration: InputDecoration(
                  labelText: 'E-posta',
                  hintText: 'testuser@example.com',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  errorText: _errorMessage,
                ),
                onChanged: (_) {
                  if (_errorMessage != null) {
                    setState(() {
                      _errorMessage = null;
                    });
                  }
                },
              ),
              const SizedBox(height: 20),
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
                      : const Text(
                          'Giriş Yap',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}