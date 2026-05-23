-- ---------------------------------------------------------------------------------
-- Author: luwenhao
-- Name: UIFullScreenPicView
-- Date: 2023-11-20 10:24:26
-- Desc: PanelFullScreenPic
-- ---------------------------------------------------------------------------------

local UIFullScreenPicView = class("UIFullScreenPicView")

function UIFullScreenPicView:OnEnter()
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end
end

function UIFullScreenPicView:OnExit()
    self.bInit = false
    self:UnRegEvent()
end

function UIFullScreenPicView:BindUIEvent()
    
end

function UIFullScreenPicView:RegEvent()
    --Event.Reg(self, EventType.XXX, func)
end

function UIFullScreenPicView:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end






-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

function UIFullScreenPicView:UpdateInfo()
    
end


return UIFullScreenPicView