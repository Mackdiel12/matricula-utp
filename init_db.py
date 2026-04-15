import os
import psycopg2

def init_database():
    database_url = os.environ.get('DATABASE_URL')
    
    if not database_url:
        print("No DATABASE_URL found. Skipping database initialization.")
        return
    
    print("Connecting to database...")
    try:
        conn = psycopg2.connect(database_url)
        cur = conn.cursor()
        
        print("Reading SQL script...")
        with open('init_db.sql', 'r', encoding='utf-8') as f:
            sql_script = f.read()
        
        print("Executing SQL script...")
        cur.execute(sql_script)
        conn.commit()
        print("Database initialized successfully!")
        cur.close()
        conn.close()
    except Exception as e:
        print(f"Database init error (may be OK if tables exist): {e}")

if __name__ == '__main__':
    init_database()
