import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:flutter_test/flutter_test.dart";
import "package:shared_preferences/shared_preferences.dart";
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

  test("AuthNotifier verifyAndChangeCredentials security check test", () async {
    SharedPreferences.setMockInitialValues({
      "custom_admin_password": "admin@1407",
      "custom_admin_name": "Smartiva Admin",
    });

    final container = ProviderContainer();
    addTearDown(container.dispose);

    final notifier = container.read(authNotifierProvider.notifier);
    await notifier.signIn(email: "admin@smart.com", password: "admin@1407");

    // 1. Wrong old password should fail
    final wrongResult = await notifier.verifyAndChangeCredentials(
      oldPassword: "wrongpassword999",
      newPassword: "newsecurepass123",
      newFullName: "Super Owner",
    );
    expect(wrongResult.success, isFalse);
    expect(wrongResult.message, contains("Incorrect old password"));

    // 2. Correct old password should succeed
    final correctResult = await notifier.verifyAndChangeCredentials(
      oldPassword: "admin@1407",
      newPassword: "newsecurepass123",
      newFullName: "Super Owner",
    );
    expect(correctResult.success, isTrue);

    // 3. State should reflect updated name
    final updatedAuth = container.read(authNotifierProvider);
    expect(updatedAuth.fullName, "Super Owner");

    // 4. Verification with newly set password should now succeed
    final verifyWithNew = await notifier.verifyAndChangeCredentials(
      oldPassword: "newsecurepass123",
      newFullName: "Super Owner 2",
    );
    expect(verifyWithNew.success, isTrue);
  });
}
