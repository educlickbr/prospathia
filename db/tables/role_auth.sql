--
-- PostgreSQL database dump
--

\restrict kJ0vWsSn3SLEzN7N1JDGYR3z5AQ6IUCUzclakRpR2VoJBpC5BwD5FvyzBN4Wye0

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
-- Name: role_auth; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.role_auth (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    nome_role public.role_enum
);


--
-- Name: role_auth role_auth_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.role_auth
    ADD CONSTRAINT role_auth_pkey PRIMARY KEY (id);


--
-- Name: role_auth; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.role_auth ENABLE ROW LEVEL SECURITY;

--
-- Name: role_auth todos_podem; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY todos_podem ON public.role_auth FOR SELECT USING (true);


--
-- PostgreSQL database dump complete
--

\unrestrict kJ0vWsSn3SLEzN7N1JDGYR3z5AQ6IUCUzclakRpR2VoJBpC5BwD5FvyzBN4Wye0

