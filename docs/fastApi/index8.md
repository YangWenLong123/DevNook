# 08. 项目结构与配置

本章目标：把单文件练习组织成可维护的项目，理解配置、应用生命周期、中间件与 CORS。

## 1. 先按职责拆分

配套项目采用小型应用结构：

```text
task-api/
├── app/
│   ├── __init__.py
│   ├── main.py          应用工厂、路由注册、生命周期
│   ├── config.py        环境配置
│   ├── db.py            引擎、会话、Base
│   ├── models.py        SQLAlchemy 表模型
│   ├── schemas.py       Pydantic 输入输出模型
│   ├── dependencies.py  会话、身份等请求依赖
│   ├── security.py      密码哈希与 Token 签发
│   └── routes.py        auth/tasks 路由
├── tests/
├── .env.example
├── requirements.txt
├── requirements-dev.txt
└── Dockerfile
```

业务增大后再把 `routes.py` 拆为 `routers/auth.py`、`routers/tasks.py`，把复杂业务提取到服务函数。不要在业务还简单时先建立大量空层级。

## 2. APIRouter

```python
from fastapi import APIRouter, FastAPI

task_router = APIRouter(prefix="/tasks", tags=["tasks"])


@task_router.get("")
def list_tasks():
    return []


app = FastAPI()
app.include_router(task_router)
```

上例路径是 `/tasks`。如果路由声明写成 `@task_router.get("/tasks")`，最终路径就会重复成 `/tasks/tasks`。

路由函数负责 HTTP 输入输出；业务函数负责规则与流程；数据库访问负责查询和写入。跨层调用尽量朝一个方向，避免模型模块导入 `app` 导致循环导入。

## 3. pydantic-settings

Pydantic v2 的 `BaseSettings` 位于独立包：

```bash
python -m pip install "pydantic-settings>=2,<3"
```

```python
from pydantic import Field, SecretStr
from pydantic_settings import BaseSettings, SettingsConfigDict


class Settings(BaseSettings):
    model_config = SettingsConfigDict(env_file=".env", extra="ignore")

    secret_key: SecretStr = Field(min_length=32)
    database_url: str = "sqlite:///./tasks.db"
    access_token_expire_minutes: int = Field(default=30, ge=1, le=1440)
```

`.env` 内容示意：

```dotenv
SECRET_KEY=此处填写自己生成的至少32字符随机值
DATABASE_URL=sqlite:///./tasks.db
ACCESS_TOKEN_EXPIRE_MINUTES=30
```

初始化 `Settings()` 时会读取配置并校验。系统环境变量通常优先于 `.env`；相对路径以启动进程的工作目录为准。`.env` 加入 `.gitignore`，只提交没有真实密钥的 `.env.example`。

`SecretStr` 能减少对象打印时意外暴露密钥的机会，但它不负责加密存储。调用签名函数时仍需通过 `get_secret_value()` 获取实际值。

## 4. 应用工厂与 lifespan

配套项目通过 `create_app(settings)` 创建应用，测试时可以注入独立配置。资源在 lifespan 中创建与释放：

```python
from contextlib import asynccontextmanager

from fastapi import FastAPI


@asynccontextmanager
async def lifespan(app: FastAPI):
    # 启动前：建立应用级资源。
    app.state.example_resource = {"ready": True}
    try:
        yield
    finally:
        # 关闭时：释放资源。真实客户端应调用其 close/aclose。
        app.state.example_resource.clear()


app = FastAPI(lifespan=lifespan)
```

数据库引擎、共享 HTTP 客户端适合应用生命周期；单次数据库 Session 适合请求依赖。多 worker 时，每个进程都会创建自己的资源，连接池数量也会叠加。

新项目优先使用 lifespan，不要同时依赖另一套启动关闭钩子的执行顺序。配套项目的 `create_all()` 只是教学初始化；生产迁移应在启动之前由部署流程完成。

## 5. 中间件与日志

下面的中间件可添加到创建应用的代码中：

```python
import logging
from time import perf_counter
from uuid import uuid4

from fastapi import Request

logger = logging.getLogger("task_api.requests")


@app.middleware("http")
async def request_log(request: Request, call_next):
    request_id = uuid4().hex
    request.state.request_id = request_id
    started = perf_counter()
    response = await call_next(request)
    elapsed = perf_counter() - started
    response.headers["X-Request-Id"] = request_id
    logger.info(
        "%s %s status=%s duration=%.3f request_id=%s",
        request.method, request.url.path, response.status_code, elapsed, request_id,
    )
    return response
```

这是最小的成功响应路径日志示例。真实项目还要记录未处理异常；流式响应的 `call_next` 耗时也不等于完整下载耗时。不要记录 Authorization 头、密码和完整敏感请求体。

配置日志输出级别和处理器后才能看到 `info` 日志，基础知识可参考 [Python logging](../python/index15.md)。

## 6. CORS：浏览器跨域

前端 `http://localhost:5173` 请求后端 `http://localhost:8000` 时，端口不同，因此属于不同 origin。

```python
from fastapi.middleware.cors import CORSMiddleware

app.add_middleware(
    CORSMiddleware,
    allow_origins=["http://localhost:5173"],
    allow_credentials=True,
    allow_methods=["GET", "POST", "PATCH", "DELETE"],
    allow_headers=["Authorization", "Content-Type"],
    expose_headers=["X-Request-Id"],
)
```

带凭证时显式配置允许的来源、方法和请求头，不要用通配符来源。`localhost` 和 `127.0.0.1` 是不同来源，需要按实际使用地址配置。

CORS 是浏览器的跨域访问机制，不是用户权限校验。curl 不受浏览器 CORS 限制；接口仍需要认证和授权。

## 7. 环境划分

| 环境 | 数据与运行约定 |
| --- | --- |
| 开发 | 本地数据库、开发密钥、可启用 reload |
| 测试 | 独立临时数据库、固定测试配置、自动清理 |
| 生产 | 平台注入密钥、正式数据库、受控迁移、日志监控 |

不要根据“是否能连接成功”自动回退到生产数据库。缺少必要配置时直接启动失败，更容易发现配置问题。

## 8. 练习与验收

运行第 13 章项目，修改 `.env` 中 Token 时长；用测试配置创建另一个应用；为响应添加请求编号；从指定前端来源发起一次请求，观察预检与 CORS 响应头。

参考：[Bigger Applications](https://fastapi.tiangolo.com/tutorial/bigger-applications/)、[Settings](https://docs.pydantic.dev/latest/concepts/pydantic_settings/)、[Lifespan](https://fastapi.tiangolo.com/advanced/events/)。下一章：[09. 异步与常见集成](./index9.md)。
