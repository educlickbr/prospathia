
-- Migration: create_global_arquivos
-- Description: Centralized table for file metadata (R2/Bunny).

CREATE TABLE IF NOT EXISTS global_arquivos (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    empresa_id uuid NULL, -- Null implies global/system file, or we can enforce it.
    path text NOT NULL, -- Full path or relative path in bucket
    bucket text DEFAULT 'r2', -- 'r2' or 'bunny' or 'local'
    tamanho_bytes bigint,
    mimetype text,
    nome_original text,
    criado_por uuid references auth.users(id),
    criado_at timestamptz DEFAULT now(),
    updated_at timestamptz DEFAULT now()
);

-- RLS Policies (Optional but recommended)
ALTER TABLE global_arquivos ENABLE ROW LEVEL SECURITY;

-- Allow read for authenticated users (adjust as needed)
CREATE POLICY "Leitura permitida para logados" ON global_arquivos
    FOR SELECT USING (auth.role() = 'authenticated');

-- Allow insert for authenticated users
CREATE POLICY "Upload permitido para logados" ON global_arquivos
    FOR INSERT WITH CHECK (auth.role() = 'authenticated');
