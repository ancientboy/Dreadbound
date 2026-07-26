# Dreadbound cloud-save service

This optional service adds email authentication and revision-protected cloud saves. The game remains fully playable with local profiles when it is unavailable.

```bash
python -m venv .venv
. .venv/bin/activate
pip install -r backend/requirements.txt
DREADBOUND_ORIGINS=https://ancientboy.github.io uvicorn backend.app:app --host 0.0.0.0 --port 8787
```

Deploy behind HTTPS, set `DREADBOUND_DB` to persistent storage, and configure Godot's `cloud/api_url` to the public service URL. Never place an administrator secret in the Web export. Passwords use PBKDF2-HMAC-SHA256; bearer tokens are stored only as SHA-256 digests server-side. Production deployments should add rate limiting, email verification, backups, monitoring, and an external secrets manager.
