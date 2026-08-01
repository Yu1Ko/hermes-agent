-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UIFirstPurChaseView
-- Date: 2022-12-30 11:02:48
-- Desc: ?
-- ---------------------------------------------------------------------------------

local UIFirstPurChaseView = class("UIFirstPurChaseView")

function UIFirstPurChaseView:OnEnter()
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end

    local dwOperatActID, nID = 55, 4

    self.nActivityID = dwOperatActID
    self.tbRewardInfoFromTable = HuaELouData.GetRewardLevelInfoByActivityID(self.nActivityID)
    UIHelper.SetVisible(self.WidgetAniAll, false)
    RemoteCallToServer("On_Recharge_CheckRFirstCharge", self.nActivityID)
end

function UIFirstPurChaseView:OnExit()
    self.bInit = false
    self:UnRegEvent()
end

function UIFirstPurChaseView:BindUIEvent()
    UIHelper.BindUIEvent(self.BtnGetReward, EventType.OnClick, function()
        for index, tbRewardInfoInTable in ipairs(self.tbRewardInfoFromTable) do
            local nRewardState = HuaELouData.GetLevelRewardStateOfPlayerByLevel(self.tbRewardInfo, tbRewardInfoInTable.nLevel)
            if nRewardState == OPERACT_REWARD_STATE.CAN_GET then
                RemoteCallToServer("On_Recharge_GetRFirstChargeRwd", tbRewardInfoInTable.nLevel, self.nActivityID)
            end
        end
    end)

    UIHelper.BindUIEvent(self.BtnPurchase, EventType.OnClick,function ()
        UIMgr.Open(VIEW_ID.PanelTopUpMain, nil, true)
    end)
end

function UIFirstPurChaseView:RegEvent()
    Event.Reg(self, EventType.On_Recharge_CheckRFirstCharge_CallBack, function(tbRewardInfo, bCanDo, dwID)
        self.tbRewardInfo = tbRewardInfo
        self.bCanDo = bCanDo
        self.dwID = dwID
        self:UpdateInfo()
    end)
    Event.Reg(self, EventType.On_Recharge_GetRFirstChargeRwd_CallBack, function(tbRewardInfo, dwID)
        self.tbRewardInfo = tbRewardInfo
        self.dwID = dwID
        self:UpdateInfo()
    end)

    Event.Reg(self, EventType.OnSelectItem, function(nTabType, nTabID, bSelected, toggle)
        _, self.scriptItemTip = TipsHelper.ShowNodeHoverTipsInDir(PREFAB_ID.WidgetItemTip, toggle, TipsLayoutDir.RIGHT_CENTER)
        self.SelectToggle = toggle
        self.nCurShowTabType = nTabType
        self.nCurShownTabID = nTabID
        self.scriptItemTip:OnInitWithTabID(nTabType, nTabID)
        self.scriptItemTip:SetBtnState({})
    end)

end

function UIFirstPurChaseView:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end






-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

function UIFirstPurChaseView:UpdateInfo()
    UIHelper.SetVisible(self.WidgetAniAll, true)
    for index, tbRewardInfoInTable in ipairs(self.tbRewardInfoFromTable) do
        if index <= #self.tbRewardDay then
            local scriptView = UIHelper.GetBindScript(self.tbRewardDay[index])
            scriptView:OnEnter(self.tbRewardInfo, tbRewardInfoInTable, index)
        end
    end

    local bCanGetReward = false
    local bFirstPurchase = false
    for index, tbRewardInfoInTable in ipairs(self.tbRewardInfoFromTable) do
        local nRewardState = HuaELouData.GetLevelRewardStateOfPlayerByLevel(self.tbRewardInfo, tbRewardInfoInTable.nLevel)
        if index == 1 and nRewardState == OPERACT_REWARD_STATE.NON_GET then
            bFirstPurchase = true
        end
        if nRewardState == OPERACT_REWARD_STATE.CAN_GET then
            bCanGetReward = true
        end
        UIHelper.SetVisible(self.tbImgNotGet[index], false)
        UIHelper.SetVisible(self.tbImgReadyToGet[index], false)
        UIHelper.SetVisible(self.tbImgGotten[index], nRewardState == OPERACT_REWARD_STATE.ALREADY_GOT)
    end

    local nBtnState = bCanGetReward and BTN_STATE.Normal or BTN_STATE.Disable
    UIHelper.SetButtonState(self.BtnGetReward, nBtnState)

    UIHelper.SetVisible(self.BtnGetReward, not bFirstPurchase)
    UIHelper.SetVisible(self.BtnPurchase, bFirstPurchase)
end

return UIFirstPurChaseView