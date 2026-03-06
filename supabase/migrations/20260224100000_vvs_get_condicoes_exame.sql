CREATE OR REPLACE FUNCTION public.vvs_get_condicoes_exame()
RETURNS SETOF public.oto_condicoes_exame
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
  RETURN QUERY
  SELECT * 
  FROM public.oto_condicoes_exame
  ORDER BY cod_condicao ASC;
END;
$$;
