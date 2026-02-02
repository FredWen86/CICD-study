# Part 6：GitHub Actions CD（单机部署：Docker Compose on Host）

本 Part 解释本仓库的 CD（持续部署）是如何把 `main` 分支的镜像部署到一台服务器上的。它不是 Kubernetes 教程，而是面向“先跑起来、可回滚、可观察”的最小闭环。

## 1) CD 的目标

- 当 `main` 有新提交时，自动部署对应的镜像版本
- 部署过程可追溯（使用 `sha-<gitsha>` tag）
- 部署失败可回滚（切回旧 tag）

## 2) 工作流文件在哪里

- `/.github/workflows/cd.yml`

## 3) 何时触发

- `push` 到 `main`
- 或手动触发：`workflow_dispatch`

## 4) CD 做了什么（按仓库实现解释）

### 4.1 生成生产环境的 env 文件（CI 里临时生成）

`cd.yml` 会在 workflow 运行时生成 `compose/.env.prod`，包含：

- `IMAGE_NAME=ghcr.io/<owner>/<repo>/api`
- `IMAGE_TAG=sha-<gitsha>`
- `ENVIRONMENT=prod`
- `POSTGRES_*` / `POSTGRES_DSN` / `REDIS_URL` / `API_PORT` 等

并打印一条英文日志：

- `INFO: compose/.env.prod created`

### 4.2 调用部署脚本：`scripts/deploy.sh`

脚本的核心逻辑：

- 把 `compose/compose.yml`、`compose/compose.prod.yml`、`compose/.env.prod` 通过 `scp` 同步到远端目录（`DEPLOY_PATH/compose/`）
- 在远端执行：
  - `docker login ghcr.io ...`
  - `docker compose pull`
  - `docker compose up -d`

## 5) Secrets（必须项）

见仓库根目录 `README.md` 的 “GitHub Actions CD（单机部署）需要的 Secrets”。

