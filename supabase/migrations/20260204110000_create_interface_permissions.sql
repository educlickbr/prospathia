-- Create Enum for Resource Type
CREATE TYPE public.tipo_recurso AS ENUM ('pagina', 'botao', 'ilha', 'elemento');

-- Create Interface Permissions Table
CREATE TABLE public.app_interface_permissoes (
    id uuid NOT NULL DEFAULT gen_random_uuid(),
    chave text NOT NULL,
    tipo public.tipo_recurso NOT NULL,
    descricao text NULL,
    papeis_permitidos jsonb NOT NULL DEFAULT '[]'::jsonb,
    produtos_permitidos jsonb NOT NULL DEFAULT '[]'::jsonb, -- New column as requested
    pai_chave text NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    ativo boolean DEFAULT true,
    
    CONSTRAINT app_interface_permissoes_pkey PRIMARY KEY (id),
    CONSTRAINT app_interface_permissoes_chave_key UNIQUE (chave)
) TABLESPACE pg_default;

-- Create Index for faster lookups
CREATE INDEX ix_app_interface_permissoes_chave ON public.app_interface_permissoes USING btree (chave);
CREATE INDEX ix_app_interface_permissoes_pai ON public.app_interface_permissoes USING btree (pai_chave);

-- Trigger for Updated At
CREATE TRIGGER trg_set_updated_at 
BEFORE UPDATE ON public.app_interface_permissoes 
FOR EACH ROW EXECUTE FUNCTION public.trg_set_updated_at();

-- RLS Policies
ALTER TABLE public.app_interface_permissoes ENABLE ROW LEVEL SECURITY;

-- Allow read access to authenticated users (so the frontend can check permissions)
CREATE POLICY "Leitura permitida para autenticados" 
ON public.app_interface_permissoes 
FOR SELECT 
TO authenticated 
USING (true);

-- Allow full access to admins only
CREATE POLICY "Admin total access" 
ON public.app_interface_permissoes 
FOR ALL 
TO authenticated 
USING ((auth.jwt() ->> 'user_role'::text) = 'admin'::text)
WITH CHECK ((auth.jwt() ->> 'user_role'::text) = 'admin'::text);
