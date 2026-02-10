--
-- PostgreSQL database dump
--

\restrict JGyMKPkCgFYTlBUird6c2UfmyfyvtGLafImdxDPqAIfQ942n9xCFtg4fbMUA9o2

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
-- Name: user_role_auth; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.user_role_auth (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    user_id uuid,
    role_id uuid,
    clinica_id uuid
);


--
-- Name: user_role_auth user_role_auth_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.user_role_auth
    ADD CONSTRAINT user_role_auth_pkey PRIMARY KEY (id);


--
-- Name: user_role_auth user_role_auth_clinica_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.user_role_auth
    ADD CONSTRAINT user_role_auth_clinica_id_fkey FOREIGN KEY (clinica_id) REFERENCES public.clinica(id) ON DELETE SET NULL;


--
-- Name: user_role_auth user_role_auth_role_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.user_role_auth
    ADD CONSTRAINT user_role_auth_role_id_fkey FOREIGN KEY (role_id) REFERENCES public.role_auth(id) ON DELETE SET NULL;


--
-- Name: user_role_auth user_role_auth_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.user_role_auth
    ADD CONSTRAINT user_role_auth_user_id_fkey FOREIGN KEY (user_id) REFERENCES auth.users(id) ON DELETE CASCADE;


--
-- Name: user_role_auth Admin via JWT pode inserir user_role_auth; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Admin via JWT pode inserir user_role_auth" ON public.user_role_auth FOR INSERT TO authenticated WITH CHECK (((auth.jwt() ->> 'user_role'::text) = 'admin'::text));


--
-- Name: user_role_auth Admin vê seu próprio user_role_auth; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Admin vê seu próprio user_role_auth" ON public.user_role_auth FOR SELECT TO authenticated USING ((((auth.jwt() ->> 'user_role'::text) = 'admin'::text) AND (user_id = auth.uid())));


--
-- Name: user_role_auth Cliente pode criar user_role_auth na sua clínica; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Cliente pode criar user_role_auth na sua clínica" ON public.user_role_auth FOR INSERT TO authenticated WITH CHECK ((((auth.jwt() ->> 'user_role'::text) = 'cliente'::text) AND (((auth.jwt() ->> 'clinica_id'::text))::uuid = (((current_setting('request.jwt.claims'::text, true))::jsonb ->> 'clinica_id'::text))::uuid)));


--
-- Name: user_role_auth Cliente pode ver user_role_auth da sua clínica; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Cliente pode ver user_role_auth da sua clínica" ON public.user_role_auth FOR SELECT TO authenticated USING ((((auth.jwt() ->> 'user_role'::text) = 'cliente'::text) AND (clinica_id = ((auth.jwt() ->> 'clinica_id'::text))::uuid)));


--
-- Name: user_role_auth Clinica vê seu próprio user_role_auth; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Clinica vê seu próprio user_role_auth" ON public.user_role_auth FOR SELECT TO authenticated USING ((((auth.jwt() ->> 'user_role'::text) = 'clinica'::text) AND (user_id = auth.uid())));


--
-- Name: user_role_auth Colaborador vê seu próprio user_role_auth; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Colaborador vê seu próprio user_role_auth" ON public.user_role_auth FOR SELECT TO authenticated USING ((((auth.jwt() ->> 'user_role'::text) = 'colaborador'::text) AND (user_id = auth.uid())));


--
-- Name: user_role_auth admin_pode_tudo; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY admin_pode_tudo ON public.user_role_auth TO authenticated USING (((auth.jwt() ->> 'user_role'::text) = 'admin'::text)) WITH CHECK (((auth.jwt() ->> 'user_role'::text) = 'admin'::text));


--
-- Name: user_role_auth; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.user_role_auth ENABLE ROW LEVEL SECURITY;

--
-- PostgreSQL database dump complete
--

\unrestrict JGyMKPkCgFYTlBUird6c2UfmyfyvtGLafImdxDPqAIfQ942n9xCFtg4fbMUA9o2

