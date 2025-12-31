SET search_path = project_data;

CREATE TABLE books
(
    id INTEGER PRIMARY KEY,
    title TEXT,
    pub_year INTEGER,
    num_page INTEGER,
    author TEXT,
    rating FLOAT,
    serie TEXT,
    top_tag TEXT,
    second_tag TEXT,
    third_tag TEXT,
    descript TEXT
)
