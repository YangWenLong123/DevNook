# 06. 数据库与 CRUD

本章目标：用 SQLAlchemy 2.x 实现可持久化的任务增删改查，理解会话、事务、查询与数据库迁移。

## 1. 先区分三个对象

| 对象 | 职责 | 例子 |
| --- | --- | --- |
| 数据库表 | 存储数据、维护约束 | `tasks` 表 |
| SQLAlchemy 模型 | 将 Python 属性映射为表字段 | `Task` |
| Pydantic 模型 | 校验接口输入、约束接口输出 | `TaskCreate`、`TaskRead` |

ORM 不会替代数据库知识。主键、唯一约束、外键、索引和事务仍需要学习。SQLite 适合单机入门；多实例、较多并发写入的服务通常选择 PostgreSQL 等服务型数据库。

## 2. 安装与文件结构

```bash
python -m pip install "fastapi>=0.115,<1" "uvicorn[standard]>=0.30,<1" "SQLAlchemy>=2,<3" alembic
```

创建独立目录 `database-demo`，放入下面三个文件：

```text
database-demo/
├── database.py
├── models.py
└── main.py
```

### 2.1 database.py：引擎与会话工厂

```python
from sqlalchemy import create_engine
from sqlalchemy.orm import DeclarativeBase, sessionmaker


class Base(DeclarativeBase):
    pass


engine = create_engine(
    "sqlite:///./tasks.db",
    connect_args={"check_same_thread": False},
)
SessionLocal = sessionmaker(bind=engine, expire_on_commit=False)


def get_db():
    with SessionLocal() as session:
        yield session
```

`engine` 管理数据库连接能力与连接池；`SessionLocal` 是创建会话的工厂；`Session` 跟踪对象变更并执行事务。

SQLite 的 `check_same_thread=False` 允许连接在不同线程中使用，配合 FastAPI 的同步请求处理。它不代表同一个 Session 可以随意跨线程并发使用。一般每个请求使用自己的会话。

### 2.2 models.py：数据库模型

```python
from sqlalchemy import Boolean, String
from sqlalchemy.orm import Mapped, mapped_column

from database import Base


class Task(Base):
    __tablename__ = "tasks"

    id: Mapped[int] = mapped_column(primary_key=True)
    title: Mapped[str] = mapped_column(String(100))
    completed: Mapped[bool] = mapped_column(Boolean, default=False, index=True)
```

`Mapped[...]` 与 `mapped_column()` 是 SQLAlchemy 2.x 的类型化映射方式。数据库长度、非空、唯一性等约束仍要按目标数据库验证；例如 SQLite 不会像某些数据库一样严格执行 `VARCHAR(100)` 长度限制。

### 2.3 main.py：完整 CRUD

```python
from contextlib import asynccontextmanager
from typing import Annotated

from fastapi import Depends, FastAPI, HTTPException, Path, Query, Response
from pydantic import BaseModel, ConfigDict, Field, field_validator
from sqlalchemy import select
from sqlalchemy.orm import Session

from database import Base, engine, get_db
from models import Task


@asynccontextmanager
async def lifespan(app: FastAPI):
    Base.metadata.create_all(engine)
    try:
        yield
    finally:
        engine.dispose()


app = FastAPI(lifespan=lifespan)
DbDep = Annotated[Session, Depends(get_db)]


class TaskCreate(BaseModel):
    title: str = Field(min_length=1, max_length=100)
    completed: bool = False


class TaskUpdate(BaseModel):
    model_config = ConfigDict(extra="forbid")

    title: str | None = Field(default=None, min_length=1, max_length=100)
    completed: bool | None = None

    @field_validator("title", "completed")
    @classmethod
    def reject_null(cls, value):
        if value is None:
            raise ValueError("字段不能为 null")
        return value


class TaskRead(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: int
    title: str
    completed: bool


def find_task(db: Session, task_id: int) -> Task:
    task = db.get(Task, task_id)
    if task is None:
        raise HTTPException(status_code=404, detail="任务不存在")
    return task


@app.post("/tasks", response_model=TaskRead, status_code=201)
def create_task(payload: TaskCreate, db: DbDep):
    task = Task(**payload.model_dump())
    db.add(task)
    db.commit()
    db.refresh(task)
    return task


@app.get("/tasks", response_model=list[TaskRead])
def list_tasks(
    db: DbDep,
    limit: Annotated[int, Query(ge=1, le=100)] = 20,
    offset: Annotated[int, Query(ge=0)] = 0,
    completed: bool | None = None,
):
    statement = select(Task)
    if completed is not None:
        statement = statement.where(Task.completed == completed)
    statement = statement.order_by(Task.id).offset(offset).limit(limit)
    return db.scalars(statement).all()


@app.get("/tasks/{task_id}", response_model=TaskRead)
def read_task(task_id: Annotated[int, Path(gt=0)], db: DbDep):
    return find_task(db, task_id)


@app.patch("/tasks/{task_id}", response_model=TaskRead)
def update_task(task_id: Annotated[int, Path(gt=0)], payload: TaskUpdate, db: DbDep):
    task = find_task(db, task_id)
    for name, value in payload.model_dump(exclude_unset=True).items():
        setattr(task, name, value)
    db.commit()
    db.refresh(task)
    return task


@app.delete("/tasks/{task_id}", status_code=204)
def delete_task(task_id: Annotated[int, Path(gt=0)], db: DbDep):
    task = find_task(db, task_id)
    db.delete(task)
    db.commit()
    return Response(status_code=204)
```

在 `database-demo` 内运行 `python -m uvicorn main:app --reload`。创建任务后停止并重新启动，任务仍然存在，数据保存在当前工作目录的 `tasks.db`。

## 3. 理解 add、flush、commit、refresh

- `add()`：把对象放入会话，尚不等于数据库已经提交。
- `flush()`：把待处理变更发送到数据库，通常可获取生成的主键，但事务还没有提交。
- `commit()`：提交当前事务；必要时会先自动 flush。
- `refresh()`：重新查询数据库，更新对象上的属性。
- `rollback()`：回滚当前事务，使失败后的会话恢复到可以继续使用的状态。

如果一次业务包含多次写入，应放在同一事务中完成，而不是每写一行就提交一次。`expire_on_commit=False` 允许提交后继续读取已加载属性，但这些属性不保证反映其他事务后续的修改。

## 4. 数据库约束与回滚

“先查用户名是否存在，再插入”不能完全避免并发重复。最终应由数据库唯一约束保证，然后处理冲突。

下面是业务代码中的事务片段，`db` 是当前 Session，`user` 是待保存且有唯一用户名约束的对象：

```python
from fastapi import HTTPException
from sqlalchemy.exc import IntegrityError

db.add(user)
try:
    db.commit()
except IntegrityError:
    db.rollback()
    raise HTTPException(status_code=409, detail="数据约束冲突") from None
```

不要把所有异常都解释成“用户名重复”；复杂项目需要识别具体约束。第 13 章的注册表结构简单，因此直接处理其唯一用户名冲突。

## 5. 分页与查询习惯

列表查询使用显式 `order_by()` 保证顺序，再使用 `offset` 与 `limit`。不要一次读出全部记录后用 Python 切片做分页。

`db.scalars(select(Task)).all()` 返回模型列表；`db.execute(select(Task)).all()` 返回 Row 列表，二者形状不同。新项目优先学习 `select()`，不必从旧式 `db.query()` 开始。

大偏移分页会越来越慢，数据量大时可以学习基于 `id > last_id` 的游标分页。索引应根据实际查询建立，单独为低区分度布尔列建立索引未必有收益，需要查看执行计划。

## 6. Alembic 数据库迁移

`create_all()` 适合练习时创建缺失的表，**不会把已有表自动修改成新的模型结构**。真实项目用版本化迁移追踪加字段、建索引等变更。

在本章 `database-demo` 中执行：

```bash
python -m alembic init migrations
```

将 `alembic.ini` 的 `sqlalchemy.url` 设置为 `sqlite:///./migration-demo.db`，用一个新数据库练习初始迁移。在生成的 `migrations/env.py` 中导入模型并替换元数据：

```python
from database import Base
import models  # 导入后，模型才登记到 Base.metadata。

target_metadata = Base.metadata
```

```bash
python -m alembic revision --autogenerate -m "create tasks"
python -m alembic upgrade head
python -m alembic current
```

检查生成脚本再执行。自动生成不能可靠判断字段重命名、业务数据转换等所有变更。若数据库已经由 `create_all()` 建好，初始对比可能没有变更；不要未经检查就把现有数据库 stamp 成某个版本。

迁移接管后，移除启动时的 `create_all()`，先执行迁移，再启动应用。`downgrade` 可能删除数据，应先在测试数据库练习。

## 7. 切换 PostgreSQL

安装 `psycopg[binary]`，把 URL 换成 `postgresql+psycopg://user:password@host:5432/tasks`，同时移除 SQLite 专用的 `connect_args`。

不要把真实密码写入文档或提交到仓库。连接信息应通过第 8 章的环境配置读取；迁移与测试也必须切换到对应数据库验证。

## 8. 练习与验收

新增、分页查询、只查询未完成任务、PATCH 修改、删除并确认 404；重启后验证数据仍在；增加描述字段并用 Alembic 生成、检查和应用迁移。

参考：[SQLAlchemy Unified Tutorial](https://docs.sqlalchemy.org/en/20/tutorial/)、[Alembic Tutorial](https://alembic.sqlalchemy.org/en/latest/tutorial.html)。下一章：[07. 用户登录与权限](./index7.md)。
