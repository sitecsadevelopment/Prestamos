import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:prestamo/data/providers/update_provider.dart';
import 'package:prestamo/data/services/update_service.dart';
import 'package:prestamo/features/shared/widgets/update_banner.dart';

void main() {
  testWidgets(
      'UpdateBanner muestra diálogo de resumen al tocar Actualizar y permite cancelar',
      (tester) async {
    const update = AppUpdate(
      version: '1.0.9',
      downloadUrl: 'https://example.com/app.msix',
      releaseNotes:
          'v1.0.9 - Nuevo rol Admin básico y resumen de actualización.',
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          updateAvailableProvider.overrideWith((ref) async => update),
        ],
        child: const MaterialApp(
          home: Scaffold(
            body: UpdateBanner(),
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Actualización disponible v1.0.9'), findsOneWidget);
    expect(find.text('Actualizar'), findsOneWidget);

    await tester.tap(find.text('Actualizar'));
    await tester.pumpAndSettle();

    expect(find.text('Nueva versión v1.0.9'), findsOneWidget);
    expect(find.text('¿Qué incluye esta actualización?'), findsOneWidget);
    expect(
      find.text('v1.0.9 - Nuevo rol Admin básico y resumen de actualización.'),
      findsOneWidget,
    );
    expect(find.text('Ahora no'), findsOneWidget);
    expect(find.text('Descargar e instalar'), findsOneWidget);

    await tester.tap(find.text('Ahora no'));
    await tester.pumpAndSettle();

    expect(find.text('Nueva versión v1.0.9'), findsNothing);
    expect(find.text('Actualización disponible v1.0.9'), findsOneWidget);
    expect(find.text('Descargando v1.0.9…'), findsNothing);
  });
}
