import "package:flutter/material.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:flutter_test/flutter_test.dart";
import "package:shared_preferences/shared_preferences.dart";
import "package:work_management/core/router/app_router.dart";
import "package:work_management/main.dart";

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({
      "custom_admin_username": "admin",
      "custom_admin_password": "admin@1407",
    });
  });

  testWidgets("Phase 2 Frontend Flow & Language Toggle test", (WidgetTester tester) async {
    // Set typical mobile screen size
    tester.view.physicalSize = const Size(1080, 1920);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(
      const ProviderScope(
        child: WorkManagementApp(),
      ),
    );
    await tester.pumpAndSettle();

    // 1. Verify Login Screen renders initial English elements
    expect(find.text("Smartiva"), findsWidgets);
    expect(find.text("Sign In"), findsOneWidget);
    expect(find.text("Tanglish"), findsOneWidget);

    // 2. Tap the Tanglish toggle button in AppBar
    await tester.tap(find.text("Tanglish"));
    await tester.pumpAndSettle();

    // Verify Tanglish text
    expect(find.text("Smartiva"), findsWidgets);
    expect(find.text("Ulle Nulai"), findsWidgets);

    // 3. Enter login credentials and tap Sign In button
    await tester.enterText(find.byType(TextField).at(0), "admin@smart.com");
    await tester.enterText(find.byType(TextField).at(1), "admin@1407");
    await tester.pumpAndSettle();

    final signInButton = find.widgetWithText(ElevatedButton, "Ulle Nulai");
    expect(signInButton, findsOneWidget);
    await tester.ensureVisible(signInButton);
    await tester.tap(signInButton);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pump(const Duration(milliseconds: 300));

    // 4. Verify Dashboard displays in Tanglish
    expect(find.text("Mukkiya Pakkam"), findsWidgets);
    expect(find.text("Oru Paarvai"), findsOneWidget);
  });

  testWidgets("Works Status Dropdown & Payments Dashboard Flow test", (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1080, 1920);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    appRouter.go("/login");
    await tester.pumpWidget(
      const ProviderScope(
        child: WorkManagementApp(),
      ),
    );
    await tester.pumpAndSettle();

    // 1. Sign In (Enter credentials and tap login ElevatedButton)
    await tester.enterText(find.byType(TextField).at(0), "admin@smart.com");
    await tester.enterText(find.byType(TextField).at(1), "admin@1407");
    await tester.pumpAndSettle();

    final signInBtn = find.byType(ElevatedButton).first;
    await tester.ensureVisible(signInBtn);
    await tester.tap(signInBtn);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pump(const Duration(milliseconds: 300));

    // 2. Navigate to Customers via Bottom Navigation Bar
    final customersNav = find.byIcon(Icons.people_outline).last;
    await tester.tap(customersNav);
    await tester.pumpAndSettle();

    // 3. Add a Customer
    final addCustomerBtn = find.byIcon(Icons.person_add).first;
    await tester.tap(addCustomerBtn);
    await tester.pumpAndSettle();

    // Fill customer form (using TextField indices: at(0) is screen search, at(1) is Name, at(2) is Phone)
    final textFields = find.byType(TextField);
    await tester.enterText(textFields.at(1), "Ramesh");
    await tester.enterText(textFields.at(2), "9876543210");
    await tester.pumpAndSettle();

    final saveCustomerBtn = find.widgetWithText(ElevatedButton, "Save").first;
    await tester.tap(saveCustomerBtn);
    await tester.pumpAndSettle();

    expect(find.text("Ramesh"), findsWidgets);

    // 4. Navigate to Works tab
    final worksNav = find.byIcon(Icons.assignment_outlined).last;
    await tester.tap(worksNav);
    await tester.pumpAndSettle();

    // 5. Add a Work for Ramesh
    final addWorkBtn = find.byType(ElevatedButton).first;
    await tester.tap(addWorkBtn);
    await tester.pumpAndSettle();

    final workFields = find.byType(TextField);
    await tester.enterText(workFields.at(0), "Ramesh");
    await tester.pumpAndSettle();

    await tester.enterText(workFields.at(1), "Engine Overhaul");
    await tester.enterText(workFields.at(2), "Full servicing of engine");
    await tester.enterText(workFields.at(3), "5000");
    await tester.enterText(workFields.at(4), "1000");
    await tester.pumpAndSettle();

    final saveWorkBtn = find.widgetWithText(ElevatedButton, "Save").first;
    await tester.ensureVisible(saveWorkBtn);
    await tester.tap(saveWorkBtn);
    await tester.pumpAndSettle();

    expect(find.text("Engine Overhaul"), findsOneWidget);

    // 6. Test Status Dropdown pill button -> Change to In Progress
    // Find the status dropdown widget (PopupMenuButton<String>)
    final statusMenu = find.byType(PopupMenuButton<String>);
    expect(statusMenu, findsOneWidget);
    await tester.tap(statusMenu);
    await tester.pumpAndSettle();

    // Tap In Progress option in popup menu
    final inProgressOption = find.byIcon(Icons.play_circle_filled);
    await tester.tap(inProgressOption);
    await tester.pumpAndSettle();

    expect(find.text("LIVE"), findsOneWidget);

    // 7. Status Dropdown -> Completed
    await tester.tap(statusMenu);
    await tester.pumpAndSettle();

    final completedOption = find.byIcon(Icons.check_circle);
    await tester.tap(completedOption);
    await tester.pumpAndSettle();

    // In the Complete Work dialog, enter action and tap Confirm Complete
    final actionInput = find.byType(TextField).first;
    await tester.enterText(actionInput, "Engine overhauled and tuned");
    final confirmCompleteBtn = find.byType(ElevatedButton).last;
    await tester.tap(confirmCompleteBtn);
    await tester.pumpAndSettle();

    expect(find.textContaining("Action: Engine overhauled and tuned"), findsOneWidget);

    // 8. Tap Payments navigation via bottom bar (Icons.payment_outlined)
    final paymentsNav = find.byIcon(Icons.payment_outlined).last;
    await tester.tap(paymentsNav);
    await tester.pumpAndSettle();

    // In Payments Dashboard, verify "Generate Bill" button appears
    expect(find.byIcon(Icons.receipt), findsOneWidget);

    // Generate Bill
    final generateBillBtn = find.byIcon(Icons.receipt).first;
    await tester.tap(generateBillBtn);
    await tester.pumpAndSettle();

    final saveBillBtn = find.byType(ElevatedButton).last;
    await tester.tap(saveBillBtn);
    await tester.pumpAndSettle();

    // Now Collect Payment button appears
    expect(find.byIcon(Icons.payment), findsWidgets);

    // Collect Payment
    final collectBtn = find.byIcon(Icons.payment).first;
    await tester.tap(collectBtn);
    await tester.pumpAndSettle();

    final confirmPaymentSaveBtn = find.byType(ElevatedButton).last;
    await tester.tap(confirmPaymentSaveBtn);
    await tester.pumpAndSettle();

    // Verify Tab 2 (Collected History)
    final historyTab = find.byIcon(Icons.history).last;
    await tester.tap(historyTab);
    await tester.pumpAndSettle();

    expect(find.text("SAVINGS"), findsOneWidget);
    expect(find.textContaining("Engine Overhaul"), findsWidgets);
    expect(find.text("ADVANCE PAYMENT"), findsOneWidget);
    expect(find.text("BILL COLLECTION"), findsOneWidget);
  });
}

