在 Docker 里**不推荐使用 supervisord 管理多个进程**，尤其是你现在这种 **MySQL + SpringBoot 同容器** 场景。supervisord 会增加一层进程管理，镜像也会变重。

如果必须在一个容器里运行多个进程，更轻量的方式有几种。

---

## 方案1（推荐）：自定义 entrypoint.sh + bash 后台进程 + exec

这是最轻量、最常见方式。

目录：

```text
.
├── Dockerfile
└── entrypoint.sh
```

---

### Dockerfile

```dockerfile
FROM debian:bookworm-slim

COPY entrypoint.sh /entrypoint.sh

RUN chmod +x /entrypoint.sh

ENTRYPOINT ["/entrypoint.sh"]
```

---

### entrypoint.sh

```bash
#!/bin/bash
set -e

MYSQL_BASE=/opt/mysql
DATADIR=/data/mysql

echo "[init] starting mysql..."

$MYSQL_BASE/bin/mysqld \
    --defaults-file=/etc/mysql/my.cnf \
    --user=mysql &

MYSQL_PID=$!

echo "[init] mysql pid=${MYSQL_PID}"


echo "[init] starting springboot..."

java -jar /app/app.jar \
    --server.port=8080 &

APP_PID=$!

echo "[init] springboot pid=${APP_PID}"


# 捕获退出信号
trap "echo stopping...; kill $MYSQL_PID $APP_PID" SIGTERM SIGINT


# 等待任意进程退出
wait -n


echo "[exit] process stopped"

kill $MYSQL_PID $APP_PID 2>/dev/null || true

exit 1
```

---

## 优点

✅ 零额外依赖
✅ 镜像最小
✅ Docker 原生支持
✅ 可以捕获 SIGTERM
✅ 支持优雅关闭

---

# 方案2：使用 tini（强烈推荐）

Docker 默认 PID 1 有一个问题：

* 僵尸进程不会自动回收
* 信号处理不好

安装：

```dockerfile
RUN apt-get update && \
    apt-get install -y tini
```

然后：

```dockerfile
ENTRYPOINT ["/usr/bin/tini","--","/entrypoint.sh"]
```

结构：

```
tini(PID 1)
 |
 └── entrypoint.sh
       |
       ├── mysqld
       |
       └── java
```

这是很多官方镜像采用方式。

---

# 方案3：使用 bash job control（简单版）

例如：

```bash
#!/bin/bash

mysqld &

java -jar app.jar &

wait
```

但是：

❌ 不处理退出
❌ 不处理信号
❌ PID 1 问题

不建议生产。

---

# 方案4：拆成两个容器（最佳实践）

你的场景：

```
docker-compose
        |
        |
  +-------------+
  | mysql       |
  +-------------+

  +-------------+
  | springboot  |
  +-------------+
```

例如：

```yaml
services:

  mysql:
    image: mysql-custom
    volumes:
      - mysql-data:/data/mysql

  app:
    image: springboot-app
    depends_on:
      - mysql
```

优点：

* 独立扩容
* 独立升级
* 独立健康检查
* Kubernetes 天然支持

---

# 结合你当前 MySQL 9.7 + SpringBoot 镜像

如果你坚持单容器，我建议：

```
container
│
├── tini
│
└── entrypoint.sh
      │
      ├── 初始化 MySQL
      │
      ├── mysqld &
      │
      ├── java -jar app.jar &
      │
      └── wait -n
```

不要：

```
container
 |
 supervisord
 |
 ├── mysqld
 └── java
```

---

## 推荐 Dockerfile 最终结构

```dockerfile
FROM debian:bookworm-slim

RUN apt-get update && \
    apt-get install -y --no-install-recommends tini && \
    rm -rf /var/lib/apt/lists/*

COPY entrypoint.sh /entrypoint.sh

RUN chmod +x /entrypoint.sh

ENTRYPOINT ["/usr/bin/tini","--"]

CMD ["/entrypoint.sh"]
```

这个方案比 supervisord：

* 镜像减少几十 MB
* 进程树更干净
* Docker/Kubernetes 更友好

对于你前面设计的 **MySQL 9.7 binary + SpringBoot 单镜像**，这个方案更合适。





你的场景是：

```
MySQL 9.7 binary
+
SpringBoot jar1
+
SpringBoot jar2
```

全部放在**一个 Docker 容器**中运行，不使用 supervisord，希望轻量化。

推荐结构：

```
container(PID 1)
│
├── tini
│
└── entrypoint.sh
      │
      ├── mysqld
      │
      ├── app1.jar
      │
      └── app2.jar
```

---

## 1. 推荐目录结构

例如：

```text
/
├── opt
│   └── mysql
│       ├── bin
│       │   └── mysqld
│       └── ...
│
├── data
│   └── mysql
│
├── app
│   ├── app1.jar
│   └── app2.jar
│
├── etc
│   └── mysql
│       └── my.cnf
│
└── entrypoint.sh
```

---

# 2. Dockerfile

```dockerfile
FROM debian:bookworm-slim

RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        tini \
        ca-certificates \
    && rm -rf /var/lib/apt/lists/*


COPY mysql-binary /opt/mysql

COPY app1.jar /app/app1.jar
COPY app2.jar /app/app2.jar

COPY entrypoint.sh /entrypoint.sh

RUN chmod +x /entrypoint.sh

ENTRYPOINT ["/usr/bin/tini","--"]

CMD ["/entrypoint.sh"]
```

---

# 3. entrypoint.sh

生产建议：

```bash
#!/bin/bash

set -e

MYSQL_HOME=/opt/mysql
MYSQL_DATA=/data/mysql


echo "[init] checking mysql..."

if [ ! -d "$MYSQL_DATA/mysql" ]; then

    echo "[init] initializing mysql..."

    $MYSQL_HOME/bin/mysqld \
        --initialize-insecure \
        --user=mysql \
        --basedir=$MYSQL_HOME \
        --datadir=$MYSQL_DATA

fi


echo "[start] mysql..."

$MYSQL_HOME/bin/mysqld \
    --defaults-file=/etc/mysql/my.cnf \
    --user=mysql &

MYSQL_PID=$!


echo "[start] app1..."

java \
 -jar /app/app1.jar \
 --server.port=8080 &

APP1_PID=$!


echo "[start] app2..."

java \
 -jar /app/app2.jar \
 --server.port=8081 &

APP2_PID=$!


echo "
mysql=$MYSQL_PID
app1=$APP1_PID
app2=$APP2_PID
"


# 优雅退出
trap '
echo "[stop] shutting down..."

kill -TERM $APP1_PID 2>/dev/null || true
kill -TERM $APP2_PID 2>/dev/null || true

mysqladmin \
 --socket=/tmp/mysql.sock \
 -uroot \
 shutdown 2>/dev/null || true

' SIGTERM SIGINT


# 任意一个退出，整个容器退出
wait -n \
    $MYSQL_PID \
    $APP1_PID \
    $APP2_PID


echo "[exit] process stopped"

exit 1
```

---

# 4. 推荐增加健康检查

Dockerfile：

```dockerfile
HEALTHCHECK \
    --interval=30s \
    --timeout=5s \
    --retries=3 \
CMD \
curl -f http://localhost:8080/actuator/health || exit 1
```

---

# 5. MySQL 配置建议

`my.cnf`

```ini
[mysqld]

basedir=/opt/mysql
datadir=/data/mysql

port=3306

socket=/tmp/mysql.sock

character-set-server=utf8mb4
collation-server=utf8mb4_general_ci

skip-name-resolve

max_connections=500

log_error=/data/mysql/error.log
pid-file=/data/mysql/mysql.pid
```

---

# 6. 两个 SpringBoot JVM 参数建议

不要共用默认 JVM 参数。

例如：

app1：

```bash
java \
-Xms512m \
-Xmx1024m \
-jar /app/app1.jar
```

app2：

```bash
java \
-Xms512m \
-Xmx1024m \
-jar /app/app2.jar
```

---

# 7. 重要提醒：单容器资源隔离

这种模式：

```
一个容器
 |
 +-- MySQL
 |
 +-- JVM1
 |
 +-- JVM2
```

需要注意：

| 项目  | 建议           |
| --- | ------------ |
| CPU | Docker limit |
| 内存  | JVM -Xmx 固定  |
| 日志  | stdout       |
| PID | tini         |
| 停止  | SIGTERM      |

例如：

```bash
docker run \
--memory=6g \
--cpus=4 \
mysql-app
```

---

## 如果你的目标是做“集成部署包”（类似传统 Tomcat + MySQL 一体机），这个方案比较合适。

如果是 Kubernetes 生产环境，建议拆成：

```
MySQL StatefulSet

SpringBoot app1 Deployment

SpringBoot app2 Deployment
```

但对于**离线交付、一键部署、边缘环境、客户现场安装包**，你这个 MySQL binary + 两个 jar + tini 的方式是合理的。




你这个需求在 Dockerfile 里用 `printf` 写入脚本时，主要难点是：

1. **脚本中的 `$变量` 必须保留到容器运行时，所以要写成 `\$变量`**
2. **脚本中的 `\` 换行符要输出，所以 Dockerfile 中要写 `\\`**
3. **`trap '...'` 里的单引号不要和 Dockerfile 的字符串引号冲突**

下面这个版本可以直接放进 Dockerfile，不会触发 Dockerfile parser 语法错误。

```dockerfile
RUN set -eux; \
    mkdir -p /runtime/init; \
    printf '%s\n' \
'echo "[start] mysql..."' \
'' \
'\$MYSQL_HOME/bin/mysqld \\' \
'    --defaults-file=/etc/mysql/my.cnf \\' \
'    --user=mysql &' \
'' \
'MYSQL_PID=\$!' \
'' \
'echo "[start] app1..."' \
'' \
'java \\' \
' -jar /app/app1.jar \\' \
' --server.port=8080 &' \
'' \
'APP1_PID=\$!' \
'' \
'echo "[start] app2..."' \
'' \
'java \\' \
' -jar /app/app2.jar \\' \
' --server.port=8081 &' \
'' \
'APP2_PID=\$!' \
'' \
'echo "mysql=\$MYSQL_PID"' \
'echo "app1=\$APP1_PID"' \
'echo "app2=\$APP2_PID"' \
'' \
'trap '\'' \
'echo "[stop] shutting down..."' \
'' \
'kill -TERM \$APP1_PID 2>/dev/null || true' \
'kill -TERM \$APP2_PID 2>/dev/null || true' \
'' \
'mysqladmin \\' \
' --socket=/tmp/mysql.sock \\' \
' -uroot \\' \
' shutdown 2>/dev/null || true' \
'\'' SIGTERM SIGINT' \
'' \
'wait -n \\' \
'    \$MYSQL_PID \\' \
'    \$APP1_PID \\' \
'    \$APP2_PID' \
'' \
'echo "[exit] process stopped"' \
'' \
'exit 1' \
> /runtime/init/start.sh; \
chmod +x /runtime/init/start.sh
```

---

生成后的 `/runtime/init/start.sh` 内容等价于：

```bash
echo "[start] mysql..."

$MYSQL_HOME/bin/mysqld \
    --defaults-file=/etc/mysql/my.cnf \
    --user=mysql &

MYSQL_PID=$!


echo "[start] app1..."

java \
 -jar /app/app1.jar \
 --server.port=8080 &

APP1_PID=$!


echo "[start] app2..."

java \
 -jar /app/app2.jar \
 --server.port=8081 &

APP2_PID=$!


echo "mysql=$MYSQL_PID"
echo "app1=$APP1_PID"
echo "app2=$APP2_PID"


trap '
echo "[stop] shutting down..."

kill -TERM $APP1_PID 2>/dev/null || true
kill -TERM $APP2_PID 2>/dev/null || true

mysqladmin \
 --socket=/tmp/mysql.sock \
 -uroot \
 shutdown 2>/dev/null || true

' SIGTERM SIGINT


wait -n \
    $MYSQL_PID \
    $APP1_PID \
    $APP2_PID


echo "[exit] process stopped"

exit 1
```

---

## 建议再加一行 shebang

你当前片段缺少：

```bash
#!/bin/bash
```

否则：

```dockerfile
ENTRYPOINT ["/runtime/init/start.sh"]
```

可能出现：

```
exec format error
```

所以最前面应该加：

```dockerfile
printf '%s\n' \
'#!/bin/bash' \
'set -e' \
...
```

---

## 如果使用 Debian slim

还建议安装：

```dockerfile
RUN apt-get update && apt-get install -y --no-install-recommends \
    bash \
    tini \
    procps \
    mysql-client
```

原因：

* `bash`：执行脚本
* `tini`：PID 1 信号处理
* `procps`：调试进程
* `mysql-client`：提供 `mysqladmin`

这样你的：

```
tini
 |
 start.sh
 |
 +-- mysqld
 +-- java app1
 +-- java app2
```

结构就比较稳定。
