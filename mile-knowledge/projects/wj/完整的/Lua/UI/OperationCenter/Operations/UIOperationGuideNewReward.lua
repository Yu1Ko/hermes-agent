-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UIOperationGuideNewReward
-- Date: 2026-04-02 20:31:05
-- Desc: 萌新引导人精炼奖励组件
-- ---------------------------------------------------------------------------------

local UIOperationGuideNewReward = class("UIOperationGuideNewReward")

function UIOperationGuideNewReward:OnEnter(nOperationID, nID)
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end

    self.nOperationID = nOperationID
    self.nID = nID

    self:UpdateInfo()
end

function UIOperationGuideNewReward:OnExit()
    self.bInit = false
    self:UnRegEvent()
end

function UIOperationGuideNewReward:BindUIEvent()
    if self.BtntReward then
        UIHelper.BindUIEvent(self.BtntReward, EventType.OnClick, function()
            self:OnRewardClick()
        end)
    end
end

function UIOperationGuideNewReward:RegEvent()
    Event.Reg(self, "EVENT_RECHARGE_CUSTOM_DATA_UPDATE", function(dwID, tData)
        Timer.AddFrame(self, 1, function()
            if not OperationGuideNewData.CheckID(dwID) then
                return
            end
            self:UpdateInfo()
        end)
    end)
end

function UIOperationGuideNewReward:UnRegEvent()
end

-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

function UIOperationGuideNewReward:UpdateInfo()
    self:RefreshRewardState()
end

function UIOperationGuideNewReward:RefreshRewardState()
    local nState = OperationGuideNewData.GetRewardState()
    local bCanGet = nState == OPERACT_REWARD_STATE.CAN_GET
    local bFinished = nState == OPERACT_REWARD_STATE.ALREADY_GOT

    -- ImgRewardCanGet: 可领取状态高亮
    if self.ImgRewardCanGet then
        UIHelper.SetVisible(self.ImgRewardCanGet, bCanGet)
    end
    -- ImgRewardFinish: 已领取遮罩
    if self.ImgRewardFinish then
        UIHelper.SetVisible(self.ImgRewardFinish, bFinished)
    end
end

function UIOperationGuideNewReward:OnRewardClick()
    local nState = OperationGuideNewData.GetRewardState()

    if nState == OPERACT_REWARD_STATE.ALREADY_GOT then
        return
    end

    if nState == OPERACT_REWARD_STATE.CAN_GET then
        self:ShowRewardStatusConfirm(true)
        return
    end

    self:ShowRewardStatusConfirm(false)
end

function UIOperationGuideNewReward:ShowRewardStatusConfirm(bCanGet)
    if bCanGet then
        local szMessage = g_tStrings.STR_GUIDEPERSON_MENGXIN_REWARD_CONFIRM
        if OperationGuideNewData.GetHasRefine() then
            szMessage = szMessage .. "\n\n" .. g_tStrings.STR_GUIDEPERSON_MENGXIN_REWARD_REFINE_WARN
        end
        UIHelper.ShowConfirm(szMessage, function()
            RemoteCallToServer("On_Recharge_GetMenxinRefineRwd")
        end)
        return
    end

    local szMessage =g_tStrings.STR_GUIDEPERSON_MENGXIN_NOT_QUALIFIED
    UIHelper.ShowConfirm(szMessage, nil, nil, true)
end

return UIOperationGuideNewReward
