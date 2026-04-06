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

  /// Signs out the current user.
  Future<void> signOut() async {
    await _client.auth.signOut();
  }

  /// Returns the currently authenticated Supabase user, or null.
  User? get currentAuthUser => _client.auth.currentUser;

  /// Stream of auth state changes.
  Stream<AuthState> get onAuthStateChange =>
      _client.auth.onAuthStateChange;
}
