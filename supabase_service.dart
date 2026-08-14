import 'package:supabase_flutter/supabase_flutter.dart';

/// Thin wrapper around Supabase initialization so `main.dart` stays clean
/// and every other service pulls the client from one place.
///
/// Reads the URL and anon key from --dart-define so they never get
/// hard-coded into source (see Validation Rules: no hard-coded secrets).
///
/// Run with:
///   flutter run \
///     --dart-define=SUPABASE_URL=https://xxxx.supabase.co \
///     --dart-define=SUPABASE_ANON_KEY=your-anon-key
class SupabaseService {
  SupabaseService._();

  static const String _url = String.fromEnvironment('SUPABASE_URL');
  static const String _anonKey = String.fromEnvironment('SUPABASE_ANON_KEY');

  static Future<void> init() async {
    assert(
      _url.isNotEmpty && _anonKey.isNotEmpty,
      'SUPABASE_URL and SUPABASE_ANON_KEY must be supplied via --dart-define. '
      'See README > Environment Setup.',
    );
    await Supabase.initialize(
      url: _url,
      anonKey: _anonKey,
    );
  }

  static SupabaseClient get client => Supabase.instance.client;
}
