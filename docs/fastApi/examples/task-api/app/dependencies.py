from typing import Annotated

import jwt
from fastapi import Depends, HTTPException, Request
from fastapi.security import OAuth2PasswordBearer
from sqlalchemy.orm import Session

from .models import User

oauth2_scheme = OAuth2PasswordBearer(tokenUrl="auth/token")


def get_db(request: Request):
    with request.app.state.session_factory() as session:
        yield session


DbDep = Annotated[Session, Depends(get_db)]


def get_current_user(
    request: Request,
    db: DbDep,
    token: Annotated[str, Depends(oauth2_scheme)],
) -> User:
    error = HTTPException(
        status_code=401,
        detail="登录凭证无效或已过期",
        headers={"WWW-Authenticate": "Bearer"},
    )
    try:
        payload = jwt.decode(
            token,
            request.app.state.settings.secret_key.get_secret_value(),
            algorithms=["HS256"],
            options={"require": ["sub", "exp", "iat"]},
        )
        user_id = int(payload["sub"])
    except (jwt.InvalidTokenError, ValueError, TypeError):
        raise error from None
    user = db.get(User, user_id)
    if user is None:
        raise error
    return user


UserDep = Annotated[User, Depends(get_current_user)]
