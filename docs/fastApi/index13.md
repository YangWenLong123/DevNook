# 13. 任务管理 API 实战

本章目标：把前面的知识串成一个可以启动、调试、测试和继续扩展的小型后端项目。

配套源码位于仓库的 `docs/fastApi/examples/task-api/`。它是独立 Python 项目，不需要修改本站的前端依赖，也不需要把所有代码放进一个 `main.py`。

## 1. 最终功能

| 方法与路径 | 功能 | 是否需要登录 |
| --- | --- | --- |
| `GET /health` | 简单存活检查 | 否 |
| `POST /auth/register` | 注册，响应只返回公开字段 | 否 |
| `POST /auth/token` | 表单登录，获取访问 Token | 否 |
| `GET /auth/me` | 查询当前用户 | 是 |
| `POST /tasks` | 创建自己的任务 | 是 |
| `GET /tasks` | 查询自己的任务，支持分页和完成状态筛选 | 是 |
| `GET /tasks/{task_id}` | 查询自己的指定任务 | 是 |
| `PATCH /tasks/{task_id}` | 修改自己任务的部分字段 | 是 |
| `DELETE /tasks/{task_id}` | 删除自己的任务 | 是 |

## 2. 推荐先自己分阶段实现

### 阶段一：内存版

参考第 2～5 章，用字典保存任务，实现 CRUD、响应模型、错误处理。验证重启后数据消失，理解它只是练习存储。

### 阶段二：数据库版

参考第 6 章，替换为 SQLAlchemy 会话和查询。给列表增加稳定排序、分页与完成状态筛选；确认重启后数据仍在。

### 阶段三：多用户版

参考第 7～8 章，增加用户表、密码哈希、登录和请求用户依赖。每个任务关联 owner_id，所有读写都校验归属。

### 阶段四：可交付版

参考第 10～11 章，使用独立测试配置，覆盖权限与错误路径，添加 Dockerfile。配套代码达到这一教学阶段，但生产能力仍需按项目补充。

## 3. 启动配套项目

在本仓库根目录执行：

```bash
cd docs/fastApi/examples/task-api
python3 -m venv .venv
source .venv/bin/activate
python -m pip install -r requirements-dev.txt
cp .env.example .env
python -c 'import secrets; print(secrets.token_hex(32))'
```

Windows PowerShell 将创建环境、激活与复制命令分别替换为：

```powershell
py -3 -m venv .venv
.\.venv\Scripts\Activate.ps1
Copy-Item .env.example .env
```

把生成的随机字符串填入 `.env` 的 `SECRET_KEY`，保存后启动：

```bash
python -m uvicorn app.main:app --reload
```

缺失或过短的密钥会导致启动失败，这是配置校验的预期结果。访问 `http://127.0.0.1:8000/docs` 开始调试。

## 4. 手动验证完整流程

以下 curl 命令适用于 macOS / Linux / Git Bash。PowerShell 用户可以通过 Swagger UI 完成同样流程。

### 4.1 注册

```bash
curl -i -X POST http://127.0.0.1:8000/auth/register \
  -H 'Content-Type: application/json' \
  -d '{"username":"alice","password":"learn-fastapi-123"}'
```

预期 201，响应类似 `{"id":1,"username":"alice"}`；重复注册返回 409。用户名会去除首尾空白并转成小写，要求以英文字母开头，后续只能包含小写字母、数字和下划线。

### 4.2 登录

```bash
curl -i -X POST http://127.0.0.1:8000/auth/token \
  -d 'username=alice&password=learn-fastapi-123'
```

复制返回的 `access_token`。下面先设置终端变量，把占位文字替换成真实值：

```bash
TASK_API_TOKEN='粘贴刚刚得到的access_token'
```

### 4.3 新建与查询

```bash
curl -i -X POST http://127.0.0.1:8000/tasks \
  -H "Authorization: Bearer $TASK_API_TOKEN" \
  -H 'Content-Type: application/json' \
  -d '{"title":"完成 FastAPI 教程"}'

curl -i 'http://127.0.0.1:8000/tasks?limit=10&offset=0&completed=false' \
  -H "Authorization: Bearer $TASK_API_TOKEN"
```

创建响应包含 `id`、`title`、`completed` 和 `owner_id`。记下真实任务编号，下面以新数据库中的编号 1 为例。

### 4.4 修改与删除

```bash
curl -i -X PATCH http://127.0.0.1:8000/tasks/1 \
  -H "Authorization: Bearer $TASK_API_TOKEN" \
  -H 'Content-Type: application/json' \
  -d '{"completed":true}'

curl -i -X DELETE http://127.0.0.1:8000/tasks/1 \
  -H "Authorization: Bearer $TASK_API_TOKEN"
```

PATCH 只更新提交字段，删除返回 204 且响应体为空。删除后再查相同编号返回 404。

## 5. 核心实现对应关系

| 设计 | 源码位置 | 对应章节 |
| --- | --- | --- |
| 输入规范化、PATCH 区分未提交与 null | `app/schemas.py` | 03、04 |
| 数据库与用户请求依赖 | `app/dependencies.py` | 05 |
| 会话、SQLAlchemy 表、查询与事务 | `app/db.py`、`app/models.py`、`app/routes.py` | 06 |
| 密码哈希、JWT、资源归属 | `app/security.py`、`app/dependencies.py`、`app/routes.py` | 07 |
| 环境配置、应用工厂与生命周期 | `app/config.py`、`app/main.py` | 08 |
| 同步数据库使用同步路由 | `app/routes.py` | 09 |
| 临时数据库与行为测试 | `tests/` | 10 |
| 非 root 容器、持久化与启动命令 | `Dockerfile`、`.dockerignore` | 11 |

业务提交在路由执行期间发生；会话通过 yield 依赖统一关闭。认证与路由默认共享同一请求的数据库依赖。用户身份来自服务端验证结果，而不是客户端传入的 owner_id。

## 6. 自动测试

在项目目录执行：

```bash
python -m pytest -q
```

测试不需要 `.env`，每个测试使用临时数据库。覆盖正常 CRUD、分页、标题清理、非法输入、重复注册、密码哈希、用户隔离、无效/过期 Token、依赖覆盖与重启持久化。

如果测试失败，先读断言里的实际响应与预期值，不要先修改状态码让测试通过。判断问题属于输入模型、鉴权、业务权限还是数据库事务。

## 7. 容易遇到的问题

| 问题 | 排查方法 |
| --- | --- |
| 启动提示 SECRET_KEY 校验失败 | 确认在项目目录启动，`.env` 已填入至少 32 字符的随机密钥 |
| 登录返回 422 | `/auth/token` 需要表单字段，不是 JSON |
| 任务接口返回 401 | 检查 `Bearer ` 前缀、Token 是否过期以及密钥是否变更 |
| 查询任务返回 404 | 检查编号和所属用户；不属于当前用户也返回 404 |
| 改模型后数据库没有新字段 | `create_all()` 不迁移已有表，需要 Alembic |
| 文档能打开但数据似乎丢了 | 检查工作目录和 DATABASE_URL，可能使用了另一份 SQLite 文件 |
| TestClient 启动资源没有初始化 | 使用 `with TestClient(app)` 管理 lifespan |

## 8. 完成标准与后续练习

能从空目录独立启动项目；能解释从 Token 到用户再到任务归属的检查链路；能通过测试证明 bob 不能操作 alice 的任务；重启后数据仍在；能说明教学自动建表与迁移的区别。

继续练习时，可以按顺序增加描述与截止日期、Alembic 迁移、PostgreSQL 集成测试、结构化日志、任务导出。缓存和实时推送等需求再参考[进阶专题](./index12.md)。

本项目没有刷新/撤销 Token、密码找回、限流、生产数据库迁移或实时通信，Docker 配置用于本地部署练习。把这些边界作为后续学习任务，不要直接视为完整生产模板。
