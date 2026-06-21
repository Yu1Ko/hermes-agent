-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UIPanelZhuanChang
-- Date: 2024-03-13 17:22:15
-- Desc: ?
-- ---------------------------------------------------------------------------------

local UIPanelZhuanChang = class("UIPanelZhuanChang")

function UIPanelZhuanChang:OnEnter()
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end
end

function UIPanelZhuanChang:OnExit()
    self.bInit = false
    self:UnRegEvent()
end

function UIPanelZhuanChang:BindUIEvent()
    
end

function UIPanelZhuanChang:RegEvent()
    --Event.Reg(self, EventType.XXX, func)
end

function UIPanelZhuanChang:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end






-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

function UIPanelZhuanChang:UpdateInfo()
    
end

function UIPanelZhuanChang:PlayAnim(szAnim, callback)
    UIHelper.PlayAni(self, self.AniAll, szAnim, callback)
end


return UIPanelZhuanChang