-- ---------------------------------------------------------------------------------
-- Author: luwenhao1
-- Name: UIPanelBlessConfirmView
-- Date: 2026-03-26 19:20:54
-- Desc: 扬刀大会-获得卡牌界面 PanelBlessConfirm
-- ---------------------------------------------------------------------------------

local UIPanelBlessConfirmView = class("UIPanelBlessConfirmView")

function UIPanelBlessConfirmView:OnEnter(tBlessCardList)
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end

    self.tBlessCardList = tBlessCardList
    self:UpdateInfo()
end

function UIPanelBlessConfirmView:OnExit()
    self.bInit = false
    self:UnRegEvent()
end

function UIPanelBlessConfirmView:BindUIEvent()
    UIHelper.BindUIEvent(self.BtnChat, EventType.OnClick, function()
        ChatHelper.Chat(UI_Chat_Channel.Team)
    end)
    UIHelper.BindUIEvent(self.BtnContinue, EventType.OnClick, function()
        UIMgr.Close(self)
    end)
    UIHelper.BindUIEvent(self.TogDetailedDesc, EventType.OnSelectChanged, function(_, bSelected)
        ArenaTowerData.ShowBlessDetailDesc(bSelected)
    end)
end

function UIPanelBlessConfirmView:RegEvent()
    Event.Reg(self, EventType.OnShowBlessDetailDesc, function()
        UIHelper.SetSelected(self.TogDetailedDesc, ArenaTowerData.bShowBlessDetailDesc, false)
    end)
end

function UIPanelBlessConfirmView:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end

function UIPanelBlessConfirmView:UpdateInfo()
    UIHelper.SetSelected(self.TogDetailedDesc, ArenaTowerData.bShowBlessDetailDesc, false)

    UIHelper.RemoveAllChildren(self.LayoutChooseBlessList)
    local bShowDescTog = false
    for _, tCardData in ipairs(self.tBlessCardList or {}) do
        local script = UIHelper.AddPrefab(PREFAB_ID.WidgetBlessCardL, self.LayoutChooseBlessList)
        script:OnInitLargeCard(tCardData)
        if ArenaTowerData.CardHasShortDesc(tCardData) then
            bShowDescTog = true
        end
    end
    UIHelper.SetVisible(self.TogDetailedDesc, bShowDescTog)
    UIHelper.LayoutDoLayout(self.LayoutChooseBlessList)
    UIHelper.LayoutDoLayout(self.LayoutBtn)
end


return UIPanelBlessConfirmView