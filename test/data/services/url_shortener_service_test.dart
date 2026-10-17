import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:prestamo/data/services/url_shortener_service.dart';

void main() {
  setUp(UrlShortenerService.clearCache);

  test('acortar devuelve enlace corto desde TinyURL y usa caché en llamadas repetidas', () async {
    var llamadas = 0;
    final mockClient = MockClient((request) async {
      llamadas++;
      expect(request.url.host, 'tinyurl.com');
      return http.Response('https://tinyurl.com/2aexhnrg\n', 200);
    });

    const supabasePdfUrl =
        'https://ucpsbxyjsiaoertcdvox.supabase.co/storage/v1/object/public/recibos-pdf/tenant1/recibo1.pdf';

    final res1 = await UrlShortenerService.acortar(
      supabasePdfUrl,
      client: mockClient,
    );
    expect(res1, 'https://tinyurl.com/2aexhnrg');
    expect(res1.contains('supabase'), isFalse);
    expect(llamadas, 1);

    // Segunda llamada para el mismo PDF sale de caché sin red
    final res2 = await UrlShortenerService.acortar(
      supabasePdfUrl,
      client: mockClient,
    );
    expect(res2, 'https://tinyurl.com/2aexhnrg');
    expect(llamadas, 1);
  });

  test('acortar hace fallback al segundo proveedor si el primero falla o devuelve error', () async {
    final hostsIntentados = <String>[];
    final mockClient = MockClient((request) async {
      hostsIntentados.add(request.url.host);
      if (request.url.host == 'tinyurl.com') {
        return http.Response('Error, database insert failed', 200);
      }
      if (request.url.host == 'da.gd') {
        return http.Response('https://da.gd/c5tlS\n', 200);
      }
      return http.Response('Not found', 500);
    });

    const supabasePdfUrl =
        'https://ucpsbxyjsiaoertcdvox.supabase.co/storage/v1/object/public/recibos-pdf/tenant1/proforma_1.pdf';

    final res = await UrlShortenerService.acortar(
      supabasePdfUrl,
      client: mockClient,
    );
    expect(res, 'https://da.gd/c5tlS');
    expect(hostsIntentados, ['tinyurl.com', 'da.gd']);
  });

  test('acortar nunca expone la URL de Supabase si todos los proveedores fallan', () async {
    final mockClient = MockClient((_) async => http.Response('Service down', 503));

    const supabasePdfUrl =
        'https://ucpsbxyjsiaoertcdvox.supabase.co/storage/v1/object/public/recibos-pdf/tenant1/recibo2.pdf';

    final res = await UrlShortenerService.acortar(
      supabasePdfUrl,
      client: mockClient,
    );
    expect(res, isEmpty);
    expect(res.contains('supabase'), isFalse);
  });
}
