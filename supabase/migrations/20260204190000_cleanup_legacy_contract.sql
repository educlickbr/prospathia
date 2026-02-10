-- Migration to Cleanup Legacy 'id_cliente' from 'cliente_contrato'

-- 1. Drop the legacy column
-- We use CASCADE to automatically remove dependent Constraints (fk_id_cliente) and RLS Policies.
ALTER TABLE public.cliente_contrato 
DROP COLUMN IF EXISTS id_cliente CASCADE;

-- 2. Recreate RLS Policy for 'cliente_contrato'
-- Since the old policy was likely dropped by CASCADE, we need a new one based on the new 'user_id' column.

-- Policy: Authenticated users can see their own contracts
CREATE POLICY "Users can view own contracts" 
ON public.cliente_contrato 
FOR SELECT 
TO authenticated 
USING (
    user_id IN (
        SELECT id 
        FROM public.user_expandido 
        WHERE user_id = auth.uid()
    )
);

-- Policy: Admin can do everything (if not already covered by a broad admin policy, checking 'Admin pode tudo...' pattern)
-- Assuming we stick to standard "Admin Access"
CREATE POLICY "Admins have full control on contracts" 
ON public.cliente_contrato 
FOR ALL 
TO authenticated 
USING ((auth.jwt() ->> 'user_role'::text) = 'admin'::text)
WITH CHECK ((auth.jwt() ->> 'user_role'::text) = 'admin'::text);
