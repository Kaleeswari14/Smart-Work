import "package:flutter/foundation.dart";
import "package:supabase_flutter/supabase_flutter.dart";
import "../../../core/config/supabase_config.dart";

class AuthRepository {
  final _client = SupabaseConfig.client;

  bool get isConnected => _client != null;

  User? get currentUser => _client?.auth.currentUser;

  Session? get currentSession => _client?.auth.currentSession;

  Stream<AuthState>? get authStateChanges => _client?.auth.onAuthStateChange;

  Future<AuthResponse?> signIn({
    required String email,
    required String password,
  }) async {
    final client = _client;
    if (client == null) {
      debugPrint("ℹ️ Supabase not configured. Mocking sign in for local mode.");
      return null;
    }

    try {
      final response = await client.auth.signInWithPassword(
        email: email,
        password: password,
      );
      return response;
    } catch (e) {
      debugPrint("⚠️ Sign in error: $e");
      rethrow;
    }
  }

  Future<AuthResponse?> signUp({
    required String email,
    required String password,
    String fullName = "Business Owner",
  }) async {
    final client = _client;
    if (client == null) {
      debugPrint("ℹ️ Supabase not configured. Mocking sign up for local mode.");
      return null;
    }

    try {
      final response = await client.auth.signUp(
        email: email,
        password: password,
        data: {
          "full_name": fullName,
          "role": "owner",
        },
      );
      return response;
    } catch (e) {
      debugPrint("⚠️ Sign up error: $e");
      rethrow;
    }
  }

  Future<void> signOut() async {
    final client = _client;
    if (client == null) return;

    try {
      await client.auth.signOut();
    } catch (e) {
      debugPrint("⚠️ Sign out error: $e");
    }
  }

  Future<void> resetPassword(String email) async {
    final client = _client;
    if (client == null) return;

    try {
      await client.auth.resetPasswordForEmail(email);
    } catch (e) {
      debugPrint("⚠️ Password reset error: $e");
      rethrow;
    }
  }

  Future<Map<String, dynamic>?> fetchProfile(String userId) async {
    final client = _client;
    if (client == null) return null;

    try {
      final profile = await client
          .from("profiles")
          .select()
          .eq("id", userId)
          .maybeSingle();
      return profile;
    } catch (e) {
      debugPrint("⚠️ Error fetching user profile: $e");
      return null;
    }
  }
}
