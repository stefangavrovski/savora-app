import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:savora_app/core/constants.dart';
import 'package:savora_app/core/theme.dart';
import 'package:savora_app/features/business/providers/business_provider.dart';
import 'package:savora_app/features/reservations/models/reservation.dart';
import 'package:savora_app/features/reservations/providers/reservation_provider.dart';

class BusinessReservationsScreen extends ConsumerWidget {
  const BusinessReservationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final businessAsync = ref.watch(myBusinessProvider);

    return businessAsync.when(
      loading: () => const Scaffold(
          body: Center(child: CircularProgressIndicator())),
      error: (e, _) => Scaffold(body: Center(child: Text('Error: $e'))),
      data: (business) {
        if (business == null) {
          return const Scaffold(
              body: Center(child: Text('No business found.')));
        }

        final reservationsAsync =
            ref.watch(businessReservationsProvider(business.id));

        return Scaffold(
          appBar: AppBar(title: const Text('Reservations')),
          body: reservationsAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(child: Text('Error: $e')),
            data: (reservations) {
              if (reservations.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.receipt_long_outlined,
                          size: 64, color: AppColors.textDisabled),
                      const SizedBox(height: AppSpacing.md),
                      Text('No reservations yet',
                          style: AppTextStyles.titleMedium
                              .copyWith(color: AppColors.textSecondary)),
                    ],
                  ),
                );
              }

              final confirmed =
                  reservations.where((r) => r.status == 'confirmed').toList();
              final others =
                  reservations.where((r) => r.status != 'confirmed').toList();

              return ListView(
                padding: const EdgeInsets.all(AppSpacing.md),
                children: [
                  if (confirmed.isNotEmpty) ...[
                    Text('Awaiting Pickup', style: AppTextStyles.titleMedium),
                    const SizedBox(height: AppSpacing.sm),
                    ...confirmed.map((r) => _ReservationTile(reservation: r)),
                    const SizedBox(height: AppSpacing.md),
                  ],
                  if (others.isNotEmpty) ...[
                    Text('Past',
                        style: AppTextStyles.titleMedium
                            .copyWith(color: AppColors.textSecondary)),
                    const SizedBox(height: AppSpacing.sm),
                    ...others.map((r) => _ReservationTile(reservation: r)),
                  ],
                ],
              );
            },
          ),
        );
      },
    );
  }
}

class _ReservationTile extends StatelessWidget {
  final Reservation reservation;
  const _ReservationTile({required this.reservation});

  Color get _statusColor {
    switch (reservation.status) {
      case 'confirmed':
        return AppColors.success;
      case 'completed':
        return AppColors.info;
      case 'cancelled':
        return AppColors.textSecondary;
      case 'no_show':
        return AppColors.error;
      default:
        return AppColors.textSecondary;
    }
  }

  String get _statusLabel {
    switch (reservation.status) {
      case 'confirmed':
        return 'Confirmed';
      case 'completed':
        return 'Completed';
      case 'cancelled':
        return 'Cancelled';
      case 'no_show':
        return 'No-show';
      default:
        return reservation.status;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppColors.border),
      ),
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
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: _statusColor.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(AppRadius.full),
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
          const SizedBox(height: AppSpacing.xs),

          if (reservation.isConfirmed) ...[
            Row(
              children: [
                const Icon(Icons.password_outlined,
                    size: 14, color: AppColors.textSecondary),
                const SizedBox(width: 4),
                Text(
                  'Code: ${AppConstants.formatPickupCode(reservation.pickupCode)}',
                  style:
                      AppTextStyles.bodySmall.copyWith(fontWeight: FontWeight.w600),
                ),
              ],
            ),
            const SizedBox(height: 2),
          ],

          if (reservation.pickupEnd != null)
            Row(
              children: [
                const Icon(Icons.schedule_outlined,
                    size: 14, color: AppColors.textSecondary),
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
    );
  }
}