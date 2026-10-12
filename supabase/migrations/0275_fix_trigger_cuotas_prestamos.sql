-- 0275: Corrección del trigger de cuotas para Préstamos / Microfinanzas
-- Evita el error 23502 (not_null_violation en cuotas.monto) cuando se crea un contrato sin plan_id.

-- 1. Asegurar que plan_id sea opcional en contratos
ALTER TABLE public.contratos ALTER COLUMN plan_id DROP NOT NULL;

-- 2. Actualizar la función exacta a la que apunta el trigger (contratos_generar_cuotas_iniciales_trg)
CREATE OR REPLACE FUNCTION public.contratos_generar_cuotas_iniciales_trg()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
BEGIN
  -- Si el contrato no tiene plan_id (es préstamo / crédito), las cuotas las genera el cliente
  IF NEW.plan_id IS NULL THEN
    RETURN NEW;
  END IF;

  -- Si ya existen cuotas creadas para este contrato, no duplicar
  IF EXISTS (SELECT 1 FROM public.cuotas WHERE contrato_id = NEW.id) THEN
    RETURN NEW;
  END IF;

  -- Para contratos legacy con plan de internet
  PERFORM public.generar_cuotas_contrato(NEW.id);
  RETURN NEW;
END;
$$;

-- 3. Asegurar que el trigger esté vinculado a esta función
DROP TRIGGER IF EXISTS trg_contratos_generar_cuotas_iniciales ON public.contratos;
CREATE TRIGGER trg_contratos_generar_cuotas_iniciales
  AFTER INSERT ON public.contratos
  FOR EACH ROW EXECUTE FUNCTION public.contratos_generar_cuotas_iniciales_trg();

-- 4. Blindar generar_cuotas_contrato para que nunca inserte cuotas con monto NULL si no hay plan
CREATE OR REPLACE FUNCTION public.generar_cuotas_contrato(
  p_contrato_id uuid,
  p_meses int default null
)
RETURNS int
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
DECLARE
  v_contrato      public.contratos%rowtype;
  v_cobrador_id   uuid;
  v_precio        numeric(10,2);
  v_max_meses     int;
  v_creadas       int := 0;
  v_periodo       date;
  v_vencimiento   date;
  v_inserto       boolean;
BEGIN
  SELECT * INTO v_contrato FROM public.contratos WHERE id = p_contrato_id;
  IF NOT FOUND OR v_contrato.plan_id IS NULL THEN
    RETURN 0;
  END IF;

  SELECT cobrador_id INTO v_cobrador_id FROM public.clientes WHERE id = v_contrato.cliente_id;
  SELECT precio_mensual INTO v_precio FROM public.planes WHERE id = v_contrato.plan_id;

  IF v_precio IS NULL THEN
    RETURN 0;
  END IF;

  IF p_meses IS NOT NULL THEN
    v_max_meses := p_meses;
  ELSIF v_contrato.fecha_fin IS NULL THEN
    v_max_meses := 3;
  ELSE
    v_max_meses := ((EXTRACT(year FROM v_contrato.fecha_fin) - EXTRACT(year FROM v_contrato.fecha_inicio)) * 12
                  + (EXTRACT(month FROM v_contrato.fecha_fin) - EXTRACT(month FROM v_contrato.fecha_inicio)))::int + 1;
  END IF;

  FOR i IN 0 .. v_max_meses - 1 LOOP
    v_periodo := (date_trunc('month', v_contrato.fecha_inicio) + (i || ' months')::interval)::date;
    v_vencimiento := public.calcular_fecha_pago(v_periodo, v_contrato.dia_pago);

    EXIT WHEN v_contrato.fecha_fin IS NOT NULL AND v_periodo > v_contrato.fecha_fin;
    CONTINUE WHEN v_vencimiento < v_contrato.fecha_inicio;

    INSERT INTO public.cuotas (
      tenant_id, contrato_id, cliente_id, cobrador_id,
      periodo, fecha_vencimiento, monto, estado
    ) VALUES (
      v_contrato.tenant_id, v_contrato.id, v_contrato.cliente_id, v_cobrador_id,
      v_periodo, v_vencimiento, v_precio, 'pendiente'
    )
    ON CONFLICT (contrato_id, periodo) DO NOTHING;

    GET DIAGNOSTICS v_inserto = row_count;
    IF v_inserto THEN
      v_creadas := v_creadas + 1;
    END IF;
  END LOOP;

  RETURN v_creadas;
END;
$$;
