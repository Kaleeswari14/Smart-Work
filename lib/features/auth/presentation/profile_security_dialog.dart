import "package:flutter/material.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:shared_preferences/shared_preferences.dart";
import "../../../core/localization/app_localizations.dart";
import "../../../core/localization/language_provider.dart";
import "auth_provider.dart";

class ProfileSecurityDialog extends ConsumerStatefulWidget {
  const ProfileSecurityDialog({super.key});

  static Future<void> show(BuildContext context) {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => const ProfileSecurityDialog(),
    );
  }

  @override
  ConsumerState<ProfileSecurityDialog> createState() => _ProfileSecurityDialogState();
}

class _ProfileSecurityDialogState extends ConsumerState<ProfileSecurityDialog> {
  final _formKey = GlobalKey<FormState>();
  final _oldPasswordController = TextEditingController();
  final _usernameController = TextEditingController();
  final _nameController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _obscureOldPassword = true;
  bool _obscureNewPassword = true;
  bool _obscureConfirmPassword = true;
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    final auth = ref.read(authNotifierProvider);
    _nameController.text = auth.fullName ?? "Business Owner";
    _loadCustomUsername();
  }

  Future<void> _loadCustomUsername() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final username = prefs.getString("custom_admin_username") ?? "admin";
      if (mounted) {
        setState(() {
          _usernameController.text = username;
        });
      }
    } catch (_) {}
  }

  @override
  void dispose() {
    _oldPasswordController.dispose();
    _usernameController.dispose();
    _nameController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _handleSave() async {
    final oldPassword = _oldPasswordController.text.trim();
    final newUsername = _usernameController.text.trim();
    final newName = _nameController.text.trim();
    final newPassword = _newPasswordController.text.trim();
    final confirmPassword = _confirmPasswordController.text.trim();
    final isTanglish = ref.read(languageProvider).languageCode == "ta";

    setState(() {
      _errorMessage = null;
    });

    if (oldPassword.isEmpty) {
      setState(() {
        _errorMessage = isTanglish
            ? "Pazhaya password enter seiyavum! (Enter current password to verify)."
            : "Please enter your current/old password to verify identity.";
      });
      return;
    }

    if (newPassword.isNotEmpty) {
      if (newPassword.length < 6) {
        setState(() {
          _errorMessage = context.tr("password_length_error");
        });
        return;
      }
      if (newPassword != confirmPassword) {
        setState(() {
          _errorMessage = context.tr("password_match_error");
        });
        return;
      }
    }

    setState(() {
      _isLoading = true;
    });

    final result = await ref.read(authNotifierProvider.notifier).verifyAndChangeCredentials(
          oldPassword: oldPassword,
          newUsername: newUsername.isNotEmpty ? newUsername : null,
          newPassword: newPassword.isNotEmpty ? newPassword : null,
          newFullName: newName.isNotEmpty ? newName : null,
        );

    if (!mounted) return;

    setState(() {
      _isLoading = false;
    });

    if (result.success) {
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle, color: Colors.white, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  isTanglish
                      ? "Username, Password & Profile vetrigaramaaga maatrapattadhu!"
                      : "Username, Password & Profile updated successfully!",
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          backgroundColor: Colors.green.shade700,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
    } else {
      setState(() {
        if (result.message.contains("Incorrect old password")) {
          _errorMessage = context.tr("old_password_error");
        } else {
          _errorMessage = result.message;
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authNotifierProvider);
    final displayEmail = auth.email ?? "admin@smart.com";
    final isTanglish = ref.watch(languageProvider).languageCode == "ta";

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 20),
      titlePadding: const EdgeInsets.fromLTRB(18, 18, 14, 6),
      contentPadding: const EdgeInsets.fromLTRB(18, 6, 18, 12),
      title: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(7),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E3A8A).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.security, color: Color(0xFF1E3A8A), size: 22),
              ),
              const SizedBox(width: 10),
              Text(
                context.tr("profile_security"),
                style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          IconButton(
            icon: const Icon(Icons.close, size: 20),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
            onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
          ),
        ],
      ),
      content: SizedBox(
        width: 420,
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Current User Info Card
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 18,
                        backgroundColor: const Color(0xFF1E3A8A),
                        child: Text(
                          (_nameController.text.isNotEmpty ? _nameController.text[0] : "O").toUpperCase(),
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              auth.fullName ?? "Business Owner",
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                            ),
                            Text(
                              displayEmail,
                              style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFF0D9488).withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Text(
                          "OWNER",
                          style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF0D9488),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),

                // Error message banner
                if (_errorMessage != null) ...[
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.red.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.red.shade200),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.error_outline, size: 16, color: Colors.red.shade700),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            _errorMessage!,
                            style: TextStyle(fontSize: 11, color: Colors.red.shade800),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),
                ],

                // Step 1: Security Verification Header
                Row(
                  children: [
                    const Icon(Icons.lock, size: 15, color: Colors.orange),
                    const SizedBox(width: 6),
                    Text(
                      isTanglish ? "1. Paadhukaappu Sarippaarppu (Security Check)" : "1. Security Verification",
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.orange),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                TextField(
                  controller: _oldPasswordController,
                  obscureText: _obscureOldPassword,
                  decoration: InputDecoration(
                    labelText: context.tr("old_password"),
                    hintText: context.tr("enter_old_password_prompt"),
                    prefixIcon: const Icon(Icons.vpn_key_outlined, size: 18),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscureOldPassword ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                        size: 18,
                      ),
                      onPressed: () {
                        setState(() {
                          _obscureOldPassword = !_obscureOldPassword;
                        });
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 14),

                // Step 2: New Information Header
                Row(
                  children: [
                    const Icon(Icons.edit_note, size: 17, color: Color(0xFF1E3A8A)),
                    const SizedBox(width: 6),
                    Text(
                      isTanglish ? "2. Pudhiya Thagavalgal (New Credentials)" : "2. Update Information",
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF1E3A8A)),
                    ),
                  ],
                ),
                const SizedBox(height: 6),

                // Login Username
                TextField(
                  controller: _usernameController,
                  decoration: InputDecoration(
                    labelText: context.tr("login_username"),
                    hintText: "e.g. admin or owner",
                    prefixIcon: const Icon(Icons.account_circle_outlined, size: 18),
                    helperText: isTanglish ? "Login seiyum username (e.g. admin)" : "Username used to log into app",
                    helperMaxLines: 1,
                  ),
                ),
                const SizedBox(height: 10),

                // Owner Display Name
                TextField(
                  controller: _nameController,
                  decoration: InputDecoration(
                    labelText: context.tr("new_username"),
                    hintText: "e.g. Business Owner",
                    prefixIcon: const Icon(Icons.badge_outlined, size: 18),
                  ),
                ),
                const SizedBox(height: 10),

                // New Password
                TextField(
                  controller: _newPasswordController,
                  obscureText: _obscureNewPassword,
                  decoration: InputDecoration(
                    labelText: context.tr("new_password"),
                    hintText: isTanglish ? "Pudhiya password (optional)" : "Leave blank to keep unchanged",
                    prefixIcon: const Icon(Icons.lock_outline, size: 18),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscureNewPassword ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                        size: 18,
                      ),
                      onPressed: () {
                        setState(() {
                          _obscureNewPassword = !_obscureNewPassword;
                        });
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 10),

                // Confirm New Password
                TextField(
                  controller: _confirmPasswordController,
                  obscureText: _obscureConfirmPassword,
                  decoration: InputDecoration(
                    labelText: context.tr("confirm_password"),
                    hintText: isTanglish ? "Pudhiya password retype" : "Retype new password",
                    prefixIcon: const Icon(Icons.lock_reset, size: 18),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscureConfirmPassword ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                        size: 18,
                      ),
                      onPressed: () {
                        setState(() {
                          _obscureConfirmPassword = !_obscureConfirmPassword;
                        });
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      actions: [
        Wrap(
          spacing: 8,
          runSpacing: 8,
          alignment: WrapAlignment.end,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            TextButton(
              onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
              child: Text(context.tr("cancel")),
            ),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1E3A8A),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              onPressed: _isLoading ? null : _handleSave,
              icon: _isLoading
                  ? const SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : const Icon(Icons.save_outlined, size: 16),
              label: Text(
                _isLoading
                    ? (isTanglish ? "Sarippaarkiradhu..." : "Saving...")
                    : context.tr("save"),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

