-- ============================================================
--  ACTUALIZAR SEGURIDAD — Solo usuarios autenticados
--  Pega en: Supabase > SQL Editor > New query > Run
-- ============================================================

-- 1. Eliminar la política pública anterior
DROP POLICY IF EXISTS "acceso_publico" ON expediciones;

-- 2. Nueva política: solo usuarios con sesión iniciada
CREATE POLICY "solo_autenticados" ON expediciones
  FOR ALL
  TO authenticated
  USING (true)
  WITH CHECK (true);
