import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:savora_app/core/supabase_client.dart';
import 'package:savora_app/features/auth/providers/auth_provider.dart';
import 'package:savora_app/features/reservations/providers/reservation_provider.dart';
import 'package:savora_app/features/reservations/models/review.dart';

// Whether a review already exists for a given reservation —
// used to decide whether to show "Leave a review" or "Reviewed".
final reviewExistsProvider =
    FutureProvider.family<bool, String>((ref, reservationId) async {
  final data = await supabase
      .from('reviews')
      .select('id')
      .eq('reservation_id', reservationId)
      .maybeSingle();

  return data != null;
});

class ReviewNotifier extends AsyncNotifier<void> {
  @override
  Future<void> build() async {}

  Future<void> submitReview({
    required String reservationId,
    required String businessId,
    required int rating,
    String? comment,
  }) async {
    final userId = ref.read(currentUserIdProvider);
    if (userId == null) throw Exception('Not authenticated');

    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      await supabase.from('reviews').insert({
        'reservation_id': reservationId,
        'customer_id': userId,
        'business_id': businessId,
        'rating': rating,
        'comment': comment,
      });

      ref.invalidate(reviewExistsProvider(reservationId));
      ref.invalidate(myReservationsProvider);
    });
  }
}

final reviewNotifierProvider =
    AsyncNotifierProvider<ReviewNotifier, void>(() => ReviewNotifier());

// Summary stats for a business — average rating and review count,
// read from the v_business_analytics view that already exists in the schema.
class BusinessRatingSummary {
  final double averageRating;
  final int reviewCount;
 
  const BusinessRatingSummary({
    required this.averageRating,
    required this.reviewCount,
  });
}
 
final businessRatingSummaryProvider =
    FutureProvider.family<BusinessRatingSummary, String>(
        (ref, businessId) async {
  final data = await supabase
      .from('v_business_analytics')
      .select('average_rating, review_count')
      .eq('business_id', businessId)
      .maybeSingle();
 
  if (data == null) {
    return const BusinessRatingSummary(averageRating: 0, reviewCount: 0);
  }
 
  return BusinessRatingSummary(
    averageRating: double.parse(data['average_rating'].toString()),
    reviewCount: data['review_count'] as int,
  );
});
 
// Individual reviews for a business, newest first, with the
// reviewing customer's display name joined in.
final businessReviewsProvider =
    FutureProvider.family<List<Review>, String>((ref, businessId) async {
  final data = await supabase
      .from('reviews')
      .select('''
        *,
        profiles ( full_name )
      ''')
      .eq('business_id', businessId)
      .order('created_at', ascending: false);
 
  return (data as List).map((e) => Review.fromJson(e)).toList();
});