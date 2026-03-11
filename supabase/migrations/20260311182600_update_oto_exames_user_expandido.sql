-- 1. Adicionar nova coluna que aponta para user_expandido
ALTER TABLE public.oto_exames 
ADD COLUMN id_user_expandido uuid NULL;

ALTER TABLE public.oto_exames
ADD CONSTRAINT oto_exames_id_user_expandido_fkey 
FOREIGN KEY (id_user_expandido) REFERENCES public.user_expandido(id) ON DELETE SET NULL;

-- 2. Migrar os dados existentes
-- Para cada exame que tem um id_profissional (que aponta para user_expandido_cliente),
-- buscamos o user_id correspondente no user_expandido_cliente,
-- depois buscamos o id no user_expandido usando esse mesmo user_id,
-- e por fim, atualizamos a nova coluna id_user_expandido no exame.
UPDATE public.oto_exames e
SET id_user_expandido = ue.id
FROM public.user_expandido_cliente uec
JOIN public.user_expandido ue ON ue.user_id = uec.user_id
WHERE e.id_profissional = uec.id;
