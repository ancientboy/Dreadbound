import hashlib
import hmac
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
ROOM_SECRET = os.environ.get("DREADBOUND_ROOM_SECRET", secrets.token_hex(32))
ASYNC_EVENT_TYPES = {"faction_help", "faction_betrayal", "promise_kept", "promise_broken", "rescue", "abandon", "run_settled"}
ROOM_COMMANDS = {"move", "interact", "attack", "choose", "extract", "claim_loot"}

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
        CREATE TABLE IF NOT EXISTS community_actions (
          package_id TEXT PRIMARY KEY, user_id TEXT NOT NULL, week INTEGER NOT NULL,
          action_code TEXT NOT NULL, faction_id TEXT NOT NULL, events_json TEXT NOT NULL,
          created_at INTEGER NOT NULL, FOREIGN KEY(user_id) REFERENCES users(id) ON DELETE CASCADE
        );
        CREATE TABLE IF NOT EXISTS multiplayer_rooms (
          room_id TEXT PRIMARY KEY, host_id TEXT NOT NULL, seed INTEGER NOT NULL,
          revision INTEGER NOT NULL DEFAULT 0, state_json TEXT NOT NULL, updated_at INTEGER NOT NULL
        );
        CREATE TABLE IF NOT EXISTS multiplayer_commands (
          command_id TEXT PRIMARY KEY, room_id TEXT NOT NULL, user_id TEXT NOT NULL,
          sequence INTEGER NOT NULL, command_type TEXT NOT NULL, result_json TEXT NOT NULL,
          created_at INTEGER NOT NULL, FOREIGN KEY(room_id) REFERENCES multiplayer_rooms(room_id) ON DELETE CASCADE
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


class CommunityPayload(BaseModel):
    package_id: str = Field(min_length=3, max_length=160)
    action_code: str = Field(min_length=3, max_length=64)
    faction_id: str = Field(min_length=2, max_length=40)
    content_version: int = Field(ge=1)
    events: list[dict] = Field(max_length=32)


class RoomCreatePayload(BaseModel):
    seed: int


class RoomCommandPayload(BaseModel):
    command_id: str = Field(min_length=3, max_length=160)
    sequence: int = Field(ge=1)
    command_type: str
    payload: dict = Field(default_factory=dict)


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


def week_id() -> int:
    return int(time.time()) // (7 * 86400)


def reconnect_token(room_id: str, user_id: str) -> str:
    return hmac.new(ROOM_SECRET.encode(), f"{room_id}|{user_id}".encode(), hashlib.sha256).hexdigest()


def room_snapshot(row: sqlite3.Row) -> dict:
    state = json.loads(row["state_json"])
    return {"room_id": row["room_id"], "seed": row["seed"], "revision": row["revision"], **state}


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


@app.post("/society/actions")
def submit_community_action(payload: CommunityPayload, user_id: str = Depends(current_user)):
    if any(str(event.get("event_type", "")) not in ASYNC_EVENT_TYPES for event in payload.events):
        raise HTTPException(400, "unsupported_event")
    safe_events = [
        {
            "event_id": str(event.get("event_id", ""))[:160],
            "event_type": str(event.get("event_type", "")),
            "world_id": str(event.get("world_id", ""))[:40],
            "choice": str(event.get("choice", ""))[:80],
        }
        for event in payload.events
    ]
    try:
        with db() as connection:
            connection.execute(
                "INSERT INTO community_actions VALUES (?, ?, ?, ?, ?, ?, ?)",
                (payload.package_id, user_id, week_id(), payload.action_code, payload.faction_id, json.dumps(safe_events, ensure_ascii=False), int(time.time())),
            )
    except sqlite3.IntegrityError:
        return {"accepted": True, "duplicate": True}
    return {"accepted": True, "duplicate": False}


@app.get("/society/week")
def community_week(user_id: str = Depends(current_user)):
    with db() as connection:
        rows = connection.execute(
            "SELECT package_id, user_id, action_code, faction_id, events_json FROM community_actions WHERE week = ? ORDER BY package_id",
            (week_id(),),
        ).fetchall()
    factions: dict[str, int] = {}
    echoes = []
    for row in rows:
        factions[row["faction_id"]] = factions.get(row["faction_id"], 0) + 1
        if row["user_id"] != user_id and len(echoes) < 12:
            echoes.append({"echo_id": hashlib.sha256(row["package_id"].encode()).hexdigest()[:12], "action_code": row["action_code"], "faction_id": row["faction_id"], "event_count": len(json.loads(row["events_json"]))})
    return {"week": week_id(), "participants": len(rows), "factions": factions, "echoes": echoes}


@app.post("/rooms")
def create_room(payload: RoomCreatePayload, user_id: str = Depends(current_user)):
    room_id = secrets.token_urlsafe(8)
    state = {"players": {user_id: {"last_sequence": 0, "position": {"x": 0.0, "y": 0.0}}}, "loot_claims": {}, "events": []}
    with db() as connection:
        connection.execute("INSERT INTO multiplayer_rooms VALUES (?, ?, ?, 0, ?, ?)", (room_id, user_id, payload.seed, json.dumps(state), int(time.time())))
    return {"reconnect_token": reconnect_token(room_id, user_id), "snapshot": {"room_id": room_id, "seed": payload.seed, "revision": 0, **state}}


@app.post("/rooms/{room_id}/join")
def join_room(room_id: str, user_id: str = Depends(current_user)):
    with db() as connection:
        row = connection.execute("SELECT * FROM multiplayer_rooms WHERE room_id = ?", (room_id,)).fetchone()
        if not row:
            raise HTTPException(404, "room_not_found")
        state = json.loads(row["state_json"])
        if user_id not in state["players"] and len(state["players"]) >= 4:
            raise HTTPException(409, "room_full")
        if user_id not in state["players"]:
            state["players"][user_id] = {"last_sequence": 0, "position": {"x": 0.0, "y": 0.0}}
            connection.execute("UPDATE multiplayer_rooms SET revision=revision+1, state_json=?, updated_at=? WHERE room_id=?", (json.dumps(state), int(time.time()), room_id))
            row = connection.execute("SELECT * FROM multiplayer_rooms WHERE room_id = ?", (room_id,)).fetchone()
    return {"reconnect_token": reconnect_token(room_id, user_id), "snapshot": room_snapshot(row)}


@app.get("/rooms/{room_id}")
def get_room(room_id: str, reconnect: str = "", user_id: str = Depends(current_user)):
    if not hmac.compare_digest(reconnect, reconnect_token(room_id, user_id)):
        raise HTTPException(403, "invalid_reconnect_token")
    with db() as connection:
        row = connection.execute("SELECT * FROM multiplayer_rooms WHERE room_id = ?", (room_id,)).fetchone()
    if not row:
        raise HTTPException(404, "room_not_found")
    snapshot = room_snapshot(row)
    if user_id not in snapshot["players"]:
        raise HTTPException(403, "not_room_member")
    return snapshot


@app.post("/rooms/{room_id}/commands")
def room_command(room_id: str, payload: RoomCommandPayload, user_id: str = Depends(current_user)):
    if payload.command_type not in ROOM_COMMANDS:
        raise HTTPException(400, "unsupported_command")
    with db() as connection:
        duplicate = connection.execute("SELECT result_json FROM multiplayer_commands WHERE command_id = ?", (payload.command_id,)).fetchone()
        if duplicate:
            return {"accepted": True, "duplicate": True, "result": json.loads(duplicate["result_json"])}
        row = connection.execute("SELECT * FROM multiplayer_rooms WHERE room_id = ?", (room_id,)).fetchone()
        if not row:
            raise HTTPException(404, "room_not_found")
        state = json.loads(row["state_json"])
        player = state["players"].get(user_id)
        if not player:
            raise HTTPException(403, "not_room_member")
        expected = int(player["last_sequence"]) + 1
        if payload.sequence != expected:
            return JSONResponse(status_code=409, content={"error": "sequence_conflict", "expected": expected, "revision": row["revision"]})
        result = apply_room_command(state, user_id, payload.command_type, payload.payload)
        player["last_sequence"] = payload.sequence
        revision = int(row["revision"]) + 1
        state["events"].append({"revision": revision, "user_id": user_id, "type": payload.command_type, "result": result})
        state["events"] = state["events"][-128:]
        connection.execute("UPDATE multiplayer_rooms SET revision=?, state_json=?, updated_at=? WHERE room_id=?", (revision, json.dumps(state), int(time.time()), room_id))
        connection.execute("INSERT INTO multiplayer_commands VALUES (?, ?, ?, ?, ?, ?, ?)", (payload.command_id, room_id, user_id, payload.sequence, payload.command_type, json.dumps(result), int(time.time())))
    return {"accepted": True, "duplicate": False, "revision": revision, "result": result}


def apply_room_command(state: dict, user_id: str, command_type: str, payload: dict) -> dict:
    if command_type == "move":
        position = {"x": max(-4096.0, min(4096.0, float(payload.get("x", 0.0)))), "y": max(-4096.0, min(4096.0, float(payload.get("y", 0.0))))}
        state["players"][user_id]["position"] = position
        return {"position": position}
    if command_type == "claim_loot":
        loot_id = str(payload.get("loot_id", ""))[:80]
        if not loot_id:
            raise HTTPException(400, "missing_loot")
        if loot_id in state["loot_claims"]:
            raise HTTPException(409, "loot_already_claimed")
        state["loot_claims"][loot_id] = user_id
        return {"loot_id": loot_id, "owner": user_id}
    return {"server_validated": True, **{key: value for key, value in payload.items() if key in {"target_id", "choice", "exit_id"}}}


@app.delete("/account")
def delete_account(user_id: str = Depends(current_user)):
    with db() as connection:
        connection.execute("DELETE FROM sessions WHERE user_id = ?", (user_id,))
        connection.execute("DELETE FROM saves WHERE user_id = ?", (user_id,))
        connection.execute("DELETE FROM users WHERE id = ?", (user_id,))
    return {"deleted": True}
