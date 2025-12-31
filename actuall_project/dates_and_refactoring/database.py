import psycopg2
from psycopg2.extras import RealDictCursor
import config


cursor = None
conn = None

def _start_connection():
    global cursor, conn
    conn = psycopg2.connect(
        dbname = config.DB_NAME,
        user = config.DB_USER,
        password = config.DB_PASSWORD,
        host = config.DB_HOST
    )

    cursor = conn.cursor(cursor_factory=RealDictCursor)

def get_cursor():
    if cursor == None:
        _start_connection()
    return cursor

def end_connection():
    cursor.close()
    conn.close()
    cursor = None
    conn = None

def change_values(text, args = ()):
    if cursor == None:
        _start_connection() 
    cursor.execute(text, args)
    conn.commit()

def get_connection():
    if conn == None:
        _start_connection()
    return conn
    