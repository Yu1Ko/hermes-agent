-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UIWidgetStampView
-- Date: 2025-05-15 11:54:57
-- Desc: ?
-- ---------------------------------------------------------------------------------

local UIWidgetStampView = class("UIWidgetStampView")

function UIWidgetStampView:OnEnter(tbItem)
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end
    self.tbItem = tbItem
    if self.tbItem.szTPLink then
        self.tbTravelList = ActivityData.GetLinkList(self.tbItem)
    end
    self:UpdateInfo()
end

function UIWidgetStampView:OnExit()
    self.bInit = false
    self:UnRegEvent()
end

function UIWidgetStampView:BindUIEvent()
    UIHelper.BindUIEvent(self.BtnStamp, EventType.OnClick, function()
        self:UpdateTravelTargets()
    end)
end

function UIWidgetStampView:RegEvent()
    Event.Reg(self, EventType.OnTouchViewBackGround, function ()
        UIHelper.SetVisible(self.WidgetAnchorLeaveFor, false)
    end)

    Event.Reg(self, EventType.HideAllHoverTips, function()
        self.scriptIcon:RawSetSelected(false)
        UIHelper.SetVisible(self.WidgetAnchorLeaveFor, false)
    end)
end

function UIWidgetStampView:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end






-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

function UIWidgetStampView:UpdateInfo()
    local tbItem = self.tbItem
    if not tbItem then
        return
    end
    UIHelper.SetString(self.LabelContent, UIHelper.GBKToUTF8(tbItem.szDsc))
    UIHelper.SetVisible(self.BtnStamp, self.tbTravelList ~= nil)

    self.scriptIcon = UIHelper.AddPrefab(PREFAB_ID.WidgetItem_80, self.WidgetItem_80)
    self.scriptIcon:OnInitWithTabID(tbItem.dwTabType, tbItem.dwIndex, tbItem.nCount or 0)
    self.scriptIcon:SetItemReceived(tbItem.bCollect)
    self:SetClickCallBack(self.scriptIcon, tbItem)
end

function UIWidgetStampView:UpdateTravelTargets()
    UIHelper.SetVisible(self.WidgetAnchorLeaveFor, true)
    local scriptView = UIHelper.GetBindScript(self.WidgetAnchorLeaveFor)
    if scriptView and self.tbTravelList then
        scriptView:OnEnter(self.tbTravelList, 3)
        scriptView:SetSwallowTouches(true)
    end
end

function UIWidgetStampView:SetClickCallBack(script, tbItem)
    script:SetToggleGroupIndex(ToggleGroupIndex.AchievementAward)
    script:SetClickCallback(function()
        local _, scriptItemTip = TipsHelper.ShowItemTips(script._rootNode, tbItem.dwTabType, tbItem.dwIndex, false)
        scriptItemTip:SetBtnState({})
    end)
end


return UIWidgetStampView