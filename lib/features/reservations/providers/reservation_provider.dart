import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:savora_app/core/supabase_client.dart';
import 'package:savora_app/features/auth/providers/auth_provider.dart';
import 'package:savora_app/features/reservations/models/reservation.dart';

// Current customer's reservations
final myReservationsProvider = FutureProvider<List<Reservation>>((ref) async {
  final userId = ref.watch(currentUserIdProvider);
  if (userId == null) return [];

  final data = await supabase
      .from('reservations')
      .select('''
        *,
        bag_listings (
          title,
          price,
          image_url,
          pickup_start,
          pickup_end,
          businesses ( name, address )
        )
      ''')
      .eq('customer_id', userId)
      .order('created_at', ascending: false);

  return (data as List).map((e) => Reservation.fromJson(e)).toList();
});

// Single reservation by id
final reservationByIdProvider =
    FutureProvider.family<Reservation?, String>((ref, reservationId) async {
  final data = await supabase
      .from('reservations')
      .select('''
        *,
        bag_listings (
          title,
          price,
          image_url,
          pickup_start,
          pickup_end,
          businesses ( name, address )
        )
      ''')
      .eq('id', reservationId)
      .single();

  return Reservation.fromJson(data);
});

// Business owner — reservations for their listings (real-time stream)
final businessReservationsProvider =
    StreamProvider.family<List<Reservation>, String>(
        (ref, businessId) {
  return supabase
      .from('reservations')
      .stream(primaryKey: ['id'])
      .map((rows) => rows.map((e) => Reservation.fromJson(e)).toList());
});

// Reservation actions notifier
class ReservationNotifier extends AsyncNotifier<void> {
  @override
  Future<void> build() async {}

  // Uses the atomic make_reservation() RPC — handles race conditions
  Future<String> makeReservation(String listingId) async {
    final userId = ref.read(currentUserIdProvider);
    if (userId == null) throw Exception('Not authenticated');

    final result = await supabase.rpc('make_reservation', params: {
      'p_listing_id': listingId,
      'p_customer_id': userId,
    });

    ref.invalidate(myReservationsProvider);
    // result is the reservation id
    return result as String;
  }

  // Uses the atomic cancel_reservation() RPC
  Future<void> cancelReservation(String reservationId) async {
    await supabase.rpc('cancel_reservation', params: {
      'p_reservation_id': reservationId,
    });
    ref.invalidate(myReservationsProvider);
  }

  // Uses the atomic complete_reservation() RPC — called by business pickup counter
  Future<Map<String, dynamic>> completeByPickupCode(String code) async {
    final reservation = await supabase.rpc(
      'get_reservation_by_pickup_code',
      params: {'p_pickup_code': code.toUpperCase()},
    );

    if (reservation == null) throw Exception('Code not found');

    await supabase.rpc('complete_reservation', params: {
      'p_reservation_id': reservation['id'],
    });

    return reservation as Map<String, dynamic>;
  }
}

final reservationNotifierProvider =
    AsyncNotifierProvider<ReservationNotifier, void>(
        () => ReservationNotifier());