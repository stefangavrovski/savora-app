import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:savora_app/core/supabase_client.dart';
import 'package:savora_app/core/geofencing_service.dart';

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

// Geofencing lifecycle — watches auth and starts/stops the service automatically
final geofencingLifecycleProvider = Provider<void>((ref) {
  final authAsync = ref.watch(authStateProvider);

  authAsync.whenData((state) {
    if (state.event == AuthChangeEvent.signedIn) {
      GeofencingService.instance.start();
    } else if (state.event == AuthChangeEvent.signedOut) {
      GeofencingService.instance.stop();
    }
  });
});