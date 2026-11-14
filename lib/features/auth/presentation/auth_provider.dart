import "dart:async";
import "package:flutter_riverpod/flutter_riverpod.dart";
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

    if (!repo.isConnected) {
      state = UserAuthState(
        status: AuthStatus.authenticated,
        email: email,
        fullName: "Business Owner",
        isOwner: true,
      );
      return true;
    }

    try {
      final response = await repo.signIn(email: email, password: password);
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
      final errString = e.toString();
      String friendlyMessage = errString.replaceAll("Exception: ", "").replaceAll("AuthApiException: ", "");

      if (errString.contains("Invalid login credentials") || errString.contains("invalid_credentials")) {
        friendlyMessage = "Invalid credentials. Ungalukku account illai endraal, Supabase-la account confirm aagi irukka vendum.";
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
}
