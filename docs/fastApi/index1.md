# 01. 前置基础

本章目标：理解 FastAPI 示例中的 Python 语法，能区分请求方法、路径、参数、请求体和状态码。

## 1. 函数、类型注解与默认值

```python
def describe_task(title: str, completed: bool = False) -> dict[str, str | bool]:
    return {"title": title, "completed": completed}


print(describe_task("学习 FastAPI"))
```

- `title: str` 表示期望接收字符串。
- `completed: bool = False` 表示参数有默认值。
- `-> dict[str, str | bool]` 表示返回字典，值可能是字符串或布尔值。
- `str | None` 表示字符串或空值；它本身不代表参数可以省略。

普通 Python 函数不会因为类型注解就自动校验参数。FastAPI 和 Pydantic 会读取这些注解，执行请求解析与校验。

```python
def find_task(task_id: int | None):
    return task_id


find_task(None)  # 可以显式传入 None
# find_task()   # TypeError：没有默认值，仍然必须传参
```

## 2. 认识 Annotated

`Annotated` 允许在类型之外携带元信息。FastAPI 使用它描述校验规则或依赖：

```python
from typing import Annotated

from fastapi import Query


def list_tasks(limit: Annotated[int, Query(ge=1, le=100)] = 20):
    return {"limit": limit}
```

读法是：`limit` 是整数，查询参数范围为 1～100，默认值为 20。此处只演示函数声明；注册成路由后才会处理 HTTP 请求。

## 3. 类与数据模型

```python
from pydantic import BaseModel, Field


class TaskCreate(BaseModel):
    title: str = Field(min_length=1, max_length=100)
    completed: bool = False


task = TaskCreate(title="完成第一章")
print(task.title)
print(task.model_dump())
```

`BaseModel` 负责根据字段定义解析和校验数据。字段不符合规则时抛出 `ValidationError`。在接口请求中，FastAPI 通常会把相应的请求校验错误转成 HTTP 422 响应。

Pydantic 默认允许部分类型转换，例如字符串 `"12"` 在适当场景下可转成整数。需要拒绝类型转换时，应另外学习严格模式，不要把类型注解理解成“只接受完全相同的运行时类型”。

## 4. 异常与上下文管理

```python
try:
    task_id = int("abc")
except ValueError:
    print("任务编号必须是整数")
```

在接口里，预期的业务错误可以转成明确的 HTTP 异常；未知错误应记录日志并排查，不要全部捕获后返回成功。

```python
with open("notes.txt", "w", encoding="utf-8") as file:
    file.write("学习 FastAPI")
```

`with` 在退出时执行清理。数据库会话和网络客户端也适合通过类似方式管理生命周期。

## 5. 装饰器与路由

```python
from fastapi import FastAPI

app = FastAPI()


@app.get("/hello")
def hello():
    return {"message": "hello"}
```

`@app.get("/hello")` 在应用导入时登记路由。收到匹配的请求时，FastAPI 才执行 `hello()`。

同步和异步函数的区别会在[第 9 章](./index9.md)详细说明。现在可以先用普通 `def` 编写入门接口。

## 6. 一次 HTTP 请求包含什么

```http
POST /tasks?notify=false HTTP/1.1
Host: localhost:8000
Content-Type: application/json
Authorization: Bearer example-token

{"title": "学习 HTTP"}
```

| 部分 | 示例 | 用途 |
| --- | --- | --- |
| 方法 | `POST` | 表达本次操作 |
| 路径 | `/tasks` | 确定操作的资源 |
| 查询参数 | `notify=false` | 筛选、分页或控制选项 |
| 请求头 | `Content-Type` | 描述数据格式等元信息 |
| 请求体 | JSON 对象 | 提交需要创建或修改的数据 |

常见方法：`GET` 查询、`POST` 创建、`PUT` 整体替换、`PATCH` 局部更新、`DELETE` 删除。具体业务语义由接口约定决定。

| 状态码 | 常见含义 |
| --- | --- |
| 200 | 请求成功，通常带响应体 |
| 201 | 创建成功 |
| 204 | 成功且没有响应体 |
| 400 | 请求在业务语义上不合理 |
| 401 | 未提供有效身份凭证 |
| 403 | 已识别身份，但无权限 |
| 404 | 资源不存在或对当前用户不可见 |
| 409 | 与当前资源状态冲突，例如用户名重复 |
| 422 | 请求参数未通过 FastAPI 的校验 |
| 500 | 服务端发生未预期错误 |

## 7. REST 风格路径

```text
GET    /tasks        查询任务列表
POST   /tasks        创建任务
GET    /tasks/1      查询指定任务
PATCH  /tasks/1      修改指定任务的部分字段
DELETE /tasks/1      删除指定任务
```

路径优先表达资源，方法表达操作。列表为空通常返回 `200` 和 `[]`；查询一个不存在的任务通常返回 `404`。

## 8. 虚拟环境与练习

macOS / Linux：

```bash
mkdir fastapi-learning
cd fastapi-learning
python3 -m venv .venv
source .venv/bin/activate
python -m pip install --upgrade pip
```

Windows PowerShell：

```powershell
mkdir fastapi-learning
cd fastapi-learning
py -3 -m venv .venv
.\.venv\Scripts\Activate.ps1
python -m pip install --upgrade pip
```

如果激活脚本受限，可以直接用 `.\.venv\Scripts\python.exe` 代替后续命令中的 `python`。不要把文件命名为 `fastapi.py`、`pydantic.py` 或 `typing.py`，以免遮蔽第三方包或标准库。

练习：解释 `title: str | None` 与 `title: str | None = None` 的区别，并为“查询用户”和“修改用户昵称”各设计一个接口方法与路径。

延伸阅读：[Python 函数与作用域](../python/index6.md)、[装饰器](../python/index11.md)、[异常处理](../python/index12.md)。

下一章：[02. FastAPI 入门](./index2.md)。
