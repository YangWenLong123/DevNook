# 05. 依赖注入

本章目标：使用 `Depends` 复用参数和校验逻辑，理解依赖树、请求内缓存与资源清理。

## 1. 为什么需要依赖

如果多个接口都要解析分页、获取数据库会话和检查当前用户，把这些逻辑写进每个路由会产生重复。依赖注入让接口声明“我需要什么”，框架负责解析并传入结果。

```text
路由 list_tasks
  ├─ pagination：解析 limit / offset
  ├─ current_user：识别当前用户
  │    └─ token：读取 Authorization
  └─ database：创建会话并在结束后关闭
```

依赖可以是普通函数、异步函数或可调用对象。FastAPI 会根据依赖函数签名继续解析参数。

## 2. 复用分页参数

保存为独立的 `main.py`：

```python
from dataclasses import dataclass
from typing import Annotated

from fastapi import Depends, FastAPI, Header, HTTPException, Query

app = FastAPI()


@dataclass
class Pagination:
    limit: int
    offset: int


def pagination(
    limit: Annotated[int, Query(ge=1, le=100)] = 20,
    offset: Annotated[int, Query(ge=0)] = 0,
) -> Pagination:
    return Pagination(limit=limit, offset=offset)


PaginationDep = Annotated[Pagination, Depends(pagination)]


@app.get("/tasks")
def list_tasks(page: PaginationDep):
    return {"items": [], "limit": page.limit, "offset": page.offset}


@app.get("/users")
def list_users(page: PaginationDep):
    return {"items": [], "limit": page.limit, "offset": page.offset}
```

两个接口都自动获得分页查询参数和文档说明。注意传入的是函数 `Depends(pagination)`，不是立即调用 `Depends(pagination())`。

## 3. 有返回值与只执行检查

补充到本章应用：

```python
def require_demo_header(
    x_demo_key: Annotated[str | None, Header()] = None,
) -> None:
    if x_demo_key != "learning-only":
        raise HTTPException(status_code=403, detail="缺少演示请求头")


@app.get("/protected", dependencies=[Depends(require_demo_header)])
def protected():
    return {"message": "检查通过"}
```

当路由需要依赖的结果时，把它作为函数参数；只需要检查是否通过时，放入 `dependencies=[...]`。

这里固定请求头只是展示依赖执行，真实的用户登录方案在[第 7 章](./index7.md)。依赖抛出 HTTPException 后，路由不会继续正常执行。

## 4. 子依赖

```python
# 补充到本章应用。
def access_context(
    page: PaginationDep,
    _: Annotated[None, Depends(require_demo_header)],
):
    return {"page": page, "source": "demo"}


@app.get("/context")
def read_context(context: Annotated[dict, Depends(access_context)]):
    return {"limit": context["page"].limit, "source": context["source"]}
```

访问 `/context?limit=5` 还需要携带 `X-Demo-Key: learning-only`。这些参数会沿依赖树收集，并出现在接口文档中。

## 5. 请求内缓存

同一次请求中，如果多个依赖需要同一个可缓存依赖，FastAPI 默认复用它的结果。数据库会话因此通常可以在同一请求的依赖和路由之间共享。

这个缓存不是跨请求缓存，也不是 Redis。确实需要在同一次请求里重复执行时，可以指定 `Depends(some_dependency, use_cache=False)`；先确认业务理由再关闭。

## 6. 使用 yield 管理资源

以下是数据库依赖的典型形态，`SessionLocal` 由[第 6 章](./index6.md)创建：

```python
def get_db():
    with SessionLocal() as session:
        yield session
```

```text
建立资源 → yield 交给接口使用 → 退出依赖时关闭资源
```

关闭会话不等于提交事务。需要保存修改时显式调用 `commit()`；失败时按事务边界执行 `rollback()`。

`yield` 之后的清理时机与依赖 scope、FastAPI 版本及响应形式有关。不要在清理部分才做决定业务成功与否的关键提交；流式响应或后台任务也不要借用生命周期已经结束的会话。

把必须在进程启动时创建、多个请求共享的资源放入 `lifespan`。把每次请求独立的资源放入依赖。不要把可变的用户身份或会话对象保存为全局变量。

## 7. 依赖覆盖

测试中可以把真实依赖替换为固定数据或测试资源：

```python
# 在测试中使用，结束后清理。
app.dependency_overrides[pagination] = lambda: Pagination(limit=5, offset=0)
# ...执行测试...
app.dependency_overrides.clear()
```

覆盖字典的 key 是原始函数对象，而不是函数名字符串。完整测试和异常情况下的清理方式见[第 10 章](./index10.md)。

## 8. 练习与验收

新增 `GET /reports`，复用分页依赖；为一组路由增加公共请求头检查；在依赖内打印日志，观察一次请求中重复引用同一依赖时的调用次数。

能够说明三个边界：请求依赖与应用生命周期、关闭会话与提交事务、依赖缓存与跨请求业务缓存。

参考：[Dependencies](https://fastapi.tiangolo.com/tutorial/dependencies/)、[Dependencies with yield](https://fastapi.tiangolo.com/tutorial/dependencies/dependencies-with-yield/)。下一章：[06. 数据库与 CRUD](./index6.md)。
