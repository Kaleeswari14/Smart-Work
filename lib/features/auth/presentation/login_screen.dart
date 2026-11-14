import "package:flutter/foundation.dart";
import "package:flutter/material.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:go_router/go_router.dart";
import "package:url_launcher/url_launcher.dart";
import "../../../core/localization/app_localizations.dart";
import "../../../core/localization/language_provider.dart";
import "auth_provider.dart";

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _emailController = TextEditingController(text: "admin@smart.com");
  final _passwordController = TextEditingController(text: "admin@1407");
  final _nameController = TextEditingController();
  bool _obscurePassword = true;
  bool _isSignUpMode = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _handleAuth() async {
    final email = _emailController.text.trim().isEmpty ? "admin@smart.com" : _emailController.text.trim();
    final password = _passwordController.text.trim().isEmpty ? "admin@1407" : _passwordController.text.trim();
    final isTanglish = ref.read(languageProvider).languageCode == "ta";

    final authNotifier = ref.read(authNotifierProvider.notifier);
    bool success = false;

    if (_isSignUpMode) {
      final name = _nameController.text.trim().isEmpty ? "Business Owner" : _nameController.text.trim();
      success = await authNotifier.signUp(
        email: email,
        password: password,
        fullName: name,
      );
    } else {
      success = await authNotifier.signIn(
        email: email,
        password: password,
      );
    }

    if (!mounted) return;

    if (success) {
      context.go("/dashboard");
    } else {
      final err = ref.read(authNotifierProvider).errorMessage ?? "Authentication error";
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            isTanglish ? "Login error: $err" : err,
          ),
          backgroundColor: Colors.red.shade700,
        ),
      );
    }
  }

  void _showForgotPasswordDialog() {
    final isTanglish = ref.read(languageProvider).languageCode == "ta";
    final resetEmailController = TextEditingController(text: _emailController.text);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(isTanglish ? "Password Reset" : "Reset Password"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              isTanglish
                  ? "Unga registered email-kku password reset link anuppapadum."
                  : "A password reset link will be sent to your registered email.",
              style: const TextStyle(fontSize: 13),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: resetEmailController,
              decoration: const InputDecoration(
                labelText: "Email",
                prefixIcon: Icon(Icons.email_outlined),
              ),
              keyboardType: TextInputType.emailAddress,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(context.tr("cancel")),
          ),
          ElevatedButton(
            onPressed: () async {
              final email = resetEmailController.text.trim();
              if (email.isNotEmpty) {
                Navigator.pop(ctx);
                final sent = await ref.read(authNotifierProvider.notifier).resetPassword(email);
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        sent
                            ? (isTanglish ? "Reset link anupiyachu!" : "Reset email sent!")
                            : (isTanglish ? "Email anuppuvadheeril thavaru." : "Failed to send reset email."),
                      ),
                    ),
                  );
                }
              }
            },
            child: Text(isTanglish ? "Send Link" : "Send Reset Link"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isTanglish = ref.watch(languageProvider).languageCode == "ta";
    final authState = ref.watch(authNotifierProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(context.tr("app_title")),
        actions: [
          TextButton.icon(
            style: TextButton.styleFrom(
              foregroundColor: Colors.white,
              backgroundColor: Colors.white.withValues(alpha: 0.15),
            ),
            icon: const Icon(Icons.language, size: 16),
            label: Text(
              isTanglish ? "English" : "Tanglish",
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
            ),
            onPressed: () {
              ref.read(languageProvider.notifier).toggleLanguage();
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Card(
              elevation: 3,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Brand Icon
                    Center(
                      child: Container(
                        width: 76,
                        height: 76,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.08),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: ClipOval(
                          child: Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Image.asset(
                              "assets/images/smartiva_logo.png",
                              fit: BoxFit.contain,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Owner Portal Tag
                    Center(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFF0D9488).withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.verified_user, size: 14, color: Color(0xFF0D9488)),
                            const SizedBox(width: 6),
                            Text(
                              isTanglish ? "OWNER PORTAL - FULL ACCESS" : "OWNER PORTAL - FULL ACCESS",
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF0D9488),
                                letterSpacing: 0.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    Text(
                      _isSignUpMode
                          ? (isTanglish ? "Owner Account Uruvaakkunga" : "Create Master Account")
                          : context.tr("login_title"),
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      _isSignUpMode
                          ? (isTanglish ? "Unga puthiya business account setup seiyavum" : "Set up your business master login")
                          : context.tr("login_subtitle"),
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
                    ),
                    const SizedBox(height: 24),

                    // Full Name Input (Only on Sign Up)
                    if (_isSignUpMode) ...[
                      TextField(
                        controller: _nameController,
                        decoration: InputDecoration(
                          labelText: isTanglish ? "Unga Peyar / Company" : "Your Name / Company",
                          prefixIcon: const Icon(Icons.badge_outlined),
                        ),
                      ),
                      const SizedBox(height: 14),
                    ],

                    // Email Input
                    TextField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      decoration: InputDecoration(
                        labelText: context.tr("username_label"),
                        prefixIcon: const Icon(Icons.email_outlined),
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Password Input
                    TextField(
                      controller: _passwordController,
                      obscureText: _obscurePassword,
                      decoration: InputDecoration(
                        labelText: context.tr("password_label"),
                        prefixIcon: const Icon(Icons.lock_outline),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscurePassword ? Icons.visibility_off : Icons.visibility,
                          ),
                          onPressed: () {
                            setState(() {
                              _obscurePassword = !_obscurePassword;
                            });
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),

                    // Forgot Password (in sign in mode)
                    if (!_isSignUpMode)
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                          onPressed: _showForgotPasswordDialog,
                          child: Text(
                            context.tr("forgot_password"),
                            style: const TextStyle(fontSize: 12),
                          ),
                        ),
                      ),
                    const SizedBox(height: 16),

                    // Sign In / Sign Up Button
                    ElevatedButton(
                      onPressed: authState.isLoading ? null : _handleAuth,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      child: authState.isLoading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                            )
                          : Text(
                              _isSignUpMode
                                  ? (isTanglish ? "Account Uruvaakku" : "Create Master Account")
                                  : context.tr("login_button"),
                              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                            ),
                    ),
                    const SizedBox(height: 16),

                    // Mode Switcher Link
                    Center(
                      child: TextButton(
                        onPressed: () {
                          setState(() {
                            _isSignUpMode = !_isSignUpMode;
                          });
                        },
                        child: Text(
                          _isSignUpMode
                              ? (isTanglish ? "Already account irukka? Login seiyavum" : "Already have an account? Sign In")
                              : (isTanglish ? "Puthiya Owner Account-a? Sign Up seiyavum" : "First time? Create Master Owner Account"),
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                        ),
                      ),
                    ),

                    if (kIsWeb) ...[
                      const SizedBox(height: 12),
                      const Divider(height: 20),
                      OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                          side: BorderSide(color: Colors.green.shade600),
                          foregroundColor: Colors.green.shade800,
                          backgroundColor: Colors.green.shade50.withValues(alpha: 0.5),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        icon: const Icon(Icons.android, color: Colors.green, size: 22),
                        label: Text(
                          context.tr("download_apk"),
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                        ),
                        onPressed: _downloadApk,
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _downloadApk() async {
    final uri = Uri.parse("smartiva.apk");
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }
}
