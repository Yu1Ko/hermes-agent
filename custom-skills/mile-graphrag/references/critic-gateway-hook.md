# Gateway Hook 接入 Critic 拦截器

## 现状

`critic.py` 代码已完成（`/root/.hermes/mile-knowledge/agents/critic.py`），已通过 gateway hook 接入对话链路。

Hook 位于 `~/.hermes/hooks/critic-intercept/`，包含：
- `HOOK.yaml` — 元数据，注册 `agent:end` 事件
- `handler.py` — 异步处理器，调 `check_reply()` + `rewrite_reply()`

## 实际 handler.py 结构

当前部署的 handler（`~/.hermes/hooks/critic-intercept/handler.py`）逻辑：

1. 从 context 获取 `user_message`（或 fallback `message`）和 `response`
2. 长度阈值：跳过 <20 或 >8000 字符的回复
3. 调 `check_reply()` 做质量检查
4. 不通过时调 `rewrite_reply()` 重写
5. 返回 `{"action": "rewrite", "new_text": ...}` 或 `None`

## Gateway 传递的 Context Key

⚠️ **关键坑**：gateway (`run.py` 的 `_run_agent_message`) 在 `agent:end` 事件传递的 context 字段名：

```python
hook_ctx = {
    "platform": source.platform.value,
    "user_id": source.user_id,
    "session_id": session_entry.session_id,
    "message": message_text[:500],     # ← 注意：是 "message" 不是 "user_message"
}
# 然后追加：
_end_results = await self.hooks.emit_collect("agent:end", {
    **hook_ctx,
    "response": (response or ""),      # ← bot 回复 key 是 "response"
})
```

Handler 中用 `context.get("user_message") or context.get("message", "")` 兼容两种写法。如果只用 `context.get("user_message", "")` 会恒为空，所有请求静默跳过。

## 接入步骤（如需重建 hook）

1. 确认 `~/.hermes/hooks/critic-intercept/` 目录存在
2. `HOOK.yaml`：
   ```yaml
   name: critic-intercept
   description: Run MiLe Critic quality gate on agent replies before delivery
   events:
     - agent:end
   ```
3. `handler.py`：参考 `~/.hermes/hooks/critic-intercept/handler.py`（已部署）
4. 确认 `data/case_library.json` 存在（无案例也能跑，few-shot 部分为空）
5. 重启 gateway：`pkill -f '[h]ermes.*gateway'` → gateway run

## 验证

```bash
# 查看 hook 是否加载
grep 'hook(s) loaded' /root/.hermes/logs/gateway.log | tail -1

# 查看 critic 拦截/重写记录
grep -i 'critic' /root/.hermes/logs/gateway.log

# 模拟测试
cd /root/.hermes/mile-knowledge
python3 agents/critic.py --user-msg "帮我写个文件" --bot-reply "好的我来分析一下..." --json
```

## 注意事项

- Hook 错误会被捕获并 log，不会阻塞主流程
- `check_reply` 在 API 故障时默认 `pass: true`（放行）
- critic 使用 `deepseek-v4-flash`，需 `DEEPSEEK_API_KEY` 在 `.env` 中可用
- 重写后的 `new_text` 会被 gateway 直接替换原回复内容
- 重写失败（API 故障/结果为空）时原回复照常发送，不会丢消息
- case_library.json 为空也可以跑（few-shot 部分为空，只靠 prompt 指令判断）
