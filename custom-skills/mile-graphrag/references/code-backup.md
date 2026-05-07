# MiLe 代码备份流程

> **⚠️ 当前状态（2026-05-08）**：本地备份已准备完成（7828 文件，360M），**但 GitHub push 尚未执行**。
> `https://github.com/Yu1Ko/hermes-agent` 当前只含上游 hermes-agent 代码 + 少量本地提交，**不含 custom-skills/ 和 mile-knowledge/**。
> 原因：服务器无 Classic PAT token（`ghp_*`），无法认证推送。精细 PAT 即使有 Contents:RW 也 403。

备份目标仓库：`https://github.com/Yu1Ko/hermes-agent`

## 备份内容

- `custom-skills/` — MiLe 自定义 skills（konata-default-persona, mile-graphrag, web-access, wps365）
- `mile-knowledge/` — GraphRAG 知识图谱 + 后台 Agent + WJ 项目
- `scripts/restart-gateway.sh` — 网关重启脚本

## 备份步骤

```bash
# 1. Clone 目标仓库
cd /tmp && git clone https://github.com/Yu1Ko/hermes-agent.git

# 2. 创建 .gitignore（排除大文件）
cat > hermes-agent/mile-knowledge/.gitignore << 'EOF'
projects/wj/task_controller/Perfeye-*/
projects/wj/task_controller/logs/
projects/wj/task_controller/log_file/
projects/wj/task_controller/Android-*/
projects/wj/task_controller/gnirehtet-rust-linux64/
projects/wj/task_controller/gnirehtet.apk
projects/wj/task_controller/WebDriverAgent.ipa
projects/wj/task_controller/uiautomator2/
projects/wj/task_controller/*.xlsx
__pycache__/
*.pyc
data/cache/
graphrag/.cache/
EOF

# 3. 用 rsync 复制 mile-knowledge（排除大文件）
rsync -av \
  --exclude='__pycache__' \
  --exclude='Perfeye-*' \
  --exclude='logs/' \
  --exclude='log_file/' \
  --exclude='Android-*' \
  --exclude='gnirehtet-rust-linux64/' \
  --exclude='gnirehtet.apk' \
  --exclude='WebDriverAgent.ipa' \
  --exclude='uiautomator2/' \
  --exclude='*.xlsx' \
  /root/.hermes/mile-knowledge/ /tmp/hermes-agent/mile-knowledge/

# 4. 移除嵌套 .git 目录
rm -rf /tmp/hermes-agent/mile-knowledge/projects/wj/task_controller/.git

# 5. 复制自定义 skills
cp -r /root/.hermes/skills/{konata-default-persona,mile-graphrag,web-access,wps365} \
  /tmp/hermes-agent/custom-skills/

# 6. Commit & push
cd /tmp/hermes-agent
git config user.name "Yu1Ko"
git config user.email "1752429910.gg@gmail.com"
git add custom-skills/ mile-knowledge/ scripts/restart-gateway.sh
git commit -m "feat: backup all MiLe server code"
git push "https://TOKEN@github.com/Yu1Ko/hermes-agent.git" main
```

## 排除体积分析

原始 621M → 排除后 ~360M

| 排除项 | 节省体积 | 原因 |
|--------|---------|------|
| Perfeye 发布包 | 247M | Perfeye-*.release APK/IPA |
| 日志文件 | ~6M | logs/ + log_file/ |
| Android 工具包 | ~4M | Android-*/ 含 ADB 二进制 |
| gnirehtet | ~4M | 反向代理工具（含 APK） |
| uiautomator2 | ~700K | Python 自动化库 |
| __pycache__ | ~1M | Python 编译缓存 |

## 恢复（从 GitHub 拉回服务器）

```bash
cd ~/.hermes
git clone https://github.com/Yu1Ko/hermes-agent.git /tmp/restore
cp -r /tmp/restore/mile-knowledge/* ./
cp -r /tmp/restore/custom-skills/* ./skills/
```

## 认证说明

本服务器无 `gh` CLI、无 SSH 私钥，只能用 Classic PAT (`ghp_*`) push。
精细 PAT (`github_pat_*`) 即使有 Contents:RW 权限也返回 403。
