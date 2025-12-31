CREATE OR REPLACE FUNCTION project_data.get_titles_and_indexes_by_substring(subst TEXT)
RETURNS TABLE (title TEXT, id INT) AS $$
BEGIN
RETURN QUERY
SELECT b.title, b.id FROM project_data.books b
WHERE b.title ILIKE subst || '%'
ORDER BY project_data.get_reviews_count(b.id) DESC;
END
$$ language plpgsql;


SELECT count(*) FROM project_data.get_users_which_read_book(
(SELECT id FROM project_data.get_titles_and_indexes_by_substring('Fellowship of') LIMIT 1)
);

CREATE OR REPLACE FUNCTION project_data.

    WITH specific_book AS (
        SELECT id FROM project_data.get_titles_and_indexes_by_substring('fellowship of ') LIMIT 1
    )

CREATE OR REPLACE FUNCTION project_data.get_similar_books(id_book INTEGER, filtr_authors BOOLEAN)
    RETURNS TABLE(title TEXT, author TEXT, counts BIGINT) as $$
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
        HAVING r.author != b.author OR filtr_authors = FALSE
        order by count(*) DESC;
    END
$$ language plpgsql;

SELECT b.title, b.id, count(*) AS VAR from project_data.books b
JOIN project_data.user_reviews u
on u.book_id = b.id
WHERE b.title = 'Mistborn'
GROUP BY b.id, b.title
ORDER BY b.id;

SELECT * FROM project_data.get_titles_and_indexes_by_substring('Mist')

SELECT * FROM project_data.get_similar_books((SELECT id FROM project_data.get_titles_and_indexes_by_substring('The Eye of the World') LIMIT 1), FALSE) LIMIT 10;

SELECT * FROM project_data.filter_by_authors((SELECT id FROM project_data.get_titles_and_indexes_by_substring('The Eye of the World') LIMIT 1), FALSE, ARRAY['J.K. Rowling']) LIMIT 10;

CREATE OR REPLACE FUNCTION project_data.filter_by_authors(id_book INTEGER, filtr_authors BOOLEAN, tab TEXT[])
RETURNS TABLE(title TEXT, author TEXT, counts BIGINT) as $$
    BEGIN
        RETURN QUERY
        SELECT * FROM project_data.get_similar_books(id_book, filtr_authors) a
        WHERE NOT a.author = ANY(
            SELECT x FROM UNNEST(tab) as x
        );
    END
$$ language plpgsql;

CREATE OR REPLACE TRIGGER project_data.update_date
BEFORE INSERT ON project_data.old_user_input
FOR EACH ROW

CREATE OR REPLACE FUNCTION project_data.check_if_book_exist_already()
RETURNS TRIGGER AS $$
BEGIN
    DELETE FROM project_data.old_user_input
    WHERE project_data.old_user_input.book_id = NEW.book_id;
    NEW.data := CURRENT_TIMESTAMP;
    RETURN NEW;
END
$$ language plpgsql;

CREATE OR REPLACE TRIGGER trigger_check_book
BEFORE INSERT ON project_data.old_user_input
FOR EACH ROW
EXECUTE FUNCTION project_data.check_if_book_exist_already();

