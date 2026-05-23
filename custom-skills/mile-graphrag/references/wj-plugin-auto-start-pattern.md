# WJ 插件的标准结构和自动启动模式

## 核心发现

WJ 框架下单纯声明函数不会让插件自动跑。每个需要自动运行的插件必须遵守统一格式：

## 标准框架（以 RunMap.tab 驱动为例）

1. **加载 RunMap.tab**（模块级）
2. **注册 RunMap 命令解析器** `Timer.AddFrameCycle(RunMap, 1, function() RunMapFrameUpdate() end)`（模块级）
3. **命令解析器逐条执行 RunMap.tab 中的命令**
4. **遇到特定命令字串时触发插件启动**（如 `/cmd Xxx.Start()`）

## 反例：RobotDeathLoop 原版

```lua
RobotDeathLoop = {}
function RobotDeathLoop.Start() ... end
function RobotDeathLoop.StartDeathCycle()
    Timer.AddCycle(RobotDeathLoop, 10, function() ... end)
end
return RobotDeathLoop  -- 没有任何模块级入口触发
```

问题：`Start()` 声明了但从未被调用，`Timer.AddCycle` 在 `StartDeathCycle` 内部无法在模块加载时执行。插件是纯粹的死代码。

## 正确格式（Dungeons / FlySkill / HangUpFight 模板）

```
模块级代码:
  local RunMap = {}
  local tbRunMapData = SearchPanel.LoadRunMapFile(..., 2)    -- 读 RunMap.tab
  local list_RunMapCMD = tbRunMapData[1]
  local list_RunMapTime = tbRunMapData[2]

  local function RunMapFrameUpdate()
      -- 逐条执行命令
      SearchPanel.RunCommand(szCmd)
      -- 遇到特定命令触发 Start()
      if string.find(szCmd, "PluginName") then PluginName.Start() end
  end

  Timer.AddFrameCycle(RunMap, 1, function() RunMapFrameUpdate() end)

  function PluginName.Start() ... end
  function PluginName.FrameUpdate() ... end

  Timer.AddFrameCycle(PluginName, 1, function() PluginName.FrameUpdate() end)

return PluginName
```

## 关键规则

- RunMap.tab 永远要走标准的 RunMap 命令解析器（模块级 `Timer.AddFrameCycle(RunMap, 1, ...)`）
- `FrameUpdate()` 和 `Start()` 是两套不同的循环——前者注册在模块级，后者通过命令触发
- 不遵循这个模式的插件 copy 进去就是死代码
