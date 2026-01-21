--
-- PostgreSQL database dump
--

\restrict RUfsb1lLLQbCxne1OaGbwU0rWkmXsHHzQjeQUhvdHDB2tq1cO7kqdnxDcyyb6Gd

-- Dumped from database version 14.20 (Ubuntu 14.20-0ubuntu0.22.04.1)
-- Dumped by pg_dump version 14.20 (Ubuntu 14.20-0ubuntu0.22.04.1)

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

--
-- Name: artur_zamorowski_kolokwium; Type: SCHEMA; Schema: -; Owner: postgres
--

CREATE SCHEMA artur_zamorowski_kolokwium;


ALTER SCHEMA artur_zamorowski_kolokwium OWNER TO postgres;

--
-- Name: project_data; Type: SCHEMA; Schema: -; Owner: postgres
--

CREATE SCHEMA project_data;


ALTER SCHEMA project_data OWNER TO postgres;

--
-- Name: test_python; Type: SCHEMA; Schema: -; Owner: postgres
--

CREATE SCHEMA test_python;


ALTER SCHEMA test_python OWNER TO postgres;

--
-- Name: delete_person_secure(integer, integer); Type: PROCEDURE; Schema: artur_zamorowski_kolokwium; Owner: postgres
--

CREATE PROCEDURE artur_zamorowski_kolokwium.delete_person_secure(IN p_admin_id integer, IN p_person_id integer)
    LANGUAGE plpgsql
    AS $$
DECLARE
    v_role_name VARCHAR;
BEGIN
    -- 1. Pobieramy nazwę roli użytkownika
    SELECT r.role_name INTO v_role_name
    FROM users u
    JOIN roles r ON u.role_id = r.id
    WHERE u.id = p_admin_id;

    -- 2. Instrukcja CASE (wymóg egzaminacyjny)
    CASE v_role_name
        WHEN 'ADMIN' THEN
            -- Jeśli Admin, usuwamy najpierw relacje (żeby nie było błędu kluczy), potem osobę
            DELETE FROM relationships WHERE child_id = p_person_id OR parent_id = p_person_id;
            DELETE FROM biographies WHERE person_id = p_person_id;
            DELETE FROM persons WHERE id = p_person_id;
        
        WHEN 'USER' THEN
            -- Jeśli zwykły User
            RAISE EXCEPTION 'Brak uprawnień. Tylko ADMIN może usuwać osoby.';
            
        ELSE
            -- Jeśli rola nieznana lub null
            RAISE EXCEPTION 'Użytkownik nieznany.';
    END CASE;
END;
$$;


ALTER PROCEDURE artur_zamorowski_kolokwium.delete_person_secure(IN p_admin_id integer, IN p_person_id integer) OWNER TO postgres;

--
-- Name: get_ancestors_report(integer); Type: FUNCTION; Schema: artur_zamorowski_kolokwium; Owner: postgres
--

CREATE FUNCTION artur_zamorowski_kolokwium.get_ancestors_report(target_person_id integer) RETURNS TABLE(id integer, first_name character varying, last_name character varying, generation integer)
    LANGUAGE plpgsql
    AS $$
BEGIN
    RETURN QUERY 
    -- Tutaj wklejamy nasze CTE (Recursive)
    WITH RECURSIVE genealogy_tree AS (
        -- 1. START (Szukamy osoby o podanym w argumencie ID)
        SELECT 
            p.id, 
            p.first_name, 
            p.last_name, 
            0 AS generation
        FROM persons p
        WHERE p.id = target_person_id  -- <--- TU JEST ZMIANA (używamy parametru)

        UNION ALL

        -- 2. REKURENCJA (Szukamy rodziców)
        SELECT 
            parent.id, 
            parent.first_name, 
            parent.last_name, 
            gt.generation + 1
        FROM persons parent
        JOIN relationships r ON parent.id = r.parent_id
        JOIN genealogy_tree gt ON r.child_id = gt.id
    )
    SELECT * FROM genealogy_tree;
END;
$$;


ALTER FUNCTION artur_zamorowski_kolokwium.get_ancestors_report(target_person_id integer) OWNER TO postgres;

--
-- Name: check_if_book_exist_already(); Type: FUNCTION; Schema: project_data; Owner: postgres
--

CREATE FUNCTION project_data.check_if_book_exist_already() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
    DELETE FROM project_data.old_user_input
    WHERE project_data.old_user_input.book_id = NEW.book_id;
    NEW.data := CURRENT_TIMESTAMP;
    RETURN NEW;
END
$$;


ALTER FUNCTION project_data.check_if_book_exist_already() OWNER TO postgres;

--
-- Name: filter_by_authors(integer, boolean, text[]); Type: FUNCTION; Schema: project_data; Owner: postgres
--

CREATE FUNCTION project_data.filter_by_authors(id_book integer, filtr_authors boolean, tab text[]) RETURNS TABLE(title text, author text, counts bigint)
    LANGUAGE plpgsql
    AS $$
    BEGIN
        RETURN QUERY
        SELECT * FROM project_data.get_similar_books(id_book, filtr_authors) a
        WHERE NOT a.author = ANY(
            SELECT x FROM UNNEST(tab) as x
        );
    END
$$;


ALTER FUNCTION project_data.filter_by_authors(id_book integer, filtr_authors boolean, tab text[]) OWNER TO postgres;

--
-- Name: get_reviews_count(integer); Type: FUNCTION; Schema: project_data; Owner: postgres
--

CREATE FUNCTION project_data.get_reviews_count(id_book integer) RETURNS integer
    LANGUAGE plpgsql
    AS $$
    BEGIN
        RETURN (SELECT count(*) FROM project_data.user_reviews u
            WHERE u.book_id = id_book);
    END
$$;


ALTER FUNCTION project_data.get_reviews_count(id_book integer) OWNER TO postgres;

--
-- Name: get_similar_books(integer, boolean); Type: FUNCTION; Schema: project_data; Owner: postgres
--

CREATE FUNCTION project_data.get_similar_books(id_book integer, filtr_authors boolean) RETURNS TABLE(title text, author text, counts bigint)
    LANGUAGE plpgsql
    AS $$
    BEGIN
        RETURN QUERY
        SELECT r.title, r.author, count(*) as VAR FROM project_data.books b
        JOIN project_data.user_reviews u
        ON id_book = u.book_id
        JOIN project_data.user_reviews o
        ON o.user_id = u.user_id
            AND o.book_id != u.book_id
        JOIN project_data.books r
        ON r.id = o.book_id
        WHERE id_book = b.id
        GROUP BY r.id, r.author, b.title, b.author
        HAVING (r.author != b.author OR filtr_authors = FALSE)
        order by count(*) DESC;
    END
$$;


ALTER FUNCTION project_data.get_similar_books(id_book integer, filtr_authors boolean) OWNER TO postgres;

--
-- Name: get_titles_and_indexes_by_substring(text); Type: FUNCTION; Schema: project_data; Owner: postgres
--

CREATE FUNCTION project_data.get_titles_and_indexes_by_substring(subst text) RETURNS TABLE(title text, id integer)
    LANGUAGE plpgsql
    AS $$
BEGIN
RETURN QUERY
SELECT b.title, b.id FROM project_data.books b
WHERE b.title ILIKE subst || '%'
ORDER BY project_data.get_reviews_count(b.id) DESC;
END
$$;


ALTER FUNCTION project_data.get_titles_and_indexes_by_substring(subst text) OWNER TO postgres;

SET default_tablespace = '';

SET default_table_access_method = heap;

--
-- Name: biographies; Type: TABLE; Schema: artur_zamorowski_kolokwium; Owner: postgres
--

CREATE TABLE artur_zamorowski_kolokwium.biographies (
    person_id integer NOT NULL,
    content text
);


ALTER TABLE artur_zamorowski_kolokwium.biographies OWNER TO postgres;

--
-- Name: persons; Type: TABLE; Schema: artur_zamorowski_kolokwium; Owner: postgres
--

CREATE TABLE artur_zamorowski_kolokwium.persons (
    id integer NOT NULL,
    first_name character varying(50),
    last_name character varying(50)
);


ALTER TABLE artur_zamorowski_kolokwium.persons OWNER TO postgres;

--
-- Name: persons_id_seq; Type: SEQUENCE; Schema: artur_zamorowski_kolokwium; Owner: postgres
--

CREATE SEQUENCE artur_zamorowski_kolokwium.persons_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE artur_zamorowski_kolokwium.persons_id_seq OWNER TO postgres;

--
-- Name: persons_id_seq; Type: SEQUENCE OWNED BY; Schema: artur_zamorowski_kolokwium; Owner: postgres
--

ALTER SEQUENCE artur_zamorowski_kolokwium.persons_id_seq OWNED BY artur_zamorowski_kolokwium.persons.id;


--
-- Name: relationships; Type: TABLE; Schema: artur_zamorowski_kolokwium; Owner: postgres
--

CREATE TABLE artur_zamorowski_kolokwium.relationships (
    id integer NOT NULL,
    child_id integer,
    parent_id integer
);


ALTER TABLE artur_zamorowski_kolokwium.relationships OWNER TO postgres;

--
-- Name: relationships_id_seq; Type: SEQUENCE; Schema: artur_zamorowski_kolokwium; Owner: postgres
--

CREATE SEQUENCE artur_zamorowski_kolokwium.relationships_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE artur_zamorowski_kolokwium.relationships_id_seq OWNER TO postgres;

--
-- Name: relationships_id_seq; Type: SEQUENCE OWNED BY; Schema: artur_zamorowski_kolokwium; Owner: postgres
--

ALTER SEQUENCE artur_zamorowski_kolokwium.relationships_id_seq OWNED BY artur_zamorowski_kolokwium.relationships.id;


--
-- Name: roles; Type: TABLE; Schema: artur_zamorowski_kolokwium; Owner: postgres
--

CREATE TABLE artur_zamorowski_kolokwium.roles (
    id integer NOT NULL,
    role_name character varying(20)
);


ALTER TABLE artur_zamorowski_kolokwium.roles OWNER TO postgres;

--
-- Name: roles_id_seq; Type: SEQUENCE; Schema: artur_zamorowski_kolokwium; Owner: postgres
--

CREATE SEQUENCE artur_zamorowski_kolokwium.roles_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE artur_zamorowski_kolokwium.roles_id_seq OWNER TO postgres;

--
-- Name: roles_id_seq; Type: SEQUENCE OWNED BY; Schema: artur_zamorowski_kolokwium; Owner: postgres
--

ALTER SEQUENCE artur_zamorowski_kolokwium.roles_id_seq OWNED BY artur_zamorowski_kolokwium.roles.id;


--
-- Name: users; Type: TABLE; Schema: artur_zamorowski_kolokwium; Owner: postgres
--

CREATE TABLE artur_zamorowski_kolokwium.users (
    id integer NOT NULL,
    username character varying(50),
    password character varying(50),
    role_id integer
);


ALTER TABLE artur_zamorowski_kolokwium.users OWNER TO postgres;

--
-- Name: users_id_seq; Type: SEQUENCE; Schema: artur_zamorowski_kolokwium; Owner: postgres
--

CREATE SEQUENCE artur_zamorowski_kolokwium.users_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE artur_zamorowski_kolokwium.users_id_seq OWNER TO postgres;

--
-- Name: users_id_seq; Type: SEQUENCE OWNED BY; Schema: artur_zamorowski_kolokwium; Owner: postgres
--

ALTER SEQUENCE artur_zamorowski_kolokwium.users_id_seq OWNED BY artur_zamorowski_kolokwium.users.id;


--
-- Name: v_family_list; Type: VIEW; Schema: artur_zamorowski_kolokwium; Owner: postgres
--

CREATE VIEW artur_zamorowski_kolokwium.v_family_list AS
 SELECT p.id,
    p.first_name,
    p.last_name,
    count(r.child_id) AS children_count
   FROM (artur_zamorowski_kolokwium.persons p
     LEFT JOIN artur_zamorowski_kolokwium.relationships r ON ((p.id = r.parent_id)))
  GROUP BY p.id, p.first_name, p.last_name;


ALTER TABLE artur_zamorowski_kolokwium.v_family_list OWNER TO postgres;

--
-- Name: v_family_readable; Type: VIEW; Schema: artur_zamorowski_kolokwium; Owner: postgres
--

CREATE VIEW artur_zamorowski_kolokwium.v_family_readable AS
 SELECT r.id AS relation_id,
    (((c.first_name)::text || ' '::text) || (c.last_name)::text) AS child_name,
    (((p.first_name)::text || ' '::text) || (p.last_name)::text) AS parent_name
   FROM ((artur_zamorowski_kolokwium.relationships r
     JOIN artur_zamorowski_kolokwium.persons c ON ((r.child_id = c.id)))
     JOIN artur_zamorowski_kolokwium.persons p ON ((r.parent_id = p.id)));


ALTER TABLE artur_zamorowski_kolokwium.v_family_readable OWNER TO postgres;

--
-- Name: books; Type: TABLE; Schema: project_data; Owner: postgres
--

CREATE TABLE project_data.books (
    id integer NOT NULL,
    title text,
    pub_year integer,
    num_page integer,
    author text,
    rating double precision,
    serie text,
    top_tag text,
    second_tag text,
    third_tag text,
    descript text
);


ALTER TABLE project_data.books OWNER TO postgres;

--
-- Name: old_user_input; Type: TABLE; Schema: project_data; Owner: postgres
--

CREATE TABLE project_data.old_user_input (
    data timestamp without time zone NOT NULL,
    book_id integer NOT NULL
);


ALTER TABLE project_data.old_user_input OWNER TO postgres;

--
-- Name: author_stats; Type: VIEW; Schema: project_data; Owner: postgres
--

CREATE VIEW project_data.author_stats AS
 SELECT b.author,
    count(*) AS positions
   FROM (project_data.old_user_input o
     JOIN project_data.books b ON ((b.id = o.book_id)))
  GROUP BY b.author
  ORDER BY (count(*)) DESC;


ALTER TABLE project_data.author_stats OWNER TO postgres;

--
-- Name: detail_reviews; Type: TABLE; Schema: project_data; Owner: postgres
--

CREATE TABLE project_data.detail_reviews (
    detail text,
    popularity integer,
    review_id uuid
);


ALTER TABLE project_data.detail_reviews OWNER TO postgres;

--
-- Name: get_counts; Type: VIEW; Schema: project_data; Owner: postgres
--

CREATE VIEW project_data.get_counts AS
 SELECT b.id,
    project_data.get_reviews_count(b.id) AS user_number
   FROM project_data.books b;


ALTER TABLE project_data.get_counts OWNER TO postgres;

--
-- Name: older_books; Type: VIEW; Schema: project_data; Owner: postgres
--

CREATE VIEW project_data.older_books AS
 SELECT b.title,
    o.data AS read_data
   FROM (project_data.old_user_input o
     JOIN project_data.books b ON ((b.id = o.book_id)))
  ORDER BY o.data DESC;


ALTER TABLE project_data.older_books OWNER TO postgres;

--
-- Name: user_reviews; Type: TABLE; Schema: project_data; Owner: postgres
--

CREATE TABLE project_data.user_reviews (
    user_id integer,
    book_id integer,
    rating integer,
    review_id uuid
);


ALTER TABLE project_data.user_reviews OWNER TO postgres;

--
-- Name: test; Type: TABLE; Schema: test_python; Owner: postgres
--

CREATE TABLE test_python.test (
    a integer,
    b text,
    c double precision
);


ALTER TABLE test_python.test OWNER TO postgres;

--
-- Name: persons id; Type: DEFAULT; Schema: artur_zamorowski_kolokwium; Owner: postgres
--

ALTER TABLE ONLY artur_zamorowski_kolokwium.persons ALTER COLUMN id SET DEFAULT nextval('artur_zamorowski_kolokwium.persons_id_seq'::regclass);


--
-- Name: relationships id; Type: DEFAULT; Schema: artur_zamorowski_kolokwium; Owner: postgres
--

ALTER TABLE ONLY artur_zamorowski_kolokwium.relationships ALTER COLUMN id SET DEFAULT nextval('artur_zamorowski_kolokwium.relationships_id_seq'::regclass);


--
-- Name: roles id; Type: DEFAULT; Schema: artur_zamorowski_kolokwium; Owner: postgres
--

ALTER TABLE ONLY artur_zamorowski_kolokwium.roles ALTER COLUMN id SET DEFAULT nextval('artur_zamorowski_kolokwium.roles_id_seq'::regclass);


--
-- Name: users id; Type: DEFAULT; Schema: artur_zamorowski_kolokwium; Owner: postgres
--

ALTER TABLE ONLY artur_zamorowski_kolokwium.users ALTER COLUMN id SET DEFAULT nextval('artur_zamorowski_kolokwium.users_id_seq'::regclass);


--
-- Name: biographies biographies_pkey; Type: CONSTRAINT; Schema: artur_zamorowski_kolokwium; Owner: postgres
--

ALTER TABLE ONLY artur_zamorowski_kolokwium.biographies
    ADD CONSTRAINT biographies_pkey PRIMARY KEY (person_id);


--
-- Name: persons persons_pkey; Type: CONSTRAINT; Schema: artur_zamorowski_kolokwium; Owner: postgres
--

ALTER TABLE ONLY artur_zamorowski_kolokwium.persons
    ADD CONSTRAINT persons_pkey PRIMARY KEY (id);


--
-- Name: relationships relationships_pkey; Type: CONSTRAINT; Schema: artur_zamorowski_kolokwium; Owner: postgres
--

ALTER TABLE ONLY artur_zamorowski_kolokwium.relationships
    ADD CONSTRAINT relationships_pkey PRIMARY KEY (id);


--
-- Name: roles roles_pkey; Type: CONSTRAINT; Schema: artur_zamorowski_kolokwium; Owner: postgres
--

ALTER TABLE ONLY artur_zamorowski_kolokwium.roles
    ADD CONSTRAINT roles_pkey PRIMARY KEY (id);


--
-- Name: users users_pkey; Type: CONSTRAINT; Schema: artur_zamorowski_kolokwium; Owner: postgres
--

ALTER TABLE ONLY artur_zamorowski_kolokwium.users
    ADD CONSTRAINT users_pkey PRIMARY KEY (id);


--
-- Name: books books_pkey; Type: CONSTRAINT; Schema: project_data; Owner: postgres
--

ALTER TABLE ONLY project_data.books
    ADD CONSTRAINT books_pkey PRIMARY KEY (id);


--
-- Name: idx_book; Type: INDEX; Schema: project_data; Owner: postgres
--

CREATE INDEX idx_book ON project_data.user_reviews USING btree (book_id);


--
-- Name: idx_book_title; Type: INDEX; Schema: project_data; Owner: postgres
--

CREATE INDEX idx_book_title ON project_data.books USING btree (title);


--
-- Name: idx_review; Type: INDEX; Schema: project_data; Owner: postgres
--

CREATE INDEX idx_review ON project_data.detail_reviews USING btree (review_id);


--
-- Name: idx_user; Type: INDEX; Schema: project_data; Owner: postgres
--

CREATE INDEX idx_user ON project_data.user_reviews USING btree (user_id);


--
-- Name: old_user_input trigger_check_book; Type: TRIGGER; Schema: project_data; Owner: postgres
--

CREATE TRIGGER trigger_check_book BEFORE INSERT ON project_data.old_user_input FOR EACH ROW EXECUTE FUNCTION project_data.check_if_book_exist_already();


--
-- Name: biographies fk_biographies_persons; Type: FK CONSTRAINT; Schema: artur_zamorowski_kolokwium; Owner: postgres
--

ALTER TABLE ONLY artur_zamorowski_kolokwium.biographies
    ADD CONSTRAINT fk_biographies_persons FOREIGN KEY (person_id) REFERENCES artur_zamorowski_kolokwium.persons(id);


--
-- Name: relationships fk_rel_child; Type: FK CONSTRAINT; Schema: artur_zamorowski_kolokwium; Owner: postgres
--

ALTER TABLE ONLY artur_zamorowski_kolokwium.relationships
    ADD CONSTRAINT fk_rel_child FOREIGN KEY (child_id) REFERENCES artur_zamorowski_kolokwium.persons(id);


--
-- Name: relationships fk_rel_parent; Type: FK CONSTRAINT; Schema: artur_zamorowski_kolokwium; Owner: postgres
--

ALTER TABLE ONLY artur_zamorowski_kolokwium.relationships
    ADD CONSTRAINT fk_rel_parent FOREIGN KEY (parent_id) REFERENCES artur_zamorowski_kolokwium.persons(id);


--
-- Name: users fk_users_roles; Type: FK CONSTRAINT; Schema: artur_zamorowski_kolokwium; Owner: postgres
--

ALTER TABLE ONLY artur_zamorowski_kolokwium.users
    ADD CONSTRAINT fk_users_roles FOREIGN KEY (role_id) REFERENCES artur_zamorowski_kolokwium.roles(id);


--
-- Name: old_user_input f_books; Type: FK CONSTRAINT; Schema: project_data; Owner: postgres
--

ALTER TABLE ONLY project_data.old_user_input
    ADD CONSTRAINT f_books FOREIGN KEY (book_id) REFERENCES project_data.books(id) NOT VALID;


--
-- PostgreSQL database dump complete
--

\unrestrict RUfsb1lLLQbCxne1OaGbwU0rWkmXsHHzQjeQUhvdHDB2tq1cO7kqdnxDcyyb6Gd

