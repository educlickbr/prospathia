--
-- PostgreSQL database dump
--

\restrict N5tdszMSCDWKWiTahE9JdTgOVjcDPgXLe6nUF4krU7DtdUAbYZnpchd243WySLK

-- Dumped from database version 15.8
-- Dumped by pg_dump version 17.7 (Debian 17.7-0+deb13u1)

SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET transaction_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET xmloption = content;
SET client_min_messages = warning;
SET row_security = off;

SET default_table_access_method = heap;

--
-- Name: user_expandido; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.user_expandido (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    user_id uuid NOT NULL,
    nome_completo text NOT NULL,
    email text NOT NULL,
    telefone text,
    imagem_user text,
    status boolean DEFAULT true NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL
);


--
-- Name: user_expandido user_expandido_email_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.user_expandido
    ADD CONSTRAINT user_expandido_email_key UNIQUE (email);


--
-- Name: user_expandido user_expandido_pkey1; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.user_expandido
    ADD CONSTRAINT user_expandido_pkey1 PRIMARY KEY (id);


--
-- Name: user_expandido user_expandido_user_id_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.user_expandido
    ADD CONSTRAINT user_expandido_user_id_key UNIQUE (user_id);


--
-- Name: ix_user_expandido_email; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX ix_user_expandido_email ON public.user_expandido USING btree (email);


--
-- Name: ix_user_expandido_user_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX ix_user_expandido_user_id ON public.user_expandido USING btree (user_id);


--
-- Name: user_expandido trg_set_updated_at; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER trg_set_updated_at BEFORE UPDATE ON public.user_expandido FOR EACH ROW EXECUTE FUNCTION public.trg_user_expandido_set_updated_at();


--
-- Name: user_expandido user_expandido_user_id_fkey1; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.user_expandido
    ADD CONSTRAINT user_expandido_user_id_fkey1 FOREIGN KEY (user_id) REFERENCES auth.users(id) ON DELETE CASCADE;


--
-- Name: user_expandido Admin pode tudo; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Admin pode tudo" ON public.user_expandido TO authenticated USING (((auth.jwt() ->> 'user_role'::text) = 'admin'::text)) WITH CHECK (((auth.jwt() ->> 'user_role'::text) = 'admin'::text));


--
-- Name: user_expandido Usuário pode atualizar seu próprio registro; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Usuário pode atualizar seu próprio registro" ON public.user_expandido FOR UPDATE TO authenticated USING ((auth.uid() = user_id)) WITH CHECK ((auth.uid() = user_id));


--
-- Name: user_expandido; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.user_expandido ENABLE ROW LEVEL SECURITY;

--
-- PostgreSQL database dump complete
--

\unrestrict N5tdszMSCDWKWiTahE9JdTgOVjcDPgXLe6nUF4krU7DtdUAbYZnpchd243WySLK

