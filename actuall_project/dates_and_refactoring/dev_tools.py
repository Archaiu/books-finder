from .database import get_cursor, get_connection
from typing import List, Tuple

def add_new_books(path : str):
    cur = get_cursor()
    with open(path) as file:
        for line in file:
            line = line.strip()
            cur.execute("""INSERT INTO project_data.books
                        VALUES(%s, %s, %s, %s, %s,%s, %s, %s, %s, %s);""",
                        tuple(line.split(",")))
        conn.commit()

def delete_books(books : List[int]):
    cur = get_cursor()
    cur.execute("""DELETE FROM project_data.old_user_input o
                WHERE o.book_id IN ( SELECT unnest(%s::int[]))""", (books,))
    cur.execute("""DELETE FROM project_data.user_reviews u
                WHERE u.book_id IN (SELECT unnest(%s::int[]));""", (books,))
    cur.execute("""DELETE FROM project_data.books b
                WHERE b.id IN (SELECT unnest(%s::int[]));""", (books,))

    get_connection().commit()

def add_new_relations(path : str):
    cur = get_cursor()
    with open(path) as file:
        for line in file:
            line = line.strip()
            cur.execute("""INSERT INTO project_data.user_reviws
                        VALUES(%s, %s);""",
                        line[0], line[1])
        get_connection().commit()
    

