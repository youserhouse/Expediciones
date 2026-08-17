-- Desglose por factura de los palés ubicados cada día
-- Ejecutar en el editor SQL de Supabase
--
-- Estructura de `detalle`: array de objetos, uno por factura que aportó palés ese día
--   [{ "factura": "F-1234", "dest": "Cliente X", "palets": 3 }, ...]
-- La suma de `palets` del array puede ser menor que `palets_ubicados` (registros
-- anteriores a este cambio, o ediciones manuales del total): la UI muestra esa
-- diferencia como una línea "Sin asignar".

ALTER TABLE historial_ubicados_dia
  ADD COLUMN IF NOT EXISTS detalle jsonb NOT NULL DEFAULT '[]'::jsonb;
