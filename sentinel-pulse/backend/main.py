from fastapi import FastAPI, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel
import redis
import psycopg2
from psycopg2.extras import RealDictCursor
import os
import time

app = FastAPI(root_path="/api")

# Add CORS middleware
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  # In production, specify the exact frontend domain
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Configuration from environment variables
REDIS_HOST = os.getenv("REDIS_HOST", "localhost")
REDIS_PORT = os.getenv("REDIS_PORT", 6379)
DB_HOST = os.getenv("POSTGRES_HOST", "localhost")
DB_NAME = os.getenv("POSTGRES_DB", "pulse_db")
DB_USER = os.getenv("POSTGRES_USER", "postgres")
DB_PASS = os.getenv("POSTGRES_PASSWORD")

# Initialize Redis
r = redis.Redis(host=REDIS_HOST, port=REDIS_PORT, decode_responses=True)

class Vote(BaseModel):
    candidate: str

@app.post("/vote")
async def cast_vote(vote: Vote):
    try:
        # Push vote to Redis list for the worker to process
        r.lpush("votes", vote.candidate)
        return {"status": "success", "message": f"Vote for {vote.candidate} recorded"}
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

@app.get("/results")
async def get_results():
    conn = None
    try:
        conn = psycopg2.connect(
            host=DB_HOST, database=DB_NAME, user=DB_USER, password=DB_PASS
        )
        cur = conn.cursor(cursor_factory=RealDictCursor)
        cur.execute("SELECT candidate, count FROM votes_count;")
        results = cur.fetchall()
        cur.close()
        return results
    except Exception as e:
        # In a real app, you'd handle the case where the table doesn't exist yet
        return {"status": "error", "message": str(e)}
    finally:
        if conn:
            conn.close()

@app.get("/health")
async def health():
    return {"status": "healthy"}
