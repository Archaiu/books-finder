CREATE OR REPLACE FUNCTION project_data.get_users_which_read_book(id INTEGER)
RETURNS TABLE(user_id INTEGER) AS $$
BEGIN
RETURN QUERY
SELECT u.user_id FROM project_data.user_reviews u
WHERE u.book_id = id;
END
$$ language plpgsql