-- Cambio 2: estado "recepcion" + columna "ubicados"
-- Ejecutar en el editor SQL de Supabase (después de alter_estados.sql)
--
-- Flujo nuevo:  en_transito → recepcion → en_preparacion (Reponer) → completado (Completo)
-- Regla:        ubicados + p_ubicar = palets   (palets = total original de la factura)

-- 1. Añadir 'recepcion' a los estados permitidos
ALTER TABLE expediciones DROP CONSTRAINT IF EXISTS expediciones_estado_check;
ALTER TABLE expediciones ADD CONSTRAINT expediciones_estado_check
  CHECK (estado IN ('en_transito', 'recepcion', 'en_preparacion', 'completado'));

-- 2. Nueva columna: palets ya ubicados de esa factura
ALTER TABLE expediciones ADD COLUMN IF NOT EXISTS ubicados integer NOT NULL DEFAULT 0;

-- 3. Backfill de las filas existentes: lo ubicado es lo que ya no está pendiente
UPDATE expediciones
   SET ubicados = GREATEST(0, LEAST(COALESCE(palets, 0),
                                    COALESCE(palets, 0) - COALESCE(p_ubicar, 0)));

-- 4. Reajustar p_ubicar para que la suma cuadre siempre con palets
UPDATE expediciones
   SET p_ubicar = COALESCE(palets, 0) - ubicados;

-- 5. Garantizar la coherencia a nivel de base de datos.
--    Si prefieres validar solo desde la app, omite este paso.
ALTER TABLE expediciones DROP CONSTRAINT IF EXISTS expediciones_coherencia_check;
ALTER TABLE expediciones ADD CONSTRAINT expediciones_coherencia_check
  CHECK (COALESCE(ubicados, 0) + COALESCE(p_ubicar, 0) = COALESCE(palets, 0));
