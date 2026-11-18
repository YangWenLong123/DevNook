# 10. 接口测试

本章目标：使用 pytest 与 TestClient 自动验证接口行为，并让测试数据库、配置和依赖与开发环境隔离。

## 1. 测试要验证行为

优先覆盖用户可观察的约定：创建成功、错误输入被拒绝、登录失败返回 401、其他用户不能修改任务、删除返回空响应。不要仅仅验证“某个内部函数被调用了一次”。

| 场景 | 预期 |
| --- | --- |
| 注册新用户 | 201，响应不含密码或哈希 |
| 重复用户名 | 409 |
| 错误密码、无效或过期 Token | 401，带 Bearer challenge |
| 空标题、非法分页、显式 null | 422 |
| 查询他人的任务 | 404 |
| 删除自己的任务 | 204，没有响应体 |

## 2. 安装和运行

在配套项目目录操作：

```bash
python -m pip install -r requirements-dev.txt
python -m pytest -q
```

pytest 默认发现名为 `test_*.py` 的文件与 `test_*` 函数。`assert` 失败会给出比较结果。

## 3. 测试应用与独立数据库

下面是配套项目 `tests/conftest.py` 的主要结构：

```python
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
```

`tmp_path` 为每个测试提供临时目录，测试不会读写开发的 `tasks.db`。`_env_file=None` 禁止读取 `.env`，重要配置再显式传入，避免本地配置影响测试。

使用 `with TestClient(...)` 执行应用 lifespan。单纯创建客户端对象不保证自动运行启动与关闭逻辑。

## 4. 一个完整 CRUD 测试

```python
def test_task_flow(client):
    registration = client.post(
        "/auth/register",
        json={"username": "alice", "password": "learn-fastapi-123"},
    )
    assert registration.status_code == 201
    assert set(registration.json()) == {"id", "username"}

    login = client.post(
        "/auth/token",
        data={"username": "alice", "password": "learn-fastapi-123"},
    )
    assert login.status_code == 200
    headers = {"Authorization": f"Bearer {login.json()['access_token']}"}

    created = client.post("/tasks", json={"title": "学习测试"}, headers=headers)
    assert created.status_code == 201
    task_id = created.json()["id"]

    updated = client.patch(
        f"/tasks/{task_id}", json={"completed": True}, headers=headers,
    )
    assert updated.status_code == 200
    assert updated.json()["title"] == "学习测试"
    assert updated.json()["completed"] is True

    deleted = client.delete(f"/tasks/{task_id}", headers=headers)
    assert deleted.status_code == 204
    assert deleted.content == b""
    assert client.get(f"/tasks/{task_id}", headers=headers).status_code == 404
```

登录用 `data=` 发送表单；注册和创建任务用 `json=`。测试同时验证 PATCH 没有覆盖未提交的标题。

## 5. 使用参数化覆盖错误输入

```python
import pytest


@pytest.mark.parametrize("title", ["", "   ", "x" * 101])
def test_bad_title(client, auth_headers, title):
    response = client.post("/tasks", json={"title": title}, headers=auth_headers)
    assert response.status_code == 422
```

`auth_headers` 是配套测试中的 fixture，它先注册并登录，再返回请求头。参数化让同一行为使用不同输入验证，不必复制整个测试函数。

## 6. 依赖覆盖

如果测试关注路由行为而不是登录，可以覆盖当前用户依赖。下面是放在配套项目中的独立测试例子：

```python
from types import SimpleNamespace

from app.dependencies import get_current_user


def test_me_with_override(application, client):
    application.dependency_overrides[get_current_user] = lambda: SimpleNamespace(
        id=7, username="test_user",
    )
    try:
        response = client.get("/auth/me")
        assert response.json() == {"id": 7, "username": "test_user"}
    finally:
        application.dependency_overrides.clear()
```

覆盖只用于适合隔离的测试。鉴权集成测试必须使用真实的签发与校验链路，否则发现不了过期 Token、算法配置或表单格式的问题。

如果覆盖数据库依赖，测试会话必须来自测试引擎。不要仅更换路由中的数据库对象，却让认证依赖继续访问真实数据库。

## 7. SQLite 测试中的线程问题

文件型临时 SQLite 比较容易理解。若使用内存 SQLite，不同连接可能看见不同数据库；需要按场景使用 `StaticPool` 共享连接，并配置 `check_same_thread=False`。

共享内存连接的策略适合受控测试，不代表可以在生产中并发共用一个会话。数据库特有的约束和 SQL 行为仍需要在目标 PostgreSQL 等环境做集成验证。

## 8. 异步测试

当测试需要直接调用异步数据库或其他异步对象时，可以使用 HTTPX `AsyncClient` 和 `ASGITransport`，配合 pytest 的异步插件。

HTTPX 的 ASGITransport 本身不自动触发 lifespan。需要用 lifespan 管理器或测试 fixture 显式管理，不能直接照抄同步 TestClient 的生命周期假设。

纯 HTTP 行为测试通常先用 TestClient 即可，不必为了接口是 `async def` 就把全部测试改成异步。

## 9. 练习与验收

运行配套测试，阅读用户隔离和过期 Token 用例；尝试临时删除归属筛选条件，确认测试会失败，然后恢复；新增一个“删除后列表不再包含任务”的断言。

参考：[Testing](https://fastapi.tiangolo.com/tutorial/testing/)、[Testing Dependencies](https://fastapi.tiangolo.com/advanced/testing-dependencies/)、[pytest Fixtures](https://docs.pytest.org/en/stable/how-to/fixtures.html)。下一章：[11. 部署与运行](./index11.md)。
