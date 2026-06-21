-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: OperationWelcomeSignInData
-- Date: 2026-03-24 09:47:45
-- Desc: ?
-- ---------------------------------------------------------------------------------

OperationWelcomeSignInData = OperationWelcomeSignInData or {className = "OperationWelcomeSignInData"}
local self = OperationWelcomeSignInData
-------------------------------- 消息定义 --------------------------------
OperationWelcomeSignInData.Event = {}
OperationWelcomeSignInData.Event.XXX = "OperationWelcomeSignInData.Msg.XXX"

local tOperationIDs = {
    OPERACT_ID.WELCOME_NEWBIE_SIGNIN,
    OPERACT_ID.WELCOME_BACK_SIGNIN,
}

function OperationWelcomeSignInData.InitOperation()
    for _, dwID in ipairs(tOperationIDs) do
        HuaELouData.RegisterProcessor(dwID, self)
    end
end

function OperationWelcomeSignInData.CheckShow(dwID)
    local nCurrentTime = GetCurrentTime()
    local tData = GDAPI_NewSignInGetInfo(dwID)
    local bShow = tData and tData.nEndTime and nCurrentTime < tData.nEndTime
    return bShow
end

function  OperationWelcomeSignInData.HasRedPoint(dwID)
    return self.CheckRewardCanGet(dwID)
end

function OperationWelcomeSignInData.CheckID(dwID)
    return table.contain_value(tOperationIDs, dwID)
end

function OperationWelcomeSignInData.CheckRewardCanGet(dwID)
    local tData = GDAPI_NewSignInGetInfo(dwID)
    if not tData then
        return false
    end
    for i, v in pairs(tData.tCanGet) do
        if v == 1 and tData.tHaveGet[i] == 0 then
            return true
        end
    end
    return false
end

function OperationWelcomeSignInData.InitCurrent(dwID)
    self.dwID = dwID
    self.tData = GDAPI_NewSignInGetInfo(dwID)
end

function OperationWelcomeSignInData.GetCurrentData()
    return self.tData
end

function OperationWelcomeSignInData.GetReward(nIndex)
    if not self.CheckRewardCanGet(self.dwID) then
        return
    end
    RemoteCallToServer("On_NewSignIn_GetReward", self.dwID, nIndex)
end

function OperationWelcomeSignInData.GetRewardState(nIndex)
    local tState = self.tData
    if not tState then
        return OPERACT_REWARD_STATE.NON_GET
    elseif tState.tHaveGet[nIndex] == 1 then
        return OPERACT_REWARD_STATE.ALREADY_GOT
    elseif tState.tCanGet[nIndex] == 1 then
        return OPERACT_REWARD_STATE.CAN_GET
    end
    return OPERACT_REWARD_STATE.NON_GET
end

Event.Reg(self, "REMOTE_NEWSIGNIN_DATA_EVENT", function()
    for _, dwID in ipairs(tOperationIDs) do
        self.CheckShow(dwID)
    end
end)
