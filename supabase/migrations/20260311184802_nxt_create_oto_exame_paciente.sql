create or replace function public.nxt_create_oto_exame_paciente(
  p_id_paciente uuid,
  p_id_clinica uuid,
  p_id_user_expandido uuid,
  p_condicoes jsonb
) returns uuid
language plpgsql
security definer
as $$
declare
  v_id_exame uuid;
  v_cond record;
begin
  -- 1. Create the main exam record
  insert into public.oto_exames (
    id_paciente,
    id_clinica,
    id_user_expandido,
    tipo,
    id_profissional -- deprecated, kept as null
  ) values (
    p_id_paciente,
    p_id_clinica,
    p_id_user_expandido,
    'exame',
    null
  ) returning id into v_id_exame;

  -- 2. Iterate through jsonb array and insert conditions
  for v_cond in select * from jsonb_array_elements(p_condicoes)
  loop
    insert into public.oto_condicoes_exame_paciente (
      id_exame,
      id_clinica,
      id_condicao,
      m1,
      m2,
      m3,
      m4,
      md,
      mnd
    ) values (
      v_id_exame,
      p_id_clinica,
      (v_cond.value->>'id_condicao')::uuid,
      (v_cond.value->>'m1')::double precision,
      (v_cond.value->>'m2')::double precision,
      (v_cond.value->>'m3')::double precision,
      (v_cond.value->>'m4')::double precision,
      (v_cond.value->>'md')::double precision,
      (v_cond.value->>'mnd')::double precision
    );
  end loop;

  return v_id_exame;
end;
$$;
