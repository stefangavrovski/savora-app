import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';
import 'package:savora_app/core/constants.dart';
import 'package:savora_app/core/theme.dart';
import 'package:savora_app/features/listings/models/bag_listing.dart';
import 'package:savora_app/features/listings/providers/listing_provider.dart';

class ExploreScreen extends ConsumerStatefulWidget {
  const ExploreScreen({super.key});

  @override
  ConsumerState<ExploreScreen> createState() => _ExploreScreenState();
}

class _ExploreScreenState extends ConsumerState<ExploreScreen> {
  final _searchController = TextEditingController();
  String _query = '';
  ({double lat, double lng}) _coords = (
    lat: AppConstants.defaultLat,
    lng: AppConstants.defaultLng,
  );

  @override
  void initState() {
    super.initState();
    _initLocation();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _initLocation() async {
    try {
      final pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.low,
          timeLimit: Duration(seconds: 5),
        ),
      );
      setState(() {
        _coords = (lat: pos.latitude, lng: pos.longitude);
      });
    } catch (_) {
      // Keep default Tetovo coords
    }
  }

  @override
  Widget build(BuildContext context) {
    final listingsAsync = ref.watch(nearbyListingsProvider(_coords));

    return Scaffold(
      appBar: AppBar(
        title: TextField(
          controller: _searchController,
          autofocus: true,
          decoration: const InputDecoration(
            hintText: 'Search bags...',
            border: InputBorder.none,
            enabledBorder: InputBorder.none,
            focusedBorder: InputBorder.none,
            filled: false,
            contentPadding: EdgeInsets.zero,
          ),
          onChanged: (v) => setState(() => _query = v.toLowerCase()),
        ),
        leading: const BackButton(),
      ),
      body: listingsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (all) {
          final listings = _query.isEmpty
              ? all
              : all
                  .where((l) =>
                      l.title.toLowerCase().contains(_query) ||
                      (l.businessName?.toLowerCase().contains(_query) ?? false))
                  .toList();

          if (listings.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.search_off,
                      size: 48, color: AppColors.textDisabled),
                  const SizedBox(height: AppSpacing.md),
                  Text(
                    _query.isEmpty
                        ? 'No active listings nearby'
                        : 'No results for "$_query"',
                    style: AppTextStyles.bodyMedium.copyWith(
                        color: AppColors.textSecondary),
                  ),
                ],
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(AppSpacing.md),
            itemCount: listings.length,
            separatorBuilder: (_, __) =>
                const SizedBox(height: AppSpacing.sm),
            itemBuilder: (_, i) => _ListingTile(listing: listings[i]),
          );
        },
      ),
    );
  }
}

class _ListingTile extends StatelessWidget {
  final BagListing listing;
  const _ListingTile({required this.listing});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context.push('/listing/${listing.id}'),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: const BorderRadius.horizontal(
                  left: Radius.circular(AppRadius.lg - 1)),
              child: listing.imageUrl != null
                  ? CachedNetworkImage(
                      imageUrl: listing.imageUrl!,
                      width: 96,
                      height: 96,
                      fit: BoxFit.cover,
                    )
                  : Container(
                      width: 96,
                      height: 96,
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
                    Text(
                      listing.businessName ?? '',
                      style: AppTextStyles.bodySmall,
                    ),
                    Text(listing.title,
                        style: AppTextStyles.titleMedium,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis),
                    const SizedBox(height: AppSpacing.xs),
                    Row(
                      children: [
                        Text(
                          AppConstants.formatMKD(listing.price),
                          style: AppTextStyles.bodyMedium.copyWith(
                              color: AppColors.primary,
                              fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Text(
                          '${listing.discountPercent.toInt()}% off',
                          style: AppTextStyles.bodySmall.copyWith(
                              color: AppColors.accent,
                              fontWeight: FontWeight.w600),
                        ),
                        const Spacer(),
                        if (listing.distanceLabel.isNotEmpty)
                          Text(listing.distanceLabel,
                              style: AppTextStyles.bodySmall),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${listing.quantityAvailable} bag${listing.quantityAvailable != 1 ? 's' : ''} left',
                      style: AppTextStyles.bodySmall.copyWith(
                        color: listing.quantityAvailable <= 2
                            ? AppColors.error
                            : AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}