import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:savora_app/core/notification_service.dart';
import 'package:savora_app/features/notifications/models/notification_model.dart';
import 'package:savora_app/features/notifications/providers/notification_provider.dart';

final _lastShownIdProvider = StateProvider<String?>((ref) => null);

final pushListenerProvider = Provider<void>((ref) {
  final notificationsAsync = ref.watch(notificationsStreamProvider);

  notificationsAsync.whenData((notifications) {
    if (notifications.isEmpty) return;

    final newest = notifications.first;

    if (!newest.isUnread) return;

    final lastShownId = ref.read(_lastShownIdProvider);
    if (lastShownId == newest.id) return;

    ref.read(_lastShownIdProvider.notifier).state = newest.id;

    NotificationService.show(
      title: newest.title,
      body: newest.body,
      payload: newest.id,
    );
  });
});