import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import 'package:savora_app/core/theme.dart';

class ShimmerBox extends StatelessWidget {
  final double width;
  final double height;
  final double borderRadius;

  const ShimmerBox({
    super.key,
    required this.width,
    required this.height,
    this.borderRadius = AppRadius.sm,
  });

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: AppColors.border,
      highlightColor: AppColors.surface,
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: AppColors.border,
          borderRadius: BorderRadius.circular(borderRadius),
        ),
      ),
    );
  }
}

class ListingCardShimmer extends StatelessWidget {
  const ListingCardShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: AppColors.border,
      highlightColor: AppColors.surface,
      child: Container(
        margin: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md, vertical: AppSpacing.sm),
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppRadius.lg),
        ),
        child: Row(
          children: [
            // Thumbnail
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: AppColors.border,
                borderRadius: BorderRadius.circular(AppRadius.md),
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                      height: 14,
                      width: double.infinity,
                      color: AppColors.border),
                  const SizedBox(height: AppSpacing.sm),
                  Container(
                      height: 12,
                      width: 120,
                      color: AppColors.border),
                  const SizedBox(height: AppSpacing.sm),
                  Container(
                      height: 12,
                      width: 80,
                      color: AppColors.border),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Renders [count] listing card skeletons in a column.
class ListingListShimmer extends StatelessWidget {
  final int count;
  const ListingListShimmer({super.key, this.count = 5});

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      physics: const NeverScrollableScrollPhysics(),
      shrinkWrap: true,
      itemCount: count,
      itemBuilder: (_, _) => const ListingCardShimmer(),
    );
  }
}

class NotificationRowShimmer extends StatelessWidget {
  const NotificationRowShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: AppColors.border,
      highlightColor: AppColors.surface,
      child: Padding(
        padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md, vertical: AppSpacing.sm),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: AppColors.border,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(height: 13, color: AppColors.border),
                  const SizedBox(height: 6),
                  Container(
                      height: 11,
                      width: 180,
                      color: AppColors.border),
                  const SizedBox(height: 6),
                  Container(
                      height: 10,
                      width: 80,
                      color: AppColors.border),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class NotificationListShimmer extends StatelessWidget {
  final int count;
  const NotificationListShimmer({super.key, this.count = 6});

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      physics: const NeverScrollableScrollPhysics(),
      shrinkWrap: true,
      itemCount: count,
      itemBuilder: (_, _) => const NotificationRowShimmer(),
    );
  }
}

class ReservationCardShimmer extends StatelessWidget {
  const ReservationCardShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: AppColors.border,
      highlightColor: AppColors.surface,
      child: Container(
        margin: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md, vertical: AppSpacing.sm),
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppRadius.lg),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                    height: 14,
                    width: 160,
                    color: AppColors.border),
                const Spacer(),
                Container(
                    height: 22,
                    width: 70,
                    decoration: BoxDecoration(
                        color: AppColors.border,
                        borderRadius:
                            BorderRadius.circular(AppRadius.sm))),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            Container(
                height: 12,
                width: 120,
                color: AppColors.border),
            const SizedBox(height: AppSpacing.sm),
            Container(
                height: 12,
                width: 90,
                color: AppColors.border),
          ],
        ),
      ),
    );
  }
}

class ReservationListShimmer extends StatelessWidget {
  final int count;
  const ReservationListShimmer({super.key, this.count = 4});

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      physics: const NeverScrollableScrollPhysics(),
      shrinkWrap: true,
      itemCount: count,
      itemBuilder: (_, _) => const ReservationCardShimmer(),
    );
  }
}

class BusinessDashboardShimmer extends StatelessWidget {
  const BusinessDashboardShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: AppColors.border,
      highlightColor: AppColors.surface,
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header card
            Container(
              height: 100,
              decoration: BoxDecoration(
                color: AppColors.border,
                borderRadius: BorderRadius.circular(AppRadius.lg),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            // Stats row
            Row(
              children: [
                Expanded(
                    child: Container(
                        height: 70,
                        decoration: BoxDecoration(
                            color: AppColors.border,
                            borderRadius:
                                BorderRadius.circular(AppRadius.md)))),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                    child: Container(
                        height: 70,
                        decoration: BoxDecoration(
                            color: AppColors.border,
                            borderRadius:
                                BorderRadius.circular(AppRadius.md)))),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            // Listings
            Container(height: 14, width: 100, color: AppColors.border),
            const SizedBox(height: AppSpacing.sm),
            ...List.generate(
                3, (_) => Padding(
                      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                      child: Container(
                          height: 72,
                          decoration: BoxDecoration(
                              color: AppColors.border,
                              borderRadius:
                                  BorderRadius.circular(AppRadius.md))),
                    )),
          ],
        ),
      ),
    );
  }
}