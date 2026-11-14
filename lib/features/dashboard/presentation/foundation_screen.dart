import "package:flutter/material.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "../../../core/localization/app_localizations.dart";
import "../../../core/localization/language_provider.dart";

class FoundationScreen extends ConsumerWidget {
  const FoundationScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentLocale = ref.watch(languageProvider);
    final isTanglish = currentLocale.languageCode == "ta";

    return Scaffold(
      appBar: AppBar(
        title: Text(context.tr("app_title")),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: TextButton.icon(
              style: TextButton.styleFrom(
                foregroundColor: Colors.white,
                backgroundColor: Colors.white.withValues(alpha: 0.15),
              ),
              icon: const Icon(Icons.language, size: 18),
              label: Text(
                isTanglish ? "English" : "Tanglish",
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              onPressed: () {
                ref.read(languageProvider.notifier).toggleLanguage();
              },
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Hero Banner
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF1E3A8A), Color(0xFF0D9488)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      context.tr("app_title"),
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      context.tr("tagline"),
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.white70,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        "${context.tr("current_language")}: ${currentLocale.languageCode.toUpperCase()}",
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Architecture Verification Cards
              Text(
                context.tr("architecture_verified"),
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),

              _buildStatusCard(
                icon: Icons.check_circle_outline,
                title: context.tr("riverpod_status"),
                color: Colors.indigo,
              ),
              const SizedBox(height: 8),

              _buildStatusCard(
                icon: Icons.alt_route,
                title: context.tr("router_status"),
                color: Colors.teal,
              ),
              const SizedBox(height: 8),

              _buildStatusCard(
                icon: Icons.palette_outlined,
                title: context.tr("theme_status"),
                color: Colors.deepPurple,
              ),
              const SizedBox(height: 8),

              _buildStatusCard(
                icon: Icons.translate,
                title: context.tr("localization_status"),
                color: Colors.amber.shade800,
              ),

              const SizedBox(height: 24),

              // Empty State Banner (No Fake Data)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.blueGrey.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.blueGrey.shade200),
                ),
                child: Row(
                  children: [
                    Icon(Icons.shield_outlined, color: Colors.blueGrey.shade700, size: 28),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        context.tr("empty_state_msg"),
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.blueGrey.shade800,
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Action button to test reactivity
              ElevatedButton.icon(
                icon: const Icon(Icons.swap_horiz),
                label: Text(context.tr("language_toggle")),
                onPressed: () {
                  ref.read(languageProvider.notifier).toggleLanguage();
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusCard({
    required IconData icon,
    required String title,
    required Color color,
  }) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: BorderSide(color: Colors.grey.shade300),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(
          children: [
            Icon(icon, color: color, size: 22),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
