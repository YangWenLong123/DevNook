# 02. FastAPI 入门

本章目标：在本机运行服务，使用浏览器、Swagger UI 与 curl 调用接口，理解请求如何进入路由函数。

## 1. 安装依赖

在第 1 章创建并激活的虚拟环境中执行：

```bash
python -m pip install "fastapi>=0.115,<1" "uvicorn[standard]>=0.30,<1"
```

FastAPI 会安装兼容的 Pydantic 与 Starlette。这里使用主版本范围表达教程的 API 约定，实际项目应在验证后锁定精确版本。

也可以安装 `fastapi[standard]` 获取官方常用配套依赖和 `fastapi dev` 命令。本教程统一用 `python -m uvicorn` 启动。

## 2. 创建第一个应用

新建 `main.py`：

```python
from fastapi import FastAPI
from pydantic import BaseModel, Field

app = FastAPI(title="任务管理 API", version="0.1.0")


class TaskCreate(BaseModel):
    title: str = Field(min_length=1, max_length=100)
    completed: bool = False


@app.get("/")
def root():
    return {"message": "Hello, FastAPI!"}


@app.get("/tasks/{task_id}")
def read_task(task_id: int):
    return {"id": task_id, "title": "学习 FastAPI"}


@app.post("/tasks", status_code=201)
def create_task(task: TaskCreate):
    return {"id": 1, **task.model_dump()}
```

这个示例没有保存数据，每次创建都返回演示编号 1。数据库版会实现真正的持久化与编号生成。

## 3. 启动服务

在 `main.py` 所在目录运行：

```bash
python -m uvicorn main:app --reload
```

- `main`：模块名，对应 `main.py`，不写 `.py` 后缀。
- `app`：模块中的 FastAPI 实例变量。
- `--reload`：代码变化后重新加载，适合本地开发。
- 默认监听 `127.0.0.1:8000`。按 `Ctrl+C` 停止。

如果提示 `Could not import module "main"`，先检查工作目录、文件名以及文件导入时是否发生异常。端口被占用时可使用 `--port 8001`。

## 4. 三种调用方式

### 4.1 浏览器

访问 `http://127.0.0.1:8000/`，应看到：

```json
{"message": "Hello, FastAPI!"}
```

直接在地址栏打开 URL 通常发出 GET 请求，不能用它直接演示带 JSON 请求体的 POST。

### 4.2 Swagger UI

打开 `http://127.0.0.1:8000/docs`：展开 `POST /tasks`，点击 `Try it out`，输入请求体，再点击 `Execute`。

```json
{"title": "写第一个接口", "completed": false}
```

预期状态码是 `201`，响应包含 `id`、`title` 和 `completed`。

其他默认地址：`/redoc` 展示 ReDoc 文档；`/openapi.json` 返回描述接口的 OpenAPI JSON。它们不是业务数据接口。

### 4.3 curl

下面命令适用于 macOS / Linux / Git Bash；Windows PowerShell 初学时可以先使用 Swagger UI，避免命令行引号差异。

```bash
curl -i http://127.0.0.1:8000/tasks/1

curl -i -X POST http://127.0.0.1:8000/tasks \
  -H 'Content-Type: application/json' \
  -d '{"title":"写第一个接口"}'
```

`-i` 显示响应头与状态码。省略 `completed` 时使用默认值 `false`。

## 5. 故意发送错误请求

```bash
curl -i http://127.0.0.1:8000/tasks/abc

curl -i -X POST http://127.0.0.1:8000/tasks \
  -H 'Content-Type: application/json' \
  -d '{"title":""}'
```

两个请求都应返回 `422`：前者无法把 `abc` 解析为整数，后者违反标题最小长度约束。重点观察响应 `detail` 中的 `loc`，它会指出错误来自 `path` 还是 `body`。

## 6. 路由顺序与方法

固定路径应放在可能匹配它的动态路径之前：

```python
# 如需加入本章应用，请把这段放在 /tasks/{task_id} 定义之前。
@app.get("/tasks/stats")
def task_stats():
    return {"total": 0}
```

否则 `/tasks/stats` 可能先匹配 `/tasks/{task_id}`，随后因为 `stats` 不是整数而返回 422。同一路径允许注册不同方法；请求方法不匹配时一般返回 405。

`/tasks` 和 `/tasks/` 也应保持约定一致，默认配置可能通过重定向补齐或移除斜杠。

## 7. 请求处理顺序

```text
进入中间件 → 匹配方法与路径 → 解析参数 / 执行依赖
→ 执行接口函数 → 处理响应模型 → 返回响应 → 离开中间件
```

请求输入错误通常在执行接口函数前就被拒绝。接口函数返回的数据不符合响应模型则属于服务端错误，需要修复代码。

## 8. 练习与验收

新增 `GET /health`，返回 `{"status": "ok"}`；为任务接口增加说明文字和 `tags=["tasks"]`；分别触发一次 201、404、405、422。

验收时能够说明：404 来自没有匹配资源或路由，405 来自方法不匹配，422 来自请求校验失败。

参考：[First Steps](https://fastapi.tiangolo.com/tutorial/first-steps/)。下一章：[03. 请求参数与数据校验](./index3.md)。
