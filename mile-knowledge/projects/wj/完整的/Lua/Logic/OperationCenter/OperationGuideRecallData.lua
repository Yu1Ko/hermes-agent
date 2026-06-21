-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: OperationGuideRecallData
-- Date: 2026-04-09 22:06:28
-- Desc: ?
-- ---------------------------------------------------------------------------------

OperationGuideRecallData = OperationGuideRecallData or {className = "OperationGuideRecallData"}
local self = OperationGuideRecallData
-------------------------------- 消息定义 --------------------------------
OperationGuideRecallData.Event = {}
OperationGuideRecallData.Event.XXX = "OperationGuideRecallData.Msg.XXX"

local ACT_ID = OPERACT_ID.RECALL_GUIDE

function OperationGuideRecallData.InitOperation()
    HuaELouData.RegisterProcessor(ACT_ID, self)
end

function OperationGuideRecallData.CheckShow(dwID)
    local nCurrentTime = GetCurrentTime()
    local tData = GDAPI_NewSignInGetInfo(dwID)
    local bShow = tData and tData.nEndTime and nCurrentTime < tData.nEndTime
    return bShow
end

function OperationGuideRecallData.CheckID(dwID)
    return dwID == ACT_ID
end

Event.Reg(self, "REMOTE_NEWSIGNIN_DATA_EVENT", function()
    self.CheckShow(ACT_ID)
end)


