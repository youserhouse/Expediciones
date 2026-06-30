-- Cambio 3: Añadir campo de nota/comentario al historial de ubicados por día
-- Ejecutar en el editor SQL de Supabase

ALTER TABLE historial_ubicados_dia ADD COLUMN IF NOT EXISTS nota text;
