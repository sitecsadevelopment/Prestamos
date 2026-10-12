import 'formatters.dart';

/// Ventana de reporte del dashboard: **mes calendario completo** (del día 1
/// al último día del mes; el fin es EXCLUSIVO = día 1 del mes siguiente).
///
/// Todas las cuotas que vencen en un mes calendario se agrupan en ese mismo mes,
/// sin cortes desplazados del 15 al 14.
const kMesesCortosPeriodo = [
  'ene', 'feb', 'mar', 'abr', 'may', 'jun',
  'jul', 'ago', 'sep', 'oct', 'nov', 'dic',
];

String mesCortoPeriodo(int mes) => kMesesCortosPeriodo[(mes - 1) % 12];

/// Primer día (inclusivo) del período [mes]/[anio]: el día 1 del propio mes.
DateTime inicioPeriodo(int anio, int mes) => DateTime(anio, mes, 1);

/// Fin EXCLUSIVO del período [mes]/[anio]: el día 1 del mes siguiente.
DateTime finPeriodo(int anio, int mes) => DateTime(anio, mes + 1, 1);

/// Mes de período que contiene [dia]: el propio mes calendario de [dia].
DateTime periodoDe(DateTime dia) => DateTime(dia.year, dia.month, 1);

/// Etiqueta legible del rango, ej. "1 – 31 oct".
String periodoLabel(int anio, int mes) {
  final fin = DateTime(anio, mes + 1, 0);
  return '1 – ${fin.day} ${mesCortoPeriodo(mes)}';
}

/// Ventana del período en curso, anclada al día de Nicaragua (UTC-6).
({DateTime inicio, DateTime fin}) ventanaPeriodoActual() {
  final p = periodoDe(Fmt.hoyNicaragua());
  return (inicio: inicioPeriodo(p.year, p.month), fin: finPeriodo(p.year, p.month));
}

/// Etiqueta del período en curso, ej. "1 – 31 oct".
String periodoLabelActual() {
  final p = periodoDe(Fmt.hoyNicaragua());
  return periodoLabel(p.year, p.month);
}

/// `yyyy-MM-dd` para comparar contra `date(...)` en SQLite.
String isoDia(DateTime d) => d.toIso8601String().substring(0, 10);
