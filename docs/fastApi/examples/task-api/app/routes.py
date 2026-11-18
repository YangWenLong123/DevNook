from typing import Annotated

from fastapi import APIRouter, Depends, HTTPException, Path, Query, Request, Response
from fastapi.security import OAuth2PasswordRequestForm
from sqlalchemy import select
from sqlalchemy.exc import IntegrityError
from sqlalchemy.orm import Session

from .dependencies import DbDep, UserDep
from .models import Task, User
from .schemas import TaskCreate, TaskRead, TaskUpdate, Token, UserCreate, UserRead
from .security import DUMMY_HASH, create_access_token, password_hash

auth_router = APIRouter(prefix="/auth", tags=["auth"])
task_router = APIRouter(prefix="/tasks", tags=["tasks"])


@auth_router.post("/register", response_model=UserRead, status_code=201)
def register(payload: UserCreate, db: DbDep):
    user = User(
        username=payload.username,
        password_hash=password_hash.hash(payload.password),
    )
    db.add(user)
    try:
        db.commit()
    except IntegrityError:
        db.rollback()
        raise HTTPException(status_code=409, detail="用户名已存在") from None
    return user


@auth_router.post("/token", response_model=Token)
def login(
    request: Request,
    db: DbDep,
    form: Annotated[OAuth2PasswordRequestForm, Depends()],
):
    username = form.username.strip().lower()
    user = db.scalar(select(User).where(User.username == username))
    valid = password_hash.verify(form.password, user.password_hash if user else DUMMY_HASH)
    if user is None or not valid:
        raise HTTPException(
            status_code=401,
            detail="用户名或密码错误",
            headers={"WWW-Authenticate": "Bearer"},
        )
    return Token(access_token=create_access_token(user.id, request.app.state.settings))


@auth_router.get("/me", response_model=UserRead)
def read_me(user: UserDep):
    return user


def owned_task(db: Session, task_id: int, user_id: int) -> Task:
    task = db.scalar(select(Task).where(Task.id == task_id, Task.owner_id == user_id))
    if task is None:
        raise HTTPException(status_code=404, detail="任务不存在")
    return task


@task_router.post("", response_model=TaskRead, status_code=201)
def create_task(payload: TaskCreate, db: DbDep, user: UserDep):
    task = Task(**payload.model_dump(), owner_id=user.id)
    db.add(task)
    db.commit()
    return task


@task_router.get("", response_model=list[TaskRead])
def list_tasks(
    db: DbDep,
    user: UserDep,
    limit: Annotated[int, Query(ge=1, le=100)] = 20,
    offset: Annotated[int, Query(ge=0)] = 0,
    completed: bool | None = None,
):
    statement = select(Task).where(Task.owner_id == user.id)
    if completed is not None:
        statement = statement.where(Task.completed == completed)
    statement = statement.order_by(Task.id).offset(offset).limit(limit)
    return db.scalars(statement).all()


@task_router.get("/{task_id}", response_model=TaskRead)
def read_task(task_id: Annotated[int, Path(gt=0)], db: DbDep, user: UserDep):
    return owned_task(db, task_id, user.id)


@task_router.patch("/{task_id}", response_model=TaskRead)
def update_task(
    task_id: Annotated[int, Path(gt=0)], payload: TaskUpdate, db: DbDep, user: UserDep
):
    task = owned_task(db, task_id, user.id)
    for name, value in payload.model_dump(exclude_unset=True).items():
        setattr(task, name, value)
    db.commit()
    return task


@task_router.delete("/{task_id}", status_code=204)
def delete_task(task_id: Annotated[int, Path(gt=0)], db: DbDep, user: UserDep):
    task = owned_task(db, task_id, user.id)
    db.delete(task)
    db.commit()
    return Response(status_code=204)
