import "package:flutter/foundation.dart";
import "package:flutter/material.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:go_router/go_router.dart";
import "package:url_launcher/url_launcher.dart";
import "../../../core/localization/app_localizations.dart";
import "../../../core/localization/language_provider.dart";
import "../../auth/presentation/auth_provider.dart";
import "../../../features/customers/presentation/customers_screen.dart";
import "../../../features/dashboard/presentation/dashboard_screen.dart";
import "../../../features/payments/presentation/payments_screen.dart";
import "../../../features/reports/presentation/reports_screen.dart";
import "../../../features/settings/presentation/settings_screen.dart";
import "../../../features/works/presentation/works_screen.dart";

final navigationIndexProvider =
    NotifierProvider<NavigationIndexNotifier, int>(() => NavigationIndexNotifier());

class NavigationIndexNotifier extends Notifier<int> {
  @override
  int build() => 0;

  void setIndex(int index) {
    state = index;
  }
}

class MainShellScreen extends ConsumerWidget {
  const MainShellScreen({super.key});

  static const List<Widget> _screens = [
    DashboardScreen(),
    CustomersScreen(),
    WorksScreen(),
    PaymentsScreen(),
    ReportsScreen(),
    SettingsScreen(),
  ];

  String _getScreenTitle(BuildContext context, int index) {
    switch (index) {
      case 0:
        return context.tr("dashboard");
      case 1:
        return context.tr("customers");
      case 2:
        return context.tr("works");
      case 3:
        return context.tr("payments");
      case 4:
        return context.tr("reports");
      case 5:
        return context.tr("settings");
      default:
        return context.tr("app_title");
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentIndex = ref.watch(navigationIndexProvider);
    final isTanglish = ref.watch(languageProvider).languageCode == "ta";

    return Scaffold(
      appBar: AppBar(
        leading: Builder(
          builder: (ctx) => IconButton(
            icon: const Icon(Icons.menu),
            tooltip: "Menu",
            onPressed: () {
              Scaffold.of(ctx).openDrawer();
            },
          ),
        ),
        title: Text(_getScreenTitle(context, currentIndex)),
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF1E3A8A), Color(0xFF0D9488)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(10),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.15),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    padding: const EdgeInsets.all(5),
                    child: Image.asset("assets/images/smartiva_logo.png", fit: BoxFit.contain),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    context.tr("app_title"),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    context.tr("tagline"),
                    style: const TextStyle(color: Colors.white70, fontSize: 11),
                  ),
                ],
              ),
            ),
            ListTile(
              leading: const Icon(Icons.dashboard_outlined),
              title: Text(context.tr("dashboard")),
              selected: currentIndex == 0,
              onTap: () {
                ref.read(navigationIndexProvider.notifier).setIndex(0);
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.people_outline),
              title: Text(context.tr("customers")),
              selected: currentIndex == 1,
              onTap: () {
                ref.read(navigationIndexProvider.notifier).setIndex(1);
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.assignment_outlined),
              title: Text(context.tr("works")),
              selected: currentIndex == 2,
              onTap: () {
                ref.read(navigationIndexProvider.notifier).setIndex(2);
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.payment_outlined),
              title: Text(context.tr("payments")),
              selected: currentIndex == 3,
              onTap: () {
                ref.read(navigationIndexProvider.notifier).setIndex(3);
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.bar_chart_outlined),
              title: Text(context.tr("reports")),
              selected: currentIndex == 4,
              onTap: () {
                ref.read(navigationIndexProvider.notifier).setIndex(4);
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.settings_outlined),
              title: Text(context.tr("settings")),
              selected: currentIndex == 5,
              onTap: () {
                ref.read(navigationIndexProvider.notifier).setIndex(5);
                Navigator.pop(context);
              },
            ),
            const Divider(),
            if (kIsWeb)
              ListTile(
                leading: const Icon(Icons.android, color: Colors.green),
                title: Text(context.tr("download_apk")),
                subtitle: Text(
                  context.tr("download_apk_desc"),
                  style: const TextStyle(fontSize: 11),
                ),
                onTap: () async {
                  Navigator.pop(context);
                  final uri = Uri.parse("smartiva.apk");
                  if (await canLaunchUrl(uri)) {
                    await launchUrl(uri, mode: LaunchMode.externalApplication);
                  }
                },
              ),
            ListTile(
              leading: const Icon(Icons.translate, color: Color(0xFF1E3A8A)),
              title: Text(isTanglish ? "English-ku Maatru" : "Switch to Tanglish"),
              onTap: () {
                ref.read(languageProvider.notifier).toggleLanguage();
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.logout, color: Colors.red),
              title: Text(context.tr("logout"), style: const TextStyle(color: Colors.red)),
              onTap: () async {
                Navigator.pop(context);
                await ref.read(authNotifierProvider.notifier).signOut();
                if (context.mounted) {
                  context.go("/login");
                }
              },
            ),
          ],
        ),
      ),
      body: SafeArea(child: _screens[currentIndex]),
      bottomNavigationBar: NavigationBar(
        selectedIndex: currentIndex > 4 ? 0 : currentIndex,
        onDestinationSelected: (idx) {
          ref.read(navigationIndexProvider.notifier).setIndex(idx);
        },
        destinations: [
          NavigationDestination(
            icon: const Icon(Icons.dashboard_outlined),
            selectedIcon: const Icon(Icons.dashboard),
            label: context.tr("dashboard"),
          ),
          NavigationDestination(
            icon: const Icon(Icons.people_outline),
            selectedIcon: const Icon(Icons.people),
            label: context.tr("customers"),
          ),
          NavigationDestination(
            icon: const Icon(Icons.assignment_outlined),
            selectedIcon: const Icon(Icons.assignment),
            label: context.tr("works"),
          ),
          NavigationDestination(
            icon: const Icon(Icons.payment_outlined),
            selectedIcon: const Icon(Icons.payment),
            label: context.tr("payments"),
          ),
          NavigationDestination(
            icon: const Icon(Icons.bar_chart_outlined),
            selectedIcon: const Icon(Icons.bar_chart),
            label: context.tr("reports"),
          ),
        ],
      ),
    );
  }
}
