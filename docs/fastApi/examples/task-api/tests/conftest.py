import pytest
from fastapi.testclient import TestClient

from app.config import Settings
from app.main import create_app


@pytest.fixture
def application(tmp_path):
    settings = Settings(
        _env_file=None,
        secret_key="test-key-" + "x" * 40,
        database_url=f"sqlite:///{tmp_path / 'test.db'}",
        access_token_expire_minutes=30,
    )
    return create_app(settings)


@pytest.fixture
def client(application):
    with TestClient(application) as test_client:
        yield test_client


@pytest.fixture
def auth_headers(client):
    response = client.post(
        "/auth/register",
        json={"username": "alice", "password": "learn-fastapi-123"},
    )
    assert response.status_code == 201
    login = client.post(
        "/auth/token",
        data={"username": "alice", "password": "learn-fastapi-123"},
    )
    assert login.status_code == 200
    return {"Authorization": f"Bearer {login.json()['access_token']}"}
