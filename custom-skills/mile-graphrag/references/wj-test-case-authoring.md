# WJ 自动化测试用例编写指南

## 核心设计哲学（奥卡姆剃刀）

**如无必要，勿增实体。** 这个项目的测试架构遵循数据驱动理念：

- **测试用例 = `.ini` + `.tab`** — 只有这两个文件是每个用例独有的
- **`.py` 是通用逻辑** — 跨用例共享的调度代码，不属于任何单个用例
- **`.tab` 是命令序列** — RunMap 驱动模式的标准载体
- **严禁新建 `.lua` 塞 `print`** — Lua 里不要写死代码
- **严禁无必要地继承控制器** — 现有框架已经够用
- **写新用例前，必须先读完已有的同类用例** — 确定是否可以直接复用，而不是新建文件

Claude Code 曾在 WJ 项目中犯过典型错误：拿到「写 JXSJ3 测试用例」任务后，
新建了 `.lua`（塞满 print）、`.py`（继承控制器）、`.ini`、`.tab` 四个文件，
而实际只需要新建一个 `.tab` + `.ini`，复用已有的 `.py`。根本原因是它没先读
`TestChengduShop` 的三个文件，不知道框架已经有了完整的驱动逻辑。

## 框架运行模式

WJ 框架有两种测试模式：

### 模式 A：RunMap.tab 驱动（简单流程，推荐）

适合线性步骤的 UI 自动化测试。由两部分组成：
- `TestXxx.lua` — 驱动脚本（约 55 行，模板化）
- `RunMap.tab` — TSV 命令序列 (CommandName \t WaitTime \t Description)

Lua 脚本通过 `SearchPanel.LoadRunMapFile(path, 2)` 加载 RunMap.tab（2 表示取 2 列数据），然后在 `FrameUpdate()` 中逐条执行命令。每条命令执行后等待 `WaitTime` 秒再执行下一条。

框架已处理的逻辑：
- `IsFromLoadingEnterGame()` — 检查是否已完成地图加载
- `perfeye_start/stop` — 自动标记性能采集起止
- `ExitGame` — 通过 `CreateEmptyFile` 信号退出游戏

### 模式 B：状态机驱动（复杂流程）

适合需要对话、战斗、轻功等复杂状态切换的场景。参考 `MainTask.lua`（568 行）。

### 模式 C：Start() + Timer 循环驱动（循环/持续流程）

适合需要持续循环操作的场景（如机器人死亡循环、定时挂机）。由两部分组成：
- `.tab` — 处理一次性初始化步骤（传送、召唤机器人、设阵营等），最后一行调用 `Plugin.Start()`
- `.lua` — 定义 `Start()` 函数，内部用 `Timer.AddCycle` 实现循环逻辑，用 `bSwitch` 控制开关

**与模式 A 的关键区别**：
- 模式 A 的 .lua 用 `FrameUpdate()` 逐条消费 .tab 命令，.lua 是通用模板不改
- 模式 C 的 .lua 包含业务逻辑（循环体），.tab 只做前置准备

**模板**（以 RobotDeathLoop 为例）：

```lua
AutoTestLog.Log("PluginName", "PluginName Start")

PluginName = {}
PluginName.bSwitch = true
PluginName.nCycleCount = 0
PluginName.nMaxCycles = 360
PluginName.nInterval = 10
PluginName.timerCycle = nil

function PluginName.Start()
    if not PluginName.bSwitch then return end
    AutoTestLog.Log("PluginName", "开始循环 " .. tostring(PluginName.nMaxCycles) .. "轮")
    PluginName.StartCycle()
end

function PluginName.StartCycle()
    PluginName.timerCycle = Timer.AddCycle(PluginName, PluginName.nInterval, function()
        if not PluginName.bSwitch then
            PluginName.StopCycle()
            return
        end
        PluginName.nCycleCount = PluginName.nCycleCount + 1
        -- 循环体逻辑
        if PluginName.nCycleCount >= PluginName.nMaxCycles then
            PluginName.StopCycle()
        end
    end)
end

function PluginName.StopCycle()
    if PluginName.timerCycle then
        Timer.Del(PluginName.timerCycle)
        PluginName.timerCycle = nil
    end
    AutoTestLog.Log("PluginName", "循环已停止 共" .. tostring(PluginName.nCycleCount) .. "轮")
end

AutoTestLog.Log("PluginName", "PluginName End")
return PluginName
```

**RobotDeathLoop 完整示例**：见 `Interface/RobotDeathLoop/RobotDeathLoop.lua`。.tab 处理传送→画质→初始化机器人→召唤→复活→设恶人阵营→开阵营模式，最后 `/cmd RobotDeathLoop.Start()` 触发循环（每 10 秒复活→自杀，共 360 轮）。

**关键格式要求**：模式 C 的 .lua 需要 RunMap 命令解析器才能自动跑。缺少这个的话，RunMap.tab 的命令永远不会被执行。完整模式 C 结构：

```lua
-- 1) 自身业务逻辑（字段、循环函数）
RobotDeathLoop = {}
RobotDeathLoop.bSwitch = true
-- ...

-- 2) RunMap 命令解析器（标准格式，每个模块级插件都必须有）
local RunMap = {}
local bFlag = true
local pCurrentTime = 0
local nNextTime = 3
local nCurrentStep = 1
local tbRunMapData = SearchPanel.LoadRunMapFile(path.."RunMap.tab", 2)
local list_RunMapCMD = tbRunMapData[1]
local list_RunMapTime = tbRunMapData[2]

local function RunMapFrameUpdate()
    -- 逐条执行 RunMap.tab 命令
    if bFlag and GetTickCount() - pCurrentTime > nNextTime * 1000 then
        -- ... SearchPanel.RunCommand(szCmd) ...
        if string.find(szCmd, "RobotDeathLoop") then
            RobotDeathLoop.Start()  -- 触发自身启动
            bFlag = false
        end
    end
end
Timer.AddFrameCycle(RunMap, 1, function() RunMapFrameUpdate() end)

-- 3) 自身的循环定时器
Timer.AddFrameCycle(RobotDeathLoop, 1, function() ... end)
-- 或 Timer.AddCycle(RobotDeathLoop, 10, function() ... end)
```

**⚠️ RobotDeathLoop 目标对象**：`RobotControl.CMD("ReviveMySelf")` 和 `RobotControl.CMD("KillMySelf")` 操作的是**服务端机器人**，不是玩家。不要写 `GetClientPlayer():IsDead()` 去检查玩家状态。循环逻辑纯靠帧/秒计数驱动，不依赖玩家生死判断。

## RobotControl 命令速查

RobotControl 是框架提供的服务端机器人控制模块。依赖声明：`Interface.ini` 中加 `,RobotControl`。

### 在 .tab 中调用（`/cmd` 前缀）

**CMD 方式**（通过 `tbCMD` 表分发）：
```
/cmd RobotControl.CMD("TeleportRobot")     → 召唤机器人到玩家位置
/cmd RobotControl.CMD("ReviveMySelf")      → 复活所有机器人
/cmd RobotControl.CMD("KillMySelf")        → 自杀
/cmd RobotControl.CMD("StartFollow")       → 跟随
/cmd RobotControl.CMD("StopFollow")        → 停止跟随
/cmd RobotControl.CMD("StartFight")        → 开启战斗
/cmd RobotControl.CMD("StopFight")         → 结束战斗
/cmd RobotControl.CMD("InviteToTeam")      → 邀请入队
/cmd RobotControl.CMD("GetTeamLeader")     → 获取团队权限
/cmd RobotControl.CMD("RequestLeaveTeam")  → 通知退组
```

**直接函数调用**（不走 tbCMD，直接发包给机器人）：
```
/cmd RobotControl.IniRobot(500, 5, "留白")   → 初始化N个机器人(起始索引,数量,名前缀)
/cmd RobotControl.SetErenCamp()              → 设置恶人阵营 (SetCamp=2)
/cmd RobotControl.SetHaoqiCamp()             → 设置浩气阵营 (SetCamp=1)
/cmd RobotControl.StartCamp()                → 开启阵营模式 (OpenCampFlag)
/cmd RobotControl.CancelCamp()               → 取消阵营 (SetCamp=0)
```

## 常见坑

1. **用错日志函数**：必须用 `AutoTestLog.Log("模块名", "消息")` 而非 `LoginMgr.Log`。项目规范要求每个插件始末使用 AutoTestLog 记录，方便排查问题。
2. **缺少 bSwitch**：每个插件必须定义 `PluginName.bSwitch = true`，用于运行时控制开关。
3. **.tab 和 .lua 重复逻辑**：初始化步骤（传送、召唤机器人等）应全部放在 .tab 中，不要在 .lua 的 Start() 里重复实现。.lua 只保留循环/状态机逻辑。
4. **忘记注册 Interface.ini**：新建插件后必须在 `Interface/SearchPanel/Interface.ini` 中添加行 `PluginName=Dependency1,Dependency2`。依赖 RobotControl 的插件必须声明 `,RobotControl`。依赖 AutoLogin 的也需声明。
5. **RobotControl 必须先 IniRobot 再操作**：在调用任何 CMD 前，必须先 `/cmd RobotControl.IniRobot(nIndex, nCount, szNameHead)` 初始化机器人面板。
6. **RobotDeathLoop ≠ 玩家死亡循环**：`RobotControl.CMD` 操作的是服务端机器人，不是玩家。不要在 FrameUpdate 里写 `GetClientPlayer():IsDead()` —— 那是在查玩家，不是机器人。循环逻辑纯靠 Timer 计数，不依赖玩家状态。
7. **模式 C 插件缺少 RunMap 解析器不会自动跑**：只有函数声明没有 RunMap 命令解析器 → RunMap.tab 永远不会被消费 → `Start()` 永远不会被调用。对比 Dungeons/HangUpFight/FlySkill 的模块级 `Timer.AddFrameCycle(RunMap, 1, ...)` 格式。

每行格式：`命令\t等待秒数\t描述`

命令类型：
- `/gm <GM命令>` — 发送 GM 命令（如传送、设坐标、死亡）
- `/cmd <Lua表达式>` — 执行任意 Lua 代码（如 UI 操作、函数调用）

常用命令速查：

### 地图传送
```
/gm player.SwitchMap(108,1, _X_, _Y_, _Z_)    → 切换到地图 108
/gm player.SetPosition(74088, 64420, 1070336)  → 精确定位
```

### UI 操作
```
/cmd UINodeControl.BtnTriggerByLable("BtnShop","商城")     → 按标签点击按钮
/cmd UINodeControl.BtnTrigger("BtnBuy")                     → 按名称点击按钮
/cmd UIMgr.Open(VIEW_ID.PanelExteriorMain)                  → 打开面板
/cmd UIMgr.Close(VIEW_ID.PanelExteriorMain)                 → 关闭面板
/cmd UIMgr.GetViewScript(VIEW_ID.PanelExteriorMain):LinkTitle(true, 3, 1, nil, nil, true)  → 切页签
```

### 商城购买（完整流程）
```
/cmd UIMgr.GetViewScript(VIEW_ID.PanelExteriorMain):LinkTitle(true, 3, 1, nil, nil, true)
/cmd (function() local view=UIMgr.GetViewScript(VIEW_ID.PanelExteriorMain); local tb=CoinShopData.GetExteriorList(1); return view:LinkExteriorSet(tb.tSetList[1].nSet) end)()
/cmd UINodeControl.BtnTrigger("BtnDownload")
/cmd UINodeControl.BtnTrigger("BtnBuy")
/cmd UINodeControl.BtnTrigger("BtnPurchase")
/cmd UINodeControl.BtnTrigger("BtnOk")    ← 可能需两次（折扣券确认）
/cmd UINodeControl.BtnTrigger("BtnOk")
/cmd UIMgr.Close(VIEW_ID.PanelExteriorMain)
```

`LinkExteriorSet(tb.tSetList[1].nSet)` 选第一个套装即"最新"。`LinkTitle` 参数 3=华裳新购页签。

### 镜头控制
```
/cmd Camera_SetRTParams(1, 3.1412010192871, -0.11414948105812)  → 旋转参数
/cmd TurnToFaceDirection()
/cmd TurnTo((GetClientPlayer().nFaceDirection + 128) % 256)       → 旋转 128 度
/cmd CameraMgr.Zoom(0.2)                                           → 拉近（值越小越近）
```

### 流程控制
```
/cmd CreateEmptyFile("perfeye_start")  → 开始性能采集
/cmd CreateEmptyFile("perfeye_stop")   → 结束性能采集
/cmd CreateEmptyFile("wait")           → 等待（由 WaitTime 控制时长）
/cmd CreateEmptyFile("ExitGame")       → 退出游戏
```

## Lua 脚本模板

```lua
AutoTestLog.Log("TestXxx", "TestXxx Start")
local TestXxx = {}
TestXxx.bSwitch = true
local list_RunMapTime = {}
local list_RunMapCMD = {}
local nNextTime = 30
local nCurrentTime = GetTickCount()
local nCurrentStep = 1
local bFlag = true

function TestXxx.FrameUpdate()
    if not TestXxx.bSwitch then return end
    if not SearchPanel.IsFromLoadingEnterGame() then return end
    if bFlag and GetTickCount() - nCurrentTime > nNextTime * 1000 then
        if nCurrentStep == #list_RunMapCMD then bFlag = false end
        local szCmd = list_RunMapCMD[nCurrentStep]
        local nTime = tonumber(list_RunMapTime[nCurrentStep])
        LOG.INFO("%s", szCmd)
        pcall(function() SearchPanel.RunCommand(szCmd) end)
        if string.find(szCmd, "perfeye_start") then
            SearchPanel.bPerfeye_Start = true
        elseif string.find(szCmd, "perfeye_stop") then
            SearchPanel.bPerfeye_Stop = true
        end
        LOG.INFO("%s", szCmd .. "===ok")
        OutputMessage("MSG_SYS", szCmd)
        nNextTime = nTime or nNextTime
        nCurrentTime = GetTickCount()
        nCurrentStep = nCurrentStep + 1
    end
end

local tbRunMapData = SearchPanel.LoadRunMapFile(SearchPanel.szCurrentInterfacePath .. "RunMap.tab", 2)
list_RunMapCMD = tbRunMapData[1]
list_RunMapTime = tbRunMapData[2]

Timer.AddFrameCycle(TestXxx, 1, function() TestXxx.FrameUpdate() end)
AutoTestLog.Log("TestXxx", "TestXxx End")
return TestXxx
```

只需改模块名 `TestXxx` 为实际名称即可，RunMap.tab 驱动逻辑不需要改。

## 创建新账号（LoginCreateRole）

LoginCreateRole 是独立模块，处理完整登录→创角流程：
- 随机生成 8 位数字账号
- 密码固定 123456
- 选择服务器（质量/TDR）
- Hook LoginMgr 的回调实现自动创建角色和进入游戏
- 通过 RunMap.tab 中 `/cmd CreateEmptyFile("LoginCreateRole_start")` 触发

**无法与商城测试合并在一个 RunMap.tab 中**。WJ 框架中它们分属不同 Interface 目录，需在 task_controller 中配置顺序执行：先 LoginCreateRole 创号进游戏，再切换目录跑商城测试。

## 热力图数据去重（HotPointMap 分支1）

HotPointMap 有两种数据保留策略：

- **分支2（默认）**：保留每个格子的全部方向数据（4 条/格），上传后平台自动排序，最差的顶到前面。
- **分支1**：插件侧在写 Data.json 前自动去重——每个格子只保留 Ms（帧耗时）最高的那条。

### 实现要点

**Lua 侧**（`HotPointRunMapOneDepth.lua`）：

```lua
-- 配置字段
HotPointRunMapOneDepth.nDedupType = 0  -- 0=全保留 1=只留最差

-- 设置函数
function HotPointRunMapOneDepth.SetDedupType(nDedupType)
    HotPointRunMapOneDepth.nDedupType = nDedupType
end

-- 去重逻辑（在写 Data.json 之前执行）
if HotPointRunMapOneDepth.nDedupType == 1 then
    for szKey, tbEntries in pairs(tbHotPointData.performanceData) do
        -- 跳过 testGM 占位数据
        local bTestGM = false
        for _, entry in ipairs(tbEntries) do
            if string.find(entry, "testGM") then bTestGM = true; break end
        end
        if not bTestGM and #tbEntries > 1 then
            -- 取 Ms 最高（性能最差）的那条
            local nMaxMs, nMaxIdx = 0, 1
            for i, entry in ipairs(tbEntries) do
                local parts = SearchPanel.StringSplit(entry, ",")
                local nMs = tonumber(parts[9]) or 0
                if nMs > nMaxMs then nMaxMs = nMs; nMaxIdx = i end
            end
            tbHotPointData.performanceData[szKey] = {tbEntries[nMaxIdx]}
        end
    end
end
```

**数据格式**：每条 entry 为 `"(camera),SetPassCall,DrawCall,DrawBatch,Vertices,Triangles,Memory,Fps,Ms,CMD"`，Ms 在逗号分割后的第 9 列（1-indexed）。

**Python 侧**（`CaseHotPointMap.py`）：
- `__init__` 新增 `self.strDedupType = "0"`
- `check_dic_args` 读 `dic_args["DedupType"]`
- `processSearchPanelTab` 加 `changeStrInFile(tmp, '_DedupType_', self.strDedupType)`

**RunMap.tab 模板**需加一行：
```
/cmd HotPointRunMapOneDepth.SetDedupType(_DedupType_)	1	分支1/2
```

| 用例 | 目录 | 说明 |
|------|------|------|
| TestChengDuShop | Interface/TestChengDuShop/ | 成都商城购买（最完整的购买流程参考） |
| TestBuyNewExterior | Interface/TestBuyNewExterior/ | 新建：商城购买最新外装 + 视角拉近 |
| Randomstore | Interface/Randomstore/ | 随机商城商品遍历 |
| LoginCreateRole | Interface/LoginCreateRole/ | 自动创建账号 + 门派角色遍历 |
| MainTask | Interface/MainTask/ | 主任务跑图（状态机模式） |
| RobotDeathLoop | Interface/RobotDeathLoop/ | 模式C示例：机器人复活自杀循环（每10秒×360轮） |
| TestDesertJourney | Interface/TestDesertJourney/ | 大漠之旅任务测试：状态机模式，纯阳成男→120级→河西瀚漠→按历程完成，禁轻功，25分钟超时 |

## 文件组织规范

```
Interface/TestXxx/
├── TestXxx.lua      ← 驱动脚本
└── RunMap.tab       ← 命令序列（TSV，CommandName \t WaitTime \t Description）
```

RunMap.tab 使用 UTF-8 编码，第一行为表头 `CommandName\tWaitTime\tDescription`，后续每行一条命令。
