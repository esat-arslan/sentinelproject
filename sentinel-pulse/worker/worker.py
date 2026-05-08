import redis
import psycopg2
import os
import time

REDIS_HOST = os.getenv("REDIS_HOST", "localhost")
REDIS_PORT = os.getenv("REDIS_PORT", 6379)
DB_HOST = os.getenv("POSTGRES_HOST", "localhost")
DB_NAME = os.getenv("POSTGRES_DB", "pulse_db")
DB_USER = os.getenv("POSTGRES_USER", "postgres")
DB_PASS = os.getenv("POSTGRES_PASSWORD", "password")

def init_db():
    print("Initializing database...")
    while True:
        try:
            conn = psycopg2.connect(
                host=DB_HOST, database=DB_NAME, user=DB_USER, password=DB_PASS
            )
            cur = conn.cursor()
            cur.execute("""
                CREATE TABLE IF NOT EXISTS votes_count (
                    candidate VARCHAR(255) PRIMARY KEY,
                    count INTEGER DEFAULT 0
                );
            """)
            # Pre-populate some candidates if empty
            cur.execute("SELECT COUNT(*) FROM votes_count;")
            if cur.fetchone()[0] == 0:
                cur.execute("INSERT INTO votes_count (candidate, count) VALUES ('Docker', 0), ('Kubernetes', 0), ('Terraform', 0);")
            
            conn.commit()
            cur.close()
            conn.close()
            print("Database initialized.")
            break
        except Exception as e:
            print(f"Waiting for database... {e}")
            time.sleep(2)

def process_votes():
    r = redis.Redis(host=REDIS_HOST, port=REDIS_PORT, decode_responses=True)
    print("Worker started. Listening for votes...")
    
    while True:
        # Block until a vote is available in the 'votes' list
        vote = r.brpop("votes", timeout=5)
        if vote:
            candidate = vote[1]
            print(f"Processing vote for: {candidate}")
            try:
                conn = psycopg2.connect(
                    host=DB_HOST, database=DB_NAME, user=DB_USER, password=DB_PASS
                )
                cur = conn.cursor()
                cur.execute("""
                    INSERT INTO votes_count (candidate, count) 
                    VALUES (%s, 1) 
                    ON CONFLICT (candidate) 
                    DO UPDATE SET count = votes_count.count + 1;
                """, (candidate,))
                conn.commit()
                cur.close()
                conn.close()
            except Exception as e:
                print(f"Error updating database: {e}")
        else:
            # Idle
            pass

if __name__ == "__main__":
    init_db()
    process_votes()
