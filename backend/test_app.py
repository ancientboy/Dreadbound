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


if __name__ == "__main__":
    test_account_save_conflict_and_delete()
    os.unlink(db_file.name)
    print("Cloud backend test passed: register, revision conflict, restore and account deletion")
