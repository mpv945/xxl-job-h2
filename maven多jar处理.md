在 GitHub Actions 中建议放到 `run` 多行脚本里，不要直接写在 YAML 字段中。你的命令需要注意：

1. `$(...)` 是 shell 命令替换。
2. `while read` 建议使用 `IFS= read -r`，避免路径包含特殊字符。
3. 找到后保存到环境变量，后续 Docker step 可以复用。

示例：

```yaml
- name: Find Spring Boot executable jar
  shell: bash
  run: |
    APP_JAR=$(find . -name "*.jar" \
      ! -name "*sources.jar" \
      ! -name "*javadoc.jar" \
      | while IFS= read -r jar
        do
          if jar tf "$jar" | grep -q "BOOT-INF"; then
            echo "$jar"
            break
          fi
        done)

    echo "Found application jar:"
    echo "$APP_JAR"

    if [ -z "$APP_JAR" ]; then
      echo "ERROR: executable Spring Boot jar not found"
      exit 1
    fi

    cp "$APP_JAR" ./docker/app.jar
```

执行后：

```text
docker/
└── app.jar
```

后续 Docker build：

```yaml
- name: Build Docker image
  run: |
    docker build \
      -t xxl-job-admin:${{ github.sha }} \
      .
```

Dockerfile：

```dockerfile
COPY docker/app.jar /app/app.jar

ENTRYPOINT [
    "java",
    "-jar",
    "/app/app.jar"
]
```

---

## 如果需要跨 GitHub Actions step 使用变量

例如后面还要打印：

```yaml
- name: Find jar
  shell: bash
  run: |
    APP_JAR=$(find . -name "*.jar" \
      ! -name "*sources.jar" \
      ! -name "*javadoc.jar" \
      | while IFS= read -r jar
        do
          if jar tf "$jar" | grep -q "BOOT-INF"; then
            echo "$jar"
            break
          fi
        done)

    echo "APP_JAR=$APP_JAR" >> "$GITHUB_ENV"
```

后面：

```yaml
- name: Show jar
  run: |
    echo "jar=$APP_JAR"
```

---

## 针对你的 xxl-job 场景，可以进一步简化

你的构建：

```bash
mvn \
-pl xxl-job/xxl-job-admin \
-am \
clean package \
-DskipTests
```

生成：

```text
xxl-job/xxl-job-admin/target/
├── xxl-job-admin-3.4.2.jar          ✅
├── xxl-job-admin-3.4.2-sources.jar  ❌
└── xxl-job-admin-3.4.2-javadoc.jar  ❌
```

其实可以：

```yaml
- name: Prepare docker jar
  run: |
    mkdir -p docker

    APP_JAR=$(find xxl-job/xxl-job-admin/target \
      -maxdepth 1 \
      -name "*.jar" \
      ! -name "*sources.jar" \
      ! -name "*javadoc.jar")

    cp "$APP_JAR" docker/app.jar
```

但是使用 `BOOT-INF` 检测更通用，适合未来：

* 多模块
* 多 Spring Boot 服务
* jar 名称变化
* Maven plugin 调整

生产 CI 推荐保留 `BOOT-INF` 判断。




你需要的是：

1. `find .` **限制最大遍历深度 3 层**
2. 找到多个 Spring Boot 可执行 jar（`BOOT-INF`）
3. 按顺序复制到：

    * `./docker/app1/xxx.jar`
    * `./docker/app2/xxx.jar`
4. 保留原始 jar 文件名

GitHub Actions 推荐这样写：

```yaml
- name: Prepare application jars
  shell: bash
  run: |
    set -euo pipefail

    mkdir -p docker/app1 docker/app2

    index=1

    find . -maxdepth 3 -type f -name "*.jar" \
      ! -name "*-sources.jar" \
      ! -name "*-javadoc.jar" \
      | while IFS= read -r jar
    do
      if jar tf "$jar" | grep -q "^BOOT-INF/"; then

        filename=$(basename "$jar")

        echo "Found Spring Boot jar: $jar"

        if [ "$index" -eq 1 ]; then
          cp "$jar" "./docker/app1/$filename"
        elif [ "$index" -eq 2 ]; then
          cp "$jar" "./docker/app2/$filename"
        else
          echo "More than 2 application jars found, skip: $jar"
          continue
        fi

        echo "Copied: ./docker/app$index/$filename"

        index=$((index+1))
      fi
    done


    if [ ! -f docker/app1/*.jar ]; then
      echo "ERROR: app1 jar not found"
      exit 1
    fi

    if [ ! -f docker/app2/*.jar ]; then
      echo "ERROR: app2 jar not found"
      exit 1
    fi
```

---

执行后例如：

目录：

```text
.
├── xxl-job
│   └── xxl-job-admin
│       └── target
│           └── xxl-job-admin-3.4.2.jar
│
├── user-service
│   └── target
│       └── user-service-1.0.jar
```

找到：

```text
xxl-job/xxl-job-admin/target/xxl-job-admin-3.4.2.jar
user-service/target/user-service-1.0.jar
```

复制：

```text
docker/
├── app1/
│   └── xxl-job-admin-3.4.2.jar
│
└── app2/
    └── user-service-1.0.jar
```

---

## 更严谨版本（推荐生产）

避免 `find` 顺序不固定，可以排序：

```yaml
- name: Prepare application jars
  shell: bash
  run: |
    set -euo pipefail

    mkdir -p docker/app1 docker/app2

    mapfile -t jars < <(
      find . -maxdepth 3 -type f -name "*.jar" \
      ! -name "*-sources.jar" \
      ! -name "*-javadoc.jar" \
      | sort
    )

    apps=()

    for jar in "${jars[@]}"; do
      if jar tf "$jar" | grep -q "^BOOT-INF/"; then
        apps+=("$jar")
      fi
    done


    if [ "${#apps[@]}" -lt 2 ]; then
      echo "Need at least 2 Spring Boot jars"
      exit 1
    fi


    cp "${apps[0]}" docker/app1/$(basename "${apps[0]}")
    cp "${apps[1]}" docker/app2/$(basename "${apps[1]}")

    echo "app1=${apps[0]}"
    echo "app2=${apps[1]}"
```

这个更适合 CI，因为：

* 不受 `find` 输出顺序影响
* 可以扩展 app3/app4
* 出错更明确

---

如果后续 Dockerfile 是：

```dockerfile
COPY docker/app1/*.jar /app/app1.jar
COPY docker/app2/*.jar /app/app2.jar
```

那么版本号变化：

```
xxl-job-admin-3.4.2.jar
xxl-job-admin-3.5.0.jar
```

都不影响构建。
