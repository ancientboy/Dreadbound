# Dreadbound cloud-save service

This optional service adds email authentication, revision-protected cloud saves, asynchronous community echoes, and authoritative 2–4 player room primitives. The game remains fully playable with local profiles when it is unavailable.

```bash
python -m venv .venv
. .venv/bin/activate
pip install -r backend/requirements.txt
DREADBOUND_ORIGINS=https://ancientboy.github.io uvicorn backend.app:app --host 0.0.0.0 --port 8787
```

Deploy behind HTTPS, set `DREADBOUND_DB` to persistent storage, set a durable random `DREADBOUND_ROOM_SECRET`, and configure Godot's `cloud/api_url` to the public service URL. Never place either secret in the Web export. Passwords use PBKDF2-HMAC-SHA256; bearer tokens are stored only as SHA-256 digests server-side.

## Social endpoints

- `POST /society/actions`: idempotently submit a whitelisted, privacy-minimized action package.
- `GET /society/week`: read faction totals and anonymized echoes for the current week.
- `POST /rooms`: create an authoritative seeded room.
- `POST /rooms/{room_id}/join`: join up to four players and receive a reconnect token.
- `GET /rooms/{room_id}?reconnect=...`: restore an authenticated snapshot.
- `POST /rooms/{room_id}/commands`: submit monotonic, idempotent player commands.

The current SQLite implementation is suitable for development and a single service process. Before public real-time launch, add rate limiting, email verification, backups, monitoring, an external secrets manager, transactional row locking or a single-writer room actor, and WebSocket transport for lower latency.
