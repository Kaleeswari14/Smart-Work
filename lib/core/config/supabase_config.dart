import "package:flutter/foundation.dart";
import "package:supabase_flutter/supabase_flutter.dart";

class SupabaseConfig {
  /// Supabase Project URL (From Supabase Dashboard -> Project Settings -> API)
  static const String supabaseUrl = String.fromEnvironment(
    "SUPABASE_URL",
    defaultValue: "https://gaeslqajpvgyfbfnmfze.supabase.co",
  );

  /// Supabase Anonymous Public Key
  static const String supabaseAnonKey = String.fromEnvironment(
    "SUPABASE_ANON_KEY",
    defaultValue: "sb_publishable_5Vhhjoo2B5gX7bjjmQ34VA_v4Ih-UIv",
  );

  /// Helper flag to know if production credentials are set
  static bool get isConfigured =>
      supabaseUrl != "https://your-project-id.supabase.co" &&
      supabaseAnonKey != "your-anon-key-here" &&
      supabaseUrl.isNotEmpty &&
      supabaseAnonKey.isNotEmpty;

  /// Safe initializer for Supabase client
  static Future<void> initialize() async {
    if (!isConfigured) {
      debugPrint("ℹ️ Supabase credentials pending. Running seamlessly in local development mode.");
      return;
    }

    try {
      await Supabase.initialize(
        url: supabaseUrl,
        anonKey: supabaseAnonKey,
      );
      debugPrint("✅ Supabase successfully connected to: $supabaseUrl");
    } catch (e) {
      debugPrint("⚠️ Supabase initialization note: $e");
    }
  }

  /// Safe accessor to the client
  static SupabaseClient? get client {
    if (isConfigured) {
      try {
        return Supabase.instance.client;
      } catch (_) {
        return null;
      }
    }
    return null;
  }
}
