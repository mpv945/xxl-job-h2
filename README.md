
mkdir xxl-job-h2
cd .\xxl-job-h2\

git init
git submodule add https://gitee.com/mpv945/xxl-job.git xxl-job 【fork项目到gitee】
git submodule update --remote --recursive

git add .
git commit -m "初始化项目"
git remote add origin https://gitee.com/mpv945/xxl-job-h2.git
git push -u origin "master"

代理
git clone -c http.proxy="http://127.0.0.1:7890" -c http.sslVerify=false https://github.com/git/git.git
git clone -c http.proxy="http://username:password@127.0.0.1:10811" https://github.com/git/git.git
# 设置代理 (仅在当前仓库内有效，但如果在全局设置，则所有仓库都有效)
# 使用 --global 设置后，再用 --unset-global 取消，以确保临时性。

# 临时设置全局代理：
git config --global http.proxy "http://代理服务器地址:端口"
git config --global https.proxy "http://代理服务器地址:端口"

# 对于 SOCKS 代理
# export ALL_PROXY="socks5://代理服务器地址:端口"

# 执行克隆
git clone [仓库地址]

# 克隆完成后，如果需要, 立即取消代理设置以实现临时效果,
# git config --global --unset http.proxy
# git config --global --unset https.proxy


在 Git 中管理子仓库，最标准且常用的方式是使用 Git 子模块（Git Submodule）。 [1, 2]
## 1. 创建主仓库并添加子仓库
你可以通过以下命令在本地初始化主仓库，并将一个已有的远程仓库作为子仓库添加进来： [1]

# 进入并初始化主仓库
cd /path/to/your/main-project
git init
# 添加子仓库（将远程仓库克隆为主仓库的一个子目录）# 格式：git submodule add <子仓库远程地址> <本地存储路径>
git submodule add https://github.com libs/sub-repo
# 查看状态，你会发现多了 .gitmodules 文件和子仓库目录
git status
# 提交这次添加操作到主仓库
git add .
git commit -m "Add sub-repo as a submodule"

------------------------------
## 2. 从已有仓库克隆与初始化
当其他团队成员克隆这个包含子模块的主仓库时，默认情况下子模块文件夹是空的。可以通过以下两种方式进行初始化和下载： [3]
## 方法 A：一步到位克隆（推荐）
在克隆主仓库时加上 --recursive 参数，Git 会自动下载主仓库并自动初始化和更新其中所有的子模块： [3]

git clone --recursive https://github.com

## 方法 B：常规克隆后手动初始化
如果已经使用了常规的 git clone，需要进入项目目录执行初始化和更新： [3, 4]

# 克隆主仓库
git clone https://github.com
cd main-project
# 初始化本地配置文件并拉取子模块代码
git submodule update --init --recursive

------------------------------
## 3. 后续更新与维护
子模块的日常更新分为“远端有新代码”和“本地修改代码”两种场景。 [3, 5]
## 场景 A：子模块远程有更新，需要同步到本地
当其他人更新了子模块的远程仓库，你需要在主仓库中将其更新到最新版本： [3]

# 在主仓库根目录下，一条命令更新所有子模块到各自远程分支的最新提交
git submodule update --remote --recursive
# 注意：更新后主仓库会检测到子模块的指针改变，需要提交这个指针变化
git add libs/sub-repo
git commit -m "Update submodule to latest commit"

## 场景 B：在本地修改子模块代码并推送到远端
如果你需要直接在本地修改子模块的代码，子模块本身就是一个独立的 Git 仓库： [5]

# 1. 必须先进入子模块目录
cd libs/sub-repo
# 2. 切换到开发分支（子模块默认可能处于“游离分支”状态，无法直接提交）
git checkout main
# 3. 修改代码并提交、推送至子模块的独立远端
git add .
git commit -m "Fix a bug in submodule"
git push origin main
# 4. 返回主仓库，将主仓库对子模块的“版本引用指针”一同更新
cd ../..
git add libs/sub-repo
git commit -m "Track updated submodule commit"
git push origin main

## 场景 C：协同开发时拉取主仓库的最新改动
当你的同事更新了主仓库，并且改变了子模块的引用版本，你拉取主仓库代码后需要同步更新本地子模块：

# 拉取主仓库更新
git pull origin main
# 根据主仓库的新记录，将本地子模块对齐到指定的提交版本
git submodule update --recursive

如果在使用过程中遇到子模块的代码冲突或需要彻底删除子模块，可以随时告诉我，我为你提供对应的解决方案！

[1] [https://blog.csdn.net](https://blog.csdn.net/L888666Q/article/details/133925987)
[2] [https://github.com](https://github.com/syaofox/syaofox.github.io/issues/46)
[3] [https://iphysresearch.github.io](https://iphysresearch.github.io/blog/post/programing/git/git_submodule/)
[4] [https://www.runoob.com](https://www.runoob.com/git/git-submodule.html)
[5] [https://www.reddit.com](https://www.reddit.com/r/git/comments/1d53pd7/how_to_update_repo_with_submodules/?tl=zh-hans)



https://www.xuxueli.com/xxl-job/#%E3%80%8A%E5%88%86%E5%B8%83%E5%BC%8F%E4%BB%BB%E5%8A%A1%E8%B0%83%E5%BA%A6%E5%B9%B3%E5%8F%B0XXL-JOB%E3%80%8B
xxl-job改造：https://zhuanlan.zhihu.com/p/514114395

https://blog.csdn.net/2201_75355172/article/details/158927702
xxl-job-admin 【调度中心】
xxl-job-core 【执行器需要依赖，核心】
xxl-job-executor-samples/xxl-job-executor-sample-springboot 【执行器示例： spring boot方式，依赖xxl-job-core,可以参考 】



