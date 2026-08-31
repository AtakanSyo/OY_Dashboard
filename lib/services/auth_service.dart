import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/app_user.dart';

class AccountApprovalException implements Exception {
  final String status;
  final String message;

  const AccountApprovalException({
    required this.status,
    required this.message,
  });

  @override
  String toString() => message;
}

class AuthService {
  SupabaseClient get _client => Supabase.instance.client;

  bool _requiresManualApproval(String roleCode) {
    return roleCode == RoleCodes.expert || roleCode == RoleCodes.optiYouTeam;
  }

  Future<AppUser> signIn({
    required String email,
    required String password,
  }) async {
    final response = await _client.auth.signInWithPassword(
      email: email,
      password: password,
    );

    final authUser = response.user;
    if (authUser == null) {
      throw const AuthException('Giriş başarısız.');
    }

    final rawProfileData = await _client
        .from('user_profiles_full')
        .select()
        .eq('auth_id', authUser.id)
        .single();

    final profileData = Map<String, dynamic>.from(rawProfileData as Map);

    final roleCode = (profileData['role_code'] ?? '').toString();
    final approvalStatus =
        (profileData['approval_status'] ?? 'approved').toString();
    final isApproved = profileData['is_approved'] as bool? ?? true;

    if (_requiresManualApproval(roleCode)) {
      if (approvalStatus != 'approved' || isApproved != true) {
        await _client.auth.signOut();

        throw AccountApprovalException(
          status: approvalStatus,
          message: _approvalMessage(approvalStatus),
        );
      }
    }

    return AppUser.fromMap(profileData);
  }

  String _approvalMessage(String status) {
    switch (status) {
      case 'pending':
        return 'Hesabınız onay bekliyor. Optiyou ekibi hesabınızı onayladıktan sonra giriş yapabilirsiniz.';
      case 'rejected':
        return 'Kayıt başvurunuz onaylanmadı. Lütfen Optiyou ekibiyle iletişime geçin.';
      case 'suspended':
        return 'Hesabınız askıya alınmıştır. Lütfen Optiyou ekibiyle iletişime geçin.';
      default:
        return 'Hesabınız henüz giriş için onaylanmamış.';
    }
  }

  Future<String> signUp({
    required String email,
    required String password,
    required String firstName,
    required String lastName,
    required String roleCode,
  }) async {
    final requiresApproval = _requiresManualApproval(roleCode);

    final response = await _client.auth.signUp(
      email: email,
      password: password,
      data: {
        'first_name': firstName,
        'last_name': lastName,
        'role_code': roleCode,
        'approval_status': requiresApproval ? 'pending' : 'approved',
        'is_approved': !requiresApproval,
      },
    );

    final authUser = response.user;
    if (authUser == null) {
      throw const AuthException('Kayıt başarısız.');
    }

    return authUser.id;
  }

  Future<void> signOut() async {
    await _client.auth.signOut();
  }

  User? get currentAuthUser => _client.auth.currentUser;

  Stream<AuthState> get onAuthStateChange => _client.auth.onAuthStateChange;

  Future<void> sendPasswordResetEmail({
    required String email,
    String? redirectTo,
  }) async {
    await Supabase.instance.client.auth.resetPasswordForEmail(
      email,
      redirectTo: redirectTo,
    );
  }

  Future<void> updatePassword({
    required String newPassword,
  }) async {
    await Supabase.instance.client.auth.updateUser(
      UserAttributes(
        password: newPassword,
      ),
    );
  }
}