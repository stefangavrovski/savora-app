import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:savora_app/core/theme.dart';
import 'package:savora_app/features/reservations/models/review.dart';
import 'package:savora_app/features/reservations/providers/review_provider.dart';
import 'package:timeago/timeago.dart' as timeago;

/// Compact "★ 4.8 (12)" badge — drop this next to a business name
/// anywhere a customer sees a business (listing detail, map sheet, etc).
class RatingBadge extends ConsumerWidget {
  final String businessId;
  const RatingBadge({super.key, required this.businessId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final summaryAsync = ref.watch(businessRatingSummaryProvider(businessId));

    return summaryAsync.when(
      loading: () => const SizedBox.shrink(),
      error: (_, _) => const SizedBox.shrink(),
      data: (summary) {
        if (summary.reviewCount == 0) {
          return Text(
            'No reviews yet',
            style: AppTextStyles.bodySmall
                .copyWith(color: AppColors.textSecondary),
          );
        }
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.star_rounded, size: 16, color: AppColors.primary),
            const SizedBox(width: 2),
            Text(
              summary.averageRating.toStringAsFixed(1),
              style: AppTextStyles.bodySmall
                  .copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(width: 2),
            Text(
              '(${summary.reviewCount})',
              style: AppTextStyles.bodySmall
                  .copyWith(color: AppColors.textSecondary),
            ),
          ],
        );
      },
    );
  }
}

/// Full reviews section — a section header with the rating summary,
/// followed by a list of individual reviews. Drop this into a
/// CustomScrollView as a SliverToBoxAdapter, or directly in a Column.
class BusinessReviewsSection extends ConsumerWidget {
  final String businessId;
  const BusinessReviewsSection({super.key, required this.businessId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reviewsAsync = ref.watch(businessReviewsProvider(businessId));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text('Reviews', style: AppTextStyles.titleMedium),
            const SizedBox(width: AppSpacing.sm),
            RatingBadge(businessId: businessId),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        reviewsAsync.when(
          loading: () => const Padding(
            padding: EdgeInsets.symmetric(vertical: AppSpacing.md),
            child: Center(child: CircularProgressIndicator()),
          ),
          error: (e, _) => Padding(
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
            child: Text('Could not load reviews',
                style: AppTextStyles.bodySmall
                    .copyWith(color: AppColors.textSecondary)),
          ),
          data: (reviews) {
            if (reviews.isEmpty) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
                child: Text(
                  'No reviews yet. Be the first to leave one after pickup!',
                  style: AppTextStyles.bodySmall
                      .copyWith(color: AppColors.textSecondary),
                ),
              );
            }
            return Column(
              children: reviews
                  .map((review) => _ReviewTile(review: review))
                  .toList(),
            );
          },
        ),
      ],
    );
  }
}

class _ReviewTile extends StatelessWidget {
  final Review review;
  const _ReviewTile({required this.review});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  review.reviewerName ?? 'Savora customer',
                  style: AppTextStyles.bodyMedium
                      .copyWith(fontWeight: FontWeight.w600),
                ),
              ),
              Text(
                timeago.format(review.createdAt),
                style: AppTextStyles.bodySmall
                    .copyWith(color: AppColors.textSecondary),
              ),
            ],
          ),
          const SizedBox(height: 2),
          Row(
            children: List.generate(5, (i) {
              return Icon(
                i < review.rating ? Icons.star_rounded : Icons.star_border_rounded,
                size: 16,
                color: i < review.rating
                    ? AppColors.primary
                    : AppColors.textDisabled,
              );
            }),
          ),
          if (review.comment != null && review.comment!.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.xs),
            Text(review.comment!, style: AppTextStyles.bodyMedium),
          ],
        ],
      ),
    );
  }
}