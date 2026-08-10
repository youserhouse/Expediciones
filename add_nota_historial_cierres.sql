-- Añadir campo de nota/comentario al historial de facturas anteriores (cierres)
-- Ejecutar en el editor SQL de Supabase

ALTER TABLE historial_cierres ADD COLUMN IF NOT EXISTS nota text;
