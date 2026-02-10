

SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET xmloption = content;
SET client_min_messages = warning;
SET row_security = off;


CREATE EXTENSION IF NOT EXISTS "pg_cron" WITH SCHEMA "pg_catalog";






CREATE EXTENSION IF NOT EXISTS "pgsodium";






COMMENT ON SCHEMA "public" IS 'standard public schema';



CREATE EXTENSION IF NOT EXISTS "pg_graphql" WITH SCHEMA "graphql";






CREATE EXTENSION IF NOT EXISTS "pg_stat_statements" WITH SCHEMA "extensions";






CREATE EXTENSION IF NOT EXISTS "pgcrypto" WITH SCHEMA "extensions";






CREATE EXTENSION IF NOT EXISTS "pgjwt" WITH SCHEMA "extensions";






CREATE EXTENSION IF NOT EXISTS "supabase_vault" WITH SCHEMA "vault";






CREATE EXTENSION IF NOT EXISTS "uuid-ossp" WITH SCHEMA "extensions";






CREATE TYPE "public"."nivel_dificuldade" AS ENUM (
    '1',
    '2',
    '3'
);


ALTER TYPE "public"."nivel_dificuldade" OWNER TO "postgres";


CREATE TYPE "public"."role_enum" AS ENUM (
    'admin',
    'cliente',
    'paciente',
    'paciente_multi',
    'colaborador',
    'colaborador_multi',
    'clinica'
);


ALTER TYPE "public"."role_enum" OWNER TO "postgres";


CREATE TYPE "public"."status_contrato" AS ENUM (
    'ativo',
    'inativo',
    'cancelado'
);


ALTER TYPE "public"."status_contrato" OWNER TO "postgres";


CREATE TYPE "public"."tipo_documento_enum" AS ENUM (
    'exame',
    'receita',
    'atestado',
    'laudo',
    'outro'
);


ALTER TYPE "public"."tipo_documento_enum" OWNER TO "postgres";


CREATE TYPE "public"."tipo_exame" AS ENUM (
    'teste',
    'normatizacao',
    'exame'
);


ALTER TYPE "public"."tipo_exame" OWNER TO "postgres";


CREATE TYPE "public"."tipo_pergunta" AS ENUM (
    'Texto Longo',
    'Texto Curto',
    'Número',
    'Número Decimal',
    'Escolha',
    'Sim/Não',
    'Data e Hora'
);


ALTER TYPE "public"."tipo_pergunta" OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."check_user_produto_status"("p_user_id" "uuid", "p_produto_id" "uuid") RETURNS "jsonb"
    LANGUAGE "plpgsql"
    AS $$
declare
  v_status boolean;
begin
  select status
  into v_status
  from produtos_user
  where user_id = p_user_id
    and produto_id = p_produto_id
  limit 1;

  if found then
    return jsonb_build_object('produto', true, 'status', v_status);
  else
    return jsonb_build_object('produto', false, 'status', null);
  end if;
end;
$$;


ALTER FUNCTION "public"."check_user_produto_status"("p_user_id" "uuid", "p_produto_id" "uuid") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."cliente_mesma_clinica"("id_clinica_param" "uuid") RETURNS boolean
    LANGUAGE "plpgsql" SECURITY DEFINER
    AS $$
begin
  return exists (
    select 1
    from public.user_expandido_cliente
    where user_id = auth.uid()
    and clinica_id = id_clinica_param
  );
end;
$$;


ALTER FUNCTION "public"."cliente_mesma_clinica"("id_clinica_param" "uuid") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."confirmar_email_usuario_expandido"() RETURNS "trigger"
    LANGUAGE "plpgsql" SECURITY DEFINER
    AS $$
begin
  update auth.users
  set email_confirmed_at = now()
  where id = NEW.user_id
    and (email_confirmed_at is null or email_confirmed_at > now()); -- só confirma se não está confirmado

  return NEW;
end;
$$;


ALTER FUNCTION "public"."confirmar_email_usuario_expandido"() OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."copiar_modelos_anamnese_globais_para_cliente_id"("cliente_id" "uuid") RETURNS "void"
    LANGUAGE "plpgsql"
    AS $$
DECLARE
    cliente RECORD;
    modelo_global RECORD;
    novo_modelo_id UUID;
    pergunta RECORD;
BEGIN
    SELECT * INTO cliente FROM user_expandido_cliente WHERE id = cliente_id;
    FOR modelo_global IN 
        SELECT * FROM anamnese_modelo WHERE global IS TRUE
    LOOP
        INSERT INTO anamnese_modelo (
            nome,
            id_clinica,
            id_cliente_criar,
            criado_em,
            modificado_em,
            status,
            global
        ) VALUES (
            modelo_global.nome,
            cliente.clinica_id,
            cliente.id,
            now(),
            now(),
            TRUE,
            FALSE
        )
        RETURNING id INTO novo_modelo_id;

        FOR pergunta IN
            SELECT * FROM anamnese_pergunta WHERE id_anamnese_modelo = modelo_global.id
        LOOP
            INSERT INTO anamnese_pergunta (
                pergunta,
                id_anamnese_modelo,
                id_clinica,
                global,
                id_cliente_criar,
                criado_em,
                modificado_em,
                tipo_pergunta,
                obrigatoria,
                ordem
            ) VALUES (
                pergunta.pergunta,
                novo_modelo_id,
                cliente.clinica_id,
                FALSE,
                cliente.id,
                now(),
                now(),
                pergunta.tipo_pergunta,
                pergunta.obrigatoria,
                pergunta.ordem
            );
        END LOOP;
    END LOOP;
END;
$$;


ALTER FUNCTION "public"."copiar_modelos_anamnese_globais_para_cliente_id"("cliente_id" "uuid") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."criar_exame_completo"("p_exame" "jsonb", "p_perguntas" "jsonb", "p_respostas" "jsonb", "p_valores" "jsonb") RETURNS "jsonb"
    LANGUAGE "plpgsql"
    AS $$declare
  v_modelo_id uuid;
  v_pergunta_id uuid;
  v_result jsonb := '{}'::jsonb;
  v_pergunta jsonb;
  v_resp jsonb;
  v_val jsonb;
  v_map jsonb := '{}'::jsonb; -- mapa id_local -> uuid_pergunta
  v_id_local int;
  v_ordem int := 1;
begin
  -- 1) Criar o exame_modelo
  insert into public.exame_modelo (
    nome, descricao, instrucoes_preparo, observacoes,
    tipo_id, subtipo_id, sistema_id, global,
    id_cliente_criar, id_user_clinica_criar
  )
  values (
    p_exame->>'nome_exame',
    p_exame->>'descricao',
    p_exame->>'instrucoes_preparo',
    p_exame->>'observacoes',
    nullif(p_exame->>'tipo','')::uuid,
    nullif(p_exame->>'subtipo','')::uuid,
    nullif(p_exame->>'sistema','')::uuid,
    coalesce((p_exame->>'global')::boolean, false),
    case when p_exame->>'criador_papel' = 'cliente'
         then (p_exame->>'criador_id')::uuid end,
    case when p_exame->>'criador_papel' = 'user_clinica'
         then (p_exame->>'criador_id')::uuid end
  )
  returning id into v_modelo_id;

  -- 2) Loop nas perguntas
  for v_pergunta in
    select * from jsonb_array_elements(p_perguntas)
  loop
    insert into public.exame_pergunta (
      id_modelo, ordem, legenda, tem_legenda,
      pergunta, dica, tipo_pergunta, encolhido
    )
    values (
      v_modelo_id,
      (v_pergunta->>'ordem')::int,
      nullif(v_pergunta->>'legenda',''),
      coalesce((v_pergunta->>'tem_legenda')::boolean, false),
      v_pergunta->>'pergunta',
      v_pergunta->>'dica',
      (v_pergunta->>'tipo_pergunta')::public.tipo_pergunta,
      coalesce((v_pergunta->>'encolhido')::boolean, false)
    )
    returning id into v_pergunta_id;

    v_id_local := (v_pergunta->>'id')::int;
    v_map := v_map || jsonb_build_object(v_id_local::text, v_pergunta_id);
  end loop;

  -- 3) Inserir respostas possíveis
  v_ordem := 1;
  for v_resp in
    select * from jsonb_array_elements(p_respostas)
  loop
    v_id_local := (v_resp->>'id_pergunta')::int;

    insert into public.exame_respostas_possiveis (
      id_pergunta, ordem, resposta, correta
    )
    values (
      (v_map ->> v_id_local::text)::uuid,
      v_ordem,
      v_resp->>'resposta',
      coalesce((v_resp->>'correta')::boolean, false)
    );

    v_ordem := v_ordem + 1;
  end loop;

  -- 4) Inserir valores de referência
  for v_val in
    select * from jsonb_array_elements(p_valores)
  loop
    v_id_local := (v_val->>'id_pergunta')::int;

    insert into public.exame_valores_referencia (
      id_pergunta, categoria, valor
    )
    values (
      (v_map ->> v_id_local::text)::uuid,
      v_val->>'categoria',
      v_val->>'valor'
    );
  end loop;

  -- Retorno
  v_result := jsonb_build_object(
    'id_modelo', v_modelo_id,
    'status', 'ok',
    'mapa', v_map
  );

  return v_result;
end;$$;


ALTER FUNCTION "public"."criar_exame_completo"("p_exame" "jsonb", "p_perguntas" "jsonb", "p_respostas" "jsonb", "p_valores" "jsonb") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."custom_access_token_hook"("event" "jsonb") RETURNS "jsonb"
    LANGUAGE "plpgsql" STABLE SECURITY DEFINER
    SET "search_path" TO ''
    AS $$DECLARE
  claims jsonb;
  role_nome text;
  clinica_id uuid;
BEGIN
  -- Busca o nome da role e clinica_id da tabela user_role_auth
  SELECT r.nome_role, ur.clinica_id
  INTO role_nome, clinica_id  -- clinica_id é variável local
  FROM public.user_role_auth ur
  JOIN public.role_auth r ON ur.role_id = r.id
  WHERE ur.user_id = (event->>'user_id')::uuid
  LIMIT 1;

  -- Inicializa claims do evento
  claims := event->'claims';

  -- Adiciona o role ao claims
  claims := jsonb_set(claims, '{user_role}', to_jsonb(role_nome));

  -- Verifica se clinica_id foi encontrado, e se sim, adiciona ao claims
  IF clinica_id IS NOT NULL THEN
    -- Usamos explicitamente a variável clinica_id e não a coluna
    claims := jsonb_set(claims, '{clinica_id}', to_jsonb(clinica_id));
  END IF;

  -- Retorna o evento atualizado com as claims
  RETURN jsonb_set(event, '{claims}', claims);
END;$$;


ALTER FUNCTION "public"."custom_access_token_hook"("event" "jsonb") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."deletar_exame_completo"("p_id_modelo" "uuid") RETURNS "jsonb"
    LANGUAGE "plpgsql"
    AS $$
declare
  v_exists boolean;
  v_result jsonb;
begin
  -- Verifica se o exame existe
  select exists(select 1 from public.exame_modelo where id = p_id_modelo)
  into v_exists;

  if not v_exists then
    return jsonb_build_object(
      'status', 'error',
      'message', 'Exame não encontrado'
    );
  end if;

  -- Exclui o modelo (cascata apaga perguntas, respostas e valores)
  delete from public.exame_modelo where id = p_id_modelo;

  v_result := jsonb_build_object(
    'status', 'deleted',
    'id_modelo', p_id_modelo
  );

  return v_result;
end;
$$;


ALTER FUNCTION "public"."deletar_exame_completo"("p_id_modelo" "uuid") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."editar_exame_completo"("p_exame" "jsonb", "p_perguntas" "jsonb", "p_respostas" "jsonb", "p_valores" "jsonb") RETURNS "jsonb"
    LANGUAGE "plpgsql"
    AS $_$
declare
  v_modelo_id uuid;
  v_pergunta_id uuid;
  v_result jsonb := '{}'::jsonb;
  v_pergunta jsonb;
  v_resp jsonb;
  v_val jsonb;
  v_map jsonb := '{}'::jsonb; -- mapa id_local -> uuid_pergunta
  v_id_local text;
  v_ordem int := 1;
begin
  -- 1) Pega o id do modelo
  v_modelo_id := (p_exame->>'id')::uuid;

  -- 2) Atualiza o exame_modelo
  update public.exame_modelo
  set
    nome = coalesce(nullif(p_exame->>'nome_exame',''), nome),
    descricao = coalesce(nullif(p_exame->>'descricao',''), descricao),
    instrucoes_preparo = coalesce(nullif(p_exame->>'instrucoes_preparo',''), instrucoes_preparo),
    observacoes = coalesce(nullif(p_exame->>'observacoes',''), observacoes),
    tipo_id = coalesce(nullif(p_exame->>'tipo','')::uuid, tipo_id),
    subtipo_id = coalesce(nullif(p_exame->>'subtipo','')::uuid, subtipo_id),
    sistema_id = coalesce(nullif(p_exame->>'sistema','')::uuid, sistema_id),
    global = coalesce((p_exame->>'global')::boolean, global),
    deletado = coalesce((p_exame->>'deletado')::boolean, deletado),
    id_cliente_modificar = case when p_exame->>'criador_papel' = 'cliente'
                                then (p_exame->>'criador_id')::uuid else id_cliente_modificar end,
    id_user_clinica_modificar = case when p_exame->>'criador_papel' = 'user_clinica'
                                     then (p_exame->>'criador_id')::uuid else id_user_clinica_modificar end,
    modificado_em = now()
  where id = v_modelo_id;

  -- 3) Processa perguntas
  for v_pergunta in
    select value
    from jsonb_array_elements(coalesce(p_perguntas, '[]'::jsonb)) as p(value)
  loop
    v_id_local := v_pergunta->>'id';

    -- tenta interpretar como UUID (pergunta existente)
    begin
      v_pergunta_id := v_id_local::uuid;

      update public.exame_pergunta
      set
        ordem = coalesce((v_pergunta->>'ordem')::int, ordem),
        legenda = coalesce(nullif(v_pergunta->>'legenda',''), legenda),
        tem_legenda = coalesce((v_pergunta->>'tem_legenda')::boolean, tem_legenda),
        pergunta = coalesce(nullif(v_pergunta->>'pergunta',''), pergunta),
        dica = coalesce(nullif(v_pergunta->>'dica',''), dica),
        tipo_pergunta = coalesce((v_pergunta->>'tipo_pergunta')::public.tipo_pergunta, tipo_pergunta),
        encolhido = coalesce((v_pergunta->>'encolhido')::boolean, encolhido),
        deletado = coalesce((v_pergunta->>'deletado')::boolean, deletado)
      where id = v_pergunta_id;

      -- limpa respostas e valores antigos
      delete from public.exame_respostas_possiveis where id_pergunta = v_pergunta_id;
      delete from public.exame_valores_referencia  where id_pergunta = v_pergunta_id;

    exception when invalid_text_representation then
      -- não era UUID → cria nova pergunta
      insert into public.exame_pergunta (
        id_modelo, ordem, legenda, tem_legenda,
        pergunta, dica, tipo_pergunta, encolhido, deletado
      )
      values (
        v_modelo_id,
        (v_pergunta->>'ordem')::int,
        nullif(v_pergunta->>'legenda',''),
        coalesce((v_pergunta->>'tem_legenda')::boolean, false),
        v_pergunta->>'pergunta',
        v_pergunta->>'dica',
        (v_pergunta->>'tipo_pergunta')::public.tipo_pergunta,
        coalesce((v_pergunta->>'encolhido')::boolean, false),
        coalesce((v_pergunta->>'deletado')::boolean, false)
      )
      returning id into v_pergunta_id;
    end;

    -- Atualiza mapa (id_local -> uuid)
    v_map := v_map || jsonb_build_object(v_id_local, v_pergunta_id);

    -- 4) Recria respostas possíveis (comparação robusta + alias correto)
    v_ordem := 1;
    for v_resp in
      select value
      from jsonb_array_elements(coalesce(p_respostas, '[]'::jsonb)) as r(value)
      where (
        -- se vier UUID válido, compara como uuid
        (case when (value->>'id_pergunta') ~* '^[0-9a-f-]{8}-[0-9a-f-]{4}-[0-9a-f-]{4}-[0-9a-f-]{4}-[0-9a-f-]{12}$'
              then (value->>'id_pergunta')::uuid end
        ) = v_pergunta_id
        -- ou compara como texto com o id local/uuid em texto
        or coalesce(value->>'id_pergunta','') = coalesce(v_id_local,'')
        or coalesce(value->>'id_pergunta','') = coalesce(v_pergunta_id::text,'')
        or coalesce(value->>'id_pergunta','') = coalesce(v_map->>v_id_local,'')
      )
    loop
      insert into public.exame_respostas_possiveis (
        id_pergunta, ordem, resposta, correta
      )
      values (
        v_pergunta_id,
        coalesce((v_resp->>'ordem')::int, v_ordem),
        v_resp->>'resposta',
        coalesce((v_resp->>'correta')::boolean, false)
      );
      v_ordem := v_ordem + 1;
    end loop;

    -- 5) Recria valores de referência (mesma lógica + alias correto)
    for v_val in
      select value
      from jsonb_array_elements(coalesce(p_valores, '[]'::jsonb)) as r(value)
      where (
        (case when (value->>'id_pergunta') ~* '^[0-9a-f-]{8}-[0-9a-f-]{4}-[0-9a-f-]{4}-[0-9a-f-]{4}-[0-9a-f-]{12}$'
              then (value->>'id_pergunta')::uuid end
        ) = v_pergunta_id
        or coalesce(value->>'id_pergunta','') = coalesce(v_id_local,'')
        or coalesce(value->>'id_pergunta','') = coalesce(v_pergunta_id::text,'')
        or coalesce(value->>'id_pergunta','') = coalesce(v_map->>v_id_local,'')
      )
    loop
      insert into public.exame_valores_referencia (
        id_pergunta, categoria, valor
      )
      values (
        v_pergunta_id,
        v_val->>'categoria',
        v_val->>'valor'
      );
    end loop;

  end loop;

  -- Retorno
  v_result := jsonb_build_object(
    'id_modelo', v_modelo_id,
    'status', 'updated',
    'mapa', v_map
  );

  return v_result;
end;
$_$;


ALTER FUNCTION "public"."editar_exame_completo"("p_exame" "jsonb", "p_perguntas" "jsonb", "p_respostas" "jsonb", "p_valores" "jsonb") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."email_existe_no_auth"("email_input" "text") RETURNS boolean
    LANGUAGE "plpgsql" SECURITY DEFINER
    AS $$
begin
  return exists (
    select 1
    from auth.users
    where lower(auth.users.email) = lower(email_input)
  );
end;
$$;


ALTER FUNCTION "public"."email_existe_no_auth"("email_input" "text") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."gerar_pagamentos_recorrentes"() RETURNS "trigger"
    LANGUAGE "plpgsql"
    AS $$
DECLARE
  i INT;
BEGIN
  FOR i IN 1..12 LOOP
    INSERT INTO public.cliente_pagamento_contrato (
      id_contrato,
      mes_index,
      data
    ) VALUES (
      NEW.id,
      i,
      (NEW.data_criacao + (interval '1 month' * (i - 1)))::DATE
    );
  END LOOP;

  RETURN NEW;
END;
$$;


ALTER FUNCTION "public"."gerar_pagamentos_recorrentes"() OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."get_admins_by_produto_paginado"("p_produto_id" "uuid", "p_page" integer, "p_limit" integer, "p_nome" "text" DEFAULT NULL::"text") RETURNS "jsonb"
    LANGUAGE "plpgsql"
    AS $$
declare
  v_offset int;
  v_total int;
  v_paginas int;
  v_result jsonb;
begin
  -- Calcula offset
  v_offset := (p_page - 1) * p_limit;

  -- Conta total de registros (sem filtrar status)
  select count(*)
  into v_total
  from public.user_expandido_admin ua
  join public.produtos_user pu on pu.user_id = ua.user_id
  where pu.produto_id = p_produto_id
    and (
      p_nome is null
      or ua.nome_completo ilike '%' || p_nome || '%'
    );

  -- Calcula nº de páginas
  v_paginas := ceil(v_total::numeric / p_limit)::int;

  -- Monta resultado em JSON
  v_result := jsonb_build_object(
    'total', v_total,
    'paginas', v_paginas,
    'pagina_atual', p_page,
    'itens_por_pagina', p_limit,
    'itens', coalesce((
      select jsonb_agg(row_to_json(r))
      from (
        select
          ua.id,
          ua.imagem_user,
          ua.nome_completo,
          ua.email,
          ua.telefone,
          ua.status   -- 👈 agora traz true ou false
        from public.user_expandido_admin ua
        join public.produtos_user pu on pu.user_id = ua.user_id
        where pu.produto_id = p_produto_id
          and (
            p_nome is null
            or ua.nome_completo ilike '%' || p_nome || '%'
          )
        order by ua.nome_completo
        limit p_limit offset v_offset
      ) r
    ), '[]'::jsonb)
  );

  return v_result;
end;
$$;


ALTER FUNCTION "public"."get_admins_by_produto_paginado"("p_produto_id" "uuid", "p_page" integer, "p_limit" integer, "p_nome" "text") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."get_complete_schema"() RETURNS "jsonb"
    LANGUAGE "plpgsql"
    AS $$
DECLARE
    result jsonb;
BEGIN
    -- Get all enums
    WITH enum_types AS (
        SELECT 
            t.typname as enum_name,
            array_agg(e.enumlabel ORDER BY e.enumsortorder) as enum_values
        FROM pg_type t
        JOIN pg_enum e ON t.oid = e.enumtypid
        JOIN pg_catalog.pg_namespace n ON n.oid = t.typnamespace
        WHERE n.nspname = 'public'
        GROUP BY t.typname
    )
    SELECT jsonb_build_object(
        'enums',
        COALESCE(
            jsonb_agg(
                jsonb_build_object(
                    'name', enum_name,
                    'values', to_jsonb(enum_values)
                )
            ),
            '[]'::jsonb
        )
    )
    FROM enum_types
    INTO result;

    -- Get all tables with their details
    WITH RECURSIVE 
    columns_info AS (
        SELECT 
            c.oid as table_oid,
            c.relname as table_name,
            a.attname as column_name,
            format_type(a.atttypid, a.atttypmod) as column_type,
            a.attnotnull as notnull,
            pg_get_expr(d.adbin, d.adrelid) as column_default,
            CASE 
                WHEN a.attidentity != '' THEN true
                WHEN pg_get_expr(d.adbin, d.adrelid) LIKE 'nextval%' THEN true
                ELSE false
            END as is_identity,
            EXISTS (
                SELECT 1 FROM pg_constraint con 
                WHERE con.conrelid = c.oid 
                AND con.contype = 'p' 
                AND a.attnum = ANY(con.conkey)
            ) as is_pk
        FROM pg_class c
        JOIN pg_namespace n ON n.oid = c.relnamespace
        LEFT JOIN pg_attribute a ON a.attrelid = c.oid
        LEFT JOIN pg_attrdef d ON d.adrelid = c.oid AND d.adnum = a.attnum
        WHERE n.nspname = 'public' 
        AND c.relkind = 'r'
        AND a.attnum > 0 
        AND NOT a.attisdropped
    ),
    fk_info AS (
        SELECT 
            c.oid as table_oid,
            jsonb_agg(
                jsonb_build_object(
                    'name', con.conname,
                    'column', col.attname,
                    'foreign_schema', fs.nspname,
                    'foreign_table', ft.relname,
                    'foreign_column', fcol.attname,
                    'on_delete', CASE con.confdeltype
                        WHEN 'a' THEN 'NO ACTION'
                        WHEN 'c' THEN 'CASCADE'
                        WHEN 'r' THEN 'RESTRICT'
                        WHEN 'n' THEN 'SET NULL'
                        WHEN 'd' THEN 'SET DEFAULT'
                        ELSE NULL
                    END
                )
            ) as foreign_keys
        FROM pg_class c
        JOIN pg_constraint con ON con.conrelid = c.oid
        JOIN pg_attribute col ON col.attrelid = con.conrelid AND col.attnum = ANY(con.conkey)
        JOIN pg_class ft ON ft.oid = con.confrelid
        JOIN pg_namespace fs ON fs.oid = ft.relnamespace
        JOIN pg_attribute fcol ON fcol.attrelid = con.confrelid AND fcol.attnum = ANY(con.confkey)
        WHERE con.contype = 'f'
        GROUP BY c.oid
    ),
    index_info AS (
        SELECT 
            c.oid as table_oid,
            jsonb_agg(
                jsonb_build_object(
                    'name', i.relname,
                    'using', am.amname,
                    'columns', (
                        SELECT jsonb_agg(a.attname ORDER BY array_position(ix.indkey, a.attnum))
                        FROM unnest(ix.indkey) WITH ORDINALITY as u(attnum, ord)
                        JOIN pg_attribute a ON a.attrelid = c.oid AND a.attnum = u.attnum
                    )
                )
            ) as indexes
        FROM pg_class c
        JOIN pg_index ix ON ix.indrelid = c.oid
        JOIN pg_class i ON i.oid = ix.indexrelid
        JOIN pg_am am ON am.oid = i.relam
        WHERE NOT ix.indisprimary
        GROUP BY c.oid
    ),
    policy_info AS (
        SELECT 
            c.oid as table_oid,
            jsonb_agg(
                jsonb_build_object(
                    'name', pol.polname,
                    'command', CASE pol.polcmd
                        WHEN 'r' THEN 'SELECT'
                        WHEN 'a' THEN 'INSERT'
                        WHEN 'w' THEN 'UPDATE'
                        WHEN 'd' THEN 'DELETE'
                        WHEN '*' THEN 'ALL'
                    END,
                    'roles', (
                        SELECT string_agg(quote_ident(r.rolname), ', ')
                        FROM pg_roles r
                        WHERE r.oid = ANY(pol.polroles)
                    ),
                    'using', pg_get_expr(pol.polqual, pol.polrelid),
                    'check', pg_get_expr(pol.polwithcheck, pol.polrelid)
                )
            ) as policies
        FROM pg_class c
        JOIN pg_policy pol ON pol.polrelid = c.oid
        GROUP BY c.oid
    ),
    trigger_info AS (
        SELECT 
            c.oid as table_oid,
            jsonb_agg(
                jsonb_build_object(
                    'name', t.tgname,
                    'timing', CASE 
                        WHEN t.tgtype & 2 = 2 THEN 'BEFORE'
                        WHEN t.tgtype & 4 = 4 THEN 'AFTER'
                        WHEN t.tgtype & 64 = 64 THEN 'INSTEAD OF'
                    END,
                    'events', (
                        CASE WHEN t.tgtype & 1 = 1 THEN 'INSERT'
                             WHEN t.tgtype & 8 = 8 THEN 'DELETE'
                             WHEN t.tgtype & 16 = 16 THEN 'UPDATE'
                             WHEN t.tgtype & 32 = 32 THEN 'TRUNCATE'
                        END
                    ),
                    'statement', pg_get_triggerdef(t.oid)
                )
            ) as triggers
        FROM pg_class c
        JOIN pg_trigger t ON t.tgrelid = c.oid
        WHERE NOT t.tgisinternal
        GROUP BY c.oid
    ),
    table_info AS (
        SELECT DISTINCT 
            c.table_oid,
            c.table_name,
            jsonb_agg(
                jsonb_build_object(
                    'name', c.column_name,
                    'type', c.column_type,
                    'notnull', c.notnull,
                    'default', c.column_default,
                    'identity', c.is_identity,
                    'is_pk', c.is_pk
                ) ORDER BY c.column_name
            ) as columns,
            COALESCE(fk.foreign_keys, '[]'::jsonb) as foreign_keys,
            COALESCE(i.indexes, '[]'::jsonb) as indexes,
            COALESCE(p.policies, '[]'::jsonb) as policies,
            COALESCE(t.triggers, '[]'::jsonb) as triggers
        FROM columns_info c
        LEFT JOIN fk_info fk ON fk.table_oid = c.table_oid
        LEFT JOIN index_info i ON i.table_oid = c.table_oid
        LEFT JOIN policy_info p ON p.table_oid = c.table_oid
        LEFT JOIN trigger_info t ON t.table_oid = c.table_oid
        GROUP BY c.table_oid, c.table_name, fk.foreign_keys, i.indexes, p.policies, t.triggers
    )
    SELECT result || jsonb_build_object(
        'tables',
        COALESCE(
            jsonb_agg(
                jsonb_build_object(
                    'name', table_name,
                    'columns', columns,
                    'foreign_keys', foreign_keys,
                    'indexes', indexes,
                    'policies', policies,
                    'triggers', triggers
                )
            ),
            '[]'::jsonb
        )
    )
    FROM table_info
    INTO result;

    -- Get all functions
    WITH function_info AS (
        SELECT 
            p.proname AS name,
            pg_get_functiondef(p.oid) AS definition
        FROM pg_proc p
        JOIN pg_namespace n ON n.oid = p.pronamespace
        WHERE n.nspname = 'public'
        AND p.prokind = 'f'
    )
    SELECT result || jsonb_build_object(
        'functions',
        COALESCE(
            jsonb_agg(
                jsonb_build_object(
                    'name', name,
                    'definition', definition
                )
            ),
            '[]'::jsonb
        )
    )
    FROM function_info
    INTO result;

    RETURN result;
END;
$$;


ALTER FUNCTION "public"."get_complete_schema"() OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."get_exame_completo"("p_id_modelo" "uuid") RETURNS "jsonb"
    LANGUAGE "plpgsql"
    AS $$
declare
  v_result jsonb;
begin
  select jsonb_build_object(
    'exame', row_to_json(em.*),
    'perguntas', (
      select coalesce(jsonb_agg(ep.*), '[]'::jsonb)
      from public.exame_pergunta ep
      where ep.id_modelo = em.id
    ),
    'respostas_possiveis', (
      select coalesce(jsonb_agg(er.*), '[]'::jsonb)
      from public.exame_respostas_possiveis er
      join public.exame_pergunta ep on ep.id = er.id_pergunta
      where ep.id_modelo = em.id
    ),
    'valores_referencia', (
      select coalesce(jsonb_agg(ev.*), '[]'::jsonb)
      from public.exame_valores_referencia ev
      join public.exame_pergunta ep on ep.id = ev.id_pergunta
      where ep.id_modelo = em.id
    )
  )
  into v_result
  from public.exame_modelo em
  where em.id = p_id_modelo;

  return v_result;
end;
$$;


ALTER FUNCTION "public"."get_exame_completo"("p_id_modelo" "uuid") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."get_questionario"("p_id_modelo" "uuid" DEFAULT NULL::"uuid", "p_nome_modelo" "text" DEFAULT NULL::"text") RETURNS "jsonb"
    LANGUAGE "plpgsql"
    AS $$
declare
  v_result jsonb := '[]'::jsonb;
begin
  v_result := coalesce((
    select jsonb_agg(
      jsonb_build_object(
        -- Modelo
        'modelo', row_to_json(qm),

        -- Grupos
        'grupos', (
          select coalesce(jsonb_agg(
            jsonb_build_object(
              'id', qpg.id,
              'nome', qpg.nome,
              'ordem', qpg.ordem,
              'encolhido', false
            )
            order by qpg.nome
          ), '[]'::jsonb)
          from public.questionario_perguntas_grupo qpg
          where qpg.id_questionario = qm.id
        ),

        -- Perguntas
        'perguntas', (
          select coalesce(jsonb_agg(
            jsonb_build_object(
              'id', qp.id,
              'id_grupo', qp.id_grupo,
              'ordem', qp.ordem,
              'pergunta', qp.pergunta,
              'encolhido', false
            )
            order by qp.ordem
          ), '[]'::jsonb)
          from public.questionario_perguntas qp
          where qp.id_questionario = qm.id
        ),

        -- Respostas
        'respostas', (
          select coalesce(jsonb_agg(
            jsonb_build_object(
              'id', qr.id,
              'id_questionario', qr.id_questionario,
              'id_pergunta', qr.id_pergunta,
              'ordem', qr.ordem,
              'resposta', qr.resposta,
              'pontuacao', qr.pontuacao,
              'encolhido', false
            )
            order by qr.ordem
          ), '[]'::jsonb)
          from public.questionario_respostas qr
          where qr.id_questionario = qm.id
             or qr.id_pergunta in (
               select id from public.questionario_perguntas where id_questionario = qm.id
             )
        ),

        -- Gabarito
        'gabarito', (
          select coalesce(jsonb_agg(
            jsonb_build_object(
              'id', qg.id,
              'pontuacao_min', qg.pontuacao_min,
              'pontuacao_max', qg.pontuacao_max,
              'diagnostico', qg.diagnostico,
              'observacoes', qg.observacoes,
              'encolhido', false
            )
            order by qg.pontuacao_min
          ), '[]'::jsonb)
          from public.questionario_gabarito qg
          where qg.id_questionario = qm.id
        )
      )
      order by qm.nome
    )
    from public.questionario_modelo qm
    where
      (p_id_modelo is null or qm.id = p_id_modelo)
      and (p_nome_modelo is null or qm.nome ilike '%' || p_nome_modelo || '%')
  ), '[]'::jsonb);

  return v_result;
end;
$$;


ALTER FUNCTION "public"."get_questionario"("p_id_modelo" "uuid", "p_nome_modelo" "text") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."get_user_dimensoes"("p_id_user_expandido" "uuid") RETURNS "jsonb"
    LANGUAGE "plpgsql" SECURITY DEFINER
    SET "search_path" TO 'public', 'pg_temp'
    AS $$
DECLARE
  v_user JSONB := '{}'::jsonb;
  v_papeis JSONB := '[]'::jsonb;
  v_produtos JSONB := '[]'::jsonb;
  v_clinicas JSONB := '[]'::jsonb;
  v_respostas JSONB := '{}'::jsonb;
  v_result JSONB;
BEGIN
  -- 🧠 0️⃣ TEMPLATE MODE (sem ID)
  IF p_id_user_expandido IS NULL THEN
    SELECT jsonb_object_agg(
      ('r_' || replace(lower(p.label), ' ', '_')),
      jsonb_build_object(
        'id_pergunta', p.id,
        'label', p.label,
        'resposta', NULL
      )
    )
    INTO v_respostas
    FROM perguntas_user p
    WHERE p.ativo IS TRUE;

    -- esquema vazio de user_expandido
    v_user := jsonb_build_object(
      'id_user_expandido', NULL,
      'user_id', NULL,
      'nome_completo', NULL,
      'email', NULL,
      'telefone', NULL,
      'imagem_user', NULL,
      'status', NULL,
      'created_at', NULL,
      'updated_at', NULL
    );

    v_result := jsonb_build_object(
      'dados', v_user || jsonb_build_object('respostas', v_respostas),
      'papeis', v_papeis,
      'clinicas', v_clinicas,
      'produtos', v_produtos
    );
    RETURN v_result;
  END IF;

  -- 🧱 1️⃣ USER_EXPANDIDO (todas as colunas)
  SELECT jsonb_build_object(
    'id_user_expandido', ue.id,
    'user_id', ue.user_id,
    'nome_completo', ue.nome_completo,
    'email', ue.email,
    'telefone', ue.telefone,
    'imagem_user', ue.imagem_user,
    'status', ue.status,
    'created_at', ue.created_at,
    'updated_at', ue.updated_at
  )
  INTO v_user
  FROM user_expandido ue
  WHERE ue.id = p_id_user_expandido;

  -- 🧠 2️⃣ PAPEIS
  SELECT jsonb_agg(jsonb_build_object(
    'role_id', ra.id,
    'nome_papel', ra.nome_role
  ))
  INTO v_papeis
  FROM user_role_auth ura
  LEFT JOIN role_auth ra ON ra.id = ura.role_id
  WHERE ura.user_id = (SELECT user_id FROM user_expandido WHERE id = p_id_user_expandido);

  -- 💼 3️⃣ PRODUTOS
  SELECT jsonb_agg(jsonb_build_object(
    'produto_id', p.id,
    'nome_produto', p.nome,
    'slug', p.slug,
    'ativo', p.ativo
  ))
  INTO v_produtos
  FROM produtos_user pu
  LEFT JOIN produtos p ON p.id = pu.produto_id
  WHERE pu.id_user_expandido = p_id_user_expandido;

  -- 🏥 4️⃣ CLÍNICAS
  SELECT jsonb_agg(jsonb_build_object(
    'clinica_id', c.id,
    'clinica_nome', c.nome,
    'imagem_clinica', c.imagem_clinica
  ))
  INTO v_clinicas
  FROM clinica_user cu
  LEFT JOIN clinica c ON c.id = cu.id_clinica
  WHERE cu.id_user = p_id_user_expandido;

  -- 🗒️ 5️⃣ RESPOSTAS
  SELECT jsonb_object_agg(
    ('r_' || replace(lower(p.label), ' ', '_')),
    jsonb_build_object(
      'id_pergunta', p.id,
      'label', p.label,
      'resposta', r.resposta
    )
  )
  INTO v_respostas
  FROM respostas_user r
  JOIN perguntas_user p ON p.id = r.id_pergunta
  WHERE r.id_user = p_id_user_expandido;

  -- 🧩 6️⃣ MONTA FINAL
  v_result := jsonb_build_object(
    'dados', v_user || jsonb_build_object('respostas', COALESCE(v_respostas, '{}'::jsonb)),
    'papeis', COALESCE(v_papeis, '[]'::jsonb),
    'clinicas', COALESCE(v_clinicas, '[]'::jsonb),
    'produtos', COALESCE(v_produtos, '[]'::jsonb)
  );

  RETURN v_result;
END;
$$;


ALTER FUNCTION "public"."get_user_dimensoes"("p_id_user_expandido" "uuid") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."get_user_dimensoes_v2"("p_papel" "uuid", "p_id_user" "uuid" DEFAULT NULL::"uuid", "p_id_clinica" "uuid" DEFAULT NULL::"uuid") RETURNS "jsonb"
    LANGUAGE "plpgsql" SECURITY DEFINER
    SET "search_path" TO 'public', 'pg_temp'
    AS $$
DECLARE
    v_user_rec record;
    v_user_expandido_id uuid;
    v_user_id uuid;

    v_json_itens JSONB := '[]'::jsonb;
    v_root JSONB;

    v_clinica_rec record;
    v_role_rec record;
    v_resp record;
    v_perg record;

    v_papel_cliente CONSTANT UUID := '67ed3bd7-72ef-4d92-b43b-78250874be1e';
BEGIN
    --------------------------------------------------------------------------
    -- 1. USER_EXPANDIDO (edição ou criação)
    --------------------------------------------------------------------------
    IF p_id_user IS NOT NULL THEN
        SELECT *
        INTO v_user_rec
        FROM user_expandido
        WHERE id = p_id_user;

        v_user_expandido_id := v_user_rec.id;
        v_user_id := v_user_rec.user_id;
    ELSE
        v_user_expandido_id := NULL;
        v_user_id := NULL;
    END IF;

    --------------------------------------------------------------------------
    -- 2. ROOT "user"
    --------------------------------------------------------------------------
    v_root := jsonb_build_object(
        'id_user_expandido', v_user_expandido_id,
        'user_id',           v_user_id
    );

    --------------------------------------------------------------------------
    -- 3. FAKE: user_expandido (nome, email, telefone, imagem_user, senha)
    --------------------------------------------------------------------------
    IF v_user_rec IS NULL THEN
        -- CRIAÇÃO
        v_json_itens := v_json_itens || jsonb_build_array(

            -- nome completo (sem ordem)
            jsonb_build_object(
                'id_pergunta','user_expandido.nome_completo',
                'pergunta','nome_completo',
                'label','Nome Completo',
                'tipo_pergunta','texto',
                'largura',2,'altura',36,'ordem',NULL,
                'obrigatorio',FALSE,'depende',FALSE,
                'depende_de',NULL,'valor_depende',NULL,'opcoes',NULL,
                'resposta',NULL,'id_dimensao',NULL,'extra_1',NULL,'extra_2',NULL
            ),

            -- email (ordem 21)
            jsonb_build_object(
                'id_pergunta','user_expandido.email',
                'pergunta','email',
                'label','E-mail',
                'tipo_pergunta','texto',
                'largura',1,'altura',36,'ordem',21,
                'obrigatorio',FALSE,'depende',FALSE,
                'depende_de',NULL,'valor_depende',NULL,'opcoes',NULL,
                'resposta',NULL,'id_dimensao',NULL,'extra_1',NULL,'extra_2',NULL
            ),

            -- telefone (ordem 9)
            jsonb_build_object(
                'id_pergunta','user_expandido.telefone',
                'pergunta','telefone',
                'label','Telefone',
                'tipo_pergunta','texto',
                'largura',1,'altura',36,'ordem',9,
                'obrigatorio',FALSE,'depende',FALSE,
                'depende_de',NULL,'valor_depende',NULL,'opcoes',NULL,
                'resposta',NULL,'id_dimensao',NULL,'extra_1',NULL,'extra_2',NULL
            ),

            -- imagem_user (ordem 5)
            jsonb_build_object(
                'id_pergunta','user_expandido.imagem_user',
                'pergunta','imagem_user',
                'label','Foto do Usuário',
                'tipo_pergunta','arquivo',
                'largura',2,'altura',36,'ordem',5,
                'obrigatorio',FALSE,'depende',FALSE,
                'depende_de',NULL,'valor_depende',NULL,'opcoes',NULL,
                'resposta',NULL,'id_dimensao',NULL,'extra_1',NULL,'extra_2',NULL
            ),

            -- senha (ordem 22)
            jsonb_build_object(
                'id_pergunta','user_expandido.senha',
                'pergunta','senha',
                'label','Senha',
                'tipo_pergunta','senha',
                'largura',1,'altura',36,'ordem',22,
                'obrigatorio',FALSE,'depende',FALSE,
                'depende_de',NULL,'valor_depende',NULL,'opcoes',NULL,
                'resposta',NULL,'id_dimensao',NULL,'extra_1',NULL,'extra_2',NULL
            )
        );

    ELSE
        -- EDIÇÃO
        v_json_itens := v_json_itens || jsonb_build_array(

            jsonb_build_object(
                'id_pergunta','user_expandido.nome_completo',
                'pergunta','nome_completo',
                'label','Nome Completo',
                'tipo_pergunta','texto',
                'largura',2,'altura',36,'ordem',NULL,
                'obrigatorio',FALSE,'depende',FALSE,
                'depende_de',NULL,'valor_depende',NULL,'opcoes',NULL,
                'resposta',v_user_rec.nome_completo,
                'id_dimensao',v_user_rec.id,'extra_1',v_user_rec.user_id,'extra_2',NULL
            ),

            jsonb_build_object(
                'id_pergunta','user_expandido.email',
                'pergunta','email',
                'label','E-mail',
                'tipo_pergunta','texto',
                'largura',1,'altura',36,'ordem',21,
                'obrigatorio',FALSE,'depende',FALSE,
                'depende_de',NULL,'valor_depende',NULL,'opcoes',NULL,
                'resposta',v_user_rec.email,
                'id_dimensao',v_user_rec.id,'extra_1',v_user_rec.user_id,'extra_2',NULL
            ),

            jsonb_build_object(
                'id_pergunta','user_expandido.telefone',
                'pergunta','telefone',
                'label','Telefone',
                'tipo_pergunta','texto',
                'largura',1,'altura',36,'ordem',9,
                'obrigatorio',FALSE,'depende',FALSE,
                'depende_de',NULL,'valor_depende',NULL,'opcoes',NULL,
                'resposta',v_user_rec.telefone,
                'id_dimensao',v_user_rec.id,'extra_1',v_user_rec.user_id,'extra_2',NULL
            ),

            jsonb_build_object(
                'id_pergunta','user_expandido.imagem_user',
                'pergunta','imagem_user',
                'label','Foto do Usuário',
                'tipo_pergunta','arquivo',
                'largura',2,'altura',36,'ordem',5,
                'obrigatorio',FALSE,'depende',FALSE,
                'depende_de',NULL,'valor_depende',NULL,'opcoes',NULL,
                'resposta',v_user_rec.imagem_user,
                'id_dimensao',v_user_rec.id,'extra_1',v_user_rec.user_id,'extra_2',NULL
            ),

            jsonb_build_object(
                'id_pergunta','user_expandido.senha',
                'pergunta','senha',
                'label','Senha',
                'tipo_pergunta','senha',
                'largura',1,'altura',36,'ordem',22,
                'obrigatorio',FALSE,'depende',FALSE,
                'depende_de',NULL,'valor_depende',NULL,'opcoes',NULL,
                'resposta',NULL,
                'id_dimensao',NULL,'extra_1',NULL,'extra_2',NULL
            )
        );
    END IF;

    --------------------------------------------------------------------------
    -- 4. FAKE: PAPEL
    --------------------------------------------------------------------------
    IF p_id_user IS NULL THEN
        v_json_itens := v_json_itens || jsonb_build_array(
            jsonb_build_object(
                'id_pergunta','user_role_auth.role',
                'pergunta','role',
                'label','Papel',
                'tipo_pergunta','uuid_texto',
                'largura',1,'altura',36,'ordem',NULL,
                'obrigatorio',FALSE,'depende',FALSE,
                'depende_de',NULL,'valor_depende',NULL,'opcoes',NULL,
                'resposta',p_papel::text,
                'id_dimensao',NULL,'extra_1',NULL,'extra_2',NULL
            )
        );
    ELSE
        SELECT *
        INTO v_role_rec
        FROM user_role_auth
        WHERE user_id = v_user_rec.user_id
        LIMIT 1;

        v_json_itens := v_json_itens || jsonb_build_array(
            jsonb_build_object(
                'id_pergunta','user_role_auth.role',
                'pergunta','role',
                'label','Papel',
                'tipo_pergunta','uuid_texto',
                'largura',1,'altura',36,'ordem',NULL,
                'obrigatorio',FALSE,'depende',FALSE,
                'depende_de',NULL,'valor_depende',NULL,'opcoes',NULL,
                'resposta',p_papel::text,
                'id_dimensao',COALESCE(v_role_rec.id,NULL),
                'extra_1',COALESCE(v_role_rec.role_id,NULL),
                'extra_2',COALESCE(v_role_rec.clinica_id,NULL)
            )
        );
    END IF;

    --------------------------------------------------------------------------
    -- 5. FAKE: CLÍNICA (somente cliente)
    --------------------------------------------------------------------------
    IF p_papel = v_papel_cliente THEN

        IF p_id_user IS NOT NULL THEN

            IF p_id_clinica IS NOT NULL THEN
                SELECT c.*, cu.id AS id_dim
                INTO v_clinica_rec
                FROM clinica_user cu
                JOIN clinica c ON c.id = cu.id_clinica
                WHERE cu.id_user = v_user_expandido_id
                  AND c.id = p_id_clinica
                LIMIT 1;
            ELSE
                SELECT c.*, cu.id AS id_dim
                INTO v_clinica_rec
                FROM clinica_user cu
                JOIN clinica c ON c.id = cu.id_clinica
                WHERE cu.id_user = v_user_expandido_id
                LIMIT 1;
            END IF;

            v_json_itens := v_json_itens || jsonb_build_array(

                -- nome clínica (ordem 4)
                jsonb_build_object(
                    'id_pergunta','clinica_user.clinica',
                    'pergunta','clinica',
                    'label','Clínica',
                    'tipo_pergunta','texto',
                    'largura',2,'altura',36,'ordem',4,
                    'obrigatorio',FALSE,'depende',FALSE,
                    'depende_de',NULL,'valor_depende',NULL,'opcoes',NULL,
                    'resposta',COALESCE(v_clinica_rec.nome,NULL),
                    'id_dimensao',COALESCE(v_clinica_rec.id_dim,NULL),
                    'extra_1',COALESCE(v_clinica_rec.id,NULL),'extra_2',NULL
                ),

                -- imagem clínica (ordem 6)
                jsonb_build_object(
                    'id_pergunta','clinica.imagem_clinica',
                    'pergunta','imagem_clinica',
                    'label','Imagem da Clínica',
                    'tipo_pergunta','arquivo',
                    'largura',2,'altura',36,'ordem',6,
                    'obrigatorio',FALSE,'depende',FALSE,
                    'depende_de',NULL,'valor_depende',NULL,'opcoes',NULL,
                    'resposta',COALESCE(v_clinica_rec.imagem_clinica,NULL),
                    'id_dimensao',COALESCE(v_clinica_rec.id,NULL),
                    'extra_1',NULL,'extra_2',NULL
                )
            );

        ELSE
            -- criação
            v_json_itens := v_json_itens || jsonb_build_array(

                jsonb_build_object(
                    'id_pergunta','clinica_user.clinica',
                    'pergunta','clinica',
                    'label','Clínica',
                    'tipo_pergunta','texto',
                    'largura',2,'altura',36,'ordem',4,
                    'obrigatorio',FALSE,'depende',FALSE,
                    'depende_de',NULL,'valor_depende',NULL,'opcoes',NULL,
                    'resposta',NULL,
                    'id_dimensao',NULL,'extra_1',NULL,'extra_2',NULL
                ),

                jsonb_build_object(
                    'id_pergunta','clinica.imagem_clinica',
                    'pergunta','imagem_clinica',
                    'label','Imagem da Clínica',
                    'tipo_pergunta','arquivo',
                    'largura',2,'altura',36,'ordem',6,
                    'obrigatorio',FALSE,'depende',FALSE,
                    'depende_de',NULL,'valor_depende',NULL,'opcoes',NULL,
                    'resposta',NULL,
                    'id_dimensao',NULL,'extra_1',NULL,'extra_2',NULL
                )
            );
        END IF;
    END IF;

    --------------------------------------------------------------------------
    -- 6. PERGUNTAS REAIS DA TABELA
    --------------------------------------------------------------------------
    FOR v_perg IN
        SELECT *
        FROM perguntas_user
        WHERE ativo = TRUE
        AND (papeis IS NULL OR papeis ? p_papel::text)
        ORDER BY ordem NULLS LAST
    LOOP

        SELECT *
        INTO v_resp
        FROM respostas_user
        WHERE id_user = v_user_expandido_id
        AND id_pergunta = v_perg.id
        LIMIT 1;

        v_json_itens := v_json_itens || jsonb_build_array(
            jsonb_build_object(
                'id_pergunta',v_perg.id,
                'pergunta',v_perg.pergunta,
                'label',v_perg.label,
                'tipo_pergunta',v_perg.tipo_pergunta,
                'largura',v_perg.largura,
                'altura',v_perg.altura,
                'ordem',v_perg.ordem,
                'obrigatorio',v_perg.obrigatorio,
                'depende',v_perg.depende,
                'depende_de',v_perg.depende_de,
                'valor_depende',v_perg.valor_depende,
                'opcoes',v_perg.opcoes,
                'resposta',COALESCE(v_resp.resposta,NULL),
                'id_dimensao',COALESCE(v_resp.id,NULL),
                'extra_1',NULL,
                'extra_2',NULL
            )
        );

    END LOOP;

    --------------------------------------------------------------------------
    -- 7. RETORNO FINAL
    --------------------------------------------------------------------------
    RETURN jsonb_build_object(
        'user', v_root,
        'itens', v_json_itens
    );
END;
$$;


ALTER FUNCTION "public"."get_user_dimensoes_v2"("p_papel" "uuid", "p_id_user" "uuid", "p_id_clinica" "uuid") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."get_user_expandido_info"() RETURNS TABLE("origem" "text", "id_user_expandido" "uuid")
    LANGUAGE "sql" SECURITY DEFINER
    AS $$SELECT 'cliente' AS origem, id FROM public.user_expandido_cliente WHERE user_id = auth.uid()
UNION ALL
SELECT 'userclinica' AS origem, id FROM public.user_expandido_userclinica WHERE user_id = auth.uid()
UNION ALL
SELECT 'admin' AS origem, id FROM public.user_expandido_admin WHERE user_id = auth.uid()
UNION ALL
SELECT 'colaborador' AS origem, id FROM public.user_expandido_colaboradores WHERE user_id = auth.uid();$$;


ALTER FUNCTION "public"."get_user_expandido_info"() OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."get_user_ids_by_produto"("p_produto_id" "uuid") RETURNS "uuid"[]
    LANGUAGE "plpgsql"
    AS $$
begin
  return array(
    select user_id
    from produtos_user
    where produto_id = p_produto_id
  );
end;
$$;


ALTER FUNCTION "public"."get_user_ids_by_produto"("p_produto_id" "uuid") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."get_users"("p_busca" "text" DEFAULT NULL::"text", "p_status" boolean DEFAULT NULL::boolean, "p_id_produto" "uuid" DEFAULT NULL::"uuid", "p_id_papel" "uuid" DEFAULT NULL::"uuid", "p_limite_itens_pagina" integer DEFAULT 10, "p_pagina_busca" integer DEFAULT 1) RETURNS "jsonb"
    LANGUAGE "plpgsql" SECURITY DEFINER
    SET "search_path" TO 'public', 'pg_temp'
    AS $$
DECLARE
  v_offset INT := (p_pagina_busca - 1) * p_limite_itens_pagina;
  v_result JSONB;
  v_total INT;
  v_qtd_paginas INT;
BEGIN
  -- Conta total de usuários aplicando filtros
  SELECT COUNT(*) INTO v_total
  FROM user_expandido ue
  LEFT JOIN produtos_user pra
    ON pra.id_user_expandido = ue.id
  LEFT JOIN user_role_auth ra
    ON ra.user_id = ue.user_id
  WHERE
    (p_busca IS NULL OR ue.nome_completo ILIKE '%' || p_busca || '%' OR ue.email ILIKE '%' || p_busca || '%')
    AND (p_status IS NULL OR ue.status = p_status)
    AND (p_id_produto IS NULL OR pra.produto_id = p_id_produto)
    AND (p_id_papel IS NULL OR ra.role_id = p_id_papel);

  v_qtd_paginas := CEIL(v_total::NUMERIC / p_limite_itens_pagina);

  -- Seleciona registros paginados
  SELECT jsonb_agg(to_jsonb(x)) INTO v_result
  FROM (
    SELECT
      ue.id AS id_user_expandido,
      ue.nome_completo AS nome,
      ue.telefone,
      ue.email,
      ue.imagem_user,
      ue.status
    FROM user_expandido ue
    LEFT JOIN produtos_user pra
      ON pra.id_user_expandido = ue.id
    LEFT JOIN user_role_auth ra
      ON ra.user_id = ue.user_id
    WHERE
      (p_busca IS NULL OR ue.nome_completo ILIKE '%' || p_busca || '%' OR ue.email ILIKE '%' || p_busca || '%')
      AND (p_status IS NULL OR ue.status = p_status)
      AND (p_id_produto IS NULL OR pra.produto_id = p_id_produto)
      AND (p_id_papel IS NULL OR ra.role_id = p_id_papel)
    ORDER BY ue.nome_completo
    OFFSET v_offset
    LIMIT p_limite_itens_pagina
  ) x;

  -- Retorna estrutura padronizada
  RETURN jsonb_build_object(
    'qtd_paginas', COALESCE(v_qtd_paginas, 1),
    'qtd_itens_total', COALESCE(v_total, 0),
    'dados', COALESCE(v_result, '[]'::jsonb)
  );
END;
$$;


ALTER FUNCTION "public"."get_users"("p_busca" "text", "p_status" boolean, "p_id_produto" "uuid", "p_id_papel" "uuid", "p_limite_itens_pagina" integer, "p_pagina_busca" integer) OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."get_users"("p_busca" "text" DEFAULT NULL::"text", "p_status" boolean DEFAULT NULL::boolean, "p_id_produto" "uuid" DEFAULT NULL::"uuid", "p_id_papel" "uuid" DEFAULT NULL::"uuid", "p_id_clinica" "uuid" DEFAULT NULL::"uuid", "p_limite_itens_pagina" integer DEFAULT 10, "p_pagina_busca" integer DEFAULT 1) RETURNS "jsonb"
    LANGUAGE "plpgsql" SECURITY DEFINER
    SET "search_path" TO 'public', 'pg_temp'
    AS $$
DECLARE
  v_offset INT := (p_pagina_busca - 1) * p_limite_itens_pagina;
  v_result JSONB;
  v_total INT;
  v_qtd_paginas INT;
BEGIN
  -- Conta total de usuários aplicando filtros
  SELECT COUNT(DISTINCT ue.id) INTO v_total
  FROM user_expandido ue
  LEFT JOIN produtos_user pra ON pra.id_user_expandido = ue.id
  LEFT JOIN user_role_auth ra ON ra.user_id = ue.user_id
  LEFT JOIN clinica_user cu ON cu.id_user = ue.id
  WHERE
    (p_busca IS NULL OR ue.nome_completo ILIKE '%' || p_busca || '%' OR ue.email ILIKE '%' || p_busca || '%')
    AND (p_status IS NULL OR ue.status = p_status)
    AND (p_id_produto IS NULL OR pra.produto_id = p_id_produto)
    AND (p_id_papel IS NULL OR ra.role_id = p_id_papel)
    AND (
      p_id_clinica IS NULL
      OR cu.id_clinica = p_id_clinica
      OR ra.clinica_id = p_id_clinica
    );

  v_qtd_paginas := CEIL(v_total::NUMERIC / p_limite_itens_pagina);

  -- Seleciona registros paginados
  SELECT jsonb_agg(to_jsonb(x)) INTO v_result
  FROM (
    SELECT DISTINCT
      ue.id AS id_user_expandido,
      ue.nome_completo AS nome,
      ue.telefone,
      ue.email,
      ue.imagem_user,
      ue.status
    FROM user_expandido ue
    LEFT JOIN produtos_user pra ON pra.id_user_expandido = ue.id
    LEFT JOIN user_role_auth ra ON ra.user_id = ue.user_id
    LEFT JOIN clinica_user cu ON cu.id_user = ue.id
    WHERE
      (p_busca IS NULL OR ue.nome_completo ILIKE '%' || p_busca || '%' OR ue.email ILIKE '%' || p_busca || '%')
      AND (p_status IS NULL OR ue.status = p_status)
      AND (p_id_produto IS NULL OR pra.produto_id = p_id_produto)
      AND (p_id_papel IS NULL OR ra.role_id = p_id_papel)
      AND (
        p_id_clinica IS NULL
        OR cu.id_clinica = p_id_clinica
        OR ra.clinica_id = p_id_clinica
      )
    ORDER BY ue.nome_completo
    OFFSET v_offset
    LIMIT p_limite_itens_pagina
  ) x;

  -- Retorna estrutura padronizada
  RETURN jsonb_build_object(
    'qtd_paginas', COALESCE(v_qtd_paginas, 1),
    'qtd_itens_total', COALESCE(v_total, 0),
    'dados', COALESCE(v_result, '[]'::jsonb)
  );
END;
$$;


ALTER FUNCTION "public"."get_users"("p_busca" "text", "p_status" boolean, "p_id_produto" "uuid", "p_id_papel" "uuid", "p_id_clinica" "uuid", "p_limite_itens_pagina" integer, "p_pagina_busca" integer) OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."get_users_por_papel"("p_id_papel" "uuid", "p_id_user_chamada" "uuid", "p_id_papel_user_chamada" "uuid") RETURNS TABLE("id_user" "uuid", "nome_completo" "text", "email" "text", "telefone" "text", "imagem_user" "text", "id_clinica" "uuid", "nome_clinica" "text", "papel" "text")
    LANGUAGE "plpgsql"
    AS $$
begin
  return query
  select
    ue.id as id_user,
    ue.nome_completo,
    ue.email,
    ue.telefone,
    ue.imagem_user,
    c.id as id_clinica,
    c.nome as nome_clinica,
    ra.nome_role::text as papel
  from public.user_expandido ue
  join public.user_role_auth ura on ura.user_id = ue.user_id
  join public.role_auth ra on ra.id = ura.role_id
  left join public.clinica_user cu on cu.id_user = ue.id  -- 👈 LEFT JOIN pra não excluir quem não tem clínica
  left join public.clinica c on c.id = cu.id_clinica
  where 
    ura.role_id = p_id_papel
    and (
      -- 👇 Se for admin, ignora filtro de clínica
      p_id_papel_user_chamada = (select id from public.role_auth where nome_role = 'admin')
      or c.id in (
        select cu2.id_clinica
        from public.clinica_user cu2
        where cu2.id_user = (
          select id
          from public.user_expandido
          where user_id = p_id_user_chamada
        )
      )
    )
    and ue.status = true
  order by ue.nome_completo;
end;
$$;


ALTER FUNCTION "public"."get_users_por_papel"("p_id_papel" "uuid", "p_id_user_chamada" "uuid", "p_id_papel_user_chamada" "uuid") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."obter_usuario_expandido_completo"() RETURNS TABLE("origem" "text", "dados" "jsonb")
    LANGUAGE "plpgsql" SECURITY DEFINER
    AS $$
BEGIN
  RETURN QUERY
  SELECT 'cliente', to_jsonb(c)
  FROM public.user_expandido_cliente c
  WHERE user_id = auth.uid()
  UNION ALL
  SELECT 'userclinica', to_jsonb(u)
  FROM public.user_expandido_userclinica u
  WHERE user_id = auth.uid()
  UNION ALL
  SELECT 'admin', to_jsonb(a)
  FROM public.user_expandido_admin a
  WHERE user_id = auth.uid()
  UNION ALL
  SELECT 'colaborador', to_jsonb(col)
  FROM public.user_expandido_colaboradores col
  WHERE user_id = auth.uid();
END;
$$;


ALTER FUNCTION "public"."obter_usuario_expandido_completo"() OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."qtd_clientes_por_mes"() RETURNS "json"
    LANGUAGE "plpgsql" SECURITY DEFINER
    SET "search_path" TO 'public', 'pg_temp'
    AS $$BEGIN
  RETURN (
    WITH dados_filtrados AS (
      SELECT created_at
      FROM user_expandido_cliente
      WHERE created_at >= date_trunc('month', CURRENT_DATE) - INTERVAL '5 months'
    ),
    dados_agrupados AS (
      SELECT
        date_trunc('month', created_at) AS data,
        COUNT(*) AS qtd_mes
      FROM dados_filtrados
      GROUP BY 1
    )
    SELECT json_build_object(
      'dados', json_agg(
        json_build_object(
          'data', data,
          'mes', CASE extract(MONTH FROM data)
            WHEN 1 THEN 'Janeiro'
            WHEN 2 THEN 'Fevereiro'
            WHEN 3 THEN 'Março'
            WHEN 4 THEN 'Abril'
            WHEN 5 THEN 'Maio'
            WHEN 6 THEN 'Junho'
            WHEN 7 THEN 'Julho'
            WHEN 8 THEN 'Agosto'
            WHEN 9 THEN 'Setembro'
            WHEN 10 THEN 'Outubro'
            WHEN 11 THEN 'Novembro'
            WHEN 12 THEN 'Dezembro'
          END,
          'qtd_mes', qtd_mes
        )
        ORDER BY data
      ),
      'total', (SELECT COUNT(*) FROM user_expandido_cliente)
    )
    FROM dados_agrupados
  );
END;$$;


ALTER FUNCTION "public"."qtd_clientes_por_mes"() OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."trg_clinica_user_set_updated_at"() RETURNS "trigger"
    LANGUAGE "plpgsql" SECURITY DEFINER
    SET "search_path" TO 'public', 'pg_temp'
    AS $$
      BEGIN
        NEW.updated_at := now();
        RETURN NEW;
      END;
      $$;


ALTER FUNCTION "public"."trg_clinica_user_set_updated_at"() OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."trg_perguntas_user_set_updated_at"() RETURNS "trigger"
    LANGUAGE "plpgsql" SECURITY DEFINER
    SET "search_path" TO 'public', 'pg_temp'
    AS $$
      BEGIN
        NEW.updated_at := now();
        RETURN NEW;
      END;
      $$;


ALTER FUNCTION "public"."trg_perguntas_user_set_updated_at"() OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."trg_respostas_user_set_updated_at"() RETURNS "trigger"
    LANGUAGE "plpgsql" SECURITY DEFINER
    SET "search_path" TO 'public', 'pg_temp'
    AS $$
      BEGIN
        NEW.updated_at := now();
        RETURN NEW;
      END;
      $$;


ALTER FUNCTION "public"."trg_respostas_user_set_updated_at"() OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."trg_set_updated_at"() RETURNS "trigger"
    LANGUAGE "plpgsql" SECURITY DEFINER
    SET "search_path" TO 'public', 'pg_temp'
    AS $$
BEGIN
  NEW.modificado_em := now();
  RETURN NEW;
END;
$$;


ALTER FUNCTION "public"."trg_set_updated_at"() OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."trg_user_expandido_set_updated_at"() RETURNS "trigger"
    LANGUAGE "plpgsql" SECURITY DEFINER
    SET "search_path" TO 'public', 'pg_temp'
    AS $$
      BEGIN
        NEW.updated_at := now();
        RETURN NEW;
      END;
      $$;


ALTER FUNCTION "public"."trg_user_expandido_set_updated_at"() OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."upsert_questionario_completo"("p_payload" "jsonb") RETURNS "jsonb"
    LANGUAGE "plpgsql" SECURITY DEFINER
    SET "search_path" TO 'public', 'pg_temp'
    AS $$
declare
  v_action text;
  v_dados jsonb;
  v_info jsonb;
  v_id_questionario uuid;
  v_result jsonb := '{}'::jsonb;
begin
  -- Extrai dados principais
  v_action := p_payload ->> 'p_action';
  v_dados := p_payload -> 'p_dados';
  v_info := v_dados -> 'informacoes_questionario';

  if v_action = 'criar' then
    insert into public.questionario_modelo (
      nome, global, instrucoes, observacoes, respostas_globais, status, deletado, criado_em
    )
    values (
      v_info ->> 'nome',
      coalesce((v_info ->> 'global')::boolean, false),
      v_info ->> 'instrucoes',
      v_info ->> 'observacoes',
      coalesce((v_info ->> 'respostas_globais')::boolean, false),
      true,
      false,
      now()
    )
    returning id into v_id_questionario;

  elsif v_action = 'editar' then
    v_id_questionario := (v_info ->> 'id')::uuid;

    update public.questionario_modelo
    set
      nome = v_info ->> 'nome',
      global = coalesce((v_info ->> 'global')::boolean, false),
      instrucoes = v_info ->> 'instrucoes',
      observacoes = v_info ->> 'observacoes',
      respostas_globais = coalesce((v_info ->> 'respostas_globais')::boolean, false),
      modificado_em = now()
    where id = v_id_questionario;
  end if;

  -- Remove dependências antigas
  delete from public.questionario_gabarito where id_questionario = v_id_questionario;
  delete from public.questionario_perguntas where id_questionario = v_id_questionario;
  delete from public.questionario_perguntas_grupo where id_questionario = v_id_questionario;
  delete from public.questionario_respostas where id_questionario = v_id_questionario;

  -- Insere grupos
  insert into public.questionario_perguntas_grupo (id_questionario, nome, criado_em)
  select v_id_questionario, item ->> 'nome', now()
  from jsonb_array_elements(v_dados -> 'questionario_grupo_perguntas') as item;

  -- Insere perguntas
  insert into public.questionario_perguntas (id_questionario, id_grupo, ordem, pergunta, criado_em)
  select
    v_id_questionario,
    null, -- associações futuras se precisar
    (item ->> 'ordem')::int,
    item ->> 'pergunta',
    now()
  from jsonb_array_elements(v_dados -> 'questionario_perguntas') as item;

  -- Insere respostas globais
  insert into public.questionario_respostas (id_questionario, ordem, resposta, pontuacao, criado_em)
  select
    v_id_questionario,
    (item ->> 'ordem')::int,
    item ->> 'resposta',
    (item ->> 'pontuacao')::numeric,
    now()
  from jsonb_array_elements(v_dados -> 'questionario_respostas_globais') as item;

  -- Insere gabarito
  insert into public.questionario_gabarito (id_questionario, diagnostico, observacoes, pontuacao_min, pontuacao_max, criado_em)
  select
    v_id_questionario,
    item ->> 'diagnostico',
    item ->> 'observacoes',
    (item ->> 'pontuacao_min')::numeric,
    (item ->> 'pontuacao_max')::numeric,
    now()
  from jsonb_array_elements(v_dados -> 'questionario_gabarito') as item;

  -- Retorno final
  v_result := jsonb_build_object(
    'status', 'sucesso',
    'acao', v_action,
    'id_questionario', v_id_questionario
  );

  return v_result;
end;
$$;


ALTER FUNCTION "public"."upsert_questionario_completo"("p_payload" "jsonb") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."upsert_user_dimensoes"("p_dados" "jsonb") RETURNS "jsonb"
    LANGUAGE "plpgsql" SECURITY DEFINER
    SET "search_path" TO 'public', 'pg_temp'
    AS $$
DECLARE
  v_dados     JSONB := p_dados->'dados';
  v_papeis    JSONB := p_dados->'papeis';
  v_clinicas  JSONB := p_dados->'clinicas';
  v_produtos  JSONB := p_dados->'produtos';
  v_respostas JSONB := v_dados->'respostas';

  v_id_user_expandido UUID;
  v_id_user_auth UUID;
  v_item JSONB;
  v_key  TEXT;
  v_clinica JSONB;
  v_id_clinica UUID;
BEGIN
  -- 1️⃣ INSERT ou UPDATE em user_expandido
  IF (v_dados->>'id_user_expandido') IS NULL THEN
    v_id_user_expandido := gen_random_uuid();

    -- tenta pegar user_id enviado
    IF v_dados ? 'user_id' THEN
      v_id_user_auth := (v_dados->>'user_id')::uuid;
    END IF;

    -- fallback: busca pelo e-mail em auth.users se user_id ainda for nulo
    IF v_id_user_auth IS NULL THEN
      SELECT id INTO v_id_user_auth
      FROM auth.users
      WHERE lower(email) = lower(v_dados->>'email')
      LIMIT 1;
    END IF;

    INSERT INTO user_expandido (id, user_id, nome_completo, email, telefone, imagem_user, status)
    VALUES (
      v_id_user_expandido,
      v_id_user_auth,
      CASE WHEN v_dados->>'nome_completo' = 'apagar_campo' THEN NULL ELSE v_dados->>'nome_completo' END,
      CASE WHEN v_dados->>'email' = 'apagar_campo' THEN NULL ELSE v_dados->>'email' END,
      CASE WHEN v_dados->>'telefone' = 'apagar_campo' THEN NULL ELSE v_dados->>'telefone' END,
      CASE WHEN v_dados->>'imagem_user' IN ('', 'apagar_campo') THEN NULL ELSE v_dados->>'imagem_user' END,
      COALESCE((v_dados->>'status')::boolean, true)
    );
  ELSE
    v_id_user_expandido := (v_dados->>'id_user_expandido')::uuid;
    UPDATE user_expandido
    SET
      nome_completo = CASE 
        WHEN v_dados ? 'nome_completo' AND v_dados->>'nome_completo' = 'apagar_campo' THEN NULL
        WHEN v_dados ? 'nome_completo' THEN v_dados->>'nome_completo'
        ELSE nome_completo END,
      email = CASE 
        WHEN v_dados ? 'email' AND v_dados->>'email' = 'apagar_campo' THEN NULL
        WHEN v_dados ? 'email' THEN v_dados->>'email'
        ELSE email END,
      telefone = CASE 
        WHEN v_dados ? 'telefone' AND v_dados->>'telefone' = 'apagar_campo' THEN NULL
        WHEN v_dados ? 'telefone' THEN NULLIF(v_dados->>'telefone','')
        ELSE telefone END,
      imagem_user = CASE 
        WHEN v_dados ? 'imagem_user' AND v_dados->>'imagem_user' IN ('', 'apagar_campo') THEN NULL
        WHEN v_dados ? 'imagem_user' THEN v_dados->>'imagem_user'
        ELSE imagem_user END,
      status = COALESCE((v_dados->>'status')::boolean, status),
      updated_at = now()
    WHERE id = v_id_user_expandido;
  END IF;

  -- 🔗 pega o user_id para usar nas tabelas seguintes
  SELECT user_id INTO v_id_user_auth
  FROM user_expandido
  WHERE id = v_id_user_expandido;

  -- 🏥 Clínicas
  IF v_clinicas IS NOT NULL AND jsonb_typeof(v_clinicas) = 'array' AND jsonb_array_length(v_clinicas) > 0 THEN
    FOR v_clinica IN SELECT * FROM jsonb_array_elements(v_clinicas)
    LOOP
      IF (v_clinica->>'clinica_id') IS NULL THEN
        v_id_clinica := gen_random_uuid();
        INSERT INTO clinica (id, user_id, nome, imagem_clinica, produto_id)
        VALUES (
          v_id_clinica,
          v_id_user_auth,
          CASE WHEN v_clinica->>'clinica_nome' = 'apagar_campo' THEN NULL ELSE v_clinica->>'clinica_nome' END,
          CASE WHEN v_clinica->>'imagem_clinica' IN ('', 'apagar_campo') THEN NULL ELSE v_clinica->>'imagem_clinica' END,
          (v_clinica->>'produto_id')::uuid
        );
      ELSE
        v_id_clinica := (v_clinica->>'clinica_id')::uuid;
        UPDATE clinica
        SET
          nome = CASE 
            WHEN v_clinica ? 'clinica_nome' AND v_clinica->>'clinica_nome' = 'apagar_campo' THEN NULL
            WHEN v_clinica ? 'clinica_nome' THEN v_clinica->>'clinica_nome'
            ELSE nome END,
          imagem_clinica = CASE 
            WHEN v_clinica ? 'imagem_clinica' AND v_clinica->>'imagem_clinica' IN ('', 'apagar_campo') THEN NULL
            WHEN v_clinica ? 'imagem_clinica' THEN v_clinica->>'imagem_clinica'
            ELSE imagem_clinica END,
          updated_at = now()
        WHERE id = v_id_clinica;
      END IF;

      INSERT INTO clinica_user (id_user, id_clinica)
      VALUES (v_id_user_expandido, v_id_clinica)
      ON CONFLICT (id_user, id_clinica) DO NOTHING;
    END LOOP;
  END IF;

  -- 👥 Papeis
  IF v_papeis IS NOT NULL AND jsonb_typeof(v_papeis) = 'array' AND jsonb_array_length(v_papeis) > 0 THEN
    DELETE FROM user_role_auth WHERE user_id = v_id_user_auth;
    INSERT INTO user_role_auth (user_id, role_id)
    SELECT v_id_user_auth, (x->>'role_id')::uuid
    FROM jsonb_array_elements(v_papeis) AS t(x);
  END IF;

  -- 💼 Produtos
  IF v_produtos IS NOT NULL AND jsonb_typeof(v_produtos) = 'array' AND jsonb_array_length(v_produtos) > 0 THEN
    DELETE FROM produtos_user WHERE id_user_expandido = v_id_user_expandido;
    INSERT INTO produtos_user (id_user_expandido, produto_id)
    SELECT v_id_user_expandido, (x->>'produto_id')::uuid
    FROM jsonb_array_elements(v_produtos) AS t(x);
  END IF;

  -- 🧠 Respostas
  IF v_respostas IS NOT NULL AND jsonb_typeof(v_respostas) = 'object' THEN
    FOR v_key, v_item IN SELECT key, value FROM jsonb_each(v_respostas)
    LOOP
      IF v_item->>'resposta' = 'apagar_campo' THEN
        DELETE FROM respostas_user
        WHERE id_user = v_id_user_expandido
          AND id_pergunta = (v_item->>'id_pergunta')::uuid;
      ELSIF TRIM(COALESCE(v_item->>'resposta','')) <> '' THEN
        INSERT INTO respostas_user (id_user, id_pergunta, resposta)
        VALUES (
          v_id_user_expandido,
          (v_item->>'id_pergunta')::uuid,
          v_item->>'resposta'
        )
        ON CONFLICT (id_user, id_pergunta)
        DO UPDATE SET
          resposta   = EXCLUDED.resposta,
          updated_at = now();
      END IF;
    END LOOP;
  END IF;

  RETURN jsonb_build_object(
    'id_user_expandido', v_id_user_expandido,
    'status', 'sucesso'
  );
END;
$$;


ALTER FUNCTION "public"."upsert_user_dimensoes"("p_dados" "jsonb") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."upsert_user_dimensoes_v2"("p_payload" "jsonb") RETURNS "jsonb"
    LANGUAGE "plpgsql" SECURITY DEFINER
    SET "search_path" TO 'public', 'pg_temp'
    AS $$
DECLARE
    -- Bloco user
    v_user_json          jsonb;
    v_user_id            uuid;
    v_user_expandido_id  uuid;
    v_produto_id         uuid;
    v_papel_id           uuid;

    -- Campos de user_expandido vindos dos itens
    v_nome_completo      text;
    v_email              text;
    v_telefone           text;
    v_imagem_user        text;
    v_senha              text; -- se você quiser usar depois

    -- Clínica
    v_clinica_nome       text;
    v_clinica_imagem     text;
    v_clinica_id         uuid;
    v_clinica_user_id    uuid;

    -- Papel / role
    v_role_auth_id       uuid;

    -- Loop de itens
    v_item               jsonb;
    v_id_pergunta        text;
    v_resposta           text;

    -- Perguntas dinâmicas (respostas_user)
    v_pergunta_uuid      uuid;
    v_resposta_id        uuid;

    -- Constante do papel cliente (se quiser usar igual ao GET)
    v_papel_cliente CONSTANT uuid := '67ed3bd7-72ef-4d92-b43b-78250874be1e';
BEGIN
    --------------------------------------------------------------------------
    -- 0. Validação básica
    --------------------------------------------------------------------------
    IF p_payload IS NULL THEN
        RAISE EXCEPTION 'Payload não pode ser nulo';
    END IF;

    v_user_json := p_payload -> 'user';
    IF v_user_json IS NULL THEN
        RAISE EXCEPTION 'Campo "user" é obrigatório no payload';
    END IF;

    --------------------------------------------------------------------------
    -- 1. Extrai metadados do bloco "user"
    --------------------------------------------------------------------------
    v_user_id           := NULLIF(v_user_json->>'user_id', '')::uuid;
    v_user_expandido_id := NULLIF(v_user_json->>'id_user_expandido', '')::uuid;
    v_produto_id        := NULLIF(v_user_json->>'produto_id', '')::uuid;
    v_papel_id          := NULLIF(v_user_json->>'papel', '')::uuid;

    IF v_user_id IS NULL THEN
        RAISE EXCEPTION 'user.user_id é obrigatório (auth.users deve ser criado via Edge antes)';
    END IF;

    --------------------------------------------------------------------------
    -- 2. Primeiro PASS: varrer itens e extrair campos de user_expandido e clínica
    --    (sem gravar nada ainda)
    --------------------------------------------------------------------------
    FOR v_item IN
        SELECT jsonb_array_elements(p_payload->'itens')
    LOOP
        v_id_pergunta := v_item->>'id_pergunta';
        v_resposta    := v_item->>'resposta';

        IF v_id_pergunta IS NULL THEN
            CONTINUE;
        END IF;

        -- Campos de user_expandido
        IF v_id_pergunta = 'user_expandido.nome_completo' THEN
            v_nome_completo := v_resposta;

        ELSIF v_id_pergunta = 'user_expandido.email' THEN
            v_email := v_resposta;

        ELSIF v_id_pergunta = 'user_expandido.telefone' THEN
            v_telefone := v_resposta;

        ELSIF v_id_pergunta = 'user_expandido.imagem_user' THEN
            v_imagem_user := v_resposta;

        ELSIF v_id_pergunta = 'user_expandido.senha' THEN
            v_senha := v_resposta;

        -- Clínica
        ELSIF v_id_pergunta = 'clinica_user.clinica' THEN
            v_clinica_nome := v_resposta;

        ELSIF v_id_pergunta = 'clinica.imagem_clinica' THEN
            v_clinica_imagem := v_resposta;
        END IF;
    END LOOP;

    --------------------------------------------------------------------------
    -- 3. UPSERT em user_expandido (primeiro de tudo)
    --------------------------------------------------------------------------
    IF v_user_expandido_id IS NULL THEN
        -- Criação
        INSERT INTO user_expandido (user_id, nome_completo, email, telefone, imagem_user)
        VALUES (
            v_user_id,
            v_nome_completo,
            v_email,
            v_telefone,
            v_imagem_user
        )
        RETURNING id INTO v_user_expandido_id;
    ELSE
        -- Edição: só atualiza o que veio preenchido
        UPDATE user_expandido
        SET
            nome_completo = COALESCE(v_nome_completo, nome_completo),
            email         = COALESCE(v_email, email),
            telefone      = COALESCE(v_telefone, telefone),
            imagem_user   = COALESCE(v_imagem_user, imagem_user)
        WHERE id = v_user_expandido_id;
    END IF;

    --------------------------------------------------------------------------
    -- 4. UPSERT em produtos_user (licença do produto)
    --------------------------------------------------------------------------
    IF v_produto_id IS NOT NULL THEN
        PERFORM 1
        FROM produtos_user
        WHERE user_id = v_user_id
          AND produto_id = v_produto_id;

        IF NOT FOUND THEN
            INSERT INTO produtos_user (user_id, produto_id, status, id_user_expandido)
            VALUES (v_user_id, v_produto_id, TRUE, v_user_expandido_id);
        ELSE
            UPDATE produtos_user
            SET
                status           = TRUE,
                id_user_expandido = v_user_expandido_id
            WHERE user_id = v_user_id
              AND produto_id = v_produto_id;
        END IF;
    END IF;

    --------------------------------------------------------------------------
    -- 5. UPSERT em user_role_auth (papel)
    --    (clinica_id será atualizado depois se criarmos clínica)
    --------------------------------------------------------------------------
    IF v_papel_id IS NOT NULL THEN
        SELECT id
        INTO v_role_auth_id
        FROM user_role_auth
        WHERE user_id = v_user_id
        LIMIT 1;

        IF NOT FOUND THEN
            INSERT INTO user_role_auth (user_id, role_id, clinica_id)
            VALUES (v_user_id, v_papel_id, NULL)
            RETURNING id INTO v_role_auth_id;
        ELSE
            UPDATE user_role_auth
            SET role_id = v_papel_id
            WHERE id = v_role_auth_id;
        END IF;
    END IF;

    --------------------------------------------------------------------------
    -- 6. UPSERT em clínica + clinica_user (se houver dados no formulário)
    --------------------------------------------------------------------------
    IF v_clinica_nome IS NOT NULL OR v_clinica_imagem IS NOT NULL THEN

        -- Tenta achar vínculo existente clínica <-> usuário
        SELECT
            cu.id AS clinica_user_id,
            c.id  AS clinica_id
        INTO
            v_clinica_user_id,
            v_clinica_id
        FROM clinica_user cu
        JOIN clinica c ON c.id = cu.id_clinica
        WHERE cu.id_user = v_user_expandido_id
        LIMIT 1;

        IF NOT FOUND THEN
            -- Cria nova clínica
            INSERT INTO clinica (user_id, nome, imagem_clinica)
            VALUES (
                v_user_id,
                COALESCE(v_clinica_nome, 'Clínica sem nome'),
                v_clinica_imagem
            )
            RETURNING id INTO v_clinica_id;

            -- Vincula user_expandido à clínica
            INSERT INTO clinica_user (id_user, id_clinica)
            VALUES (v_user_expandido_id, v_clinica_id)
            RETURNING id INTO v_clinica_user_id;
        ELSE
            -- Atualiza dados da clínica existente
            UPDATE clinica
            SET
                nome          = COALESCE(v_clinica_nome, nome),
                imagem_clinica = COALESCE(v_clinica_imagem, imagem_clinica)
            WHERE id = v_clinica_id;
        END IF;

        -- Se tiver papel (especialmente cliente), amarra clinica no user_role_auth
        IF v_papel_id IS NOT NULL AND v_clinica_id IS NOT NULL THEN
            UPDATE user_role_auth
            SET clinica_id = v_clinica_id
            WHERE user_id = v_user_id;
        END IF;
    END IF;

    --------------------------------------------------------------------------
    -- 7. Segundo PASS: perguntas dinâmicas (respostas_user)
    --    Tudo que não for user_expandido.* nem clinica_* vira resposta_user
    --------------------------------------------------------------------------
    FOR v_item IN
        SELECT jsonb_array_elements(p_payload->'itens')
    LOOP
        v_id_pergunta := v_item->>'id_pergunta';
        v_resposta    := v_item->>'resposta';

        IF v_id_pergunta IS NULL THEN
            CONTINUE;
        END IF;

        -- Pula campos especiais que já tratamos
        IF v_id_pergunta LIKE 'user_expandido.%'
           OR v_id_pergunta LIKE 'clinica_user.%'
           OR v_id_pergunta LIKE 'clinica.%'
        THEN
            CONTINUE;
        END IF;

        -- Sem resposta = não insere / não atualiza / não apaga
        IF v_resposta IS NULL OR btrim(v_resposta) = '' THEN
            CONTINUE;
        END IF;

        -- Tenta interpretar id_pergunta como UUID (perguntas_user.id)
        BEGIN
            v_pergunta_uuid := v_id_pergunta::uuid;
        EXCEPTION WHEN others THEN
            -- Se não for UUID, ignora (pode ser algum campo especial futuro)
            CONTINUE;
        END;

        -- Procura resposta existente (sem delete implícito)
        SELECT id
        INTO v_resposta_id
        FROM respostas_user
        WHERE id_user = v_user_expandido_id
          AND id_pergunta = v_pergunta_uuid
        LIMIT 1;

        IF NOT FOUND THEN
            INSERT INTO respostas_user (
                id_user,
                id_pergunta,
                resposta,
                id_clinica
            )
            VALUES (
                v_user_expandido_id,
                v_pergunta_uuid,
                v_resposta,
                v_clinica_id
            );
        ELSE
            UPDATE respostas_user
            SET
                resposta   = v_resposta,
                id_clinica = COALESCE(v_clinica_id, id_clinica),
                updated_at = now()
            WHERE id = v_resposta_id;
        END IF;
    END LOOP;

    --------------------------------------------------------------------------
    -- 8. Retorno
    --------------------------------------------------------------------------
    RETURN jsonb_build_object(
        'status', 'ok',
        'user_id', v_user_id,
        'id_user_expandido', v_user_expandido_id,
        'clinica_id', v_clinica_id,
        'produto_id', v_produto_id,
        'papel', v_papel_id
    );
END;
$$;


ALTER FUNCTION "public"."upsert_user_dimensoes_v2"("p_payload" "jsonb") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."upsert_usuario_completo"("p_user" "jsonb", "p_respostas" "jsonb" DEFAULT '[]'::"jsonb", "p_clinica" "jsonb" DEFAULT '{}'::"jsonb", "p_produtos" "jsonb" DEFAULT '[]'::"jsonb") RETURNS "jsonb"
    LANGUAGE "plpgsql"
    AS $$
declare
  v_auth_id uuid;
  v_user_expandido_id uuid;
  v_role_id uuid;
  v_clinica_id uuid;
  v_result jsonb;
begin
  -- 1. Auth user
  v_auth_id := (p_user->>'user_id')::uuid;
  if v_auth_id is null then
    raise exception 'Auth user_id não informado.';
  end if;

  -- 2. Papel
  v_role_id := (p_user->>'role_id')::uuid;
  if v_role_id is null then
    raise exception 'role_id é obrigatório';
  end if;

  -- 3. Verifica se é edição ou criação
  v_user_expandido_id := (p_user->>'id_user_expandido')::uuid;

  if v_user_expandido_id is null then
    -- Inserção
    insert into public.user_expandido (
      user_id, nome_completo, email, telefone,
      role_id, clinica_id, imagem_user, status, produtos
    )
    values (
      v_auth_id,
      p_user->>'nome_completo',
      p_user->>'email',
      p_user->>'telefone',
      v_role_id,
      null, -- setado abaixo se clinica
      p_user->>'imagem_user',
      coalesce((p_user->>'status')::boolean, true),
      coalesce(p_user->'produtos', '[]'::jsonb)
    )
    returning id into v_user_expandido_id;
  else
    -- Update
    update public.user_expandido
    set
      nome_completo = coalesce(p_user->>'nome_completo', nome_completo),
      email = coalesce(p_user->>'email', email),
      telefone = coalesce(p_user->>'telefone', telefone),
      role_id = coalesce(v_role_id, role_id),
      imagem_user = coalesce(p_user->>'imagem_user', imagem_user),
      status = coalesce((p_user->>'status')::boolean, status),
      produtos = coalesce(p_user->'produtos', produtos),
      ultima_interacao = now()
    where id = v_user_expandido_id;
  end if;

  -- 4. Garante papel em user_role_auth (upsert)
  insert into public.user_role_auth (user_id, role_id, clinica_id)
  values (v_auth_id, v_role_id, (p_user->>'clinica_id')::uuid)
  on conflict (user_id, role_id, clinica_id) do nothing;

  -- 5. Cria clínica se necessário
  if jsonb_typeof(p_clinica) = 'object' and p_clinica <> '{}'::jsonb then
    insert into public.clinica (user_id, nome, imagem_clinica, produto_id)
    values (
      v_auth_id,
      p_clinica->>'nome',
      p_clinica->>'imagem_clinica',
      (p_clinica->>'produto_id')::uuid
    )
    returning id into v_clinica_id;

    update public.user_expandido set clinica_id = v_clinica_id
    where id = v_user_expandido_id;
  end if;

  -- 6. Relaciona produtos (limpa e recria)
  delete from public.produtos_user where user_id = v_auth_id;
  insert into public.produtos_user (user_id, produto_id)
  select v_auth_id, (value->>'id')::uuid
  from jsonb_array_elements(p_produtos) as value;

  -- 7. Upsert respostas
  if jsonb_typeof(p_respostas) = 'array' then
    insert into public.respostas_user (user_expandido_id, pergunta_id, clinica_id, resposta)
    select
      v_user_expandido_id,
      (value->>'pergunta_id')::uuid,
      (value->>'clinica_id')::uuid,
      value->>'resposta'
    from jsonb_array_elements(p_respostas) as value
    on conflict (user_expandido_id, pergunta_id)
    do update set
      resposta = excluded.resposta,
      atualizado_em = now();
  end if;

  -- 8. Retorna JSON consolidado
  v_result := public.get_user_detalhes_completo(v_user_expandido_id);

  return v_result;
end;
$$;


ALTER FUNCTION "public"."upsert_usuario_completo"("p_user" "jsonb", "p_respostas" "jsonb", "p_clinica" "jsonb", "p_produtos" "jsonb") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."verifica_limite_clinica"("p_id_cliente" "uuid", "p_id_produto" "uuid", "p_id_modulo" "uuid") RETURNS "jsonb"
    LANGUAGE "plpgsql"
    AS $$
declare
  v_plano_id uuid;
  v_plano_modulo_id uuid;
  v_tem_limite boolean;
  v_limite int;
  v_clinica_id uuid;
  v_total_utilizado int;
  v_pode_criar boolean;
begin
  -- 1. Pega o plano do cliente
  select plano_id, clinica_id
  into v_plano_id, v_clinica_id
  from user_expandido_cliente
  where id = p_id_cliente;

  if v_plano_id is null or v_clinica_id is null then
    return jsonb_build_object('erro', 'Cliente não encontrado ou sem clínica/plano associado');
  end if;

  -- 2. Busca o plano_módulo correspondente ao módulo e plano
  select pm.id, pm.tem_limite
  into v_plano_modulo_id, v_tem_limite
  from planos_modulos pm
  join modulos m on m.id = pm.modulo_id
  where pm.plano_id = v_plano_id
    and pm.modulo_id = p_id_modulo
    and m.produto_id = p_id_produto
    and pm.disponivel = true;

  if v_plano_modulo_id is null then
    return jsonb_build_object('erro', 'Módulo não encontrado no plano');
  end if;

  -- 3. Se tem limite, busca o valor
  if v_tem_limite then
    select limite_usuarios
    into v_limite
    from planos_modulos_limites
    where plano_modulo_id = v_plano_modulo_id;
  else
    v_limite := null;
  end if;

  -- 4. Conta os usuários da clínica
  select count(*)
  into v_total_utilizado
  from user_expandido_userclinica
  where clinica_id = v_clinica_id;

  -- 5. Decide se pode criar
  if v_tem_limite then
    v_pode_criar := v_total_utilizado < v_limite;
  else
    v_pode_criar := true;
  end if;

  -- 6. Retorna resultado
  return jsonb_build_object(
    'limite', v_limite,
    'total_utilizado', v_total_utilizado,
    'pode_criar', v_pode_criar
  );
end;
$$;


ALTER FUNCTION "public"."verifica_limite_clinica"("p_id_cliente" "uuid", "p_id_produto" "uuid", "p_id_modulo" "uuid") OWNER TO "postgres";

SET default_tablespace = '';

SET default_table_access_method = "heap";


CREATE TABLE IF NOT EXISTS "public"."anamnese" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "id_paciente" "uuid" NOT NULL,
    "id_clinica" "uuid" NOT NULL,
    "id_cliente_criar" "uuid",
    "id_user_clinica_criar" "uuid",
    "id_cliente_modificar" "uuid",
    "id_user_clinica_modificar" "uuid",
    "id_modelo" "uuid" NOT NULL,
    "criado_em" timestamp without time zone DEFAULT "now"(),
    "modificado_em" timestamp without time zone DEFAULT "now"(),
    "id_atendimento" "uuid"
);


ALTER TABLE "public"."anamnese" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."anamnese_modelo" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "nome" "text" NOT NULL,
    "id_clinica" "uuid",
    "id_cliente_criar" "uuid",
    "id_cliente_modificar" "uuid",
    "id_user_clinica_criar" "uuid",
    "id_user_clinica_modificar" "uuid",
    "criado_em" timestamp without time zone DEFAULT "now"(),
    "modificado_em" timestamp without time zone DEFAULT "now"(),
    "status" boolean DEFAULT true,
    "global" boolean DEFAULT false
);


ALTER TABLE "public"."anamnese_modelo" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."anamnese_pergunta" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "pergunta" "text" NOT NULL,
    "id_anamnese_modelo" "uuid" NOT NULL,
    "criado_em" timestamp without time zone DEFAULT "now"(),
    "modificado_em" timestamp without time zone DEFAULT "now"(),
    "tipo_pergunta" "public"."tipo_pergunta" DEFAULT 'Texto Curto'::"public"."tipo_pergunta",
    "ordem" integer
);


ALTER TABLE "public"."anamnese_pergunta" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."anamnese_resposta" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "resposta" "text" NOT NULL,
    "id_paciente" "uuid" NOT NULL,
    "id_anamnese" "uuid" NOT NULL,
    "id_clinica" "uuid" NOT NULL,
    "id_anamnese_modelo" "uuid",
    "id_cliente_criar" "uuid",
    "id_cliente_modificar" "uuid",
    "id_user_clinica_criar" "uuid",
    "id_user_clinica_modificar" "uuid",
    "criado_em" timestamp without time zone DEFAULT "now"(),
    "modificado_em" timestamp without time zone DEFAULT "now"(),
    "id_anamnese_pergunta" "uuid"
);


ALTER TABLE "public"."anamnese_resposta" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."app_atualizacoes" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "id_produto" "uuid" NOT NULL,
    "titulo" "text" NOT NULL,
    "mensagem" "text" NOT NULL,
    "versao" "text",
    "tipo" "text",
    "destaque" boolean DEFAULT false,
    "data_atualizacao" timestamp with time zone DEFAULT "now"() NOT NULL,
    "criado_por" "uuid",
    "criado_em" timestamp with time zone DEFAULT "now"(),
    "atualizado_em" timestamp with time zone DEFAULT "now"()
);


ALTER TABLE "public"."app_atualizacoes" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."arquivos_pacientes" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "id_paciente" "uuid" NOT NULL,
    "id_clinica" "uuid" NOT NULL,
    "id_atendimento" "uuid",
    "id_cliente_criar" "uuid",
    "id_user_clinica_criar" "uuid",
    "criado_em" timestamp with time zone DEFAULT "now"() NOT NULL,
    "path" "text" NOT NULL,
    "nome_original" "text" NOT NULL,
    "tipo_documento" "public"."tipo_documento_enum",
    "tamanho_bytes" integer,
    "mime_type" "text",
    "status" "text" DEFAULT 'ativo'::"text",
    "observacoes" "text"
);


ALTER TABLE "public"."arquivos_pacientes" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."atendimentos" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "id_paciente" "uuid" NOT NULL,
    "id_profissional" "uuid" NOT NULL,
    "id_user_clinica" "uuid",
    "id_clinica" "uuid" NOT NULL,
    "data_reserva" timestamp with time zone DEFAULT "now"(),
    "data_inicio" timestamp with time zone,
    "data_fim" timestamp with time zone,
    "status" "text" DEFAULT 'em andamento'::"text"
);


ALTER TABLE "public"."atendimentos" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."cliente_contrato" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "status" "public"."status_contrato" DEFAULT 'ativo'::"public"."status_contrato" NOT NULL,
    "data_criacao" timestamp with time zone DEFAULT "now"(),
    "id_cliente" "uuid"
);


ALTER TABLE "public"."cliente_contrato" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."cliente_pagamento_contrato" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "id_contrato" "uuid" NOT NULL,
    "mes_index" integer,
    "data" "date" NOT NULL,
    "status" boolean DEFAULT false,
    CONSTRAINT "cliente_pagamento_contrato_mes_index_check" CHECK ((("mes_index" >= 1) AND ("mes_index" <= 12)))
);


ALTER TABLE "public"."cliente_pagamento_contrato" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."clinica" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "user_id" "uuid" NOT NULL,
    "nome" "text" NOT NULL,
    "created_at" timestamp without time zone DEFAULT "now"(),
    "imagem_clinica" "text",
    "contexto_id" "uuid",
    "id_cliente" "uuid",
    "produto_id" "uuid"
);


ALTER TABLE "public"."clinica" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."clinica_user" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "id_user" "uuid" NOT NULL,
    "id_clinica" "uuid" NOT NULL,
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "updated_at" timestamp with time zone DEFAULT "now"() NOT NULL
);


ALTER TABLE "public"."clinica_user" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."controle_pareamento" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "id_user" "uuid" NOT NULL,
    "pareado_dispositivo" boolean DEFAULT false,
    "exame_iniciado" boolean DEFAULT false,
    "created_at" timestamp without time zone DEFAULT "now"()
);


ALTER TABLE "public"."controle_pareamento" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."crm" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "id_produto" "uuid",
    "nome_completo" "text" NOT NULL,
    "telefone" "text",
    "email" "text",
    "status" "text" DEFAULT 'novo'::"text" NOT NULL,
    "origem" "text",
    "etapa_funil" "text",
    "notas" "text",
    "id_responsavel" "uuid",
    "criado_em" timestamp with time zone DEFAULT "now"() NOT NULL,
    "modificado_em" timestamp with time zone DEFAULT "now"() NOT NULL
);


ALTER TABLE "public"."crm" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."exame_modelo" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "nome" "text" NOT NULL,
    "descricao" "text",
    "instrucoes_preparo" "text",
    "observacoes" "text",
    "tipo_id" "uuid",
    "subtipo_id" "uuid",
    "sistema_id" "uuid",
    "id_clinica" "uuid",
    "id_cliente_criar" "uuid",
    "id_cliente_modificar" "uuid",
    "id_user_clinica_criar" "uuid",
    "id_user_clinica_modificar" "uuid",
    "criado_em" timestamp without time zone DEFAULT "now"(),
    "modificado_em" timestamp without time zone DEFAULT "now"(),
    "status" boolean DEFAULT true,
    "global" boolean DEFAULT false,
    "deletado" boolean DEFAULT false NOT NULL
);


ALTER TABLE "public"."exame_modelo" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."exame_pergunta" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "id_modelo" "uuid" NOT NULL,
    "ordem" integer NOT NULL,
    "pergunta" "text" NOT NULL,
    "tipo_pergunta" "public"."tipo_pergunta" NOT NULL,
    "legenda" "text",
    "obrigatorio" boolean DEFAULT true,
    "dica" "text",
    "altura" integer,
    "largura" integer,
    "valores_referencia" "jsonb",
    "encolhido" boolean DEFAULT false NOT NULL,
    "tem_legenda" boolean DEFAULT false NOT NULL,
    "deletado" boolean DEFAULT false NOT NULL
);


ALTER TABLE "public"."exame_pergunta" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."exame_respostas_possiveis" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "id_pergunta" "uuid" NOT NULL,
    "ordem" integer NOT NULL,
    "resposta" "text" NOT NULL,
    "correta" boolean DEFAULT false NOT NULL
);


ALTER TABLE "public"."exame_respostas_possiveis" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."exame_sistema" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "nome" "text" NOT NULL,
    "descricao" "text"
);


ALTER TABLE "public"."exame_sistema" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."exame_subtipo" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "nome" "text" NOT NULL,
    "tipo_id" "uuid",
    "descricao" "text"
);


ALTER TABLE "public"."exame_subtipo" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."exame_tipo" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "nome" "text" NOT NULL,
    "descricao" "text"
);


ALTER TABLE "public"."exame_tipo" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."exame_valores_referencia" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "id_pergunta" "uuid" NOT NULL,
    "categoria" "text",
    "valor" "text"
);


ALTER TABLE "public"."exame_valores_referencia" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."modulos" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "nome" "text" NOT NULL,
    "descricao" "text",
    "created_at" timestamp without time zone DEFAULT "now"(),
    "produto_id" "uuid"
);


ALTER TABLE "public"."modulos" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."oto_condicoes_exame" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "nome" "text" NOT NULL,
    "label" "text" NOT NULL,
    "cod_condicao" integer NOT NULL,
    "amaxdir" integer NOT NULL,
    "amaxesq" integer NOT NULL,
    "amindir" integer NOT NULL,
    "aminesq" integer NOT NULL,
    "aidealcab" integer NOT NULL,
    "amincab" integer NOT NULL,
    "amaxcab" integer NOT NULL,
    "created_at" timestamp with time zone DEFAULT "now"()
);


ALTER TABLE "public"."oto_condicoes_exame" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."oto_condicoes_exame_paciente" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "id_exame" "uuid" NOT NULL,
    "id_clinica" "uuid" NOT NULL,
    "id_condicao" "uuid" NOT NULL,
    "m1" double precision,
    "m2" double precision,
    "m3" double precision,
    "m4" double precision,
    "md" double precision,
    "mnd" double precision,
    "criado_em" timestamp with time zone DEFAULT "now"(),
    "criado_por" "uuid",
    "modificado_em" timestamp with time zone DEFAULT "now"(),
    "modificado_por" "uuid",
    "deletado" boolean DEFAULT false NOT NULL
);


ALTER TABLE "public"."oto_condicoes_exame_paciente" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."oto_exames" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "id_paciente" "uuid" NOT NULL,
    "id_profissional" "uuid",
    "id_user_clinica" "uuid",
    "id_clinica" "uuid" NOT NULL,
    "tipo" "public"."tipo_exame" DEFAULT 'exame'::"public"."tipo_exame" NOT NULL,
    "criado_em" timestamp with time zone DEFAULT "now"(),
    "criado_por" "uuid",
    "modificado_em" timestamp with time zone DEFAULT "now"(),
    "modificado_por" "uuid",
    "deletado" boolean DEFAULT false NOT NULL,
    "laudo" "text"
);


ALTER TABLE "public"."oto_exames" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."perguntas_user" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "pergunta" "text" NOT NULL,
    "label" "text" NOT NULL,
    "tipo_pergunta" "text" NOT NULL,
    "opcoes" "jsonb",
    "papeis" "jsonb",
    "ativo" boolean DEFAULT true NOT NULL,
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "updated_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "ordem" integer,
    "largura" integer,
    "altura" integer,
    "obrigatorio" boolean DEFAULT false NOT NULL,
    "depende" boolean DEFAULT false NOT NULL,
    "depende_de" "uuid",
    "valor_depende" "text"
);


ALTER TABLE "public"."perguntas_user" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."planos" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "nome" "text" NOT NULL,
    "descricao" "text",
    "created_at" timestamp without time zone DEFAULT "now"(),
    "valor" numeric(10,2),
    "produto_id" "uuid"
);


ALTER TABLE "public"."planos" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."planos_modulos" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "plano_id" "uuid" NOT NULL,
    "modulo_id" "uuid" NOT NULL,
    "disponivel" boolean DEFAULT true NOT NULL,
    "tem_limite" boolean DEFAULT false NOT NULL
);


ALTER TABLE "public"."planos_modulos" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."planos_modulos_limites" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "plano_modulo_id" "uuid" NOT NULL,
    "limite_usuarios" integer NOT NULL
);


ALTER TABLE "public"."planos_modulos_limites" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."produtos" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "nome" "text" NOT NULL,
    "slug" "text" NOT NULL,
    "ativo" boolean DEFAULT true,
    "dominio" "text",
    "logo_menor" "text",
    "logo_maior" "text"
);


ALTER TABLE "public"."produtos" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."produtos_user" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "user_id" "uuid",
    "produto_id" "uuid",
    "criado_em" timestamp without time zone DEFAULT "now"(),
    "status" boolean DEFAULT true NOT NULL,
    "id_user_expandido" "uuid"
);


ALTER TABLE "public"."produtos_user" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."questionario_gabarito" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "id_questionario" "uuid" NOT NULL,
    "pontuacao_min" numeric(8,2) NOT NULL,
    "pontuacao_max" numeric(8,2) NOT NULL,
    "diagnostico" "text" NOT NULL,
    "observacoes" "text",
    "criado_por_cliente" "uuid",
    "criado_por_user_clinica" "uuid",
    "modificado_por_cliente" "uuid",
    "modificado_por_user_clinica" "uuid",
    "criado_em" timestamp without time zone DEFAULT "now"(),
    "modificado_em" timestamp without time zone
);


ALTER TABLE "public"."questionario_gabarito" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."questionario_modelo" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "nome" "text" NOT NULL,
    "instrucoes" "text",
    "observacoes" "text",
    "global" boolean DEFAULT false,
    "status" boolean DEFAULT true,
    "deletado" boolean DEFAULT false,
    "id_clinica" "uuid",
    "respostas_globais" boolean DEFAULT false,
    "criado_por_cliente" "uuid",
    "criado_por_user_clinica" "uuid",
    "modificado_por_cliente" "uuid",
    "modificado_por_user_clinica" "uuid",
    "criado_em" timestamp without time zone DEFAULT "now"(),
    "modificado_em" timestamp without time zone
);


ALTER TABLE "public"."questionario_modelo" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."questionario_perguntas" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "id_questionario" "uuid" NOT NULL,
    "pergunta" "text" NOT NULL,
    "ordem" integer NOT NULL,
    "deletada" boolean DEFAULT false,
    "criado_por_cliente" "uuid",
    "criado_por_user_clinica" "uuid",
    "modificado_por_cliente" "uuid",
    "modificado_por_user_clinica" "uuid",
    "criado_em" timestamp without time zone DEFAULT "now"(),
    "modificado_em" timestamp without time zone,
    "id_grupo" "uuid"
);


ALTER TABLE "public"."questionario_perguntas" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."questionario_perguntas_grupo" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "nome" "text" NOT NULL,
    "criado_por_cliente" "uuid",
    "criado_por_user_clinica" "uuid",
    "modificado_por_cliente" "uuid",
    "modificado_por_user_clinica" "uuid",
    "criado_em" timestamp without time zone DEFAULT "now"(),
    "modificado_em" timestamp without time zone,
    "id_questionario" "uuid",
    "ordem" integer
);


ALTER TABLE "public"."questionario_perguntas_grupo" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."questionario_respostas" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "id_questionario" "uuid",
    "id_pergunta" "uuid",
    "resposta" "text" NOT NULL,
    "pontuacao" numeric(8,2) NOT NULL,
    "ordem" integer NOT NULL,
    "criado_por_cliente" "uuid",
    "criado_por_user_clinica" "uuid",
    "modificado_por_cliente" "uuid",
    "modificado_por_user_clinica" "uuid",
    "criado_em" timestamp without time zone DEFAULT "now"(),
    "modificado_em" timestamp without time zone
);


ALTER TABLE "public"."questionario_respostas" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."reabilitacao_exercicios" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "id_paciente" "uuid" NOT NULL,
    "id_reabilitacao" "uuid" NOT NULL,
    "id_clinica" "uuid" NOT NULL,
    "instrucoes_gerais" "text",
    "status" boolean DEFAULT true,
    "created_at" timestamp with time zone DEFAULT "now"()
);


ALTER TABLE "public"."reabilitacao_exercicios" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."reabilitacao_exercicios_videos" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "id_reabilitacao_exercicio" "uuid" NOT NULL,
    "id_video" "uuid" NOT NULL,
    "instrucao_auxiliar" "text",
    "created_at" timestamp with time zone DEFAULT "now"()
);


ALTER TABLE "public"."reabilitacao_exercicios_videos" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."reabilitacoes" (
    "id" "uuid" DEFAULT "extensions"."uuid_generate_v4"() NOT NULL,
    "nome" "text" NOT NULL,
    "descricao" "text"
);


ALTER TABLE "public"."reabilitacoes" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."respostas_user" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "id_user" "uuid" NOT NULL,
    "id_pergunta" "uuid" NOT NULL,
    "resposta" "text",
    "resposta_data" timestamp with time zone,
    "nome_arquivo_original" "text",
    "id_clinica" "uuid",
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "updated_at" timestamp with time zone DEFAULT "now"() NOT NULL
);


ALTER TABLE "public"."respostas_user" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."role_auth" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "nome_role" "public"."role_enum"
);


ALTER TABLE "public"."role_auth" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."user_expandido" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "user_id" "uuid" NOT NULL,
    "nome_completo" "text" NOT NULL,
    "email" "text" NOT NULL,
    "telefone" "text",
    "imagem_user" "text",
    "status" boolean DEFAULT true NOT NULL,
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "updated_at" timestamp with time zone DEFAULT "now"() NOT NULL
);


ALTER TABLE "public"."user_expandido" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."user_expandido_admin" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "user_id" "uuid" NOT NULL,
    "nome_completo" "text" NOT NULL,
    "cpf" "text" NOT NULL,
    "email" "text" NOT NULL,
    "telefone" "text",
    "created_at" timestamp without time zone DEFAULT "now"(),
    "role_id" "uuid" NOT NULL,
    "imagem_user" "text",
    "status" boolean DEFAULT false
);


ALTER TABLE "public"."user_expandido_admin" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."user_expandido_cliente" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "user_id" "uuid" NOT NULL,
    "tipo_juridico_fisico" "text" NOT NULL,
    "nome_completo" "text" NOT NULL,
    "sexo" "text",
    "data_nascimento" "date",
    "cpf" character varying(14) NOT NULL,
    "rg" character varying(20),
    "tipo_credenciamento" "text",
    "numero_credenciamento" character varying(20),
    "telefone" character varying(20),
    "cep" character varying(10),
    "endereco" "text",
    "numero" character varying(10),
    "complemento" "text",
    "bairro" "text",
    "cidade" "text",
    "estado" character varying(50),
    "pais" character varying(50),
    "role_id" "uuid",
    "created_at" timestamp without time zone DEFAULT "now"(),
    "email" "text" NOT NULL,
    "status" boolean,
    "plano_id" "uuid",
    "razao_social" "text",
    "cnpj" character varying(18),
    "clinica_id" "uuid",
    "imagem_user" "text",
    CONSTRAINT "user_expandido_sexo_check" CHECK (("sexo" = ANY (ARRAY['masculino'::"text", 'feminino'::"text"]))),
    CONSTRAINT "user_expandido_tipo_credenciamento_check" CHECK (("tipo_credenciamento" = ANY (ARRAY['CRM'::"text", 'RPQ'::"text", 'CRFa'::"text", 'CFM'::"text"]))),
    CONSTRAINT "user_expandido_tipo_juridico_fisico_check" CHECK (("tipo_juridico_fisico" = ANY (ARRAY['pessoa física'::"text", 'pessoa jurídica'::"text"])))
);


ALTER TABLE "public"."user_expandido_cliente" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."user_expandido_colaboradores" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "user_id" "uuid" NOT NULL,
    "nome_completo" "text" NOT NULL,
    "cpf" "text" NOT NULL,
    "email" "text" NOT NULL,
    "telefone" "text",
    "created_at" timestamp without time zone DEFAULT "now"(),
    "role_id" "uuid" NOT NULL,
    "imagem_user" "text",
    "status" boolean DEFAULT false,
    "clinica_id" "uuid" NOT NULL
);


ALTER TABLE "public"."user_expandido_colaboradores" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."user_expandido_paciente" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "nome_completo" "text" NOT NULL,
    "email" "text",
    "telefone" character varying(20),
    "sexo" "text",
    "data_nascimento" "date",
    "status" boolean DEFAULT true,
    "id_clinica" "uuid" NOT NULL,
    "created_at" timestamp without time zone DEFAULT "now"(),
    "ultima_interacao" "date",
    CONSTRAINT "usuario_expandido_paciente_sexo_check" CHECK (("sexo" = ANY (ARRAY['masculino'::"text", 'feminino'::"text"])))
);


ALTER TABLE "public"."user_expandido_paciente" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."user_expandido_paciente_detalhes" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "id_paciente" "uuid" NOT NULL,
    "antecedentes_clinicos" "text",
    "antecedentes_cirurgicos" "text",
    "antecedentes_familiares" "text",
    "habitos" "text",
    "alergias" "text",
    "medicamentos_em_uso" "text",
    "created_at" timestamp without time zone DEFAULT "now"(),
    "updated_at" timestamp without time zone DEFAULT "now"()
);


ALTER TABLE "public"."user_expandido_paciente_detalhes" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."user_expandido_userclinica" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "user_id" "uuid" NOT NULL,
    "nome_completo" "text" NOT NULL,
    "cpf" "text" NOT NULL,
    "email" "text" NOT NULL,
    "telefone" "text",
    "created_at" timestamp without time zone DEFAULT "now"(),
    "role_id" "uuid" NOT NULL,
    "imagem_user" "text",
    "status" boolean DEFAULT false,
    "clinica_id" "uuid" NOT NULL
);


ALTER TABLE "public"."user_expandido_userclinica" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."user_role_auth" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "user_id" "uuid",
    "role_id" "uuid",
    "clinica_id" "uuid"
);


ALTER TABLE "public"."user_role_auth" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."user_role_log" (
    "id" integer NOT NULL,
    "deleted_at" timestamp with time zone DEFAULT "now"(),
    "deleted_by" "uuid" DEFAULT "auth"."uid"(),
    "deleted_data" "jsonb"
);


ALTER TABLE "public"."user_role_log" OWNER TO "postgres";


CREATE SEQUENCE IF NOT EXISTS "public"."user_role_log_id_seq"
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE "public"."user_role_log_id_seq" OWNER TO "postgres";


ALTER SEQUENCE "public"."user_role_log_id_seq" OWNED BY "public"."user_role_log"."id";



CREATE TABLE IF NOT EXISTS "public"."videos" (
    "id" "uuid" DEFAULT "extensions"."uuid_generate_v4"() NOT NULL,
    "id_bunnystream" "text" NOT NULL,
    "nome" "text" NOT NULL,
    "url_thumbnail" "text",
    "descricao" "text",
    "instrucao_para_profissional" "text",
    "instrucao_para_paciente" "text",
    "gabarito" "text",
    "sugestao_uso" "text",
    "nivel" "public"."nivel_dificuldade" DEFAULT '1'::"public"."nivel_dificuldade" NOT NULL,
    "reabilitacao_id" "uuid",
    "created_at" timestamp with time zone DEFAULT "now"(),
    "categoria_id" "uuid"
);


ALTER TABLE "public"."videos" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."videos_categorias" (
    "id" "uuid" DEFAULT "extensions"."uuid_generate_v4"() NOT NULL,
    "nome" "text" NOT NULL
);


ALTER TABLE "public"."videos_categorias" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."videos_grupos" (
    "id" "uuid" DEFAULT "extensions"."uuid_generate_v4"() NOT NULL,
    "nome" "text" NOT NULL,
    "descricao" "text",
    "criado_em" timestamp without time zone DEFAULT "now"()
);


ALTER TABLE "public"."videos_grupos" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."videos_grupos_rel_videos" (
    "video_id" "uuid" NOT NULL,
    "grupo_id" "uuid" NOT NULL
);


ALTER TABLE "public"."videos_grupos_rel_videos" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."videos_habilidades" (
    "id" "uuid" DEFAULT "extensions"."uuid_generate_v4"() NOT NULL,
    "nome" "text" NOT NULL
);


ALTER TABLE "public"."videos_habilidades" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."videos_habilidades_rel_videos" (
    "video_id" "uuid" NOT NULL,
    "habilidade_id" "uuid" NOT NULL
);


ALTER TABLE "public"."videos_habilidades_rel_videos" OWNER TO "postgres";


CREATE OR REPLACE VIEW "public"."view_exercicios" WITH ("security_invoker"='on') AS
 SELECT "ex"."id" AS "id_exercicio",
    "ex"."id_paciente",
    "pac"."nome_completo" AS "nome_paciente",
    "ex"."id_reabilitacao",
    "r"."nome" AS "nome_reabilitacao",
    "ex"."status",
    "count"("v"."id") AS "quantidade_videos"
   FROM ((("public"."reabilitacao_exercicios" "ex"
     JOIN "public"."user_expandido_paciente" "pac" ON (("ex"."id_paciente" = "pac"."id")))
     JOIN "public"."reabilitacoes" "r" ON (("ex"."id_reabilitacao" = "r"."id")))
     LEFT JOIN "public"."reabilitacao_exercicios_videos" "v" ON (("v"."id_reabilitacao_exercicio" = "ex"."id")))
  GROUP BY "ex"."id", "ex"."id_paciente", "pac"."nome_completo", "ex"."id_reabilitacao", "r"."nome", "ex"."status";


ALTER TABLE "public"."view_exercicios" OWNER TO "postgres";


CREATE OR REPLACE VIEW "public"."view_oto_exames_completo" WITH ("security_invoker"='on') AS
 WITH "dados_condicoes" AS (
         SELECT "c"."id_exame",
            "ce"."nome" AS "nome_condicao",
            "c"."md",
            "c"."mnd"
           FROM ("public"."oto_condicoes_exame_paciente" "c"
             JOIN "public"."oto_condicoes_exame" "ce" ON (("ce"."id" = "c"."id_condicao")))
        ), "condicoes_pivot" AS (
         SELECT "dados_condicoes"."id_exame",
            "max"(
                CASE
                    WHEN ("dados_condicoes"."nome_condicao" = 'neutra'::"text") THEN "dados_condicoes"."md"
                    ELSE NULL::double precision
                END) AS "neutra_md",
            "max"(
                CASE
                    WHEN ("dados_condicoes"."nome_condicao" = 'neutra'::"text") THEN "dados_condicoes"."mnd"
                    ELSE NULL::double precision
                END) AS "neutra_mnd",
            "max"(
                CASE
                    WHEN ("dados_condicoes"."nome_condicao" = 'estatica_direita'::"text") THEN "dados_condicoes"."md"
                    ELSE NULL::double precision
                END) AS "estatica_direita_md",
            "max"(
                CASE
                    WHEN ("dados_condicoes"."nome_condicao" = 'estatica_direita'::"text") THEN "dados_condicoes"."mnd"
                    ELSE NULL::double precision
                END) AS "estatica_direita_mnd",
            "max"(
                CASE
                    WHEN ("dados_condicoes"."nome_condicao" = 'estatica_esquerda'::"text") THEN "dados_condicoes"."md"
                    ELSE NULL::double precision
                END) AS "estatica_esquerda_md",
            "max"(
                CASE
                    WHEN ("dados_condicoes"."nome_condicao" = 'estatica_esquerda'::"text") THEN "dados_condicoes"."mnd"
                    ELSE NULL::double precision
                END) AS "estatica_esquerda_mnd",
            "max"(
                CASE
                    WHEN ("dados_condicoes"."nome_condicao" = 'dinamica_horario'::"text") THEN "dados_condicoes"."md"
                    ELSE NULL::double precision
                END) AS "dinamica_horario_md",
            "max"(
                CASE
                    WHEN ("dados_condicoes"."nome_condicao" = 'dinamica_horario'::"text") THEN "dados_condicoes"."mnd"
                    ELSE NULL::double precision
                END) AS "dinamica_horario_mnd",
            "max"(
                CASE
                    WHEN ("dados_condicoes"."nome_condicao" = 'dinamica_antihorario'::"text") THEN "dados_condicoes"."md"
                    ELSE NULL::double precision
                END) AS "dinamica_antihorario_md",
            "max"(
                CASE
                    WHEN ("dados_condicoes"."nome_condicao" = 'dinamica_antihorario'::"text") THEN "dados_condicoes"."mnd"
                    ELSE NULL::double precision
                END) AS "dinamica_antihorario_mnd",
            "max"(
                CASE
                    WHEN ("dados_condicoes"."nome_condicao" = 'haptica_direita'::"text") THEN "dados_condicoes"."md"
                    ELSE NULL::double precision
                END) AS "haptica_direita_md",
            "max"(
                CASE
                    WHEN ("dados_condicoes"."nome_condicao" = 'haptica_direita'::"text") THEN "dados_condicoes"."mnd"
                    ELSE NULL::double precision
                END) AS "haptica_direita_mnd",
            "max"(
                CASE
                    WHEN ("dados_condicoes"."nome_condicao" = 'haptica_esquerda'::"text") THEN "dados_condicoes"."md"
                    ELSE NULL::double precision
                END) AS "haptica_esquerda_md",
            "max"(
                CASE
                    WHEN ("dados_condicoes"."nome_condicao" = 'haptica_esquerda'::"text") THEN "dados_condicoes"."mnd"
                    ELSE NULL::double precision
                END) AS "haptica_esquerda_mnd"
           FROM "dados_condicoes"
          GROUP BY "dados_condicoes"."id_exame"
        )
 SELECT "e"."id",
    "e"."id_paciente",
    "e"."id_profissional",
    "e"."id_user_clinica",
    "e"."id_clinica",
    "e"."tipo",
    "e"."criado_em",
    "e"."criado_por",
    "e"."modificado_em",
    "e"."modificado_por",
    "e"."deletado",
    "e"."laudo",
    COALESCE("p"."nome_completo", "uc"."nome_completo") AS "nome_profissional_ou_userclinica",
    "cp"."neutra_md",
    "cp"."neutra_mnd",
    "cp"."estatica_direita_md",
    "cp"."estatica_direita_mnd",
    "cp"."estatica_esquerda_md",
    "cp"."estatica_esquerda_mnd",
    "cp"."dinamica_horario_md",
    "cp"."dinamica_horario_mnd",
    "cp"."dinamica_antihorario_md",
    "cp"."dinamica_antihorario_mnd",
    "cp"."haptica_direita_md",
    "cp"."haptica_direita_mnd",
    "cp"."haptica_esquerda_md",
    "cp"."haptica_esquerda_mnd"
   FROM ((("public"."oto_exames" "e"
     LEFT JOIN "public"."user_expandido_cliente" "p" ON (("p"."id" = "e"."id_profissional")))
     LEFT JOIN "public"."user_expandido_userclinica" "uc" ON (("uc"."id" = "e"."id_user_clinica")))
     LEFT JOIN "condicoes_pivot" "cp" ON (("cp"."id_exame" = "e"."id")));


ALTER TABLE "public"."view_oto_exames_completo" OWNER TO "postgres";


CREATE OR REPLACE VIEW "public"."view_oto_exames_por_m" WITH ("security_invoker"='on') AS
 SELECT
        CASE EXTRACT(month FROM "oto_exames"."criado_em")
            WHEN 1 THEN 'Janeiro'::"text"
            WHEN 2 THEN 'Fevereiro'::"text"
            WHEN 3 THEN 'Março'::"text"
            WHEN 4 THEN 'Abril'::"text"
            WHEN 5 THEN 'Maio'::"text"
            WHEN 6 THEN 'Junho'::"text"
            WHEN 7 THEN 'Julho'::"text"
            WHEN 8 THEN 'Agosto'::"text"
            WHEN 9 THEN 'Setembro'::"text"
            WHEN 10 THEN 'Outubro'::"text"
            WHEN 11 THEN 'Novembro'::"text"
            WHEN 12 THEN 'Dezembro'::"text"
            ELSE NULL::"text"
        END AS "mes",
    "oto_exames"."id_clinica",
    "count"(*) AS "total_exames"
   FROM "public"."oto_exames"
  WHERE (("oto_exames"."deletado" = false) AND ("oto_exames"."criado_em" >= ("now"() - '365 days'::interval)))
  GROUP BY "oto_exames"."id_clinica", (EXTRACT(month FROM "oto_exames"."criado_em"))
  ORDER BY "oto_exames"."id_clinica", (EXTRACT(month FROM "oto_exames"."criado_em"));


ALTER TABLE "public"."view_oto_exames_por_m" OWNER TO "postgres";


CREATE OR REPLACE VIEW "public"."view_planos_com_modulos_pivotado" WITH ("security_invoker"='on') AS
 SELECT "p"."id" AS "plano_id",
    "p"."nome" AS "plano_nome",
    "p"."produto_id" AS "plano_produto_id",
    "jsonb_agg"("jsonb_build_object"('modulo_id', "m"."id", 'nome', "m"."nome", 'produto_id', "m"."produto_id", 'tem_limite', "pm"."tem_limite", 'limite_usuarios', COALESCE("pml"."limite_usuarios", 0)) ORDER BY "m"."nome") AS "modulos"
   FROM ((("public"."planos" "p"
     LEFT JOIN "public"."planos_modulos" "pm" ON (("pm"."plano_id" = "p"."id")))
     LEFT JOIN "public"."modulos" "m" ON (("m"."id" = "pm"."modulo_id")))
     LEFT JOIN "public"."planos_modulos_limites" "pml" ON (("pml"."plano_modulo_id" = "pm"."id")))
  GROUP BY "p"."id", "p"."nome", "p"."produto_id"
  ORDER BY "p"."nome";


ALTER TABLE "public"."view_planos_com_modulos_pivotado" OWNER TO "postgres";


CREATE OR REPLACE VIEW "public"."vw_videos_filtrados_teste" WITH ("security_invoker"='on') AS
 SELECT "v"."id",
    "v"."nome",
    "v"."descricao",
    "v"."id_bunnystream",
    "v"."url_thumbnail" AS "thumbnail",
    "v"."nivel",
    "v"."categoria_id",
    "c"."nome" AS "categoria_nome",
    "v"."sugestao_uso",
    "v"."gabarito",
    "v"."instrucao_para_paciente",
    "v"."instrucao_para_profissional",
    "array_agg"(DISTINCT "jsonb_build_object"('id', "g"."id", 'nome', "g"."nome")) AS "grupos",
    "array_agg"(DISTINCT "jsonb_build_object"('id', "h"."id", 'nome', "h"."nome")) AS "habilidades",
    "array_agg"(DISTINCT "g"."nome") AS "grupos_nomes_texto",
    "array_agg"(DISTINCT "h"."nome") AS "habilidades_nomes_texto"
   FROM ((((("public"."videos" "v"
     LEFT JOIN "public"."videos_categorias" "c" ON (("c"."id" = "v"."categoria_id")))
     LEFT JOIN "public"."videos_grupos_rel_videos" "grv" ON (("grv"."video_id" = "v"."id")))
     LEFT JOIN "public"."videos_grupos" "g" ON (("g"."id" = "grv"."grupo_id")))
     LEFT JOIN "public"."videos_habilidades_rel_videos" "vrh" ON (("vrh"."video_id" = "v"."id")))
     LEFT JOIN "public"."videos_habilidades" "h" ON (("h"."id" = "vrh"."habilidade_id")))
  GROUP BY "v"."id", "v"."nome", "v"."descricao", "v"."id_bunnystream", "v"."url_thumbnail", "v"."nivel", "v"."categoria_id", "c"."nome", "v"."sugestao_uso", "v"."gabarito", "v"."instrucao_para_paciente", "v"."instrucao_para_profissional";


ALTER TABLE "public"."vw_videos_filtrados_teste" OWNER TO "postgres";


ALTER TABLE ONLY "public"."user_role_log" ALTER COLUMN "id" SET DEFAULT "nextval"('"public"."user_role_log_id_seq"'::"regclass");



ALTER TABLE ONLY "public"."anamnese_modelo"
    ADD CONSTRAINT "anamnese_modelo_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."anamnese_pergunta"
    ADD CONSTRAINT "anamnese_pergunta_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."anamnese"
    ADD CONSTRAINT "anamnese_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."anamnese_resposta"
    ADD CONSTRAINT "anamnese_resposta_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."arquivos_pacientes"
    ADD CONSTRAINT "arquivos_pacientes_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."atendimentos"
    ADD CONSTRAINT "atendimentos_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."videos_categorias"
    ADD CONSTRAINT "categorias_nome_key" UNIQUE ("nome");



ALTER TABLE ONLY "public"."videos_categorias"
    ADD CONSTRAINT "categorias_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."cliente_contrato"
    ADD CONSTRAINT "cliente_contrato_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."cliente_pagamento_contrato"
    ADD CONSTRAINT "cliente_pagamento_contrato_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."clinica"
    ADD CONSTRAINT "clinica_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."clinica_user"
    ADD CONSTRAINT "clinica_user_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."clinica_user"
    ADD CONSTRAINT "clinica_user_unq" UNIQUE ("id_user", "id_clinica");



ALTER TABLE ONLY "public"."controle_pareamento"
    ADD CONSTRAINT "controle_pareamento_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."crm"
    ADD CONSTRAINT "crm_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."exame_modelo"
    ADD CONSTRAINT "exame_modelo_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."exame_pergunta"
    ADD CONSTRAINT "exame_pergunta_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."exame_respostas_possiveis"
    ADD CONSTRAINT "exame_respostas_possiveis_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."exame_sistema"
    ADD CONSTRAINT "exame_sistema_nome_key" UNIQUE ("nome");



ALTER TABLE ONLY "public"."exame_sistema"
    ADD CONSTRAINT "exame_sistema_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."exame_subtipo"
    ADD CONSTRAINT "exame_subtipo_nome_key" UNIQUE ("nome");



ALTER TABLE ONLY "public"."exame_subtipo"
    ADD CONSTRAINT "exame_subtipo_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."exame_tipo"
    ADD CONSTRAINT "exame_tipo_nome_key" UNIQUE ("nome");



ALTER TABLE ONLY "public"."exame_tipo"
    ADD CONSTRAINT "exame_tipo_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."exame_valores_referencia"
    ADD CONSTRAINT "exame_valores_referencia_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."oto_exames"
    ADD CONSTRAINT "exames_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."videos_habilidades"
    ADD CONSTRAINT "habilidades_nome_key" UNIQUE ("nome");



ALTER TABLE ONLY "public"."videos_habilidades"
    ADD CONSTRAINT "habilidades_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."modulos"
    ADD CONSTRAINT "modulos_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."oto_condicoes_exame"
    ADD CONSTRAINT "oto_condicoes_exame_nome_key" UNIQUE ("nome");



ALTER TABLE ONLY "public"."oto_condicoes_exame_paciente"
    ADD CONSTRAINT "oto_condicoes_exame_paciente_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."oto_condicoes_exame"
    ADD CONSTRAINT "oto_condicoes_exame_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."perguntas_user"
    ADD CONSTRAINT "perguntas_user_pergunta_key" UNIQUE ("pergunta");



ALTER TABLE ONLY "public"."perguntas_user"
    ADD CONSTRAINT "perguntas_user_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."planos_modulos_limites"
    ADD CONSTRAINT "planos_modulos_limites_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."planos_modulos"
    ADD CONSTRAINT "planos_modulos_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."planos"
    ADD CONSTRAINT "planos_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."produtos"
    ADD CONSTRAINT "produtos_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."produtos"
    ADD CONSTRAINT "produtos_slug_key" UNIQUE ("slug");



ALTER TABLE ONLY "public"."produtos_user"
    ADD CONSTRAINT "produtos_user_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."questionario_gabarito"
    ADD CONSTRAINT "questionario_gabarito_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."questionario_modelo"
    ADD CONSTRAINT "questionario_modelo_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."questionario_perguntas_grupo"
    ADD CONSTRAINT "questionario_perguntas_grupo_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."questionario_perguntas"
    ADD CONSTRAINT "questionario_perguntas_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."questionario_respostas"
    ADD CONSTRAINT "questionario_respostas_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."reabilitacao_exercicios"
    ADD CONSTRAINT "reabilitacao_exercicios_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."reabilitacao_exercicios_videos"
    ADD CONSTRAINT "reabilitacao_exercicios_videos_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."reabilitacoes"
    ADD CONSTRAINT "reabilitacoes_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."respostas_user"
    ADD CONSTRAINT "respostas_user_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."respostas_user"
    ADD CONSTRAINT "respostas_user_unq" UNIQUE ("id_user", "id_pergunta");



ALTER TABLE ONLY "public"."role_auth"
    ADD CONSTRAINT "role_auth_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."produtos_user"
    ADD CONSTRAINT "unq_user_produto" UNIQUE ("user_id", "produto_id");



ALTER TABLE ONLY "public"."user_expandido_admin"
    ADD CONSTRAINT "user_expandido_admin_cpf_key" UNIQUE ("cpf");



ALTER TABLE ONLY "public"."user_expandido_admin"
    ADD CONSTRAINT "user_expandido_admin_email_key" UNIQUE ("email");



ALTER TABLE ONLY "public"."user_expandido_admin"
    ADD CONSTRAINT "user_expandido_admin_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."user_expandido_admin"
    ADD CONSTRAINT "user_expandido_admin_user_id_key" UNIQUE ("user_id");



ALTER TABLE ONLY "public"."user_expandido_cliente"
    ADD CONSTRAINT "user_expandido_cliente_email_unique" UNIQUE ("email");



ALTER TABLE ONLY "public"."user_expandido_cliente"
    ADD CONSTRAINT "user_expandido_cliente_user_id_unique" UNIQUE ("user_id");



ALTER TABLE ONLY "public"."user_expandido_colaboradores"
    ADD CONSTRAINT "user_expandido_colaboradores_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."user_expandido"
    ADD CONSTRAINT "user_expandido_email_key" UNIQUE ("email");



ALTER TABLE ONLY "public"."user_expandido_paciente_detalhes"
    ADD CONSTRAINT "user_expandido_paciente_detalhes_id_paciente_key" UNIQUE ("id_paciente");



ALTER TABLE ONLY "public"."user_expandido_paciente_detalhes"
    ADD CONSTRAINT "user_expandido_paciente_detalhes_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."user_expandido_cliente"
    ADD CONSTRAINT "user_expandido_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."user_expandido"
    ADD CONSTRAINT "user_expandido_pkey1" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."user_expandido"
    ADD CONSTRAINT "user_expandido_user_id_key" UNIQUE ("user_id");



ALTER TABLE ONLY "public"."user_expandido_userclinica"
    ADD CONSTRAINT "user_expandido_userclinica_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."user_role_auth"
    ADD CONSTRAINT "user_role_auth_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."user_role_log"
    ADD CONSTRAINT "user_role_log_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."user_expandido_paciente"
    ADD CONSTRAINT "usuario_expandido_paciente_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."videos_grupos"
    ADD CONSTRAINT "videos_grupos_nome_key" UNIQUE ("nome");



ALTER TABLE ONLY "public"."videos_grupos"
    ADD CONSTRAINT "videos_grupos_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."videos_grupos_rel_videos"
    ADD CONSTRAINT "videos_grupos_rel_videos_pkey" PRIMARY KEY ("video_id", "grupo_id");



ALTER TABLE ONLY "public"."videos_habilidades_rel_videos"
    ADD CONSTRAINT "videos_habilidades_rel_videos_pkey" PRIMARY KEY ("video_id", "habilidade_id");



ALTER TABLE ONLY "public"."videos"
    ADD CONSTRAINT "videos_pkey" PRIMARY KEY ("id");



CREATE INDEX "idx_arquivos_pacientes_atendimento" ON "public"."arquivos_pacientes" USING "btree" ("id_atendimento");



CREATE INDEX "idx_arquivos_pacientes_clinica" ON "public"."arquivos_pacientes" USING "btree" ("id_clinica");



CREATE INDEX "idx_arquivos_pacientes_paciente" ON "public"."arquivos_pacientes" USING "btree" ("id_paciente");



CREATE INDEX "ix_clinica_user_clinica" ON "public"."clinica_user" USING "btree" ("id_clinica");



CREATE INDEX "ix_clinica_user_user" ON "public"."clinica_user" USING "btree" ("id_user");



CREATE INDEX "ix_perguntas_user_pergunta" ON "public"."perguntas_user" USING "btree" ("pergunta");



CREATE INDEX "ix_produtos_user_id_user_expandido" ON "public"."produtos_user" USING "btree" ("id_user_expandido");



CREATE INDEX "ix_respostas_user_clinica" ON "public"."respostas_user" USING "btree" ("id_clinica");



CREATE INDEX "ix_respostas_user_pergunta" ON "public"."respostas_user" USING "btree" ("id_pergunta");



CREATE INDEX "ix_respostas_user_user" ON "public"."respostas_user" USING "btree" ("id_user");



CREATE INDEX "ix_user_expandido_email" ON "public"."user_expandido" USING "btree" ("email");



CREATE INDEX "ix_user_expandido_user_id" ON "public"."user_expandido" USING "btree" ("user_id");



CREATE OR REPLACE TRIGGER "trg_confirmar_email_automaticamente" AFTER INSERT ON "public"."user_expandido_admin" FOR EACH ROW EXECUTE FUNCTION "public"."confirmar_email_usuario_expandido"();



CREATE OR REPLACE TRIGGER "trg_confirmar_email_automaticamente" AFTER INSERT ON "public"."user_expandido_cliente" FOR EACH ROW EXECUTE FUNCTION "public"."confirmar_email_usuario_expandido"();



CREATE OR REPLACE TRIGGER "trg_confirmar_email_automaticamente" AFTER INSERT ON "public"."user_expandido_colaboradores" FOR EACH ROW EXECUTE FUNCTION "public"."confirmar_email_usuario_expandido"();



CREATE OR REPLACE TRIGGER "trg_confirmar_email_automaticamente" AFTER INSERT ON "public"."user_expandido_userclinica" FOR EACH ROW EXECUTE FUNCTION "public"."confirmar_email_usuario_expandido"();



CREATE OR REPLACE TRIGGER "trg_crm_updated_at" BEFORE UPDATE ON "public"."crm" FOR EACH ROW EXECUTE FUNCTION "public"."trg_set_updated_at"();



CREATE OR REPLACE TRIGGER "trg_set_updated_at" BEFORE UPDATE ON "public"."clinica_user" FOR EACH ROW EXECUTE FUNCTION "public"."trg_clinica_user_set_updated_at"();



CREATE OR REPLACE TRIGGER "trg_set_updated_at" BEFORE UPDATE ON "public"."perguntas_user" FOR EACH ROW EXECUTE FUNCTION "public"."trg_perguntas_user_set_updated_at"();



CREATE OR REPLACE TRIGGER "trg_set_updated_at" BEFORE UPDATE ON "public"."respostas_user" FOR EACH ROW EXECUTE FUNCTION "public"."trg_respostas_user_set_updated_at"();



CREATE OR REPLACE TRIGGER "trg_set_updated_at" BEFORE UPDATE ON "public"."user_expandido" FOR EACH ROW EXECUTE FUNCTION "public"."trg_user_expandido_set_updated_at"();



CREATE OR REPLACE TRIGGER "trigger_pagamentos_recorrentes" AFTER INSERT ON "public"."cliente_contrato" FOR EACH ROW EXECUTE FUNCTION "public"."gerar_pagamentos_recorrentes"();



ALTER TABLE ONLY "public"."anamnese"
    ADD CONSTRAINT "anamnese_id_atendimento_fkey" FOREIGN KEY ("id_atendimento") REFERENCES "public"."atendimentos"("id");



ALTER TABLE ONLY "public"."anamnese"
    ADD CONSTRAINT "anamnese_id_cliente_criar_fkey" FOREIGN KEY ("id_cliente_criar") REFERENCES "public"."user_expandido_cliente"("id");



ALTER TABLE ONLY "public"."anamnese"
    ADD CONSTRAINT "anamnese_id_cliente_modificar_fkey" FOREIGN KEY ("id_cliente_modificar") REFERENCES "public"."user_expandido_cliente"("id");



ALTER TABLE ONLY "public"."anamnese"
    ADD CONSTRAINT "anamnese_id_clinica_fkey" FOREIGN KEY ("id_clinica") REFERENCES "public"."clinica"("id");



ALTER TABLE ONLY "public"."anamnese"
    ADD CONSTRAINT "anamnese_id_modelo_fkey" FOREIGN KEY ("id_modelo") REFERENCES "public"."anamnese_modelo"("id");



ALTER TABLE ONLY "public"."anamnese"
    ADD CONSTRAINT "anamnese_id_paciente_fkey" FOREIGN KEY ("id_paciente") REFERENCES "public"."user_expandido_paciente"("id");



ALTER TABLE ONLY "public"."anamnese"
    ADD CONSTRAINT "anamnese_id_user_clinica_criar_fkey" FOREIGN KEY ("id_user_clinica_criar") REFERENCES "public"."user_expandido_userclinica"("id");



ALTER TABLE ONLY "public"."anamnese"
    ADD CONSTRAINT "anamnese_id_user_clinica_modificar_fkey" FOREIGN KEY ("id_user_clinica_modificar") REFERENCES "public"."user_expandido_userclinica"("id");



ALTER TABLE ONLY "public"."anamnese_modelo"
    ADD CONSTRAINT "anamnese_modelo_id_cliente_criar_fkey" FOREIGN KEY ("id_cliente_criar") REFERENCES "public"."user_expandido_cliente"("id");



ALTER TABLE ONLY "public"."anamnese_modelo"
    ADD CONSTRAINT "anamnese_modelo_id_cliente_modificar_fkey" FOREIGN KEY ("id_cliente_modificar") REFERENCES "public"."user_expandido_cliente"("id");



ALTER TABLE ONLY "public"."anamnese_modelo"
    ADD CONSTRAINT "anamnese_modelo_id_clinica_fkey" FOREIGN KEY ("id_clinica") REFERENCES "public"."clinica"("id");



ALTER TABLE ONLY "public"."anamnese_modelo"
    ADD CONSTRAINT "anamnese_modelo_id_user_clinica_criar_fkey" FOREIGN KEY ("id_user_clinica_criar") REFERENCES "public"."user_expandido_userclinica"("id");



ALTER TABLE ONLY "public"."anamnese_modelo"
    ADD CONSTRAINT "anamnese_modelo_id_user_clinica_modificar_fkey" FOREIGN KEY ("id_user_clinica_modificar") REFERENCES "public"."user_expandido_userclinica"("id");



ALTER TABLE ONLY "public"."anamnese_pergunta"
    ADD CONSTRAINT "anamnese_pergunta_id_anamnese_modelo_fkey" FOREIGN KEY ("id_anamnese_modelo") REFERENCES "public"."anamnese_modelo"("id");



ALTER TABLE ONLY "public"."anamnese_resposta"
    ADD CONSTRAINT "anamnese_resposta_id_anamnese_fkey" FOREIGN KEY ("id_anamnese") REFERENCES "public"."anamnese"("id");



ALTER TABLE ONLY "public"."anamnese_resposta"
    ADD CONSTRAINT "anamnese_resposta_id_anamnese_modelo_fkey" FOREIGN KEY ("id_anamnese_modelo") REFERENCES "public"."anamnese_modelo"("id");



ALTER TABLE ONLY "public"."anamnese_resposta"
    ADD CONSTRAINT "anamnese_resposta_id_anamnese_pergunta_fkey" FOREIGN KEY ("id_anamnese_pergunta") REFERENCES "public"."anamnese_pergunta"("id");



ALTER TABLE ONLY "public"."anamnese_resposta"
    ADD CONSTRAINT "anamnese_resposta_id_cliente_criar_fkey" FOREIGN KEY ("id_cliente_criar") REFERENCES "public"."user_expandido_cliente"("id");



ALTER TABLE ONLY "public"."anamnese_resposta"
    ADD CONSTRAINT "anamnese_resposta_id_cliente_modificar_fkey" FOREIGN KEY ("id_cliente_modificar") REFERENCES "public"."user_expandido_cliente"("id");



ALTER TABLE ONLY "public"."anamnese_resposta"
    ADD CONSTRAINT "anamnese_resposta_id_clinica_fkey" FOREIGN KEY ("id_clinica") REFERENCES "public"."clinica"("id");



ALTER TABLE ONLY "public"."anamnese_resposta"
    ADD CONSTRAINT "anamnese_resposta_id_paciente_fkey" FOREIGN KEY ("id_paciente") REFERENCES "public"."user_expandido_paciente"("id");



ALTER TABLE ONLY "public"."anamnese_resposta"
    ADD CONSTRAINT "anamnese_resposta_id_user_clinica_criar_fkey" FOREIGN KEY ("id_user_clinica_criar") REFERENCES "public"."user_expandido_userclinica"("id");



ALTER TABLE ONLY "public"."anamnese_resposta"
    ADD CONSTRAINT "anamnese_resposta_id_user_clinica_modificar_fkey" FOREIGN KEY ("id_user_clinica_modificar") REFERENCES "public"."user_expandido_userclinica"("id");



ALTER TABLE ONLY "public"."app_atualizacoes"
    ADD CONSTRAINT "app_atualizacoes_criado_por_fkey" FOREIGN KEY ("criado_por") REFERENCES "auth"."users"("id");



ALTER TABLE ONLY "public"."app_atualizacoes"
    ADD CONSTRAINT "app_atualizacoes_id_produto_fkey" FOREIGN KEY ("id_produto") REFERENCES "public"."produtos"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."arquivos_pacientes"
    ADD CONSTRAINT "arquivos_pacientes_id_cliente_criar_fkey" FOREIGN KEY ("id_cliente_criar") REFERENCES "public"."user_expandido_cliente"("id") ON DELETE SET NULL;



ALTER TABLE ONLY "public"."arquivos_pacientes"
    ADD CONSTRAINT "arquivos_pacientes_id_clinica_fkey" FOREIGN KEY ("id_clinica") REFERENCES "public"."clinica"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."arquivos_pacientes"
    ADD CONSTRAINT "arquivos_pacientes_id_paciente_fkey" FOREIGN KEY ("id_paciente") REFERENCES "public"."user_expandido_paciente"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."arquivos_pacientes"
    ADD CONSTRAINT "arquivos_pacientes_id_user_clinica_criar_fkey" FOREIGN KEY ("id_user_clinica_criar") REFERENCES "public"."user_expandido_userclinica"("id") ON DELETE SET NULL;



ALTER TABLE ONLY "public"."atendimentos"
    ADD CONSTRAINT "atendimentos_id_clinica_fkey" FOREIGN KEY ("id_clinica") REFERENCES "public"."clinica"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."atendimentos"
    ADD CONSTRAINT "atendimentos_id_paciente_fkey" FOREIGN KEY ("id_paciente") REFERENCES "public"."user_expandido_paciente"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."atendimentos"
    ADD CONSTRAINT "atendimentos_id_profissional_fkey" FOREIGN KEY ("id_profissional") REFERENCES "public"."user_expandido_cliente"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."atendimentos"
    ADD CONSTRAINT "atendimentos_id_userclinica_fkey" FOREIGN KEY ("id_user_clinica") REFERENCES "public"."user_expandido_userclinica"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."clinica"
    ADD CONSTRAINT "clinica_id_cliente_fkey" FOREIGN KEY ("id_cliente") REFERENCES "public"."user_expandido_cliente"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."clinica"
    ADD CONSTRAINT "clinica_produto_id_fkey" FOREIGN KEY ("produto_id") REFERENCES "public"."produtos"("id");



ALTER TABLE ONLY "public"."clinica_user"
    ADD CONSTRAINT "clinica_user_id_clinica_fkey" FOREIGN KEY ("id_clinica") REFERENCES "public"."clinica"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."clinica"
    ADD CONSTRAINT "clinica_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "public"."user_expandido_cliente"("user_id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."clinica_user"
    ADD CONSTRAINT "clinica_user_id_user_fkey" FOREIGN KEY ("id_user") REFERENCES "public"."user_expandido"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."controle_pareamento"
    ADD CONSTRAINT "controle_pareamento_id_user_fkey" FOREIGN KEY ("id_user") REFERENCES "auth"."users"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."crm"
    ADD CONSTRAINT "crm_id_produto_fkey" FOREIGN KEY ("id_produto") REFERENCES "public"."produtos"("id") ON DELETE SET NULL;



ALTER TABLE ONLY "public"."crm"
    ADD CONSTRAINT "crm_id_responsavel_fkey" FOREIGN KEY ("id_responsavel") REFERENCES "public"."user_expandido"("id");



ALTER TABLE ONLY "public"."exame_modelo"
    ADD CONSTRAINT "exame_modelo_id_cliente_criar_fkey" FOREIGN KEY ("id_cliente_criar") REFERENCES "public"."user_expandido_cliente"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."exame_modelo"
    ADD CONSTRAINT "exame_modelo_id_cliente_modificar_fkey" FOREIGN KEY ("id_cliente_modificar") REFERENCES "public"."user_expandido_cliente"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."exame_modelo"
    ADD CONSTRAINT "exame_modelo_id_clinica_fkey" FOREIGN KEY ("id_clinica") REFERENCES "public"."clinica"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."exame_modelo"
    ADD CONSTRAINT "exame_modelo_id_user_clinica_criar_fkey" FOREIGN KEY ("id_user_clinica_criar") REFERENCES "public"."user_expandido_userclinica"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."exame_modelo"
    ADD CONSTRAINT "exame_modelo_id_user_clinica_modificar_fkey" FOREIGN KEY ("id_user_clinica_modificar") REFERENCES "public"."user_expandido_userclinica"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."exame_modelo"
    ADD CONSTRAINT "exame_modelo_sistema_id_fkey" FOREIGN KEY ("sistema_id") REFERENCES "public"."exame_sistema"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."exame_modelo"
    ADD CONSTRAINT "exame_modelo_subtipo_id_fkey" FOREIGN KEY ("subtipo_id") REFERENCES "public"."exame_subtipo"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."exame_modelo"
    ADD CONSTRAINT "exame_modelo_tipo_id_fkey" FOREIGN KEY ("tipo_id") REFERENCES "public"."exame_tipo"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."exame_pergunta"
    ADD CONSTRAINT "exame_pergunta_id_modelo_fkey" FOREIGN KEY ("id_modelo") REFERENCES "public"."exame_modelo"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."exame_respostas_possiveis"
    ADD CONSTRAINT "exame_respostas_possiveis_id_pergunta_fkey" FOREIGN KEY ("id_pergunta") REFERENCES "public"."exame_pergunta"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."exame_subtipo"
    ADD CONSTRAINT "exame_subtipo_tipo_id_fkey" FOREIGN KEY ("tipo_id") REFERENCES "public"."exame_tipo"("id");



ALTER TABLE ONLY "public"."exame_valores_referencia"
    ADD CONSTRAINT "exame_valores_referencia_id_pergunta_fkey" FOREIGN KEY ("id_pergunta") REFERENCES "public"."exame_pergunta"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."oto_exames"
    ADD CONSTRAINT "exames_id_clinica_fkey" FOREIGN KEY ("id_clinica") REFERENCES "public"."clinica"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."oto_exames"
    ADD CONSTRAINT "exames_id_paciente_fkey" FOREIGN KEY ("id_paciente") REFERENCES "public"."user_expandido_paciente"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."oto_exames"
    ADD CONSTRAINT "exames_id_user_clinica_fkey" FOREIGN KEY ("id_user_clinica") REFERENCES "public"."user_expandido_userclinica"("id") ON DELETE SET NULL;



ALTER TABLE ONLY "public"."reabilitacao_exercicios"
    ADD CONSTRAINT "fk_clinica" FOREIGN KEY ("id_clinica") REFERENCES "public"."clinica"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."cliente_pagamento_contrato"
    ADD CONSTRAINT "fk_contrato" FOREIGN KEY ("id_contrato") REFERENCES "public"."cliente_contrato"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."user_expandido_paciente_detalhes"
    ADD CONSTRAINT "fk_detalhes_paciente" FOREIGN KEY ("id_paciente") REFERENCES "public"."user_expandido_paciente"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."reabilitacao_exercicios_videos"
    ADD CONSTRAINT "fk_exercicio" FOREIGN KEY ("id_reabilitacao_exercicio") REFERENCES "public"."reabilitacao_exercicios"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."cliente_contrato"
    ADD CONSTRAINT "fk_id_cliente" FOREIGN KEY ("id_cliente") REFERENCES "public"."user_expandido_cliente"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."reabilitacao_exercicios"
    ADD CONSTRAINT "fk_paciente" FOREIGN KEY ("id_paciente") REFERENCES "public"."user_expandido_paciente"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."reabilitacao_exercicios"
    ADD CONSTRAINT "fk_reabilitacao" FOREIGN KEY ("id_reabilitacao") REFERENCES "public"."reabilitacoes"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."reabilitacao_exercicios_videos"
    ADD CONSTRAINT "fk_video" FOREIGN KEY ("id_video") REFERENCES "public"."videos"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."modulos"
    ADD CONSTRAINT "modulos_produto_id_fkey" FOREIGN KEY ("produto_id") REFERENCES "public"."produtos"("id");



ALTER TABLE ONLY "public"."oto_condicoes_exame_paciente"
    ADD CONSTRAINT "oto_condicoes_exame_paciente_id_clinica_fkey" FOREIGN KEY ("id_clinica") REFERENCES "public"."clinica"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."oto_condicoes_exame_paciente"
    ADD CONSTRAINT "oto_condicoes_exame_paciente_id_condicao_fkey" FOREIGN KEY ("id_condicao") REFERENCES "public"."oto_condicoes_exame"("id") ON DELETE RESTRICT;



ALTER TABLE ONLY "public"."oto_condicoes_exame_paciente"
    ADD CONSTRAINT "oto_condicoes_exame_paciente_id_exame_fkey" FOREIGN KEY ("id_exame") REFERENCES "public"."oto_exames"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."oto_exames"
    ADD CONSTRAINT "oto_exames_id_profissional_fkey" FOREIGN KEY ("id_profissional") REFERENCES "public"."user_expandido_cliente"("id");



ALTER TABLE ONLY "public"."planos_modulos_limites"
    ADD CONSTRAINT "planos_modulos_limites_plano_modulo_id_fkey" FOREIGN KEY ("plano_modulo_id") REFERENCES "public"."planos_modulos"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."planos_modulos"
    ADD CONSTRAINT "planos_modulos_modulo_id_fkey" FOREIGN KEY ("modulo_id") REFERENCES "public"."modulos"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."planos_modulos"
    ADD CONSTRAINT "planos_modulos_plano_id_fkey" FOREIGN KEY ("plano_id") REFERENCES "public"."planos"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."planos"
    ADD CONSTRAINT "planos_produto_id_fkey" FOREIGN KEY ("produto_id") REFERENCES "public"."produtos"("id");



ALTER TABLE ONLY "public"."produtos_user"
    ADD CONSTRAINT "produtos_user_id_user_expandido_fkey" FOREIGN KEY ("id_user_expandido") REFERENCES "public"."user_expandido"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."produtos_user"
    ADD CONSTRAINT "produtos_user_produto_id_fkey" FOREIGN KEY ("produto_id") REFERENCES "public"."produtos"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."produtos_user"
    ADD CONSTRAINT "produtos_user_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "auth"."users"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."questionario_gabarito"
    ADD CONSTRAINT "questionario_gabarito_criado_por_cliente_fkey" FOREIGN KEY ("criado_por_cliente") REFERENCES "public"."user_expandido_cliente"("id") ON DELETE SET NULL;



ALTER TABLE ONLY "public"."questionario_gabarito"
    ADD CONSTRAINT "questionario_gabarito_criado_por_user_clinica_fkey" FOREIGN KEY ("criado_por_user_clinica") REFERENCES "public"."user_expandido_userclinica"("id") ON DELETE SET NULL;



ALTER TABLE ONLY "public"."questionario_gabarito"
    ADD CONSTRAINT "questionario_gabarito_id_questionario_fkey" FOREIGN KEY ("id_questionario") REFERENCES "public"."questionario_modelo"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."questionario_gabarito"
    ADD CONSTRAINT "questionario_gabarito_modificado_por_cliente_fkey" FOREIGN KEY ("modificado_por_cliente") REFERENCES "public"."user_expandido_cliente"("id") ON DELETE SET NULL;



ALTER TABLE ONLY "public"."questionario_gabarito"
    ADD CONSTRAINT "questionario_gabarito_modificado_por_user_clinica_fkey" FOREIGN KEY ("modificado_por_user_clinica") REFERENCES "public"."user_expandido_userclinica"("id") ON DELETE SET NULL;



ALTER TABLE ONLY "public"."questionario_modelo"
    ADD CONSTRAINT "questionario_modelo_criado_por_cliente_fkey" FOREIGN KEY ("criado_por_cliente") REFERENCES "public"."user_expandido_cliente"("id") ON DELETE SET NULL;



ALTER TABLE ONLY "public"."questionario_modelo"
    ADD CONSTRAINT "questionario_modelo_criado_por_user_clinica_fkey" FOREIGN KEY ("criado_por_user_clinica") REFERENCES "public"."user_expandido_userclinica"("id") ON DELETE SET NULL;



ALTER TABLE ONLY "public"."questionario_modelo"
    ADD CONSTRAINT "questionario_modelo_id_clinica_fkey" FOREIGN KEY ("id_clinica") REFERENCES "public"."clinica"("id") ON DELETE SET NULL;



ALTER TABLE ONLY "public"."questionario_modelo"
    ADD CONSTRAINT "questionario_modelo_modificado_por_cliente_fkey" FOREIGN KEY ("modificado_por_cliente") REFERENCES "public"."user_expandido_cliente"("id") ON DELETE SET NULL;



ALTER TABLE ONLY "public"."questionario_modelo"
    ADD CONSTRAINT "questionario_modelo_modificado_por_user_clinica_fkey" FOREIGN KEY ("modificado_por_user_clinica") REFERENCES "public"."user_expandido_userclinica"("id") ON DELETE SET NULL;



ALTER TABLE ONLY "public"."questionario_perguntas"
    ADD CONSTRAINT "questionario_perguntas_criado_por_cliente_fkey" FOREIGN KEY ("criado_por_cliente") REFERENCES "public"."user_expandido_cliente"("id") ON DELETE SET NULL;



ALTER TABLE ONLY "public"."questionario_perguntas"
    ADD CONSTRAINT "questionario_perguntas_criado_por_user_clinica_fkey" FOREIGN KEY ("criado_por_user_clinica") REFERENCES "public"."user_expandido_userclinica"("id") ON DELETE SET NULL;



ALTER TABLE ONLY "public"."questionario_perguntas_grupo"
    ADD CONSTRAINT "questionario_perguntas_grupo_criado_por_cliente_fkey" FOREIGN KEY ("criado_por_cliente") REFERENCES "public"."user_expandido_cliente"("id") ON DELETE SET NULL;



ALTER TABLE ONLY "public"."questionario_perguntas_grupo"
    ADD CONSTRAINT "questionario_perguntas_grupo_criado_por_user_clinica_fkey" FOREIGN KEY ("criado_por_user_clinica") REFERENCES "public"."user_expandido_userclinica"("id") ON DELETE SET NULL;



ALTER TABLE ONLY "public"."questionario_perguntas_grupo"
    ADD CONSTRAINT "questionario_perguntas_grupo_id_questionario_fkey" FOREIGN KEY ("id_questionario") REFERENCES "public"."questionario_modelo"("id");



ALTER TABLE ONLY "public"."questionario_perguntas_grupo"
    ADD CONSTRAINT "questionario_perguntas_grupo_modificado_por_cliente_fkey" FOREIGN KEY ("modificado_por_cliente") REFERENCES "public"."user_expandido_cliente"("id") ON DELETE SET NULL;



ALTER TABLE ONLY "public"."questionario_perguntas_grupo"
    ADD CONSTRAINT "questionario_perguntas_grupo_modificado_por_user_clinica_fkey" FOREIGN KEY ("modificado_por_user_clinica") REFERENCES "public"."user_expandido_userclinica"("id") ON DELETE SET NULL;



ALTER TABLE ONLY "public"."questionario_perguntas"
    ADD CONSTRAINT "questionario_perguntas_id_grupo_fkey" FOREIGN KEY ("id_grupo") REFERENCES "public"."questionario_perguntas_grupo"("id") ON DELETE SET NULL;



ALTER TABLE ONLY "public"."questionario_perguntas"
    ADD CONSTRAINT "questionario_perguntas_id_questionario_fkey" FOREIGN KEY ("id_questionario") REFERENCES "public"."questionario_modelo"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."questionario_perguntas"
    ADD CONSTRAINT "questionario_perguntas_modificado_por_cliente_fkey" FOREIGN KEY ("modificado_por_cliente") REFERENCES "public"."user_expandido_cliente"("id") ON DELETE SET NULL;



ALTER TABLE ONLY "public"."questionario_perguntas"
    ADD CONSTRAINT "questionario_perguntas_modificado_por_user_clinica_fkey" FOREIGN KEY ("modificado_por_user_clinica") REFERENCES "public"."user_expandido_userclinica"("id") ON DELETE SET NULL;



ALTER TABLE ONLY "public"."questionario_respostas"
    ADD CONSTRAINT "questionario_respostas_criado_por_cliente_fkey" FOREIGN KEY ("criado_por_cliente") REFERENCES "public"."user_expandido_cliente"("id") ON DELETE SET NULL;



ALTER TABLE ONLY "public"."questionario_respostas"
    ADD CONSTRAINT "questionario_respostas_criado_por_user_clinica_fkey" FOREIGN KEY ("criado_por_user_clinica") REFERENCES "public"."user_expandido_userclinica"("id") ON DELETE SET NULL;



ALTER TABLE ONLY "public"."questionario_respostas"
    ADD CONSTRAINT "questionario_respostas_id_pergunta_fkey" FOREIGN KEY ("id_pergunta") REFERENCES "public"."questionario_perguntas"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."questionario_respostas"
    ADD CONSTRAINT "questionario_respostas_id_questionario_fkey" FOREIGN KEY ("id_questionario") REFERENCES "public"."questionario_modelo"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."questionario_respostas"
    ADD CONSTRAINT "questionario_respostas_modificado_por_cliente_fkey" FOREIGN KEY ("modificado_por_cliente") REFERENCES "public"."user_expandido_cliente"("id") ON DELETE SET NULL;



ALTER TABLE ONLY "public"."questionario_respostas"
    ADD CONSTRAINT "questionario_respostas_modificado_por_user_clinica_fkey" FOREIGN KEY ("modificado_por_user_clinica") REFERENCES "public"."user_expandido_userclinica"("id") ON DELETE SET NULL;



ALTER TABLE ONLY "public"."respostas_user"
    ADD CONSTRAINT "respostas_user_id_clinica_fkey" FOREIGN KEY ("id_clinica") REFERENCES "public"."clinica"("id") ON DELETE SET NULL;



ALTER TABLE ONLY "public"."respostas_user"
    ADD CONSTRAINT "respostas_user_id_pergunta_fkey" FOREIGN KEY ("id_pergunta") REFERENCES "public"."perguntas_user"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."respostas_user"
    ADD CONSTRAINT "respostas_user_id_user_fkey" FOREIGN KEY ("id_user") REFERENCES "public"."user_expandido"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."user_expandido_admin"
    ADD CONSTRAINT "user_expandido_admin_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "auth"."users"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."user_expandido_cliente"
    ADD CONSTRAINT "user_expandido_cliente_clinica_fkey" FOREIGN KEY ("clinica_id") REFERENCES "public"."clinica"("id") ON DELETE SET NULL;



ALTER TABLE ONLY "public"."user_expandido_cliente"
    ADD CONSTRAINT "user_expandido_cliente_plano_id_fkey" FOREIGN KEY ("plano_id") REFERENCES "public"."planos"("id") ON DELETE SET NULL;



ALTER TABLE ONLY "public"."user_expandido_colaboradores"
    ADD CONSTRAINT "user_expandido_colaboradores_clinica_id_fkey" FOREIGN KEY ("clinica_id") REFERENCES "public"."clinica"("id") ON DELETE SET NULL;



ALTER TABLE ONLY "public"."user_expandido_colaboradores"
    ADD CONSTRAINT "user_expandido_colaboradores_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "auth"."users"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."user_expandido_cliente"
    ADD CONSTRAINT "user_expandido_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "auth"."users"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."user_expandido"
    ADD CONSTRAINT "user_expandido_user_id_fkey1" FOREIGN KEY ("user_id") REFERENCES "auth"."users"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."user_expandido_userclinica"
    ADD CONSTRAINT "user_expandido_userclinica_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "auth"."users"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."user_role_auth"
    ADD CONSTRAINT "user_role_auth_clinica_id_fkey" FOREIGN KEY ("clinica_id") REFERENCES "public"."clinica"("id") ON DELETE SET NULL;



ALTER TABLE ONLY "public"."user_role_auth"
    ADD CONSTRAINT "user_role_auth_role_id_fkey" FOREIGN KEY ("role_id") REFERENCES "public"."role_auth"("id") ON DELETE SET NULL;



ALTER TABLE ONLY "public"."user_role_auth"
    ADD CONSTRAINT "user_role_auth_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "auth"."users"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."user_expandido_paciente"
    ADD CONSTRAINT "usuario_expandido_paciente_clinica_fkey" FOREIGN KEY ("id_clinica") REFERENCES "public"."clinica"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."videos"
    ADD CONSTRAINT "videos_categoria_id_fkey" FOREIGN KEY ("categoria_id") REFERENCES "public"."videos_categorias"("id") ON DELETE SET NULL;



ALTER TABLE ONLY "public"."videos_grupos_rel_videos"
    ADD CONSTRAINT "videos_grupos_rel_videos_grupo_id_fkey" FOREIGN KEY ("grupo_id") REFERENCES "public"."videos_grupos"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."videos_grupos_rel_videos"
    ADD CONSTRAINT "videos_grupos_rel_videos_video_id_fkey" FOREIGN KEY ("video_id") REFERENCES "public"."videos"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."videos_habilidades_rel_videos"
    ADD CONSTRAINT "videos_habilidades_rel_videos_habilidade_id_fkey" FOREIGN KEY ("habilidade_id") REFERENCES "public"."videos_habilidades"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."videos_habilidades_rel_videos"
    ADD CONSTRAINT "videos_habilidades_rel_videos_video_id_fkey" FOREIGN KEY ("video_id") REFERENCES "public"."videos"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."videos"
    ADD CONSTRAINT "videos_reabilitacao_id_fkey" FOREIGN KEY ("reabilitacao_id") REFERENCES "public"."reabilitacoes"("id") ON DELETE CASCADE;



CREATE POLICY "Admin pode acessar/modificar tudo" ON "public"."controle_pareamento" TO "authenticated" USING ((("auth"."jwt"() ->> 'user_role'::"text") = 'admin'::"text")) WITH CHECK ((("auth"."jwt"() ->> 'user_role'::"text") = 'admin'::"text"));



CREATE POLICY "Admin pode tudo" ON "public"."anamnese" USING ((("auth"."jwt"() ->> 'user_role'::"text") = 'admin'::"text")) WITH CHECK ((("auth"."jwt"() ->> 'user_role'::"text") = 'admin'::"text"));



CREATE POLICY "Admin pode tudo" ON "public"."anamnese_resposta" USING ((("auth"."jwt"() ->> 'user_role'::"text") = 'admin'::"text")) WITH CHECK ((("auth"."jwt"() ->> 'user_role'::"text") = 'admin'::"text"));



CREATE POLICY "Admin pode tudo" ON "public"."arquivos_pacientes" USING ((("auth"."jwt"() ->> 'user_role'::"text") = 'admin'::"text")) WITH CHECK ((("auth"."jwt"() ->> 'user_role'::"text") = 'admin'::"text"));



CREATE POLICY "Admin pode tudo" ON "public"."atendimentos" USING ((("auth"."jwt"() ->> 'user_role'::"text") = 'admin'::"text"));



CREATE POLICY "Admin pode tudo" ON "public"."cliente_contrato" TO "authenticated" USING ((("auth"."jwt"() ->> 'user_role'::"text") = 'admin'::"text")) WITH CHECK ((("auth"."jwt"() ->> 'user_role'::"text") = 'admin'::"text"));



CREATE POLICY "Admin pode tudo" ON "public"."cliente_pagamento_contrato" TO "authenticated" USING ((("auth"."jwt"() ->> 'user_role'::"text") = 'admin'::"text")) WITH CHECK ((("auth"."jwt"() ->> 'user_role'::"text") = 'admin'::"text"));



CREATE POLICY "Admin pode tudo" ON "public"."clinica" TO "authenticated" USING ((("auth"."jwt"() ->> 'user_role'::"text") = 'admin'::"text")) WITH CHECK ((("auth"."jwt"() ->> 'user_role'::"text") = 'admin'::"text"));



CREATE POLICY "Admin pode tudo" ON "public"."clinica_user" TO "authenticated" USING ((("auth"."jwt"() ->> 'user_role'::"text") = 'admin'::"text")) WITH CHECK ((("auth"."jwt"() ->> 'user_role'::"text") = 'admin'::"text"));



CREATE POLICY "Admin pode tudo" ON "public"."crm" TO "authenticated" USING ((("auth"."jwt"() ->> 'user_role'::"text") = 'admin'::"text")) WITH CHECK ((("auth"."jwt"() ->> 'user_role'::"text") = 'admin'::"text"));



CREATE POLICY "Admin pode tudo" ON "public"."modulos" TO "authenticated" USING ((("auth"."jwt"() ->> 'user_role'::"text") = 'admin'::"text")) WITH CHECK ((("auth"."jwt"() ->> 'user_role'::"text") = 'admin'::"text"));



CREATE POLICY "Admin pode tudo" ON "public"."oto_condicoes_exame_paciente" TO "authenticated" USING ((("auth"."jwt"() ->> 'user_role'::"text") = 'admin'::"text")) WITH CHECK ((("auth"."jwt"() ->> 'user_role'::"text") = 'admin'::"text"));



CREATE POLICY "Admin pode tudo" ON "public"."oto_exames" TO "authenticated" USING ((("auth"."jwt"() ->> 'user_role'::"text") = 'admin'::"text")) WITH CHECK ((("auth"."jwt"() ->> 'user_role'::"text") = 'admin'::"text"));



CREATE POLICY "Admin pode tudo" ON "public"."planos" TO "authenticated" USING ((("auth"."jwt"() ->> 'user_role'::"text") = 'admin'::"text")) WITH CHECK ((("auth"."jwt"() ->> 'user_role'::"text") = 'admin'::"text"));



CREATE POLICY "Admin pode tudo" ON "public"."planos_modulos" TO "authenticated" USING ((("auth"."jwt"() ->> 'user_role'::"text") = 'admin'::"text")) WITH CHECK ((("auth"."jwt"() ->> 'user_role'::"text") = 'admin'::"text"));



CREATE POLICY "Admin pode tudo" ON "public"."planos_modulos_limites" TO "authenticated" USING ((("auth"."jwt"() ->> 'user_role'::"text") = 'admin'::"text")) WITH CHECK ((("auth"."jwt"() ->> 'user_role'::"text") = 'admin'::"text"));



CREATE POLICY "Admin pode tudo" ON "public"."produtos_user" TO "authenticated" USING ((("auth"."jwt"() ->> 'user_role'::"text") = 'admin'::"text")) WITH CHECK ((("auth"."jwt"() ->> 'user_role'::"text") = 'admin'::"text"));



CREATE POLICY "Admin pode tudo" ON "public"."reabilitacoes" TO "authenticated" USING ((("auth"."jwt"() ->> 'user_role'::"text") = 'admin'::"text")) WITH CHECK ((("auth"."jwt"() ->> 'user_role'::"text") = 'admin'::"text"));



CREATE POLICY "Admin pode tudo" ON "public"."user_expandido" TO "authenticated" USING ((("auth"."jwt"() ->> 'user_role'::"text") = 'admin'::"text")) WITH CHECK ((("auth"."jwt"() ->> 'user_role'::"text") = 'admin'::"text"));



CREATE POLICY "Admin pode tudo" ON "public"."user_expandido_admin" TO "authenticated" USING ((("auth"."jwt"() ->> 'user_role'::"text") = 'admin'::"text")) WITH CHECK ((("auth"."jwt"() ->> 'user_role'::"text") = 'admin'::"text"));



CREATE POLICY "Admin pode tudo" ON "public"."user_expandido_cliente" TO "authenticated" USING ((("auth"."jwt"() ->> 'user_role'::"text") = 'admin'::"text")) WITH CHECK ((("auth"."jwt"() ->> 'user_role'::"text") = 'admin'::"text"));



CREATE POLICY "Admin pode tudo" ON "public"."user_expandido_colaboradores" TO "authenticated" USING ((("auth"."jwt"() ->> 'user_role'::"text") = 'admin'::"text")) WITH CHECK ((("auth"."jwt"() ->> 'user_role'::"text") = 'admin'::"text"));



CREATE POLICY "Admin pode tudo" ON "public"."user_expandido_paciente_detalhes" USING ((("auth"."jwt"() ->> 'user_role'::"text") = 'admin'::"text"));



CREATE POLICY "Admin pode tudo" ON "public"."user_expandido_userclinica" TO "authenticated" USING ((("auth"."jwt"() ->> 'user_role'::"text") = 'admin'::"text"));



CREATE POLICY "Admin pode tudo" ON "public"."videos" TO "authenticated" USING ((("auth"."jwt"() ->> 'user_role'::"text") = 'admin'::"text")) WITH CHECK ((("auth"."jwt"() ->> 'user_role'::"text") = 'admin'::"text"));



CREATE POLICY "Admin pode tudo" ON "public"."videos_categorias" TO "authenticated" USING ((("auth"."jwt"() ->> 'user_role'::"text") = 'admin'::"text")) WITH CHECK ((("auth"."jwt"() ->> 'user_role'::"text") = 'admin'::"text"));



CREATE POLICY "Admin pode tudo" ON "public"."videos_grupos" TO "authenticated" USING ((("auth"."jwt"() ->> 'user_role'::"text") = 'admin'::"text")) WITH CHECK ((("auth"."jwt"() ->> 'user_role'::"text") = 'admin'::"text"));



CREATE POLICY "Admin pode tudo" ON "public"."videos_grupos_rel_videos" TO "authenticated" USING ((("auth"."jwt"() ->> 'user_role'::"text") = 'admin'::"text")) WITH CHECK ((("auth"."jwt"() ->> 'user_role'::"text") = 'admin'::"text"));



CREATE POLICY "Admin pode tudo" ON "public"."videos_habilidades" TO "authenticated" USING ((("auth"."jwt"() ->> 'user_role'::"text") = 'admin'::"text")) WITH CHECK ((("auth"."jwt"() ->> 'user_role'::"text") = 'admin'::"text"));



CREATE POLICY "Admin pode tudo" ON "public"."videos_habilidades_rel_videos" TO "authenticated" USING ((("auth"."jwt"() ->> 'user_role'::"text") = 'admin'::"text")) WITH CHECK ((("auth"."jwt"() ->> 'user_role'::"text") = 'admin'::"text"));



CREATE POLICY "Admin pode tudo em exame_sistema" ON "public"."exame_sistema" TO "authenticated" USING ((("auth"."jwt"() ->> 'user_role'::"text") = 'admin'::"text")) WITH CHECK ((("auth"."jwt"() ->> 'user_role'::"text") = 'admin'::"text"));



CREATE POLICY "Admin pode tudo em exame_subtipo" ON "public"."exame_subtipo" TO "authenticated" USING ((("auth"."jwt"() ->> 'user_role'::"text") = 'admin'::"text")) WITH CHECK ((("auth"."jwt"() ->> 'user_role'::"text") = 'admin'::"text"));



CREATE POLICY "Admin pode tudo em exame_tipo" ON "public"."exame_tipo" TO "authenticated" USING ((("auth"."jwt"() ->> 'user_role'::"text") = 'admin'::"text")) WITH CHECK ((("auth"."jwt"() ->> 'user_role'::"text") = 'admin'::"text"));



CREATE POLICY "Admin pode tudo em questionario_gabarito" ON "public"."questionario_gabarito" TO "authenticated" USING ((("auth"."jwt"() ->> 'user_role'::"text") = 'admin'::"text")) WITH CHECK ((("auth"."jwt"() ->> 'user_role'::"text") = 'admin'::"text"));



CREATE POLICY "Admin pode tudo em questionario_modelo" ON "public"."questionario_modelo" TO "authenticated" USING ((("auth"."jwt"() ->> 'user_role'::"text") = 'admin'::"text")) WITH CHECK ((("auth"."jwt"() ->> 'user_role'::"text") = 'admin'::"text"));



CREATE POLICY "Admin pode tudo em questionario_perguntas" ON "public"."questionario_perguntas" TO "authenticated" USING ((("auth"."jwt"() ->> 'user_role'::"text") = 'admin'::"text")) WITH CHECK ((("auth"."jwt"() ->> 'user_role'::"text") = 'admin'::"text"));



CREATE POLICY "Admin pode tudo em questionario_perguntas_grupo" ON "public"."questionario_perguntas_grupo" TO "authenticated" USING ((("auth"."jwt"() ->> 'user_role'::"text") = 'admin'::"text")) WITH CHECK ((("auth"."jwt"() ->> 'user_role'::"text") = 'admin'::"text"));



CREATE POLICY "Admin pode tudo em questionario_respostas" ON "public"."questionario_respostas" TO "authenticated" USING ((("auth"."jwt"() ->> 'user_role'::"text") = 'admin'::"text")) WITH CHECK ((("auth"."jwt"() ->> 'user_role'::"text") = 'admin'::"text"));



CREATE POLICY "Admin pode tudo nas respostas" ON "public"."respostas_user" TO "authenticated" USING ((("auth"."jwt"() ->> 'user_role'::"text") = 'admin'::"text")) WITH CHECK ((("auth"."jwt"() ->> 'user_role'::"text") = 'admin'::"text"));



CREATE POLICY "Admin pode tudo_deletar_depois" ON "public"."reabilitacao_exercicios" TO "authenticated" USING ((("auth"."jwt"() ->> 'user_role'::"text") = 'admin'::"text")) WITH CHECK ((("auth"."jwt"() ->> 'user_role'::"text") = 'admin'::"text"));



CREATE POLICY "Admin pode tudo_deletar_depois" ON "public"."reabilitacao_exercicios_videos" TO "authenticated" USING ((("auth"."jwt"() ->> 'user_role'::"text") = 'admin'::"text")) WITH CHECK ((("auth"."jwt"() ->> 'user_role'::"text") = 'admin'::"text"));



CREATE POLICY "Admin pode tudo_deletar_depois" ON "public"."user_expandido_paciente" TO "authenticated" USING ((("auth"."jwt"() ->> 'user_role'::"text") = 'admin'::"text")) WITH CHECK ((("auth"."jwt"() ->> 'user_role'::"text") = 'admin'::"text"));



CREATE POLICY "Admin pode ver apenas globais" ON "public"."anamnese_modelo" FOR SELECT TO "authenticated" USING (((("auth"."jwt"() ->> 'user_role'::"text") = 'admin'::"text") AND ("global" IS TRUE)));



CREATE POLICY "Admin pode ver perguntas apenas se modelo for global" ON "public"."anamnese_pergunta" FOR SELECT TO "authenticated" USING (((("auth"."jwt"() ->> 'role_user'::"text") = 'admin'::"text") AND (EXISTS ( SELECT 1
   FROM "public"."anamnese_modelo" "am"
  WHERE (("am"."id" = "anamnese_pergunta"."id_anamnese_modelo") AND ("am"."global" = true))))));



CREATE POLICY "Admin pode ver perguntas apenas se modelo for global" ON "public"."exame_pergunta" FOR SELECT TO "authenticated" USING (((("auth"."jwt"() ->> 'role_user'::"text") = 'admin'::"text") AND (EXISTS ( SELECT 1
   FROM "public"."exame_modelo" "em"
  WHERE (("em"."id" = "exame_pergunta"."id_modelo") AND ("em"."global" = true))))));



CREATE POLICY "Admin via JWT pode inserir user_role_auth" ON "public"."user_role_auth" FOR INSERT TO "authenticated" WITH CHECK ((("auth"."jwt"() ->> 'user_role'::"text") = 'admin'::"text"));



CREATE POLICY "Admin vê seu próprio user_role_auth" ON "public"."user_role_auth" FOR SELECT TO "authenticated" USING (((("auth"."jwt"() ->> 'user_role'::"text") = 'admin'::"text") AND ("user_id" = "auth"."uid"())));



CREATE POLICY "Anon pode inserir lead" ON "public"."crm" FOR INSERT TO "anon" WITH CHECK (true);



CREATE POLICY "Cliente e Clinica podem acessar apenas dados da própria clíni" ON "public"."anamnese" USING (((("auth"."jwt"() ->> 'user_role'::"text") = ANY (ARRAY['cliente'::"text", 'clinica'::"text"])) AND ("id_clinica" = (("auth"."jwt"() ->> 'clinica_id'::"text"))::"uuid"))) WITH CHECK (((("auth"."jwt"() ->> 'user_role'::"text") = ANY (ARRAY['cliente'::"text", 'clinica'::"text"])) AND ("id_clinica" = (("auth"."jwt"() ->> 'clinica_id'::"text"))::"uuid")));



CREATE POLICY "Cliente e Clinica podem acessar apenas dados da própria clíni" ON "public"."anamnese_modelo" TO "authenticated" USING (((("auth"."jwt"() ->> 'user_role'::"text") = ANY (ARRAY['cliente'::"text", 'clinica'::"text"])) AND ("id_clinica" = (("auth"."jwt"() ->> 'clinica_id'::"text"))::"uuid"))) WITH CHECK (((("auth"."jwt"() ->> 'user_role'::"text") = ANY (ARRAY['cliente'::"text", 'clinica'::"text"])) AND ("id_clinica" = (("auth"."jwt"() ->> 'clinica_id'::"text"))::"uuid")));



CREATE POLICY "Cliente e Clinica podem acessar apenas dados da própria clíni" ON "public"."anamnese_resposta" USING (((("auth"."jwt"() ->> 'user_role'::"text") = ANY (ARRAY['cliente'::"text", 'clinica'::"text"])) AND ("id_clinica" = (("auth"."jwt"() ->> 'clinica_id'::"text"))::"uuid"))) WITH CHECK (((("auth"."jwt"() ->> 'user_role'::"text") = ANY (ARRAY['cliente'::"text", 'clinica'::"text"])) AND ("id_clinica" = (("auth"."jwt"() ->> 'clinica_id'::"text"))::"uuid")));



CREATE POLICY "Cliente e Clinica podem acessar apenas dados da própria clíni" ON "public"."arquivos_pacientes" USING (((("auth"."jwt"() ->> 'user_role'::"text") = ANY (ARRAY['cliente'::"text", 'clinica'::"text"])) AND ("id_clinica" = (("auth"."jwt"() ->> 'clinica_id'::"text"))::"uuid"))) WITH CHECK (((("auth"."jwt"() ->> 'user_role'::"text") = ANY (ARRAY['cliente'::"text", 'clinica'::"text"])) AND ("id_clinica" = (("auth"."jwt"() ->> 'clinica_id'::"text"))::"uuid")));



CREATE POLICY "Cliente e Clínica podem gerenciar modelos da própria clínica" ON "public"."exame_modelo" TO "authenticated" USING (((("auth"."jwt"() ->> 'user_role'::"text") = ANY (ARRAY['cliente'::"text", 'clinica'::"text"])) AND ("id_clinica" = (("auth"."jwt"() ->> 'clinica_id'::"text"))::"uuid"))) WITH CHECK (((("auth"."jwt"() ->> 'user_role'::"text") = ANY (ARRAY['cliente'::"text", 'clinica'::"text"])) AND ("id_clinica" = (("auth"."jwt"() ->> 'clinica_id'::"text"))::"uuid")));



CREATE POLICY "Cliente e Clínica podem gerenciar modelos da própria clínica" ON "public"."questionario_modelo" TO "authenticated" USING (((("auth"."jwt"() ->> 'user_role'::"text") = ANY (ARRAY['cliente'::"text", 'clinica'::"text"])) AND ("id_clinica" = (("auth"."jwt"() ->> 'clinica_id'::"text"))::"uuid"))) WITH CHECK (((("auth"."jwt"() ->> 'user_role'::"text") = ANY (ARRAY['cliente'::"text", 'clinica'::"text"])) AND ("id_clinica" = (("auth"."jwt"() ->> 'clinica_id'::"text"))::"uuid")));



CREATE POLICY "Cliente e Clínica podem gerenciar perguntas dos modelos da pr" ON "public"."exame_pergunta" TO "authenticated" USING ((EXISTS ( SELECT 1
   FROM "public"."exame_modelo" "em"
  WHERE (("em"."id" = "exame_pergunta"."id_modelo") AND ("em"."id_clinica" = (("auth"."jwt"() ->> 'clinica_id'::"text"))::"uuid"))))) WITH CHECK ((EXISTS ( SELECT 1
   FROM "public"."exame_modelo" "em"
  WHERE (("em"."id" = "exame_pergunta"."id_modelo") AND ("em"."id_clinica" = (("auth"."jwt"() ->> 'clinica_id'::"text"))::"uuid")))));



CREATE POLICY "Cliente e Clínica podem gerenciar respostas possíveis de perg" ON "public"."exame_respostas_possiveis" TO "authenticated" USING ((EXISTS ( SELECT 1
   FROM ("public"."exame_pergunta" "ep"
     JOIN "public"."exame_modelo" "em" ON (("em"."id" = "ep"."id_modelo")))
  WHERE (("ep"."id" = "exame_respostas_possiveis"."id_pergunta") AND ("em"."id_clinica" = (("auth"."jwt"() ->> 'clinica_id'::"text"))::"uuid"))))) WITH CHECK ((EXISTS ( SELECT 1
   FROM ("public"."exame_pergunta" "ep"
     JOIN "public"."exame_modelo" "em" ON (("em"."id" = "ep"."id_modelo")))
  WHERE (("ep"."id" = "exame_respostas_possiveis"."id_pergunta") AND ("em"."id_clinica" = (("auth"."jwt"() ->> 'clinica_id'::"text"))::"uuid")))));



CREATE POLICY "Cliente e Clínica podem gerenciar valores de referência de pe" ON "public"."exame_valores_referencia" TO "authenticated" USING ((EXISTS ( SELECT 1
   FROM ("public"."exame_pergunta" "ep"
     JOIN "public"."exame_modelo" "em" ON (("em"."id" = "ep"."id_modelo")))
  WHERE (("ep"."id" = "exame_valores_referencia"."id_pergunta") AND ("em"."id_clinica" = (("auth"."jwt"() ->> 'clinica_id'::"text"))::"uuid"))))) WITH CHECK ((EXISTS ( SELECT 1
   FROM ("public"."exame_pergunta" "ep"
     JOIN "public"."exame_modelo" "em" ON (("em"."id" = "ep"."id_modelo")))
  WHERE (("ep"."id" = "exame_valores_referencia"."id_pergunta") AND ("em"."id_clinica" = (("auth"."jwt"() ->> 'clinica_id'::"text"))::"uuid")))));



CREATE POLICY "Cliente e Clínica podem ver modelos globais" ON "public"."anamnese_modelo" FOR SELECT TO "authenticated" USING (((("auth"."jwt"() ->> 'user_role'::"text") = ANY (ARRAY['cliente'::"text", 'clinica'::"text"])) AND ("global" = true)));



CREATE POLICY "Cliente e Clínica podem ver modelos globais" ON "public"."exame_modelo" FOR SELECT TO "authenticated" USING (((("auth"."jwt"() ->> 'user_role'::"text") = ANY (ARRAY['cliente'::"text", 'clinica'::"text"])) AND ("global" = true)));



CREATE POLICY "Cliente e Clínica podem ver perguntas de modelos globais" ON "public"."exame_pergunta" FOR SELECT TO "authenticated" USING ((EXISTS ( SELECT 1
   FROM "public"."exame_modelo" "em"
  WHERE (("em"."id" = "exame_pergunta"."id_modelo") AND ("em"."global" = true)))));



CREATE POLICY "Cliente e Clínica podem ver respostas possíveis de perguntas " ON "public"."exame_respostas_possiveis" FOR SELECT TO "authenticated" USING ((EXISTS ( SELECT 1
   FROM ("public"."exame_pergunta" "ep"
     JOIN "public"."exame_modelo" "em" ON (("em"."id" = "ep"."id_modelo")))
  WHERE (("ep"."id" = "exame_respostas_possiveis"."id_pergunta") AND ("em"."global" = true)))));



CREATE POLICY "Cliente e Clínica podem ver valores de referência de pergunta" ON "public"."exame_valores_referencia" FOR SELECT TO "authenticated" USING ((EXISTS ( SELECT 1
   FROM ("public"."exame_pergunta" "ep"
     JOIN "public"."exame_modelo" "em" ON (("em"."id" = "ep"."id_modelo")))
  WHERE (("ep"."id" = "exame_valores_referencia"."id_pergunta") AND ("em"."global" = true)))));



CREATE POLICY "Cliente gerencia vídeos da sua clínica" ON "public"."reabilitacao_exercicios_videos" TO "authenticated" USING (((("auth"."jwt"() ->> 'user_role'::"text") = 'cliente'::"text") AND (EXISTS ( SELECT 1
   FROM ("public"."reabilitacao_exercicios" "re"
     JOIN "public"."user_expandido_cliente" "uec" ON (("uec"."clinica_id" = "re"."id_clinica")))
  WHERE (("re"."id" = "reabilitacao_exercicios_videos"."id_reabilitacao_exercicio") AND ("uec"."user_id" = "auth"."uid"())))))) WITH CHECK (((("auth"."jwt"() ->> 'user_role'::"text") = 'cliente'::"text") AND (EXISTS ( SELECT 1
   FROM ("public"."reabilitacao_exercicios" "re"
     JOIN "public"."user_expandido_cliente" "uec" ON (("uec"."clinica_id" = "re"."id_clinica")))
  WHERE (("re"."id" = "reabilitacao_exercicios_videos"."id_reabilitacao_exercicio") AND ("uec"."user_id" = "auth"."uid"()))))));



CREATE POLICY "Cliente pode criar colaboradores" ON "public"."user_expandido_colaboradores" FOR INSERT TO "authenticated" WITH CHECK (((("auth"."jwt"() ->> 'user_role'::"text") = 'cliente'::"text") AND ((("auth"."jwt"() ->> 'clinica_id'::"text"))::"uuid" = ((("current_setting"('request.jwt.claims'::"text", true))::"jsonb" ->> 'clinica_id'::"text"))::"uuid")));



CREATE POLICY "Cliente pode criar paciente na sua clínica" ON "public"."user_expandido_paciente" TO "authenticated" WITH CHECK (((("auth"."jwt"() ->> 'user_role'::"text") = 'cliente'::"text") AND ("id_clinica" = (("auth"."jwt"() ->> 'clinica_id'::"text"))::"uuid")));



CREATE POLICY "Cliente pode criar userClinica na sua clínica" ON "public"."user_expandido_userclinica" FOR INSERT TO "authenticated" WITH CHECK (((("auth"."jwt"() ->> 'user_role'::"text") = 'cliente'::"text") AND ("clinica_id" = (("auth"."jwt"() ->> 'clinica_id'::"text"))::"uuid")));



CREATE POLICY "Cliente pode criar user_role_auth na sua clínica" ON "public"."user_role_auth" FOR INSERT TO "authenticated" WITH CHECK (((("auth"."jwt"() ->> 'user_role'::"text") = 'cliente'::"text") AND ((("auth"."jwt"() ->> 'clinica_id'::"text"))::"uuid" = ((("current_setting"('request.jwt.claims'::"text", true))::"jsonb" ->> 'clinica_id'::"text"))::"uuid")));



CREATE POLICY "Cliente pode editar a si mesmo" ON "public"."user_expandido_cliente" FOR UPDATE TO "authenticated" USING (((("auth"."jwt"() ->> 'user_role'::"text") = 'cliente'::"text") AND ("user_id" = "auth"."uid"()))) WITH CHECK (((("auth"."jwt"() ->> 'user_role'::"text") = 'cliente'::"text") AND ("user_id" = "auth"."uid"())));



CREATE POLICY "Cliente pode editar colaboradores" ON "public"."user_expandido_colaboradores" FOR UPDATE TO "authenticated" USING (((("auth"."jwt"() ->> 'user_role'::"text") = 'cliente'::"text") AND ("clinica_id" = (("auth"."jwt"() ->> 'clinica_id'::"text"))::"uuid"))) WITH CHECK (((("auth"."jwt"() ->> 'user_role'::"text") = 'cliente'::"text") AND ("clinica_id" = (("auth"."jwt"() ->> 'clinica_id'::"text"))::"uuid")));



CREATE POLICY "Cliente pode editar paciente da sua clínica" ON "public"."user_expandido_paciente" TO "authenticated" WITH CHECK (((("auth"."jwt"() ->> 'user_role'::"text") = 'cliente'::"text") AND ("id_clinica" = (("auth"."jwt"() ->> 'clinica_id'::"text"))::"uuid")));



CREATE POLICY "Cliente pode editar userClinica da sua clínica" ON "public"."user_expandido_userclinica" FOR UPDATE TO "authenticated" USING (((("auth"."jwt"() ->> 'user_role'::"text") = 'cliente'::"text") AND ("clinica_id" = (("auth"."jwt"() ->> 'clinica_id'::"text"))::"uuid"))) WITH CHECK (((("auth"."jwt"() ->> 'user_role'::"text") = 'cliente'::"text") AND ("clinica_id" = (("auth"."jwt"() ->> 'clinica_id'::"text"))::"uuid")));



CREATE POLICY "Cliente pode gerenciar exercícios da própria clínica" ON "public"."reabilitacao_exercicios" TO "authenticated" USING (((("auth"."jwt"() ->> 'user_role'::"text") = 'cliente'::"text") AND (EXISTS ( SELECT 1
   FROM "public"."user_expandido_cliente" "uec"
  WHERE (("uec"."user_id" = "auth"."uid"()) AND ("uec"."clinica_id" = "reabilitacao_exercicios"."id_clinica")))))) WITH CHECK (((("auth"."jwt"() ->> 'user_role'::"text") = 'cliente'::"text") AND (EXISTS ( SELECT 1
   FROM "public"."user_expandido_cliente" "uec"
  WHERE (("uec"."user_id" = "auth"."uid"()) AND ("uec"."clinica_id" = "reabilitacao_exercicios"."id_clinica"))))));



CREATE POLICY "Cliente pode gerenciar sua clínica" ON "public"."clinica" TO "authenticated" USING (((("auth"."jwt"() ->> 'user_role'::"text") = 'cliente'::"text") AND (EXISTS ( SELECT 1
   FROM "public"."user_expandido_cliente" "uec"
  WHERE (("uec"."user_id" = "auth"."uid"()) AND ("uec"."clinica_id" = "clinica"."id")))))) WITH CHECK (((("auth"."jwt"() ->> 'user_role'::"text") = 'cliente'::"text") AND (EXISTS ( SELECT 1
   FROM "public"."user_expandido_cliente" "uec"
  WHERE (("uec"."user_id" = "auth"."uid"()) AND ("uec"."clinica_id" = "clinica"."id"))))));



CREATE POLICY "Cliente pode ver" ON "public"."videos_grupos_rel_videos" FOR SELECT TO "authenticated" USING ((("auth"."jwt"() ->> 'user_role'::"text") = 'cliente'::"text"));



CREATE POLICY "Cliente pode ver" ON "public"."videos_habilidades_rel_videos" FOR SELECT TO "authenticated" USING ((("auth"."jwt"() ->> 'user_role'::"text") = 'cliente'::"text"));



CREATE POLICY "Cliente pode ver a si mesmo" ON "public"."user_expandido_cliente" FOR SELECT TO "authenticated" USING (((("auth"."jwt"() ->> 'user_role'::"text") = 'cliente'::"text") AND (("user_id")::"text" = ("auth"."uid"())::"text")));



CREATE POLICY "Cliente pode ver categorias" ON "public"."videos_categorias" FOR SELECT TO "authenticated" USING ((("auth"."jwt"() ->> 'user_role'::"text") = 'cliente'::"text"));



CREATE POLICY "Cliente pode ver colaboradores da sua clínica" ON "public"."user_expandido_colaboradores" FOR SELECT TO "authenticated" USING (((("auth"."jwt"() ->> 'user_role'::"text") = 'cliente'::"text") AND ("clinica_id" = (("auth"."jwt"() ->> 'clinica_id'::"text"))::"uuid")));



CREATE POLICY "Cliente pode ver grupos" ON "public"."videos_grupos" FOR SELECT TO "authenticated" USING ((("auth"."jwt"() ->> 'user_role'::"text") = 'cliente'::"text"));



CREATE POLICY "Cliente pode ver habilidades" ON "public"."videos_habilidades" FOR SELECT TO "authenticated" USING ((("auth"."jwt"() ->> 'user_role'::"text") = 'cliente'::"text"));



CREATE POLICY "Cliente pode ver paciente da sua clínica" ON "public"."user_expandido_paciente" TO "authenticated" USING (((("auth"."jwt"() ->> 'user_role'::"text") = 'cliente'::"text") AND ("id_clinica" = (("auth"."jwt"() ->> 'clinica_id'::"text"))::"uuid")));



CREATE POLICY "Cliente pode ver seus contratos" ON "public"."cliente_contrato" FOR SELECT TO "authenticated" USING (((("auth"."jwt"() ->> 'user_role'::"text") = 'cliente'::"text") AND ("id_cliente" = (("auth"."jwt"() ->> 'user_id'::"text"))::"uuid")));



CREATE POLICY "Cliente pode ver seus próprios produtos" ON "public"."produtos_user" FOR SELECT TO "authenticated" USING ((("user_id" = "auth"."uid"()) AND (("auth"."jwt"() ->> 'user_role'::"text") = 'cliente'::"text")));



CREATE POLICY "Cliente pode ver suas linhas" ON "public"."produtos_user" FOR SELECT TO "authenticated" USING (((("auth"."jwt"() ->> 'user_role'::"text") = 'cliente'::"text") AND ("user_id" = "auth"."uid"())));



CREATE POLICY "Cliente pode ver todas" ON "public"."reabilitacoes" FOR SELECT TO "authenticated" USING ((("auth"."jwt"() ->> 'user_role'::"text") = 'cliente'::"text"));



CREATE POLICY "Cliente pode ver todos" ON "public"."modulos" FOR SELECT TO "authenticated" USING ((("auth"."jwt"() ->> 'user_role'::"text") = 'cliente'::"text"));



CREATE POLICY "Cliente pode ver todos" ON "public"."planos" FOR SELECT TO "authenticated" USING ((("auth"."jwt"() ->> 'user_role'::"text") = 'cliente'::"text"));



CREATE POLICY "Cliente pode ver todos" ON "public"."planos_modulos" FOR SELECT TO "authenticated" USING ((("auth"."jwt"() ->> 'user_role'::"text") = 'cliente'::"text"));



CREATE POLICY "Cliente pode ver todos" ON "public"."planos_modulos_limites" FOR SELECT TO "authenticated" USING ((("auth"."jwt"() ->> 'user_role'::"text") = 'cliente'::"text"));



CREATE POLICY "Cliente pode ver userClinica da sua clínica" ON "public"."user_expandido_userclinica" FOR SELECT TO "authenticated" USING (((("auth"."jwt"() ->> 'user_role'::"text") = 'cliente'::"text") AND ("clinica_id" = (("auth"."jwt"() ->> 'clinica_id'::"text"))::"uuid")));



CREATE POLICY "Cliente pode ver user_role_auth da sua clínica" ON "public"."user_role_auth" FOR SELECT TO "authenticated" USING (((("auth"."jwt"() ->> 'user_role'::"text") = 'cliente'::"text") AND ("clinica_id" = (("auth"."jwt"() ->> 'clinica_id'::"text"))::"uuid")));



CREATE POLICY "Cliente pode ver vídeos" ON "public"."videos" FOR SELECT TO "authenticated" USING ((("auth"."jwt"() ->> 'user_role'::"text") = 'cliente'::"text"));



CREATE POLICY "Cliente/Clínica pode criar atendimentos" ON "public"."atendimentos" WITH CHECK (((("auth"."jwt"() ->> 'user_role'::"text") = ANY (ARRAY['cliente'::"text", 'clinica'::"text"])) AND ("id_clinica" = (("auth"."jwt"() ->> 'clinica_id'::"text"))::"uuid")));



CREATE POLICY "Cliente/Clínica pode criar condicoes do exame" ON "public"."oto_condicoes_exame_paciente" FOR INSERT TO "authenticated" WITH CHECK (((("auth"."jwt"() ->> 'user_role'::"text") = ANY (ARRAY['cliente'::"text", 'clinica'::"text"])) AND ("id_clinica" = (("auth"."jwt"() ->> 'clinica_id'::"text"))::"uuid")));



CREATE POLICY "Cliente/Clínica pode criar detalhes do paciente" ON "public"."user_expandido_paciente_detalhes" FOR INSERT WITH CHECK (((("auth"."jwt"() ->> 'user_role'::"text") = ANY (ARRAY['cliente'::"text", 'clinica'::"text"])) AND (EXISTS ( SELECT 1
   FROM "public"."user_expandido_paciente" "p"
  WHERE (("p"."id" = "user_expandido_paciente_detalhes"."id_paciente") AND ("p"."id_clinica" = (("auth"."jwt"() ->> 'clinica_id'::"text"))::"uuid"))))));



CREATE POLICY "Cliente/Clínica pode criar exames" ON "public"."oto_exames" FOR INSERT TO "authenticated" WITH CHECK (((("auth"."jwt"() ->> 'user_role'::"text") = ANY (ARRAY['cliente'::"text", 'clinica'::"text"])) AND ("id_clinica" = (("auth"."jwt"() ->> 'clinica_id'::"text"))::"uuid")));



CREATE POLICY "Cliente/Clínica pode editar condicoes do exame" ON "public"."oto_condicoes_exame_paciente" FOR UPDATE TO "authenticated" USING (((("auth"."jwt"() ->> 'user_role'::"text") = ANY (ARRAY['cliente'::"text", 'clinica'::"text"])) AND ("id_clinica" = (("auth"."jwt"() ->> 'clinica_id'::"text"))::"uuid"))) WITH CHECK (((("auth"."jwt"() ->> 'user_role'::"text") = ANY (ARRAY['cliente'::"text", 'clinica'::"text"])) AND ("id_clinica" = (("auth"."jwt"() ->> 'clinica_id'::"text"))::"uuid")));



CREATE POLICY "Cliente/Clínica pode editar detalhes do paciente" ON "public"."user_expandido_paciente_detalhes" FOR UPDATE USING (((("auth"."jwt"() ->> 'user_role'::"text") = ANY (ARRAY['cliente'::"text", 'clinica'::"text"])) AND (EXISTS ( SELECT 1
   FROM "public"."user_expandido_paciente" "p"
  WHERE (("p"."id" = "user_expandido_paciente_detalhes"."id_paciente") AND ("p"."id_clinica" = (("auth"."jwt"() ->> 'clinica_id'::"text"))::"uuid"))))));



CREATE POLICY "Cliente/Clínica pode editar exames" ON "public"."oto_exames" FOR UPDATE TO "authenticated" USING (((("auth"."jwt"() ->> 'user_role'::"text") = ANY (ARRAY['cliente'::"text", 'clinica'::"text"])) AND ("id_clinica" = (("auth"."jwt"() ->> 'clinica_id'::"text"))::"uuid"))) WITH CHECK (((("auth"."jwt"() ->> 'user_role'::"text") = ANY (ARRAY['cliente'::"text", 'clinica'::"text"])) AND ("id_clinica" = (("auth"."jwt"() ->> 'clinica_id'::"text"))::"uuid")));



CREATE POLICY "Cliente/Clínica pode editar seus atendimentos" ON "public"."atendimentos" USING (((("auth"."jwt"() ->> 'user_role'::"text") = ANY (ARRAY['cliente'::"text", 'clinica'::"text"])) AND ("id_clinica" = (("auth"."jwt"() ->> 'clinica_id'::"text"))::"uuid")));



CREATE POLICY "Cliente/Clínica pode ver condicoes do exame" ON "public"."oto_condicoes_exame_paciente" FOR SELECT TO "authenticated" USING (((("auth"."jwt"() ->> 'user_role'::"text") = ANY (ARRAY['cliente'::"text", 'clinica'::"text"])) AND ("id_clinica" = (("auth"."jwt"() ->> 'clinica_id'::"text"))::"uuid")));



CREATE POLICY "Cliente/Clínica pode ver detalhes do paciente" ON "public"."user_expandido_paciente_detalhes" FOR SELECT USING (((("auth"."jwt"() ->> 'user_role'::"text") = ANY (ARRAY['cliente'::"text", 'clinica'::"text"])) AND (EXISTS ( SELECT 1
   FROM "public"."user_expandido_paciente" "p"
  WHERE (("p"."id" = "user_expandido_paciente_detalhes"."id_paciente") AND ("p"."id_clinica" = (("auth"."jwt"() ->> 'clinica_id'::"text"))::"uuid"))))));



CREATE POLICY "Cliente/Clínica pode ver seus atendimentos" ON "public"."atendimentos" FOR SELECT USING (((("auth"."jwt"() ->> 'user_role'::"text") = ANY (ARRAY['cliente'::"text", 'clinica'::"text"])) AND ("id_clinica" = (("auth"."jwt"() ->> 'clinica_id'::"text"))::"uuid")));



CREATE POLICY "Cliente/Clínica pode ver seus exames" ON "public"."oto_exames" FOR SELECT TO "authenticated" USING (((("auth"."jwt"() ->> 'user_role'::"text") = ANY (ARRAY['cliente'::"text", 'clinica'::"text"])) AND ("id_clinica" = (("auth"."jwt"() ->> 'clinica_id'::"text"))::"uuid")));



CREATE POLICY "Cliente/UserClinica pode ver perguntas do seu modelo ou global" ON "public"."anamnese_pergunta" FOR SELECT TO "authenticated" USING ((EXISTS ( SELECT 1
   FROM "public"."anamnese_modelo" "am"
  WHERE (("am"."id" = "anamnese_pergunta"."id_anamnese_modelo") AND (("am"."global" = true) OR ("am"."id_clinica" = (("auth"."jwt"() ->> 'clinica_id'::"text"))::"uuid"))))));



CREATE POLICY "Cliente/UserClinica podem gerenciar gabaritos da própria clín" ON "public"."questionario_gabarito" TO "authenticated" USING ((EXISTS ( SELECT 1
   FROM "public"."questionario_modelo" "qm"
  WHERE (("qm"."id" = "questionario_gabarito"."id_questionario") AND ("qm"."id_clinica" = (("auth"."jwt"() ->> 'clinica_id'::"text"))::"uuid"))))) WITH CHECK ((EXISTS ( SELECT 1
   FROM "public"."questionario_modelo" "qm"
  WHERE (("qm"."id" = "questionario_gabarito"."id_questionario") AND ("qm"."id_clinica" = (("auth"."jwt"() ->> 'clinica_id'::"text"))::"uuid")))));



CREATE POLICY "Cliente/UserClinica podem gerenciar grupos da própria clínica" ON "public"."questionario_perguntas_grupo" TO "authenticated" USING ((EXISTS ( SELECT 1
   FROM "public"."questionario_modelo" "qm"
  WHERE (("qm"."id" = "questionario_perguntas_grupo"."id_questionario") AND ("qm"."id_clinica" = (("auth"."jwt"() ->> 'clinica_id'::"text"))::"uuid"))))) WITH CHECK ((EXISTS ( SELECT 1
   FROM "public"."questionario_modelo" "qm"
  WHERE (("qm"."id" = "questionario_perguntas_grupo"."id_questionario") AND ("qm"."id_clinica" = (("auth"."jwt"() ->> 'clinica_id'::"text"))::"uuid")))));



CREATE POLICY "Cliente/UserClinica podem gerenciar perguntas da própria clín" ON "public"."questionario_perguntas" TO "authenticated" USING ((EXISTS ( SELECT 1
   FROM "public"."questionario_modelo" "qm"
  WHERE (("qm"."id" = "questionario_perguntas"."id_questionario") AND ("qm"."id_clinica" = (("auth"."jwt"() ->> 'clinica_id'::"text"))::"uuid"))))) WITH CHECK ((EXISTS ( SELECT 1
   FROM "public"."questionario_modelo" "qm"
  WHERE (("qm"."id" = "questionario_perguntas"."id_questionario") AND ("qm"."id_clinica" = (("auth"."jwt"() ->> 'clinica_id'::"text"))::"uuid")))));



CREATE POLICY "Cliente/UserClinica podem gerenciar respostas da própria clín" ON "public"."questionario_respostas" TO "authenticated" USING ((EXISTS ( SELECT 1
   FROM ("public"."questionario_perguntas" "qp"
     JOIN "public"."questionario_modelo" "qm" ON (("qm"."id" = "qp"."id_questionario")))
  WHERE ((("questionario_respostas"."id_pergunta" = "qp"."id") OR ("questionario_respostas"."id_questionario" = "qm"."id")) AND ("qm"."id_clinica" = (("auth"."jwt"() ->> 'clinica_id'::"text"))::"uuid"))))) WITH CHECK ((EXISTS ( SELECT 1
   FROM ("public"."questionario_perguntas" "qp"
     JOIN "public"."questionario_modelo" "qm" ON (("qm"."id" = "qp"."id_questionario")))
  WHERE ((("questionario_respostas"."id_pergunta" = "qp"."id") OR ("questionario_respostas"."id_questionario" = "qm"."id")) AND ("qm"."id_clinica" = (("auth"."jwt"() ->> 'clinica_id'::"text"))::"uuid")))));



CREATE POLICY "Clinica pode criar colaboradores na sua clínica" ON "public"."user_expandido_colaboradores" TO "authenticated" WITH CHECK (((("auth"."jwt"() ->> 'user_role'::"text") = 'clinica'::"text") AND ("clinica_id" = (("auth"."jwt"() ->> 'clinica_id'::"text"))::"uuid")));



CREATE POLICY "Clinica pode criar paciente na sua clínica" ON "public"."user_expandido_paciente" TO "authenticated" WITH CHECK (((("auth"."jwt"() ->> 'user_role'::"text") = 'clinica'::"text") AND ("id_clinica" = (("auth"."jwt"() ->> 'clinica_id'::"text"))::"uuid")));



CREATE POLICY "Clinica pode editar colaboradores da sua clínica" ON "public"."user_expandido_colaboradores" TO "authenticated" USING (((("auth"."jwt"() ->> 'user_role'::"text") = 'clinica'::"text") AND ("clinica_id" = (("auth"."jwt"() ->> 'clinica_id'::"text"))::"uuid"))) WITH CHECK (((("auth"."jwt"() ->> 'user_role'::"text") = 'clinica'::"text") AND ("clinica_id" = (("auth"."jwt"() ->> 'clinica_id'::"text"))::"uuid")));



CREATE POLICY "Clinica pode editar paciente da sua clínica" ON "public"."user_expandido_paciente" TO "authenticated" USING (((("auth"."jwt"() ->> 'user_role'::"text") = 'clinica'::"text") AND ("id_clinica" = (("auth"."jwt"() ->> 'clinica_id'::"text"))::"uuid"))) WITH CHECK (((("auth"."jwt"() ->> 'user_role'::"text") = 'clinica'::"text") AND ("id_clinica" = (("auth"."jwt"() ->> 'clinica_id'::"text"))::"uuid")));



CREATE POLICY "Clinica pode ver colaborador da sua clínica" ON "public"."user_expandido_colaboradores" TO "authenticated" USING (((("auth"."jwt"() ->> 'user_role'::"text") = 'clinica'::"text") AND ("clinica_id" = (("auth"."jwt"() ->> 'clinica_id'::"text"))::"uuid")));



CREATE POLICY "Clinica pode ver paciente da sua clínica" ON "public"."user_expandido_paciente" TO "authenticated" USING (((("auth"."jwt"() ->> 'user_role'::"text") = 'clinica'::"text") AND ("id_clinica" = (("auth"."jwt"() ->> 'clinica_id'::"text"))::"uuid")));



CREATE POLICY "Clinica pode ver sua clínica" ON "public"."clinica" FOR SELECT TO "authenticated" USING (((("auth"."jwt"() ->> 'user_role'::"text") = 'clinica'::"text") AND ("id" = (("auth"."jwt"() ->> 'clinica_id'::"text"))::"uuid")));



CREATE POLICY "Clinica vê seu próprio user_role_auth" ON "public"."user_role_auth" FOR SELECT TO "authenticated" USING (((("auth"."jwt"() ->> 'user_role'::"text") = 'clinica'::"text") AND ("user_id" = "auth"."uid"())));



CREATE POLICY "Clínica pode ver seus próprios produtos" ON "public"."produtos_user" FOR SELECT TO "authenticated" USING ((("user_id" = "auth"."uid"()) AND (("auth"."jwt"() ->> 'user_role'::"text") = 'clinica'::"text")));



CREATE POLICY "Colaborador pode editar a si próprio" ON "public"."user_expandido_colaboradores" FOR UPDATE TO "authenticated" USING (((("auth"."jwt"() ->> 'user_role'::"text") = 'colaborador'::"text") AND ("user_id" = "auth"."uid"())));



CREATE POLICY "Colaborador pode ver a si próprio" ON "public"."user_expandido_colaboradores" FOR SELECT TO "authenticated" USING (((("auth"."jwt"() ->> 'user_role'::"text") = 'colaborador'::"text") AND ("user_id" = "auth"."uid"())));



CREATE POLICY "Colaborador pode ver paciente da sua clínica" ON "public"."user_expandido_paciente" TO "authenticated" USING (((("auth"."jwt"() ->> 'user_role'::"text") = 'colaborador'::"text") AND ("id_clinica" = (("auth"."jwt"() ->> 'clinica_id'::"text"))::"uuid")));



CREATE POLICY "Colaborador pode ver seus próprios produtos" ON "public"."produtos_user" FOR SELECT TO "authenticated" USING ((("user_id" = "auth"."uid"()) AND (("auth"."jwt"() ->> 'user_role'::"text") = 'colaborador'::"text")));



CREATE POLICY "Colaborador pode ver sua clínica" ON "public"."clinica" FOR SELECT TO "authenticated" USING (((("auth"."jwt"() ->> 'user_role'::"text") = 'colaborador'::"text") AND ("id" = (("auth"."jwt"() ->> 'clinica_id'::"text"))::"uuid")));



CREATE POLICY "Colaborador vê seu próprio user_role_auth" ON "public"."user_role_auth" FOR SELECT TO "authenticated" USING (((("auth"."jwt"() ->> 'user_role'::"text") = 'colaborador'::"text") AND ("user_id" = "auth"."uid"())));



CREATE POLICY "Paciente pode ver" ON "public"."videos_grupos_rel_videos" FOR SELECT TO "authenticated" USING ((("auth"."jwt"() ->> 'user_role'::"text") = 'paciente'::"text"));



CREATE POLICY "Paciente pode ver" ON "public"."videos_habilidades_rel_videos" FOR SELECT TO "authenticated" USING ((("auth"."jwt"() ->> 'user_role'::"text") = 'paciente'::"text"));



CREATE POLICY "Paciente pode ver categorias" ON "public"."videos_categorias" FOR SELECT TO "authenticated" USING ((("auth"."jwt"() ->> 'user_role'::"text") = 'paciente'::"text"));



CREATE POLICY "Paciente pode ver grupos" ON "public"."videos_grupos" FOR SELECT TO "authenticated" USING ((("auth"."jwt"() ->> 'user_role'::"text") = 'paciente'::"text"));



CREATE POLICY "Paciente pode ver habilidades" ON "public"."videos_habilidades" FOR SELECT TO "authenticated" USING ((("auth"."jwt"() ->> 'user_role'::"text") = 'paciente'::"text"));



CREATE POLICY "Paciente pode ver todas" ON "public"."reabilitacoes" FOR SELECT TO "authenticated" USING ((("auth"."jwt"() ->> 'user_role'::"text") = 'paciente'::"text"));



CREATE POLICY "Paciente pode ver vídeos" ON "public"."videos" FOR SELECT TO "authenticated" USING ((("auth"."jwt"() ->> 'user_role'::"text") = 'paciente'::"text"));



CREATE POLICY "Todos autenticados podem ver condições" ON "public"."oto_condicoes_exame" FOR SELECT TO "authenticated" USING (true);



CREATE POLICY "User_clinica pode ver clientes da sua clínica" ON "public"."user_expandido_cliente" FOR SELECT TO "authenticated" USING (((("auth"."jwt"() ->> 'user_role'::"text") = 'clinica'::"text") AND ("clinica_id" = (("auth"."jwt"() ->> 'clinica_id'::"text"))::"uuid")));



CREATE POLICY "Usuário autenticado pode ver exame_sistema" ON "public"."exame_sistema" FOR SELECT TO "authenticated" USING (true);



CREATE POLICY "Usuário autenticado pode ver exame_subtipo" ON "public"."exame_subtipo" FOR SELECT TO "authenticated" USING (true);



CREATE POLICY "Usuário autenticado pode ver exame_tipo" ON "public"."exame_tipo" FOR SELECT TO "authenticated" USING (true);



CREATE POLICY "Usuário pode acessar/modificar seu próprio pareamento" ON "public"."controle_pareamento" TO "authenticated" USING (("id_user" = "auth"."uid"())) WITH CHECK (("id_user" = "auth"."uid"()));



CREATE POLICY "Usuário pode atualizar seu próprio registro" ON "public"."user_expandido" FOR UPDATE TO "authenticated" USING (("auth"."uid"() = "user_id")) WITH CHECK (("auth"."uid"() = "user_id"));



CREATE POLICY "Usuário pode gerenciar seus próprios vínculos" ON "public"."clinica_user" TO "authenticated" USING (("id_user" = ( SELECT "user_expandido"."id"
   FROM "public"."user_expandido"
  WHERE ("user_expandido"."user_id" = "auth"."uid"())))) WITH CHECK (("id_user" = ( SELECT "user_expandido"."id"
   FROM "public"."user_expandido"
  WHERE ("user_expandido"."user_id" = "auth"."uid"()))));



CREATE POLICY "Usuário pode gerenciar suas próprias respostas" ON "public"."respostas_user" TO "authenticated" USING (("id_user" = ( SELECT "user_expandido"."id"
   FROM "public"."user_expandido"
  WHERE ("user_expandido"."user_id" = "auth"."uid"())))) WITH CHECK (("id_user" = ( SELECT "user_expandido"."id"
   FROM "public"."user_expandido"
  WHERE ("user_expandido"."user_id" = "auth"."uid"()))));



CREATE POLICY "admin pode gerenciar exame_modelo" ON "public"."exame_modelo" TO "authenticated" USING ((("auth"."jwt"() ->> 'user_role'::"text") = 'admin'::"text")) WITH CHECK ((("auth"."jwt"() ->> 'user_role'::"text") = 'admin'::"text"));



CREATE POLICY "admin pode gerenciar exame_pergunta" ON "public"."exame_pergunta" TO "authenticated" USING ((("auth"."jwt"() ->> 'user_role'::"text") = 'admin'::"text")) WITH CHECK ((("auth"."jwt"() ->> 'user_role'::"text") = 'admin'::"text"));



CREATE POLICY "admin pode gerenciar exame_respostas_possiveis" ON "public"."exame_respostas_possiveis" TO "authenticated" USING ((("auth"."jwt"() ->> 'user_role'::"text") = 'admin'::"text")) WITH CHECK ((("auth"."jwt"() ->> 'user_role'::"text") = 'admin'::"text"));



CREATE POLICY "admin pode gerenciar exame_valores_referencia" ON "public"."exame_valores_referencia" TO "authenticated" USING ((("auth"."jwt"() ->> 'user_role'::"text") = 'admin'::"text")) WITH CHECK ((("auth"."jwt"() ->> 'user_role'::"text") = 'admin'::"text"));



CREATE POLICY "admin pode tudo em perguntas_user" ON "public"."perguntas_user" TO "authenticated" USING ((("auth"."jwt"() ->> 'user_role'::"text") = 'admin'::"text")) WITH CHECK ((("auth"."jwt"() ->> 'user_role'::"text") = 'admin'::"text"));



CREATE POLICY "admin_pode_tudo" ON "public"."user_role_auth" TO "authenticated" USING ((("auth"."jwt"() ->> 'user_role'::"text") = 'admin'::"text")) WITH CHECK ((("auth"."jwt"() ->> 'user_role'::"text") = 'admin'::"text"));



ALTER TABLE "public"."anamnese" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."anamnese_modelo" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."anamnese_pergunta" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."anamnese_resposta" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."app_atualizacoes" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."arquivos_pacientes" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."atendimentos" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."cliente_contrato" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."cliente_pagamento_contrato" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."clinica" ENABLE ROW LEVEL SECURITY;


CREATE POLICY "clinica pode editar a si mesmo" ON "public"."user_expandido_userclinica" FOR UPDATE TO "authenticated" USING (((("auth"."jwt"() ->> 'user_role'::"text") = 'clinica'::"text") AND ("user_id" = "auth"."uid"()))) WITH CHECK (((("auth"."jwt"() ->> 'user_role'::"text") = 'clinica'::"text") AND ("user_id" = "auth"."uid"())));



CREATE POLICY "clinica pode ver a si mesmo" ON "public"."user_expandido_userclinica" FOR SELECT TO "authenticated" USING (((("auth"."jwt"() ->> 'user_role'::"text") = 'clinica'::"text") AND ("user_id" = "auth"."uid"())));



ALTER TABLE "public"."clinica_user" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."controle_pareamento" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."crm" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."exame_modelo" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."exame_pergunta" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."exame_respostas_possiveis" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."exame_sistema" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."exame_subtipo" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."exame_tipo" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."exame_valores_referencia" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."modulos" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."oto_condicoes_exame" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."oto_condicoes_exame_paciente" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."oto_exames" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."perguntas_user" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."planos" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."planos_modulos" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."planos_modulos_limites" ENABLE ROW LEVEL SECURITY;


CREATE POLICY "politica de criacao (deletar depois)" ON "public"."reabilitacao_exercicios_videos" TO "authenticated" USING (true) WITH CHECK (true);



ALTER TABLE "public"."produtos" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."produtos_user" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."questionario_gabarito" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."questionario_modelo" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."questionario_perguntas" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."questionario_perguntas_grupo" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."questionario_respostas" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."reabilitacao_exercicios" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."reabilitacao_exercicios_videos" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."reabilitacoes" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."respostas_user" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."role_auth" ENABLE ROW LEVEL SECURITY;


CREATE POLICY "todos podem ver produtos" ON "public"."produtos" FOR SELECT USING (true);



CREATE POLICY "todos veem perguntas" ON "public"."perguntas_user" FOR SELECT TO "authenticated" USING (true);



CREATE POLICY "todos_podem" ON "public"."role_auth" FOR SELECT USING (true);



CREATE POLICY "todos_veem_atualizações" ON "public"."app_atualizacoes" FOR SELECT TO "authenticated" USING (true);



ALTER TABLE "public"."user_expandido" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."user_expandido_admin" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."user_expandido_cliente" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."user_expandido_colaboradores" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."user_expandido_paciente" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."user_expandido_paciente_detalhes" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."user_expandido_userclinica" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."user_role_auth" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."user_role_log" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."videos" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."videos_categorias" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."videos_grupos" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."videos_grupos_rel_videos" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."videos_habilidades" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."videos_habilidades_rel_videos" ENABLE ROW LEVEL SECURITY;




ALTER PUBLICATION "supabase_realtime" OWNER TO "postgres";






ALTER PUBLICATION "supabase_realtime" ADD TABLE ONLY "public"."controle_pareamento";






GRANT USAGE ON SCHEMA "public" TO "postgres";
GRANT USAGE ON SCHEMA "public" TO "anon";
GRANT USAGE ON SCHEMA "public" TO "authenticated";
GRANT USAGE ON SCHEMA "public" TO "service_role";
GRANT USAGE ON SCHEMA "public" TO "supabase_auth_admin";









































































































































































































GRANT ALL ON FUNCTION "public"."check_user_produto_status"("p_user_id" "uuid", "p_produto_id" "uuid") TO "anon";
GRANT ALL ON FUNCTION "public"."check_user_produto_status"("p_user_id" "uuid", "p_produto_id" "uuid") TO "authenticated";
GRANT ALL ON FUNCTION "public"."check_user_produto_status"("p_user_id" "uuid", "p_produto_id" "uuid") TO "service_role";



GRANT ALL ON FUNCTION "public"."cliente_mesma_clinica"("id_clinica_param" "uuid") TO "anon";
GRANT ALL ON FUNCTION "public"."cliente_mesma_clinica"("id_clinica_param" "uuid") TO "authenticated";
GRANT ALL ON FUNCTION "public"."cliente_mesma_clinica"("id_clinica_param" "uuid") TO "service_role";



GRANT ALL ON FUNCTION "public"."confirmar_email_usuario_expandido"() TO "anon";
GRANT ALL ON FUNCTION "public"."confirmar_email_usuario_expandido"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."confirmar_email_usuario_expandido"() TO "service_role";



GRANT ALL ON FUNCTION "public"."copiar_modelos_anamnese_globais_para_cliente_id"("cliente_id" "uuid") TO "anon";
GRANT ALL ON FUNCTION "public"."copiar_modelos_anamnese_globais_para_cliente_id"("cliente_id" "uuid") TO "authenticated";
GRANT ALL ON FUNCTION "public"."copiar_modelos_anamnese_globais_para_cliente_id"("cliente_id" "uuid") TO "service_role";



GRANT ALL ON FUNCTION "public"."criar_exame_completo"("p_exame" "jsonb", "p_perguntas" "jsonb", "p_respostas" "jsonb", "p_valores" "jsonb") TO "anon";
GRANT ALL ON FUNCTION "public"."criar_exame_completo"("p_exame" "jsonb", "p_perguntas" "jsonb", "p_respostas" "jsonb", "p_valores" "jsonb") TO "authenticated";
GRANT ALL ON FUNCTION "public"."criar_exame_completo"("p_exame" "jsonb", "p_perguntas" "jsonb", "p_respostas" "jsonb", "p_valores" "jsonb") TO "service_role";



REVOKE ALL ON FUNCTION "public"."custom_access_token_hook"("event" "jsonb") FROM PUBLIC;
GRANT ALL ON FUNCTION "public"."custom_access_token_hook"("event" "jsonb") TO "service_role";
GRANT ALL ON FUNCTION "public"."custom_access_token_hook"("event" "jsonb") TO "supabase_auth_admin";



GRANT ALL ON FUNCTION "public"."deletar_exame_completo"("p_id_modelo" "uuid") TO "anon";
GRANT ALL ON FUNCTION "public"."deletar_exame_completo"("p_id_modelo" "uuid") TO "authenticated";
GRANT ALL ON FUNCTION "public"."deletar_exame_completo"("p_id_modelo" "uuid") TO "service_role";



GRANT ALL ON FUNCTION "public"."editar_exame_completo"("p_exame" "jsonb", "p_perguntas" "jsonb", "p_respostas" "jsonb", "p_valores" "jsonb") TO "anon";
GRANT ALL ON FUNCTION "public"."editar_exame_completo"("p_exame" "jsonb", "p_perguntas" "jsonb", "p_respostas" "jsonb", "p_valores" "jsonb") TO "authenticated";
GRANT ALL ON FUNCTION "public"."editar_exame_completo"("p_exame" "jsonb", "p_perguntas" "jsonb", "p_respostas" "jsonb", "p_valores" "jsonb") TO "service_role";



GRANT ALL ON FUNCTION "public"."email_existe_no_auth"("email_input" "text") TO "anon";
GRANT ALL ON FUNCTION "public"."email_existe_no_auth"("email_input" "text") TO "authenticated";
GRANT ALL ON FUNCTION "public"."email_existe_no_auth"("email_input" "text") TO "service_role";



GRANT ALL ON FUNCTION "public"."gerar_pagamentos_recorrentes"() TO "anon";
GRANT ALL ON FUNCTION "public"."gerar_pagamentos_recorrentes"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."gerar_pagamentos_recorrentes"() TO "service_role";



GRANT ALL ON FUNCTION "public"."get_admins_by_produto_paginado"("p_produto_id" "uuid", "p_page" integer, "p_limit" integer, "p_nome" "text") TO "anon";
GRANT ALL ON FUNCTION "public"."get_admins_by_produto_paginado"("p_produto_id" "uuid", "p_page" integer, "p_limit" integer, "p_nome" "text") TO "authenticated";
GRANT ALL ON FUNCTION "public"."get_admins_by_produto_paginado"("p_produto_id" "uuid", "p_page" integer, "p_limit" integer, "p_nome" "text") TO "service_role";



GRANT ALL ON FUNCTION "public"."get_complete_schema"() TO "anon";
GRANT ALL ON FUNCTION "public"."get_complete_schema"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."get_complete_schema"() TO "service_role";



GRANT ALL ON FUNCTION "public"."get_exame_completo"("p_id_modelo" "uuid") TO "anon";
GRANT ALL ON FUNCTION "public"."get_exame_completo"("p_id_modelo" "uuid") TO "authenticated";
GRANT ALL ON FUNCTION "public"."get_exame_completo"("p_id_modelo" "uuid") TO "service_role";



GRANT ALL ON FUNCTION "public"."get_questionario"("p_id_modelo" "uuid", "p_nome_modelo" "text") TO "anon";
GRANT ALL ON FUNCTION "public"."get_questionario"("p_id_modelo" "uuid", "p_nome_modelo" "text") TO "authenticated";
GRANT ALL ON FUNCTION "public"."get_questionario"("p_id_modelo" "uuid", "p_nome_modelo" "text") TO "service_role";



GRANT ALL ON FUNCTION "public"."get_user_dimensoes"("p_id_user_expandido" "uuid") TO "anon";
GRANT ALL ON FUNCTION "public"."get_user_dimensoes"("p_id_user_expandido" "uuid") TO "authenticated";
GRANT ALL ON FUNCTION "public"."get_user_dimensoes"("p_id_user_expandido" "uuid") TO "service_role";



GRANT ALL ON FUNCTION "public"."get_user_dimensoes_v2"("p_papel" "uuid", "p_id_user" "uuid", "p_id_clinica" "uuid") TO "anon";
GRANT ALL ON FUNCTION "public"."get_user_dimensoes_v2"("p_papel" "uuid", "p_id_user" "uuid", "p_id_clinica" "uuid") TO "authenticated";
GRANT ALL ON FUNCTION "public"."get_user_dimensoes_v2"("p_papel" "uuid", "p_id_user" "uuid", "p_id_clinica" "uuid") TO "service_role";



GRANT ALL ON FUNCTION "public"."get_user_expandido_info"() TO "anon";
GRANT ALL ON FUNCTION "public"."get_user_expandido_info"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."get_user_expandido_info"() TO "service_role";



GRANT ALL ON FUNCTION "public"."get_user_ids_by_produto"("p_produto_id" "uuid") TO "anon";
GRANT ALL ON FUNCTION "public"."get_user_ids_by_produto"("p_produto_id" "uuid") TO "authenticated";
GRANT ALL ON FUNCTION "public"."get_user_ids_by_produto"("p_produto_id" "uuid") TO "service_role";



GRANT ALL ON FUNCTION "public"."get_users"("p_busca" "text", "p_status" boolean, "p_id_produto" "uuid", "p_id_papel" "uuid", "p_limite_itens_pagina" integer, "p_pagina_busca" integer) TO "anon";
GRANT ALL ON FUNCTION "public"."get_users"("p_busca" "text", "p_status" boolean, "p_id_produto" "uuid", "p_id_papel" "uuid", "p_limite_itens_pagina" integer, "p_pagina_busca" integer) TO "authenticated";
GRANT ALL ON FUNCTION "public"."get_users"("p_busca" "text", "p_status" boolean, "p_id_produto" "uuid", "p_id_papel" "uuid", "p_limite_itens_pagina" integer, "p_pagina_busca" integer) TO "service_role";



GRANT ALL ON FUNCTION "public"."get_users"("p_busca" "text", "p_status" boolean, "p_id_produto" "uuid", "p_id_papel" "uuid", "p_id_clinica" "uuid", "p_limite_itens_pagina" integer, "p_pagina_busca" integer) TO "anon";
GRANT ALL ON FUNCTION "public"."get_users"("p_busca" "text", "p_status" boolean, "p_id_produto" "uuid", "p_id_papel" "uuid", "p_id_clinica" "uuid", "p_limite_itens_pagina" integer, "p_pagina_busca" integer) TO "authenticated";
GRANT ALL ON FUNCTION "public"."get_users"("p_busca" "text", "p_status" boolean, "p_id_produto" "uuid", "p_id_papel" "uuid", "p_id_clinica" "uuid", "p_limite_itens_pagina" integer, "p_pagina_busca" integer) TO "service_role";



GRANT ALL ON FUNCTION "public"."get_users_por_papel"("p_id_papel" "uuid", "p_id_user_chamada" "uuid", "p_id_papel_user_chamada" "uuid") TO "anon";
GRANT ALL ON FUNCTION "public"."get_users_por_papel"("p_id_papel" "uuid", "p_id_user_chamada" "uuid", "p_id_papel_user_chamada" "uuid") TO "authenticated";
GRANT ALL ON FUNCTION "public"."get_users_por_papel"("p_id_papel" "uuid", "p_id_user_chamada" "uuid", "p_id_papel_user_chamada" "uuid") TO "service_role";



GRANT ALL ON FUNCTION "public"."obter_usuario_expandido_completo"() TO "anon";
GRANT ALL ON FUNCTION "public"."obter_usuario_expandido_completo"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."obter_usuario_expandido_completo"() TO "service_role";



GRANT ALL ON FUNCTION "public"."qtd_clientes_por_mes"() TO "anon";
GRANT ALL ON FUNCTION "public"."qtd_clientes_por_mes"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."qtd_clientes_por_mes"() TO "service_role";



GRANT ALL ON FUNCTION "public"."trg_clinica_user_set_updated_at"() TO "anon";
GRANT ALL ON FUNCTION "public"."trg_clinica_user_set_updated_at"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."trg_clinica_user_set_updated_at"() TO "service_role";



GRANT ALL ON FUNCTION "public"."trg_perguntas_user_set_updated_at"() TO "anon";
GRANT ALL ON FUNCTION "public"."trg_perguntas_user_set_updated_at"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."trg_perguntas_user_set_updated_at"() TO "service_role";



GRANT ALL ON FUNCTION "public"."trg_respostas_user_set_updated_at"() TO "anon";
GRANT ALL ON FUNCTION "public"."trg_respostas_user_set_updated_at"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."trg_respostas_user_set_updated_at"() TO "service_role";



GRANT ALL ON FUNCTION "public"."trg_set_updated_at"() TO "anon";
GRANT ALL ON FUNCTION "public"."trg_set_updated_at"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."trg_set_updated_at"() TO "service_role";



GRANT ALL ON FUNCTION "public"."trg_user_expandido_set_updated_at"() TO "anon";
GRANT ALL ON FUNCTION "public"."trg_user_expandido_set_updated_at"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."trg_user_expandido_set_updated_at"() TO "service_role";



GRANT ALL ON FUNCTION "public"."upsert_questionario_completo"("p_payload" "jsonb") TO "anon";
GRANT ALL ON FUNCTION "public"."upsert_questionario_completo"("p_payload" "jsonb") TO "authenticated";
GRANT ALL ON FUNCTION "public"."upsert_questionario_completo"("p_payload" "jsonb") TO "service_role";



GRANT ALL ON FUNCTION "public"."upsert_user_dimensoes"("p_dados" "jsonb") TO "anon";
GRANT ALL ON FUNCTION "public"."upsert_user_dimensoes"("p_dados" "jsonb") TO "authenticated";
GRANT ALL ON FUNCTION "public"."upsert_user_dimensoes"("p_dados" "jsonb") TO "service_role";



GRANT ALL ON FUNCTION "public"."upsert_user_dimensoes_v2"("p_payload" "jsonb") TO "anon";
GRANT ALL ON FUNCTION "public"."upsert_user_dimensoes_v2"("p_payload" "jsonb") TO "authenticated";
GRANT ALL ON FUNCTION "public"."upsert_user_dimensoes_v2"("p_payload" "jsonb") TO "service_role";



GRANT ALL ON FUNCTION "public"."upsert_usuario_completo"("p_user" "jsonb", "p_respostas" "jsonb", "p_clinica" "jsonb", "p_produtos" "jsonb") TO "anon";
GRANT ALL ON FUNCTION "public"."upsert_usuario_completo"("p_user" "jsonb", "p_respostas" "jsonb", "p_clinica" "jsonb", "p_produtos" "jsonb") TO "authenticated";
GRANT ALL ON FUNCTION "public"."upsert_usuario_completo"("p_user" "jsonb", "p_respostas" "jsonb", "p_clinica" "jsonb", "p_produtos" "jsonb") TO "service_role";



GRANT ALL ON FUNCTION "public"."verifica_limite_clinica"("p_id_cliente" "uuid", "p_id_produto" "uuid", "p_id_modulo" "uuid") TO "anon";
GRANT ALL ON FUNCTION "public"."verifica_limite_clinica"("p_id_cliente" "uuid", "p_id_produto" "uuid", "p_id_modulo" "uuid") TO "authenticated";
GRANT ALL ON FUNCTION "public"."verifica_limite_clinica"("p_id_cliente" "uuid", "p_id_produto" "uuid", "p_id_modulo" "uuid") TO "service_role";
























GRANT ALL ON TABLE "public"."anamnese" TO "anon";
GRANT ALL ON TABLE "public"."anamnese" TO "authenticated";
GRANT ALL ON TABLE "public"."anamnese" TO "service_role";



GRANT ALL ON TABLE "public"."anamnese_modelo" TO "anon";
GRANT ALL ON TABLE "public"."anamnese_modelo" TO "authenticated";
GRANT ALL ON TABLE "public"."anamnese_modelo" TO "service_role";



GRANT ALL ON TABLE "public"."anamnese_pergunta" TO "anon";
GRANT ALL ON TABLE "public"."anamnese_pergunta" TO "authenticated";
GRANT ALL ON TABLE "public"."anamnese_pergunta" TO "service_role";



GRANT ALL ON TABLE "public"."anamnese_resposta" TO "anon";
GRANT ALL ON TABLE "public"."anamnese_resposta" TO "authenticated";
GRANT ALL ON TABLE "public"."anamnese_resposta" TO "service_role";



GRANT ALL ON TABLE "public"."app_atualizacoes" TO "anon";
GRANT ALL ON TABLE "public"."app_atualizacoes" TO "authenticated";
GRANT ALL ON TABLE "public"."app_atualizacoes" TO "service_role";



GRANT ALL ON TABLE "public"."arquivos_pacientes" TO "anon";
GRANT ALL ON TABLE "public"."arquivos_pacientes" TO "authenticated";
GRANT ALL ON TABLE "public"."arquivos_pacientes" TO "service_role";



GRANT ALL ON TABLE "public"."atendimentos" TO "anon";
GRANT ALL ON TABLE "public"."atendimentos" TO "authenticated";
GRANT ALL ON TABLE "public"."atendimentos" TO "service_role";



GRANT ALL ON TABLE "public"."cliente_contrato" TO "anon";
GRANT ALL ON TABLE "public"."cliente_contrato" TO "authenticated";
GRANT ALL ON TABLE "public"."cliente_contrato" TO "service_role";



GRANT ALL ON TABLE "public"."cliente_pagamento_contrato" TO "anon";
GRANT ALL ON TABLE "public"."cliente_pagamento_contrato" TO "authenticated";
GRANT ALL ON TABLE "public"."cliente_pagamento_contrato" TO "service_role";



GRANT ALL ON TABLE "public"."clinica" TO "anon";
GRANT ALL ON TABLE "public"."clinica" TO "authenticated";
GRANT ALL ON TABLE "public"."clinica" TO "service_role";



GRANT ALL ON TABLE "public"."clinica_user" TO "anon";
GRANT ALL ON TABLE "public"."clinica_user" TO "authenticated";
GRANT ALL ON TABLE "public"."clinica_user" TO "service_role";



GRANT ALL ON TABLE "public"."controle_pareamento" TO "anon";
GRANT ALL ON TABLE "public"."controle_pareamento" TO "authenticated";
GRANT ALL ON TABLE "public"."controle_pareamento" TO "service_role";



GRANT ALL ON TABLE "public"."crm" TO "anon";
GRANT ALL ON TABLE "public"."crm" TO "authenticated";
GRANT ALL ON TABLE "public"."crm" TO "service_role";



GRANT ALL ON TABLE "public"."exame_modelo" TO "anon";
GRANT ALL ON TABLE "public"."exame_modelo" TO "authenticated";
GRANT ALL ON TABLE "public"."exame_modelo" TO "service_role";



GRANT ALL ON TABLE "public"."exame_pergunta" TO "anon";
GRANT ALL ON TABLE "public"."exame_pergunta" TO "authenticated";
GRANT ALL ON TABLE "public"."exame_pergunta" TO "service_role";



GRANT ALL ON TABLE "public"."exame_respostas_possiveis" TO "anon";
GRANT ALL ON TABLE "public"."exame_respostas_possiveis" TO "authenticated";
GRANT ALL ON TABLE "public"."exame_respostas_possiveis" TO "service_role";



GRANT ALL ON TABLE "public"."exame_sistema" TO "anon";
GRANT ALL ON TABLE "public"."exame_sistema" TO "authenticated";
GRANT ALL ON TABLE "public"."exame_sistema" TO "service_role";



GRANT ALL ON TABLE "public"."exame_subtipo" TO "anon";
GRANT ALL ON TABLE "public"."exame_subtipo" TO "authenticated";
GRANT ALL ON TABLE "public"."exame_subtipo" TO "service_role";



GRANT ALL ON TABLE "public"."exame_tipo" TO "anon";
GRANT ALL ON TABLE "public"."exame_tipo" TO "authenticated";
GRANT ALL ON TABLE "public"."exame_tipo" TO "service_role";



GRANT ALL ON TABLE "public"."exame_valores_referencia" TO "anon";
GRANT ALL ON TABLE "public"."exame_valores_referencia" TO "authenticated";
GRANT ALL ON TABLE "public"."exame_valores_referencia" TO "service_role";



GRANT ALL ON TABLE "public"."modulos" TO "anon";
GRANT ALL ON TABLE "public"."modulos" TO "authenticated";
GRANT ALL ON TABLE "public"."modulos" TO "service_role";



GRANT ALL ON TABLE "public"."oto_condicoes_exame" TO "anon";
GRANT ALL ON TABLE "public"."oto_condicoes_exame" TO "authenticated";
GRANT ALL ON TABLE "public"."oto_condicoes_exame" TO "service_role";



GRANT ALL ON TABLE "public"."oto_condicoes_exame_paciente" TO "anon";
GRANT ALL ON TABLE "public"."oto_condicoes_exame_paciente" TO "authenticated";
GRANT ALL ON TABLE "public"."oto_condicoes_exame_paciente" TO "service_role";



GRANT ALL ON TABLE "public"."oto_exames" TO "anon";
GRANT ALL ON TABLE "public"."oto_exames" TO "authenticated";
GRANT ALL ON TABLE "public"."oto_exames" TO "service_role";



GRANT ALL ON TABLE "public"."perguntas_user" TO "anon";
GRANT ALL ON TABLE "public"."perguntas_user" TO "authenticated";
GRANT ALL ON TABLE "public"."perguntas_user" TO "service_role";



GRANT ALL ON TABLE "public"."planos" TO "anon";
GRANT ALL ON TABLE "public"."planos" TO "authenticated";
GRANT ALL ON TABLE "public"."planos" TO "service_role";



GRANT ALL ON TABLE "public"."planos_modulos" TO "anon";
GRANT ALL ON TABLE "public"."planos_modulos" TO "authenticated";
GRANT ALL ON TABLE "public"."planos_modulos" TO "service_role";



GRANT ALL ON TABLE "public"."planos_modulos_limites" TO "anon";
GRANT ALL ON TABLE "public"."planos_modulos_limites" TO "authenticated";
GRANT ALL ON TABLE "public"."planos_modulos_limites" TO "service_role";



GRANT ALL ON TABLE "public"."produtos" TO "anon";
GRANT ALL ON TABLE "public"."produtos" TO "authenticated";
GRANT ALL ON TABLE "public"."produtos" TO "service_role";



GRANT ALL ON TABLE "public"."produtos_user" TO "anon";
GRANT ALL ON TABLE "public"."produtos_user" TO "authenticated";
GRANT ALL ON TABLE "public"."produtos_user" TO "service_role";



GRANT ALL ON TABLE "public"."questionario_gabarito" TO "anon";
GRANT ALL ON TABLE "public"."questionario_gabarito" TO "authenticated";
GRANT ALL ON TABLE "public"."questionario_gabarito" TO "service_role";



GRANT ALL ON TABLE "public"."questionario_modelo" TO "anon";
GRANT ALL ON TABLE "public"."questionario_modelo" TO "authenticated";
GRANT ALL ON TABLE "public"."questionario_modelo" TO "service_role";



GRANT ALL ON TABLE "public"."questionario_perguntas" TO "anon";
GRANT ALL ON TABLE "public"."questionario_perguntas" TO "authenticated";
GRANT ALL ON TABLE "public"."questionario_perguntas" TO "service_role";



GRANT ALL ON TABLE "public"."questionario_perguntas_grupo" TO "anon";
GRANT ALL ON TABLE "public"."questionario_perguntas_grupo" TO "authenticated";
GRANT ALL ON TABLE "public"."questionario_perguntas_grupo" TO "service_role";



GRANT ALL ON TABLE "public"."questionario_respostas" TO "anon";
GRANT ALL ON TABLE "public"."questionario_respostas" TO "authenticated";
GRANT ALL ON TABLE "public"."questionario_respostas" TO "service_role";



GRANT ALL ON TABLE "public"."reabilitacao_exercicios" TO "anon";
GRANT ALL ON TABLE "public"."reabilitacao_exercicios" TO "authenticated";
GRANT ALL ON TABLE "public"."reabilitacao_exercicios" TO "service_role";



GRANT ALL ON TABLE "public"."reabilitacao_exercicios_videos" TO "anon";
GRANT ALL ON TABLE "public"."reabilitacao_exercicios_videos" TO "authenticated";
GRANT ALL ON TABLE "public"."reabilitacao_exercicios_videos" TO "service_role";



GRANT ALL ON TABLE "public"."reabilitacoes" TO "anon";
GRANT ALL ON TABLE "public"."reabilitacoes" TO "authenticated";
GRANT ALL ON TABLE "public"."reabilitacoes" TO "service_role";



GRANT ALL ON TABLE "public"."respostas_user" TO "anon";
GRANT ALL ON TABLE "public"."respostas_user" TO "authenticated";
GRANT ALL ON TABLE "public"."respostas_user" TO "service_role";



GRANT ALL ON TABLE "public"."role_auth" TO "anon";
GRANT ALL ON TABLE "public"."role_auth" TO "authenticated";
GRANT ALL ON TABLE "public"."role_auth" TO "service_role";
GRANT SELECT ON TABLE "public"."role_auth" TO "supabase_auth_admin";



GRANT ALL ON TABLE "public"."user_expandido" TO "anon";
GRANT ALL ON TABLE "public"."user_expandido" TO "authenticated";
GRANT ALL ON TABLE "public"."user_expandido" TO "service_role";



GRANT ALL ON TABLE "public"."user_expandido_admin" TO "anon";
GRANT ALL ON TABLE "public"."user_expandido_admin" TO "authenticated";
GRANT ALL ON TABLE "public"."user_expandido_admin" TO "service_role";



GRANT ALL ON TABLE "public"."user_expandido_cliente" TO "anon";
GRANT ALL ON TABLE "public"."user_expandido_cliente" TO "authenticated";
GRANT ALL ON TABLE "public"."user_expandido_cliente" TO "service_role";



GRANT ALL ON TABLE "public"."user_expandido_colaboradores" TO "anon";
GRANT ALL ON TABLE "public"."user_expandido_colaboradores" TO "authenticated";
GRANT ALL ON TABLE "public"."user_expandido_colaboradores" TO "service_role";



GRANT ALL ON TABLE "public"."user_expandido_paciente" TO "anon";
GRANT ALL ON TABLE "public"."user_expandido_paciente" TO "authenticated";
GRANT ALL ON TABLE "public"."user_expandido_paciente" TO "service_role";



GRANT ALL ON TABLE "public"."user_expandido_paciente_detalhes" TO "anon";
GRANT ALL ON TABLE "public"."user_expandido_paciente_detalhes" TO "authenticated";
GRANT ALL ON TABLE "public"."user_expandido_paciente_detalhes" TO "service_role";



GRANT ALL ON TABLE "public"."user_expandido_userclinica" TO "anon";
GRANT ALL ON TABLE "public"."user_expandido_userclinica" TO "authenticated";
GRANT ALL ON TABLE "public"."user_expandido_userclinica" TO "service_role";



GRANT ALL ON TABLE "public"."user_role_auth" TO "anon";
GRANT ALL ON TABLE "public"."user_role_auth" TO "authenticated";
GRANT ALL ON TABLE "public"."user_role_auth" TO "service_role";
GRANT SELECT ON TABLE "public"."user_role_auth" TO "supabase_auth_admin";



GRANT ALL ON TABLE "public"."user_role_log" TO "anon";
GRANT ALL ON TABLE "public"."user_role_log" TO "authenticated";
GRANT ALL ON TABLE "public"."user_role_log" TO "service_role";



GRANT ALL ON SEQUENCE "public"."user_role_log_id_seq" TO "anon";
GRANT ALL ON SEQUENCE "public"."user_role_log_id_seq" TO "authenticated";
GRANT ALL ON SEQUENCE "public"."user_role_log_id_seq" TO "service_role";



GRANT ALL ON TABLE "public"."videos" TO "anon";
GRANT ALL ON TABLE "public"."videos" TO "authenticated";
GRANT ALL ON TABLE "public"."videos" TO "service_role";



GRANT ALL ON TABLE "public"."videos_categorias" TO "anon";
GRANT ALL ON TABLE "public"."videos_categorias" TO "authenticated";
GRANT ALL ON TABLE "public"."videos_categorias" TO "service_role";



GRANT ALL ON TABLE "public"."videos_grupos" TO "anon";
GRANT ALL ON TABLE "public"."videos_grupos" TO "authenticated";
GRANT ALL ON TABLE "public"."videos_grupos" TO "service_role";



GRANT ALL ON TABLE "public"."videos_grupos_rel_videos" TO "anon";
GRANT ALL ON TABLE "public"."videos_grupos_rel_videos" TO "authenticated";
GRANT ALL ON TABLE "public"."videos_grupos_rel_videos" TO "service_role";



GRANT ALL ON TABLE "public"."videos_habilidades" TO "anon";
GRANT ALL ON TABLE "public"."videos_habilidades" TO "authenticated";
GRANT ALL ON TABLE "public"."videos_habilidades" TO "service_role";



GRANT ALL ON TABLE "public"."videos_habilidades_rel_videos" TO "anon";
GRANT ALL ON TABLE "public"."videos_habilidades_rel_videos" TO "authenticated";
GRANT ALL ON TABLE "public"."videos_habilidades_rel_videos" TO "service_role";



GRANT ALL ON TABLE "public"."view_exercicios" TO "anon";
GRANT ALL ON TABLE "public"."view_exercicios" TO "authenticated";
GRANT ALL ON TABLE "public"."view_exercicios" TO "service_role";



GRANT ALL ON TABLE "public"."view_oto_exames_completo" TO "anon";
GRANT ALL ON TABLE "public"."view_oto_exames_completo" TO "authenticated";
GRANT ALL ON TABLE "public"."view_oto_exames_completo" TO "service_role";



GRANT ALL ON TABLE "public"."view_oto_exames_por_m" TO "anon";
GRANT ALL ON TABLE "public"."view_oto_exames_por_m" TO "authenticated";
GRANT ALL ON TABLE "public"."view_oto_exames_por_m" TO "service_role";



GRANT ALL ON TABLE "public"."view_planos_com_modulos_pivotado" TO "anon";
GRANT ALL ON TABLE "public"."view_planos_com_modulos_pivotado" TO "authenticated";
GRANT ALL ON TABLE "public"."view_planos_com_modulos_pivotado" TO "service_role";



GRANT ALL ON TABLE "public"."vw_videos_filtrados_teste" TO "anon";
GRANT ALL ON TABLE "public"."vw_videos_filtrados_teste" TO "authenticated";
GRANT ALL ON TABLE "public"."vw_videos_filtrados_teste" TO "service_role";



ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON SEQUENCES  TO "postgres";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON SEQUENCES  TO "anon";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON SEQUENCES  TO "authenticated";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON SEQUENCES  TO "service_role";






ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON FUNCTIONS  TO "postgres";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON FUNCTIONS  TO "anon";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON FUNCTIONS  TO "authenticated";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON FUNCTIONS  TO "service_role";






ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON TABLES  TO "postgres";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON TABLES  TO "anon";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON TABLES  TO "authenticated";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON TABLES  TO "service_role";






























drop extension if exists "pg_net";


  create policy "autenticados enviam"
  on "realtime"."messages"
  as permissive
  for insert
  to public
with check (true);



  create policy "autenticados leem"
  on "realtime"."messages"
  as permissive
  for select
  to authenticated
using (true);



  create policy "Cliente só acessa arquivos da sua clínica"
  on "storage"."objects"
  as permissive
  for all
  to public
using (((bucket_id = 'arquivosclinicas'::text) AND (split_part(name, '/'::text, 1) = ( SELECT (user_expandido_cliente.clinica_id)::text AS clinica_id
   FROM public.user_expandido_cliente
  WHERE (user_expandido_cliente.user_id = auth.uid())
 LIMIT 1)) AND true));



  create policy "Usuários autenticados podem deletar arquivos temporários"
  on "storage"."objects"
  as permissive
  for delete
  to public
using (((bucket_id = 'provisoriooto'::text) AND (auth.role() = 'authenticated'::text)));



  create policy "Usuários autenticados podem fazer upload de arquivos temporár"
  on "storage"."objects"
  as permissive
  for insert
  to public
with check (((bucket_id = 'provisoriooto'::text) AND (auth.role() = 'authenticated'::text)));



  create policy "Usuários autenticados podem ler arquivos temporários"
  on "storage"."objects"
  as permissive
  for select
  to public
using (((bucket_id = 'provisoriooto'::text) AND (auth.role() = 'authenticated'::text)));



