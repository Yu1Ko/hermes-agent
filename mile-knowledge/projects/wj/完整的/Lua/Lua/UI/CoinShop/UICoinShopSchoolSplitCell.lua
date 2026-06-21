-- ---------------------------------------------------------------------------------
-- Name: UICoinShopSchoolSplitCell
-- WidgetLieBianActivity
-- Desc: 外观 - 校服裂变活动 - 规则 - cell
-- ---------------------------------------------------------------------------------
local UICoinShopSchoolSplitCell = class("UICoinShopSchoolSplitCell")

-----------------------------View------------------------------
function UICoinShopSchoolSplitCell:OnEnter()
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end
end

function UICoinShopSchoolSplitCell:OnExit()
    self.bInit = false
end

function UICoinShopSchoolSplitCell:BindUIEvent()
    UIHelper.BindUIEvent(self.BtnGet, EventType.OnClick, function()
        RemoteCallToServer("On_Activity_FissionGetReward", self.nIndex) -- 领取奖励
    end)
end

function UICoinShopSchoolSplitCell:RegEvent()

end

function UICoinShopSchoolSplitCell:UpdateInvite(tInfo)
    self.nIndex     = tInfo.nIndex

    local szTaskDes = FormatString("<D0>位受邀好友购买15元点月卡", self.nIndex)
    UIHelper.SetString(self.LabelTaskDes, szTaskDes)

    if tInfo.nState == OPERACT_REWARD_STATE.NON_GET then
        UIHelper.SetVisible(self.ImgUndone, true)
        UIHelper.SetVisible(self.ImgCanGet, false)
        UIHelper.SetVisible(self.ImgItemCanGet, false)
        UIHelper.SetVisible(self.WidgetFinish, false)
    elseif tInfo.nState == OPERACT_REWARD_STATE.CAN_GET then
        UIHelper.SetVisible(self.ImgUndone, false)
        UIHelper.SetVisible(self.ImgCanGet, true)
        UIHelper.SetVisible(self.ImgItemCanGet, true)
        UIHelper.SetVisible(self.WidgetFinish, false)
    elseif tInfo.nState == OPERACT_REWARD_STATE.ALREADY_GOT then
        UIHelper.SetVisible(self.ImgUndone, false)
        UIHelper.SetVisible(self.ImgCanGet, false)
        UIHelper.SetVisible(self.ImgItemCanGet, false)
        UIHelper.SetVisible(self.WidgetFinish, true)
        UIHelper.SetOpacity(self.LabelTaskDes, 76)
    end
end

function UICoinShopSchoolSplitCell:UpdateLevel(tInfo)
    self.nIndex     = tInfo.nIndex

    local szTaskDes = FormatString("当前等级（<D0>/120）", tInfo.nLevel)
    UIHelper.SetString(self.LabelTaskDes, szTaskDes)

    if tInfo.nState == OPERACT_REWARD_STATE.NON_GET then
        UIHelper.SetVisible(self.ImgCanGet, false)
        UIHelper.SetVisible(self.WidgetFinish, false)
    elseif tInfo.nState == OPERACT_REWARD_STATE.CAN_GET then
        UIHelper.SetVisible(self.ImgCanGet, true)
        UIHelper.SetVisible(self.WidgetFinish, false)
    elseif tInfo.nState == OPERACT_REWARD_STATE.ALREADY_GOT then
        UIHelper.SetVisible(self.ImgCanGet, false)
        UIHelper.SetVisible(self.WidgetFinish, true)
    end
end

return UICoinShopSchoolSplitCell