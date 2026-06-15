-- Cambio 2: Tabla para historial de palés ubicados por día
-- Ejecutar en el editor SQL de Supabase

CREATE TABLE historial_ubicados_dia (
  id              uuid DEFAULT gen_random_uuid() PRIMARY KEY,
  fecha           date UNIQUE NOT NULL,
  palets_ubicados integer DEFAULT 0 NOT NULL,
  created_at      timestamptz DEFAULT now() NOT NULL
);

ALTER TABLE historial_ubicados_dia ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Authenticated users can manage ubicados historial"
  ON historial_ubicados_dia
  FOR ALL
  TO authenticated
  USING (true)
  WITH CHECK (true);
