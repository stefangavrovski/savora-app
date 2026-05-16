import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:savora_app/core/supabase_client.dart';
import 'package:savora_app/features/auth/providers/auth_provider.dart';
import 'package:savora_app/features/business/models/business.dart';

// The current business owner's business
final myBusinessProvider = FutureProvider<Business?>((ref) async {
  final userId = ref.watch(currentUserIdProvider);
  if (userId == null) return null;

  final data = await supabase
      .from('businesses')
      .select()
      .eq('owner_id', userId)
      .maybeSingle();

  if (data == null) return null;
  return Business.fromJson(data);
});

// All businesses (admin use)
final allBusinessesProvider = FutureProvider<List<Business>>((ref) async {
  final data = await supabase
      .from('businesses')
      .select()
      .order('created_at', ascending: false);

  return (data as List).map((e) => Business.fromJson(e)).toList();
});

// Pending businesses awaiting admin review
final pendingBusinessesProvider = FutureProvider<List<Business>>((ref) async {
  final data = await supabase
      .from('businesses')
      .select()
      .eq('verification_status', 'pending')
      .order('created_at', ascending: true);

  return (data as List).map((e) => Business.fromJson(e)).toList();
});

// Single business by id
final businessByIdProvider =
    FutureProvider.family<Business?, String>((ref, businessId) async {
  final data = await supabase
      .from('businesses')
      .select()
      .eq('id', businessId)
      .maybeSingle();

  if (data == null) return null;
  return Business.fromJson(data);
});

// Business onboarding notifier
class BusinessOnboardingNotifier extends AsyncNotifier<void> {
  @override
  Future<void> build() async {}

  Future<String> registerBusiness({
    required String name,
    required String description,
    required String address,
    required double latitude,
    required double longitude,
    required String category,
    required String edb,
    required String embs,
    String? phone,
    String? openingTime,
    String? closingTime,
  }) async {
    final userId = ref.read(currentUserIdProvider);
    if (userId == null) throw Exception('Not authenticated');

    final response = await supabase
        .from('businesses')
        .insert({
          'owner_id': userId,
          'name': name,
          'description': description,
          'address': address,
          'latitude': latitude,
          'longitude': longitude,
          'category': category,
          'edb': edb,
          'embs': embs,
          'phone': phone,
          'opening_time': openingTime,
          'closing_time': closingTime,
        })
        .select('id')
        .single();

    ref.invalidate(myBusinessProvider);
    return response['id'] as String;
  }

  Future<void> uploadDocument({
    required String businessId,
    required String documentType,
    required String storagePath,
  }) async {
    await supabase.from('business_documents').upsert({
      'business_id': businessId,
      'document_type': documentType,
      'storage_path': storagePath,
    });
  }

  Future<void> approveBusinessAdmin(String businessId) async {
    await supabase.rpc('fn_approve_business', params: {
      'p_business_id': businessId,
    });
    ref.invalidate(pendingBusinessesProvider);
    ref.invalidate(allBusinessesProvider);
  }

  Future<void> rejectBusinessAdmin({
    required String businessId,
    required String reason,
  }) async {
    await supabase.rpc('fn_reject_business', params: {
      'p_business_id': businessId,
      'p_reason': reason,
    });
    ref.invalidate(pendingBusinessesProvider);
    ref.invalidate(allBusinessesProvider);
  }
}

final businessOnboardingProvider =
    AsyncNotifierProvider<BusinessOnboardingNotifier, void>(
        () => BusinessOnboardingNotifier());