import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:savora_app/core/router.dart';
import 'package:savora_app/core/theme.dart';
import 'package:savora_app/features/auth/providers/auth_provider.dart';
import 'package:savora_app/features/profile/providers/profile_provider.dart';

class SplashScreen extends ConsumerWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authStateProvider);

    authState.whenData((state) {
      final session = state.session;
      if (session == null) {
        Future.microtask(() => context.go(AppRoutes.login));
        return;
      }

      if (session.user.emailConfirmedAt == null) {
        Future.microtask(() => context.go(AppRoutes.verifyEmail));
        return;
      }

      // Load profile to determine role-based redirect
      ref.read(currentProfileProvider.future).then((profile) {
        if (!context.mounted) return;
        if (profile == null) {
          context.go(AppRoutes.login);
          return;
        }

        if (profile.isAdmin) {
          context.go(AppRoutes.adminPanel);
        } else if (profile.isBusinessOwner) {
          context.go(AppRoutes.businessDashboard);
        } else {
          context.go(AppRoutes.map);
        }
      });
    });

    return Scaffold(
      backgroundColor: AppColors.primary,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Logo placeholder — replace with your actual SVG/asset
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: AppColors.white.withOpacity(0.15),
                borderRadius: BorderRadius.circular(AppRadius.xl),
              ),
              child: const Icon(
                Icons.eco_rounded,
                color: AppColors.white,
                size: 48,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              'Savora',
              style: AppTextStyles.displayLarge.copyWith(
                color: AppColors.white,
                letterSpacing: 1.5,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Rescue food. Save money.',
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.white.withOpacity(0.8),
              ),
            ),
            const SizedBox(height: AppSpacing.xxl),
            const CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(AppColors.white),
              strokeWidth: 2,
            ),
          ],
        ),
      ),
    );
  }
}