-- ============================================================
--  TABLERO EXPEDICIONES — Setup Supabase
--  Pega este script en: Supabase > SQL Editor > New query > Run
-- ============================================================

-- 1. Crear la tabla
CREATE TABLE IF NOT EXISTS expediciones (
  id          uuid        DEFAULT gen_random_uuid() PRIMARY KEY,
  fecha       date,
  dest        text        NOT NULL,
  factura     text        NOT NULL,
  palets      integer     DEFAULT 0,
  p_ubicar    integer     DEFAULT 0,
  calle       text        DEFAULT '',
  obs         text        DEFAULT '',
  estado      text        DEFAULT 'pendiente'
                          CHECK (estado IN ('pendiente', 'ok', 'tarde')),
  created_at  timestamptz DEFAULT now()
);

-- 2. Activar Row Level Security (obligatorio para usar con anon key)
ALTER TABLE expediciones ENABLE ROW LEVEL SECURITY;

-- 3. Política de acceso público total (sin login)
CREATE POLICY "acceso_publico" ON expediciones
  FOR ALL
  TO anon
  USING (true)
  WITH CHECK (true);

-- 4. Índices para ordenar
CREATE INDEX IF NOT EXISTS idx_expediciones_created_at ON expediciones(created_at);
CREATE INDEX IF NOT EXISTS idx_expediciones_fecha      ON expediciones(fecha);

-- 5. Habilitar Realtime en la tabla (para sincronización entre pestañas)
ALTER PUBLICATION supabase_realtime ADD TABLE expediciones;
