-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UIHLIdentityFishingPlayerCard
-- Date: 2024-02-29 10:58:51
-- Desc: ?
-- ---------------------------------------------------------------------------------
local UIHLIdentityFishingPlayerCard = class("UIHLIdentityFishingPlayerCard")

function UIHLIdentityFishingPlayerCard:OnEnter()
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end
    self:UpdateInfo()
end

function UIHLIdentityFishingPlayerCard:OnExit()
    self.bInit = false
    self:UnRegEvent()
end

function UIHLIdentityFishingPlayerCard:BindUIEvent()
    UIHelper.SetTouchDownHideTips(self.TogHide, false)
    UIHelper.SetTouchDownHideTips(self.TogAoutSell01, false)
    UIHelper.SetTouchDownHideTips(self.TogAoutSell02, false)
    UIHelper.BindUIEvent(self.BtnNote, EventType.OnClick, function()
        UIMgr.Open(VIEW_ID.PanelHomeFishNote)
    end)

    UIHelper.BindUIEvent(self.BtnCollect, EventType.OnClick, function()
        -- UIMgr.Open(VIEW_ID.PanelHomeFishNote)
    end)

    UIHelper.BindUIEvent(self.TogHide, EventType.OnClick, function(btn)
        if UIHelper.GetSelected(self.TogHide) then
            self:UpdateHideInfo()
        end
    end)

    UIHelper.BindUIEvent(self.TogAoutSell01, EventType.OnClick, function(btn)
        local nDisplayType = UIHelper.GetSelected(self.TogAoutSell01) and GameSettingType.PlayDisplay.HideAll or GameSettingType.PlayDisplay.All
        APIHelper.SetPlayDisplay(nDisplayType, true)
    end)

    UIHelper.BindUIEvent(self.TogAoutSell02, EventType.OnClick, function(btn)
        local bHideNpc = UIHelper.GetSelected(self.TogAoutSell02)
        ToggleNpc(not bHideNpc)
    end)
end

function UIHLIdentityFishingPlayerCard:RegEvent()
    Event.Reg(self, EventType.HideAllHoverTips, function ()
        UIHelper.SetSelected(self.TogHide, false)
    end)
end

function UIHLIdentityFishingPlayerCard:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end






-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

function UIHLIdentityFishingPlayerCard:UpdateInfo()
    local tFishData         = HomelandFishingData.tFishData
    self.dwID               = tFishData.dwID
    self.tExpData           = HomelandFishingData.tExpData

    local nLevel     = self.tExpData.nLevel or 0
    local nExp       = self.tExpData.nExp or 0
    local nNextExp   = self.tExpData.nNextExp or 0
    local fPercent   = self.tExpData.fExpPercent or 0
    local szExp      = string.format("%s/%s",nExp, nNextExp)

    UIHelper.SetProgressBarPercent(self.SliderExp, fPercent * 100)
    UIHelper.SetString(self.LabelPlayerLevel, nLevel)
    UIHelper.SetString(self.LabelExp, szExp)
end

function UIHLIdentityFishingPlayerCard:UpdateHideInfo()
    UIHelper.SetSelected(self.TogAoutSell01, APIHelper.MainCityLeftBottomPlayDisplayCheck())
    UIHelper.SetSelected(self.TogAoutSell02, APIHelper.NpcDisplayCheck())
end

return UIHLIdentityFishingPlayerCard