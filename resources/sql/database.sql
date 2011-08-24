--
-- PostgreSQL database dump
--

SET statement_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = off;
SET check_function_bodies = false;
SET client_min_messages = warning;
SET escape_string_warning = off;

--
-- Name: toogworld; Type: SCHEMA; Schema: -; Owner: -
--

-- CREATE SCHEMA toogworld;


-- SET search_path = toogworld, pg_catalog;

--
-- Name: array_merge(anyarray, anyarray); Type: FUNCTION; Schema: toogworld; Owner: -
--

CREATE FUNCTION array_merge(array1 anyarray, array2 anyarray) RETURNS anyarray
    LANGUAGE plpgsql
    AS $$
    DECLARE
        i integer ;
        return_array array1%TYPE;
    BEGIN
        return_array := array1;
        FOR i IN SELECT * FROM unnest(array2) LOOP
            IF NOT i = ANY(return_array) THEN
                return_array := return_array || i;
            END IF;
        END LOOP;

        RETURN return_array;
    END;
$$;


--
-- Name: cut_nicely(character varying, integer); Type: FUNCTION; Schema: toogworld; Owner: -
--

CREATE FUNCTION cut_nicely(my_string character varying, my_length integer) RETURNS character varying
    LANGUAGE plpgsql
    AS $$
    DECLARE
        my_pointer INTEGER;
    BEGIN
        my_pointer := my_length;
        WHILE my_pointer < length(my_string) AND transliterate(substr(my_string, my_pointer, 1)) ~* '[a-z]' LOOP
            my_pointer := my_pointer + 1;
        END LOOP;

        RETURN substr(my_string, 1, my_pointer);
    END;
$$;


--
-- Name: is_email(character varying); Type: FUNCTION; Schema: toogworld; Owner: -
--

CREATE FUNCTION is_email(email character varying) RETURNS boolean
    LANGUAGE plpgsql
    AS $_$
BEGIN
      RETURN email ~* e'^([^@\\s]+)@((?:[a-z0-9-]+\\.)+[a-z]{2,})$';
END;
$_$;


--
-- Name: is_url(character varying); Type: FUNCTION; Schema: toogworld; Owner: -
--

CREATE FUNCTION is_url(url character varying) RETURNS boolean
    LANGUAGE plpgsql
    AS $_$
BEGIN
      RETURN url ~* e'(https?|ftps?)://((([a-z0-9-]+\\.)+[a-z]{2,6})|(\\d{1,3}\\.\\d{1,3}\\.\\d{1,3}\\.\\d{1,3}))(:[0-9]+)?(/\\S*)*$';
END;
$_$;


--
-- Name: slugify(character varying); Type: FUNCTION; Schema: toogworld; Owner: -
--

CREATE FUNCTION slugify(string character varying) RETURNS character varying
    LANGUAGE plpgsql
    AS $$
    BEGIN
          RETURN trim(both '-' from regexp_replace(lower(transliterate(string::varchar)), '[^a-z0-9]+', '-', 'g'));
    END;
$$;


--
-- Name: transliterate(character varying); Type: FUNCTION; Schema: toogworld; Owner: -
--

CREATE FUNCTION transliterate(my_text character varying) RETURNS character varying
    LANGUAGE plpgsql
    AS $$
    DECLARE 
      text_out VARCHAR DEFAULT '';
    BEGIN
           text_out := my_text;
           text_out := translate(text_out, 'àâäåáăąãāçċćčĉéèėëêēĕîïìíīñôöøõōùúüûūýÿỳ', 'aaaaaaaaaccccceeeeeeeiiiiinooooouuuuuyyy');
           text_out := translate(text_out, 'ÀÂÄÅÁĂĄÃĀÇĊĆČĈÉÈĖËÊĒĔÎÏÌÍĪÑÔÖØÕŌÙÚÜÛŪÝŸỲ', 'AAAAAAAAACCCCCEEEEEEEIIIIINOOOOOUUUUUYYY');
           text_out := replace(text_out, 'æ', 'ae');
           text_out := replace(text_out, 'Œ', 'OE');
           text_out := replace(text_out, 'Æ', 'AE');
           text_out := replace(text_out, 'ß', 'ss');
           text_out := replace(text_out, 'œ', 'oe');

           RETURN text_out;
    END;
$$;


--
-- Name: update_updated_at(); Type: FUNCTION; Schema: toogworld; Owner: -
--

CREATE FUNCTION update_updated_at() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
  BEGIN
    NEW.updated_at := now();

    RETURN NEW;
  END;
$$;


SET default_tablespace = '';

SET default_with_oids = false;

--
-- Name: access_control; Type: TABLE; Schema: toogworld; Owner: -; Tablespace: 
--

CREATE TABLE access_control (
    user_id integer NOT NULL,
    tool_id integer NOT NULL,
    app_data character varying
);


--
-- Name: app_auth; Type: TABLE; Schema: toogworld; Owner: -; Tablespace: 
--

CREATE TABLE app_auth (
    app_ref character varying NOT NULL,
    token character varying NOT NULL,
    user_id integer NOT NULL,
    created_at timestamp without time zone DEFAULT now() NOT NULL
);


--
-- Name: my_user; Type: TABLE; Schema: toogworld; Owner: -; Tablespace: 
--

CREATE TABLE my_user (
    id integer NOT NULL,
    email character varying NOT NULL,
    password character varying NOT NULL,
    is_active boolean DEFAULT true NOT NULL,
    password_nuke integer DEFAULT 1 NOT NULL,
    super_user boolean DEFAULT false,
    CONSTRAINT check_email CHECK (is_email(email))
);


--
-- Name: my_user_id_seq; Type: SEQUENCE; Schema: toogworld; Owner: -
--

CREATE SEQUENCE my_user_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MAXVALUE
    NO MINVALUE
    CACHE 1;


--
-- Name: my_user_id_seq; Type: SEQUENCE OWNED BY; Schema: toogworld; Owner: -
--

ALTER SEQUENCE my_user_id_seq OWNED BY my_user.id;


--
-- Name: tool; Type: TABLE; Schema: toogworld; Owner: -; Tablespace: 
--

CREATE TABLE tool (
    id integer NOT NULL,
    name character varying NOT NULL,
    name_slug character varying NOT NULL,
    zone character varying,
    zone_slug character varying,
    url character varying,
    type character varying,
    created_at timestamp without time zone DEFAULT now()
);


--
-- Name: tool_id_seq; Type: SEQUENCE; Schema: toogworld; Owner: -
--

CREATE SEQUENCE tool_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MAXVALUE
    NO MINVALUE
    CACHE 1;


--
-- Name: tool_id_seq; Type: SEQUENCE OWNED BY; Schema: toogworld; Owner: -
--

ALTER SEQUENCE tool_id_seq OWNED BY tool.id;


--
-- Name: id; Type: DEFAULT; Schema: toogworld; Owner: -
--

ALTER TABLE my_user ALTER COLUMN id SET DEFAULT nextval('my_user_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: toogworld; Owner: -
--

ALTER TABLE tool ALTER COLUMN id SET DEFAULT nextval('tool_id_seq'::regclass);


--
-- Name: access_control_pkey; Type: CONSTRAINT; Schema: toogworld; Owner: -; Tablespace: 
--

ALTER TABLE ONLY access_control
    ADD CONSTRAINT access_control_pkey PRIMARY KEY (user_id, tool_id);


--
-- Name: app_auth_pkey; Type: CONSTRAINT; Schema: toogworld; Owner: -; Tablespace: 
--

ALTER TABLE ONLY app_auth
    ADD CONSTRAINT app_auth_pkey PRIMARY KEY (app_ref, token);


--
-- Name: my_user_email_key; Type: CONSTRAINT; Schema: toogworld; Owner: -; Tablespace: 
--

ALTER TABLE ONLY my_user
    ADD CONSTRAINT my_user_email_key UNIQUE (email);


--
-- Name: my_user_pkey; Type: CONSTRAINT; Schema: toogworld; Owner: -; Tablespace: 
--

ALTER TABLE ONLY my_user
    ADD CONSTRAINT my_user_pkey PRIMARY KEY (id);


--
-- Name: tool_pkey; Type: CONSTRAINT; Schema: toogworld; Owner: -; Tablespace: 
--

ALTER TABLE ONLY tool
    ADD CONSTRAINT tool_pkey PRIMARY KEY (id);


--
-- Name: access_control_tool_id_fkey; Type: FK CONSTRAINT; Schema: toogworld; Owner: -
--

ALTER TABLE ONLY access_control
    ADD CONSTRAINT access_control_tool_id_fkey FOREIGN KEY (tool_id) REFERENCES tool(id);


--
-- Name: access_control_user_id_fkey; Type: FK CONSTRAINT; Schema: toogworld; Owner: -
--

ALTER TABLE ONLY access_control
    ADD CONSTRAINT access_control_user_id_fkey FOREIGN KEY (user_id) REFERENCES my_user(id);


--
-- Name: app_auth_user_id_fkey; Type: FK CONSTRAINT; Schema: toogworld; Owner: -
--

ALTER TABLE ONLY app_auth
    ADD CONSTRAINT app_auth_user_id_fkey FOREIGN KEY (user_id) REFERENCES my_user(id);


--
-- PostgreSQL database dump complete
--

