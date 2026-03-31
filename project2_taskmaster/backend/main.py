from fastapi import FastAPI, HTTPException
from pydantic import BaseModel
from typing import List, Optional
from datetime import datetime
import sqlite3
import json

app = FastAPI(title="TaskMaster API")

# DB Setup
DB_PATH = "tasks.db"

def init_db():
    with sqlite3.connect(DB_PATH) as conn:
        conn.execute('''
            CREATE TABLE IF NOT EXISTS tasks (
                id TEXT PRIMARY KEY,
                title TEXT NOT NULL,
                is_done BOOLEAN DEFAULT 0,
                created_at TEXT NOT NULL,
                priority TEXT DEFAULT 'medium'
            )
        ''')

init_db()

class Task(BaseModel):
    id: str
    title: str
    is_done: bool = False
    created_at: datetime
    priority: str = "medium"

class TaskCreate(BaseModel):
    title: str
    priority: str = "medium"

@app.get("/api/v1/tasks", response_model=List[Task])
async def get_tasks():
    with sqlite3.connect(DB_PATH) as conn:
        cursor = conn.execute("SELECT id, title, is_done, created_at, priority FROM tasks ORDER BY created_at DESC")
        rows = cursor.fetchall()
        return [
            Task(id=r[0], title=r[1], is_done=bool(r[2]), created_at=datetime.fromisoformat(r[3]), priority=r[4])
            for r in rows
        ]

@app.post("/api/v1/tasks", response_model=Task)
async def create_task(task_in: TaskCreate):
    task = Task(
        id=str(int(datetime.now().timestamp() * 1000)),
        title=task_in.title,
        created_at=datetime.now(),
        priority=task_in.priority
    )
    with sqlite3.connect(DB_PATH) as conn:
        conn.execute(
            "INSERT INTO tasks (id, title, is_done, created_at, priority) VALUES (?, ?, ?, ?, ?)",
            (task.id, task.title, task.is_done, task.created_at.isoformat(), task.priority)
        )
    return task

@app.put("/api/v1/tasks/{task_id}", response_model=Task)
async def update_task(task_id: str, is_done: Optional[bool] = None, title: Optional[str] = None):
    with sqlite3.connect(DB_PATH) as conn:
        if is_done is not None:
            conn.execute("UPDATE tasks SET is_done = ? WHERE id = ?", (int(is_done), task_id))
        if title is not None:
            conn.execute("UPDATE tasks SET title = ? WHERE id = ?", (title, task_id))
        
        cursor = conn.execute("SELECT id, title, is_done, created_at, priority FROM tasks WHERE id = ?", (task_id,))
        r = cursor.fetchone()
        if not r:
            raise HTTPException(status_code=404, detail="Task not found")
        return Task(id=r[0], title=r[1], is_done=bool(r[2]), created_at=datetime.fromisoformat(r[3]), priority=r[4])

@app.delete("/api/v1/tasks/{task_id}")
async def delete_task(task_id: str):
    with sqlite3.connect(DB_PATH) as conn:
        conn.execute("DELETE FROM tasks WHERE id = ?", (task_id,))
    return {"status": "ok"}

@app.delete("/api/v1/tasks/clear/completed")
async def clear_completed():
    with sqlite3.connect(DB_PATH) as conn:
        conn.execute("DELETE FROM tasks WHERE is_done = 1")
    return {"status": "ok"}

if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=8001)
