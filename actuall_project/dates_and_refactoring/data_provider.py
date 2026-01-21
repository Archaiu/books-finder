

from .database import get_cursor, change_values
from typing import List, Optional
import datetime


def get_books_with_start_as_string(word : str):
    cur = get_cursor()
    cur.execute("""
        SELECT * FROM project_data.get_titles_and_indexes_by_substring(%s);""", (word,))
    return cur.fetchall()

def get_books_to_recommend(id : int, /, include_author : bool = True, filtr_authors : Optional[List[str]] = None):
    cur = get_cursor()
    change_values("""INSERT INTO project_data.old_user_input
                VALUES (%s,%s);""",(datetime.datetime.now(),id))
    if (filtr_authors != None):
        cur.execute("""
            SELECT * FROM project_data.filter_by_authors(%s, %s, %s)""", (id, include_author, filtr_authors))
    else:
        cur.execute("""
            SELECT * FROM project_data.get_similar_books(%s, %s)""", (id, include_author))

    return cur.fetchall()

def get_info(book):
    cur = get_cursor()
    if isinstance(book, int):
        cur.execute("""SELECT * from project_data.books 
                    WHERE id=%s;""",(book,))
    else:
        cur.execute("""SELECT * from project_data.books
                    WHERE title=%s""",(book,))
    try:
        return cur.fetchall()[0]
    except IndexError:
        return None

def get_olds(number : int = 5):
    cur = get_cursor()
    cur.execute("""SELECT * FROM project_data.older_books
                LIMIT %s""",(number,))
    return cur.fetchall()

def remove_olds(id : int):
    cur = get_cursor()
    change_values("""DELETE FROM project_data.old_user_input o
                  WHERE %s = o.book_id;""",(id,))
    
def get_stats():
    cur = get_cursor()
    cur.execute("""SELECT * FROM project_data.author_stats;""")
    return cur.fetchall()



    