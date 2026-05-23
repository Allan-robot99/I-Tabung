class SupabaseConfig {
  // Configure with --dart-define=SUPABASE_URL / SUPABASE_ANON_KEY
  // or through local environment tooling outside version control.
  static const url = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: '',
  );

  static const anonKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
    defaultValue: '',
  );

  static bool get isConfigured => url.isNotEmpty && anonKey.isNotEmpty;
}
