# 04. 响应与异常处理

本章目标：明确接口输出契约，正确返回成功与错误状态，并防止内部字段意外暴露。

## 1. 输入模型和输出模型应分开

注册用户时输入可能包含明文密码，数据库保存密码哈希，响应则只应该返回公开字段。任务也可以按 `TaskCreate`、`TaskUpdate`、`TaskRead` 分开建模。

下面是可以独立运行的 `main.py`：

```python
from typing import Annotated

from fastapi import FastAPI, HTTPException, Path, Response, status
from pydantic import BaseModel, ConfigDict, Field

app = FastAPI()


class TaskCreate(BaseModel):
    title: str = Field(min_length=1, max_length=100)


class TaskRead(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: int
    title: str
    completed: bool


tasks: dict[int, dict] = {}
next_id = 1


@app.post("/tasks", response_model=TaskRead, status_code=status.HTTP_201_CREATED)
def create_task(payload: TaskCreate):
    global next_id
    task = {
        "id": next_id,
        "title": payload.title,
        "completed": False,
        "internal_note": "这个字段不应出现在响应中",
    }
    tasks[next_id] = task
    next_id += 1
    return task


@app.get("/tasks/{task_id}", response_model=TaskRead)
def read_task(task_id: Annotated[int, Path(gt=0)]):
    if task_id not in tasks:
        raise HTTPException(status_code=404, detail="任务不存在")
    return tasks[task_id]


@app.delete("/tasks/{task_id}", status_code=204)
def delete_task(task_id: Annotated[int, Path(gt=0)]):
    if task_id not in tasks:
        raise HTTPException(status_code=404, detail="任务不存在")
    del tasks[task_id]
    return Response(status_code=204)
```

调用 POST 后，响应中没有 `internal_note`。这个例子使用进程内字典，重启会清空，也不适合多进程共享。

## 2. response_model 的三项职责

1. 声明文档中的响应结构。
2. 校验和转换接口返回的数据。
3. 按模型筛选输出字段。

`from_attributes=True` 允许从对象属性读取字段，方便后续返回 SQLAlchemy 对象。字典本身不需要这个配置。

请求参数违反模型规则通常返回 422；接口返回值违反响应模型属于程序错误，一般表现为 500。不要把后者伪装成客户端输入错误。

返回 `Response` 或其子类实例时，会直接使用这个响应，通常不会再经过 `response_model` 的校验和过滤。因此不要把敏感字段放入自己构造的 JSONResponse。

## 3. 部分更新模型

补充到本章应用：

```python
from pydantic import field_validator


class TaskUpdate(BaseModel):
    model_config = ConfigDict(extra="forbid")

    title: str | None = Field(default=None, min_length=1, max_length=100)
    completed: bool | None = None

    @field_validator("title", "completed")
    @classmethod
    def reject_explicit_null(cls, value):
        if value is None:
            raise ValueError("该字段不能显式传 null")
        return value


@app.patch("/tasks/{task_id}", response_model=TaskRead)
def update_task(task_id: Annotated[int, Path(gt=0)], payload: TaskUpdate):
    if task_id not in tasks:
        raise HTTPException(status_code=404, detail="任务不存在")
    changes = payload.model_dump(exclude_unset=True)
    tasks[task_id].update(changes)
    return tasks[task_id]
```

`{"completed": true}` 只修改完成状态，不会把标题改成默认值。`exclude_unset=True` 排除没有提交的字段，**不会排除显式提交的 null**。

本例字段不允许清空，所以校验器拒绝显式 null；未提交字段使用默认值且默认不触发该字段校验器。若描述字段允许清空，则可以允许它接收 null。

## 4. 使用 HTTPException

```python
# 放在需要检查业务条件的接口或依赖中。
raise HTTPException(
    status_code=401,
    detail="登录状态无效",
    headers={"WWW-Authenticate": "Bearer"},
)
```

要使用 `raise`，不能 `return HTTPException(...)`。`raise` 会终止当前正常流程，交给异常处理器返回响应。

常见约定：资源不存在用 404，用户名重复用 409，未登录用 401。列表为空返回空列表，而不是因为没有数据就返回 404。

## 5. 统一业务错误格式

下面代码可以补充到本章应用：

```python
from fastapi import Request
from fastapi.responses import JSONResponse


class BusinessError(Exception):
    def __init__(self, code: str, message: str, status_code: int = 400):
        self.code = code
        self.message = message
        self.status_code = status_code


@app.exception_handler(BusinessError)
async def business_error_handler(request: Request, exc: BusinessError):
    return JSONResponse(
        status_code=exc.status_code,
        content={"code": exc.code, "message": exc.message},
    )


@app.get("/business-error-demo")
def business_error_demo():
    raise BusinessError("TASK_LIMIT_REACHED", "已达到任务数量上限", 409)
```

该处理器只影响 `BusinessError`。框架的 HTTP 错误和请求校验错误仍采用原有格式。如果团队要求全部统一，应分别处理并保留原有状态码、鉴权响应头和定位信息。

## 6. 响应头、Cookie 与其他响应

```python
# 补充到本章应用。
from fastapi.responses import RedirectResponse, StreamingResponse


@app.get("/response-info")
def response_info(response: Response):
    response.headers["X-API-Version"] = "1"
    response.set_cookie("theme", "light", httponly=True, samesite="lax")
    return {"message": "ok"}


@app.get("/go-docs")
def go_docs():
    return RedirectResponse(url="/docs", status_code=307)


@app.get("/export")
def export_tasks():
    def rows():
        yield "id,title\n"
        yield "1,Learn FastAPI\n"

    return StreamingResponse(rows(), media_type="text/csv")
```

文件下载可使用 `FileResponse`，路径必须由服务端限制在允许访问的范围内。流式输出发送响应头后，后续错误通常无法再改成另一种 HTTP 状态。

204 响应没有响应体，不应返回 `{"message": "deleted"}`。Cookie 用于真实登录时还要结合 HTTPS、`Secure` 和 CSRF 防护设计，不能照搬演示的主题 Cookie 配置。

## 7. 练习与验收

依次创建任务、修改完成状态、查询任务、删除任务，再次查询应返回 404。检查创建响应是否隐藏内部字段，删除响应是否为空，PATCH 显式传入 null 是否被拒绝。

参考：[Response Model](https://fastapi.tiangolo.com/tutorial/response-model/)、[Handling Errors](https://fastapi.tiangolo.com/tutorial/handling-errors/)。下一章：[05. 依赖注入](./index5.md)。
