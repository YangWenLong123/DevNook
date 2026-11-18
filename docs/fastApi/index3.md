# 03. 请求参数与数据校验

本章目标：明确参数从哪里来，把输入要求写成可执行、可展示的模型规则。

## 1. FastAPI 如何判断参数来源

| 声明方式 | 来源 | 示例 |
| --- | --- | --- |
| 名字出现在路径中 | 路径参数 | `/tasks/{task_id}` 中的 `task_id` |
| 普通标量且不在路径中 | 默认视为查询参数 | `limit: int = 20` |
| Pydantic 模型 | 默认视为 JSON 请求体 | `task: TaskCreate` |
| `Header()` / `Cookie()` | 请求头 / Cookie | `x_request_id` / `session_id` |
| `Form()` / `File()` | 表单 / 文件 | 登录表单、文件上传 |

可以用 `Query()`、`Body()` 等显式指定来源。类型注解决定如何解析数据，`Field()` 等元信息表达约束。

## 2. 一个可以运行的参数示例

保存为独立的 `main.py`，使用第 2 章的启动命令：

```python
from enum import Enum
from typing import Annotated

from fastapi import Cookie, FastAPI, Header, Path, Query
from pydantic import BaseModel, ConfigDict, Field, field_validator

app = FastAPI()


class Priority(str, Enum):
    low = "low"
    normal = "normal"
    high = "high"


class Label(BaseModel):
    name: str = Field(min_length=1, max_length=20)


class TaskCreate(BaseModel):
    model_config = ConfigDict(extra="forbid")

    title: str = Field(min_length=1, max_length=100)
    description: str | None = Field(default=None, max_length=500)
    priority: Priority = Priority.normal
    labels: list[Label] = Field(default_factory=list, max_length=5)

    @field_validator("title", mode="before")
    @classmethod
    def strip_title(cls, value: object) -> object:
        if isinstance(value, str):
            return value.strip()
        return value


@app.get("/tasks")
def list_tasks(
    limit: Annotated[int, Query(ge=1, le=100)] = 20,
    offset: Annotated[int, Query(ge=0)] = 0,
    completed: bool | None = None,
    tags: Annotated[list[str] | None, Query()] = None,
):
    return {"limit": limit, "offset": offset, "completed": completed, "tags": tags}


@app.get("/tasks/{task_id}")
def read_task(task_id: Annotated[int, Path(gt=0)]):
    return {"id": task_id}


@app.post("/tasks", status_code=201)
def create_task(task: TaskCreate):
    return task


@app.get("/request-info")
def request_info(
    x_request_id: Annotated[str | None, Header()] = None,
    session_id: Annotated[str | None, Cookie()] = None,
):
    return {"request_id": x_request_id, "has_session": session_id is not None}
```

`Header()` 默认把 Python 参数中的下划线转换为连字符，因此 `x_request_id` 对应 HTTP 头 `X-Request-Id`，请求头名称大小写不敏感。

## 3. 路径参数与查询参数

```text
GET /tasks/12
GET /tasks?limit=10&offset=0&completed=false
GET /tasks?tags=python&tags=backend
```

最后一个请求会把重复出现的 `tags` 解析为列表。路径参数不能省略；查询参数是否必填取决于是否提供默认值。

常用约束：`gt` 大于、`ge` 大于等于、`lt` 小于、`le` 小于等于；字符串可设置 `min_length`、`max_length`、`pattern`。

## 4. 请求体与嵌套模型

```json
{
  "title": "  学习参数校验  ",
  "description": null,
  "priority": "high",
  "labels": [{"name": "Python"}]
}
```

响应中的标题会去掉首尾空白。因为清理使用 `mode="before"`，空格标题会先变成空字符串，再被 `min_length=1` 拒绝。

`extra="forbid"` 会拒绝未声明字段，帮助发现诸如 `titel` 的拼写错误。Pydantic 默认通常会忽略多余字段，因此有严格接口契约时应显式配置。

使用 `default_factory=list` 表达“每个模型实例创建自己的列表”。模型之间不要共享需要修改的默认状态。

## 5. 必填、可省略与允许 null

| 字段声明 | 可省略 | 允许 null |
| --- | --- | --- |
| `title: str` | 否 | 否 |
| `title: str = "未命名"` | 是 | 否 |
| `title: str \| None` | 否 | 是 |
| `title: str \| None = None` | 是 | 是 |

这在 PATCH 中尤其重要：没有提交字段代表“不修改”，显式提交 `null` 则可能代表“清空”。后续可用 `model_dump(exclude_unset=True)` 区分两者。

## 6. 跨字段校验

单个字段清理使用 `field_validator`；多个字段之间的约束使用 `model_validator`。以下是独立模型示例：

```python
from typing import Self

from pydantic import BaseModel, model_validator


class NumberRange(BaseModel):
    start: int
    end: int

    @model_validator(mode="after")
    def check_order(self) -> Self:
        if self.end < self.start:
            raise ValueError("end 不能小于 start")
        return self
```

校验器表达数据约束。用户名是否已存在、用户是否有权限等需要查询外部状态的逻辑，应放在依赖或业务代码中。

## 7. 表单与文件上传

先安装解析依赖：

```bash
python -m pip install python-multipart
```

以下代码补充到本章应用：

```python
from fastapi import File, Form, UploadFile


@app.post("/feedback")
def feedback(message: Annotated[str, Form(min_length=1, max_length=500)]):
    return {"message": message}


@app.post("/attachments")
async def upload_attachment(file: Annotated[UploadFile, File()]):
    total = 0
    try:
        while chunk := await file.read(1024 * 1024):
            total += len(chunk)
        return {"filename": file.filename, "size": total}
    finally:
        await file.close()
```

```bash
curl -X POST http://127.0.0.1:8000/feedback -d 'message=hello'
curl -X POST http://127.0.0.1:8000/attachments -F 'file=@./main.py'
```

上传接口只统计文件大小，不保存内容。实际上传还需要限制请求体大小、验证内容并生成服务端文件名，避免直接拼接客户端提供的文件路径。

一个请求只有一种主要请求体编码。JSON 请求体与 `multipart/form-data` 不是可以任意混合的两份 body；同时上传文件与描述信息时通常把描述声明为 `Form()` 字段。

## 8. 练习与验收

为任务增加 `due_date: date | None = None`，观察 ISO 日期的解析；尝试空白标题、非法枚举、多余字段和 6 个标签，确认都返回 422；通过请求头传入 `X-Request-Id` 并检查响应。

参考：[Request Body](https://fastapi.tiangolo.com/tutorial/body/)、[Pydantic Validators](https://docs.pydantic.dev/latest/concepts/validators/)。下一章：[04. 响应与异常处理](./index4.md)。
