# 运行容器
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