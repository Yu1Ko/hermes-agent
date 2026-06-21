-- ---------------------------------------------------------------------------------
-- Author: luwenhao1
-- Name: UIAgeLimitedPopView
-- Date: 2022-11-14 15:42:53
-- Desc: 登录适龄提醒界面 PanelAgeLimitedPop
-- ---------------------------------------------------------------------------------

local UIAgeLimitedPopView = class("UIAgeLimitedPopView")

function UIAgeLimitedPopView:OnEnter()
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true

        self:UpdateInfo()
    end
end

function UIAgeLimitedPopView:OnExit()
    self.bInit = false
    self:UnRegEvent()
end

function UIAgeLimitedPopView:BindUIEvent()
    UIHelper.BindUIEvent(self.BtnClose, EventType.OnClick, function()
        UIMgr.Close(self)
    end)
    UIHelper.BindUIEvent(self.BtnCloseFullScreen, EventType.OnClick, function()
        UIMgr.Close(self)
    end)
end

function UIAgeLimitedPopView:RegEvent()
    --Event.Reg(self, EventType.XXX, func)
end

function UIAgeLimitedPopView:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end






-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

function UIAgeLimitedPopView:UpdateInfo()
    UIHelper.ScrollViewDoLayout(self.ScrollBag)
	UIHelper.ScrollToTop(self.ScrollBag, 0, false)
end


return UIAgeLimitedPopView