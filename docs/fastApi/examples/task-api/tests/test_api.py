from datetime import datetime, timedelta, timezone
from types import SimpleNamespace

import jwt
import pytest
from fastapi.testclient import TestClient

from app.config import Settings
from app.dependencies import get_current_user
from app.main import create_app


def test_health_and_openapi(client):
    assert client.get("/health").json() == {"status": "ok"}
    schema = client.get("/openapi.json").json()
    assert schema["components"]["securitySchemes"]["OAuth2PasswordBearer"]
    assert "/tasks/{task_id}" in schema["paths"]


def test_task_flow(client, auth_headers):
    created = client.post("/tasks", json={"title": "  学习测试  "}, headers=auth_headers)
    assert created.status_code == 201
    task = created.json()
    assert task["title"] == "学习测试"
    assert task["completed"] is False
    task_id = task["id"]
    assert client.get(f"/tasks/{task_id}", headers=auth_headers).json() == task

    updated = client.patch(
        f"/tasks/{task_id}", json={"completed": True}, headers=auth_headers
    )
    assert updated.status_code == 200
    assert updated.json()["title"] == "学习测试"
    assert updated.json()["completed"] is True
    assert client.get("/tasks?completed=false", headers=auth_headers).json() == []
    assert len(client.get("/tasks?completed=true", headers=auth_headers).json()) == 1

    deleted = client.delete(f"/tasks/{task_id}", headers=auth_headers)
    assert deleted.status_code == 204
    assert deleted.content == b""
    assert client.get(f"/tasks/{task_id}", headers=auth_headers).status_code == 404
    assert client.get("/tasks", headers=auth_headers).json() == []


def test_register_conflict_and_response_filtering(client):
    payload = {"username": " Alice ", "password": "learn-fastapi-123"}
    created = client.post("/auth/register", json=payload)
    assert created.status_code == 201
    assert set(created.json()) == {"id", "username"}
    assert created.json()["username"] == "alice"
    assert client.post("/auth/register", json=payload).status_code == 409
    assert client.post(
        "/auth/register", json={"username": "bob", "password": payload["password"]}
    ).status_code == 201


@pytest.mark.parametrize("username", ["alice", "nobody"])
def test_wrong_login(client, auth_headers, username):
    response = client.post(
        "/auth/token", data={"username": username, "password": "wrong-password"}
    )
    assert response.status_code == 401
    assert response.headers["www-authenticate"] == "Bearer"
    assert response.json()["detail"] == "用户名或密码错误"


def test_me_and_password_is_hashed(client, auth_headers):
    from sqlalchemy import select

    from app.models import User
    from app.security import password_hash

    me = client.get("/auth/me", headers=auth_headers)
    assert me.status_code == 200
    assert set(me.json()) == {"id", "username"}
    with client.app.state.session_factory() as db:
        user = db.scalar(select(User).where(User.username == "alice"))
        assert user.password_hash != "learn-fastapi-123"
        assert password_hash.verify("learn-fastapi-123", user.password_hash)


@pytest.mark.parametrize("title", ["", "   ", "x" * 101])
def test_bad_title(client, auth_headers, title):
    response = client.post("/tasks", json={"title": title}, headers=auth_headers)
    assert response.status_code == 422


@pytest.mark.parametrize("query", ["limit=0", "limit=101", "offset=-1", "limit=abc"])
def test_bad_pagination(client, auth_headers, query):
    assert client.get(f"/tasks?{query}", headers=auth_headers).status_code == 422


def test_stable_pagination(client, auth_headers):
    ids = [
        client.post("/tasks", json={"title": f"任务 {i}"}, headers=auth_headers).json()["id"]
        for i in range(3)
    ]
    page = client.get("/tasks?limit=1&offset=1", headers=auth_headers)
    assert [task["id"] for task in page.json()] == [ids[1]]


@pytest.mark.parametrize("payload", [{"title": None}, {"completed": None}, {"title": "   "}])
def test_invalid_patch_preserves_task(client, auth_headers, payload):
    task = client.post("/tasks", json={"title": "原任务"}, headers=auth_headers).json()
    path = f"/tasks/{task['id']}"
    assert client.patch(path, json=payload, headers=auth_headers).status_code == 422
    assert client.get(path, headers=auth_headers).json() == task


def test_cannot_choose_task_owner(client, auth_headers):
    response = client.post(
        "/tasks", json={"title": "伪造所属用户", "owner_id": 999}, headers=auth_headers
    )
    assert response.status_code == 422


def test_user_isolation(client, auth_headers):
    task = client.post("/tasks", json={"title": "alice 的任务"}, headers=auth_headers).json()
    assert client.post(
        "/auth/register", json={"username": "bob", "password": "learn-fastapi-456"}
    ).status_code == 201
    login = client.post(
        "/auth/token", data={"username": "bob", "password": "learn-fastapi-456"}
    )
    bob_headers = {"Authorization": f"Bearer {login.json()['access_token']}"}
    assert client.get("/tasks", headers=bob_headers).json() == []
    path = f"/tasks/{task['id']}"
    assert client.get(path, headers=bob_headers).status_code == 404
    assert client.patch(path, json={"completed": True}, headers=bob_headers).status_code == 404
    assert client.delete(path, headers=bob_headers).status_code == 404
    assert client.get(path, headers=auth_headers).json() == task


@pytest.mark.parametrize("headers", [{}, {"Authorization": "Bearer not-a-jwt"}])
def test_unauthenticated(client, headers):
    response = client.get("/tasks", headers=headers)
    assert response.status_code == 401
    assert response.headers["www-authenticate"] == "Bearer"


@pytest.mark.parametrize("case", ["expired", "wrong-key", "missing-exp", "bad-sub", "deleted-user"])
def test_invalid_signed_tokens(client, auth_headers, case):
    settings = client.app.state.settings
    key = settings.secret_key.get_secret_value()
    now = datetime.now(timezone.utc)
    payload = {"sub": "1", "iat": now, "exp": now + timedelta(minutes=5)}
    if case == "expired":
        payload["exp"] = now - timedelta(minutes=1)
    elif case == "wrong-key":
        key = "other-test-key-" + "z" * 40
    elif case == "missing-exp":
        del payload["exp"]
    elif case == "bad-sub":
        payload["sub"] = "not-a-number"
    elif case == "deleted-user":
        payload["sub"] = "99999"
    token = jwt.encode(payload, key, algorithm="HS256")
    response = client.get("/tasks", headers={"Authorization": f"Bearer {token}"})
    assert response.status_code == 401
    assert response.headers["www-authenticate"] == "Bearer"


def test_dependency_override(application, client):
    application.dependency_overrides[get_current_user] = lambda: SimpleNamespace(
        id=7, username="test_user"
    )
    try:
        response = client.get("/auth/me")
        assert response.json() == {"id": 7, "username": "test_user"}
    finally:
        application.dependency_overrides.clear()
    assert client.get("/auth/me").status_code == 401


def test_data_survives_app_restart(tmp_path):
    settings = Settings(
        _env_file=None,
        secret_key="restart-test-key-" + "x" * 40,
        database_url=f"sqlite:///{tmp_path / 'persistent.db'}",
    )
    with TestClient(create_app(settings)) as first:
        first.post(
            "/auth/register", json={"username": "alice", "password": "learn-fastapi-123"}
        )
        token = first.post(
            "/auth/token", data={"username": "alice", "password": "learn-fastapi-123"}
        ).json()["access_token"]
        headers = {"Authorization": f"Bearer {token}"}
        assert first.post("/tasks", json={"title": "持久化任务"}, headers=headers).status_code == 201
    with TestClient(create_app(settings)) as second:
        response = second.get("/tasks", headers=headers)
        assert response.status_code == 200
        assert [task["title"] for task in response.json()] == ["持久化任务"]
