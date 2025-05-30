import sqlite3
from datetime import datetime
from contextlib import contextmanager

DATABASE_FILE = 'downloads.db'

def init_db():
    with get_db() as db:
        # Create initial table
        db.execute('''
            CREATE TABLE IF NOT EXISTS downloads (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                pid TEXT NOT NULL,
                title TEXT NOT NULL,
                status TEXT NOT NULL,
                created_at TIMESTAMP NOT NULL,
                completed_at TIMESTAMP
            )
        ''')
        
        # Check if file_path column exists
        columns = db.execute('PRAGMA table_info(downloads)').fetchall()
        column_names = [col[1] for col in columns]
        
        # Add file_path column if it doesn't exist
        if 'file_path' not in column_names:
            print("Adding file_path column to downloads table...")
            db.execute('ALTER TABLE downloads ADD COLUMN file_path TEXT')
            db.commit()

@contextmanager
def get_db():
    conn = sqlite3.connect(DATABASE_FILE)
    conn.row_factory = sqlite3.Row
    try:
        yield conn
    finally:
        conn.close()

def add_download(pid, title):
    with get_db() as db:
        db.execute('''
            INSERT INTO downloads (pid, title, status, created_at)
            VALUES (?, ?, ?, ?)
        ''', (pid, title, 'started', datetime.now()))
        db.commit()

def update_download_status(pid, status, file_path=None):
    with get_db() as db:
        if status == 'completed':
            db.execute('''
                UPDATE downloads 
                SET status = ?, completed_at = ?, file_path = ?
                WHERE pid = ? AND status != 'completed'
            ''', (status, datetime.now(), file_path, pid))
        else:
            db.execute('''
                UPDATE downloads 
                SET status = ?
                WHERE pid = ? AND status != 'completed'
            ''', (status, pid))
        db.commit()

def get_downloads(limit=50):
    with get_db() as db:
        return db.execute('''
            SELECT * FROM downloads 
            ORDER BY created_at DESC 
            LIMIT ?
        ''', (limit,)).fetchall() 