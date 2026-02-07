import 'package:supabase_flutter/supabase_flutter.dart';

/// Supabase configuration and initialization
class SupabaseConfig {
  SupabaseConfig._();

  // Supabase project credentials
  static const String supabaseUrl = 'https://zzyyibrckbbjdfsitlje.supabase.co';
  static const String supabaseAnonKey =
      'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Inp6eXlpYnJja2JiamRmc2l0bGplIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzAzMTMxOTAsImV4cCI6MjA4NTg4OTE5MH0.oj1-P2ETNKB03NeBdGjsfElbn2n0Cd1m0w3LNrqJgKI';

  /// Initialize Supabase client
  static Future<void> initialize() async {
    await Supabase.initialize(
      url: supabaseUrl,
      anonKey: supabaseAnonKey,
      authOptions: const FlutterAuthClientOptions(
        authFlowType: AuthFlowType.pkce,
      ),
      realtimeClientOptions: const RealtimeClientOptions(
        logLevel: RealtimeLogLevel.info,
      ),
    );
  }

  /// Get the Supabase client instance
  static SupabaseClient get client => Supabase.instance.client;

  /// Get the auth instance
  static GoTrueClient get auth => client.auth;

  /// Get the current user
  static User? get currentUser => auth.currentUser;

  /// Get the current session
  static Session? get currentSession => auth.currentSession;

  /// Check if user is authenticated
  static bool get isAuthenticated => currentUser != null;
}
