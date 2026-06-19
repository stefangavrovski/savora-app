import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:savora_app/core/constants.dart';
import 'package:savora_app/core/theme.dart';
import 'package:savora_app/features/listings/models/bag_listing.dart';
import 'package:savora_app/features/listings/providers/listing_provider.dart';
import 'package:savora_app/features/reservations/providers/reservation_provider.dart';
import 'package:savora_app/features/business/providers/follow_provider.dart';

class ListingDetailScreen extends ConsumerStatefulWidget {
  final String listingId;
  const ListingDetailScreen({super.key, required this.listingId});

  @override
  ConsumerState<ListingDetailScreen> createState() =>
      _ListingDetailScreenState();
}

class _ListingDetailScreenState extends ConsumerState<ListingDetailScreen> {
  bool _reserving = false;

  Future<void> _reserve(BagListing listing) async {
    setState(() => _reserving = true);
    try {
      final reservationId = await ref
          .read(reservationNotifierProvider.notifier)
          .makeReservation(listing.id);

      if (!mounted) return;
      // Navigate to the detail screen of the new reservation
      context.pushReplacement('/reservations/$reservationId');
    } on Exception catch (e) {
      if (!mounted) return;
      final msg = e.toString().replaceAll('Exception: ', '');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            msg.contains('no bags left') ? 'Sorry, all bags are gone!' : msg,
          ),
          backgroundColor: AppColors.error,
        ),
      );
    } finally {
      if (mounted) setState(() => _reserving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Use the real-time stream so quantity updates live
    final listingAsync = ref.watch(listingStreamProvider(widget.listingId));
    // Fall back to one-shot fetch for initial data (image, description)
    final listingDetailAsync = ref.watch(listingByIdProvider(widget.listingId));

    return Scaffold(
      backgroundColor: AppColors.surface,
      body: listingDetailAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (listing) {
          if (listing == null) {
            return const Center(child: Text('Listing not found'));
          }

          // Prefer real-time quantity from stream
          final liveQuantity = listingAsync.value?.quantityAvailable ??
              listing.quantityAvailable;
          final liveStatus =
              listingAsync.value?.status ?? listing.status;
          final isAvailable =
              liveStatus == 'active' && liveQuantity > 0;

          return CustomScrollView(
            slivers: [
              // App bar with hero image
              SliverAppBar(
                expandedHeight: listing.imageUrl != null ? 280 : 120,
                pinned: true,
                backgroundColor: AppColors.white,
                leading: IconButton(
                  icon: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: AppColors.white.withValues(alpha: 0.9),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.arrow_back_rounded,
                        color: AppColors.textPrimary),
                  ),
                  onPressed: () => context.pop(),
                ),
                flexibleSpace: FlexibleSpaceBar(
                  background: listing.imageUrl != null
                      ? CachedNetworkImage(
                          imageUrl: listing.imageUrl!,
                          fit: BoxFit.cover,
                          placeholder: (_, _) => Container(
                            color: AppColors.primarySurface,
                          ),
                        )
                      : Container(
                          color: AppColors.primarySurface,
                          child: const Center(
                            child: Icon(Icons.shopping_bag_outlined,
                                size: 64, color: AppColors.primaryLight),
                          ),
                        ),
                ),
              ),

              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Status chip
                      if (!isAvailable)
                        Container(
                          margin: const EdgeInsets.only(bottom: AppSpacing.sm),
                          padding: const EdgeInsets.symmetric(
                              horizontal: AppSpacing.sm, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppColors.border,
                            borderRadius:
                                BorderRadius.circular(AppRadius.full),
                          ),
                          child: Text(
                            liveStatus == 'sold_out'
                                ? 'Sold Out'
                                : liveStatus == 'expired'
                                    ? 'Expired'
                                    : 'Unavailable',
                            style: AppTextStyles.bodySmall.copyWith(
                              color: AppColors.textSecondary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),

                      // Business name + follow button
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              listing.businessName ?? '',
                              style: AppTextStyles.bodyMedium.copyWith(
                                  color: AppColors.textSecondary),
                            ),
                          ),
                          _FollowButton(businessId: listing.businessId),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.xs),

                      // Title
                      Text(listing.title, style: AppTextStyles.displayMedium),
                      const SizedBox(height: AppSpacing.md),

                      // Price card
                      Container(
                        padding: const EdgeInsets.all(AppSpacing.md),
                        decoration: BoxDecoration(
                          color: AppColors.primarySurface,
                          borderRadius: BorderRadius.circular(AppRadius.lg),
                        ),
                        child: Row(
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Price',
                                    style: AppTextStyles.bodySmall),
                                Text(
                                  AppConstants.formatMKD(listing.price),
                                  style: AppTextStyles.titleLarge.copyWith(
                                    color: AppColors.primary,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(width: AppSpacing.lg),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Original value',
                                    style: AppTextStyles.bodySmall),
                                Text(
                                  AppConstants.formatMKD(listing.originalValue),
                                  style: AppTextStyles.bodyMedium.copyWith(
                                    decoration: TextDecoration.lineThrough,
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                            const Spacer(),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: AppSpacing.sm, vertical: 6),
                              decoration: BoxDecoration(
                                color: AppColors.accent,
                                borderRadius:
                                    BorderRadius.circular(AppRadius.md),
                              ),
                              child: Text(
                                '-${listing.discountPercent.toInt()}%',
                                style: AppTextStyles.labelLarge.copyWith(
                                    color: AppColors.white),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: AppSpacing.md),

                      // Details grid
                      _DetailRow(
                        icon: Icons.schedule_outlined,
                        label: 'Pickup window',
                        value: AppConstants.formatPickupWindow(
                            listing.pickupStart, listing.pickupEnd),
                      ),
                      _DetailRow(
                        icon: Icons.inventory_2_outlined,
                        label: 'Bags available',
                        value: '$liveQuantity of ${listing.quantityTotal}',
                      ),
                      if (listing.estWeightGrams != null)
                        _DetailRow(
                          icon: Icons.scale_outlined,
                          label: 'Estimated weight',
                          value:
                              '~${(listing.estWeightGrams! / 1000).toStringAsFixed(1)} kg',
                        ),
                      if (listing.businessAddress != null)
                        _DetailRow(
                          icon: Icons.place_outlined,
                          label: 'Address',
                          value: listing.businessAddress!,
                        ),

                      // Description
                      if (listing.description != null &&
                          listing.description!.isNotEmpty) ...[
                        const SizedBox(height: AppSpacing.md),
                        Text("What's in the bag",
                            style: AppTextStyles.titleMedium),
                        const SizedBox(height: AppSpacing.xs),
                        Text(listing.description!,
                            style: AppTextStyles.bodyMedium.copyWith(
                                color: AppColors.textSecondary)),
                      ],

                      const SizedBox(height: AppSpacing.xxl),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
      bottomNavigationBar: listingDetailAsync.when(
        loading: () => const SizedBox.shrink(),
        error: (_, _) => const SizedBox.shrink(),
        data: (listing) {
          if (listing == null) return const SizedBox.shrink();
          final liveStatus =
              ref.watch(listingStreamProvider(widget.listingId)).value?.status ??
                  listing.status;
          final liveQty = ref
                  .watch(listingStreamProvider(widget.listingId))
                  .value
                  ?.quantityAvailable ??
              listing.quantityAvailable;
          final isAvailable = liveStatus == 'active' && liveQty > 0;

          return SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                  AppSpacing.md, AppSpacing.sm, AppSpacing.md, AppSpacing.md),
              child: ElevatedButton(
                onPressed: (isAvailable && !_reserving) ? () => _reserve(listing) : null,
                child: _reserving
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor:
                              AlwaysStoppedAnimation<Color>(AppColors.white),
                        ),
                      )
                    : Text(isAvailable ? 'Reserve for ${AppConstants.formatMKD(listing.price)}' : 'Not Available'),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _FollowButton extends ConsumerWidget {
  final String businessId;
  const _FollowButton({required this.businessId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isFollowingAsync = ref.watch(isFollowingProvider(businessId));

    return isFollowingAsync.when(
      loading: () => const SizedBox(
        width: 32,
        height: 32,
        child: Padding(
          padding: EdgeInsets.all(6),
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      ),
      error: (_, _) => const SizedBox.shrink(),
      data: (isFollowing) {
        return TextButton.icon(
          onPressed: () async {
            final notifier = ref.read(followNotifierProvider.notifier);
            try {
              if (isFollowing) {
                await notifier.unfollow(businessId);
              } else {
                await notifier.follow(businessId);
              }
            } catch (e) {
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Error: $e')),
                );
              }
            }
          },
          icon: Icon(
            isFollowing ? Icons.notifications_active : Icons.notifications_none,
            size: 18,
            color: isFollowing ? AppColors.primary : AppColors.textSecondary,
          ),
          label: Text(
            isFollowing ? 'Following' : 'Follow',
            style: AppTextStyles.bodySmall.copyWith(
              color: isFollowing ? AppColors.primary : AppColors.textSecondary,
              fontWeight: FontWeight.w600,
            ),
          ),
        );
      },
    );
  }
}

class _DetailRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _DetailRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: AppColors.primary),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: AppTextStyles.bodySmall
                        .copyWith(color: AppColors.textSecondary)),
                Text(value, style: AppTextStyles.bodyMedium),
              ],
            ),
          ),
        ],
      ),
    );
  }
}