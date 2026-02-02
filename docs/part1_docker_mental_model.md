# Part 1：Docker 的本质（脚本运维人的视角）

本 Part 的目标不是背命令，而是把 Docker 还原成你熟悉的系统概念：**进程 + 隔离 + 资源控制 + 分层文件系统**。

## 1) 你熟悉的世界 vs 容器世界（对齐心智模型）

- **容器（container）≈ 受隔离约束的一组进程**
  - namespace：让进程看到“自己的” PID/网络/挂载点/用户等视图
  - cgroup：对 CPU/内存/IO 做资源配额与统计
- **镜像（image）≈ 可复现的部署产物（制品），不是运行态**
  - 由多层 layer 组成（union filesystem）
  - 镜像不可变；运行时的可写层只存在于容器里
- **tag ≈ 人类友好的指针**
  - tag 会移动；sha digest 才是不可变的“内容地址”

一句话总结：
- 你过去用脚本“在机器上改状态”；Docker 更倾向于“构建制品 + 运行制品”。

## 2) 最小命令演练（建议你亲手跑一遍）

### 拉取镜像

```bash
docker pull nginx:alpine
```

### 运行一个容器（前台）

```bash
docker run --rm -p 8080:80 nginx:alpine
```

验证：

```bash
curl -I localhost:8080
```

### 运行一个容器（后台）

```bash
docker run -d --name demo-nginx -p 8080:80 nginx:alpine
```

查看：

```bash
docker ps
docker logs -f demo-nginx
```

### 进入容器（理解“容器不是 VM”）

```bash
docker exec -it demo-nginx sh
```

在容器里看进程与网络：

```bash
ps aux
ip a
```

### 文件系统与可写层（容器里写入，再删容器）

```bash
docker exec demo-nginx sh -lc 'echo hello > /tmp/hello.txt && cat /tmp/hello.txt'
docker rm -f demo-nginx
```

重新运行同名服务后，`/tmp/hello.txt` 不会保留（因为之前写在容器可写层里）。

### volume（把“数据”从容器生命周期里剥离出来）

```bash
docker volume create demo-data
docker run -d --name demo-alpine -v demo-data:/data alpine:3.20 sleep 999999
docker exec demo-alpine sh -lc 'echo hello > /data/hello.txt && cat /data/hello.txt'
docker rm -f demo-alpine

docker run --rm -v demo-data:/data alpine:3.20 sh -lc 'cat /data/hello.txt'
```

## 3) 你跑完后应该能回答的 5 个问题

1. 为什么说“容器是进程”，不是虚拟机？
2. 为什么说镜像是不可变制品，容器才是运行态？
3. layer 与容器可写层分别解决什么问题？
4. tag 和 digest 的区别是什么？为什么生产环境更偏好 digest？
5. 为什么数据要用 volume，而不是写在容器文件系统里？

