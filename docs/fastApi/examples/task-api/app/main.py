from contextlib import asynccontextmanager

from fastapi import FastAPI

from .config import Settings
from .db import Base, create_database
from .routes import auth_router, task_router


def create_app(settings: Settings | None = None) -> FastAPI:
    @asynccontextmanager
    async def lifespan(app: FastAPI):
        config = settings if settings is not None else Settings()
        engine, factory = create_database(config.database_url)
        try:
            # Learning shortcut: create missing tables. Use Alembic for real migrations.
            Base.metadata.create_all(engine)
            app.state.settings = config
            app.state.session_factory = factory
            yield
        finally:
            engine.dispose()

    application = FastAPI(title="任务管理 API", version="0.1.0", lifespan=lifespan)
    application.include_router(auth_router)
    application.include_router(task_router)

    @application.get("/health", tags=["system"])
    def health():
        return {"status": "ok"}

    return application


app = create_app()
