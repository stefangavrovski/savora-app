import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:savora_app/core/constants.dart';
import 'package:savora_app/core/theme.dart';
import 'package:savora_app/features/listings/models/bag_listing.dart';

class ListingBottomSheet extends StatelessWidget {
  final BagListing listing;
  const ListingBottomSheet({super.key, required this.listing});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(
          AppSpacing.sm, 0, AppSpacing.sm, AppSpacing.sm),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(AppRadius.xl),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag handle
          const SizedBox(height: AppSpacing.sm),
          Container(
            width: 36,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.border,
              borderRadius: BorderRadius.circular(AppRadius.full),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),

          // Image
          if (listing.imageUrl != null)
            ClipRRect(
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(AppRadius.xl - 2),
              ),
              child: CachedNetworkImage(
                imageUrl: listing.imageUrl!,
                height: 180,
                width: double.infinity,
                fit: BoxFit.cover,
              ),
            ),

          Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Business name + distance
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        listing.businessName ?? '',
                        style: AppTextStyles.bodySmall,
                      ),
                    ),
                    if (listing.distanceLabel.isNotEmpty)
                      Row(
                        children: [
                          const Icon(Icons.near_me_outlined,
                              size: 12, color: AppColors.textSecondary),
                          const SizedBox(width: 2),
                          Text(listing.distanceLabel,
                              style: AppTextStyles.bodySmall),
                        ],
                      ),
                  ],
                ),
                const SizedBox(height: AppSpacing.xs),

                // Listing title
                Text(listing.title, style: AppTextStyles.titleMedium),
                const SizedBox(height: AppSpacing.xs),

                // Pickup window
                Row(
                  children: [
                    const Icon(Icons.schedule_outlined,
                        size: 14, color: AppColors.textSecondary),
                    const SizedBox(width: AppSpacing.xs),
                    Text(
                      AppConstants.formatPickupWindow(
                          listing.pickupStart, listing.pickupEnd),
                      style: AppTextStyles.bodySmall,
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),

                // Price row + CTA
                Row(
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          AppConstants.formatMKD(listing.price),
                          style: AppTextStyles.titleMedium.copyWith(
                            color: AppColors.primary,
                          ),
                        ),
                        Text(
                          '${listing.discountPercent.toInt()}% off',
                          style: AppTextStyles.bodySmall.copyWith(
                            color: AppColors.accent,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    const Spacer(),
                    // Quantity badge
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.sm, vertical: 4),
                      decoration: BoxDecoration(
                        color: listing.isAvailable
                            ? AppColors.primarySurface
                            : AppColors.border,
                        borderRadius: BorderRadius.circular(AppRadius.full),
                      ),
                      child: Text(
                        listing.isAvailable
                            ? '${listing.quantityAvailable} left'
                            : listing.status.toUpperCase(),
                        style: AppTextStyles.bodySmall.copyWith(
                          color: listing.isAvailable
                              ? AppColors.primary
                              : AppColors.textSecondary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    ElevatedButton(
                      onPressed: listing.isAvailable
                          ? () {
                              Navigator.pop(context);
                              context.push('/listing/${listing.id}');
                            }
                          : null,
                      style: ElevatedButton.styleFrom(
                        minimumSize: const Size(0, 44),
                        padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.lg),
                      ),
                      child: const Text('View'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}