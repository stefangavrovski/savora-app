import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:savora_app/core/theme.dart';
import 'package:savora_app/features/business/providers/business_provider.dart';

class BusinessAnalyticsScreen extends ConsumerWidget {
  const BusinessAnalyticsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statsAsync = ref.watch(businessAnalyticsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Analytics')),
      body: statsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (stats) {
          if (stats == null) {
            return const Center(child: Text('No data yet.'));
          }

          final totalListings = stats['total_listings'] ?? 0;
          final bagsSold = stats['total_bags_sold'] ?? 0;
          final bagsWasted = stats['total_bags_wasted'] ?? 0;
          final weightKg = stats['total_weight_rescued_grams'] != null
              ? (stats['total_weight_rescued_grams'] as num).toDouble() / 1000
              : 0.0;
          final avgRating = stats['average_rating'] != null
              ? (stats['average_rating'] as num).toDouble()
              : 0.0;
          final reviewCount = stats['review_count'] ?? 0;
          final followerCount = stats['follower_count'] ?? 0;

          return RefreshIndicator(
            onRefresh: () async => ref.invalidate(businessAnalyticsProvider),
            child: ListView(
              padding: const EdgeInsets.all(AppSpacing.md),
              children: [
                Row(
                  children: [
                    Expanded(
                      child: _StatCard(
                        icon: Icons.shopping_bag_outlined,
                        value: '$bagsSold',
                        label: 'Bags Sold',
                        color: AppColors.success,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: _StatCard(
                        icon: Icons.delete_outline,
                        value: '$bagsWasted',
                        label: 'Bags Wasted',
                        color: AppColors.error,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.sm),
                Row(
                  children: [
                    Expanded(
                      child: _StatCard(
                        icon: Icons.scale_outlined,
                        value: '${weightKg.toStringAsFixed(1)} kg',
                        label: 'Food Rescued',
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: _StatCard(
                        icon: Icons.inventory_2_outlined,
                        value: '$totalListings',
                        label: 'Total Listings',
                        color: AppColors.info,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.sm),
                Row(
                  children: [
                    Expanded(
                      child: _StatCard(
                        icon: Icons.star_outline,
                        value: avgRating > 0
                            ? avgRating.toStringAsFixed(1)
                            : '—',
                        label: '$reviewCount Reviews',
                        color: AppColors.accent,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: _StatCard(
                        icon: Icons.people_outline,
                        value: '$followerCount',
                        label: 'Followers',
                        color: AppColors.warning,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  final Color color;

  const _StatCard({
    required this.icon,
    required this.value,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(AppRadius.md),
            ),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(value, style: AppTextStyles.titleLarge),
          Text(label,
              style: AppTextStyles.bodySmall
                  .copyWith(color: AppColors.textSecondary)),
        ],
      ),
    );
  }
}