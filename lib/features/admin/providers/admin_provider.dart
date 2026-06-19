import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:savora_app/core/supabase_client.dart';
import 'package:savora_app/features/business/models/business.dart';

final businessDetailProvider =
    FutureProvider.family<Business?, String>((ref, businessId) async {
  final data = await supabase
      .from('businesses')
      .select()
      .eq('id', businessId)
      .maybeSingle();

  if (data == null) return null;
  return Business.fromJson(data);
});

final businessDocumentsProvider =
    FutureProvider.family<List<Map<String, dynamic>>, String>(
        (ref, businessId) async {
  // 1. Fetch document rows
  final rows = await supabase
      .from('business_documents')
      .select()
      .eq('business_id', businessId);

  final List<Map<String, dynamic>> result = [];

  for (final row in (rows as List)) {
    final doc = Map<String, dynamic>.from(row as Map);
    final storagePath = doc['storage_path'] as String?;

    if (storagePath != null) {
      try {
        // 2. Generate a signed URL valid for 60 minutes
        final signedUrl = await supabase.storage
            .from('business-documents')
            .createSignedUrl(storagePath, 3600);
        doc['signed_url'] = signedUrl;
      } catch (_) {
        doc['signed_url'] = null;
      }
    } else {
      doc['signed_url'] = null;
    }

    result.add(doc);
  }

  return result;
});

final allUsersProvider =
    FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final data = await supabase
      .from('profiles')
      .select('id, full_name, role, created_at')
      .order('created_at', ascending: false);

  return (data as List)
      .map((j) => Map<String, dynamic>.from(j as Map))
      .toList();
});

class AdminActionsNotifier extends AsyncNotifier<void> {
  @override
  Future<void> build() async {}

  Future<void> approveBusiness(String businessId) async {
    final adminId = supabase.auth.currentUser?.id;
    if (adminId == null) throw Exception('Not authenticated');

    await supabase.rpc('approve_business', params: {
      'p_business_id': businessId,
      'p_admin_id': adminId,
    });
  }

  Future<void> rejectBusiness(String businessId) async {
    final adminId = supabase.auth.currentUser?.id;
    if (adminId == null) throw Exception('Not authenticated');

    await supabase.rpc('reject_business', params: {
      'p_business_id': businessId,
      'p_admin_id': adminId,
    });
  }
}

final adminActionsProvider =
    AsyncNotifierProvider<AdminActionsNotifier, void>(
        AdminActionsNotifier.new);