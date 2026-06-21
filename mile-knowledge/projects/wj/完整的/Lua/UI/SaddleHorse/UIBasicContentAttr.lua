-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UIBasicContentAttr
-- Date: 2022-12-07 15:00:05
-- Desc: ?
-- ---------------------------------------------------------------------------------

local UIBasicContentAttr = class("UIBasicContentAttr")

function UIBasicContentAttr:OnEnter(szTitle,szContent,nIndex,bMagic,nIconID)
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end

    self.TogContent:setTouchDownHideTips(false)
end

function UIBasicContentAttr:OnExit()
    self.bInit = false
    self:UnRegEvent()
end

function UIBasicContentAttr:BindUIEvent()
end

function UIBasicContentAttr:RegEvent()
    --Event.Reg(self, EventType.XXX, func)
end

function UIBasicContentAttr:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end






-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

function UIBasicContentAttr:UpdateInfo()
end


return UIBasicContentAttr