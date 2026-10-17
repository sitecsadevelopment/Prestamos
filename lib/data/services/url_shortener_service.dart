import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

/// Servicio para acortar enlaces de PDFs (recibos y proformas) antes de
/// compartirlos por WhatsApp, evitando exponer la URL de Supabase Storage
/// (`*.supabase.co/storage/v1/object/public/...`).
class UrlShortenerService {
  UrlShortenerService._();

  static final Map<String, String> _cache = {};

  /// Limpia la caché en memoria (útil para tests).
  @visibleForTesting
  static void clearCache() => _cache.clear();

  /// Acorta [longUrl] usando una cadena de proveedores públicos sin API key
  /// (`tinyurl.com` → `da.gd` → `clck.ru`) con timeout corto por intento.
  ///
  /// - Si alguno responde con una URL `https://` válida que no contenga
  ///   `supabase`, la guarda en caché y la devuelve.
  /// - Si todos fallan (ej. sin conexión), devuelve `''` para no exponer jamás
  ///   la dirección cruda de Supabase en el mensaje de WhatsApp.
  static Future<String> acortar(
    String longUrl, {
    http.Client? client,
    Duration timeout = const Duration(seconds: 4),
  }) async {
    final limpia = longUrl.trim();
    if (limpia.isEmpty) return '';

    final cacheada = _cache[limpia];
    if (cacheada != null && cacheada.isNotEmpty) {
      return cacheada;
    }

    final encoded = Uri.encodeComponent(limpia);
    final endpoints = <String>[
      'https://tinyurl.com/api-create.php?url=$encoded',
      'https://da.gd/s?url=$encoded',
      'https://clck.ru/--?url=$encoded',
    ];

    final httpClient = client ?? http.Client();
    final debeCerrar = client == null;

    try {
      for (final endpoint in endpoints) {
        try {
          final response =
              await httpClient.get(Uri.parse(endpoint)).timeout(timeout);
          if (response.statusCode == 200) {
            final candidato = response.body.trim();
            if (_esUrlCortaValida(candidato)) {
              _cache[limpia] = candidato;
              return candidato;
            }
          }
        } catch (e) {
          debugPrint('UrlShortenerService fallo en $endpoint: $e');
        }
      }
    } finally {
      if (debeCerrar) {
        httpClient.close();
      }
    }

    return '';
  }

  static bool _esUrlCortaValida(String valor) {
    if (!valor.startsWith('https://')) return false;
    if (valor.contains(' ') || valor.contains('\n') || valor.contains('\r')) {
      return false;
    }
    if (valor.toLowerCase().contains('supabase')) return false;
    final uri = Uri.tryParse(valor);
    return uri != null && uri.host.isNotEmpty && uri.path.length > 1;
  }
}
