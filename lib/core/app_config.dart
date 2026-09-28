class AppConfig {
  // AFD Søkshund deler Supabase-prosjekt med AFD IMT/Lager.
  // Publishable key er laget for bruk i klientapper. Service-role brukes aldri i appen.
  static const supabaseUrl = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: 'https://lgpodkznfuvxpmpzpuau.supabase.co',
  );

  static const supabasePublishableKey = String.fromEnvironment(
    'SUPABASE_PUBLISHABLE_KEY',
    defaultValue: 'sb_publishable_QxKMUrgFhVtwtrzu009_bQ_oOg8DUX3',
  );

  static bool get isConfigured =>
      supabaseUrl.isNotEmpty && supabasePublishableKey.isNotEmpty;
}
