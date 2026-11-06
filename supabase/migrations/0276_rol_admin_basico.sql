-- =========================================================================
-- 0276 — Rol `admin_basico` ("Admin básico")
--
-- Alcance aprobado por Rubén:
--   · Hace todo lo que hace `admin` (clientes, contratos, calculadora,
--     cuotas, pagos, cobros a revisar, reportes/arqueo, ajustes/settings de
--     la empresa, aprobar solicitudes, cobrar con su propio prefijo de
--     recibo, usar su propio PIN de dashboard).
--   · Restricción en Cobradores/Usuarios: en `/admin/cobradores` solo puede
--     VER la lista de cobradores (modo solo lectura en esa pantalla). NO
--     puede crear usuarios nuevos ni editar, cambiar roles, activar/desactivar
--     ni cambiar/ver contraseñas de usuarios existentes.
-- =========================================================================

BEGIN;

-- -------------------------------------------------------------------------
-- 1. CHECK del rol en `public.cobradores`
-- -------------------------------------------------------------------------
ALTER TABLE public.cobradores DROP CONSTRAINT IF EXISTS cobradores_rol_check;
ALTER TABLE public.cobradores ADD CONSTRAINT cobradores_rol_check
  CHECK (rol IN ('super_admin','admin','admin_basico','admin_cobranza','cobrador',
                 'tecnico','admin_tickets','admin_usuarios','lectura',
                 'coordinador'));

-- -------------------------------------------------------------------------
-- 2. handle_new_user: sumar 'admin_basico' a la whitelist y a los roles con
--    prefijo_recibo (basado en 0207_rol_coordinador.sql).
-- -------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.handle_new_user()
 RETURNS trigger
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public', 'pg_temp'
AS $function$
DECLARE
  v_tenant_id      uuid;
  v_rol            text;
  v_nombre         text;
  v_telefono       text;
  v_prefijo        text;
  v_empresa_nombre text;
BEGIN
  v_tenant_id      := (new.raw_user_meta_data ->> 'tenant_id')::uuid;
  v_rol            := coalesce(new.raw_user_meta_data ->> 'rol', 'admin');
  v_nombre         := coalesce(
                        new.raw_user_meta_data ->> 'nombre',
                        split_part(new.email, '@', 1)
                      );
  v_telefono       := new.raw_user_meta_data ->> 'telefono';
  v_prefijo        := new.raw_user_meta_data ->> 'prefijo_recibo';
  v_empresa_nombre := new.raw_user_meta_data ->> 'empresa_nombre';

  IF v_rol NOT IN ('super_admin', 'admin', 'admin_basico', 'admin_cobranza',
                   'cobrador', 'tecnico', 'admin_tickets', 'admin_usuarios',
                   'lectura', 'coordinador') THEN
    v_rol := 'admin';
  END IF;

  IF v_rol = 'super_admin' THEN
    v_tenant_id := '00000000-0000-0000-0000-000000000000';
  ELSIF v_tenant_id IS NULL THEN
    INSERT INTO public.tenants (nombre)
      VALUES (coalesce(v_empresa_nombre, 'Mi ISP'))
      RETURNING id INTO v_tenant_id;
    v_rol := 'admin';
  END IF;

  INSERT INTO public.cobradores (
    id, tenant_id, nombre, telefono, rol, prefijo_recibo, activo
  ) VALUES (
    new.id, v_tenant_id, v_nombre, v_telefono, v_rol,
    CASE WHEN v_rol IN ('cobrador', 'admin', 'admin_basico', 'admin_cobranza')
         THEN v_prefijo ELSE NULL END,
    true
  )
  ON CONFLICT (id) DO UPDATE
    SET tenant_id      = excluded.tenant_id,
        nombre         = excluded.nombre,
        telefono       = excluded.telefono,
        rol            = excluded.rol,
        prefijo_recibo = excluded.prefijo_recibo;

  RETURN new;
END;
$function$;

-- -------------------------------------------------------------------------
-- 3. Helpers de rol para RLS (incluyen 'admin_basico' en las capacidades
--    operativas de admin).
-- -------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.is_admin()
 RETURNS boolean
 LANGUAGE sql
 STABLE SECURITY DEFINER
 SET search_path = ''
AS $function$
  SELECT public.current_user_rol() IN ('admin', 'admin_basico');
$function$;

CREATE OR REPLACE FUNCTION public.is_admin_or_cobranza()
 RETURNS boolean
 LANGUAGE sql
 STABLE SECURITY DEFINER
 SET search_path = ''
AS $function$
  SELECT public.current_user_rol() IN ('admin', 'admin_basico', 'admin_cobranza');
$function$;

CREATE OR REPLACE FUNCTION public.is_personal_cobranza()
 RETURNS boolean
 LANGUAGE sql
 STABLE SECURITY DEFINER
 SET search_path = ''
AS $function$
  SELECT public.current_user_rol() IN ('admin', 'admin_basico', 'admin_cobranza', 'cobrador');
$function$;

CREATE OR REPLACE FUNCTION public.is_admin_or_tickets()
 RETURNS boolean
 LANGUAGE sql
 STABLE SECURITY DEFINER
 SET search_path = ''
AS $function$
  SELECT public.current_user_rol() IN ('admin', 'admin_basico', 'admin_tickets');
$function$;

CREATE OR REPLACE FUNCTION public.is_ticket_staff()
 RETURNS boolean
 LANGUAGE sql
 STABLE SECURITY DEFINER
 SET search_path = ''
AS $function$
  SELECT public.current_user_rol() IN ('admin', 'admin_basico', 'admin_tickets', 'tecnico');
$function$;

-- -------------------------------------------------------------------------
-- 4. puede_cambiar_fecha_pago (basado en 0200_lectura_cambio_fecha.sql)
-- -------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.puede_cambiar_fecha_pago()
RETURNS boolean LANGUAGE sql STABLE SECURITY DEFINER
SET search_path TO 'public', 'pg_temp'
AS $function$
  select
    coalesce((
      select s.valor = 'true'
        from public.settings s
       where s.tenant_id = public.current_tenant_id()
         and s.clave = 'cobranza.cambio_fecha_habilitado'
    ), false)
    and coalesce((
      select (c.rol <> 'lectura' and (c.rol in ('admin', 'admin_basico') or c.puede_cambiar_fecha))
        from public.cobradores c
       where c.id = auth.uid()
    ), false);
$function$;

-- -------------------------------------------------------------------------
-- 5. Policy `settings_write_admin` en `public.settings` (basado en 0085):
--    `admin` y `admin_basico` pueden editar settings del tenant (excepto
--    las `super_admin`).
-- -------------------------------------------------------------------------
DROP POLICY IF EXISTS "settings_write_admin" ON public.settings;
CREATE POLICY "settings_write_admin" ON public.settings
  FOR ALL USING (
    tenant_id = public.current_tenant_id()
    AND public.current_user_rol() IN ('admin', 'admin_basico')
    AND editable_por <> 'super_admin'
  ) WITH CHECK (
    tenant_id = public.current_tenant_id()
    AND public.current_user_rol() IN ('admin', 'admin_basico')
    AND editable_por <> 'super_admin'
  );

-- -------------------------------------------------------------------------
-- 6. Policy `cobradores_write_admin` en `public.cobradores`:
--    · `admin` completo puede actualizar cualquier fila de su tenant.
--    · `admin_basico` SOLO puede actualizar su propia fila (ej. fallback
--      offline de su propio PIN), NUNCA filas de otros cobradores.
-- -------------------------------------------------------------------------
DROP POLICY IF EXISTS "cobradores_write_admin" ON public.cobradores;
CREATE POLICY "cobradores_write_admin" ON public.cobradores
  FOR ALL USING (
    tenant_id = public.current_tenant_id()
    AND (
      public.current_user_rol() = 'admin'
      OR (public.current_user_rol() = 'admin_basico' AND id = (SELECT auth.uid()))
    )
  ) WITH CHECK (
    tenant_id = public.current_tenant_id()
    AND (
      public.current_user_rol() = 'admin'
      OR (public.current_user_rol() = 'admin_basico' AND id = (SELECT auth.uid()))
    )
  );

-- -------------------------------------------------------------------------
-- 7. RPC `set_cobrador_rol` (basado en 0250_atribucion_rpc_super_admin.sql):
--    · Solo `super_admin` o `admin` (NUNCA `admin_basico`).
--    · Soporta `'admin_basico'` en la whitelist y conserva `prefijo_recibo`.
-- -------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.set_cobrador_rol(p_cobrador_id uuid, p_nuevo_rol text)
 RETURNS void
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public', 'pg_temp'
AS $function$
DECLARE
  v_es_super       boolean;
  v_mi_rol         text;
  v_mi_tenant      uuid;
  v_mi_nombre      text;
  v_target_rol     text;
  v_target_prefijo text;
  v_tenant         uuid;
  v_campos         jsonb;
BEGIN
  v_es_super := public.is_super_admin();
  SELECT rol, tenant_id, nombre
    INTO v_mi_rol, v_mi_tenant, v_mi_nombre
    FROM public.cobradores WHERE id = auth.uid();

  IF NOT (v_es_super OR v_mi_rol = 'admin') THEN
    RAISE EXCEPTION 'Solo super_admin o admin puede cambiar el rol' USING errcode = '42501';
  END IF;
  IF p_cobrador_id = auth.uid() THEN
    RAISE EXCEPTION 'No podés modificar tu propio rol';
  END IF;
  IF p_nuevo_rol NOT IN ('admin','admin_basico','admin_cobranza','cobrador','tecnico','admin_tickets','admin_usuarios','lectura','coordinador') THEN
    RAISE EXCEPTION 'Rol inválido. Permitidos: admin, admin_basico, admin_cobranza, cobrador, tecnico, admin_tickets, admin_usuarios, lectura, coordinador';
  END IF;
  SELECT rol, prefijo_recibo, tenant_id
    INTO v_target_rol, v_target_prefijo, v_tenant
    FROM public.cobradores WHERE id = p_cobrador_id FOR UPDATE;
  IF v_target_rol IS NULL THEN
    RAISE EXCEPTION 'Cobrador no existe' USING errcode = 'P0002';
  END IF;
  IF v_target_rol = 'super_admin' THEN
    RAISE EXCEPTION 'No se puede modificar el rol de otro super_admin';
  END IF;
  IF NOT v_es_super AND v_tenant <> v_mi_tenant THEN
    RAISE EXCEPTION 'Ese usuario es de otra empresa' USING errcode = '42501';
  END IF;
  IF v_target_rol = p_nuevo_rol THEN
    RETURN;
  END IF;
  UPDATE public.cobradores
     SET rol = p_nuevo_rol,
         prefijo_recibo = CASE WHEN p_nuevo_rol IN ('cobrador','admin','admin_basico','admin_cobranza')
                               THEN prefijo_recibo ELSE NULL END
   WHERE id = p_cobrador_id;

  v_campos := jsonb_build_array(
    jsonb_build_object('campo','rol','antes',v_target_rol,'despues',p_nuevo_rol));
  IF v_target_prefijo IS NOT NULL
     AND p_nuevo_rol NOT IN ('cobrador','admin','admin_basico','admin_cobranza') THEN
    v_campos := v_campos || jsonb_build_array(
      jsonb_build_object('campo','prefijo_recibo','antes',v_target_prefijo,'despues',NULL));
  END IF;

  INSERT INTO public.op_log (id, tenant_id, op_id, tipo_op, entidad, entidad_id,
                             actor_id, actor_label, accion, diff, ocurrido_en)
  VALUES (gen_random_uuid(), v_tenant, gen_random_uuid(), 'edicion_entidad',
          'cobradores', p_cobrador_id,
          CASE WHEN v_es_super THEN NULL ELSE auth.uid() END,
          CASE WHEN v_es_super THEN 'System Admin'
               ELSE coalesce(v_mi_nombre, 'Administrador') END,
          'update',
          jsonb_build_object('campos', v_campos)::text, now());
END;
$function$;

-- -------------------------------------------------------------------------
-- 8. RPC `list_cobrador_emails` (basado en 0091_list_cobrador_emails.sql):
--    incluir `'admin_basico'` para que la pantalla de cobradores en modo
--    lectura muestre los emails de los miembros sin error.
-- -------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.list_cobrador_emails()
RETURNS TABLE (cobrador_id uuid, email text)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $$
DECLARE
  v_rol    text;
  v_tenant uuid;
BEGIN
  SELECT c.rol INTO v_rol
  FROM public.cobradores c
  WHERE c.id = auth.uid();

  IF v_rol IS NULL OR v_rol NOT IN ('admin', 'admin_basico', 'admin_cobranza', 'super_admin') THEN
    RETURN;
  END IF;

  v_tenant := public.current_tenant_id();
  IF v_tenant IS NULL THEN
    RETURN;
  END IF;

  RETURN QUERY
  SELECT c.id, u.email::text
  FROM public.cobradores c
  JOIN auth.users u ON u.id = c.id
  WHERE c.tenant_id = v_tenant;
END;
$$;

REVOKE ALL ON FUNCTION public.list_cobrador_emails() FROM public;
GRANT EXECUTE ON FUNCTION public.list_cobrador_emails() TO authenticated;

-- -------------------------------------------------------------------------
-- 9. RPC `forzar_reset_dashboard_pin` (basado en 0250):
--    · Solo `admin` o `super_admin` pueden forzar el PIN de otro usuario;
--      `admin_basico` solo puede sobre sí mismo (`p_cobrador_id = auth.uid()`).
-- -------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.forzar_reset_dashboard_pin(p_cobrador_id uuid)
 RETURNS void
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public', 'pg_temp'
AS $function$
DECLARE
  v_mi_rol    text;
  v_mi_tenant uuid;
  v_mi_nombre text;
  v_su_rol    text;
  v_su_tenant uuid;
BEGIN
  SELECT rol, tenant_id, nombre INTO v_mi_rol, v_mi_tenant, v_mi_nombre
    FROM public.cobradores WHERE id = auth.uid();
  IF v_mi_rol IS NULL THEN
    RAISE EXCEPTION 'No autorizado' USING errcode = '42501';
  END IF;
  IF v_mi_rol NOT IN ('admin', 'super_admin')
     AND NOT (v_mi_rol = 'admin_basico' AND p_cobrador_id = auth.uid()) THEN
    RAISE EXCEPTION 'Solo un administrador puede forzar el cambio de PIN'
      USING errcode = '42501';
  END IF;

  SELECT rol, tenant_id INTO v_su_rol, v_su_tenant
    FROM public.cobradores WHERE id = p_cobrador_id;
  IF v_su_rol IS NULL THEN
    RAISE EXCEPTION 'Ese usuario no existe' USING errcode = 'P0002';
  END IF;
  IF v_su_rol = 'super_admin' THEN
    RAISE EXCEPTION 'No se puede forzar el PIN de un super_admin';
  END IF;
  IF v_mi_rol <> 'super_admin' AND v_su_tenant <> v_mi_tenant THEN
    RAISE EXCEPTION 'Ese usuario es de otra empresa' USING errcode = '42501';
  END IF;

  UPDATE public.cobradores  SET dashboard_pin = '' WHERE id = p_cobrador_id;
  UPDATE public.dashboard_pins SET pin = '', updated_at = now()
   WHERE id = p_cobrador_id;

  INSERT INTO public.op_log (id, tenant_id, op_id, tipo_op, entidad, entidad_id,
                             actor_id, actor_label, accion, diff, ocurrido_en)
  VALUES (gen_random_uuid(), v_su_tenant, gen_random_uuid(), 'editar',
          'cobradores', p_cobrador_id,
          CASE WHEN v_mi_rol = 'super_admin' THEN NULL ELSE auth.uid() END,
          CASE WHEN v_mi_rol = 'super_admin' THEN 'System Admin'
               ELSE coalesce(v_mi_nombre, 'Administrador') END,
          'update',
          jsonb_build_object('campos', '[]'::jsonb, 'resumen',
            jsonb_build_object('motivo',
              'PIN del dashboard reseteado por el administrador. La persona '
              'define uno nuevo la próxima vez que abre el dashboard.'))::text,
          now());
END;
$function$;

COMMIT;
