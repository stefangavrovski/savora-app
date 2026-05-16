import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:savora_app/core/supabase_client.dart';

// Raw Supabase auth state stream
final authStateProvider = StreamProvider<AuthState>((ref) {
  return supabase.auth.onAuthStateChange;
});

// Convenience: current session (nullable)
final currentSessionProvider = Provider<Session?>((ref) {
  return ref.watch(authStateProvider).value?.session;
});

// Convenience: current user id (nullable)
final currentUserIdProvider = Provider<String?>((ref) {
  return ref.watch(currentSessionProvider)?.user.id;
});