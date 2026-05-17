import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:savora_app/core/constants.dart';
import 'package:savora_app/core/theme.dart';
import 'package:savora_app/features/reservations/models/reservation.dart';
import 'package:savora_app/features/reservations/providers/reservation_provider.dart';

class MyReservationsScreen extends ConsumerWidget {
  const MyReservationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reservationsAsync = ref.watch(myReservationsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Reservations'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_outlined),
            onPressed: () => ref.invalidate(myReservationsProvider),
          ),
        ],
      ),
      body: reservationsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (reservations) {
          if (reservations.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.shopping_bag_outlined,
                      size: 64, color: AppColors.textDisabled),
                  const SizedBox(height: AppSpacing.md),
                  Text('No reservations yet',
                      style: AppTextStyles.titleMedium.copyWith(
                          color: AppColors.textSecondary)),
                  const SizedBox(height: AppSpacing.xs),
                  Text('Reserve a surprise bag from the map!',
                      style: AppTextStyles.bodyMedium.copyWith(
                          color: AppColors.textDisabled)),
                ],
              ),
            );
          }

          final active = reservations
              .where((r) => r.status == 'confirmed')
              .toList();
          final past = reservations
              .where((r) => r.status != 'confirmed')
              .toList();

          return RefreshIndicator(
            onRefresh: () async => ref.invalidate(myReservationsProvider),
            child: ListView(
              padding: const EdgeInsets.all(AppSpacing.md),
              children: [
                if (active.isNotEmpty) ...[
                  Text('Upcoming', style: AppTextStyles.titleMedium),
                  const SizedBox(height: AppSpacing.sm),
                  ...active.map((r) => _ReservationCard(reservation: r)),
                  const SizedBox(height: AppSpacing.md),
                ],
                if (past.isNotEmpty) ...[
                  Text('Past', style: AppTextStyles.titleMedium.copyWith(
                      color: AppColors.textSecondary)),
                  const SizedBox(height: AppSpacing.sm),
                  ...past.map((r) => _ReservationCard(reservation: r)),
                ],
              ],
            ),
          );
        },
      ),
    );
  }
}

class _ReservationCard extends StatelessWidget {
  final Reservation reservation;
  const _ReservationCard({required this.reservation});

  Color get _statusColor {
    switch (reservation.status) {
      case 'confirmed': return AppColors.success;
      case 'completed': return AppColors.info;
      case 'cancelled': return AppColors.textSecondary;
      case 'no_show': return AppColors.error;
      default: return AppColors.textSecondary;
    }
  }

  String get _statusLabel {
    switch (reservation.status) {
      case 'confirmed': return 'Confirmed';
      case 'completed': return 'Completed';
      case 'cancelled': return 'Cancelled';
      case 'no_show': return 'No-show';
      default: return reservation.status;
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context.push('/reservations/${reservation.id}'),
      child: Container(
        margin: const EdgeInsets.only(bottom: AppSpacing.sm),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            // Image or placeholder
            ClipRRect(
              borderRadius: const BorderRadius.horizontal(
                  left: Radius.circular(AppRadius.lg - 1)),
              child: reservation.listingImageUrl != null
                  ? CachedNetworkImage(
                      imageUrl: reservation.listingImageUrl!,
                      width: 88,
                      height: 88,
                      fit: BoxFit.cover,
                    )
                  : Container(
                      width: 88,
                      height: 88,
                      color: AppColors.primarySurface,
                      child: const Icon(Icons.shopping_bag_outlined,
                          color: AppColors.primaryLight, size: 32),
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
                          child: Text(
                            reservation.listingTitle ?? 'Surprise Bag',
                            style: AppTextStyles.titleMedium,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: _statusColor.withOpacity(0.12),
                            borderRadius:
                                BorderRadius.circular(AppRadius.full),
                          ),
                          child: Text(
                            _statusLabel,
                            style: AppTextStyles.bodySmall.copyWith(
                              color: _statusColor,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      reservation.businessName ?? '',
                      style: AppTextStyles.bodySmall,
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    if (reservation.pickupEnd != null)
                      Row(
                        children: [
                          const Icon(Icons.schedule_outlined,
                              size: 12, color: AppColors.textSecondary),
                          const SizedBox(width: 4),
                          Text(
                            AppConstants.formatPickupWindow(
                              reservation.pickupStart ?? DateTime.now(),
                              reservation.pickupEnd!,
                            ),
                            style: AppTextStyles.bodySmall,
                          ),
                        ],
                      ),
                  ],
                ),
              ),
            ),
            const Padding(
              padding: EdgeInsets.only(right: AppSpacing.sm),
              child: Icon(Icons.chevron_right, color: AppColors.textSecondary),
            ),
          ],
        ),
      ),
    );
  }
}