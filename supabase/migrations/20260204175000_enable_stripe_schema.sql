-- Migration to adapt schema for Stripe Integration AND Consolidate User Tables

-- 1. Updates to 'planos' table
ALTER TABLE public.planos
ADD COLUMN IF NOT EXISTS stripe_price_id text,
ADD COLUMN IF NOT EXISTS stripe_product_id text,
ADD COLUMN IF NOT EXISTS intervalo text CHECK (intervalo IN ('month', 'year', 'one_time'));

-- 2. Updates to 'user_expandido' ( Consolidated Table )
-- We add stripe_customer_id here instead of the legacy table
ALTER TABLE public.user_expandido
ADD COLUMN IF NOT EXISTS stripe_customer_id text;

CREATE INDEX IF NOT EXISTS ix_user_expandido_stripe_id ON public.user_expandido (stripe_customer_id);

-- 3. Updates to 'cliente_contrato'
-- 3.1 New Fields for Stripe
ALTER TABLE public.cliente_contrato
ADD COLUMN IF NOT EXISTS stripe_subscription_id text,
ADD COLUMN IF NOT EXISTS current_period_end timestamptz,
ADD COLUMN IF NOT EXISTS cancel_at_period_end boolean DEFAULT false;

CREATE INDEX IF NOT EXISTS ix_cliente_contrato_stripe_sub_id ON public.cliente_contrato (stripe_subscription_id);

-- 3.2 Migration Field for User Consolidation
-- We create a new link to the correct table 'user_expandido'
ALTER TABLE public.cliente_contrato
ADD COLUMN IF NOT EXISTS user_id uuid REFERENCES public.user_expandido(id);

CREATE INDEX IF NOT EXISTS ix_cliente_contrato_user_id ON public.cliente_contrato (user_id);

-- 3.3 DATA MIGRATION Logic
-- Try to find the correct 'user_expandido' for existing contracts based on the old 'id_cliente'
-- We assume user_expandido_cliente and user_expandido share the same Authentication 'user_id'
DO $$
BEGIN
    -- Only run if user_expandido_cliente table still exists
    IF EXISTS (SELECT FROM pg_tables WHERE schemaname = 'public' AND tablename = 'user_expandido_cliente') THEN
        
        UPDATE public.cliente_contrato cc
        SET user_id = ue.id
        FROM public.user_expandido ue
        JOIN public.user_expandido_cliente uec ON uec.user_id = ue.user_id
        WHERE cc.id_cliente = uec.id
        AND cc.user_id IS NULL; -- Only update if not already set
        
    END IF;
END $$;

-- 4. Disable manual trigger for recursive payments
DROP TRIGGER IF EXISTS trigger_pagamentos_recorrentes ON public.cliente_contrato;

-- 5. Adapt 'cliente_pagamento_contrato' to be 'faturas'
ALTER TABLE public.cliente_pagamento_contrato
ADD COLUMN IF NOT EXISTS stripe_invoice_id text,
ADD COLUMN IF NOT EXISTS invoice_pdf text,
ADD COLUMN IF NOT EXISTS billing_reason text,
ADD COLUMN IF NOT EXISTS valor_pago numeric(10,2);
