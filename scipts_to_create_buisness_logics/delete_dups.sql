DELETE FROM project_data.books b
USING project_data.books f
WHERE b.title = f.title
    AND 
    ((SELECT user_number FROM project_data.get_counts c
        WHERE c.id = b.id)
    < (SELECT user_number FROM project_data.get_counts c
        WHERE c.id = f.id)
    AND b.id != f.id
    OR (SELECT user_number FROM project_data.get_counts c
        WHERE c.id = b.id)
    = (SELECT user_number FROM project_data.get_counts c
        WHERE c.id = f.id)
    AND b.id > f.id);

CREATE OR REPLACE FUNCTION project_data.get_reviews_count(id_book INTEGER)
RETURNS INTEGER as $$
    BEGIN
        RETURN (SELECT count(*) FROM project_data.user_reviews u
            WHERE u.book_id = id_book);
    END
$$ language plpgsql;

CREATE OR REPLACE VIEW project_data.get_counts AS
    SELECT b.id AS id,
    project_data.get_reviews_count(b.id) AS user_number
    FROM project_data.books b

-- test
SELECT * FROM project_data.get_reviews_count(15881);
SELECT * FROM project_data.get_reviews_count(822148);

-- killer
DROP *