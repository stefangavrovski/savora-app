import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:savora_app/core/constants.dart';
import 'package:savora_app/core/theme.dart';
import 'package:savora_app/features/reservations/models/reservation.dart';
import 'package:savora_app/features/reservations/providers/reservation_provider.dart';

class ReservationDetailScreen extends ConsumerStatefulWidget {
  final String reservationId;
  const ReservationDetailScreen({super.key, required this.reservationId});

  @override
  ConsumerState<ReservationDetailScreen> createState() =>
      _ReservationDetailScreenState();
}

class _ReservationDetailScreenState
    extends ConsumerState<ReservationDetailScreen> {
  bool _cancelling = false;

  Future<void> _cancel(Reservation reservation) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Cancel reservation?'),
        content: const Text(
            'Your spot will be released. This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Keep it'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('Cancel reservation'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;
    setState(() => _cancelling = true);

    try {
      await ref
          .read(reservationNotifierProvider.notifier)
          .cancelReservation(reservation.id);
      if (!mounted) return;
      ref.invalidate(reservationByIdProvider(widget.reservationId));
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Reservation cancelled.')),
      );
    } on Exception catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceAll('Exception: ', '')),
          backgroundColor: AppColors.error,
        ),
      );
    } finally {
      if (mounted) setState(() => _cancelling = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final reservationAsync =
        ref.watch(reservationByIdProvider(widget.reservationId));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Reservation'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => context.pop(),
        ),
      ),
      body: reservationAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (reservation) {
          if (reservation == null) {
            return const Center(child: Text('Reservation not found.'));
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Pickup code card (shown only for confirmed)
                if (reservation.isConfirmed) ...[
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(AppRadius.xl),
                    ),
                    child: Column(
                      children: [
                        Text(
                          'Your pickup code',
                          style: AppTextStyles.bodyMedium.copyWith(
                              color: AppColors.white.withOpacity(0.8)),
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        Text(
                          AppConstants.formatPickupCode(reservation.pickupCode),
                          style: AppTextStyles.pickupCode
                              .copyWith(color: AppColors.white),
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        GestureDetector(
                          onTap: () {
                            Clipboard.setData(ClipboardData(
                                text: reservation.pickupCode));
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                  content: Text('Code copied to clipboard')),
                            );
                          },
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.copy_outlined,
                                  color: Colors.white70, size: 14),
                              const SizedBox(width: 4),
                              Text(
                                'Tap to copy',
                                style: AppTextStyles.bodySmall
                                    .copyWith(color: Colors.white70),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                ],

                // Details card
                Container(
                  decoration: BoxDecoration(
                    color: AppColors.white,
                    borderRadius: BorderRadius.circular(AppRadius.lg),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Column(
                    children: [
                      _InfoTile(
                        icon: Icons.shopping_bag_outlined,
                        label: 'Bag',
                        value: reservation.listingTitle ?? 'Surprise Bag',
                      ),
                      const Divider(height: 1),
                      _InfoTile(
                        icon: Icons.storefront_outlined,
                        label: 'Business',
                        value: reservation.businessName ?? '—',
                      ),
                      if (reservation.businessAddress != null) ...[
                        const Divider(height: 1),
                        _InfoTile(
                          icon: Icons.place_outlined,
                          label: 'Address',
                          value: reservation.businessAddress!,
                        ),
                      ],
                      if (reservation.pickupEnd != null) ...[
                        const Divider(height: 1),
                        _InfoTile(
                          icon: Icons.schedule_outlined,
                          label: 'Pickup window',
                          value: AppConstants.formatPickupWindow(
                            reservation.pickupStart ?? DateTime.now(),
                            reservation.pickupEnd!,
                          ),
                        ),
                      ],
                      if (reservation.price != null) ...[
                        const Divider(height: 1),
                        _InfoTile(
                          icon: Icons.payments_outlined,
                          label: 'Amount to pay',
                          value: AppConstants.formatMKD(reservation.price!),
                        ),
                      ],
                      const Divider(height: 1),
                      _InfoTile(
                        icon: Icons.info_outline,
                        label: 'Status',
                        value: reservation.status[0].toUpperCase() +
                            reservation.status.substring(1),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: AppSpacing.md),

                // Info box
                Container(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  decoration: BoxDecoration(
                    color: AppColors.accentSurface,
                    borderRadius: BorderRadius.circular(AppRadius.lg),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.info_outline,
                          color: AppColors.accent, size: 18),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: Text(
                          'Show your pickup code to the business when collecting your bag. Payment is made in person.',
                          style: AppTextStyles.bodySmall
                              .copyWith(color: AppColors.accent),
                        ),
                      ),
                    ],
                  ),
                ),

                // Cancel button
                if (reservation.canCancel) ...[
                  const SizedBox(height: AppSpacing.lg),
                  OutlinedButton(
                    onPressed: _cancelling ? null : () => _cancel(reservation),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.error,
                      side: const BorderSide(color: AppColors.error),
                    ),
                    child: _cancelling
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('Cancel Reservation'),
                  ),
                ],
              ],
            ),
          );
        },
      ),
    );
  }
}

class _InfoTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoTile({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md, vertical: AppSpacing.sm + 2),
      child: Row(
        children: [
          Icon(icon, size: 18, color: AppColors.primary),
          const SizedBox(width: AppSpacing.md),
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