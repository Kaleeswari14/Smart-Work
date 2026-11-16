import "package:flutter/foundation.dart";
import "package:shared_preferences/shared_preferences.dart";
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

  Future<bool> verifyCurrentPassword({
    required String email,
    required String password,
  }) async {
    final client = _client;

    // Check SharedPreferences first
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedPass = prefs.getString("custom_admin_password") ?? "admin@1407";
      if (password == savedPass) {
        return true;
      }
    } catch (_) {}

    // If Supabase is connected, check with Supabase auth
    if (client != null) {
      try {
        final res = await client.auth.signInWithPassword(
          email: email,
          password: password,
        );
        return res.user != null;
      } catch (e) {
        debugPrint("⚠️ Password verification failed in Supabase: $e");
        return false;
      }
    }

    return false;
  }

  Future<void> updateCredentials({
    required String email,
    String? newPassword,
    String? newFullName,
  }) async {
    final client = _client;

    // 1. Persist to local storage
    try {
      final prefs = await SharedPreferences.getInstance();
      if (newPassword != null && newPassword.isNotEmpty) {
        await prefs.setString("custom_admin_password", newPassword);
      }
      if (newFullName != null && newFullName.isNotEmpty) {
        await prefs.setString("custom_admin_name", newFullName);
      }
    } catch (e) {
      debugPrint("⚠️ Error saving credentials to SharedPreferences: $e");
    }

    // 2. Persist to Supabase if connected
    if (client != null && client.auth.currentUser != null) {
      try {
        final attributes = UserAttributes(
          password: (newPassword != null && newPassword.isNotEmpty) ? newPassword : null,
          data: (newFullName != null && newFullName.isNotEmpty) ? {"full_name": newFullName} : null,
        );
        await client.auth.updateUser(attributes);

        if (newFullName != null && newFullName.isNotEmpty) {
          final userId = client.auth.currentUser!.id;
          await client.from("profiles").update({"full_name": newFullName}).eq("id", userId);
        }
      } catch (e) {
        debugPrint("⚠️ Error updating credentials in Supabase: $e");
        rethrow;
      }
    }
  }
}
