- Migration to add RPCs for Plan Management

-- 1. nxt_get_planos
CREATE OR REPLACE FUNCTION public.nxt_get_planos(
    p_produto_id uuid
)
RETURNS TABLE(
    id uuid,
    nome text,
    descricao text,
    valor numeric,
    intervalo text,
    stripe_price_id text,
    stripe_product_id text,
    ativo boolean,
    created_at timestamp without time zone
)
LANGUAGE plpgsql
SECURITY DEFINER
AS $function$
BEGIN
    RETURN QUERY
    SELECT 
        p.id,
        p.nome,
        p.descricao,
        p.valor,
        p.intervalo,
        p.stripe_price_id,
        p.stripe_product_id,
        TRUE as ativo, -- Logic for 'ativo' might be implicit or we add a column later. For now, assuming plans are active if present or we can add an 'active' column.
        -- Wait, 'planos' table definition in previous context didn't show 'ativo' column explicitly in the CREATE TABLE snippet provided by user, 
        -- but 'produtos' had it. Let's check if 'planos' has it.
        -- User provided: "create table public.planos ... valor numeric(10, 2) null, produto_id uuid null ..."
        -- No 'ativo' column in user snippet. 
        -- Let's return TRUE for now or check if we should add it.
        -- Schema usually has 'created_at'.
        p.created_at
    FROM public.planos p
    WHERE p.produto_id = p_produto_id
    ORDER BY p.created_at DESC;
END;
$function$;

-- 2. nxt_upsert_plano
CREATE OR REPLACE FUNCTION public.nxt_upsert_plano(
    p_id uuid,
    p_produto_id uuid,
    p_nome text,
    p_descricao text,
    p_valor numeric,
    p_intervalo text,
    p_stripe_price_id text,
    p_stripe_product_id text
)
RETURNS uuid
LANGUAGE plpgsql
SECURITY DEFINER
AS $function$
DECLARE
    v_id uuid;
BEGIN
    IF p_id IS NULL THEN
        -- Insert
        INSERT INTO public.planos (
            produto_id, 
            nome, 
            descricao, 
            valor, 
            intervalo, 
            stripe_price_id, 
            stripe_product_id,
            created_at
        ) VALUES (
            p_produto_id,
            p_nome,
            p_descricao,
            p_valor,
            p_intervalo,
            p_stripe_price_id,
            p_stripe_product_id,
            now()
        ) RETURNING id INTO v_id;
    ELSE
        -- Update
        UPDATE public.planos
        SET 
            nome = p_nome,
            descricao = p_descricao,
            valor = p_valor,
            intervalo = p_intervalo,
            stripe_price_id = p_stripe_price_id,
            stripe_product_id = p_stripe_product_id
        WHERE id = p_id
        RETURNING id INTO v_id;
    END IF;

    RETURN v_id;
END;
$function$;

-- 3. nxt_delete_plano
CREATE OR REPLACE FUNCTION public.nxt_delete_plano(
    p_id uuid
)
RETURNS boolean
LANGUAGE plpgsql
SECURITY DEFINER
AS $function$
BEGIN
    DELETE FROM public.planos WHERE id = p_id;
    RETURN FOUND;
EXCEPTION
    WHEN foreign_key_violation THEN
        RETURN FALSE; -- Could not delete due to existing contracts
END;
$function$;

-- Grant Permissions
GRANT EXECUTE ON FUNCTION public.nxt_get_planos(uuid) TO authenticated;
GRANT EXECUTE ON FUNCTION public.nxt_upsert_plano(uuid, uuid, text, text, numeric, text, text, text) TO authenticated;
GRANT EXECUTE ON FUNCTION public.nxt_delete_plano(uuid) TO authenticated;

GRANT EXECUTE ON FUNCTION public.nxt_get_planos(uuid) TO service_role;
GRANT EXECUTE ON FUNCTION public.nxt_upsert_plano(uuid, uuid, text, text, numeric, text, text, text) TO service_role;
GRANT EXECUTE ON FUNCTION public.nxt_delete_plano(uuid) TO service_role;
