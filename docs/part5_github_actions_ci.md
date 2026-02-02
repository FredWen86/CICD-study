# Part 5：GitHub Actions CI（lint / test / build）

本 Part 解释本仓库的 `ci` 工作流做了什么、何时触发、如何在 GitHub 前端观察日志，以及它如何帮助你形成“提交 → 检查 → 合并”的闭环。

## 1) CI 的目标

- **统一代码风格与质量门槛**：格式化与静态检查
- **保证基本正确性**：自动化测试
- **构建制品**：Docker 镜像（为后续部署做准备）

## 2) 工作流文件在哪里

- `/.github/workflows/ci.yml`

## 3) 何时触发

`ci.yml` 配置了：

- `pull_request`：当你创建/更新 PR 时触发（通常用于阻断合并）
- `push` 到 `main`：当 PR 合入 `main`（或直接 push 到 `main`）触发

## 4) 具体做了哪些步骤

CI 主要分三段：

### 4.1 Python 环境与依赖

- `actions/setup-python` 使用 Python 3.12
- 安装 `requirements-dev.txt`

### 4.2 Lint（ruff）

对应命令：

```bash
python -m ruff format --check .
python -m ruff check .
```

### 4.3 Test（pytest）

对应命令：

```bash
python -m pytest
```

### 4.4 Build（Docker 镜像）

本仓库用 Buildx + GitHub Actions cache（`type=gha`）：

- 首次构建会较慢
- 后续构建会复用缓存层，速度明显提升

## 5) 如何在 GitHub 上看结果

- PR 页面的 `Checks`
- Actions 页面的 workflow 运行记录

