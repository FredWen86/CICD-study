"""FastAPI 应用入口。"""

from __future__ import annotations

import logging

import os
import asyncpg
import redis.asyncio as redis
from fastapi import FastAPI

from app.settings import Settings

logger = logging.getLogger("cicd-study")


def create_app() -> FastAPI:
    """创建 FastAPI 应用。"""

    settings = Settings()

    logging.basicConfig(
        level=logging.INFO,
        format="%(asctime)s %(levelname)s %(name)s - %(message)s",
    )

    app = FastAPI(title=settings.app_name)

    @app.get("/health")
    async def health() -> dict[str, object]:
        """健康检查：liveness + 可选 readiness。"""

        readiness: dict[str, object] = {"postgres": None, "redis": None}

        if settings.postgres_dsn:
            try:
                conn = await asyncpg.connect(settings.postgres_dsn, timeout=2)
                try:
                    await conn.execute("SELECT 1")
                    readiness["postgres"] = True
                finally:
                    await conn.close()
            except Exception as exc:  # noqa: BLE001
                logger.warning("Postgres readiness check failed: %s", exc)
                readiness["postgres"] = False

        if settings.redis_url:
            try:
                client = redis.from_url(settings.redis_url, socket_timeout=2)
                try:
                    pong = await client.ping()
                    readiness["redis"] = bool(pong)
                finally:
                    await client.aclose()
            except Exception as exc:  # noqa: BLE001
                logger.warning("Redis readiness check failed: %s", exc)
                readiness["redis"] = False

        return {
            "status": "ok",
            "environment": settings.environment,
            "readiness": readiness,
        }

    @app.get("/")
    async def root() -> dict[str, str]:
        return {"message": "Hello from cicd-study"}

    return app


app = create_app()
