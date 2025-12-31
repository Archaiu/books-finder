import psycopg2
import config

file_path = "data_to_projects/goodreads_books_fantasy_paranormal.csv"

DB_CONFIG = {
    "dbname": config.DB_NAME,
    "user": config.DB_USER,
    "password": config.DB_PASSWORD, 
    "host": config.DB_HOST,
    "port": config.DB_PORT
}

conn = psycopg2.connect(**DB_CONFIG)

copy_instruction = """
    COPY project_data.books( id, title, pub_year, num_page, author, rating, serie, top_tag, second_tag, third_tag, descript)
    FROM STDIN
    WITH (
        FORMAT CSV,
        HEADER true,
        DELIMITER ',',
        QUOTE '"',
        NULL ''
    )
"""

cur = conn.cursor()

cur


with open(file_path, encoding='utf-8') as file:
    print("Start copying")
    cur.copy_expert(copy_instruction, file)

conn.commit()