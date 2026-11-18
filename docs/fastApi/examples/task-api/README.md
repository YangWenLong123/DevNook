# 任务管理 API 教学项目

配合 [FastAPI 实战文档](../../index13.md)学习。技术栈为 FastAPI、Pydantic v2、同步 SQLAlchemy 2.x、SQLite、PyJWT 与 pwdlib Argon2。

## 本地运行

在本目录创建虚拟环境并激活，Python 3.12+：

```bash
python3 -m venv .venv
source .venv/bin/activate
python -m pip install -r requirements-dev.txt
cp .env.example .env
python -c 'import secrets; print(secrets.token_hex(32))'
```

把生成的值填入 `.env` 的 `SECRET_KEY`，再运行：

```bash
python -m uvicorn app.main:app --reload
```

打开 `http://127.0.0.1:8000/docs`。先注册，再通过 Authorize 输入用户名密码登录。注册接收 JSON，`/auth/token` 接收表单。任务接口使用 Bearer Token。

Windows PowerShell 使用 `py -3 -m venv .venv`、`.\.venv\Scripts\Activate.ps1` 和 `Copy-Item .env.example .env`；其余步骤相同。

## 测试

```bash
python -m pytest -q
```

测试使用临时数据库与显式测试密钥，不需要 `.env`。覆盖登录、密码哈希、参数校验、CRUD、分页、用户隔离、Token 失效、依赖覆盖和应用重启后的持久化。

## 文件与约定

- `app/config.py`：环境变量与 `.env` 读取。
- `app/db.py`、`app/models.py`：连接工厂与数据库模型。
- `app/schemas.py`：独立的请求与响应模型。
- `app/security.py`、`app/dependencies.py`：哈希、JWT、会话和当前用户依赖。
- `app/routes.py`、`app/main.py`：路由与应用工厂。
- `Dockerfile`：容器练习，运行命令见 [部署文档](../../index11.md)。

默认数据库是当前工作目录中的 `tasks.db`。教程使用启动时 `create_all()` 创建缺失表，不包含 Alembic 迁移、刷新 Token、撤销 Token、密码找回和生产限流。修改已有表结构应接入迁移；多实例部署应改用服务型数据库。

依赖文件采用版本范围，实际交付应在测试后锁定精确版本。不要提交真实 `.env`、数据库或密钥。
