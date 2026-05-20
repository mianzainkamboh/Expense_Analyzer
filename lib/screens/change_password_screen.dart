import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../utils/app_constants.dart';

class ChangePasswordScreen extends StatefulWidget {
  const ChangePasswordScreen({super.key});
  @override
  State<ChangePasswordScreen> createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends State<ChangePasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _currentCtrl = TextEditingController();
  final _newCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();
  final AuthService _authService = AuthService();
  bool _loading = false;
  bool _hideCurrentPw = true;
  bool _hideNewPw = true;
  bool _hideConfirmPw = true;

  @override
  void dispose() {
    _currentCtrl.dispose();
    _newCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    try {
      await _authService.changePassword(
        currentPassword: _currentCtrl.text.trim(),
        newPassword: _newCtrl.text.trim(),
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Password updated successfully!'), backgroundColor: AppColors.success),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString()), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded, color: AppColors.textDark),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Change Password', style: TextStyle(color: AppColors.textDark, fontWeight: FontWeight.bold, fontSize: 18)),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 20),
              // Icon header
              Center(
                child: Container(
                  width: 72, height: 72,
                  decoration: BoxDecoration(color: AppColors.primaryLight, borderRadius: BorderRadius.circular(20)),
                  child: const Icon(Icons.lock_reset_rounded, color: AppColors.primary, size: 38),
                ),
              ),
              const SizedBox(height: 16),
              const Center(
                child: Text('Update your password', style: TextStyle(color: AppColors.textGrey, fontSize: 14)),
              ),
              const SizedBox(height: 32),
              Form(
                key: _formKey,
                child: Column(
                  children: [
                    // Current password
                    TextFormField(
                      controller: _currentCtrl,
                      obscureText: _hideCurrentPw,
                      decoration: _dec('Current Password', Icons.lock_outline_rounded).copyWith(
                        suffixIcon: IconButton(
                          icon: Icon(_hideCurrentPw ? Icons.visibility_off_outlined : Icons.visibility_outlined, color: AppColors.textGrey),
                          onPressed: () => setState(() => _hideCurrentPw = !_hideCurrentPw),
                        ),
                      ),
                      validator: (v) => v == null || v.isEmpty ? 'Enter current password' : null,
                    ),
                    const SizedBox(height: 16),
                    // New password
                    TextFormField(
                      controller: _newCtrl,
                      obscureText: _hideNewPw,
                      decoration: _dec('New Password', Icons.lock_rounded).copyWith(
                        suffixIcon: IconButton(
                          icon: Icon(_hideNewPw ? Icons.visibility_off_outlined : Icons.visibility_outlined, color: AppColors.textGrey),
                          onPressed: () => setState(() => _hideNewPw = !_hideNewPw),
                        ),
                      ),
                      validator: (v) {
                        if (v == null || v.isEmpty) return 'Enter new password';
                        if (v.length < 6) return 'Min 6 characters';
                        if (v == _currentCtrl.text) return 'New password must be different';
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    // Confirm new password
                    TextFormField(
                      controller: _confirmCtrl,
                      obscureText: _hideConfirmPw,
                      decoration: _dec('Confirm New Password', Icons.lock_rounded).copyWith(
                        suffixIcon: IconButton(
                          icon: Icon(_hideConfirmPw ? Icons.visibility_off_outlined : Icons.visibility_outlined, color: AppColors.textGrey),
                          onPressed: () => setState(() => _hideConfirmPw = !_hideConfirmPw),
                        ),
                      ),
                      validator: (v) => v != _newCtrl.text ? 'Passwords do not match' : null,
                    ),
                    const SizedBox(height: 32),
                    // Save button
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton(
                        onPressed: _loading ? null : _save,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          elevation: 0,
                        ),
                        child: _loading
                            ? const CircularProgressIndicator(color: Colors.white)
                            : const Text('Update Password', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.white)),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  InputDecoration _dec(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon, color: AppColors.textGrey, size: 20),
      labelStyle: const TextStyle(color: AppColors.textGrey),
      filled: true,
      fillColor: const Color(0xFFF8FAFC),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade200)),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade200)),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.primary, width: 1.5)),
    );
  }
}
