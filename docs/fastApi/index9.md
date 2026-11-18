# 09. 异步与常见集成

本章目标：知道什么时候使用 `async def`，避免把同步阻塞调用放进事件循环，并正确管理外部客户端与后台任务。

## 1. 异步解决什么问题

查询外部 HTTP 接口、等待数据库和读取网络数据都包含等待时间。异步代码在等待支持异步的 I/O 时可以让出执行权，让事件循环处理其他任务。

`async` 不会把计算自动分配到多个 CPU，也不会把普通阻塞库变成异步库。

| 工作内容 | 推荐起点 |
| --- | --- |
| 同步 SQLAlchemy、同步第三方 SDK | 路由或依赖使用 `def` |
| HTTPX AsyncClient、异步数据库驱动 | `async def` + `await` |
| 图像处理、大量计算 | 进程池、独立 worker 或任务队列 |
| 异步流程中少量必须使用的阻塞调用 | 明确使用线程池桥接，并控制并发 |

FastAPI 会在线程池执行普通 `def` 路由和同步依赖。但在 `async def` 内直接调用自己的普通函数，框架不会自动替你把它转移到线程池。

## 2. 一个常见错误

```python
# 错误示范：不能因为接口声明为 async 就调用阻塞 sleep。
import time


async def blocking_example():
    time.sleep(3)
```

等待演示应使用：

```python
import asyncio


async def non_blocking_example():
    await asyncio.sleep(3)
```

类似地，`requests.get()` 和同步数据库查询不会因为被放入 `async def` 就变得非阻塞。第 13 章使用同步 SQLAlchemy，因此数据库路由保留为 `def`。

## 3. 使用共享 HTTPX AsyncClient

安装 `httpx` 后，下例可保存成独立 `main.py` 运行。访问外部网站需要网络连通：

```python
from contextlib import asynccontextmanager

import httpx
from fastapi import FastAPI, HTTPException, Request


@asynccontextmanager
async def lifespan(app: FastAPI):
    async with httpx.AsyncClient(
        base_url="https://httpbin.org",
        timeout=httpx.Timeout(5.0, connect=2.0),
        limits=httpx.Limits(max_connections=20, max_keepalive_connections=10),
    ) as client:
        app.state.http_client = client
        yield


app = FastAPI(lifespan=lifespan)


@app.get("/upstream")
async def read_upstream(request: Request):
    client: httpx.AsyncClient = request.app.state.http_client
    try:
        response = await client.get("/get", params={"source": "fastapi-learning"})
        response.raise_for_status()
    except httpx.TimeoutException:
        raise HTTPException(status_code=504, detail="上游服务超时") from None
    except httpx.HTTPError:
        raise HTTPException(status_code=502, detail="上游服务请求失败") from None
    try:
        return response.json()
    except ValueError:
        raise HTTPException(status_code=502, detail="上游返回格式错误") from None
```

共享客户端复用连接池，退出 lifespan 时统一关闭。不要在循环中反复新建客户端；也不要允许客户端任意传入完整目标 URL，否则可能形成访问内部地址的入口。

超时是接口契约的一部分。重试需要结合幂等性、次数、退避与总耗时预算，不应对所有 POST 请求无条件重试。

## 4. 并发执行独立 I/O

```python
# 此函数由异步业务代码调用，client 为共享 AsyncClient。
import asyncio


async def read_two_pages(client):
    async def fetch(path):
        response = await client.get(path)
        response.raise_for_status()
        return response.json()

    async with asyncio.TaskGroup() as group:
        first = group.create_task(fetch("/get?a=1"))
        second = group.create_task(fetch("/get?a=2"))
    return [first.result(), second.result()]
```

两次请求互相独立时可以并发；第二次调用依赖第一次结果时应顺序执行。TaskGroup 中子任务失败会取消其他未完成任务，并可能以异常组传播，调用方需要设计错误处理。

不要一次创建无限多任务。连接池上限、信号量、下游承载能力与总请求预算需要一起考虑。

## 5. 异步数据库的基本形态

另建练习目录安装 `aiosqlite`。以下代码定义异步资源，需要配合已有的 SQLAlchemy `Task` 模型，并由 lifespan 创建表、在退出时执行 `await engine.dispose()`：

```python
from sqlalchemy import select
from sqlalchemy.ext.asyncio import async_sessionmaker, create_async_engine

engine = create_async_engine("sqlite+aiosqlite:///./async-tasks.db")
AsyncSessionLocal = async_sessionmaker(engine, expire_on_commit=False)


async def get_async_db():
    async with AsyncSessionLocal() as session:
        yield session


async def read_tasks(session):
    result = await session.scalars(select(Task).order_by(Task.id))
    return result.all()
```

异步引擎需要匹配异步驱动，例如 PostgreSQL 的 `asyncpg`。查询和提交等产生 I/O 的操作需要 await，`session.add()` 等操作通常不需要。

每个并发任务使用独立 AsyncSession，不要把一个 Session 传给多个并发协程执行查询。也要避免在序列化时意外触发懒加载 I/O，必要时提前加载关联数据。

## 6. BackgroundTasks

下面代码可以补充到本章 HTTPX 应用：

```python
import logging

from fastapi import BackgroundTasks

logger = logging.getLogger("task_api.events")


def record_event(task_id: int):
    logger.info("task created: %s", task_id)


@app.post("/event-demo", status_code=202)
def event_demo(background_tasks: BackgroundTasks):
    background_tasks.add_task(record_event, 1)
    return {"message": "已接受演示事件"}
```

任务在响应发送后由当前应用进程执行。进程崩溃或重启时不能保证任务完成，也没有自动的持久化重试。

传入简单标识符，在后台函数里创建并关闭自己的数据库会话。不要把请求依赖得到的 Session 或 UploadFile 直接交给后台长期使用。

短小、可丢失的附加动作可以从这里开始；支付、重要通知、耗时导出等应考虑可持久化任务队列。

## 7. 练习与验收

把外部接口地址故意改错，确认返回 502；把超时调小观察 504；解释为什么同步 SQLAlchemy 路由可以使用 `def`，以及为什么一个异步 Session 不能被多个并发任务共享。

参考：[Concurrency and async / await](https://fastapi.tiangolo.com/async/)、[HTTPX Async](https://www.python-httpx.org/async/)、[SQLAlchemy AsyncIO](https://docs.sqlalchemy.org/en/20/orm/extensions/asyncio.html)。下一章：[10. 接口测试](./index10.md)。
