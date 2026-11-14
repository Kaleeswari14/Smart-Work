import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:flutter_test/flutter_test.dart";
import "package:work_management/features/auth/presentation/auth_provider.dart";

void main() {
  test("AuthNotifier initial state & sign in / sign out flow test", () async {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    // 1. Initial State
    final initialAuth = container.read(authNotifierProvider);
    expect(initialAuth.status, anyOf(AuthStatus.unauthenticated, AuthStatus.authenticated));

    final notifier = container.read(authNotifierProvider.notifier);

    // 2. Perform Owner Sign In
    final success = await notifier.signIn(
      email: "owner@business.com",
      password: "secretpassword123",
    );

    // 3. Verify Authenticated State with Full Owner Access
    expect(success, isTrue);
    final loggedInAuth = container.read(authNotifierProvider);
    expect(loggedInAuth.status, AuthStatus.authenticated);
    expect(loggedInAuth.isAuthenticated, isTrue);
    expect(loggedInAuth.isOwner, isTrue);
    expect(loggedInAuth.email, "owner@business.com");

    // 4. Perform Sign Out
    await notifier.signOut();
    final loggedOutAuth = container.read(authNotifierProvider);
    expect(loggedOutAuth.status, AuthStatus.unauthenticated);
    expect(loggedOutAuth.isAuthenticated, isFalse);
  });
}
