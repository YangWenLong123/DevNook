from pydantic import Field, SecretStr
from pydantic_settings import BaseSettings, SettingsConfigDict


class Settings(BaseSettings):
    model_config = SettingsConfigDict(env_file=".env", extra="ignore")

    secret_key: SecretStr = Field(min_length=32)
    database_url: str = "sqlite:///./tasks.db"
    access_token_expire_minutes: int = Field(default=30, ge=1, le=1440)
