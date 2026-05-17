import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:savora_app/core/constants.dart';
import 'package:savora_app/core/router.dart';
import 'package:savora_app/core/theme.dart';
import 'package:savora_app/features/notifications/models/notification_model.dart';
import 'package:savora_app/features/notifications/providers/notification_provider.dart';
import 'package:timeago/timeago.dart' as timeago;

class NotificationsScreen extends ConsumerWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notificationsAsync = ref.watch(notificationsStreamProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        actions: [
          notificationsAsync.maybeWhen(
            data: (notifications) {
              final hasUnread = notifications.any((n) => n.isUnread);
              if (!hasUnread) return const SizedBox.shrink();
              return TextButton(
                onPressed: () {
                  ref
                      .read(notificationNotifierProvider.notifier)
                      .markAllAsRead();
                },
                child: Text(
                  'Mark all read',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              );
            },
            orElse: () => const SizedBox.shrink(),
          ),
        ],
      ),
      body: notificationsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (notifications) {
          if (notifications.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      color: AppColors.primarySurface,
                      borderRadius: BorderRadius.circular(AppRadius.xl),
                    ),
                    child: const Icon(
                      Icons.notifications_none_rounded,
                      size: 36,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Text('No notifications yet',
                      style: AppTextStyles.titleMedium),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    'You\'ll be notified about reservations,\nnew listings, and more.',
                    style: AppTextStyles.bodyMedium
                        .copyWith(color: AppColors.textSecondary),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
            itemCount: notifications.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final notif = notifications[index];
              return _NotificationTile(
                notification: notif,
                onTap: () {
                  if (notif.isUnread) {
                    ref
                        .read(notificationNotifierProvider.notifier)
                        .markAsRead(notif.id);
                  }
                  _handleNotificationTap(context, notif);
                },
              );
            },
          );
        },
      ),
    );
  }

  void _handleNotificationTap(
      BuildContext context, NotificationModel notif) {
    final meta = notif.metadata;
    switch (notif.type) {
      case 'new_listing':
      case 'geofence_listing_nearby':
        final listingId = meta['listing_id'] as String?;
        if (listingId != null) {
          context.push('/listing/$listingId');
        }
        break;
      case 'reservation_confirmed':
      case 'pickup_reminder':
        final reservationId = meta['reservation_id'] as String?;
        if (reservationId != null) {
          context.push('/reservations/$reservationId');
        }
        break;
      case 'business_verified':
      case 'business_rejected':
        context.go(AppRoutes.businessDashboard);
        break;
      default:
        break;
    }
  }
}

class _NotificationTile extends StatelessWidget {
  final NotificationModel notification;
  final VoidCallback onTap;

  const _NotificationTile({
    required this.notification,
    required this.onTap,
  });

  IconData get _icon {
    switch (notification.type) {
      case 'new_listing':
        return Icons.shopping_bag_outlined;
      case 'reservation_confirmed':
        return Icons.check_circle_outline;
      case 'pickup_reminder':
        return Icons.access_time_rounded;
      case 'business_verified':
        return Icons.verified_outlined;
      case 'business_rejected':
        return Icons.cancel_outlined;
      case 'geofence_listing_nearby':
        return Icons.location_on_outlined;
      default:
        return Icons.notifications_outlined;
    }
  }

  Color get _iconColor {
    switch (notification.type) {
      case 'new_listing':
      case 'geofence_listing_nearby':
        return AppColors.primary;
      case 'reservation_confirmed':
      case 'business_verified':
        return AppColors.success;
      case 'pickup_reminder':
        return AppColors.warning;
      case 'business_rejected':
        return AppColors.error;
      default:
        return AppColors.textSecondary;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isUnread = notification.isUnread;

    return InkWell(
      onTap: onTap,
      child: Container(
        color: isUnread
            ? AppColors.primarySurface.withOpacity(0.4)
            : Colors.transparent,
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.md,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Icon
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: _iconColor.withOpacity(0.12),
                borderRadius: BorderRadius.circular(AppRadius.md),
              ),
              child: Icon(_icon, color: _iconColor, size: 22),
            ),
            const SizedBox(width: AppSpacing.md),

            // Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          notification.title,
                          style: AppTextStyles.bodyMedium.copyWith(
                            fontWeight: isUnread
                                ? FontWeight.w600
                                : FontWeight.w400,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (isUnread)
                        Container(
                          width: 8,
                          height: 8,
                          margin: const EdgeInsets.only(left: AppSpacing.sm),
                          decoration: const BoxDecoration(
                            color: AppColors.primary,
                            shape: BoxShape.circle,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    notification.body,
                    style: AppTextStyles.bodySmall,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    timeago.format(notification.createdAt),
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.textDisabled,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}