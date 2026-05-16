import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:savora_app/core/supabase_client.dart';
import 'package:savora_app/features/auth/providers/auth_provider.dart';
import 'package:savora_app/features/notifications/models/notification_model.dart';

// Real-time notifications stream for current user
final notificationsStreamProvider =
    StreamProvider<List<NotificationModel>>((ref) {
  final userId = ref.watch(currentUserIdProvider);
  if (userId == null) return Stream.value([]);

  return supabase
      .from('notifications')
      .stream(primaryKey: ['id'])
      .eq('user_id', userId)
      .order('created_at', ascending: false)
      .map((rows) =>
          rows.map((e) => NotificationModel.fromJson(e)).toList());
});

// Unread count — derived from the stream above
final unreadNotifCountProvider = Provider<int>((ref) {
  final notifications = ref.watch(notificationsStreamProvider).value ?? [];
  return notifications.where((n) => n.isUnread).length;
});

// Notification actions
class NotificationNotifier extends AsyncNotifier<void> {
  @override
  Future<void> build() async {}

  Future<void> markAsRead(String notificationId) async {
    await supabase
        .from('notifications')
        .update({'read_at': DateTime.now().toIso8601String()}).eq(
            'id', notificationId);
  }

  Future<void> markAllAsRead() async {
    final userId = ref.read(currentUserIdProvider);
    if (userId == null) return;

    await supabase
        .from('notifications')
        .update({'read_at': DateTime.now().toIso8601String()})
        .eq('user_id', userId)
        .isFilter('read_at', null);
  }
}

final notificationNotifierProvider =
    AsyncNotifierProvider<NotificationNotifier, void>(
        () => NotificationNotifier());