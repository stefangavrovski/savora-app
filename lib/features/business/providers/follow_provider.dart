import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:savora_app/core/supabase_client.dart';
import 'package:savora_app/features/auth/providers/auth_provider.dart';

final isFollowingProvider =
    FutureProvider.family<bool, String>((ref, businessId) async {
  final userId = ref.watch(currentUserIdProvider);
  if (userId == null) return false;

  final data = await supabase
      .from('business_follows')
      .select('business_id')
      .eq('customer_id', userId)
      .eq('business_id', businessId)
      .maybeSingle();

  return data != null;
});

class FollowNotifier extends AsyncNotifier<void> {
  @override
  Future<void> build() async {}

  Future<void> follow(String businessId) async {
    final userId = ref.read(currentUserIdProvider);
    if (userId == null) throw Exception('Not authenticated');

    await supabase.from('business_follows').insert({
      'customer_id': userId,
      'business_id': businessId,
    });

    ref.invalidate(isFollowingProvider(businessId));
  }

  Future<void> unfollow(String businessId) async {
    final userId = ref.read(currentUserIdProvider);
    if (userId == null) throw Exception('Not authenticated');

    await supabase
        .from('business_follows')
        .delete()
        .eq('customer_id', userId)
        .eq('business_id', businessId);

    ref.invalidate(isFollowingProvider(businessId));
  }
}

final followNotifierProvider =
    AsyncNotifierProvider<FollowNotifier, void>(() => FollowNotifier());