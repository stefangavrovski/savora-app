import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:savora_app/core/supabase_client.dart';
import 'package:savora_app/core/theme.dart';
import 'package:savora_app/core/router.dart';

class VerifyEmailScreen extends ConsumerStatefulWidget {
  const VerifyEmailScreen({super.key});

  @override
  ConsumerState<VerifyEmailScreen> createState() => _VerifyEmailScreenState();
}

class _VerifyEmailScreenState extends ConsumerState<VerifyEmailScreen> {
  bool _resending = false;
  bool _resent = false;

  Future<void> _resend() async {
    final email = supabase.auth.currentUser?.email ?? ref.read(pendingVerificationEmailProvider);
    if (email == null) return;
    setState(() { _resending = true; _resent = false; });

    try {
      await supabase.auth.resend(
        type: OtpType.signup,
        email: email,
      );
      if (mounted) setState(() => _resent = true);
    } on Exception catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceAll('Exception: ', '')),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _resending = false);
    }
  }

  Future<void> _signOut() async {
    // Router redirect handles navigation back to login
    await supabase.auth.signOut();
    ref.read(pendingEmailVerificationProvider.notifier).state = false;
    ref.read(pendingVerificationEmailProvider.notifier).state = null;
  }

  @override
  Widget build(BuildContext context) {
    final email = supabase.auth.currentUser?.email ?? ref.read(pendingVerificationEmailProvider) ?? 'your email';

    return Scaffold(
      backgroundColor: AppColors.surface,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 88,
                height: 88,
                decoration: BoxDecoration(
                  color: AppColors.primarySurface,
                  borderRadius: BorderRadius.circular(AppRadius.xl),
                ),
                child: const Icon(
                  Icons.mark_email_unread_outlined,
                  color: AppColors.primary,
                  size: 44,
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              Text(
                'Check your inbox',
                style: AppTextStyles.displayMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                'We sent a confirmation link to\n$email',
                style: AppTextStyles.bodyLarge
                    .copyWith(color: AppColors.textSecondary),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                'Click the link to activate your account.\nCome back here once verified.',
                style: AppTextStyles.bodyMedium
                    .copyWith(color: AppColors.textSecondary),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.xl),

              if (_resent)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md,
                    vertical: AppSpacing.sm,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.primarySurface,
                    borderRadius: BorderRadius.circular(AppRadius.md),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.check_circle_outline,
                          color: AppColors.success, size: 18),
                      const SizedBox(width: AppSpacing.sm),
                      Text(
                        'Email resent!',
                        style: AppTextStyles.bodyMedium
                            .copyWith(color: AppColors.success),
                      ),
                    ],
                  ),
                ),

              const SizedBox(height: AppSpacing.md),

              OutlinedButton(
                onPressed: _resending ? null : _resend,
                child: _resending
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Resend verification email'),
              ),
              const SizedBox(height: AppSpacing.sm),

              TextButton(
                onPressed: _signOut,
                child: Text(
                  'Sign out',
                  style: AppTextStyles.bodyMedium
                      .copyWith(color: AppColors.textSecondary),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}