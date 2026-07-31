`docker buildx build` 是 Docker BuildKit 提供的新一代构建命令，比传统 `docker build` 强很多，尤其适合：

* 多架构构建（amd64/arm64）
* CI/CD（GitHub Actions）
* 导出镜像文件
* 导出构建产物到本地
* 不推送镜像，只生成 tar/目录
* 高级缓存

你现在的场景（Dockerfile 构建 JRE + MySQL binary + Spring Boot 应用），非常适合使用。

---

# 1. 基本语法

```bash
docker buildx build [OPTIONS] PATH
```

例如：

```bash
docker buildx build \
-t my-image:v1 \
.
```

等价于：

```bash
docker build -t my-image:v1 .
```

---

# 2. 常用参数详解

---

## 2.1 指定镜像名称

参数：

```bash
-t
```

或者：

```bash
--tag
```

例如：

```bash
docker buildx build \
-t xxl-job-runtime:1.0 \
.
```

生成：

```text
xxl-job-runtime:1.0
```

---

# 2.2 指定 Dockerfile

默认：

```text
./Dockerfile
```

指定：

```bash
-f
```

例如：

```bash
docker buildx build \
-f Dockerfile-supervisor \
-t xxl-job:latest \
.
```

你的场景：

```bash
docker buildx build \
-f Dockerfile-supervisor \
-t xxl-job-h2:3.4.2 \
.
```

---

# 2.3 不使用缓存

你之前问过 Github Actions 卡缓存。

参数：

```bash
--no-cache
```

例如：

```bash
docker buildx build \
--no-cache \
-t app:v1 .
```

---

# 2.4 使用缓存

默认：

```bash
cache
```

导出缓存：

```bash
--cache-to
```

例如：

```bash
docker buildx build \
--cache-to type=local,dest=.docker-cache \
.
```

下次：

```bash
docker buildx build \
--cache-from type=local,src=.docker-cache \
.
```

GitHub Actions 很常用。

---

# 2.5 构建平台

例如：

AMD64：

```bash
--platform linux/amd64
```

ARM：

```bash
--platform linux/arm64
```

多架构：

```bash
docker buildx build \
--platform linux/amd64,linux/arm64 \
-t app:v1 .
```

---

# 2.6 推送镜像

默认：

buildx 不一定加载到本地 Docker。

推送：

```bash
--push
```

例如：

```bash
docker buildx build \
--platform linux/amd64 \
-t registry.example.com/app:v1 \
--push .
```

---

# 2.7 加载到本地 Docker

buildx 默认：

```text
只构建，不进入 docker images
```

需要：

```bash
--load
```

例如：

```bash
docker buildx build \
-t app:v1 \
--load \
.
```

之后：

```bash
docker images
```

可以看到。

---

# 3. 重点：导出资源到本地

这是 buildx 最大优势。

---

# 方法1：导出目录（推荐）

假设 Dockerfile：

```dockerfile
FROM alpine

RUN mkdir /runtime

COPY test.txt /runtime/
```

执行：

```bash
docker buildx build \
--output type=local,dest=./output \
.
```

结果：

```text
output/
└── runtime
    └── test.txt
```

---

## 你的场景

Dockerfile：

```dockerfile
FROM xxx AS runtime

COPY --from=jlink-builder /runtime /runtime
```

导出：

```bash
docker buildx build \
-f Dockerfile-supervisor \
--target runtime \
--output type=local,dest=./runtime-output \
.
```

得到：

```text
runtime-output/

├── jre
├── mysql-binary
├── apps
└── lib
```

---

# 4. 导出成 tar.gz 压缩包

你想：

> 打包压缩资源到本地

推荐：

## 第一步：buildx 输出 tar

```bash
docker buildx build \
--output type=tar,dest=runtime.tar \
.
```

生成：

```text
runtime.tar
```

---

## 第二步压缩

Linux：

```bash
gzip runtime.tar
```

得到：

```text
runtime.tar.gz
```

恢复：

```bash
tar -xzf runtime.tar.gz
```

---

# 5. 导出镜像 tar（完整镜像）

如果你想保存整个 Docker 镜像：

使用：

```bash
--output type=docker
```

例如：

```bash
docker buildx build \
-t xxl-job:v1 \
--output type=docker \
-o xxl-job.tar \
.
```

然后：

```bash
docker load -i xxl-job.tar
```

查看：

```bash
docker images
```

---

# 6. type=docker 和 type=oci区别

## docker

```bash
type=docker
```

生成：

```text
docker image tar
```

可以：

```bash
docker load
```

适合：

* 离线部署
* 内网服务器

---

## oci

```bash
type=oci
```

生成：

```text
OCI image layout
```

适合：

* Kubernetes
* containerd

---

# 7. 多阶段构建导出（你的场景最佳）

你的 Dockerfile：

```dockerfile
FROM eclipse-temurin:25 AS jdk

RUN jlink ...


FROM debian:12 AS runtime

COPY --from=jdk /runtime/jre /runtime/jre

COPY apps /runtime/apps


FROM scratch AS export

COPY --from=runtime /runtime /runtime
```

然后：

导出运行资源：

```bash
docker buildx build \
--target export \
--output type=local,dest=./runtime \
.
```

结果：

```text
runtime/

└── runtime
    ├── jre
    ├── apps
    └── mysql-binary
```

---

# 8. GitHub Actions推荐写法

你的场景：

```yaml
- name: Build runtime
  run: |
    docker buildx build \
      --file Dockerfile-supervisor \
      --target export \
      --output type=local,dest=./runtime \
      .
```

压缩：

```yaml
- name: Compress
  run: |
    tar -czf xxl-job-runtime.tar.gz runtime
```

上传：

```yaml
- uses: actions/upload-artifact@v4
  with:
    name: xxl-job-runtime
    path: xxl-job-runtime.tar.gz
```

---

# 9. 你的项目推荐流程

结合你现在：

```
Dockerfile-supervisor

        |
        |
     buildx
        |
        |
   export stage
        |
        |
runtime.tar.gz

包含：

runtime/
├── jre
├── mysql-binary
├── apps
├── supervisor
└── lib
```

部署服务器：

```bash
tar -xzf runtime.tar.gz -C /
```

或者：

```bash
docker load < xxl-job-image.tar
```

---

## 总结常用命令

| 需求    | 命令                                   |
| ----- | ------------------------------------ |
| 普通构建  | `docker buildx build -t app:v1 .`    |
| 不缓存   | `--no-cache`                         |
| 加载本地  | `--load`                             |
| 推送仓库  | `--push`                             |
| 导出目录  | `--output type=local,dest=目录`        |
| 导出tar | `--output type=tar,dest=a.tar`       |
| 导出镜像  | `--output type=docker,dest=a.tar`    |
| 多架构   | `--platform linux/amd64,linux/arm64` |

对于你当前 **GitHub Actions + Dockerfile-supervisor + jlink + MySQL binary + Spring Boot**，建议采用：

```
buildx build
    |
    +-- target runtime-export
    |
    +-- output type=local
    |
    +-- tar.gz
    |
    +-- upload artifact
```

比保存整个 Docker image 更适合离线部署。

	   
	   
导出单个镜像: docker save mysql:9.7 | gzip > mysql-9.7.tar.gz 恢复：gunzip -c mysql-9.7.tar.gz | docker load 或者：zcat mysql-9.7.tar.gz | docker load
pigz 是 gzip 的并行版本 apt install pigz 或者 yum install pigz: 
		导出 ：docker save mysql:9.7 | pigz -9 > mysql-9.7.tar.gz   恢复：pigz -dc mysql-9.7.tar.gz | docker load
		| 参数 | 说明   |
		| -- | ---- |
		| -1 | 最快   |
		| -6 | 默认   |
		| -9 | 最大压缩 |
	通常性能最好： docker save big-image:latest | pigz -6 > image.tar.gz
zstd 压缩（现在推荐）apt install zstd： 
		导出： docker save mysql:9.7 | zstd -T0 -19 -o mysql-9.7.tar.zst  恢复： zstd -dc mysql-9.7.tar.zst | docker load
		| 参数  | 含义       |
		| --- | -------- |
		| -T0 | 使用全部 CPU |
		| -19 | 压缩等级     |
		| -3  | 快速压缩     |
	例如生产备份： docker save app:v1 | zstd -T0 -10 > app-v1.tar.zst
xz 压缩（最高压缩率）： docker save mysql:9.7 | xz -T0 -9 > mysql.tar.xz  恢复： xz -dc mysql.tar.xz | docker load
导出多个镜像一起压缩： docker save mysql:9.7 redis:7 nginx:1.29 | pigz -9 > base-images.tar.gz 恢复：pigz -dc base-images.tar.gz | docker load
指定所有镜像导出，如果有大量 dangling image：先清理 docker image prune 例如导出本机所有镜像： docker save $(docker images -q) | pigz -9 > all-images.tar.gz
不压缩：
docker save -o my-platform-images.tar mysql:9.7 my-app:1.0 my-gateway:1.0 恢复 ： docker load -i /tmp/my-platform-images.tar

docker save -o mysql-9.7.tar mysql:9.7 或 docker save mysql:9.7 > mysql-9.7.tar
docker load -i file.tar 或  docker load < file.tar

导出容器
docker export -o my-container.tar my-container  或 docker export my-container > my-container.tar
import 时可以补充元数据
docker import \
--change 'CMD ["java","-jar","app.jar"]' \
--change 'ENV JAVA_HOME=/opt/java' \
--change 'EXPOSE 8080' \
container.tar \
myapp:v1


| 策略               | 说明               |
| ---------------- | ---------------- |
| `no`             | 不自动重启（默认）        |
| `always`         | 无论退出原因，都自动重启     |
| `unless-stopped` | 除非手动 stop，否则自动重启 |
| `on-failure`     | 只有异常退出才重启        |
| `on-failure:N`   | 最多重启 N 次         |

运行：docker run  --restart=unless-stopped -dit --memory=4g --cpus=1 -e ROOT_PASSWORD='Xiehaijun888' -e TZ=Asia/Shanghai -p 14336:3306 -p 18880:8080 --name xxl-job-service xxl-job-h2:latest
查看日志 docker logs -f xxl-job-service

docker run --rm -it --entrypoint /bin/bash xxl-job-h2:latest 【docker run --rm -it debian:12-slim bash】

docker run -d \
 --name mysql-stack \
 --restart=unless-stopped \
 -p 3306:3306 \
 -p 8080:8080 \
 -p 8081:8081 \
 -v mysql-data:/runtime/mysql-data \
 your-image
 
 docker run --rm -it \
 --entrypoint /bin/bash \
 your-image
 如果镜像没有 bash
 docker run --rm -it \
 --entrypoint /bin/sh \
 your-image
 
 已存在容器修改 restart 策略
 docker update \
 --restart=unless-stopped \
 container_name
 查看：
 docker inspect container_name \
 | grep RestartPolicy -A 3
 
 
 
 # Docker关闭NUMA
innodb_numa_interleave=OFF


# 容器环境建议
innodb_buffer_pool_size=1G

innodb_flush_method=O_DIRECT
container_aware=ON

# 生产环境不建议 --privileged。
 --cap-add SYS_NICE \
 --cap-add SYS_RESOURCE \
 innodb_numa_interleave=ON
 
# 自动感知资源
 --memory=8g \
 --cpus=4 \
 配置 container_aware=ON
 
 
 1. 挂载目录（可读写）格式：-v 宿主机目录:容器目录
目录读写：默认 rw
文件只读：添加 :ro
目录只读：添加 :ro
docker run -d \
  -v /data/mysql:/runtime/mysql-data \
  -v /etc/mysql:/etc/mysql:ro \
  -v /opt/config/my.cnf:/etc/mysql/my.cnf:ro \
  --mount type=bind,source=/data/mysql,target=/runtime/mysql-data \
  --mount type=bind,source=/opt/config/my.cnf,target=/etc/mysql/my.cnf,readonly \
  mysql-image
6. 查看挂载是否成功： docker inspect mysql-platform

sudo docker run --rm -it -v "$(pwd)/init.sh:/runtime/mysql-binary/init.sh:ro" --entrypoint /bin/bash xxl-job-h2:latest
docker run  --restart=unless-stopped -dit --memory=4g --cpus=1 \
-v "$(pwd)/init.sh:/runtime/mysql-binary/init.sh:ro" \
-v "$(pwd)/my.cnf:/runtime/mysql-binary/etc/my.cnf:ro" \
-e ROOT_PASSWORD='Xiehaijun888' -e TZ=Asia/Shanghai \
-p 14336:3306 -p 18880:8080 --name xxl-job-service xxl-job-h2:latest



sudo docker run  --restart=unless-stopped -dit --memory=4g --cpus=1 -v "$(pwd)/init.sh:/runtime/mysql-binary/init.sh:ro" -v "$(pwd)/my.cnf:/runtime/mysql-binary/etc/my.cnf:ro" -e ROOT_PASSWORD='Xiehaijun888' -e TZ=Asia/Shanghai -p 14336:3306 -p 18880:8080 --name xxl-job-service xxl-job-h2:latest
sudo docker run  --restart=unless-stopped -dit --memory=4g --cpus=1 --cap-add SYS_NICE --cap-add SYS_RESOURCE -e ROOT_PASSWORD='Xiehaijun888' -e TZ=Asia/Shanghai -p 14336:3306 -p 18880:8080 --name xxl-job-service xxl-job-h2:latest

验证生成的JRE
查看模块
/runtime/jre/bin/java --list-modules
方案1（推荐）：jlink 生成标准完整 JRE
RUN set -eux; \
    /opt/jdk/bin/jlink \
    --module-path /opt/jdk/jmods \
    --add-modules java.se \
    --strip-debug \
    --no-man-pages \
    --no-header-files \
    --compress=zip-6 \
    --output /runtime/jre

	
方案2：完全等价 JDK 发布版 JRE
RUN /opt/jdk/bin/jlink \
    --module-path /opt/jdk/jmods \
    --add-modules ALL-MODULE-PATH \
    --strip-debug \
    --no-man-pages \
    --no-header-files \
    --compress=zip-6 \
    --output /runtime/jre
	
验证 MySQL 9.7 支持哪些参数
/runtime/mysql-binary/bin/mysqld \
--verbose \
--help | grep skip



sudo docker run --rm -it -v "$(pwd)/init.sh:/runtime/mysql-binary/init.sh:ro" -v "$(pwd)/my.cnf:/runtime/mysql-binary/etc/my.cnf:ro" --entrypoint /bin/bash xxl-job-h2:latest

