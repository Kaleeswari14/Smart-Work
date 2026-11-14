import "package:flutter/material.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:shared_preferences/shared_preferences.dart";

final languageProvider = NotifierProvider<LanguageNotifier, Locale>(() => LanguageNotifier());

class LanguageNotifier extends Notifier<Locale> {
  static const String _prefKey = "app_language_code";

  @override
  Locale build() {
    _loadSavedLanguage();
    return const Locale("en");
  }

  Future<void> _loadSavedLanguage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final code = prefs.getString(_prefKey) ?? "en";
      state = Locale(code);
    } catch (_) {}
  }

  Future<void> toggleLanguage() async {
    final newCode = state.languageCode == "en" ? "ta" : "en";
    state = Locale(newCode);
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_prefKey, newCode);
    } catch (_) {}
  }

  Future<void> setLanguage(String code) async {
    if (code == "en" || code == "ta") {
      state = Locale(code);
      try {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(_prefKey, code);
      } catch (_) {}
    }
  }
}
