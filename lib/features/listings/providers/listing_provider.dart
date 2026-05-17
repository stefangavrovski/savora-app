import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:savora_app/core/supabase_client.dart';
import 'package:savora_app/features/auth/providers/auth_provider.dart';
import 'package:savora_app/features/listings/models/bag_listing.dart';

// Listings near a lat/lng point — uses the PostGIS RPC function
final nearbyListingsProvider =
    FutureProvider.family<List<BagListing>, ({double lat, double lng})>(
        (ref, coords) async {
  final data = await supabase.rpc('fn_listings_near_point', params: {
    'p_lat': coords.lat,
    'p_lng': coords.lng,
    'p_radius': 5000,
  });

  return (data as List).map((e) => BagListing.fromJson(e)).toList();
});

// Real-time stream for a single listing (quantity updates, sold out, etc.)
final listingStreamProvider =
    StreamProvider.family<BagListing?, String>((ref, listingId) {
  return supabase
      .from('bag_listings')
      .stream(primaryKey: ['id'])
      .eq('id', listingId)
      .map((rows) => rows.isEmpty ? null : BagListing.fromJson(rows.first));
});

// Fetch a single listing by id (one-shot, for detail screen)
final listingByIdProvider =
    FutureProvider.family<BagListing?, String>((ref, listingId) async {
  final data = await supabase
      .from('bag_listings')
      .select('''
        *,
        businesses (
          name,
          address,
          logo_url,
          latitude,
          longitude,
          phone,
          category
        )
      ''')
      .eq('id', listingId)
      .single();

  // Flatten nested business fields
  final business = data['businesses'] as Map<String, dynamic>?;
  final flat = {
    ...data,
    'business_name': business?['name'],
    'logo_url': business?['logo_url'],
    'address': business?['address'],
    'latitude': business?['latitude'],
    'longitude': business?['longitude'],
  };

  return BagListing.fromJson(flat);
});

// Business owner's own listings
final myListingsProvider = FutureProvider<List<BagListing>>((ref) async {
  final userId = ref.watch(currentUserIdProvider);
  if (userId == null) return [];

  final data = await supabase
      .from('bag_listings')
      .select('''
        *,
        businesses!inner ( owner_id )
      ''')
      .eq('businesses.owner_id', userId)
      .order('created_at', ascending: false);

  return (data as List).map((e) => BagListing.fromJson(e)).toList();
});

// Create listing notifier
class CreateListingNotifier extends AsyncNotifier<void> {
  @override
  Future<void> build() async {}

  Future<void> createListing({
    required String businessId,
    required String title,
    required String description,
    required double price,
    required double originalValue,
    required int quantityTotal,
    required DateTime pickupStart,
    required DateTime pickupEnd,
    int? estWeightGrams,
    String? imageUrl,
  }) async {
    await supabase.from('bag_listings').insert({
      'business_id': businessId,
      'title': title,
      'description': description,
      'price': price,
      'original_value': originalValue,
      'quantity_total': quantityTotal,
      'quantity_available': quantityTotal,
      'pickup_start': pickupStart.toIso8601String(),
      'pickup_end': pickupEnd.toIso8601String(),
      if (estWeightGrams != null) 'est_weight_grams': estWeightGrams,
      if (imageUrl != null) 'image_url': imageUrl,
    });

    ref.invalidate(myListingsProvider);
  }

  Future<void> cancelListing(String listingId) async {
    await supabase
        .from('bag_listings')
        .update({'status': 'cancelled'}).eq('id', listingId);

    ref.invalidate(myListingsProvider);
  }
}

final createListingProvider =
    AsyncNotifierProvider<CreateListingNotifier, void>(
        () => CreateListingNotifier());