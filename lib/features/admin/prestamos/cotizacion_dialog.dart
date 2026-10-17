// ignore_for_file: use_build_context_synchronously


import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:printing/printing.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher_string.dart';

import '../../../config/env.dart';
import '../../../data/providers/cobrador_provider.dart';
import '../../../data/providers/logo_empresa_provider.dart';
import '../../../data/repositories/settings_repo.dart';
import '../../../data/services/url_shortener_service.dart';
import '../../../data/utils/formatters.dart';
import '../../../powersync/db.dart' as ps;
import '../reportes/descarga_archivo.dart';
import 'calculadora_prestamos_screen.dart'
    show CuotaAmortizacion, FrecuenciaPago, MetodoCalculo;
import 'proforma_pdf.dart';

/// Abre el diálogo para ingresar los datos del cliente, generar la proforma
/// en PDF y enviarla por WhatsApp o descargarla.
Future<void> mostrarCotizacionDialog({
  required BuildContext context,
  required WidgetRef ref,
  required double monto,
  required double tasaInteres,
  required bool tasaEsMensual,
  required FrecuenciaPago frecuencia,
  required int plazoCuotas,
  required MetodoCalculo metodo,
  required double montoCuota,
  required double totalInteres,
  required double totalPagar,
  required String moneda,
  required DateTime fechaPrimerPago,
  required List<CuotaAmortizacion> cronograma,
}) {
  return showDialog<void>(
    context: context,
    barrierDismissible: true,
    builder: (dialogContext) => _CotizacionDialog(
      monto: monto,
      tasaInteres: tasaInteres,
      tasaEsMensual: tasaEsMensual,
      frecuencia: frecuencia,
      plazoCuotas: plazoCuotas,
      metodo: metodo,
      montoCuota: montoCuota,
      totalInteres: totalInteres,
      totalPagar: totalPagar,
      moneda: moneda,
      fechaPrimerPago: fechaPrimerPago,
      cronograma: cronograma,
    ),
  );
}

class _CotizacionDialog extends ConsumerStatefulWidget {
  const _CotizacionDialog({
    required this.monto,
    required this.tasaInteres,
    required this.tasaEsMensual,
    required this.frecuencia,
    required this.plazoCuotas,
    required this.metodo,
    required this.montoCuota,
    required this.totalInteres,
    required this.totalPagar,
    required this.moneda,
    required this.fechaPrimerPago,
    required this.cronograma,
  });

  final double monto;
  final double tasaInteres;
  final bool tasaEsMensual;
  final FrecuenciaPago frecuencia;
  final int plazoCuotas;
  final MetodoCalculo metodo;
  final double montoCuota;
  final double totalInteres;
  final double totalPagar;
  final String moneda;
  final DateTime fechaPrimerPago;
  final List<CuotaAmortizacion> cronograma;

  @override
  ConsumerState<_CotizacionDialog> createState() => _CotizacionDialogState();
}

class _CotizacionDialogState extends ConsumerState<_CotizacionDialog> {
  final _formKey = GlobalKey<FormState>();

  final _nombreCtrl = TextEditingController();
  final _telefonoCtrl = TextEditingController();
  final _cedulaCtrl = TextEditingController();
  final _notasCtrl = TextEditingController();

  bool _enviandoWhatsApp = false;
  bool _descargandoPdf = false;
  bool _compartiendoPdf = false;

  List<Map<String, dynamic>> _clientesSugeridos = const [];

  @override
  void initState() {
    super.initState();
    _cargarClientesLocales();
  }

  @override
  void dispose() {
    _nombreCtrl.dispose();
    _telefonoCtrl.dispose();
    _cedulaCtrl.dispose();
    _notasCtrl.dispose();
    super.dispose();
  }

  Future<void> _cargarClientesLocales() async {
    try {
      final rows = await ps.db.getAll(
        'SELECT id, nombre, telefono, cedula FROM clientes ORDER BY nombre ASC LIMIT 300',
      );
      if (mounted) {
        setState(() {
          _clientesSugeridos = rows;
        });
      }
    } catch (_) {}
  }

  void _seleccionarClienteSugerido(Map<String, dynamic> c) {
    setState(() {
      _nombreCtrl.text = c['nombre'] as String? ?? '';
      _telefonoCtrl.text = c['telefono'] as String? ?? '';
      _cedulaCtrl.text = c['cedula'] as String? ?? '';
    });
  }

  Future<Uint8List> _construirBytesPdf() async {
    final settings = ref.read(appSettingsProvider);
    Uint8List? logoBytes;
    try {
      logoBytes = await ref.read(logoEmpresaBytesProvider.future);
    } catch (_) {}

    final doc = await buildProformaPrestamoPdf(
      empresaNombre: settings.empresaNombre,
      empresaDireccion: settings.empresaDireccion,
      empresaTelefono: settings.empresaTelefono.isNotEmpty
          ? settings.empresaTelefono
          : settings.empresaWhatsapp,
      clienteNombre: _nombreCtrl.text.trim(),
      clienteTelefono: _telefonoCtrl.text.trim(),
      clienteCedula: _cedulaCtrl.text.trim().isNotEmpty
          ? _cedulaCtrl.text.trim()
          : null,
      notas: _notasCtrl.text.trim().isNotEmpty
          ? _notasCtrl.text.trim()
          : null,
      montoPrestado: widget.monto,
      moneda: widget.moneda,
      tasaInteres: widget.tasaInteres,
      tasaEsMensual: widget.tasaEsMensual,
      frecuencia: widget.frecuencia.etiqueta,
      plazoCuotas: widget.plazoCuotas,
      metodoCalculo: widget.metodo.titulo,
      montoCuota: widget.montoCuota,
      totalInteres: widget.totalInteres,
      totalPagar: widget.totalPagar,
      fechaEmision: DateTime.now(),
      fechaPrimerPago: widget.fechaPrimerPago,
      cronograma: widget.cronograma,
      logoBytes: logoBytes,
    );

    return doc.save();
  }

  String _armarMensajeWhatsApp({String linkPdf = ''}) {
    final settings = ref.read(appSettingsProvider);
    final empresa = settings.empresaNombre.isNotEmpty
        ? settings.empresaNombre
        : 'PRESTAMOS SITECSA';
    final cliente = _nombreCtrl.text.trim().isNotEmpty
        ? _nombreCtrl.text.trim()
        : 'Estimado/a Cliente';
    final fechaFmt = DateFormat('dd/MM/yyyy');

    final buffer = StringBuffer();
    buffer.writeln('📄 *COTIZACIÓN DE PRÉSTAMO*');
    buffer.writeln('🏢 *$empresa*');
    buffer.writeln('--------------------------------');
    buffer.writeln('👤 *Cliente:* $cliente');
    buffer.writeln('💰 *Monto Solicitado:* ${Fmt.monto(widget.monto, widget.moneda)}');
    buffer.writeln(
        '📊 *Tasa de Interés:* ${widget.tasaInteres}% ${widget.tasaEsMensual ? "por período" : "total"}');
    buffer.writeln(
        '⏱️ *Plazo:* ${widget.plazoCuotas} cuotas (${widget.frecuencia.etiqueta})');
    buffer.writeln('📐 *Modalidad:* ${widget.metodo.titulo}');
    buffer.writeln('--------------------------------');
    buffer.writeln('💵 *VALOR DE LA CUOTA:* ${Fmt.monto(widget.montoCuota, widget.moneda)}');
    buffer.writeln('📈 *Total Intereses:* ${Fmt.monto(widget.totalInteres, widget.moneda)}');
    buffer.writeln('💳 *TOTAL A PAGAR:* ${Fmt.monto(widget.totalPagar, widget.moneda)}');
    buffer.writeln('📅 *Primer Pago:* ${fechaFmt.format(widget.fechaPrimerPago)}');
    buffer.writeln('--------------------------------');

    if (linkPdf.isNotEmpty) {
      buffer.writeln('📥 *Descargar Proforma Completa en PDF:*');
      buffer.writeln(linkPdf);
      buffer.writeln('--------------------------------');
    }

    buffer.writeln('_Cotización informativa válida por 15 días hábiles._');
    return buffer.toString();
  }

  Future<void> _enviarPorWhatsApp() async {
    if (!_formKey.currentState!.validate()) return;

    final telTexto = _telefonoCtrl.text.trim();
    if (telTexto.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Por favor ingresa un número de teléfono / WhatsApp.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() => _enviandoWhatsApp = true);

    try {
      final pdfBytes = await _construirBytesPdf();
      final tenantId = ref.read(tenantIdProvider) ??
          'f7227a73-f6e8-4578-b5a6-f476f9ebeffe';

      var linkPdf = '';
      if (tenantId.isNotEmpty) {
        try {
          final timestamp = DateTime.now().millisecondsSinceEpoch;
          final storagePath = '$tenantId/proformas/proforma_$timestamp.pdf';
          await Supabase.instance.client.storage
              .from('recibos-pdf')
              .uploadBinary(
                storagePath,
                pdfBytes,
                fileOptions: const FileOptions(
                  contentType: 'application/pdf',
                  upsert: true,
                ),
              );
          final rawUrl =
              '${Env.supabaseUrl}/storage/v1/object/public/recibos-pdf/$storagePath';
          linkPdf = await UrlShortenerService.acortar(rawUrl);
        } catch (e) {
          debugPrint('Aviso: No se pudo subir PDF a Storage (se enviará resumen): $e');
        }
      }

      final texto = _armarMensajeWhatsApp(linkPdf: linkPdf);

      // Normalizar número telefónico
      final rawTel = telTexto.replaceAll(RegExp(r'[^0-9]'), '');
      var phone = rawTel;
      if (phone.length == 8) {
        phone = '505$phone';
      }

      final encoded = Uri.encodeComponent(texto);
      final uri = phone.isNotEmpty
          ? 'https://wa.me/$phone?text=$encoded'
          : 'https://wa.me/?text=$encoded';

      await launchUrlString(uri, mode: LaunchMode.externalApplication);

      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Abriendo WhatsApp con la cotización...'),
            backgroundColor: Color(0xFF0F766E),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al preparar cotización: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _enviandoWhatsApp = false);
    }
  }

  Future<void> _descargarPdf() async {
    setState(() => _descargandoPdf = true);
    try {
      final pdfBytes = await _construirBytesPdf();
      final nombreLimpio = _nombreCtrl.text.trim().replaceAll(' ', '_');
      final fileName =
          'proforma_${nombreLimpio.isNotEmpty ? nombreLimpio : "prestamo"}.pdf';

      await guardarPdfConAviso(
        context,
        fileName: fileName,
        bytes: pdfBytes,
        mensaje: 'Proforma PDF guardada con éxito',
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al generar PDF: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _descargandoPdf = false);
    }
  }

  Future<void> _compartirPdfDirecto() async {
    setState(() => _compartiendoPdf = true);
    try {
      final pdfBytes = await _construirBytesPdf();
      final nombreLimpio = _nombreCtrl.text.trim().replaceAll(' ', '_');
      final fileName =
          'proforma_${nombreLimpio.isNotEmpty ? nombreLimpio : "prestamo"}.pdf';

      await Printing.sharePdf(bytes: pdfBytes, filename: fileName);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al compartir PDF: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _compartiendoPdf = false);
    }
  }

  void _copiarTexto() {
    final texto = _armarMensajeWhatsApp();
    Clipboard.setData(ClipboardData(text: texto));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Cotización copiada al portapapeles.'),
        backgroundColor: Color(0xFF0F766E),
        duration: Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final esMovil = MediaQuery.sizeOf(context).width < 600;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      insetPadding: EdgeInsets.symmetric(
        horizontal: esMovil ? 16 : 40,
        vertical: 24,
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 580),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Header del Dialog
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: const Color(0xFF0F766E).withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.description_outlined,
                        color: Color(0xFF0F766E),
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Proforma de Crédito',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            'Generá el PDF oficial y envialo por WhatsApp',
                            style: TextStyle(
                              fontSize: 12,
                              color: scheme.outline,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                // Resumen compacto del crédito
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'MONTO DEL CRÉDITO',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF64748B),
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              Fmt.monto(widget.monto, widget.moneda),
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF0F766E),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        height: 32,
                        width: 1,
                        color: const Color(0xFFCBD5E1),
                        margin: const EdgeInsets.symmetric(horizontal: 10),
                      ),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'CUOTA (${widget.frecuencia.etiqueta.toUpperCase()})',
                              style: const TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF64748B),
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              Fmt.monto(widget.montoCuota, widget.moneda),
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF1E293B),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        height: 32,
                        width: 1,
                        color: const Color(0xFFCBD5E1),
                        margin: const EdgeInsets.symmetric(horizontal: 10),
                      ),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'TOTAL A PAGAR',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF64748B),
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              Fmt.monto(widget.totalPagar, widget.moneda),
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF1E293B),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 18),

                // Selector rápido de cliente si hay en la base local
                if (_clientesSugeridos.isNotEmpty) ...[
                  Row(
                    children: [
                      const Icon(Icons.person_search, size: 16, color: Color(0xFF0F766E)),
                      const SizedBox(width: 6),
                      Text(
                        'Autocompletar con cliente existente (opcional):',
                        style: TextStyle(fontSize: 11.5, color: scheme.outline),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Autocomplete<Map<String, dynamic>>(
                    displayStringForOption: (c) =>
                        '${c['nombre'] ?? ''} • ${c['telefono'] ?? ''}',
                    optionsBuilder: (textEditingValue) {
                      final q = textEditingValue.text.trim().toLowerCase();
                      if (q.isEmpty) return const [];
                      return _clientesSugeridos.where((c) {
                        final nom = (c['nombre'] as String? ?? '').toLowerCase();
                        final tel = (c['telefono'] as String? ?? '').toLowerCase();
                        final ced = (c['cedula'] as String? ?? '').toLowerCase();
                        return nom.contains(q) || tel.contains(q) || ced.contains(q);
                      }).take(5);
                    },
                    onSelected: _seleccionarClienteSugerido,
                    fieldViewBuilder:
                        (context, textEditingController, focusNode, onFieldSubmitted) {
                      return TextField(
                        controller: textEditingController,
                        focusNode: focusNode,
                        decoration: InputDecoration(
                          hintText: 'Buscar por nombre, teléfono o cédula...',
                          prefixIcon: const Icon(Icons.search, size: 20),
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 10),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide:
                                const BorderSide(color: Color(0xFFCBD5E1)),
                          ),
                          isDense: true,
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 14),
                ],

                // Nombre completo
                TextFormField(
                  controller: _nombreCtrl,
                  textCapitalization: TextCapitalization.words,
                  decoration: InputDecoration(
                    labelText: 'Nombre del Prestatario / Solicitante *',
                    hintText: 'Ej. Juan Manuel Pérez Flores',
                    prefixIcon: const Icon(Icons.person_outline),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    isDense: true,
                  ),
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) {
                      return 'Por favor ingresá el nombre del solicitante';
                    }
                    return null;
                  },
                ),

                const SizedBox(height: 12),

                // Teléfono / WhatsApp y Cédula
                Row(
                  children: [
                    Expanded(
                      flex: 3,
                      child: TextFormField(
                        controller: _telefonoCtrl,
                        keyboardType: TextInputType.phone,
                        decoration: InputDecoration(
                          labelText: 'WhatsApp / Teléfono *',
                          hintText: 'Ej. 88889999 o +50588889999',
                          prefixIcon: const Icon(Icons.phone_android),
                          helperText: 'Autocompleta +505 si son 8 dígitos',
                          helperStyle: const TextStyle(fontSize: 10.5),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          isDense: true,
                        ),
                        validator: (v) {
                          if (v == null || v.trim().isEmpty) {
                            return 'Ingresá el teléfono';
                          }
                          return null;
                        },
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      flex: 2,
                      child: TextFormField(
                        controller: _cedulaCtrl,
                        decoration: InputDecoration(
                          labelText: 'Cédula / DNI',
                          hintText: '001-000000-0000A',
                          prefixIcon: const Icon(Icons.badge_outlined),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          isDense: true,
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                // Notas / Destino del crédito
                TextFormField(
                  controller: _notasCtrl,
                  decoration: InputDecoration(
                    labelText: 'Destino del Crédito / Observaciones (opcional)',
                    hintText: 'Ej. Inversión en mercadería para pulpería',
                    prefixIcon: const Icon(Icons.notes_outlined),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    isDense: true,
                  ),
                ),

                const SizedBox(height: 24),

                // Botón principal: Mandar por WhatsApp
                FilledButton.icon(
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFF25D366),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  onPressed: _enviandoWhatsApp ? null : _enviarPorWhatsApp,
                  icon: _enviandoWhatsApp
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.chat, size: 20),
                  label: Text(
                    _enviandoWhatsApp
                        ? 'Generando y preparando WhatsApp...'
                        : 'Mandar Proforma por WhatsApp',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                  ),
                ),

                const SizedBox(height: 10),

                // Botones secundarios: Descargar PDF, Compartir PDF y Copiar texto
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  alignment: WrapAlignment.spaceBetween,
                  children: [
                    OutlinedButton.icon(
                      onPressed: _descargandoPdf ? null : _descargarPdf,
                      icon: _descargandoPdf
                          ? const SizedBox(
                              width: 14,
                              height: 14,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.download, size: 16),
                      label: const Text('Descargar PDF'),
                      style: OutlinedButton.styleFrom(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                    OutlinedButton.icon(
                      onPressed: _compartiendoPdf ? null : _compartirPdfDirecto,
                      icon: _compartiendoPdf
                          ? const SizedBox(
                              width: 14,
                              height: 14,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.share, size: 16),
                      label: const Text('Compartir Archivo'),
                      style: OutlinedButton.styleFrom(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                    TextButton.icon(
                      onPressed: _copiarTexto,
                      icon: const Icon(Icons.copy, size: 16),
                      label: const Text('Copiar Texto'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
