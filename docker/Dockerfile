FROM python:3.12-slim AS builder

ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1 \
    PIP_DISABLE_PIP_VERSION_CHECK=1 \
    PIP_NO_CACHE_DIR=1

WORKDIR /build

# 构建阶段可包含编译工具（运行阶段不需要）
RUN apt-get update \
    && apt-get install -y --no-install-recommends build-essential \
    && rm -rf /var/lib/apt/lists/*

COPY requirements.txt /build/requirements.txt

RUN python -m venv /opt/venv
ENV PATH="/opt/venv/bin:$PATH"

RUN python -m pip install -U pip \
    && python -m pip install -r /build/requirements.txt


FROM python:3.12-slim AS runtime

ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1 \
    PATH="/opt/venv/bin:$PATH"

WORKDIR /app

RUN adduser --disabled-password --gecos "" --home /nonexistent appuser

COPY --from=builder /opt/venv /opt/venv
COPY app /app/app
COPY docker/entrypoint.sh /app/docker/entrypoint.sh
COPY docker/healthcheck.py /app/docker/healthcheck.py

RUN chmod +x /app/docker/entrypoint.sh \
    && chown -R appuser:appuser /app

USER appuser

EXPOSE 8000

HEALTHCHECK --interval=10s --timeout=3s --start-period=10s --retries=3 \
  CMD ["python", "/app/docker/healthcheck.py"]

ENTRYPOINT ["/app/docker/entrypoint.sh"]
