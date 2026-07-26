import os
import tempfile

db_file = tempfile.NamedTemporaryFile(delete=False)
db_file.close()
os.environ["DREADBOUND_DB"] = db_file.name
os.environ["DREADBOUND_ORIGINS"] = "http://localhost"

from fastapi.testclient import TestClient
from backend.app import app


def test_account_save_conflict_and_delete():
    client = TestClient(app)
    credentials = {"email": "walker@example.test", "password": "correct-horse-battery", "nickname": "夜航者"}
    registered = client.post("/auth/register", json=credentials)
    assert registered.status_code == 200
    token = registered.json()["access_token"]
    headers = {"Authorization": f"Bearer {token}"}

    empty = client.get("/save", headers=headers)
    assert empty.status_code == 200
    assert empty.json()["revision"] == 0

    uploaded = client.put("/save", headers=headers, json={"revision": 0, "save_version": 11, "save": {"echo_shards": 9}})
    assert uploaded.status_code == 200
    assert uploaded.json()["revision"] == 1

    conflict = client.put("/save", headers=headers, json={"revision": 0, "save_version": 11, "save": {"echo_shards": 99}})
    assert conflict.status_code == 409
    assert conflict.json()["save"]["echo_shards"] == 9

    restored = client.get("/save", headers=headers)
    assert restored.json()["save"]["echo_shards"] == 9
    assert client.delete("/account", headers=headers).status_code == 200
    assert client.get("/save", headers=headers).status_code == 401


def test_async_society_and_authoritative_room():
    client = TestClient(app)
    first = {"email": "first@example.test", "password": "correct-horse-battery", "nickname": "甲"}
    second = {"email": "second@example.test", "password": "correct-horse-battery", "nickname": "乙"}
    token_a = client.post("/auth/register", json=first).json()["access_token"]
    token_b = client.post("/auth/register", json=second).json()["access_token"]
    headers_a = {"Authorization": f"Bearer {token_a}"}
    headers_b = {"Authorization": f"Bearer {token_b}"}

    package = {"package_id": "a:SAN-1", "action_code": "SAN-1", "faction_id": "drifters", "content_version": 17, "events": [{"event_id": "SAN-1:1", "event_type": "rescue", "world_id": "sanatorium", "choice": "help"}]}
    accepted = client.post("/society/actions", headers=headers_a, json=package)
    assert accepted.json() == {"accepted": True, "duplicate": False}
    assert client.post("/society/actions", headers=headers_a, json=package).json()["duplicate"] is True
    assert client.get("/society/week", headers=headers_b).json()["echoes"][0]["action_code"] == "SAN-1"

    created = client.post("/rooms", headers=headers_a, json={"seed": 4242}).json()
    room_id = created["snapshot"]["room_id"]
    joined = client.post(f"/rooms/{room_id}/join", headers=headers_b).json()
    assert len(joined["snapshot"]["players"]) == 2
    command = {"command_id": "move-b-1", "sequence": 1, "command_type": "move", "payload": {"x": 12, "y": -9}}
    moved = client.post(f"/rooms/{room_id}/commands", headers=headers_b, json=command)
    assert moved.status_code == 200 and moved.json()["revision"] == 2
    assert client.post(f"/rooms/{room_id}/commands", headers=headers_b, json=command).json()["duplicate"] is True
    stale = client.post(f"/rooms/{room_id}/commands", headers=headers_b, json={**command, "command_id": "bad-seq", "sequence": 3})
    assert stale.status_code == 409 and stale.json()["expected"] == 2
    restored = client.get(f"/rooms/{room_id}", headers=headers_b, params={"reconnect": joined["reconnect_token"]})
    assert restored.status_code == 200
    assert restored.json()["players"][list(restored.json()["players"].keys())[1]]["position"] == {"x": 12.0, "y": -9.0}


if __name__ == "__main__":
    test_account_save_conflict_and_delete()
    test_async_society_and_authoritative_room()
    os.unlink(db_file.name)
    print("Cloud backend test passed: register, revision conflict, restore and account deletion")
