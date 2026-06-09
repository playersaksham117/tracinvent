import 'package:supabase_flutter/supabase_flutter.dart';

/// ⚠️ NOT ACTIVE — call SupabaseConfig.initialize() only when auth is activated.
///
/// Set your real keys in:
///   SUPABASE_URL  = https://your-project.supabase.co
///   SUPABASE_ANON_KEY = eyJ...
///
/// For production, inject via --dart-define in CI:
///   flutter run --dart-define=SUPABASE_URL=... --dart-define=SUPABASE_ANON_KEY=...
class SupabaseConfig {
  static const String url = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: 'https://YOUR_PROJECT.supabase.co',
  );

  static const String anonKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
    defaultValue: 'YOUR_ANON_KEY',
  );

  static SupabaseClient get client => Supabase.instance.client;

  /// Call this once in main() BEFORE runApp() — only when activating the system.
  static Future<void> initialize() async {
    await Supabase.initialize(
      url: url,
      anonKey: anonKey,
      authOptions: const FlutterAuthClientOptions(
        authFlowType: AuthFlowType.pkce,
        autoRefreshToken: true,
      ),
    );
  }
}
