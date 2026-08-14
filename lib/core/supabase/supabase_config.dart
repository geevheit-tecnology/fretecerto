class SupabaseConfig {
  const SupabaseConfig._();

  static const url = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: 'https://fnjfdrbxdszrrevzvost.supabase.co',
  );

  static const publishableKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
    defaultValue: 'sb_publishable_7NwGju-no0OnnBJbh_6CCQ_n7ymvHDU',
  );
}
