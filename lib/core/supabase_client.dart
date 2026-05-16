import 'package:supabase_flutter/supabase_flutter.dart';

/// Convenience accessor — use `supabase` anywhere in the app
/// instead of `Supabase.instance.client`
SupabaseClient get supabase => Supabase.instance.client;