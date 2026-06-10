class SupabaseConfig {
  static const String url = String.fromEnvironment('SUPABASE_URL');
  static const String publishableKey =
      String.fromEnvironment('SUPABASE_PUBLISHABLE_KEY');
  static const String anonKey = String.fromEnvironment('SUPABASE_ANON_KEY');

  static String get resolvedKey =>
      publishableKey.isNotEmpty ? publishableKey : anonKey;

  static bool get isConfigured => url.isNotEmpty && resolvedKey.isNotEmpty;
}