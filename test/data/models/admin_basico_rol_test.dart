import 'package:flutter_test/flutter_test.dart';
import 'package:prestamo/config/router.dart';
import 'package:prestamo/data/models/cobrador.dart';
import 'package:prestamo/data/utils/cobrador_helpers.dart';

void main() {
  group('Rol admin_basico (0276)', () {
    const adminBasico = Cobrador(
      id: 'cb-1',
      tenantId: 'ten-1',
      nombre: 'María Admin Básico',
      rol: 'admin_basico',
      prefijoRecibo: 'MAB',
      activo: true,
    );

    const adminFull = Cobrador(
      id: 'cb-2',
      tenantId: 'ten-1',
      nombre: 'Pedro Admin',
      rol: 'admin',
      prefijoRecibo: 'PAD',
      activo: true,
    );

    test('esAdmin, esAdminBasico y permisos derivados en Cobrador', () {
      expect(adminBasico.esAdmin, isTrue);
      expect(adminBasico.esAdminBasico, isTrue);
      expect(adminBasico.puedeGestionarUsuarios, isFalse);
      expect(adminBasico.tieneAccesoAdmin, isTrue);
      expect(adminBasico.tieneAccesoAdminShell, isTrue);

      expect(adminFull.esAdmin, isTrue);
      expect(adminFull.esAdminBasico, isFalse);
      expect(adminFull.puedeGestionarUsuarios, isTrue);
    });

    test('rolLabel devuelve Admin básico', () {
      expect(rolLabel('admin_basico'), 'Admin básico');
    });

    test('redirectInicialPorRol lleva admin_basico a /admin y permite sub-rutas', () {
      expect(
        redirectInicialPorRol(
          rol: 'admin_basico',
          loc: '/',
          impersonating: false,
        ),
        '/admin',
      );
      expect(
        redirectInicialPorRol(
          rol: 'admin_basico',
          loc: '/admin/clientes',
          impersonating: false,
        ),
        isNull,
      );
      expect(
        redirectInicialPorRol(
          rol: 'admin_basico',
          loc: '/admin/cobradores',
          impersonating: false,
        ),
        isNull,
      );
    });
  });
}
