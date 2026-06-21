---
name: wps365-user-current
description: 当前用户 - 查询当前登录用户信息（昵称、企业、部门、邮箱等），调用 V7 接口。
---

# 当前用户

查询当前登录用户的身份信息，包括昵称、企业、部门、邮箱、手机等。

## 快速开始

```bash
export WPS_SID="your_sid"
cd ~/.hermes/skills/wps365
```

## Commands

```bash
python user-current/run.py
```

## 返回信息

- 用户 ID、昵称
- 企业 ID
- 部门列表
- 邮箱、手机号
- 头像 URL
- 创建/修改时间（UTC ISO 8601）

## 示例

```bash
python user-current/run.py

# 输出：
# ## 当前用户
# - 用户：张三
# - 用户ID：xxx
# - 企业ID：xxx
# - 部门：技术部
```

## 注意事项

- 需要先设置环境变量 WPS_SID
- 输出格式：Markdown 摘要 + 完整 JSON
