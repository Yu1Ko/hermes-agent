-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UIPanelVisionPopView
-- Date: 2023-07-24 10:45:49
-- Desc: ?
-- ---------------------------------------------------------------------------------

local UIPanelVisionPopView = class("UIPanelVisionPopView")

function UIPanelVisionPopView:OnEnter()
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end
    self:UpdateInfo()
end

function UIPanelVisionPopView:OnExit()
    self.bInit = false
    self:UnRegEvent()
end

function UIPanelVisionPopView:BindUIEvent()
    UIHelper.BindUIEvent(self.BtnClose, EventType.OnClick, function()
        UIMgr.Close(self)
    end)
end

function UIPanelVisionPopView:RegEvent()
    Event.Reg(self, EventType.OnSelectVersion, function()
        UIMgr.Close(self)
    end)
end

function UIPanelVisionPopView:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end






-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

function UIPanelVisionPopView:UpdateInfo()
    for nIndex, tbValue in ipairs(tStrCreditsVersion) do
        local szUITexPath = tbValue[2]
        local nUITexFrame = tbValue[3]
        local tbData = {}
        tbData.nIndex = nIndex
        tbData.szImage = tMobileIconPath[szUITexPath][nUITexFrame]
        UIHelper.AddPrefab(PREFAB_ID.WidgetVisonSelect, self.ScrollViewActivityHelp, tbData)
    end
    UIHelper.ScrollViewDoLayout(self.ScrollViewActivityHelp)
    UIHelper.ScrollToTop(self.ScrollViewActivityHelp)
end


return UIPanelVisionPopView