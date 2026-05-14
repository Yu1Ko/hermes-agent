# WJ 插件自动启动的必须步骤

## 问题

插件 `Xxx.lua` 写好放进游戏 Interface 目录后不自动执行。`Start()` 函数声明了但从未被调用。

## 根因

WJ 框架中，插件不会因为定义了 `Start()` 就自动运行。必须通过 RunMap 命令解析器触发。缺失 RunMap 命令解析循环是插件"不自动跑"的最常见原因。

## 标准模式（参考 Dungeons、HangUpFight、FlySkill）

```lua
-- 1. 模块级加载 RunMap.tab
local tbRunMapData = SearchPanel.LoadRunMapFile(SearchPanel.szCurrentInterfacePath.."RunMap.tab", 2)
local list_RunMapCMD = tbRunMapData[1]
local list_RunMapTime = tbRunMapData[2]

-- 2. 定义 RunMap 命令解析函数
local RunMap = {}
local bFlag = true
local pCurrentTime = 0
local nNextTime = 3
local nCurrentStep = 1

local function RunMapFrameUpdate()
    local player = GetClientPlayer()
    if not player then return end
    if bFlag and GetTickCount() - pCurrentTime > nNextTime * 1000 then
        if nCurrentStep > #list_RunMapCMD then
            bFlag = false
            return
        end
        local szCmd = list_RunMapCMD[nCurrentStep]
        local nTime = tonumber(list_RunMapTime[nCurrentStep])
        if szCmd and szCmd:sub(1, 1) == "/" then
            SearchPanel.RunCommand(szCmd)
        end
        nNextTime = nTime
        pCurrentTime = GetTickCount()
        nCurrentStep = nCurrentStep + 1
    end
end

-- 3. 模块级注册——这是自动启动的关键
Timer.AddFrameCycle(RunMap, 1, function()
    RunMapFrameUpdate()
end)
```

RunMap.tab 中写入 `/cmd Xxx.Start()` 作为最后一行命令，解析器读到后通过 `SearchPanel.RunCommand` 触发 `Start()`。

## 常见错误

- 只定义了 `Start()` 和 `FrameUpdate()` 函数，但没有 RunMap 命令解析器 → 函数永远不会被调用
- 把 `Timer.AddFrameCycle(Xxx, 1, ...)` 写在模块级但没有加载 RunMap.tab → 能跑但没有命令驱动的初始化步骤
- `RobotDeathLoop` 是典型反例：原始代码只有函数声明没有入口，修复后加上了 RunMap 解析器才自启成功

2026-05-07：RobotDeathLoop 踩中原坑。同样的坑在之前的 session 中也被踩到过，说明这是一个反复出现的知识盲区。
