import hashlib
import json
import os
import secrets
import sqlite3
import time
from contextlib import contextmanager

from fastapi import Depends, FastAPI, Header, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import JSONResponse
from pydantic import BaseModel, Field

DB_PATH = os.environ.get("DREADBOUND_DB", "dreadbound_cloud.sqlite3")
ALLOWED_ORIGINS = os.environ.get("DREADBOUND_ORIGINS", "https://ancientboy.github.io").split(",")
SESSION_DAYS = 30

app = FastAPI(title="Dreadbound Cloud Save", docs_url=None, redoc_url=None)
app.add_middleware(CORSMiddleware, allow_origins=ALLOWED_ORIGINS, allow_methods=["GET", "POST", "PUT", "DELETE"], allow_headers=["Authorization", "Content-Type"])


@contextmanager
def db():
    connection = sqlite3.connect(DB_PATH)
    connection.row_factory = sqlite3.Row
    try:
        yield connection
        connection.commit()
    finally:
        connection.close()


def init_db():
    with db() as connection:
        connection.executescript("""
        CREATE TABLE IF NOT EXISTS users (
          id TEXT PRIMARY KEY, email TEXT UNIQUE NOT NULL, nickname TEXT NOT NULL,
          password_hash TEXT NOT NULL, created_at INTEGER NOT NULL
        );
        CREATE TABLE IF NOT EXISTS sessions (
          token_hash TEXT PRIMARY KEY, user_id TEXT NOT NULL, expires_at INTEGER NOT NULL,
          FOREIGN KEY(user_id) REFERENCES users(id) ON DELETE CASCADE
        );
        CREATE TABLE IF NOT EXISTS saves (
          user_id TEXT PRIMARY KEY, revision INTEGER NOT NULL DEFAULT 0,
          save_version INTEGER NOT NULL DEFAULT 0, save_json TEXT NOT NULL DEFAULT '{}',
          updated_at INTEGER NOT NULL, FOREIGN KEY(user_id) REFERENCES users(id) ON DELETE CASCADE
        );
        """)


init_db()


class Credentials(BaseModel):
    email: str = Field(min_length=5, max_length=160)
    password: str = Field(min_length=10, max_length=200)
    nickname: str = Field(default="行者", min_length=1, max_length=16)


class SavePayload(BaseModel):
    revision: int = Field(ge=0)
    save_version: int = Field(ge=1)
    save: dict


def password_hash(password: str, salt: bytes | None = None) -> str:
    salt = salt or secrets.token_bytes(16)
    derived = hashlib.pbkdf2_hmac("sha256", password.encode(), salt, 310_000)
    return f"{salt.hex()}:{derived.hex()}"


def verify_password(password: str, encoded: str) -> bool:
    salt_hex, expected = encoded.split(":", 1)
    actual = password_hash(password, bytes.fromhex(salt_hex)).split(":", 1)[1]
    return secrets.compare_digest(actual, expected)


def new_session(connection: sqlite3.Connection, user_id: str) -> str:
    token = secrets.token_urlsafe(32)
    token_digest = hashlib.sha256(token.encode()).hexdigest()
    connection.execute("INSERT INTO sessions VALUES (?, ?, ?)", (token_digest, user_id, int(time.time()) + SESSION_DAYS * 86400))
    return token


def current_user(authorization: str = Header(default="")) -> str:
    if not authorization.startswith("Bearer "):
        raise HTTPException(401, "missing_session")
    digest = hashlib.sha256(authorization[7:].encode()).hexdigest()
    with db() as connection:
        row = connection.execute("SELECT user_id, expires_at FROM sessions WHERE token_hash = ?", (digest,)).fetchone()
    if not row or row["expires_at"] < time.time():
        raise HTTPException(401, "expired_session")
    return row["user_id"]


@app.post("/auth/register")
def register(credentials: Credentials):
    email = credentials.email.strip().lower()
    if "@" not in email:
        raise HTTPException(400, "invalid_email")
    user_id = secrets.token_hex(16)
    try:
        with db() as connection:
            connection.execute("INSERT INTO users VALUES (?, ?, ?, ?, ?)", (user_id, email, credentials.nickname.strip(), password_hash(credentials.password), int(time.time())))
            connection.execute("INSERT INTO saves VALUES (?, 0, 0, '{}', ?)", (user_id, int(time.time())))
            token = new_session(connection, user_id)
    except sqlite3.IntegrityError:
        raise HTTPException(409, "email_exists")
    return {"access_token": token, "user_id": user_id, "revision": 0}


@app.post("/auth/login")
def login(credentials: Credentials):
    with db() as connection:
        user = connection.execute("SELECT * FROM users WHERE email = ?", (credentials.email.strip().lower(),)).fetchone()
        if not user or not verify_password(credentials.password, user["password_hash"]):
            raise HTTPException(401, "invalid_credentials")
        save = connection.execute("SELECT revision FROM saves WHERE user_id = ?", (user["id"],)).fetchone()
        token = new_session(connection, user["id"])
    return {"access_token": token, "user_id": user["id"], "revision": save["revision"]}


@app.get("/save")
def get_save(user_id: str = Depends(current_user)):
    with db() as connection:
        row = connection.execute("SELECT * FROM saves WHERE user_id = ?", (user_id,)).fetchone()
    return {"revision": row["revision"], "save_version": row["save_version"], "save": json.loads(row["save_json"]), "updated_at": row["updated_at"]}


@app.put("/save")
def put_save(payload: SavePayload, user_id: str = Depends(current_user)):
    with db() as connection:
        current = connection.execute("SELECT * FROM saves WHERE user_id = ?", (user_id,)).fetchone()
        if payload.revision != current["revision"]:
            return JSONResponse(status_code=409, content={"error": "revision_conflict", "revision": current["revision"], "save_version": current["save_version"], "save": json.loads(current["save_json"]), "updated_at": current["updated_at"]})
        revision = current["revision"] + 1
        connection.execute("UPDATE saves SET revision=?, save_version=?, save_json=?, updated_at=? WHERE user_id=?", (revision, payload.save_version, json.dumps(payload.save, ensure_ascii=False), int(time.time()), user_id))
    return {"revision": revision}


@app.delete("/account")
def delete_account(user_id: str = Depends(current_user)):
    with db() as connection:
        connection.execute("DELETE FROM sessions WHERE user_id = ?", (user_id,))
        connection.execute("DELETE FROM saves WHERE user_id = ?", (user_id,))
        connection.execute("DELETE FROM users WHERE id = ?", (user_id,))
    return {"deleted": True}
