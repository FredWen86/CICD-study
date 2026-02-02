# CICD-study

这是一个用于系统练习 **Docker / Docker Compose / CI / CD** 的示例仓库（练习栈：**Python + FastAPI**，CI 平台：**GitHub Actions**）。

## 文档（按 Part 阅读）

- [docs/README.md](./docs/README.md)

## 本地开发（不使用 Docker）

- **安装依赖**：

```bash
python -m venv .venv
. .venv/bin/activate
python -m pip install -U pip
python -m pip install -e ".[dev]"
```

- **运行服务**：

```bash
uvicorn app.main:app --host 0.0.0.0 --port 8000 --reload
```

- **验证**：

```bash
curl -sS localhost:8000/health | python -m json.tool
```

- **运行检查**：

```bash
python -m ruff format .
python -m ruff check .
python -m pytest
```

## 本地开发（Docker Compose）

- **准备环境变量**：

```bash
cp compose/.env.example compose/.env
```

- **启动（dev：热更新）**：

```bash
docker compose --env-file compose/.env \
  -f compose/compose.yml -f compose/compose.dev.yml up --build
```

- **验证**（默认对外端口 `18000`）：

```bash
curl -sS localhost:18000/health | python -m json.tool
```

- **停止并清理**：

```bash
docker compose --env-file compose/.env \
  -f compose/compose.yml -f compose/compose.dev.yml down -v
```

## 生产形态（Compose 思维）

- **关键原则**：
  - **镜像 = 制品**：prod 不挂载源码、不在服务器上 build
  - **配置/密钥 = 环境注入**：不进仓库，用 Secrets/环境变量/服务器文件
  - **tag = 版本**：上线与回滚都只改镜像 tag（本仓库 CI 默认推 `sha-<gitsha>` 与 `latest`）

- **示例（本机模拟 prod）**：

```bash
# 仍然使用 compose/.env（只是示例），真实 prod 建议单独准备 compose/.env.prod
docker compose --env-file compose/.env \
  -f compose/compose.yml -f compose/compose.prod.yml up -d
```

## GitHub Actions CD（单机部署）需要的 Secrets

在 GitHub 仓库的 `Settings -> Secrets and variables -> Actions` 里配置：

- **部署主机信息**
  - `DEPLOY_HOST`：目标主机 IP/域名
  - `DEPLOY_USER`：SSH 用户
  - `DEPLOY_PATH`：部署目录（例如 `/opt/cicd-study`）
  - `DEPLOY_SSH_KEY`：SSH 私钥（建议单独用于 CI/CD）

- **拉取 GHCR 镜像**
  - `GHCR_USERNAME`：GHCR 用户名/组织名
  - `GHCR_TOKEN`：具备 `read:packages` 权限的 token（用于部署机 `docker login`）

- **应用配置（示例使用本仓库自带 postgres/redis）**
  - `POSTGRES_PASSWORD`：生产环境数据库密码（必填）
  - `POSTGRES_USER`、`POSTGRES_DB`、`API_PORT`：可选（不填则使用默认值）
