// Lee las variables de entorno pasadas con --dart-define o --dart-define-from-file.
// Configuración base para Prestamos con defaults directos para build nativo.
class Env {
  static const supabaseUrl = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: 'https://ucpsbxyjsiaoertcdvox.supabase.co',
  );
  static const supabaseAnonKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
    defaultValue: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InVjcHNieHlqc2lhb2VydGNkdm94Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3OTE3NDY2MDgsImV4cCI6MjEwNzMyMjYwOH0.EqOqcIodMkP0009AbUYr1M3fa6gXv29-3eYwMVLj74Y',
  );
  static const powersyncUrl = String.fromEnvironment(
    'POWERSYNC_URL',
    defaultValue: 'https://6acc0cabf0708554f16dab73.powersync.journeyapps.com',
  );
  static const powersyncTokenEndpoint = String.fromEnvironment(
    'POWERSYNC_TOKEN_ENDPOINT',
    defaultValue: 'https://ucpsbxyjsiaoertcdvox.supabase.co/functions/v1/powersync-auth',
  );

  static bool get isConfigured =>
      supabaseUrl.isNotEmpty &&
      supabaseAnonKey.isNotEmpty &&
      powersyncUrl.isNotEmpty &&
      powersyncTokenEndpoint.isNotEmpty;
}
