# Part 2：Dockerfile（把部署脚本固化成制品）

本 Part 以本仓库的 `docker/Dockerfile` 为例，讲清楚 Dockerfile 的“工程化写法”：**可复现、可缓存、最小权限、可健康检查**，并解释它为什么能显著提升 CI/CD 效率。

## 1) Dockerfile 的核心：把“部署步骤”变成“可缓存的层”

你可以把 Dockerfile 理解成一串“可缓存的部署步骤”：

- 每条 `RUN / COPY / ADD` 都可能形成一个 **layer**
- 当某一层的输入（指令文本 + 依赖文件）变化时，这一层和它之后的层会重建
- 前面的层如果输入不变，就会 **命中 cache**

这就是为什么“把变化频率低的东西放前面，把变化频率高的东西放后面”很重要。

## 2) 本仓库 Dockerfile 的分段解释

文件位置：`docker/Dockerfile`

### 2.1 多阶段构建：builder / runtime

- `builder`：允许装编译工具、构建依赖（最终镜像不带这些）
- `runtime`：只带运行所需的最小文件（更小、更安全）

设计意图：**构建环境 ≠ 运行环境**。

### 2.2 依赖缓存：先 COPY requirements，再 pip install

本仓库把 `requirements.txt` 单独拷贝后再装依赖：

- 你只改业务代码时，不会触发依赖重装
- 你改 `requirements.txt` 时，才会从依赖层开始重建

这一步对 CI 提速最明显。

### 2.3 venv 拷贝：把依赖变成可搬运的制品

本仓库在 `builder` 阶段创建 `/opt/venv`，安装依赖，再把整个 venv 拷贝到 `runtime`：

- `runtime` 阶段不需要编译工具
- 依赖是“已安装好的产物”，启动更稳定

### 2.4 非 root 运行：最小权限

本仓库创建 `appuser` 并 `USER appuser`：

- 避免容器内进程拥有 root 权限
- 这是生产环境的基础安全习惯

### 2.5 健康检查：把“服务可用”变成可观测状态

本仓库使用：

- Dockerfile：`HEALTHCHECK ...`
- 脚本：`docker/healthcheck.py`（访问 `http://127.0.0.1:$PORT/health`）

这能让：

- `docker ps` 显示容器 `healthy/unhealthy`
- Compose/K8s 更容易做“依赖可用再启动”的编排

## 3) ENTRYPOINT vs CMD（结合本仓库）

### 3.1 结论（你要记住的）

- **ENTRYPOINT**：固定入口（把容器当成“可执行程序”）
- **CMD**：默认参数（可被覆盖）

### 3.2 本仓库为什么只写 ENTRYPOINT

本仓库的 `docker/entrypoint.sh` 用环境变量控制 `HOST/PORT/WEB_CONCURRENCY`，并通过 `exec` 启动 uvicorn：

- `exec` 的价值：让 uvicorn 成为 PID 1，能够正确接收 `SIGTERM`（优雅退出）
- 可变配置走环境变量：更符合“部署系统注入配置”的方式

dev 环境（compose）会通过 `command:` 覆盖启动方式（加入 `--reload`），这是“开发体验优先”的典型做法。

## 4) 建议你做的 3 个验证（强烈建议亲手跑）

在仓库根目录执行：

### 4.1 构建镜像

```bash
docker build -f docker/Dockerfile -t cicd-study-api:local .
```

### 4.2 看镜像层（理解 layer）

```bash
docker history cicd-study-api:local
```

### 4.3 验证 cache（第二次构建应显著更快）

```bash
docker build -f docker/Dockerfile -t cicd-study-api:local .
```

如果你修改了 `requirements.txt`，你会看到从 `COPY requirements.txt ...` 之后的层开始重建，这是符合预期的。

