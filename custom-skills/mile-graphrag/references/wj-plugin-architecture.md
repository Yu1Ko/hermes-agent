# WJ Plugin Architecture — Auto-Start Pattern

How WJ Lua plugins start running when copied into the game's plugin directory.
The loading chain and the mandatory RunMap command parser pattern.

## Loading Chain

```
SearchPanel loads Interface.ini
  → reads [Interface] section: Type=RobotDeathLoop, Switch=1
  → reads dependency: RobotDeathLoop=AutoLogin,RobotControl
  → require("mui/Lua/Interface/AutoLogin/AutoLogin.lua")
  → require("mui/Lua/Interface/RobotControl/RobotControl.lua")
  → require("mui/Lua/Interface/RobotDeathLoop/RobotDeathLoop.lua")
  → module stored in SearchPanel.tbModule["RobotDeathLoop"]
```

The `require()` call executes the lua file top-to-bottom. Module-level code runs immediately.
But the plugin's `Start()` is NOT called automatically — it must be triggered by a RunMap
command parser running at module level.

## Mandatory Pattern: RunMap Command Parser

Every WJ plugin that auto-runs follows this exact structure. Missing it means the plugin
loads but never activates.

```lua
-- ===== 1. Load RunMap.tab (module level) =====
local RunMap = {}
local bFlag = true
local pCurrentTime = 0
local nNextTime = 3
local nCurrentStep = 1
local tbRunMapData = SearchPanel.LoadRunMapFile(SearchPanel.szCurrentInterfacePath.."RunMap.tab", 2)
local list_RunMapCMD = tbRunMapData[1]
local list_RunMapTime = tbRunMapData[2]

-- ===== 2. Command parser function =====
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

-- ===== 3. Register at module level =====
Timer.AddFrameCycle(RunMap, 1, function()
    RunMapFrameUpdate()
end)
```

This reads RunMap.tab entries like:
```
/cmd RobotDeathLoop.Start()	3	启动死亡循环 每10秒复活→自杀 共360轮
/cmd perfeye_start		10	开始性能采集
/cmd perfeye_stop		5	结束性能采集
```

`SearchPanel.RunCommand("/cmd Xxx.Start()")` calls `SearchPanel.MyExecuteScriptCommand("Xxx.Start()")`
which executes `return Xxx.Start()` via `loadstring`.

The **plugin's own** FrameUpdate cycle can also be registered at module level,
but it depends on `Start()` being called to reset state:

```lua
function PluginName.Start()
    -- reset counters, state
end

function PluginName.FrameUpdate()
    -- per-frame logic
end

-- Module-level registration — runs every frame immediately
Timer.AddFrameCycle(PluginName, 1, function()
    PluginName.FrameUpdate()
end)
```

## RunMap.tab Format

```
/cmd command_or_path	wait_seconds	description
/gm GMCommand	wait_seconds	description
/path/to/file	wait_seconds	description
```

- First column: command (`/cmd` = execute script, `/gm` = GM command) or path
- Second column: wait time in seconds before next step
- Third column: description (ignored)

## Dependencies (Interface.ini)

```
[Interface]
Type=PluginName           ; which plugin to load
Switch=1                  ; 1=enabled, 0=disabled
PluginName=Dep1,Dep2      ; comma-separated dependencies loaded before this plugin
```

Dependencies are `require()`'d before the main plugin. Use this when your plugin calls
functions from other modules (e.g., RobotControl.CMD).

## Case Study: RobotDeathLoop — What Went Wrong

**Original (broken)**: Had `Start()` and `StartDeathCycle()` defined but no module-level
RunMap command parser. `Start()` was never called. Plugin loaded silently and did nothing.

**Fix**: Added the standard RunMap command parser + `Timer.AddFrameCycle` for both the
command runner and the FrameUpdate cycle. Matched the pattern used by Dungeons, HangUpFight,
FlySkill, and every other auto-running WJ plugin.

Key files compared: `Dungeons/Dungeons.lua` (lines 395-441), `HangUpFight/HangUpFight.lua`,
`FlySkill/FlySkill.lua` (lines 282-320).

### Pitfalls: Robot vs Player, Over-engineering

**RobotDeathLoop controls robots, not the player.** The core logic is
`RobotControl.CMD("ReviveMySelf")` and `RobotControl.CMD("KillMySelf")` — these send
commands to server-side robots. Do NOT use `GetClientPlayer()` or `player:IsDead()` for
this plugin. Checking player death state is the wrong target entirely.

**The revive/kill order matters.** RunMap.tab says "复活→自杀" — revive first, then kill.
Do NOT reverse this. The correct cycle: `ReviveMySelf` → wait → `KillMySelf`.

**Don't over-engineer the timing.** Original code used `Timer.AddCycle(10 seconds)` and
`Timer.Add(1 second)` for the revive-to-kill gap. This is fine. An attempt to replace it
with per-frame counting (`nFrameCount`, `nKillDelay=30`, `nReviveDelay=60`) was rejected
because it complicated a simple cycle with unnecessary frame tracking and got the order
wrong. If the user wants a 10-second cycle, use `Timer.AddCycle`. FrameUpdate is for
per-frame logic (state machines, movement, death detection of player character), not
for timed robot cycling.
