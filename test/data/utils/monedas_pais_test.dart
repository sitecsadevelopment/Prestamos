import 'package:flutter_test/flutter_test.dart';
import 'package:prestamo/data/utils/formatters.dart';
import 'package:prestamo/data/utils/monedas_pais.dart';
import 'package:prestamo/data/utils/monto_a_letras.dart';

void main() {
  setUp(() {
    // Restaurar a default (Nicaragua) antes de cada test
    Fmt.configurarMoneda(kMonedaPaisDefault);
  });

  group('Catálogo de Monedas de América (kMonedasAmerica)', () {
    test('contiene todos los países de América esperados', () {
      expect(kMonedasAmerica.length, greaterThanOrEqualTo(28));
      final codigos = kMonedasAmerica.map((m) => m.codigoPais).toSet();
      // Centroamérica
      expect(codigos, containsAll(['NI', 'GT', 'HN', 'SV', 'CR', 'PA', 'BZ']));
      // Norteamérica
      expect(codigos, containsAll(['US', 'MX', 'CA']));
      // Sudamérica
      expect(codigos, containsAll(['CO', 'PE', 'EC', 'CL', 'AR', 'BO', 'PY', 'UY', 'BR', 'VE']));
      // Caribe
      expect(codigos, containsAll(['DO', 'CU', 'PR', 'HT', 'JM']));
    });

    test('todos los IDs son únicos', () {
      final ids = kMonedasAmerica.map((m) => m.id).toList();
      expect(ids.toSet().length, equals(ids.length));
    });

    test('países dolarizados tienen bandera esDolarizada y símbolo US\$', () {
      final sv = monedaPaisPorCodigo('SV');
      expect(sv.esDolarizada, isTrue);
      expect(sv.simbolo, 'US\$');

      final ec = monedaPaisPorCodigo('EC');
      expect(ec.esDolarizada, isTrue);
      expect(ec.simbolo, 'US\$');

      final pa = monedaPaisPorCodigo('PA');
      expect(pa.esDolarizada, isTrue);
      expect(pa.simbolo, 'US\$');
    });

    test('monedaPaisPorCodigo busca por país y por moneda insensible a mayúsculas', () {
      expect(monedaPaisPorCodigo('gt').nombrePais, 'Guatemala');
      expect(monedaPaisPorCodigo('GTQ').nombrePais, 'Guatemala');
      expect(monedaPaisPorCodigo('hn').nombrePais, 'Honduras');
      expect(monedaPaisPorCodigo('HNL').nombrePais, 'Honduras');
      expect(monedaPaisPorCodigo('cr').nombrePais, 'Costa Rica');
      expect(monedaPaisPorCodigo('CRC').nombrePais, 'Costa Rica');
      expect(monedaPaisPorCodigo('pe').nombrePais, 'Perú');
      expect(monedaPaisPorCodigo('PEN').nombrePais, 'Perú');
      expect(monedaPaisPorCodigo('do').nombrePais, 'República Dominicana');
    });

    test('código desconocido hace fallback seguro a Nicaragua', () {
      final fallback = monedaPaisPorCodigo('XX');
      expect(fallback.codigoPais, 'NI');
      expect(fallback.simbolo, 'C\$');
    });
  });

  group('Fmt con configuración dinámica de moneda', () {
    test('default es Nicaragua C\$', () {
      expect(Fmt.monedaActual.codigoPais, 'NI');
      expect(Fmt.simboloLocal, 'C\$');
      expect(Fmt.nombreMonedaLocal, 'Córdoba');
      expect(Fmt.esPaisDolarizado, isFalse);
      expect(Fmt.cordobas(500), contains('C\$'));
    });

    test('cambiar a Guatemala actualiza símbolo a Q y nombre a Quetzal', () {
      final guatemala = monedaPaisPorCodigo('GT');
      Fmt.configurarMoneda(guatemala);

      expect(Fmt.monedaActual.codigoPais, 'GT');
      expect(Fmt.simboloLocal, 'Q');
      expect(Fmt.nombreMonedaLocal, 'Quetzal');
      expect(Fmt.esPaisDolarizado, isFalse);
      expect(Fmt.cordobas(500), contains('Q'));
      expect(Fmt.monto(500, 'NIO'), contains('Q'));
      expect(Fmt.monto(500, 'USD'), contains('US\$'));
    });

    test('cambiar a Honduras actualiza símbolo a L y nombre a Lempira', () {
      final honduras = monedaPaisPorCodigo('HN');
      Fmt.configurarMoneda(honduras);

      expect(Fmt.monedaActual.codigoPais, 'HN');
      expect(Fmt.simboloLocal, 'L');
      expect(Fmt.nombreMonedaLocal, 'Lempira');
      expect(Fmt.cordobas(1250.50), contains('L'));
    });

    test('cambiar a Perú actualiza símbolo a S/ y nombre a Sol', () {
      final peru = monedaPaisPorCodigo('PE');
      Fmt.configurarMoneda(peru);

      expect(Fmt.monedaActual.codigoPais, 'PE');
      expect(Fmt.simboloLocal, 'S/');
      expect(Fmt.nombreMonedaLocal, 'Sol');
      expect(Fmt.cordobas(350), contains('S/'));
    });

    test('país dolarizado (El Salvador) marca esPaisDolarizado = true', () {
      final elSalvador = monedaPaisPorCodigo('SV');
      Fmt.configurarMoneda(elSalvador);

      expect(Fmt.esPaisDolarizado, isTrue);
      expect(Fmt.simboloLocal, 'US\$');
    });
  });

  group('montoALetras dinámico según país/moneda', () {
    test('Nicaragua produce CÓRDOBAS', () {
      Fmt.configurarMoneda(kMonedaPaisDefault);
      final letras = montoALetras(100.50, moneda: 'NIO');
      expect(letras, contains('CIEN'));
      expect(letras, contains('CÓRDOBAS'));
      expect(letras, contains('50/100'));
    });

    test('Guatemala produce QUETZALES', () {
      Fmt.configurarMoneda(monedaPaisPorCodigo('GT'));
      final letras = montoALetras(100.50, moneda: 'NIO');
      expect(letras, contains('CIEN'));
      expect(letras, contains('QUETZALES'));
      expect(letras, contains('50/100'));
    });

    test('Honduras produce LEMPIRAS', () {
      Fmt.configurarMoneda(monedaPaisPorCodigo('HN'));
      final letras = montoALetras(100.50, moneda: 'NIO');
      expect(letras, contains('CIEN'));
      expect(letras, contains('LEMPIRAS'));
      expect(letras, contains('50/100'));
    });

    test('Perú produce SOLES', () {
      Fmt.configurarMoneda(monedaPaisPorCodigo('PE'));
      final letras = montoALetras(1, moneda: 'NIO');
      expect(letras, contains('UN'));
      expect(letras, contains('SOL'));

      final letrasPlural = montoALetras(200, moneda: 'NIO');
      expect(letrasPlural, contains('DOSCIENTOS'));
      expect(letrasPlural, contains('SOLES'));
    });

    test('moneda USD produce DÓLARES independientemente del país', () {
      Fmt.configurarMoneda(monedaPaisPorCodigo('GT'));
      final letras = montoALetras(100.50, moneda: 'USD');
      expect(letras, contains('DÓLARES'));
    });
  });
}
