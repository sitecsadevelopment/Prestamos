/// Catálogo de países y monedas de toda América (Norteamérica, Centroamérica,
/// Caribe y Sudamérica) para configurar la moneda local del tenant.
///
/// La clave de configuración en `settings` es `moneda.principal` (default `'NIO'`).
/// En la base de datos (`pagos.moneda`), el valor `'NIO'` representa internamente
/// la moneda local del tenant (con `tasa_conversion = 1`), mientras que `'USD'`
/// representa el Dólar estadounidense con conversión según `pagos.tasa_usd_cordoba`.
library;

class MonedaPais {
  const MonedaPais({
    required this.id,
    required this.codigoPais,
    required this.nombrePais,
    required this.bandera,
    required this.codigoMoneda,
    required this.simbolo,
    required this.nombreSingular,
    required this.nombrePluralLetras,
    required this.prefijoTel,
    required this.region,
  });

  /// Identificador único guardado en `settings` (`moneda.principal`).
  /// Para países con moneda única coincide con [codigoMoneda] (ej. `'NIO'`, `'HNL'`).
  /// Para países dolarizados distingue el país (ej. `'USD'`, `'USD_SV'`, `'USD_PA'`, `'USD_EC'`).
  final String id;

  /// Código ISO 3166-1 alpha-2 del país (ej. `'NI'`, `'HN'`, `'MX'`).
  final String codigoPais;

  /// Nombre del país en español.
  final String nombrePais;

  /// Emoji de bandera del país.
  final String bandera;

  /// Código ISO 4217 de la moneda (ej. `'NIO'`, `'HNL'`, `'MXN'`, `'USD'`).
  final String codigoMoneda;

  /// Símbolo monetario mostrado antes de los montos (ej. `'C$'`, `'L'`, `'Q'`, `'S/'`).
  final String simbolo;

  /// Nombre singular de la moneda (ej. `'Córdoba'`, `'Lempira'`, `'Sol'`).
  final String nombreSingular;

  /// Nombre plural en mayúsculas para recibos en letras (ej. `'CÓRDOBAS'`, `'LEMPIRAS'`).
  final String nombrePluralLetras;

  /// Prefijo telefónico internacional sin `+` (ej. `'505'`, `'504'`, `'52'`).
  final String prefijoTel;

  /// Región geográfica de América para agrupar o describir.
  final String region;

  /// `true` cuando la moneda local del país ya es el Dólar estadounidense (`USD`).
  bool get esDolarizada => codigoMoneda == 'USD';

  /// Etiqueta corta para chips de selección (ej. `'C$ (Córdoba)'` o `'L (Lempira)'`).
  String get etiquetaChip => '$simbolo ($nombreSingular)';

  /// Etiqueta completa para el selector en Configuración.
  String get etiquetaSelector =>
      '$bandera $nombrePais — $nombreSingular ($simbolo · $codigoMoneda)';
}

/// Catálogo completo de países y monedas de América.
const List<MonedaPais> kMonedasAmerica = [
  // ── Centroamérica ──────────────────────────────────────────────────────────
  MonedaPais(
    id: 'NIO',
    codigoPais: 'NI',
    nombrePais: 'Nicaragua',
    bandera: '🇳🇮',
    codigoMoneda: 'NIO',
    simbolo: r'C$',
    nombreSingular: 'Córdoba',
    nombrePluralLetras: 'CÓRDOBAS',
    prefijoTel: '505',
    region: 'Centroamérica',
  ),
  MonedaPais(
    id: 'HNL',
    codigoPais: 'HN',
    nombrePais: 'Honduras',
    bandera: '🇭🇳',
    codigoMoneda: 'HNL',
    simbolo: 'L',
    nombreSingular: 'Lempira',
    nombrePluralLetras: 'LEMPIRAS',
    prefijoTel: '504',
    region: 'Centroamérica',
  ),
  MonedaPais(
    id: 'GTQ',
    codigoPais: 'GT',
    nombrePais: 'Guatemala',
    bandera: '🇬🇹',
    codigoMoneda: 'GTQ',
    simbolo: 'Q',
    nombreSingular: 'Quetzal',
    nombrePluralLetras: 'QUETZALES',
    prefijoTel: '502',
    region: 'Centroamérica',
  ),
  MonedaPais(
    id: 'CRC',
    codigoPais: 'CR',
    nombrePais: 'Costa Rica',
    bandera: '🇨🇷',
    codigoMoneda: 'CRC',
    simbolo: '₡',
    nombreSingular: 'Colón',
    nombrePluralLetras: 'COLONES',
    prefijoTel: '506',
    region: 'Centroamérica',
  ),
  MonedaPais(
    id: 'USD_SV',
    codigoPais: 'SV',
    nombrePais: 'El Salvador',
    bandera: '🇸🇻',
    codigoMoneda: 'USD',
    simbolo: r'US$',
    nombreSingular: 'Dólar',
    nombrePluralLetras: 'DÓLARES',
    prefijoTel: '503',
    region: 'Centroamérica',
  ),
  MonedaPais(
    id: 'USD_PA',
    codigoPais: 'PA',
    nombrePais: 'Panamá',
    bandera: '🇵🇦',
    codigoMoneda: 'USD',
    simbolo: r'US$',
    nombreSingular: 'Dólar / Balboa',
    nombrePluralLetras: 'DÓLARES',
    prefijoTel: '507',
    region: 'Centroamérica',
  ),
  MonedaPais(
    id: 'BZD',
    codigoPais: 'BZ',
    nombrePais: 'Belice',
    bandera: '🇧🇿',
    codigoMoneda: 'BZD',
    simbolo: r'BZ$',
    nombreSingular: 'Dólar beliceño',
    nombrePluralLetras: 'DÓLARES BELICEÑOS',
    prefijoTel: '501',
    region: 'Centroamérica',
  ),

  // ── Norteamérica ───────────────────────────────────────────────────────────
  MonedaPais(
    id: 'MXN',
    codigoPais: 'MX',
    nombrePais: 'México',
    bandera: '🇲🇽',
    codigoMoneda: 'MXN',
    simbolo: r'MX$',
    nombreSingular: 'Peso mexicano',
    nombrePluralLetras: 'PESOS MEXICANOS',
    prefijoTel: '52',
    region: 'Norteamérica',
  ),
  MonedaPais(
    id: 'USD',
    codigoPais: 'US',
    nombrePais: 'Estados Unidos',
    bandera: '🇺🇸',
    codigoMoneda: 'USD',
    simbolo: r'US$',
    nombreSingular: 'Dólar',
    nombrePluralLetras: 'DÓLARES',
    prefijoTel: '1',
    region: 'Norteamérica',
  ),
  MonedaPais(
    id: 'CAD',
    codigoPais: 'CA',
    nombrePais: 'Canadá',
    bandera: '🇨🇦',
    codigoMoneda: 'CAD',
    simbolo: r'CA$',
    nombreSingular: 'Dólar canadiense',
    nombrePluralLetras: 'DÓLARES CANADIENSES',
    prefijoTel: '1',
    region: 'Norteamérica',
  ),

  // ── Caribe ─────────────────────────────────────────────────────────────────
  MonedaPais(
    id: 'DOP',
    codigoPais: 'DO',
    nombrePais: 'República Dominicana',
    bandera: '🇩🇴',
    codigoMoneda: 'DOP',
    simbolo: r'RD$',
    nombreSingular: 'Peso dominicano',
    nombrePluralLetras: 'PESOS DOMINICANOS',
    prefijoTel: '1',
    region: 'Caribe',
  ),
  MonedaPais(
    id: 'CUP',
    codigoPais: 'CU',
    nombrePais: 'Cuba',
    bandera: '🇨🇺',
    codigoMoneda: 'CUP',
    simbolo: r'$MN',
    nombreSingular: 'Peso cubano',
    nombrePluralLetras: 'PESOS CUBANOS',
    prefijoTel: '53',
    region: 'Caribe',
  ),
  MonedaPais(
    id: 'HTG',
    codigoPais: 'HT',
    nombrePais: 'Haití',
    bandera: '🇭🇹',
    codigoMoneda: 'HTG',
    simbolo: 'G',
    nombreSingular: 'Gourde',
    nombrePluralLetras: 'GOURDES',
    prefijoTel: '509',
    region: 'Caribe',
  ),
  MonedaPais(
    id: 'JMD',
    codigoPais: 'JM',
    nombrePais: 'Jamaica',
    bandera: '🇯🇲',
    codigoMoneda: 'JMD',
    simbolo: r'J$',
    nombreSingular: 'Dólar jamaiquino',
    nombrePluralLetras: 'DÓLARES JAMAIQUINOS',
    prefijoTel: '1',
    region: 'Caribe',
  ),
  MonedaPais(
    id: 'TTD',
    codigoPais: 'TT',
    nombrePais: 'Trinidad y Tobago',
    bandera: '🇹🇹',
    codigoMoneda: 'TTD',
    simbolo: r'TT$',
    nombreSingular: 'Dólar trinitense',
    nombrePluralLetras: 'DÓLARES TRINITENSES',
    prefijoTel: '1',
    region: 'Caribe',
  ),
  MonedaPais(
    id: 'BSD',
    codigoPais: 'BS',
    nombrePais: 'Bahamas',
    bandera: '🇧🇸',
    codigoMoneda: 'BSD',
    simbolo: r'B$',
    nombreSingular: 'Dólar bahameño',
    nombrePluralLetras: 'DÓLARES BAHAMEÑOS',
    prefijoTel: '1',
    region: 'Caribe',
  ),
  MonedaPais(
    id: 'BBD',
    codigoPais: 'BB',
    nombrePais: 'Barbados',
    bandera: '🇧🇧',
    codigoMoneda: 'BBD',
    simbolo: r'Bds$',
    nombreSingular: 'Dólar barbadense',
    nombrePluralLetras: 'DÓLARES BARBADENSES',
    prefijoTel: '1',
    region: 'Caribe',
  ),
  MonedaPais(
    id: 'USD_PR',
    codigoPais: 'PR',
    nombrePais: 'Puerto Rico',
    bandera: '🇵🇷',
    codigoMoneda: 'USD',
    simbolo: r'US$',
    nombreSingular: 'Dólar',
    nombrePluralLetras: 'DÓLARES',
    prefijoTel: '1',
    region: 'Caribe',
  ),

  // ── Sudamérica ─────────────────────────────────────────────────────────────
  MonedaPais(
    id: 'COP',
    codigoPais: 'CO',
    nombrePais: 'Colombia',
    bandera: '🇨🇴',
    codigoMoneda: 'COP',
    simbolo: r'COP$',
    nombreSingular: 'Peso colombiano',
    nombrePluralLetras: 'PESOS COLOMBIANOS',
    prefijoTel: '57',
    region: 'Sudamérica',
  ),
  MonedaPais(
    id: 'PEN',
    codigoPais: 'PE',
    nombrePais: 'Perú',
    bandera: '🇵🇪',
    codigoMoneda: 'PEN',
    simbolo: 'S/',
    nombreSingular: 'Sol',
    nombrePluralLetras: 'SOLES',
    prefijoTel: '51',
    region: 'Sudamérica',
  ),
  MonedaPais(
    id: 'USD_EC',
    codigoPais: 'EC',
    nombrePais: 'Ecuador',
    bandera: '🇪🇨',
    codigoMoneda: 'USD',
    simbolo: r'US$',
    nombreSingular: 'Dólar',
    nombrePluralLetras: 'DÓLARES',
    prefijoTel: '593',
    region: 'Sudamérica',
  ),
  MonedaPais(
    id: 'BOB',
    codigoPais: 'BO',
    nombrePais: 'Bolivia',
    bandera: '🇧🇴',
    codigoMoneda: 'BOB',
    simbolo: 'Bs',
    nombreSingular: 'Boliviano',
    nombrePluralLetras: 'BOLIVIANOS',
    prefijoTel: '591',
    region: 'Sudamérica',
  ),
  MonedaPais(
    id: 'PYG',
    codigoPais: 'PY',
    nombrePais: 'Paraguay',
    bandera: '🇵🇾',
    codigoMoneda: 'PYG',
    simbolo: '₲',
    nombreSingular: 'Guaraní',
    nombrePluralLetras: 'GUARANÍES',
    prefijoTel: '595',
    region: 'Sudamérica',
  ),
  MonedaPais(
    id: 'UYU',
    codigoPais: 'UY',
    nombrePais: 'Uruguay',
    bandera: '🇺🇾',
    codigoMoneda: 'UYU',
    simbolo: r'$U',
    nombreSingular: 'Peso uruguayo',
    nombrePluralLetras: 'PESOS URUGUAYOS',
    prefijoTel: '598',
    region: 'Sudamérica',
  ),
  MonedaPais(
    id: 'CLP',
    codigoPais: 'CL',
    nombrePais: 'Chile',
    bandera: '🇨🇱',
    codigoMoneda: 'CLP',
    simbolo: r'CLP$',
    nombreSingular: 'Peso chileno',
    nombrePluralLetras: 'PESOS CHILENOS',
    prefijoTel: '56',
    region: 'Sudamérica',
  ),
  MonedaPais(
    id: 'ARS',
    codigoPais: 'AR',
    nombrePais: 'Argentina',
    bandera: '🇦🇷',
    codigoMoneda: 'ARS',
    simbolo: r'ARS$',
    nombreSingular: 'Peso argentino',
    nombrePluralLetras: 'PESOS ARGENTINOS',
    prefijoTel: '54',
    region: 'Sudamérica',
  ),
  MonedaPais(
    id: 'BRL',
    codigoPais: 'BR',
    nombrePais: 'Brasil',
    bandera: '🇧🇷',
    codigoMoneda: 'BRL',
    simbolo: r'R$',
    nombreSingular: 'Real',
    nombrePluralLetras: 'REALES',
    prefijoTel: '55',
    region: 'Sudamérica',
  ),
  MonedaPais(
    id: 'VES',
    codigoPais: 'VE',
    nombrePais: 'Venezuela',
    bandera: '🇻🇪',
    codigoMoneda: 'VES',
    simbolo: 'Bs.',
    nombreSingular: 'Bolívar',
    nombrePluralLetras: 'BOLÍVARES',
    prefijoTel: '58',
    region: 'Sudamérica',
  ),
  MonedaPais(
    id: 'GYD',
    codigoPais: 'GY',
    nombrePais: 'Guyana',
    bandera: '🇬🇾',
    codigoMoneda: 'GYD',
    simbolo: r'GY$',
    nombreSingular: 'Dólar guyanés',
    nombrePluralLetras: 'DÓLARES GUYANESES',
    prefijoTel: '592',
    region: 'Sudamérica',
  ),
  MonedaPais(
    id: 'SRD',
    codigoPais: 'SR',
    nombrePais: 'Surinam',
    bandera: '🇸🇷',
    codigoMoneda: 'SRD',
    simbolo: r'SR$',
    nombreSingular: 'Dólar surinamés',
    nombrePluralLetras: 'DÓLARES SURINAMESES',
    prefijoTel: '597',
    region: 'Sudamérica',
  ),
];

/// Moneda por defecto del sistema (Nicaragua — Córdoba).
const MonedaPais kMonedaPaisDefault = ManualDefaultMoneda.nio;

abstract final class ManualDefaultMoneda {
  static const MonedaPais nio = MonedaPais(
    id: 'NIO',
    codigoPais: 'NI',
    nombrePais: 'Nicaragua',
    bandera: '🇳🇮',
    codigoMoneda: 'NIO',
    simbolo: r'C$',
    nombreSingular: 'Córdoba',
    nombrePluralLetras: 'CÓRDOBAS',
    prefijoTel: '505',
    region: 'Centroamérica',
  );
}

/// Resuelve un [MonedaPais] a partir del valor guardado en `moneda.principal`
/// (puede ser `id` como `'USD_SV'`, `codigoMoneda` como `'HNL'` o `codigoPais` como `'HN'`).
/// Si no coincide con ninguno, devuelve Nicaragua (`NIO`).
MonedaPais monedaPaisPorCodigo(String? codigo) {
  if (codigo == null || codigo.trim().isEmpty) return kMonedaPaisDefault;
  final norm = codigo.trim().toUpperCase();
  for (final m in kMonedasAmerica) {
    if (m.id.toUpperCase() == norm) return m;
  }
  for (final m in kMonedasAmerica) {
    if (m.codigoMoneda.toUpperCase() == norm) return m;
  }
  for (final m in kMonedasAmerica) {
    if (m.codigoPais.toUpperCase() == norm) return m;
  }
  return kMonedaPaisDefault;
}
