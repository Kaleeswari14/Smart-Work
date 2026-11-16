import "package:flutter/material.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
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
  }

  @override
  void dispose() {
    _oldPasswordController.dispose();
    _nameController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _handleSave() async {
    final oldPassword = _oldPasswordController.text.trim();
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
                  context.tr("password_updated_success"),
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
      titlePadding: const EdgeInsets.fromLTRB(20, 20, 16, 8),
      contentPadding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
      title: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E3A8A).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.security, color: Color(0xFF1E3A8A), size: 24),
              ),
              const SizedBox(width: 12),
              Text(
                context.tr("profile_security"),
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          IconButton(
            icon: const Icon(Icons.close, size: 20),
            onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
          ),
        ],
      ),
      content: SizedBox(
        width: 440,
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Current User Info Card
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 20,
                        backgroundColor: const Color(0xFF1E3A8A),
                        child: Text(
                          (_nameController.text.isNotEmpty ? _nameController.text[0] : "O").toUpperCase(),
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              auth.fullName ?? "Business Owner",
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                            ),
                            Text(
                              displayEmail,
                              style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: const Color(0xFF0D9488).withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Text(
                          "OWNER",
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF0D9488),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Error message banner
                if (_errorMessage != null) ...[
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.red.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.red.shade200),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.error_outline, size: 18, color: Colors.red.shade700),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _errorMessage!,
                            style: TextStyle(fontSize: 12, color: Colors.red.shade800),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                ],

                // Step 1: Security Verification Header
                Row(
                  children: [
                    const Icon(Icons.lock, size: 16, color: Colors.orange),
                    const SizedBox(width: 6),
                    Text(
                      isTanglish ? "1. Paadhukaappu Sarippaarppu (Security Check)" : "1. Security Verification",
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.orange),
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
                    prefixIcon: const Icon(Icons.vpn_key_outlined, size: 20),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscureOldPassword ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                        size: 20,
                      ),
                      onPressed: () {
                        setState(() {
                          _obscureOldPassword = !_obscureOldPassword;
                        });
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Step 2: New Information Header
                Row(
                  children: [
                    const Icon(Icons.edit_note, size: 18, color: Color(0xFF1E3A8A)),
                    const SizedBox(width: 6),
                    Text(
                      isTanglish ? "2. Pudhiya Thagavalgal (New Credentials)" : "2. Update Information",
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF1E3A8A)),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                // Full Name / Username
                TextField(
                  controller: _nameController,
                  decoration: InputDecoration(
                    labelText: context.tr("new_username"),
                    prefixIcon: const Icon(Icons.person_outline, size: 20),
                  ),
                ),
                const SizedBox(height: 12),
                // New Password
                TextField(
                  controller: _newPasswordController,
                  obscureText: _obscureNewPassword,
                  decoration: InputDecoration(
                    labelText: context.tr("new_password"),
                    hintText: isTanglish ? "Maatra vendil type seiyavum" : "Leave blank to keep unchanged",
                    prefixIcon: const Icon(Icons.lock_outline, size: 20),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscureNewPassword ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                        size: 20,
                      ),
                      onPressed: () {
                        setState(() {
                          _obscureNewPassword = !_obscureNewPassword;
                        });
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                // Confirm New Password
                TextField(
                  controller: _confirmPasswordController,
                  obscureText: _obscureConfirmPassword,
                  decoration: InputDecoration(
                    labelText: context.tr("confirm_password"),
                    hintText: isTanglish ? "Pudhiya password retype seiyavum" : "Retype new password",
                    prefixIcon: const Icon(Icons.lock_reset, size: 20),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscureConfirmPassword ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                        size: 20,
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
      actionsPadding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
          child: Text(context.tr("cancel")),
        ),
        ElevatedButton.icon(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF1E3A8A),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
          onPressed: _isLoading ? null : _handleSave,
          icon: _isLoading
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                )
              : const Icon(Icons.save_outlined, size: 18),
          label: Text(
            _isLoading
                ? (isTanglish ? "Sarippaarkiradhu..." : "Verifying...")
                : context.tr("save"),
          ),
        ),
      ],
    );
  }
}
