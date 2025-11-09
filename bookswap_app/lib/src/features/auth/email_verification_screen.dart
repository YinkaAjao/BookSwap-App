import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/providers/providers.dart';
import '../../core/theme/app_theme.dart';

class EmailVerificationScreen extends ConsumerStatefulWidget {
  const EmailVerificationScreen({super.key});

  @override
  ConsumerState<EmailVerificationScreen> createState() => _EmailVerificationScreenState();
}

class _EmailVerificationScreenState extends ConsumerState<EmailVerificationScreen> {
  bool _isLoading = false;
  bool _emailSent = false;
  String? _errorMessage;

  Future<void> _resendVerification() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final authService = ref.read(authServiceProvider);
      await authService.resendVerificationEmail();
      
      setState(() {
        _emailSent = true;
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Verification email sent!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      setState(() {
        _errorMessage = e.toString().contains('AuthException') 
            ? e.toString().split(': ')[1] 
            : 'Failed to send verification email.';
      });
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _checkVerification() async {
    setState(() => _isLoading = true);
    
    try {
      final user = ref.read(authServiceProvider).currentUser;
      if (user != null) {
        await user.reload();
        final refreshedUser = ref.read(authServiceProvider).currentUser;
        
        if (refreshedUser?.emailVerified == true && mounted) {
          // Verification successful - user will be automatically navigated via authStateProvider
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Email verified successfully!'),
              backgroundColor: Colors.green,
            ),
          );
        } else {
          setState(() {
            _errorMessage = 'Email not verified yet. Please check your inbox.';
          });
        }
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error checking verification status.';
      });
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _signOut() async {
    try {
      await ref.read(authServiceProvider).signOut();
    } catch (e) {
      // Ignore errors during sign out from verification screen
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = ref.watch(unverifiedAuthStateProvider).value;
    
    return Scaffold(
      backgroundColor: AppColors.surfaceLight,
      appBar: AppBar(
        title: const Text('Verify Your Email'),
        backgroundColor: AppColors.primaryDark,
        foregroundColor: AppColors.primaryAccent,
        actions: [
          TextButton(
            onPressed: _signOut,
            child: const Text(
              'Sign Out',
              style: TextStyle(color: AppColors.primaryAccent),
            ),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.email_outlined,
              size: 80,
              color: AppColors.primaryAccent,
            ),
            const SizedBox(height: 24),
            Text(
              'Verify Your Email Address',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: AppColors.textDark,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Text(
              'We\'ve sent a verification email to:',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: AppColors.textDark,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              currentUser?.email ?? '',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: AppColors.textDark,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            Text(
              'Please check your email and click the verification link to continue.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppColors.textLight,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'If you don\'t see the email, check your spam folder.',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppColors.textLight,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            
            if (_errorMessage != null) ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.errorRed.withAlpha(25),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.errorRed),
                ),
                child: Text(
                  _errorMessage!,
                  style: TextStyle(color: AppColors.errorRed),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 16),
            ],
            
            if (_emailSent) ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.successGreen.withAlpha(25),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.successGreen),
                ),
                child: Text(
                  'Verification email sent! Please check your inbox.',
                  style: TextStyle(color: AppColors.successGreen),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 16),
            ],
            
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _checkVerification,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryAccent,
                  foregroundColor: AppColors.textDark,
                ),
                child: _isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('I\'ve Verified My Email'),
              ),
            ),
            const SizedBox(height: 16),
            TextButton(
              onPressed: _isLoading ? null : _resendVerification,
              child: Text(
                'Resend Verification Email',
                style: TextStyle(color: AppColors.primaryAccent),
              ),
            ),
          ],
        ),
      ),
    );
  }
}