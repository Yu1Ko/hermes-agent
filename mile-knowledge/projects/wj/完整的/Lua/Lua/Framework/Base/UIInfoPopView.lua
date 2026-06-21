-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UIInfoPopView
-- Date: 2023-02-16 11:26:35
-- Desc: ?
-- ---------------------------------------------------------------------------------

local UIInfoPopView = class("UIInfoPopView")

function UIInfoPopView:OnEnter(szTitle, szInfo)
    self.szTitle = szTitle
    self.szInfo = szInfo

    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end

    self:UpdateInfo()
end

function UIInfoPopView:OnExit()
    self.bInit = false
    self:UnRegEvent()
end

function UIInfoPopView:BindUIEvent()
    UIHelper.BindUIEvent(self.BtnClose, EventType.OnClick, function()
        UIMgr.Close(self)
    end)
    UIHelper.BindUIEvent(self.BtnCloseFullScreen, EventType.OnClick, function()
        UIMgr.Close(self)
    end)
end

function UIInfoPopView:RegEvent()
    --Event.Reg(self, EventType.XXX, func)
end

function UIInfoPopView:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end






-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

function UIInfoPopView:UpdateInfo()
    UIHelper.SetString(self.LabelTitle, self.szTitle)
    UIHelper.SetString(self.LabelContent, self.szInfo)

    UIHelper.ScrollViewDoLayout(self.ScrollBag)
	UIHelper.ScrollToTop(self.ScrollBag, 0, false)
end


return UIInfoPopView