import "package:flutter/foundation.dart";
import "package:flutter/material.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:go_router/go_router.dart";
import "package:url_launcher/url_launcher.dart";
import "../../../core/localization/app_localizations.dart";
import "../../../core/localization/language_provider.dart";
import "../../auth/presentation/auth_provider.dart";
import "../../auth/presentation/profile_security_dialog.dart";

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  void _showLogoutConfirmation(BuildContext context, WidgetRef ref) {
    final isTanglish = ref.read(languageProvider).languageCode == "ta";

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(isTanglish ? "Logout Seiyalama?" : "Confirm Logout"),
        content: Text(
          isTanglish
              ? "Unga session end aagi login page-kku pogum. Nichayamaaga logout seiya venduma?"
              : "Are you sure you want to log out of your Business Owner account?",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(context.tr("cancel")),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.shade700,
              foregroundColor: Colors.white,
            ),
            onPressed: () async {
              Navigator.pop(ctx);
              await ref.read(authNotifierProvider.notifier).signOut();
              if (context.mounted) {
                context.go("/login");
              }
            },
            child: Text(context.tr("logout")),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentLocale = ref.watch(languageProvider);
    final isTanglish = currentLocale.languageCode == "ta";
    final authState = ref.watch(authNotifierProvider);

    final displayName = authState.fullName ?? "Business Owner";
    final displayEmail = authState.email ?? "owner@business.com";

    return ListView(
      padding: const EdgeInsets.all(16.0),
      children: [
        // User Profile Section
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 28,
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  child: const Icon(Icons.admin_panel_settings, color: Colors.white, size: 30),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        displayName,
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        displayEmail,
                        style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                      ),
                      const SizedBox(height: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFF0D9488).withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          isTanglish ? "OWNER - FULL ACCESS" : "OWNER - FULL ACCESS",
                          style: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF0D9488),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton.filledTonal(
                  icon: const Icon(Icons.edit_outlined, size: 20),
                  tooltip: context.tr("profile_security"),
                  onPressed: () => ProfileSecurityDialog.show(context),
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 20),

        // Preferences Section
        Text(
          context.tr("preferences"),
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.grey),
        ),
        const SizedBox(height: 8),

        Card(
          child: Column(
            children: [
              // Language Toggle Tile
              ListTile(
                leading: const Icon(Icons.translate, color: Color(0xFF1E3A8A)),
                title: Text(context.tr("language_preference")),
                subtitle: Text(
                  isTanglish ? "Tanglish (Tamil script in English)" : "English",
                ),
                trailing: Switch(
                  value: isTanglish,
                  onChanged: (val) {
                    ref.read(languageProvider.notifier).toggleLanguage();
                  },
                ),
              ),
              const Divider(height: 1),
              // Theme Mode Preview
              ListTile(
                leading: const Icon(Icons.palette_outlined, color: Colors.deepPurple),
                title: Text(context.tr("theme_mode")),
                subtitle: Text(context.tr("theme_light")),
                trailing: const Icon(Icons.check, color: Color(0xFF0D9488)),
              ),
            ],
          ),
        ),

        const SizedBox(height: 20),

        // App Info Section
        Card(
          child: Column(
            children: [
              ListTile(
                leading: const Icon(Icons.info_outline, color: Colors.blueGrey),
                title: Text(context.tr("app_title")),
                subtitle: Text(context.tr("app_version")),
              ),
              const Divider(height: 1),
              ListTile(
                leading: const Icon(Icons.history, color: Colors.teal),
                title: Text(context.tr("customer_history_title")),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => context.push("/history"),
              ),
              if (kIsWeb) ...[
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.android, color: Colors.green),
                  title: Text(context.tr("download_apk")),
                  subtitle: Text(context.tr("download_apk_desc")),
                  trailing: const Icon(Icons.download, color: Colors.green),
                  onTap: () async {
                    final uri = Uri.parse("smartiva.apk");
                    if (await canLaunchUrl(uri)) {
                      await launchUrl(uri, mode: LaunchMode.externalApplication);
                    }
                  },
                ),
              ],
            ],
          ),
        ),

        const SizedBox(height: 24),

        // Logout Button
        OutlinedButton.icon(
          style: OutlinedButton.styleFrom(
            foregroundColor: Colors.red.shade700,
            side: BorderSide(color: Colors.red.shade300),
            padding: const EdgeInsets.symmetric(vertical: 14),
          ),
          icon: const Icon(Icons.logout),
          label: Text(context.tr("logout")),
          onPressed: () => _showLogoutConfirmation(context, ref),
        ),
      ],
    );
  }
}
