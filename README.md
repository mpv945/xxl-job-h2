
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


git add . 提交如何回退？

如果你刚刚不小心执行了 git add .，把所有文件都添加到了暂存区（Staging Area），你可以通过以下几种非常简单的命令进行回退。
根据你目前项目的不同状态，选择最适合你的一种方式：
## 1. 最推荐：撤销全部暂存文件（保留本地修改）
如果你只想把文件从暂存区拉出来，但不想丢失你刚刚辛辛苦苦改写的代码内容，请执行：

git reset

(在较新版本的 Git 中，你也可以使用 git restore --staged .，效果完全相同)
执行后，文件会变回红色的未暂存状态，你可以重新单独添加真正需要提交的文件。
------------------------------
## 2. 撤销单个或特定文件夹（精准回退）
如果你其实想提交大部分文件，只是想把某一个文件或文件夹从 git add . 的范围中剔除出来，请执行：

# 撤销单个文件
git reset 路径/到/文件名.java
# 撤销整个文件夹
git reset 路径/到/文件夹名/

------------------------------
## 3. 彻底放弃所有修改（危险操作！谨慎使用）
如果你发现自己写了一堆烂代码，或者完全是误操作，不仅想撤销 git add .，还想把本地写的所有代码全部删掉，彻底恢复到和上次提交一模一样的干净状态，请执行：

# 注意：这会瞬间抹去你所有未提交的本地修改，无法找回！
git reset --hard HEAD

------------------------------
## 💡 怎么查看当前状态？
在执行完上述回退命令后，建议随时运行以下命令来确认文件是否已经成功移出暂存区：

git status


* 如果文件名是 绿色：说明还在暂存区（等待被 commit）。
* 如果文件名是 红色：说明已经成功回退到工作区（不会被 commit）。

------------------------------
请问你当前的项目是第一次初始化（从来没有提交过 commit），还是已经有历史 commit 记录了呢？
如果是在没有任何历史记录的全新项目上误操作，上面的个别命令可能需要稍微变通，你可以告诉我，我为你提供针对首发提交的撤销命令。

git commit -m 这个提交如何恢复
如果你刚刚执行了 git commit -m "提交信息"，想要撤销这次提交，可以根据你的实际需求选择以下三种最常用的回退方法。
这些操作只会影响你本地的仓库，只要你还没执行 git push，就可以完美后悔。
------------------------------
## 方案 1：最常用！只撤销 Commit，保留代码修改（软回退）
如果你只是信息写错了，或者漏掉了几个文件想重新赞存一起提交，请执行：

git reset --soft HEAD~1


* 效果：刚刚的 commit 会被取消。
* 代码状态：你写的代码完好无损，且文件依然是绿色的暂存状态（相当于回到了你刚执行完 git add . 之后、还没有 commit 的时刻）。你可以修改代码、修改 commit 信息后重新提交。

------------------------------
## 方案 2：撤销 Commit，并让代码回到未暂存状态
如果你不仅想撤销 commit，还想把文件退回到红色的未暂存状态，请执行：

git reset HEAD~1


* 效果：撤销最近一次 commit。
* 代码状态：代码不会丢失，但文件会变成红色的未暂存状态。

------------------------------
## 方案 3：彻底毁灭！连同代码修改一起删掉（危险操作）
如果你觉得这次 commit 的代码完全没用，不仅要撤销提交，还要把本地刚刚写的所有代码彻底删光，恢复到上一次干净的提交状态，请执行：

# ⚠️ 警告：这会永久删除你本地未保存的修改，无法轻易找回！
git reset --hard HEAD~1

------------------------------
## 💡 进阶技巧：我只是想改一下刚刚的 Commit 注释（不撤销）
如果你不需要撤销代码，仅仅是发现 -m "..." 里的提交文字打错了，不需要用 reset。直接输入以下命令，就会弹出一个编辑器让你修改上一条提交信息：

git commit --amend

------------------------------
请问你刚刚有没有执行 git push 把这个提交推送到远程仓库（如 GitHub / GitLab）？
如果已经推送到远程，回退方法会有所不同（需要用到 git revert 或强推），你可以告诉我，我为你提供远程回退的安全方案。


git push后如何正确并且安全回退？
当你的错误提交已经通过 git push 推送到了远程仓库（如 GitHub/GitLab），回退时最核心的原则是：确保不破坏团队中其他人的本地代码历史。
根据你的分支是个人独立开发分支还是多人共用的公共分支（如 main/master/develop），请选择对应的安全回退方案：
------------------------------
## 方案一：在【公共分支】上安全回退（最安全、不影响他人）
如果这个分支有其他人也在同时开发，绝对不能使用强推（force push），否则会导致同事的代码无法拉取或历史错乱。
正确做法：使用 git revert 创建一次“反向提交”。它的原理是新建一个提交，里面的内容恰好是用来抵消你上一次错误提交所做的修改。

1. 撤销最近的一次远程提交：

git revert HEAD

2. 在弹出的控制台编辑器中保存提交信息（默认会自动生成一条 Revert "你原本的错误信息"），保存并退出。
3. 将这个“反向撤销”的提交安全地推送到远程：

git push origin <当前分支名>



* 效果：远程和本地的历史记录里会保留你犯错的 commit，但紧接着会多出一个绿色的新 commit 把错误改了过来。代码完美恢复，同事拉取代码时不会收到任何冲突和报错。

------------------------------
## 方案二：在【个人独立分支】上回退（让历史记录干干净净）
如果你是在自己独立的 Feature 专属分支上开发，确认没有任何人会拉取你这个分支的代码，你可以选择强行抹去远程的错误提交记录。

1. 在本地将代码强制回退到上一个版本（保留代码修改到暂存区）：

git reset --soft HEAD~1

(如果你连本地代码也不想要了，可以使用 --hard HEAD~1)
2. 使用强推命令，用本地干净的历史强行覆盖远程历史：

git push origin <当前分支名> --force-with-lease


⚠️ 为什么不用 --force？
建议永远使用 --force-with-lease 代替 -f 或 --force。
这是 Git 的保护机制：如果在这几分钟内，恰好有同事在你不知道的情况下往这个分支推了新代码，--force-with-lease 会自动拒绝强推，从而避免你误删同事刚刚提交的全新代码。

------------------------------
## 💡 怎么撤销“好几天前 / 很多次之前”的某次特定推送？
如果你要撤销的不是最后一次，而是前天推送的某一个 commit，你可以通过 git log 找到那次提交的哈希值（commit ID），然后精准撤销它：

# 精准撤销某一次提交，而不影响它之后的其他提交
git revert <那次错误的commit_id>
git push origin <当前分支名>

------------------------------
请问你当前操作的是 main / master 生产主分支，还是你个人的开发分支？
如果主分支被保护了（Protected branch）导致强推被拒绝，或者你在执行 revert 时遇到了 Conflict（代码冲突），请把提示发给我，我来帮你解冲突。

https://www.xuxueli.com/xxl-job/#%E3%80%8A%E5%88%86%E5%B8%83%E5%BC%8F%E4%BB%BB%E5%8A%A1%E8%B0%83%E5%BA%A6%E5%B9%B3%E5%8F%B0XXL-JOB%E3%80%8B
xxl-job改造：https://zhuanlan.zhihu.com/p/514114395

https://blog.csdn.net/2201_75355172/article/details/158927702
xxl-job-admin 【调度中心】
xxl-job-core 【执行器需要依赖，核心】
xxl-job-executor-samples/xxl-job-executor-sample-springboot 【执行器示例： spring boot方式，依赖xxl-job-core,可以参考 】


子仓库改动提交（必须先推送到子仓库）
# 以后拉取带有子仓库的项目，最标准的命令：
git pull --recurse-submodules
# 1. 命令行进入子仓库的目录
cd <你的子仓库文件夹路径>
# 2. 查看当前状态，并切换到你需要开发的分支（例如 main 或 develop）
git checkout main 【可选】
第二步：在【子仓库】中提交并推送代码
# 1. 暂存子仓库的修改
git add .
# 2. 提交子仓库的修改
git commit -m "feat: 修改了子仓库的某些功能"
# 3. 必须先把子仓库的代码推送到它的远程仓库
git push origin main 【如果没有 git checkout main，推送直接：git push】

cd ..
主仓库提交【回到主仓库】

git add .
git commit -m "修改代码"
git push -u origin "master"


