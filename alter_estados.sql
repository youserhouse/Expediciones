-- Cambio 1: Nuevos valores de estado
-- Ejecutar en el editor SQL de Supabase

-- 1. Eliminar el CHECK constraint existente
ALTER TABLE expediciones DROP CONSTRAINT IF EXISTS expediciones_estado_check;

-- 2. Migrar valores existentes al nuevo esquema
UPDATE expediciones SET estado = 'en_transito'     WHERE estado = 'pendiente';
UPDATE expediciones SET estado = 'completado'     WHERE estado = 'ok';
UPDATE expediciones SET estado = 'en_preparacion' WHERE estado = 'tarde';

-- 3. Añadir nuevo CHECK constraint
ALTER TABLE expediciones ADD CONSTRAINT expediciones_estado_check
  CHECK (estado IN ('en_transito', 'en_preparacion', 'completado'));

-- 4. Actualizar valor por defecto
ALTER TABLE expediciones ALTER COLUMN estado SET DEFAULT 'en_transito';
