-- ---------------------------------------------------------------------------------
-- Author: luwenhao1
-- Name: MonopolyInitializer
-- Date: 2026-04-20 14:21:16
-- Desc: Monopoly初始化器
-- ---------------------------------------------------------------------------------

MonopolyInitializer = MonopolyInitializer or {className = "MonopolyInitializer"}
local self = MonopolyInitializer

function MonopolyInitializer.Init()
    -- 时序问题，在默认的require阶段IdentityCustomValueName里的GetMiniGameMgr()会为空，
    -- 因此把require放在Game.Init()的阶段；
    -- 又因为MonopolyData里的local常量表(DOWN_EVENT_MAP下发消息表)依赖IdentityCustomValueName.lua，
    -- 因此MonopolyData的require也放在这里
    require("scripts/MiniGame/DaFuWeng/IdentityCustomValueName.lua")
    require("Lua/Logic/Monopoly/MonopolyData.lua")
    require("Lua/Logic/Monopoly/MonopolyRightEvent.lua")
    MonopolyData.Init()
end

function MonopolyInitializer.UnInit()
    MonopolyData.UnInit()
end