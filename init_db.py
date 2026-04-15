import os
import psycopg2

def init_database():
    database_url = os.environ.get('DATABASE_URL')
    
    if not database_url:
        print("No DATABASE_URL found. Skipping database initialization.")
        return
    
    print("Connecting to database...")
    conn = psycopg2.connect(database_url)
    cur = conn.cursor()
    
    # Leer y ejecutar el script SQL
    print("Reading SQL script...")
    with open('init_db.sql', 'r') as f:
        sql_script = f.read()
    
    print("Executing SQL script...")
    try:
        cur.execute(sql_script)
        conn.commit()
        print("Database initialized successfully!")
    except Exception as e:
        print(f"Error (might be OK if tables exist): {e}")
        conn.rollback()
    finally:
        cur.close()
        conn.close()

if __name__ == '__main__':
    init_database()
