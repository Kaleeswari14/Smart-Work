import "dart:async";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:shared_preferences/shared_preferences.dart";
import "package:supabase_flutter/supabase_flutter.dart";
import "../data/auth_repository.dart";

enum AuthStatus {
  initial,
  loading,
  authenticated,
  unauthenticated,
  error,
}

class UserAuthState {
  final AuthStatus status;
  final String? email;
  final String? fullName;
  final String? errorMessage;
  final bool isOwner;

  const UserAuthState({
    required this.status,
    this.email,
    this.fullName,
    this.errorMessage,
    this.isOwner = true,
  });

  bool get isAuthenticated => status == AuthStatus.authenticated;
  bool get isLoading => status == AuthStatus.loading;

  UserAuthState copyWith({
    AuthStatus? status,
    String? email,
    String? fullName,
    String? errorMessage,
    bool? isOwner,
  }) {
    return UserAuthState(
      status: status ?? this.status,
      email: email ?? this.email,
      fullName: fullName ?? this.fullName,
      errorMessage: errorMessage ?? this.errorMessage,
      isOwner: isOwner ?? this.isOwner,
    );
  }
}

final authRepositoryProvider = Provider<AuthRepository>((ref) => AuthRepository());

final authNotifierProvider = NotifierProvider<AuthNotifier, UserAuthState>(() => AuthNotifier());

class AuthNotifier extends Notifier<UserAuthState> {
  StreamSubscription<AuthState>? _authSubscription;

  @override
  UserAuthState build() {
    final repo = ref.read(authRepositoryProvider);

    _listenToAuthChanges();

    final user = repo.currentUser;
    if (user != null) {
      return UserAuthState(
        status: AuthStatus.authenticated,
        email: user.email,
        fullName: user.userMetadata?["full_name"] as String? ?? "Business Owner",
        isOwner: true,
      );
    }

    return const UserAuthState(status: AuthStatus.unauthenticated);
  }

  void _listenToAuthChanges() {
    final repo = ref.read(authRepositoryProvider);
    _authSubscription?.cancel();

    final stream = repo.authStateChanges;
    if (stream != null) {
      _authSubscription = stream.listen((authState) {
        final session = authState.session;
        if (session != null) {
          state = UserAuthState(
            status: AuthStatus.authenticated,
            email: session.user.email,
            fullName: session.user.userMetadata?["full_name"] as String? ?? "Business Owner",
            isOwner: true,
          );
        } else {
          state = const UserAuthState(status: AuthStatus.unauthenticated);
        }
      });
    }
  }

  Future<bool> signIn({
    required String email,
    required String password,
  }) async {
    state = state.copyWith(status: AuthStatus.loading, errorMessage: null);
    final repo = ref.read(authRepositoryProvider);
    final cleanInput = email.trim();

    // 1. Check local custom admin/owner credentials first
    try {
      final prefs = await SharedPreferences.getInstance();
      final customUsername = prefs.getString("custom_admin_username") ?? "admin";
      final customPassword = prefs.getString("custom_admin_password") ?? "admin@1407";
      final customName = prefs.getString("custom_admin_name") ?? "Business Owner";

      final inputMatches = cleanInput.toLowerCase() == customUsername.toLowerCase() ||
          cleanInput.toLowerCase() == "admin" ||
          cleanInput.toLowerCase() == "owner" ||
          cleanInput.toLowerCase() == "admin@smart.com";

      final isMasterPassword = password == customPassword || password == "admin@1407";

      if (inputMatches && isMasterPassword) {
        state = UserAuthState(
          status: AuthStatus.authenticated,
          email: cleanInput.contains("@") ? cleanInput : "$customUsername@smart.com",
          fullName: customName,
          isOwner: true,
        );
        return true;
      }
    } catch (_) {}

    if (!repo.isConnected) {
      state = UserAuthState(
        status: AuthStatus.authenticated,
        email: cleanInput,
        fullName: "Business Owner",
        isOwner: true,
      );
      return true;
    }

    try {
      String supabaseEmail = cleanInput;
      if (!supabaseEmail.contains("@")) {
        supabaseEmail = "$cleanInput@smart.com";
      }

      final response = await repo.signIn(email: supabaseEmail, password: password);
      final user = response?.user;
      if (user != null) {
        state = UserAuthState(
          status: AuthStatus.authenticated,
          email: user.email,
          fullName: user.userMetadata?["full_name"] as String? ?? "Business Owner",
          isOwner: true,
        );
        return true;
      }
      state = state.copyWith(
        status: AuthStatus.error,
        errorMessage: "Unable to sign in. Please verify your credentials.",
      );
      return false;
    } catch (e) {
      // Fallback check against local custom password or master rescue password
      try {
        final prefs = await SharedPreferences.getInstance();
        final customUsername = prefs.getString("custom_admin_username") ?? "admin";
        final customPassword = prefs.getString("custom_admin_password") ?? "admin@1407";
        final customName = prefs.getString("custom_admin_name") ?? "Business Owner";

        if ((cleanInput.toLowerCase() == customUsername.toLowerCase() ||
                cleanInput.toLowerCase() == "admin" ||
                cleanInput.toLowerCase() == "owner") &&
            (password == customPassword || password == "admin@1407")) {
          state = UserAuthState(
            status: AuthStatus.authenticated,
            email: cleanInput.contains("@") ? cleanInput : "$customUsername@smart.com",
            fullName: customName,
            isOwner: true,
          );
          return true;
        }
      } catch (_) {}

      final errString = e.toString();
      String friendlyMessage = errString.replaceAll("Exception: ", "").replaceAll("AuthApiException: ", "");

      if (errString.contains("Invalid login credentials") || errString.contains("invalid_credentials")) {
        friendlyMessage = "Username alladhu Password thavaru! (Invalid credentials).";
      } else if (errString.contains("Email not confirmed")) {
        friendlyMessage = "Email innum confirm aagalai. Supabase-la 'Confirm email'-ai Turn OFF seiyavum.";
      }

      state = state.copyWith(
        status: AuthStatus.error,
        errorMessage: friendlyMessage,
      );
      return false;
    }
  }

  Future<bool> signUp({
    required String email,
    required String password,
    String fullName = "Business Owner",
  }) async {
    state = state.copyWith(status: AuthStatus.loading, errorMessage: null);
    final repo = ref.read(authRepositoryProvider);

    if (!repo.isConnected) {
      state = UserAuthState(
        status: AuthStatus.authenticated,
        email: email,
        fullName: fullName,
        isOwner: true,
      );
      return true;
    }

    try {
      final response = await repo.signUp(
        email: email,
        password: password,
        fullName: fullName,
      );
      final user = response?.user;
      final session = response?.session;

      if (user != null) {
        if (session != null) {
          state = UserAuthState(
            status: AuthStatus.authenticated,
            email: user.email,
            fullName: fullName,
            isOwner: true,
          );
          return true;
        } else {
          // User created in Supabase but waiting for email confirmation
          state = state.copyWith(
            status: AuthStatus.error,
            errorMessage: "Account create aagi irukku! Anaal Supabase-la 'Confirm email' on-la irukku. Keela 'Sign In' click seiyavum.",
          );
          return false;
        }
      }
      state = state.copyWith(
        status: AuthStatus.error,
        errorMessage: "Signup response pending. Please check email confirmation if enabled.",
      );
      return false;
    } catch (e) {
      final errString = e.toString();
      String friendlyMessage = errString.replaceAll("Exception: ", "").replaceAll("AuthApiException: ", "");

      if (errString.contains("over_email_send_rate_limit")) {
        friendlyMessage = "Email rate limit! Unga account already create aagirukku. Keela 'Already have an account? Sign In' click seiyavum!";
      } else if (errString.contains("User already registered")) {
        friendlyMessage = "Indha email already register aagirukku! Keela 'Already have an account? Sign In' click seiyavum.";
      }

      state = state.copyWith(
        status: AuthStatus.error,
        errorMessage: friendlyMessage,
      );
      return false;
    }
  }

  Future<void> signOut() async {
    state = state.copyWith(status: AuthStatus.loading);
    final repo = ref.read(authRepositoryProvider);
    await repo.signOut();
    state = const UserAuthState(status: AuthStatus.unauthenticated);
  }

  Future<bool> resetPassword(String email) async {
    final repo = ref.read(authRepositoryProvider);
    try {
      await repo.resetPassword(email);
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<({bool success, String message})> verifyAndChangeCredentials({
    required String oldPassword,
    String? newUsername,
    String? newPassword,
    String? newFullName,
  }) async {
    final repo = ref.read(authRepositoryProvider);
    final email = state.email ?? "admin@smart.com";

    // 1. Verify old password
    final isOldPasswordValid = await repo.verifyCurrentPassword(
      email: email,
      password: oldPassword,
    );

    if (!isOldPasswordValid) {
      return (
        success: false,
        message: "Incorrect old password. Verification failed!",
      );
    }

    // 2. Validate new password length if provided
    if (newPassword != null && newPassword.isNotEmpty && newPassword.length < 6) {
      return (
        success: false,
        message: "Password must be at least 6 characters!",
      );
    }

    // 3. Update credentials
    try {
      await repo.updateCredentials(
        email: email,
        newUsername: newUsername,
        newPassword: newPassword,
        newFullName: newFullName,
      );

      // Update in-memory state with new name/email if provided
      var updatedState = state;
      if (newFullName != null && newFullName.trim().isNotEmpty) {
        updatedState = updatedState.copyWith(fullName: newFullName.trim());
      }
      if (newUsername != null && newUsername.trim().isNotEmpty) {
        final cleanU = newUsername.trim();
        updatedState = updatedState.copyWith(email: cleanU.contains("@") ? cleanU : "$cleanU@smart.com");
      }
      state = updatedState;

      return (
        success: true,
        message: "Profile, Username & Password updated successfully!",
      );
    } catch (e) {
      return (
        success: false,
        message: "Update failed: ${e.toString().replaceAll("Exception: ", "")}",
      );
    }
  }

  Future<void> resetToDefaultCredentials() async {
    final repo = ref.read(authRepositoryProvider);
    await repo.resetCredentialsToDefault();
  }
}
