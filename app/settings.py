"""应用配置（dev/prod 通过环境变量控制）。"""

from __future__ import annotations

from pydantic_settings import BaseSettings, SettingsConfigDict


class Settings(BaseSettings):
    """应用运行配置。

    说明：
    - 日志打印要求英文，代码注释用中文。
    - dev/prod 的差异由 compose 的 env 注入，不在代码里写死。
    """

    model_config = SettingsConfigDict(env_prefix="", case_sensitive=False)

    app_name: str = "cicd-study-api"
    environment: str = "dev"

    # 这些连接串用于 readiness 检查；未配置时不强制依赖外部服务。
    postgres_dsn: str | None = None
    redis_url: str | None = None
