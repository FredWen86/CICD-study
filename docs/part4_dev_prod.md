# Part 4：开发环境 vs 生产环境（分离原则落地）

本 Part 解释为什么 dev/prod 不能共用一套运行方式，并以本仓库的 `compose/compose.dev.yml` 与 `compose/compose.prod.yml` 为例，把差异落到可操作的规则上。

## 1) 一句话原则

- **dev**：开发体验优先（热更新/调试/可观察性），允许依赖本机状态
- **prod**：稳定与可复现优先（镜像即制品），禁止“服务器上临时改状态”

## 2) 本仓库的两层覆盖

### 2.1 dev 覆盖层：`compose/compose.dev.yml`

dev 的目标是快速迭代：

- **从源码 build**：`build: { context: .., dockerfile: docker/Dockerfile }`
- **挂载源码**：`../app:/app/app`（宿主机源码同步到容器）
- **覆盖启动方式**：`uvicorn ... --reload`（更适合开发）

一句话：**dev 允许“运行态依赖本机”，用更快迭代换来更少可复现性**。

### 2.2 prod 覆盖层：`compose/compose.prod.yml`

prod 的目标是可复现与稳定：

- **不挂载源码**（镜像即制品）
- **不在服务器上 build**（只拉取已构建好的镜像）
- **restart 策略**：`unless-stopped`
- 启动方式由镜像内 `ENTRYPOINT` 决定（见 `docker/entrypoint.sh`）

一句话：**prod 只运行制品镜像，通过环境注入配置**。

## 3) 版本切换/回滚应该改什么

理想情况下：

- 不改 `compose*.yml`（声明应尽量稳定）
- 只改镜像 tag（版本号），例如在 `.env.prod` 里修改：
  - `IMAGE_TAG=sha-<gitsha>`

然后执行：

```bash
docker compose --env-file compose/.env.prod \
  -f compose/compose.yml -f compose/compose.prod.yml pull

docker compose --env-file compose/.env.prod \
  -f compose/compose.yml -f compose/compose.prod.yml up -d
```

