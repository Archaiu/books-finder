import psycopg2
import config

file_path = "data_to_projects/goodreads_interactions_fantasy_paranormal.csv"

DB_CONFIG = {
    "dbname": config.DB_NAME,
    "user": config.DB_USER,
    "password": config.DB_PASSWORD, 
    "host": config.DB_HOST,
    "port": config.DB_PORT
}

conn = psycopg2.connect(**DB_CONFIG)

copy_instruction = """
    COPY project_data.user_reviews( user_id, book_id, rating, review_id)
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