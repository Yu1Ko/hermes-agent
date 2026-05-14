-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: OperationGuideNewData
-- Date: 2026-04-02 21:11:24
-- Desc: 萌新引导人活动数据管理模块
-- ---------------------------------------------------------------------------------

OperationGuideNewData = OperationGuideNewData or {className = "OperationGuideNewData"}
local self = OperationGuideNewData

-------------------------------- 常量定义 --------------------------------
local ACT_ID = OPERACT_ID.GUIDE_PERSON_MENGXIN
local REWARD_STATE = OPERACT_REWARD_STATE

-------------------------------- 私有变量 --------------------------------
self.tData = nil

-------------------------------- 公共函数 --------------------------------
function OperationGuideNewData.InitOperation()
    HuaELouData.RegisterProcessor(ACT_ID, self)
end

function OperationGuideNewData.HasRedPoint(dwID)
    if not self.CheckID(dwID) then
        return false
    end
    return self.GetRewardState() == REWARD_STATE.CAN_GET
end

function OperationGuideNewData.GetOperationID()
    return ACT_ID
end

function OperationGuideNewData.CheckID(dwID)
    return dwID == ACT_ID
end

function OperationGuideNewData.SetData(tData)
    self.tData = tData or {}
end

function OperationGuideNewData.GetData()
    return self.tData or {}
end

function OperationGuideNewData.GetRewardState()
    local nRewardState = self.GetData().nRewardState
    if nRewardState ~= REWARD_STATE.CAN_GET and nRewardState ~= REWARD_STATE.ALREADY_GOT then
        return REWARD_STATE.NON_GET
    end
    return nRewardState
end

function OperationGuideNewData.GetHasRefine()
    return self.GetData().bHasRefine and true or false
end

-------------------------------- 事件处理 --------------------------------

Event.Reg(self, "EVENT_RECHARGE_CUSTOM_DATA_UPDATE", function(dwID, tData)
    if not self.CheckID(dwID) then
        return
    end

    self.SetData(tData)
end)
