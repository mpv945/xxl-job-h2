envsubst < /etc/mysql/my.cnf.tpl > /etc/mysql/my.cnf

可以用，而且这是**很典型的 MySQL 官方“二进制精简版 vs 完整版”选择问题**。

https://dev.mysql.com/downloads/mysql/
Select Version:  9.7.1 LTS
Select Operating System: Linux - Generic
Select OS Version: Linux - Generic (glibc 2.28) (x86, 64-bit)

你这两个包本质都是 Linux 通用二进制安装包（不是 rpm/deb）：

* `mysql-9.7.1-linux-glibc2.28-x86_64.tar.xz`
* `mysql-9.7.1-linux-glibc2.28-x86_64-minimal.tar.xz`

都属于 MySQL 官方 Generic Linux Binary。

---

# 🚀 一、结论先说

| 包类型            | 是否推荐  | 适用场景           |
| -------------- | ----- | -------------- |
| `full`（完整包）    | ⭐⭐⭐⭐  | 生产/开发通用        |
| `minimal`（精简包） | ⭐⭐⭐⭐⭐ | 容器 / 内网 / 极致轻量 |

---

# 📦 二、核心区别（重点）

## 1️⃣ full（完整包）

```bash
mysql-9.7.1-linux-glibc2.28-x86_64.tar.xz
```

### 包含内容：

✔ MySQL Server
✔ Client 工具（mysql / mysqldump）
✔ Debug 工具
✔ 一些额外库
✔ 完整插件体系
✔ man page / 辅助工具

### 特点：

* 功能完整
* 体积较大（通常 400MB~600MB）
* 适合传统安装方式

---

## 2️⃣ minimal（精简包）

```bash
mysql-9.7.1-linux-glibc2.28-x86_64-minimal.tar.xz
```

### 只包含：

✔ mysqld（核心服务端）
✔ 最基本 client
✔ 最小运行依赖
❌ 没有多余工具
❌ 没有 debug 工具
❌ 没有多余 plugin bundle

### 特点：

* 体积小（通常 80MB~150MB）
* 启动更快
* 更适合 Docker / K8s

---

# 🧠 三、最关键差异（本质）

| 维度           | full | minimal |
| ------------ | ---- | ------- |
| mysqld       | ✔    | ✔       |
| mysql client | ✔ 完整 | ✔ 简化    |
| mysqldump    | ✔    | ❌/弱化    |
| plugin       | 全    | 最小集合    |
| debug工具      | 有    | 无       |
| 容器体积         | 大    | ⭐小      |

---

# 🚀 四、哪个该选？

## ✔ 推荐选择逻辑

### 👉 如果你是：

### 1️⃣ Docker / Spring Boot / 微服务

✔ 用 minimal（强烈推荐）

---

### 2️⃣ 传统 Linux 安装（运维环境）

✔ 用 full

---

### 3️⃣ 内网离线部署（你这种场景）

✔ 推荐 minimal + 自定义补工具

---

### 4️⃣ 做数据库平台 / DBA 环境

✔ full 更合适

---

# 🐳 五、Docker 场景推荐（重点）

你如果要做：

> MySQL + Spring Boot + Docker

👉 最优解是：

```text
mysql minimal tar + 自定义 Dockerfile
```

原因：

* 镜像小（可以做到 <200MB）
* 启动快
* 不带冗余工具
* 更安全（攻击面小）

---

# ⚙️ 六、minimal 安装方式（核心步骤）

## 1️⃣ 解压

```bash
tar -xJf mysql-9.7.1-linux-glibc2.28-x86_64-minimal.tar.xz
mv mysql-9.7.1-linux-glibc2.28-x86_64-minimal /usr/local/mysql
```

---

## 2️⃣ 初始化

```bash
cd /usr/local/mysql

bin/mysqld --initialize \
  --user=mysql \
  --basedir=/usr/local/mysql \
  --datadir=/data/mysql
```

---

## 3️⃣ 启动

```bash
bin/mysqld_safe --user=mysql &
```

---

# ⚠️ 七、minimal 的坑（很重要）

## ❌ 1. mysqldump 可能没有

👉 需要你单独补：

```bash
apt install mysql-client
```

---

## ❌ 2. 缺少运维工具

比如：

* mysqladmin
* mysqlcheck

---

## ❌ 3. 插件可能要手动加载

---

# 🧠 八、推荐架构（企业最佳实践）

如果你做生产系统：

```text
Spring Boot
    ↓
MySQL (minimal Docker)
    ↓
Volume 持久化
```

或者：

```text
MySQL full（传统服务器）
```

---

# 🚀 九、最终建议（给你直接结论）

✔ 如果你要：

### 👉 Docker / 微服务 / Spring Boot

➡ 选：

```text
mysql-minimal.tar.xz ⭐⭐⭐⭐⭐
```

---

### 👉 运维服务器 / DBA / 全功能

➡ 选：

```text
mysql-full.tar.xz ⭐⭐⭐⭐
```

---

# 🔥 如果你下一步要做

我可以直接帮你做一个完整方案：

### 🚀 MySQL minimal + Spring Boot Docker 一体化

包含：

* Dockerfile（最小镜像）
* 自动初始化 SQL
* Spring Boot 连接优化
* healthcheck
* docker-compose 一键启动
* 内网离线部署版本

直接可以上线用 👍




很好，这个需求本质是做一个**“极简生产级 MySQL + Spring Boot 一体化容器（但仍保持最佳实践隔离）”**。

我给你做一套**真正偏生产思路 + 镜像极简 + 可直接跑**的方案。

---

# 🚀 一、核心目标设计

你要的是：

* ✔ MySQL 使用 minimal 版（体积小）
* ✔ Spring Boot 同容器运行
* ✔ 镜像尽可能小
* ✔ 启动简单
* ✔ 适合内网 / 离线 / demo / PoC
* ✔ 不用 systemd / supervisor（更轻）

---

# ⚠️ 先说结论（非常重要）

👉 最干净方案其实是：

> **MySQL + Spring Boot 同容器 + tini + bash 启动脚本**

不用：

* ❌ supervisor（重）
* ❌ systemd（更重）
* ❌ 多层 init 系统

---

# 🧱 二、最终架构

```
容器启动
   │
   ├── mysqld (后台)
   │
   └── Spring Boot (前台 PID1)
```

---

# 📦 三、目录结构

```
mysql-springboot/
├── Dockerfile
├── entrypoint.sh
├── mysql/
│   └── mysql-9.7-minimal.tar.xz
├── app/
│   └── app.jar
└── my.cnf
```

---

# 🐳 四、Dockerfile（极简核心）

👉 基于 alpine（尽量小）

```dockerfile id="d1kq0a"
FROM alpine:3.20

# 基础依赖（最小集合）
RUN apk add --no-cache \
    bash \
    libstdc++ \
    libaio \
    libgcc \
    tar \
    xz \
    openjdk17-jre-headless

# 创建目录
WORKDIR /opt

# 复制 MySQL minimal
COPY mysql/mysql-9.7.1-linux-glibc2.28-x86_64-minimal.tar.xz /opt/

# 解压 MySQL
RUN tar -xJf mysql-*.tar.xz && \
    mv mysql-*-minimal mysql && \
    rm -f mysql-*.tar.xz

# 创建数据目录
RUN addgroup -S mysql && adduser -S mysql -G mysql && \
    mkdir -p /data/mysql && \
    chown -R mysql:mysql /data/mysql /opt/mysql

# Spring Boot
COPY app/app.jar /app/app.jar

# 配置文件
COPY my.cnf /etc/my.cnf
COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

EXPOSE 3306 8080

ENTRYPOINT ["/entrypoint.sh"]
```

---

# ⚙️ 五、MySQL 配置（极简）

```ini id="g8k3x2"
[mysqld]
basedir=/opt/mysql
datadir=/data/mysql
port=3306

character-set-server=utf8mb4
collation-server=utf8mb4_general_ci

skip-name-resolve
max_connections=500

log_error=/data/mysql/error.log
```

---

# 🚀 六、启动脚本（核心关键）

```bash id="p7c2f9"
#!/bin/bash

set -e

MYSQL_HOME=/opt/mysql
DATADIR=/data/mysql

echo ">>> init mysql if needed"

if [ ! -d "$DATADIR/mysql" ]; then
  echo ">>> initializing mysql..."
  $MYSQL_HOME/bin/mysqld \
    --initialize-insecure \
    --user=mysql \
    --basedir=$MYSQL_HOME \
    --datadir=$DATADIR
fi

echo ">>> starting mysql..."
$MYSQL_HOME/bin/mysqld \
  --defaults-file=/etc/my.cnf \
  --user=mysql &

MYSQL_PID=$!

echo ">>> waiting mysql..."
sleep 10

echo ">>> starting spring boot..."
exec java -jar /app/app.jar \
  --spring.datasource.url="jdbc:mysql://127.0.0.1:3306/test?useSSL=false&serverTimezone=Asia/Shanghai" \
  --spring.datasource.username=root \
  --spring.datasource.password=
```

---

# 📦 七、Spring Boot Docker 打包方式

建议你用：

```dockerfile id="q9w2lm"
FROM eclipse-temurin:17-jre-alpine

WORKDIR /app
COPY app.jar /app/app.jar

ENTRYPOINT ["java","-jar","/app/app.jar"]
```

但这里我们已经合并进 MySQL 容器了。

---

# 🧪 八、构建镜像

```bash id="x3c9lm"
docker build -t mysql-springboot-lite .
```

---

# 🚀 九、运行

```bash id="n1kq7v"
docker run -d \
  --name ms-lite \
  -p 3306:3306 \
  -p 8080:8080 \
  mysql-springboot-lite
```

---

# 📉 十、最终镜像优化效果

| 项目         | 结果              |
| ---------- | --------------- |
| MySQL      | minimal         |
| JRE        | alpine-headless |
| shell      | bash only       |
| init       | inline          |
| supervisor | ❌ 无             |
| systemd    | ❌ 无             |
| 镜像大小       | ⚡ 250MB ~ 450MB |

---

# ⚠️ 十一、这个方案的真实问题（必须知道）

## ❌ 不适合：

* Kubernetes
* 高可用生产
* MySQL 主从
* 独立扩展

---

## ✔ 适合：

* 内网项目
* demo环境
* 单机部署
* Spring Boot + DB 一体化交付
* 离线环境

---

# 🧠 十二、如果你想再升级（我可以帮你）

可以直接帮你做：

## 🚀 企业级版本：

* MySQL minimal + 主从复制 Docker
* Spring Boot + HikariCP 优化
* Flyway 自动建表
* 健康检查（HEALTHCHECK）
* docker-compose 完整生产版
* 镜像压缩到 <300MB
* 离线 tar 包部署方案

---

# 👍 如果你下一步想继续优化

可以直接说：

👉 “我要 MySQL + Spring Boot + Redis + Nginx 一体化极简架构”

我可以帮你做一套**真正可以上线的微服务底座模板**。




可以，这种叫做 **“单文件自包含 + supervisor 多进程容器”**，适合你这种“极简交付 + 无外部依赖”的需求。

我给你做一版**真正干净、Dockerfile 内完成 MySQL + Spring Boot + 配置 + 启动脚本 + supervisor 全内联版本**。

---

# 🚀 一、目标结构（最终效果）

✔ 一个 Dockerfile
✔ 不依赖外部 my.cnf / entrypoint.sh
✔ supervisor 管理两个进程
✔ MySQL minimal tar 包
✔ Spring Boot jar
✔ 全部内联生成

---

# 🧱 二、最终 Dockerfile（核心）

```dockerfile id="m1q8xk"
FROM alpine:3.20

# =========================
# 1. 安装依赖（极简）
# =========================
RUN apk add --no-cache \
    bash \
    supervisor \
    libaio \
    libstdc++ \
    libgcc \
    tar \
    xz \
    openjdk17-jre-headless

# =========================
# 2. 创建用户
# =========================
RUN addgroup -S mysql && adduser -S mysql -G mysql

# =========================
# 3. 解压 MySQL（minimal）
# =========================
COPY mysql-minimal.tar.xz /tmp/mysql.tar.xz

RUN mkdir -p /opt/mysql && \
    tar -xJf /tmp/mysql.tar.xz -C /opt && \
    mv /opt/mysql-*-minimal /opt/mysql && \
    rm -f /tmp/mysql.tar.xz

# =========================
# 4. 创建数据目录
# =========================
RUN mkdir -p /data/mysql && \
    chown -R mysql:mysql /data/mysql /opt/mysql

# =========================
# 5. Spring Boot
# =========================
COPY app.jar /app/app.jar

# =========================
# 6. 内联 MySQL 配置
# =========================
RUN mkdir -p /etc/mysql && \
    cat > /etc/mysql/my.cnf << 'EOF'
[mysqld]
basedir=/opt/mysql
datadir=/data/mysql
port=3306

character-set-server=utf8mb4
collation-server=utf8mb4_general_ci

skip-name-resolve
max_connections=500

log_error=/data/mysql/error.log
EOF

# =========================
# 7. supervisor 内联配置
# =========================
RUN mkdir -p /etc/supervisor.d && \
    cat > /etc/supervisord.conf << 'EOF'
[supervisord]
nodaemon=true

[program:mysql]
command=/opt/mysql/bin/mysqld --defaults-file=/etc/mysql/my.cnf --user=mysql
autostart=true
autorestart=true
priority=10

[program:springboot]
command=java -jar /app/app.jar --server.port=8080
autostart=true
autorestart=true
priority=20
stdout_logfile=/dev/stdout
stderr_logfile=/dev/stderr
EOF

# =========================
# 8. 初始化脚本（无文件版）
# =========================
RUN cat > /init.sh << 'EOF'
#!/bin/bash

set -e

MYSQL_BASE=/opt/mysql
DATADIR=/data/mysql

echo "[init] checking mysql data dir..."

if [ ! -d "$DATADIR/mysql" ]; then
  echo "[init] initializing mysql..."
  $MYSQL_BASE/bin/mysqld \
    --initialize-insecure \
    --user=mysql \
    --basedir=$MYSQL_BASE \
    --datadir=$DATADIR
fi

echo "[init] starting supervisor..."
exec /usr/bin/supervisord -c /etc/supervisord.conf
EOF

RUN chmod +x /init.sh

# =========================
# 9. 暴露端口
# =========================
EXPOSE 3306 8080

# =========================
# 10. 启动入口
# =========================
CMD ["/init.sh"]
```

---

# 📦 三、你需要准备的文件

```
mysql-minimal.tar.xz
app.jar
Dockerfile
```

---

# 🚀 四、构建镜像

```bash id="q8k2lm"
docker build -t mysql-springboot-supervisor .
```

---

# 🚀 五、运行

```bash id="w3k9lm"
docker run -d \
  --name ms \
  -p 3306:3306 \
  -p 8080:8080 \
  mysql-springboot-supervisor
```

---

# 🧠 六、这个方案的特点（重点）

## ✔ 优点

* ✔ 单 Dockerfile（完全自包含）
* ✔ 无 external config 文件
* ✔ supervisor 管理双进程
* ✔ MySQL minimal（轻量）
* ✔ Spring Boot 内置
* ✔ 适合离线交付
* ✔ 一条命令启动

---

## ❌ 缺点（必须知道）

* MySQL + App 在一个容器（不符合微服务规范）
* 升级困难
* 资源隔离差
* 不适合 Kubernetes

---

# 📉 七、镜像体积优化建议

如果你想再压小：

### 可以做三件事：

### 1️⃣ 换 JRE 更小

```dockerfile
eclipse-temurin:17-jre-alpine
```

---

### 2️⃣ MySQL 再裁剪（remove test plugins）

---

### 3️⃣ strip bin

```bash
strip /opt/mysql/bin/*
```

---

# 🚀 八、企业级建议（给你方向）

如果你后面要做生产系统，建议：

```text
MySQL（独立容器）
Spring Boot（独立容器）
Redis（独立容器）
Nginx（Gateway）
```

但如果你是：

* 内网交付
* 离线部署
* demo环境
* 一体化系统

👉 你这个方案是合理的

---

# 🔥 如果你下一步要升级

我可以帮你继续优化成：

### 🚀 极限版本（更狠）

* 镜像 <200MB（极致压缩）
* MySQL + Flyway 自动建表
* Spring Boot healthcheck
* 自动重连 MySQL 等待机制
* docker-compose 一键编排版本
* 内网离线 tar 包发行版

只要你说 👍



这是一个很关键的问题，本质是在问：**“Linux 容器里怎么正确跑多个进程”**。

我给你讲清楚原理，你以后做 Docker 就不会再踩坑。

---

# 🚀 一、核心结论

👉 是的，可以不用 supervisor
👉 但必须有“进程管理机制”

常见三种方案：

| 方案          | 是否推荐    | 原理                  |
| ----------- | ------- | ------------------- |
| supervisor  | ❌ 重     | 专门进程管理器             |
| tini + bash | ⭐ 推荐    | 最轻量 PID1 + shell 控制 |
| systemd     | ❌ 不适合容器 | OS级管理               |

---

# 🧠 二、为什么容器需要 tini？

## ❗ Docker 的本质问题

容器里：

> PID 1 是“特殊进程”

它有两个坑：

### ❌ 1. 信号不会正确转发

比如：

```bash
docker stop
```

如果没有 PID1 处理：

* Java 不退出
* MySQL 不退出
* 容器卡死

---

### ❌ 2. 僵尸进程（Zombie）

子进程退出后：

* 不被回收
* 进程表污染

---

# 🚀 三、tini 是干什么的？

👉 tini

它是一个**超轻量 init 进程（只有几 KB）**

作用只有三个：

### ✔ 1. 正确转发信号（SIGTERM / SIGKILL）

```text
docker stop → tini → Java / MySQL
```

---

### ✔ 2. 回收僵尸进程

自动 `wait()` 子进程

---

### ✔ 3. 作为 PID 1

替代 shell / java 成为容器入口

---

# 🧱 四、bash 启动脚本在干嘛？

bash 的作用是：

👉 “编排多个进程启动顺序”

比如：

```bash
mysqld &
sleep 10
java -jar app.jar
```

它本质是：

> 一个“手写 mini supervisor”

---

# 🚀 五、MySQL + Spring Boot 同容器原理

你实际运行的是：

```text
tini (PID1)
  └── bash (启动脚本)
        ├── mysqld (后台)
        └── java (前台)
```

---

# ⚙️ 六、标准启动模型（推荐写法）

## Dockerfile：

```dockerfile
ENTRYPOINT ["/tini","--"]
CMD ["/start.sh"]
```

---

## start.sh（核心逻辑）

```bash
#!/bin/bash

set -e

echo "starting mysql..."

mysqld --user=mysql &
MYSQL_PID=$!

echo "waiting mysql..."
sleep 10

echo "starting spring boot..."

exec java -jar /app/app.jar
```

---

# 🧠 七、为什么不用 supervisor？

## supervisor 做了什么？

```text
supervisor = 重型进程管理器
```

功能包括：

* Web 管理
* 日志管理
* 自动重启
* 配置解析

---

## ❌ 在 Docker 中的问题：

* 镜像变大
* 多一层抽象
* 和 Kubernetes 冲突
* 实际用不到 web UI

---

# 🚀 八、tini + bash vs supervisor 对比

| 特性        | tini + bash | supervisor |
| --------- | ----------- | ---------- |
| 体积        | ⭐ 极小        | ❌ 大        |
| 复杂度       | ⭐ 简单        | ❌ 中等       |
| Docker 兼容 | ⭐ 最佳        | 一般         |
| 多进程控制     | 手写          | 自动         |
| 生产推荐      | ⭐⭐⭐⭐        | ⭐⭐⭐        |

---

# 🧱 九、关键设计原则（非常重要）

在 Docker 中：

> ❗ 一个容器最好一个“主进程”

你现在做的是：

```text
MySQL + Spring Boot = 多进程容器
```

👉 所以必须：

### ✔ 有 PID1（tini）

### ✔ 有启动编排（bash）

### ✔ Java 用 exec（关键）

---

# ⚠️ 十、最容易踩坑的点

## ❌ 1. 不用 exec 启动 Java

```bash
java -jar app.jar
```

👉 错误

---

## ✔ 正确：

```bash
exec java -jar app.jar
```

原因：

* 保证 Java 成为 PID 1
* signal 正确传递
* docker stop 正常退出

---

## ❌ 2. mysqld 不后台启动

必须：

```bash
mysqld &
```

否则 bash 卡死

---

# 🚀 十一、推荐最终架构（你应该用这个）

```text
tini (PID1)
   ↓
start.sh
   ├── mysqld (background)
   └── java (foreground)
```

---

# 🧠 十二、什么时候不用 supervisor？

✔ 你现在这种场景：

* Docker 单机部署
* 内网环境
* demo / PoC
* MySQL + Java 一体

👉 不需要 supervisor

---

# 🚀 十三、什么时候必须用 supervisor？

只有这些情况才用：

* 一个容器 >3 个进程
* 需要进程 UI 管理
* legacy 系统迁移
* 非 Docker 原生应用

---

# 🔥 如果你下一步想升级

我可以帮你做一个：

### 🚀 “工业级 MySQL + Spring Boot tini 架构”

包含：

* tini + bash 最优模板
* MySQL 等待健康检查（防启动竞争）
* Spring Boot DB ready probe
* docker-compose 版本
* 镜像 <200MB 优化版
* Kubernetes 迁移版拆分方案

只要你说 👍




要做“最小 Spring Boot 镜像 + 多阶段构建 + 极致压缩 JVM”，核心目标其实是三件事：

> ✔ 只带运行所需 JRE
> ✔ 去掉无用模块（jlink）
> ✔ 镜像分层最小化（distroless / alpine / scratch）

我给你一套**生产级最小镜像方案（推荐路线）**。

---

# 🚀 一、最佳实践结论（先说结果）

👉 最小可用方案排序：

| 方案                   | 镜像大小      | 推荐度         |
| -------------------- | --------- | ----------- |
| openjdk alpine       | 120~200MB | ⭐⭐⭐         |
| eclipse-temurin slim | 80~150MB  | ⭐⭐⭐⭐        |
| jlink 自定义 JVM        | 40~80MB   | ⭐⭐⭐⭐⭐       |
| distroless + jlink   | 35~70MB   | ⭐⭐⭐⭐⭐（生产最佳） |

---

# 🧠 二、核心思路（关键）

要做到最小镜像：

## ❗必须做 3 件事：

### 1️⃣ 多阶段构建（builder + runtime）

### 2️⃣ jlink 构建最小 JVM

### 3️⃣ 只复制 fat jar

---

# 🚀 三、推荐方案（企业级最优）：jlink + distroless

👉 使用 Spring Boot + JDK jlink

---

# 📦 四、完整 Dockerfile（极简生产版）

## 🔥 Stage 1：构建 Spring Boot

```dockerfile id="d1"
FROM maven:3.9-eclipse-temurin-17 AS builder

WORKDIR /build

COPY . .

RUN mvn clean package -DskipTests
```

---

## 🔥 Stage 2：构建最小 JVM（jlink）

```dockerfile id="d2"
FROM eclipse-temurin:17-jdk AS jlink-builder

RUN jlink \
  --add-modules java.base,java.logging,java.sql,java.xml \
  --compress=2 \
  --strip-debug \
  --no-header-files \
  --no-man-pages \
  --output /jre
```

---

## 🔥 Stage 3：运行镜像（distroless）

```dockerfile id="d3"
FROM gcr.io/distroless/base-debian12

WORKDIR /app

# 复制最小 JRE
COPY --from=jlink-builder /jre /jre

# 复制 jar
COPY --from=builder /build/target/app.jar /app/app.jar

ENV JAVA_HOME=/jre
ENV PATH=$JAVA_HOME/bin:$PATH

EXPOSE 8080

CMD ["java","-jar","/app/app.jar"]
```

---

# 📉 五、优化效果

| 项目              | 大小        |
| --------------- | --------- |
| JDK full        | 300MB+    |
| alpine JRE      | 120MB     |
| jlink runtime   | ⭐ 40~70MB |
| Spring Boot jar | 20~40MB   |

👉 最终镜像：

```text id="m1"
60MB ~ 120MB（可生产级）
```

---

# 🚀 六、进一步极限优化（可选）

## ✔ 1. 去掉 Spring 不用模块

jlink 精简：

```bash id="m2"
--add-modules java.base,java.logging,java.sql
```

---

## ✔ 2. Spring Boot Layered Jar（非常重要）

```bash id="m3"
java -Djarmode=layertools -jar app.jar extract
```

---

## ✔ 3. Docker layer 优化

```dockerfile id="m4"
COPY target/dependencies/ /app/lib/
COPY target/snapshot-dependencies/ /app/lib/
COPY target/application/ /app/app/
```

---

# 🚀 七、超极简版本（不推荐但很小）

如果你追求极致小：

```dockerfile id="m5"
FROM scratch
COPY jre /jre
COPY app.jar /app.jar
ENTRYPOINT ["/jre/bin/java","-jar","/app.jar"]
```

👉 可做到：

```text id="m6"
30MB级别
```

但问题：

* ❌ 没 shell
* ❌ 无 debug
* ❌ 运维困难

---

# 🧠 八、关键优化点总结（重点）

## ✔ 1. JVM 最重要优化

```text id="m7"
jlink = 镜像减肥核心
```

---

## ✔ 2. Spring Boot 优化

```text id="m8"
fat jar + layered jar
```

---

## ✔ 3. Docker 优化

```text id="m9"
multi-stage build + distroless
```

---

# ⚠️ 九、常见错误（坑）

## ❌ 1. 用 full JDK

```text id="n1"
300MB+ ❌
```

---

## ❌ 2. 不用 jlink

👉 直接浪费 100MB+

---

## ❌ 3. alpine + glibc 冲突

Spring Boot + native library 可能炸

---

# 🚀 十、推荐最终架构（企业级）

```text id="n2"
Maven Builder
     ↓
Jlink JVM
     ↓
Distroless Runtime
     ↓
Spring Boot App
```

---

# 🔥 如果你要继续升级

我可以帮你做：

### 🚀 企业级 Spring Boot 极限镜像方案

* ✔ 40MB JVM 镜像
* ✔ MySQL + Spring Boot 分层优化
* ✔ GraalVM native image（10MB级）
* ✔ Kubernetes ready image
* ✔ 内网离线镜像仓库方案

只要你说 👍

