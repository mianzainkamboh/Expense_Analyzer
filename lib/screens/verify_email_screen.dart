import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/auth_service.dart';
import '../utils/app_constants.dart';

class VerifyEmailScreen extends StatefulWidget {
  const VerifyEmailScreen({super.key});
  @override
  State<VerifyEmailScreen> createState() => _VerifyEmailScreenState();
}

class _VerifyEmailScreenState extends State<VerifyEmailScreen> {
  final AuthService _authService = AuthService();
  Timer? _timer;
  bool _resending = false;
  bool _checking = false;
  String _email = '';

  @override
  void initState() {
    super.initState();
    _email = FirebaseAuth.instance.currentUser?.email ?? '';
    // Poll every 4 seconds to check if email is verified
    _timer = Timer.periodic(const Duration(seconds: 4), (_) => _checkVerified());
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _checkVerified() async {
    if (_checking) return;
    setState(() => _checking = true);
    try {
      await FirebaseAuth.instance.currentUser?.reload();
      final user = FirebaseAuth.instance.currentUser;
      if (user != null && user.emailVerified) {
        _timer?.cancel();
        if (mounted) Navigator.pushReplacementNamed(context, '/login');
      }
    } catch (_) {}
    if (mounted) setState(() => _checking = false);
  }

  Future<void> _resend() async {
    setState(() => _resending = true);
    try {
      await _authService.resendVerificationEmail();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Verification email sent!'), backgroundColor: AppColors.success),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString()), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _resending = false);
    }
  }

  Future<void> _cancel() async {
    await _authService.signOut();
    if (mounted) Navigator.pushReplacementNamed(context, '/login');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Icon
              Container(
                width: 90, height: 90,
                decoration: BoxDecoration(
                  color: AppColors.primaryLight,
                  borderRadius: BorderRadius.circular(24),
                ),
                child: const Icon(Icons.mark_email_unread_rounded, color: AppColors.primary, size: 48),
              ),
              const SizedBox(height: 28),
              const Text(
                'Verify Your Email',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppColors.textDark),
              ),
              const SizedBox(height: 12),
              Text(
                'We sent a verification link to',
                style: const TextStyle(color: AppColors.textGrey, fontSize: 14),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 4),
              Text(
                _email,
                style: const TextStyle(color: AppColors.primary, fontSize: 15, fontWeight: FontWeight.w600),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              const Text(
                'Please check your inbox and click the link to activate your account.',
                style: TextStyle(color: AppColors.textGrey, fontSize: 13),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),

              // Auto-checking indicator
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(
                    width: 16, height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: _checking ? AppColors.primary : AppColors.textLight,
                    ),
                  ),
                  const SizedBox(width: 10),
                  const Text('Waiting for verification...', style: TextStyle(color: AppColors.textGrey, fontSize: 13)),
                ],
              ),
              const SizedBox(height: 32),

              // Resend button
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: _resending ? null : _resend,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    elevation: 0,
                  ),
                  child: _resending
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text('Resend Email', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Colors.white)),
                ),
              ),
              const SizedBox(height: 12),

              // Already verified / go back
              SizedBox(
                width: double.infinity,
                height: 52,
                child: OutlinedButton(
                  onPressed: _checkVerified,
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: AppColors.primary),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  child: const Text("I've Verified", style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.primary)),
                ),
              ),
              const SizedBox(height: 12),

              TextButton(
                onPressed: _cancel,
                child: const Text('Back to Login', style: TextStyle(color: AppColors.textGrey, fontSize: 13)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
