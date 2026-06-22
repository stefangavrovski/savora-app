import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:savora_app/core/router.dart';
import 'package:savora_app/core/supabase_client.dart';
import 'package:savora_app/core/theme.dart';
import 'package:image_picker/image_picker.dart';
import 'package:savora_app/features/business/models/business.dart';
import 'package:savora_app/features/business/providers/business_provider.dart';

class BusinessDashboardScreen extends ConsumerWidget {
  const BusinessDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final businessAsync = ref.watch(myBusinessProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await supabase.auth.signOut();
              if (context.mounted) context.go(AppRoutes.login);
            },
          ),
        ],
      ),
      body: businessAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (business) {
          if (business == null) {
            return _NoBusinessView(
              onStart: () => context.push(AppRoutes.businessOnboarding),
            );
          }

          if (!business.isApproved) {
            return _VerificationPendingView(business: business);
          }

          return _ActiveDashboard(business: business);
        },
      ),
    );
  }
}

class _NoBusinessView extends StatelessWidget {
  final VoidCallback onStart;
  const _NoBusinessView({required this.onStart});

  @override
  Widget build(BuildContext context) {
    return Padding(
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
            child: const Icon(Icons.storefront_outlined,
                color: AppColors.primary, size: 48),
          ),
          const SizedBox(height: AppSpacing.lg),
          Text('Register your business',
              style: AppTextStyles.displayMedium, textAlign: TextAlign.center),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Start listing surplus bags and reduce food waste in Tetovo.',
            style: AppTextStyles.bodyLarge
                .copyWith(color: AppColors.textSecondary),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.xl),
          ElevatedButton(
            onPressed: onStart,
            child: const Text('Get Started'),
          ),
        ],
      ),
    );
  }
}

class _VerificationPendingView extends StatelessWidget {
  final Business business;
  const _VerificationPendingView({required this.business});

  @override
  Widget build(BuildContext context) {
    final isPending = business.isPending;
    final isRejected = business.isRejected;

    return Padding(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 88,
            height: 88,
            decoration: BoxDecoration(
              color: isRejected
                  ? AppColors.error.withValues(alpha: 0.1)
                  : AppColors.primarySurface,
              borderRadius: BorderRadius.circular(AppRadius.xl),
            ),
            child: Icon(
              isRejected
                  ? Icons.cancel_outlined
                  : Icons.hourglass_empty_rounded,
              color: isRejected ? AppColors.error : AppColors.primary,
              size: 48,
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          Text(
            isRejected
                ? 'Application Not Approved'
                : 'Application Under Review',
            style: AppTextStyles.displayMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            isRejected
                ? 'Your application for ${business.name} was not approved. Please contact support for details.'
                : 'Your application for ${business.name} is being reviewed. You\'ll be notified once approved.',
            style: AppTextStyles.bodyLarge
                .copyWith(color: AppColors.textSecondary),
            textAlign: TextAlign.center,
          ),
          if (isPending) ...[
            const SizedBox(height: AppSpacing.xl),
            Container(
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: AppColors.warning.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(AppRadius.lg),
                border: Border.all(color: AppColors.warning.withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline,
                      color: AppColors.warning, size: 18),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Text(
                      'Review typically takes 1–2 business days.',
                      style: AppTextStyles.bodySmall
                          .copyWith(color: AppColors.warning),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _ActiveDashboard extends ConsumerWidget {
  final Business business;
  const _ActiveDashboard({required this.business});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return RefreshIndicator(
      onRefresh: () async => ref.invalidate(myBusinessProvider),
      child: ListView(
        padding: const EdgeInsets.all(AppSpacing.md),
        children: [
          Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.circular(AppRadius.xl),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    GestureDetector(
                      onTap: () async {
                        final picker = ImagePicker();
                        final image = await picker.pickImage(
                            source: ImageSource.gallery,
                            imageQuality: 80,
                            maxWidth: 600);
                        if (image == null) return;

                        final bytes = await image.readAsBytes();
                        final ext = image.name.split('.').last;

                        await ref.read(logoUploadProvider.notifier).uploadLogo(
                              businessId: business.id,
                              bytes: bytes,
                              extension: ext,
                              oldLogoUrl: business.logoUrl,
                            );
                      },
                      child: Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: AppColors.white.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(AppRadius.md),
                        ),
                        child: business.logoUrl != null
                            ? ClipRRect(
                                borderRadius:
                                    BorderRadius.circular(AppRadius.md),
                                child: Image.network(business.logoUrl!,
                                    fit: BoxFit.cover),
                              )
                            : const Icon(Icons.storefront,
                                color: AppColors.white, size: 28),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            business.name,
                            style: AppTextStyles.titleLarge
                                .copyWith(color: AppColors.white),
                          ),
                          Text(
                            business.categoryLabel,
                            style: AppTextStyles.bodySmall.copyWith(
                                color: AppColors.white.withValues(alpha: 0.8)),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.sm, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.success.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(AppRadius.full),
                      ),
                      child: Text(
                        'Verified',
                        style: AppTextStyles.bodySmall.copyWith(
                            color: AppColors.white,
                            fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  business.address,
                  style: AppTextStyles.bodySmall
                      .copyWith(color: AppColors.white.withValues(alpha: 0.8)),
                ),
              ],
            ),
          ),

          const SizedBox(height: AppSpacing.lg),
          Text('Actions', style: AppTextStyles.titleMedium),
          const SizedBox(height: AppSpacing.sm),

          _ActionTile(
            icon: Icons.add_box_outlined,
            title: 'Create New Listing',
            subtitle: 'Post a new surprise bag for today',
            color: AppColors.primary,
            onTap: () => context.push(AppRoutes.createListing),
          ),
          const SizedBox(height: AppSpacing.sm),

          _ActionTile(
            icon: Icons.inventory_2_outlined,
            title: 'My Listings',
            subtitle: 'View and manage your active bags',
            color: AppColors.info,
            onTap: () => context.push(AppRoutes.myListings),
          ),
          const SizedBox(height: AppSpacing.sm),

          _ActionTile(
            icon: Icons.qr_code_scanner_outlined,
            title: 'Pickup Counter',
            subtitle: 'Scan or type customer pickup codes',
            color: AppColors.accent,
            onTap: () => context.push(AppRoutes.pickupCounter),
          ),
          const SizedBox(height: AppSpacing.sm),

          _ActionTile(
            icon: Icons.receipt_long_outlined,
            title: 'Reservations',
            subtitle: 'See all incoming reservations',
            color: AppColors.success,
            onTap: () => context.push(AppRoutes.businessReservations),
          ),
          const SizedBox(height: AppSpacing.sm),

          _ActionTile(
            icon: Icons.bar_chart_outlined,
            title: 'Analytics',
            subtitle: 'See your performance and impact',
            color: AppColors.warning,
            onTap: () => context.push(AppRoutes.businessAnalytics),
          ),
        ],
      ),
    );
  }
}

class _ActionTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  const _ActionTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(AppRadius.md),
              ),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: AppTextStyles.titleMedium),
                  Text(subtitle,
                      style: AppTextStyles.bodySmall
                          .copyWith(color: AppColors.textSecondary)),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: AppColors.textSecondary),
          ],
        ),
      ),
    );
  }
}