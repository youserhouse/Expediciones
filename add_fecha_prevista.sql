-- Añadir columna "fecha prevista" a expediciones
-- Ejecutar en el editor SQL de Supabase

ALTER TABLE expediciones ADD COLUMN IF NOT EXISTS fecha_prevista date;
