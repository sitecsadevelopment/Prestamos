// ignore_for_file: prefer_const_constructors
import 'dart:typed_data';

import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../../../data/utils/formatters.dart';
import '../../shared/pdf/pdf_theme.dart';
import 'calculadora_prestamos_screen.dart' show CuotaAmortizacion;

// Colores corporativos sobrios y financieros
const _primaryColor = PdfColor.fromInt(0xFF0F766E); // Teal financiero
const _darkSlate = PdfColor.fromInt(0xFF1E293B);
const _mutedText = PdfColor.fromInt(0xFF64748B);
const _tableHeaderBg = PdfColor.fromInt(0xFF0F766E);
const _rowEven = PdfColor.fromInt(0xFFF8FAFC);
const _rowOdd = PdfColors.white;

/// Genera el documento PDF formal de Proforma / Cotización de Préstamo.
/// Diseñado para microfinanzas con tabla de amortización, términos y firmas.
Future<pw.Document> buildProformaPrestamoPdf({
  required String empresaNombre,
  required String empresaDireccion,
  required String empresaTelefono,
  required String clienteNombre,
  required String clienteTelefono,
  String? clienteCedula,
  String? notas,
  required double montoPrestado,
  required String moneda,
  required double tasaInteres,
  required bool tasaEsMensual,
  required String frecuencia,
  required int plazoCuotas,
  required String metodoCalculo,
  required double montoCuota,
  required double totalInteres,
  required double totalPagar,
  required DateTime fechaEmision,
  required DateTime fechaPrimerPago,
  required List<CuotaAmortizacion> cronograma,
  Uint8List? logoBytes,
}) async {
  final pdf = pw.Document();
  final theme = await pdfTheme();
  final logo = logoBytes == null ? null : pw.MemoryImage(logoBytes);

  final fechaFmt = DateFormat('dd/MM/yyyy', 'es_NI');
  final codigoCotizacion =
      'COT-${fechaEmision.millisecondsSinceEpoch.toRadixString(36).toUpperCase()}';

  String fmtDinero(num valor) => Fmt.monto(valor, moneda);

  pdf.addPage(
    pw.MultiPage(
      theme: theme,
      pageFormat: PdfPageFormat.letter,
      margin: const pw.EdgeInsets.symmetric(horizontal: 36, vertical: 32),
      header: (context) {
        return pw.Container(
          margin: const pw.EdgeInsets.only(bottom: 16),
          child: pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              // Logo e info empresa
              pw.Expanded(
                child: pw.Row(
                  crossAxisAlignment: pw.CrossAxisAlignment.center,
                  children: [
                    if (logo != null)
                      pw.Container(
                        height: 48,
                        constraints: const pw.BoxConstraints(maxWidth: 110),
                        margin: const pw.EdgeInsets.only(right: 12),
                        child: pw.Image(logo, fit: pw.BoxFit.contain),
                      ),
                    pw.Expanded(
                      child: pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Text(
                            empresaNombre.isNotEmpty
                                ? empresaNombre
                                : 'PRESTAMOS SITECSA',
                            style: pw.TextStyle(
                              fontSize: 16,
                              fontWeight: pw.FontWeight.bold,
                              color: _darkSlate,
                            ),
                          ),
                          if (empresaDireccion.isNotEmpty) ...[
                            pw.SizedBox(height: 2),
                            pw.Text(
                              empresaDireccion,
                              style: pw.TextStyle(
                                fontSize: 8.5,
                                color: _mutedText,
                              ),
                            ),
                          ],
                          if (empresaTelefono.isNotEmpty) ...[
                            pw.SizedBox(height: 1),
                            pw.Text(
                              'Atención: $empresaTelefono',
                              style: pw.TextStyle(
                                fontSize: 8.5,
                                color: _mutedText,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              // Título del documento y folio
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.end,
                children: [
                  pw.Container(
                    padding: const pw.EdgeInsets.symmetric(
                        horizontal: 10, vertical: 4),
                    decoration: pw.BoxDecoration(
                      color: _primaryColor,
                      borderRadius: pw.BorderRadius.circular(6),
                    ),
                    child: pw.Text(
                      'PROFORMA DE CRÉDITO',
                      style: pw.TextStyle(
                        color: PdfColors.white,
                        fontWeight: pw.FontWeight.bold,
                        fontSize: 11,
                      ),
                    ),
                  ),
                  pw.SizedBox(height: 4),
                  pw.Text(
                    'No. $codigoCotizacion',
                    style: pw.TextStyle(
                      fontWeight: pw.FontWeight.bold,
                      fontSize: 9.5,
                      color: _darkSlate,
                    ),
                  ),
                  pw.Text(
                    'Fecha: ${fechaFmt.format(fechaEmision)}',
                    style: pw.TextStyle(fontSize: 8.5, color: _mutedText),
                  ),
                  pw.Text(
                    'Vigencia: 15 días hábiles',
                    style: pw.TextStyle(
                      fontSize: 8,
                      color: _mutedText,
                      fontStyle: pw.FontStyle.italic,
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
      footer: (context) {
        return pw.Container(
          margin: const pw.EdgeInsets.only(top: 14),
          padding: const pw.EdgeInsets.only(top: 6),
          decoration: const pw.BoxDecoration(
            border: pw.Border(
              top: pw.BorderSide(color: PdfColors.grey300, width: 0.5),
            ),
          ),
          child: pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text(
                'Cotización informativa • Sujeta a verificación de requisitos crediticios.',
                style: pw.TextStyle(fontSize: 7.5, color: _mutedText),
              ),
              pw.Text(
                'Página ${context.pageNumber} de ${context.pagesCount}',
                style: pw.TextStyle(fontSize: 7.5, color: _mutedText),
              ),
            ],
          ),
        );
      },
      build: (context) => [
        // 1. Tarjeta de Datos del Solicitante
        pw.Container(
          padding: const pw.EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: pw.BoxDecoration(
            color: const PdfColor.fromInt(0xFFF1F5F9),
            borderRadius: pw.BorderRadius.circular(8),
            border: pw.Border.all(
                color: const PdfColor.fromInt(0xFFCBD5E1), width: 0.8),
          ),
          child: pw.Row(
            children: [
              pw.Expanded(
                flex: 3,
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      'DATOS DEL PROSPECTO / PRESTATARIO',
                      style: pw.TextStyle(
                        fontSize: 8,
                        fontWeight: pw.FontWeight.bold,
                        color: _primaryColor,
                      ),
                    ),
                    pw.SizedBox(height: 2),
                    pw.Text(
                      clienteNombre.isNotEmpty
                          ? clienteNombre
                          : 'Cliente Particular',
                      style: pw.TextStyle(
                        fontSize: 11,
                        fontWeight: pw.FontWeight.bold,
                        color: _darkSlate,
                      ),
                    ),
                  ],
                ),
              ),
              pw.Expanded(
                flex: 2,
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      'WHATSAPP / TELÉFONO',
                      style: pw.TextStyle(fontSize: 7.5, color: _mutedText),
                    ),
                    pw.Text(
                      clienteTelefono.isNotEmpty
                          ? clienteTelefono
                          : 'No especificado',
                      style: pw.TextStyle(
                        fontSize: 9.5,
                        fontWeight: pw.FontWeight.bold,
                        color: _darkSlate,
                      ),
                    ),
                  ],
                ),
              ),
              if (clienteCedula != null && clienteCedula.trim().isNotEmpty)
                pw.Expanded(
                  flex: 2,
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        'CÉDULA / DNI',
                        style:
                            pw.TextStyle(fontSize: 7.5, color: _mutedText),
                      ),
                      pw.Text(
                        clienteCedula,
                        style: pw.TextStyle(
                          fontSize: 9.5,
                          fontWeight: pw.FontWeight.bold,
                          color: _darkSlate,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),

        pw.SizedBox(height: 12),

        // 2. Resumen de Condiciones del Crédito (Grid visual)
        pw.Container(
          padding: const pw.EdgeInsets.all(12),
          decoration: pw.BoxDecoration(
            border: pw.Border.all(color: const PdfColor.fromInt(0xFFE2E8F0)),
            borderRadius: pw.BorderRadius.circular(8),
          ),
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                'CONDICIONES FINANCIERAS DE LA PROPUESTA',
                style: pw.TextStyle(
                  fontSize: 9,
                  fontWeight: pw.FontWeight.bold,
                  color: _primaryColor,
                ),
              ),
              pw.SizedBox(height: 8),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  _datoFinanciero('MONTO PRESTADO', fmtDinero(montoPrestado),
                      destacado: true),
                  _datoFinanciero(
                      'PLAZO TOTAL', '$plazoCuotas cuotas ($frecuencia)'),
                  _datoFinanciero('TASA DE INTERÉS',
                      '$tasaInteres% ${tasaEsMensual ? "por período" : "total"}'),
                  _datoFinanciero('MODALIDAD', metodoCalculo),
                ],
              ),
              pw.SizedBox(height: 8),
              pw.Divider(
                  color: const PdfColor.fromInt(0xFFE2E8F0), thickness: 0.7),
              pw.SizedBox(height: 6),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  _datoFinanciero(
                    'CUOTA PERIÓDICA',
                    fmtDinero(montoCuota),
                    destacado: true,
                    colorTexto: _primaryColor,
                  ),
                  _datoFinanciero('TOTAL INTERESES', fmtDinero(totalInteres)),
                  _datoFinanciero('TOTAL A PAGAR', fmtDinero(totalPagar),
                      destacado: true),
                  _datoFinanciero(
                      'PRIMER PAGO', fechaFmt.format(fechaPrimerPago)),
                ],
              ),
            ],
          ),
        ),

        pw.SizedBox(height: 14),

        // 3. Título de Cronograma
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Text(
              'PROYECCIÓN DE PAGOS Y TABLA DE AMORTIZACIÓN',
              style: pw.TextStyle(
                fontSize: 9.5,
                fontWeight: pw.FontWeight.bold,
                color: _darkSlate,
              ),
            ),
            pw.Text(
              '${cronograma.length} cuotas proyectadas',
              style: pw.TextStyle(fontSize: 8.5, color: _mutedText),
            ),
          ],
        ),

        pw.SizedBox(height: 6),

        // 4. Tabla de Amortización
        pw.Table(
          border: pw.TableBorder.all(
            color: const PdfColor.fromInt(0xFFE2E8F0),
            width: 0.5,
          ),
          columnWidths: const {
            0: pw.FixedColumnWidth(26), // #
            1: pw.FixedColumnWidth(65), // Fecha
            2: pw.FlexColumnWidth(2), // Capital
            3: pw.FlexColumnWidth(2), // Interes
            4: pw.FlexColumnWidth(2.2), // Cuota
            5: pw.FlexColumnWidth(2.2), // Saldo
          },
          children: [
            // Cabecera de la tabla
            pw.TableRow(
              decoration: const pw.BoxDecoration(color: _tableHeaderBg),
              children: [
                _th('#', align: pw.TextAlign.center),
                _th('Fecha Venc.', align: pw.TextAlign.center),
                _th('Abono Capital', align: pw.TextAlign.right),
                _th('Interés Ord.', align: pw.TextAlign.right),
                _th('Cuota Total', align: pw.TextAlign.right),
                _th('Saldo Deudor', align: pw.TextAlign.right),
              ],
            ),
            // Filas
            ...cronograma.map((c) {
              final esPar = c.numero % 2 == 0;
              return pw.TableRow(
                decoration: pw.BoxDecoration(color: esPar ? _rowEven : _rowOdd),
                children: [
                  _td('${c.numero}', align: pw.TextAlign.center),
                  _td(fechaFmt.format(c.fecha), align: pw.TextAlign.center),
                  _td(fmtDinero(c.capital), align: pw.TextAlign.right),
                  _td(fmtDinero(c.interes), align: pw.TextAlign.right),
                  _td(fmtDinero(c.cuota),
                      align: pw.TextAlign.right,
                      bold: true,
                      color: _primaryColor),
                  _td(fmtDinero(c.saldoRestante), align: pw.TextAlign.right),
                ],
              );
            }),
            // Fila de Totales
            pw.TableRow(
              decoration: const pw.BoxDecoration(
                color: PdfColor.fromInt(0xFFE2E8F0),
              ),
              children: [
                _td('', align: pw.TextAlign.center),
                _td('TOTALES', align: pw.TextAlign.center, bold: true),
                _td(fmtDinero(montoPrestado),
                    align: pw.TextAlign.right, bold: true),
                _td(fmtDinero(totalInteres),
                    align: pw.TextAlign.right, bold: true),
                _td(fmtDinero(totalPagar),
                    align: pw.TextAlign.right,
                    bold: true,
                    color: _primaryColor),
                _td(fmtDinero(0), align: pw.TextAlign.right, bold: true),
              ],
            ),
          ],
        ),

        pw.SizedBox(height: 16),

        // 5. Notas / Destino del crédito si se proveyeron
        if (notas != null && notas.trim().isNotEmpty) ...[
          pw.Container(
            padding: const pw.EdgeInsets.all(8),
            decoration: pw.BoxDecoration(
              color: const PdfColor.fromInt(0xFFF8FAFC),
              borderRadius: pw.BorderRadius.circular(6),
              border: pw.Border.all(
                  color: const PdfColor.fromInt(0xFFE2E8F0), width: 0.5),
            ),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  'DESTINO / OBSERVACIONES:',
                  style: pw.TextStyle(
                      fontSize: 7.5,
                      fontWeight: pw.FontWeight.bold,
                      color: _mutedText),
                ),
                pw.SizedBox(height: 2),
                pw.Text(
                  notas,
                  style: pw.TextStyle(fontSize: 8.5, color: _darkSlate),
                ),
              ],
            ),
          ),
          pw.SizedBox(height: 16),
        ],

        // 6. Cláusula informativa y firmas
        pw.Container(
          padding: const pw.EdgeInsets.all(8),
          decoration: pw.BoxDecoration(
            color: const PdfColor.fromInt(0xFFF8FAFC),
            borderRadius: pw.BorderRadius.circular(6),
          ),
          child: pw.Text(
            'IMPORTANTE: Esta proforma contiene una proyección estimada bajo las condiciones '
            'del crédito simuladas al momento de su emisión. Los pagos se realizarán con estricto '
            'apego a las fechas estipuladas. Para formalizar el desembolso definitivo es indispensable '
            'presentar cédula de identidad vigente y cumplir con la documentación crediticia requerida.',
            style: pw.TextStyle(
              fontSize: 7.2,
              color: _mutedText,
              lineSpacing: 1.2,
            ),
          ),
        ),

        pw.SizedBox(height: 28),

        // Firmas
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
          children: [
            pw.Column(
              children: [
                pw.Container(
                  width: 170,
                  height: 1,
                  color: _darkSlate,
                ),
                pw.SizedBox(height: 4),
                pw.Text(
                  clienteNombre.isNotEmpty
                      ? clienteNombre
                      : 'Prestatario / Solicitante',
                  style: pw.TextStyle(
                    fontSize: 8.5,
                    fontWeight: pw.FontWeight.bold,
                    color: _darkSlate,
                  ),
                ),
                pw.Text(
                  'Firma del Solicitante',
                  style: pw.TextStyle(fontSize: 7.5, color: _mutedText),
                ),
              ],
            ),
            pw.Column(
              children: [
                pw.Container(
                  width: 170,
                  height: 1,
                  color: _darkSlate,
                ),
                pw.SizedBox(height: 4),
                pw.Text(
                  empresaNombre.isNotEmpty
                      ? empresaNombre
                      : 'Oficial de Crédito',
                  style: pw.TextStyle(
                    fontSize: 8.5,
                    fontWeight: pw.FontWeight.bold,
                    color: _darkSlate,
                  ),
                ),
                pw.Text(
                  'Asesor / Autorización',
                  style: pw.TextStyle(fontSize: 7.5, color: _mutedText),
                ),
              ],
            ),
          ],
        ),
      ],
    ),
  );

  return pdf;
}

pw.Widget _datoFinanciero(
  String etiqueta,
  String valor, {
  bool destacado = false,
  PdfColor? colorTexto,
}) {
  return pw.Column(
    crossAxisAlignment: pw.CrossAxisAlignment.start,
    children: [
      pw.Text(
        etiqueta,
        style: pw.TextStyle(
          fontSize: 7.5,
          color: PdfColor.fromInt(0xFF64748B),
        ),
      ),
      pw.SizedBox(height: 2),
      pw.Text(
        valor,
        style: pw.TextStyle(
          fontSize: destacado ? 11 : 9.5,
          fontWeight: destacado ? pw.FontWeight.bold : pw.FontWeight.normal,
          color: colorTexto ?? const PdfColor.fromInt(0xFF1E293B),
        ),
      ),
    ],
  );
}

pw.Widget _th(String text, {pw.TextAlign align = pw.TextAlign.left}) {
  return pw.Padding(
    padding: const pw.EdgeInsets.symmetric(horizontal: 5, vertical: 4),
    child: pw.Text(
      text,
      textAlign: align,
      style: pw.TextStyle(
        color: PdfColors.white,
        fontWeight: pw.FontWeight.bold,
        fontSize: 7.5,
      ),
    ),
  );
}

pw.Widget _td(
  String text, {
  pw.TextAlign align = pw.TextAlign.left,
  bool bold = false,
  PdfColor? color,
}) {
  return pw.Padding(
    padding: const pw.EdgeInsets.symmetric(horizontal: 5, vertical: 3.5),
    child: pw.Text(
      text,
      textAlign: align,
      style: pw.TextStyle(
        fontSize: 7.5,
        fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal,
        color: color ?? const PdfColor.fromInt(0xFF1E293B),
      ),
    ),
  );
}
