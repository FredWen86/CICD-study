# Part 3：Docker Compose（单机编排）

本 Part 聚焦 Compose 的“单机编排”能力：用声明式方式把 `api + postgres + redis` 作为一个整体启动、观察、停止，并讲清楚 **网络 / 健康依赖 / volume** 三个关键概念。

## 1) Compose 的核心：声明「我想要的运行态」

你写的 `compose*.yml` 不是脚本，而是“目标状态”：

- **服务**（service）：要跑什么进程（镜像/命令/端口/环境变量/依赖）
- **网络**（network）：服务之间如何通信（默认网络即可）
- **卷**（volume）：数据如何持久化（数据库数据必须脱离容器生命周期）

Compose 会尽可能把当前状态收敛到你声明的状态。

## 2) 本仓库的基础层：`compose/compose.yml`

这里定义了“业务需要哪些服务”以及“服务之间怎么连”：

- `api`：FastAPI 服务（默认只引用镜像 `image:`）
- `postgres`：数据库（带健康检查、挂载 `postgres_data`）
- `redis`：缓存（带健康检查）
- `api` 的 `depends_on`：等待 postgres/redis 健康后再启动

> 设计意图：`compose.yml` 尽量稳定，成为 dev/prod 共同的“最小运行拓扑”。

## 3) 为什么 DSN 里是 `postgres` 而不是 `localhost`

在同一个 Compose 项目里，服务通过 **service 名称**互相访问：

- 数据库：`postgres:5432`
- Redis：`redis:6379`

而 `localhost`（127.0.0.1）只代表“当前容器自己”，访问不到其他容器。

## 4) 健康依赖：`service_healthy` 解决的是什么

脚本时代常见坑：**进程起来了 ≠ 服务可用**。

本仓库用 healthcheck 把“可用”变成可观测状态，再让 `api` 等依赖服务 health 之后启动，减少启动抖动与偶发失败。

## 5) 数据持久化：为什么 Postgres 必须 volume

数据库的数据不能写在容器可写层里（删容器就丢失）。

本仓库用 named volume（`postgres_data`）把数据生命周期从容器里剥离出来。

## 6) 常用命令（本仓库推荐）

### 启动（dev 形态需要叠加 dev 覆盖层，见 Part 4）

```bash
cp compose/.env.example compose/.env

docker compose --env-file compose/.env \
  -f compose/compose.yml -f compose/compose.dev.yml up --build
```

### 查看状态与日志

```bash
docker compose --env-file compose/.env \
  -f compose/compose.yml -f compose/compose.dev.yml ps

docker compose --env-file compose/.env \
  -f compose/compose.yml -f compose/compose.dev.yml logs -f api
```

### 停止并清理（含 volume）

```bash
docker compose --env-file compose/.env \
  -f compose/compose.yml -f compose/compose.dev.yml down -v
```

