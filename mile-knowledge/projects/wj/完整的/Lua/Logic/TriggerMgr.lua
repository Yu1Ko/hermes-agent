TriggerMgr = TriggerMgr or {className = "TriggerMgr"}
local self = TriggerMgr


function TriggerMgr.Init()
    TriggerMgr.RegEvent()
end

function TriggerMgr.UnInit()
    Event.UnRegAll(self)
end

function TriggerMgr.OnTriggerCallBack(dwMapID, nTriggerID, bEnter)
    local hPlayer = GetClientPlayer()

    if bEnter then
        GDAPI_EnterTrigger(hPlayer, dwMapID, nTriggerID)
    else
        GDAPI_LeaveTrigger(hPlayer, dwMapID, nTriggerID)
    end
end

function TriggerMgr.OnLeaveScene(dwPlayerID)
    local hPlayer = GetClientPlayer()
    if not hPlayer then
        return
    end
    if hPlayer.dwID == dwPlayerID then
        local dwMapID = hPlayer.GetMapID()
        GDAPI_LeaveScene(hPlayer, dwMapID)
    end
end

function TriggerMgr.RegEvent()
    Event.Reg(self, "PLAYER_ENTER_SCENE", function (dwPlayerID)
        TriggerMgr.OnLeaveScene(dwPlayerID)
    end)

    Event.Reg(self, "LOGICAL_TRIGGER_CALLBACK", function (dwMapID, nTriggerID, bEnter)
        TriggerMgr.OnTriggerCallBack(dwMapID, nTriggerID, bEnter)
    end)
end