-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UIPanelBahuangBackgroundPopView
-- Date: 2024-01-01 16:54:43
-- Desc: ?
-- ---------------------------------------------------------------------------------

local UIPanelBahuangBackgroundPopView = class("UIPanelBahuangBackgroundPopView")

function UIPanelBahuangBackgroundPopView:OnEnter()
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end
    self:UpdateInfo()
end

function UIPanelBahuangBackgroundPopView:OnExit()
    self.bInit = false
    self:UnRegEvent()
end

function UIPanelBahuangBackgroundPopView:BindUIEvent()
    UIHelper.BindUIEvent(self.BtnClose, EventType.OnClick, function()
        UIMgr.Close(self)
    end)
end

function UIPanelBahuangBackgroundPopView:RegEvent()
    --Event.Reg(self, EventType.XXX, func)
end

function UIPanelBahuangBackgroundPopView:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end






-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

function UIPanelBahuangBackgroundPopView:UpdateInfo()
    UIHelper.ScrollViewDoLayout(self.ScrollView)
    UIHelper.ScrollToTop(self.ScrollView)
end


return UIPanelBahuangBackgroundPopView