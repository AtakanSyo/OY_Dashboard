import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/app_user.dart';

class AuthService {
  SupabaseClient get _client => Supabase.instance.client;

  /// Signs in with email and password, then fetches the user profile.
  /// Throws [AuthException] on auth failure, [Exception] on profile fetch failure.
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

    final profileData = await _client
        .from('user_profiles_full')
        .select()
        .eq('auth_id', authUser.id)
        .single();

    return AppUser.fromMap(profileData);
  }

  /// Registers a new user with email/password and metadata for the trigger.
  /// Returns the created auth user's ID. The profile row is created automatically
  /// by the on_auth_user_created trigger using first_name / last_name / role_code metadata.
  Future<String> signUp({
    required String email,
    required String password,
    required String firstName,
    required String lastName,
    required String roleCode,
  }) async {
    final response = await _client.auth.signUp(
      email: email,
      password: password,
      data: {
        'first_name': firstName,
        'last_name': lastName,
        'role_code': roleCode,
      },
    );

    final authUser = response.user;
    if (authUser == null) {
      throw const AuthException('Kayıt başarısız.');
    }

    return authUser.id;
  }

  /// Signs out the current user.
  Future<void> signOut() async {
    await _client.auth.signOut();
  }

  /// Returns the currently authenticated Supabase user, or null.
  User? get currentAuthUser => _client.auth.currentUser;

  /// Stream of auth state changes.
  Stream<AuthState> get onAuthStateChange =>
      _client.auth.onAuthStateChange;

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


