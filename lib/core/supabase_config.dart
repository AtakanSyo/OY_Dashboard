class SupabaseConfig {
  static const String url = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: 'https://iytzfqfhlqcboohtpugh.supabase.co',
  );

  // Public publishable key — safe to embed in client apps.
  // Never embed an sb_secret_... or service_role key here.
  static const String publishableKey = String.fromEnvironment(
    'SUPABASE_PUBLISHABLE_KEY',
    defaultValue: String.fromEnvironment(
      // Geçiş sürecindeki eski build komutları için geriye uyumluluk.
      'SUPABASE_ANON_KEY',
      defaultValue: 'sb_publishable_lsEJ2rlxDeiWK4hr46mmng_hlnynFG2',
    ),
  );
}
