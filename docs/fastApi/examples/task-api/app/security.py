from datetime import datetime, timedelta, timezone

import jwt
from pwdlib import PasswordHash

from .config import Settings

password_hash = PasswordHash.recommended()
DUMMY_HASH = password_hash.hash("timing-only-not-a-user-password")


def create_access_token(user_id: int, settings: Settings) -> str:
    now = datetime.now(timezone.utc)
    return jwt.encode(
        {
            "sub": str(user_id),
            "iat": now,
            "exp": now + timedelta(minutes=settings.access_token_expire_minutes),
        },
        settings.secret_key.get_secret_value(),
        algorithm="HS256",
    )
