--
-- PostgreSQL database dump
--

\restrict x70zz85bflfk21VcbtI9rBdf1Nmamwm5aZKLRNEePSauXplx184PWCV6dx6r1cd

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
-- Name: old_user_input; Type: TABLE; Schema: project_data; Owner: postgres
--

CREATE TABLE project_data.old_user_input (
    data timestamp without time zone NOT NULL,
    book_id integer NOT NULL
);


ALTER TABLE project_data.old_user_input OWNER TO postgres;

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
-- Name: old_user_input f_books; Type: FK CONSTRAINT; Schema: project_data; Owner: postgres
--

ALTER TABLE ONLY project_data.old_user_input
    ADD CONSTRAINT f_books FOREIGN KEY (book_id) REFERENCES project_data.books(id) NOT VALID;


--
-- PostgreSQL database dump complete
--

\unrestrict x70zz85bflfk21VcbtI9rBdf1Nmamwm5aZKLRNEePSauXplx184PWCV6dx6r1cd

