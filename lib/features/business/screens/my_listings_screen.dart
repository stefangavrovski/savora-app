import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:savora_app/core/constants.dart';
import 'package:savora_app/core/router.dart';
import 'package:savora_app/core/theme.dart';
import 'package:savora_app/features/listings/models/bag_listing.dart';
import 'package:savora_app/features/listings/providers/listing_provider.dart';

class MyListingsScreen extends ConsumerWidget {
  const MyListingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final listingsAsync = ref.watch(myListingsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Listings'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => context.push(AppRoutes.createListing),
          ),
        ],
      ),
      body: listingsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (listings) {
          if (listings.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.inventory_2_outlined,
                      size: 64, color: AppColors.textDisabled),
                  const SizedBox(height: AppSpacing.md),
                  Text('No listings yet',
                      style: AppTextStyles.titleMedium
                          .copyWith(color: AppColors.textSecondary)),
                  const SizedBox(height: AppSpacing.xs),
                  Text('Create your first surprise bag listing.',
                      style: AppTextStyles.bodyMedium
                          .copyWith(color: AppColors.textDisabled)),
                  const SizedBox(height: AppSpacing.lg),
                  ElevatedButton(
                    onPressed: () => context.push(AppRoutes.createListing),
                    child: const Text('Create Listing'),
                  ),
                ],
              ),
            );
          }

          final active =
              listings.where((l) => l.status == 'active').toList();
          final others =
              listings.where((l) => l.status != 'active').toList();

          return RefreshIndicator(
            onRefresh: () async => ref.invalidate(myListingsProvider),
            child: ListView(
              padding: const EdgeInsets.all(AppSpacing.md),
              children: [
                if (active.isNotEmpty) ...[
                  Text('Active', style: AppTextStyles.titleMedium),
                  const SizedBox(height: AppSpacing.sm),
                  ...active.map((l) => _ListingCard(listing: l)),
                  const SizedBox(height: AppSpacing.md),
                ],
                if (others.isNotEmpty) ...[
                  Text('Past',
                      style: AppTextStyles.titleMedium
                          .copyWith(color: AppColors.textSecondary)),
                  const SizedBox(height: AppSpacing.sm),
                  ...others.map((l) => _ListingCard(listing: l)),
                ],
              ],
            ),
          );
        },
      ),
    );
  }
}

class _ListingCard extends ConsumerWidget {
  final BagListing listing;
  const _ListingCard({required this.listing});

  Color _statusColor(String status) {
    switch (status) {
      case 'active': return AppColors.success;
      case 'sold_out': return AppColors.error;
      case 'expired': return AppColors.textSecondary;
      case 'cancelled': return AppColors.textDisabled;
      default: return AppColors.textSecondary;
    }
  }

  String _statusLabel(String status) {
    switch (status) {
      case 'active': return 'Active';
      case 'sold_out': return 'Sold Out';
      case 'expired': return 'Expired';
      case 'cancelled': return 'Cancelled';
      default: return status;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          Row(
            children: [
              ClipRRect(
                borderRadius: const BorderRadius.horizontal(
                    left: Radius.circular(AppRadius.lg - 1)),
                child: listing.imageUrl != null
                    ? CachedNetworkImage(
                        imageUrl: listing.imageUrl!,
                        width: 88,
                        height: 88,
                        fit: BoxFit.cover,
                      )
                    : Container(
                        width: 88,
                        height: 88,
                        color: AppColors.primarySurface,
                        child: const Icon(Icons.shopping_bag_outlined,
                            color: AppColors.primaryLight),
                      ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.sm),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(listing.title,
                                style: AppTextStyles.titleMedium,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: _statusColor(listing.status)
                                  .withValues(alpha: 0.12),
                              borderRadius:
                                  BorderRadius.circular(AppRadius.full),
                            ),
                            child: Text(
                              _statusLabel(listing.status),
                              style: AppTextStyles.bodySmall.copyWith(
                                color: _statusColor(listing.status),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${listing.quantityAvailable} / ${listing.quantityTotal} left · ${AppConstants.formatMKD(listing.price)}',
                        style: AppTextStyles.bodySmall,
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        AppConstants.formatPickupWindow(
                            listing.pickupStart, listing.pickupEnd),
                        style: AppTextStyles.bodySmall
                            .copyWith(color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          if (listing.isActive) ...[
            const Divider(height: 1),
            TextButton.icon(
              onPressed: () async {
                final confirmed = await showDialog<bool>(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: const Text('Cancel listing?'),
                    content: const Text(
                        'This will cancel the listing and release any reservations.'),
                    actions: [
                      TextButton(
                          onPressed: () => Navigator.pop(ctx, false),
                          child: const Text('Keep')),
                      TextButton(
                          onPressed: () => Navigator.pop(ctx, true),
                          style: TextButton.styleFrom(
                              foregroundColor: AppColors.error),
                          child: const Text('Cancel listing')),
                    ],
                  ),
                );
                if (confirmed == true) {
                  await ref
                      .read(createListingProvider.notifier)
                      .cancelListing(listing.id);
                }
              },
              icon: const Icon(Icons.cancel_outlined,
                  size: 16, color: AppColors.error),
              label: Text('Cancel listing',
                  style: AppTextStyles.bodySmall
                      .copyWith(color: AppColors.error)),
            ),
          ],
        ],
      ),
    );
  }
}